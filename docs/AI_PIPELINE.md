# AI Pipeline

Como o Relya transforma "uma coisa qualquer" em ações úteis, e o que impede
esse caminho de correr mal.

---

## 1. O caminho completo

```
input                    imagem · PDF · texto · URL
  │
  ▼  [dispositivo]
hash SHA-256             já analisámos isto? → devolve o resultado em cache
  │
  ▼  [dispositivo]
OCR local (ML Kit)       texto extraído, offline, grátis
  │
  ▼  [dispositivo]
upload condicional       só se o OCR falhou, ou é PDF, ou o utilizador
  │                      pediu para guardar o original
  ▼
POST /functions/v1/analyze-capture           (JWT do utilizador)
  │
  ├── quota              consume_capture_quota() → 429 se excedida
  ├── escolha de modelo  texto curto → modelo pequeno
  │                      imagem → modelo multimodal
  ├── prompt             SYSTEM + CONTEXT + DOCUMENT (fenced)
  ├── geração            tool call com JSON Schema estrito
  ├── validação          Zod → normalização → clamp de confiança
  ├── persistência       capture_analyses (cache) + ai_usage (custo)
  ▼
ExtractionResult[]
  │
  ▼  [dispositivo]
ecrã de confirmação      o utilizador vê, corrige, aceita
  │
  ▼
life_items + reminders   escrito só depois do toque do utilizador
```

---

## 2. Onde o dinheiro é gasto (e poupado)

Quatro travões, por ordem de impacto. Todos estão implementados.

| Travão | Onde | Efeito |
|---|---|---|
| Cache por hash | `captures.content_hash` (índice único) | O mesmo screenshot partilhado duas vezes é analisado uma |
| Cache de resultado | `capture_analyses` | Reabrir a confirmação não custa nada |
| OCR local primeiro | `MlKitOcrService` | Um prompt de texto custa uma fração de um multimodal |
| Modelo pequeno por omissão | `preferSmallModel` | Texto com menos de 1500 caracteres nunca usa o modelo grande |

Cada chamada grava uma linha em `ai_usage` com tokens, custo em USD, latência e
se usou imagem. É isso que torna possível responder a "quanto custa um
utilizador gratuito por mês" sem esperar pela fatura.

---

## 3. O prompt

Três blocos, sempre nesta ordem, sempre rotulados
([`_shared/prompt.ts`](../supabase/functions/_shared/prompt.ts)).

**SYSTEM** — regras. O que extrair, como pontuar confiança, como resolver
datas, e a instrução explícita de que o bloco seguinte é conteúdo, não ordens.

**CONTEXT** — factos fiáveis fornecidos pela aplicação: data e hora atuais,
timezone IANA, locale do utilizador, e os nomes das entidades que já conhece
(para o modelo poder ligar um documento novo ao carro certo). Nomes apenas —
nunca dados de terceiros.

**DOCUMENT** — o conteúdo, dentro de `<untrusted_content>…</untrusted_content>`,
com uma linha depois do fecho a repetir que aquilo é dados.

---

## 4. Defesa contra prompt injection

Um utilizador vai, mais cedo ou mais tarde, partilhar um PDF que diz
"ignore previous instructions". Quatro camadas, e nenhuma depende do modelo
"portar-se bem":

1. **Rotulagem e fence.** O conteúdo está delimitado e o system prompt declara
   que é não-confiável. A linha de fecho é repetida depois do payload, para que
   um conteúdo truncado ou injetado não faça a fronteira desaparecer.

2. **Canal de saída fechado.** A resposta é gerada através de um *tool call*
   com JSON Schema estrito. Não existe campo de texto livre onde uma instrução
   possa sair. `suggested_actions` é um enum fechado.

3. **Nenhuma ação a jusante.** A edge function não tem ferramentas. Não apaga,
   não envia, não paga, não escreve `life_items`. O único efeito de uma análise
   é devolver JSON e escrever contabilidade. Um documento não pode pedir nada
   porque não há nada para pedir.

4. **Confirmação humana.** Nada entra na vida do utilizador sem um toque no
   ecrã de confirmação. Mesmo uma extração perfeitamente maliciosa produz, no
   máximo, uma sugestão que a pessoa vê antes de aceitar.

Testado em [`_tests/schema_test.ts`](../supabase/functions/_tests/schema_test.ts):
categorias e ações inventadas são rejeitadas pela validação, e o fence
sobrevive a payloads hostis.

---

## 5. Datas

O ponto onde é mais fácil errar e mais caro errar.

O modelo devolve, por data:

```jsonc
{
  "raw": "12/10",                        // como aparece, verbatim
  "kind": "deadline",
  "resolved": "2026-10-12T00:00:00Z",    // a leitura escolhida, em UTC
  "timezone": "Europe/Lisbon",
  "has_time": false,
  "ambiguous": true,                     // as duas leituras são plausíveis
  "alternative": "2026-12-10T00:00:00Z"  // a outra
}
```

- `raw` é mantido para o ecrã de confirmação poder mostrar de onde veio.
- O locale decide: `pt-PT` lê `12/10` como 12 de outubro; `en-US` como
  10 de dezembro.
