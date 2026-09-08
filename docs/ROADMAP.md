# Roadmap

Estado por fase, na ordem definida na secção 81 da especificação.

Legenda: **feito** · **parcial** — o essencial existe, falta a parte marcada ·
**por fazer**

---

## MVP V1

| # | Fase | Estado | Notas |
|---|---|---|---|
| 1 | Estrutura técnica e arquitetura | feito | `core/`, `shared/`, `features/`, env por `--dart-define-from-file`, branding num só ficheiro |
| 2 | Design system | feito | Camada de conceito: um *kit* por design (fundo, cartão, linha, secção, badge, botão, chip, estado vazio, tipografia, densidade) mais vistas por conceito onde o layout diverge — Início, Entrada e Assistente têm quatro. Serif Merriweather (OFL) no Aconchego. Arte desenhada em código, dois fundos de ecrã inteiro |
| 3 | Navegação e ecrãs com dados mock | feito | 5 tabs + 13 rotas, Home com cartão de foco, Próximos com calendário mensal, avatar de conta. `USE_MOCK_DATA=true` corre a app inteira sem backend |
| 4 | Autenticação | feito | Criar conta ou entrar no mesmo ecrã: Apple nativo, Google OAuth, email+password com recuperação, magic link. Gate no router |
| 5 | Base de dados Supabase | feito | 13 tabelas, RLS em todas, índices, quota atómica, storage privado |
| 6 | Capture | feito | Câmara, galeria, ficheiro, texto colado, entrada manual. Fila offline: uma partilha sem rede fica em disco e sobe sozinha quando a rede volta |
| 7 | Share extension | parcial | Android completo. iOS: código e Info.plist prontos, **falta criar o target no Xcode** (5 min, passos no README) |
| 8 | Extração por IA | feito | Edge function, dois adapters, schema estrito, defesa contra injeção, contabilidade de custo |
| 9 | Fluxo de confirmação | feito | O ecrã central. Confiança, datas ambíguas, correção inline, "Add all" |
| 10 | Lembretes e calendário | feito | Agendamento com timezone, quiet hours e categorias silenciadas, ligado ao submit do ecrã de confirmação. Calendário via folha do sistema |
| 11 | Subscrições | parcial | RevenueCat, paywall e webhook prontos; **falta criar os produtos nas lojas** e configurar as offerings |
| 12 | Localização | feito | en, pt-PT, pt-BR, es completos e com paridade verificada. Formatação regional separada do idioma da interface |
| 13 | Analytics e error reporting | feito | PostHog e Sentry com scrubbing. Catálogo de eventos fechado |
| 14 | Testes | feito | 116 testes Flutter + 9 Deno, `analyze --fatal-infos` limpo. Inclui o caminho crítico ponta a ponta, a fila offline e uma varredura de acessibilidade a 1,6x em 5 ecrãs x 4 temas |
| 15 | Preparação para as lojas | por fazer | Ícones, screenshots, política de privacidade, ficha de loja |

---

## O que falta para submeter

Por ordem de bloqueio.

1. **Target da Share Extension no Xcode.** É a funcionalidade central em iOS.
   Passos no README; o Swift e o `Info.plist` já existem em
   `ios/ShareExtension/`. O `Runner.entitlements` e o `CUSTOM_GROUP_ID`
   (`group.com.relya.app`) já estão no projeto; falta criar o App Group e o
   capability de Sign in with Apple no portal da Apple, e repetir o
   entitlement no target novo.
2. **Produtos nas lojas** (App Store Connect e Play Console) e offerings no
   RevenueCat, com os identificadores `pro_monthly` e `pro_annual`.
3. **Logótipo definitivo** (o actual é provisório mas funcional) e o domínio
   real em `Brand`, se não for `relya.app`.
4. **Política de privacidade e termos** publicados nos URLs configurados.
   Obrigatório para ambas as lojas, e a app já liga para lá.

---

## Lacunas face ao mercado

As treze diferenças identificadas numa comparação com o que existe hoje
(apps de screenshot→calendário, Todoist/TickTick/Structured, VaultlyKeep e
afins, Rocket Money). Estado real, não intenção.