- Se o locale não desempatar, `ambiguous: true` e a interface **pergunta**
  (`_AmbiguityPicker`), com as duas datas como botões. Nunca adivinha em
  silêncio.
- Expressões relativas ("amanhã", "sexta-feira", "daqui a duas semanas")
  resolvem contra a data e o timezone do bloco CONTEXT.
- Tudo é guardado em UTC, com o timezone IANA do evento ao lado. Uma viagem
  não deve mover uma consulta.

---

## 6. Confiança

| Intervalo | O que a interface faz |
|---|---|
| `>= 0.85` | Mostra normalmente, sem badge. Um aviso em tudo é ruído |
| `0.55 – 0.85` | Badge âmbar "Confirma" |
| `< 0.55` | Badge vermelho + aviso a dizer que não percebeu completamente |

Além disso, `unresolved_note` transporta, em texto, aquilo que o modelo não
conseguiu confirmar, e é mostrado tal e qual. A regra da secção 5 da
especificação é explícita no system prompt: **nunca inventar prazos legais ou
garantias**. Dizer "não consegui confirmar" é sempre melhor do que um palpite
confiante.

`ExtractionResult.needsUserAttention` é verdadeiro se a confiança for baixa,
se houver uma data ambígua, ou se houver uma nota por resolver. Só itens
acima de 0.55 chegam pré-selecionados ao ecrã de confirmação.

---

## 7. Normalização

Antes de o resultado sair do servidor
([`_shared/normalise.ts`](../supabase/functions/_shared/normalise.ts)):

- confiança é limitada a `[0, 1]`;
- moeda é passada a maiúsculas;
- datas que não fazem parse, ou a mais de um século de distância, são
  descartadas (é alucinação, não prazo);
- lembretes ancorados a uma data que não existe são removidos;
- no máximo três sugestões de lembrete por item.

Barato de correr, e elimina uma classe inteira de bugs do tipo "a app agendou
uma coisa absurda".

---

## 8. Trocar de fornecedor

```ts
interface AIProvider {
  extract(request: ExtractionRequest): Promise<ProviderResult>;
  answer(systemPrompt: string, userPrompt: string): Promise<string>;
}
```

Três implementados, escolhidos pela variável `AI_PROVIDER`:

| Valor | Fornecedor | Chave | Notas |
|---|---|---|---|
| `anthropic` (omissão) | Claude Sonnet 5 / Haiku 4.5 | `ANTHROPIC_API_KEY` | |
| `gemini` | Gemini 2.0 Flash / Flash-Lite | `GEMINI_API_KEY` | **Tier gratuito**, multimodal |
| `openai` | GPT | `OPENAI_API_KEY` | |

Nenhum outro ficheiro do projeto sabe qual o fornecedor em uso.

O Gemini existe por ser o único com tier gratuito que também é multimodal — e
a entrada principal deste produto é a fotografia de um documento, que um
modelo só de texto não lê. **O tier gratuito da Google treina com o que lhe
envias**: serve para construir e testar, não para recibos e consultas médicas
de pessoas reais. Antes de abrir ao público, ou se passa ao tier pago ou se
declara isso na política de privacidade.

A saída estruturada usa `responseSchema` em vez de tool call, com o mesmo
efeito: não há canal de texto livre onde um documento hostil possa escrever
instruções. O schema é **um só**, traduzido para o dialecto de cada fornecedor
em `toGeminiSchema()` — duas cópias divergiriam no primeiro campo novo. Três
testes fixam a tradução.

Cada adapter é responsável por devolver `costUsd` — a tabela de preços vive
junto do adapter, para não haver duas fontes de verdade a divergir.

---

## 9. O Assistant

Mesma disciplina, problema diferente: a resposta tem de vir **só** dos dados do
utilizador.

- A recuperação é uma função SQL, `assistant_context(user_id, from, to, limit)`,
  que devolve uma janela fixa de items ativos. O modelo não consulta a base de
  dados; recebe a lista e mais nada.
- O system prompt diz explicitamente que aquela lista é a totalidade do que ele
  sabe, e que deve dizer que não encontrou nada quando não encontrar.
- As citações são filtradas contra os ids que foram efetivamente mostrados, por
  isso não é possível citar um item inexistente.

---

## 10. Testar

**Fixtures** ([`_tests/fixtures.ts`](../supabase/functions/_tests/fixtures.ts))
cobrem os nove casos da secção 70 da especificação: consulta, fatura,
subscrição, prazo de devolução, voo, entrega, documento, evento e a data
ambígua `04/05`.

**Testes de contrato** correm sem chamar nenhum modelo: validam o schema,
a normalização e a resistência do fence a injeção. São rápidos e correm no CI.

**Avaliação de modelo** — quando mudar o prompt ou o modelo, correr as mesmas
fixtures contra o fornecedor real e comparar categoria, data resolvida e
confiança. Uma descida na taxa de acerto das datas é o sinal que mais importa,
porque é o campo em que um erro é imediatamente visível para o utilizador.