| # | Lacuna | Estado |
|---|---|---|
| 5 | Editar um item depois de guardado | **feito** — ecrã `/item/:id/edit`, todos os campos, e os lembretes seguem a data nova |
| 6 | Snooze | **feito** — esconde até ao momento escolhido, sem mexer na data do item, e volta sozinho |
| 7 | Recorrência a sério | **feito** — `RecurrenceRule` (FREQ+INTERVAL), concluir uma ocorrência escreve a seguinte, `series_id` liga a série |
| 11 | Leitura offline | **feito** — `CachedLifeItemRepository` guarda a última leitura em disco, por utilizador, apagada no sign-out |
| 2 | Ingestão por email | **feito no código** — endereço por conta, edge function `inbound-email`, remetente validado. Falta DNS e provedor: ver o README |
| 8 | Web | **parcial** — build web a compilar, e a captura por ficheiro/imagem passou a viajar em bytes. Faltam notificações (Web Push) e compras |
| — | Quick-add de serviços | **feito** — 111 marcas e 20 genéricos, com recorrência já preenchida |
| 1 | Posicionamento contra o SO | **por fazer** — decisão de produto, não de código. Ver abaixo |
| 13 | Voz → item | **por fazer** — precisa de `speech_to_text` e da permissão de microfone nos dois manifestos |
| 4 | Ler o calendário do telemóvel | **por fazer** — precisa de `device_calendar`, `READ_CALENDAR` e `NSCalendarsUsageDescription`. Muda a revisão nas lojas |
| 8 | Widget e relógio | **por fazer** — o widget precisa de código nativo (Glance/WidgetKit); o relógio precisa de um target no Xcode |
| 10 | Claim pack | **por fazer** — gerar um PDF de garantia/seguro a partir do item e dos anexos |
| 9 | Partilha e família | **por fazer** — implica `households`, reescrever a RLS das 13 tabelas e um entitlement de família no RevenueCat |
| 12 | Integrações | **bloqueado** — Google Calendar bidirecional precisa de client IDs verificados; Zapier precisa de API pública e conta de developer |
| 3 | Ligação bancária | **bloqueado** — precisa de um agregador PSD2 (Tink, GoCardless) com contrato e KYC |

### Sobre o ponto 1

O iOS 26 põe um botão *Add to Calendar* no próprio screenshot, e o Gemini faz
o mesmo no Android. A tese "partilha um screenshot e eu trato" deixou de ser
diferenciadora. O que continua por ocupar é a vida administrativa **depois** do
evento — prazo de devolução, garantia a expirar, subscrição a renovar, seguro,
fatura — e é aí que a estrutura desta app já vai mais longe do que qualquer app
de screenshot ou de garantias. Isto é trabalho de copy: onboarding, paywall,
ficha de loja.

### Migração

O código já escreve `snoozed_until`, `recurrence_rule`, `recurrence_until` e
`series_id`. **A migração `0006_snooze_recurrence.sql` tem de ser aplicada antes
de correr esta versão contra o backend real**, ou qualquer insert e qualquer
update de `life_items` falha com uma coluna desconhecida.

```bash
supabase db push
```

A `0007_email_inbox.sql` acrescenta `inbox_token` a `profiles` e o valor
`email` ao enum `capture_source`.

A `0008_quota_refund_and_assistant.sql` acrescenta `refund_capture_quota` e
`consume_assistant_quota`, duas colunas em `profiles` e uma versão nova da
vista `ai_cost_per_user_month`. Sem ela nada rebenta - as duas edge functions
falham em aberto de propósito - mas **a quota não é devolvida numa falha do
modelo e o assistente continua sem limite**, e a única pista fica no log da
função. Todas as migrações são idempotentes e podem ser coladas no SQL Editor
num projeto sem CLI ligado.

---

## V2 — Life Graph

Arquitetura já preparada: as tabelas `entities` e `entity_relationships`
existem, `LifeItem.entityId` existe, e a extração já devolve
`related_entity` como pista.

- Ligação automática entre capturas pela mesma matrícula, número de série ou
  apólice (`FeatureFlags.lifeGraphAutoLinking`).
- Áreas de Compras, Garantias e Documentos com vistas próprias.
- Subscrições com total mensal e aviso de renovação.
- Bloqueio biométrico nos documentos (a preferência já existe).

## V3 — Assistente e importação

- Importação de email (Gmail, Outlook) como fonte de capturas.
- Inteligência de viagem: check-in, documentos necessários, hora de sair.
- Casa: contadores, contratos, manutenção.

## V4 — Família e proteção

- FamilyOS (partilha entre até 5 pessoas).
- Purchase Guardian: devoluções e garantias proativas.
- Deteção de burla em documentos partilhados.
- Insights de dinheiro a partir de faturas e subscrições já registadas.

---

## Decisões deliberadamente adiadas

Registadas aqui para não serem redescobertas como "esquecimentos".

| Decisão | Porquê |
|---|---|
| Modelos escritos à mão em vez de `freezed` | Evita `build_runner` no ciclo de desenvolvimento e no CI. A migração é mecânica se o número de modelos crescer |
| Sem calendário próprio | O sistema já tem um bom. `add_2_calendar` não pede sequer permissão de leitura |
| Google Sign-In via OAuth, não nativo | Menos configuração nativa para o MVP. O upgrade para id-token nativo é local ao `SupabaseAuthService` |
| Sem cache local em SQLite | `USE_MOCK_DATA` e a cache do Supabase cobrem o MVP. Offline real (fila de capturas) é a próxima peça de infraestrutura |
| `tracked_subscriptions` não existe como tabela | Uma subscrição é um `life_item` com `recurrence` em `metadata`. Menos schema, mesma funcionalidade |
| Family não implementado | Secção 55 da especificação exclui-o explicitamente do V1 |
