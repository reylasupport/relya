# Relya

> Send anything. It remembers for you.

Um assistente pessoal para a vida administrativa. O utilizador partilha um
screenshot, um recibo, um PDF ou uma mensagem; o Relya percebe o que aquilo é,
quando acontece, o que é preciso fazer, e lembra-se por ele.

Nome, cores, ícone e URLs vivem todos num ficheiro — ver [Marca e design](#marca-e-design).

---

## Índice

- [O que já funciona](#o-que-já-funciona)
- [Stack](#stack)
- [Arquitetura](#arquitetura)
- [Setup rápido](#setup-rápido) · [sem telemóvel ligado?](#sem-telemóvel-ligado)
- [Configuração](#configuração)
- [Supabase](#supabase)
- [RevenueCat](#revenuecat)
- [iOS](#ios)
- [Android](#android)
- [Share extension](#share-extension)
- [Correr, testar, compilar](#correr-testar-compilar)
- [Localização](#localização)
- [Marca e design](#marca-e-design)
- [Segurança e privacidade](#segurança-e-privacidade)
- [Documentação](#documentação)

---

## O que já funciona

```bash
cd mobile
flutter run --dart-define-from-file=env/example.json
```

Isto corre a aplicação **completa** contra fixtures em memória, sem backend,
sem chaves e sem conta. Onboarding, autenticação, Home, Inbox, captura,
análise, confirmação, timeline, entidades, assistente, pesquisa, definições e
paywall estão todos navegáveis.

O caminho que vale a pena ver primeiro: **Inbox → Try an example**. É a
experiência dos dez segundos da secção 58 da especificação — três coisas
encontradas num screenshot, uma confirmação, feito.

---

## Stack

| Camada | Escolha | Porquê |
|---|---|---|
| Mobile | Flutter 3.35 | iOS e Android numa base de código, UI premium |
| Estado / DI | Riverpod 2 | Sem codegen, e qualquer serviço é substituível em testes |
| Navegação | GoRouter | Rotas declarativas, deep links, share intake por rota |
| Backend | Supabase | Postgres com RLS, auth, storage e edge functions |
| IA | Anthropic (default) ou OpenAI | Provider-agnóstico, trocado por env var |
| OCR | ML Kit, no dispositivo | Corta custo, latência e exposição de dados |
| Subscrições | RevenueCat | Regra obrigatória das lojas para conteúdo digital |
| Analytics | PostHog | Self-hostável, região EU |
| Erros | Sentry | Com scrubbing de conteúdo pessoal |

---

## Arquitetura

```
Relya/
├── docs/            ARCHITECTURE.md · AI_PIPELINE.md · ROADMAP.md
├── supabase/
│   ├── migrations/  schema, RLS, storage, funções SQL
│   └── functions/   edge functions (Deno) + testes
├── mobile/
│   └── lib/
│       ├── core/        branding, config, design system, formatação
│       ├── l10n/        ARB (en, pt-PT, pt-BR, es)
│       ├── navigation/  router, shell, share gate
│       ├── services/    OCR, notificações, calendário, share, analytics
│       ├── shared/      domínio, repositórios, widgets partilhados
│       └── features/    12 features, cada uma com application/ e presentation/
├── .env.example     segredos de servidor (nunca no cliente)
└── .github/         CI
```

Regra: uma feature nunca importa de outra feature. Nenhum ecrã importa
`supabase_flutter`. Detalhe completo em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Setup rápido

**Requisitos:** Flutter 3.35+, JDK 21–23 (o Gradle 8.12 não aceita o 25, e
`--enable-native-access` em `android/gradle.properties` precisa do 21),
Xcode 15+ para iOS, CocoaPods.

```bash
git clone <repo> && cd Relya/mobile
flutter pub get
flutter gen-l10n
cp env/example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

Com `USE_MOCK_DATA: true` (o valor em `example.json`) não é preciso mais nada.
Para ligar ao backend real, ver as duas secções seguintes e pôr
`"USE_MOCK_DATA": false`.

### Sem telemóvel ligado?

Há três formas de ver a app, por ordem de fidelidade.

**Emulador Android** — o alvo real, e já está a funcionar nesta máquina. Basta
arrancar o AVD e correr a app **a partir de `mobile/`**:

```bash
flutter emulators --launch Pixel_10_Pro_Fold
flutter run --dart-define-from-file=env/example.json
```

No Android Studio, abrir **`Desktop\Relya\mobile`**, não `Desktop\Relya`. A
configuração *Relya* em `mobile/.run/` já traz o `--dart-define-from-file`.

Três coisas tiveram de ser resolvidas para o primeiro build passar. Ficam
registadas porque nenhuma é óbvia a partir da mensagem de erro:

| Sintoma | Causa | Correção |
|---|---|---|
| `Unable to find valid certification path` ao descarregar o Gradle | O Norton intercepta TLS com uma CA própria, que o Windows conhece e o JDK não | `~/.gradle/gradle.properties` (ficheiro do utilizador, **fora do repositório**) aponta para uma truststore em `~/.relya-certs/` — cópia da `cacerts` do JDK **mais** essa CA. A verificação continua ligada |
| `What went wrong: 25.0.2` | O Flutter usava o Java 25 do Android Studio, que o Gradle 8.12 rejeita | `flutter config --jdk-dir` fixado no JDK 21 |
| `Inconsistent JVM-target compatibility` | Plugins do pub ainda declaram Java 1.8 enquanto o Kotlin segue o JDK | `android/build.gradle.kts` puxa todos os subprojetos para o 17 |

Se o Norton deixar de inspecionar HTTPS, as duas linhas `systemProp.javax.net.ssl.*`
em `~/.gradle/gradle.properties` podem ser removidas. Nada disto está no
repositório: outra máquina compila sem tocar em nada.

**Chrome** — instantâneo, sem instalar nada, com hot reload. Serve para rever
design, textos e navegação. Câmara, share sheet, OCR local, notificações e
compras não existem na web; com `USE_MOCK_DATA: true` nada disso é chamado.

```bash
flutter run -d chrome --dart-define-from-file=env/example.json
```

**Windows desktop** — precisa do workload *Desktop development with C++* no
Visual Studio, que não está instalado nesta máquina.

> A plataforma web existe **só como pré-visualização**. iOS e Android continuam
> a ser os únicos alvos de publicação; nada no `web/` vai para as lojas.

---

## Configuração

Duas famílias de configuração, separadas de propósito.

**`mobile/env/*.json`** — vai dentro do binário. Nada aqui é secreto, porque
tudo o que está num binário é legível por quem tiver o binário. Só valores
publicáveis: URL do Supabase, publishable key (protegida por RLS), chaves
públicas do RevenueCat, chave de ingestão do PostHog, DSN do Sentry.

**`.env.example` na raiz** — segredos de servidor. Chaves de modelos, a
service-role key do Supabase, o segredo do webhook do RevenueCat. Vivem apenas
como secrets das edge functions:

```bash
cp .env.example .env      # preencher
supabase secrets set --env-file .env
```

`env/*.json` e `.env` estão no `.gitignore`. Só os `.example` são versionados.

---

## Supabase

```bash
supabase link --project-ref <ref>
supabase db push                    # aplica migrations/0001..0006
supabase functions deploy analyze-capture
supabase functions deploy ask-assistant
supabase functions deploy delete-account
supabase functions deploy export-data
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

O `--no-verify-jwt` só no webhook: quem chama é o RevenueCat, não um
utilizador. A autenticação dessa função é o `REVENUECAT_WEBHOOK_SECRET`.

> A `0006` acrescenta `snoozed_until`, `recurrence_rule`, `recurrence_until` e
> `series_id` a `life_items`. O cliente já escreve estas colunas: **sem esta
> migração aplicada, qualquer insert ou update de um item falha**.

**As migrações criam:** 13 tabelas com RLS ativa e política "só o dono",
o bucket privado `captures` com policies por `user_id`, o trigger que cria
`profiles` e `user_preferences` quando uma conta nasce, a função atómica de
quota, e `assistant_context()` — a janela fechada de dados que o assistente
pode ver.

**Auth:** ativar Apple e Google em *Authentication → Providers* e acrescentar
`relya://auth-callback` aos *Redirect URLs*.

---

## RevenueCat

1. Criar produtos `pro_monthly` (7,99 €) e `pro_annual` (59,99 €) na App Store
   Connect e na Play Console.
2. No RevenueCat: entitlement com o identificador **`pro`**, e uma offering
   com os dois pacotes.
3. Pôr as chaves públicas do SDK em `env/*.json`.
4. Configurar o webhook para
   `https://<ref>.supabase.co/functions/v1/revenuecat-webhook`, com o header
   `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>`.

O cliente nunca decide se alguém é Pro. `profiles.plan` é escrito só pelo
webhook, e a app lê o entitlement do RevenueCat.

---

## iOS

Já configurado no repositório: deployment target 15.5, permissões com texto em
linguagem humana, esquema de URL `relya`, e o `Podfile` com as flags do
`permission_handler` (as permissões não listadas são compiladas fora do
binário).

```bash
cd mobile/ios && pod install
```

Falta uma coisa manual: o target da share extension.

---

## Android

Já configurado: intent filters para `SEND` e `SEND_MULTIPLE` (texto, imagem,
PDF), deep links `relya://`, `minSdk 23`, core library desugaring para os
lembretes, receiver de boot para os lembretes sobreviverem a um reinício, R8 e
regras de ProGuard.

Para assinar releases, criar `android/key.properties`:

```properties
storeFile=../upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Sem esse ficheiro o build de release assina com a chave de debug, o que serve
para `flutter run --release` local e nunca para uma submissão.

---

## Share extension

É a funcionalidade central do produto: o utilizador tem de conseguir usar o
Relya sem abrir o Relya.

**Android** — funciona já. Os intent filters estão no manifesto.

**iOS** — cinco minutos no Xcode, uma vez:

1. `File → New → Target → Share Extension`, com o nome exatamente
   **`ShareExtension`**.
2. Substituir o `ShareViewController.swift` gerado pelo que está em
   [`ios/ShareExtension/ShareViewController.swift`](mobile/ios/ShareExtension/ShareViewController.swift),
   e o `Info.plist` pelo de [`ios/ShareExtension/Info.plist`](mobile/ios/ShareExtension/Info.plist).
3. Em *Signing & Capabilities*, adicionar **App Groups** aos **dois** targets,
   com o mesmo identificador: `group.com.relya.app`.
4. Definir `CUSTOM_GROUP_ID = group.com.relya.app` nos build settings dos dois
   targets.
5. Deployment target da extensão: 15.5.

A extensão não analisa nada. Copia o ficheiro para o container partilhado e
devolve o controlo à app — extensões correm com pouca memória e são mortas sem
aviso, por isso o pipeline vive do outro lado.

---

## Reencaminhar email

Cada conta tem um endereço próprio, `u-<token>@<EMAIL_INBOX_DOMAIN>`. O
utilizador reencaminha a fatura ou a confirmação de voo para lá e a captura
aparece na Entrada, já analisada, à espera de confirmação.

Não é acesso à caixa de correio: sem OAuth, sem varrimento, sem nada para
revogar. É também a única versão desta funcionalidade que não precisa de
aprovação de scopes restritos da Google ou da Microsoft.

**Três defesas**, e a terceira é a que importa:

1. O segredo `INBOUND_EMAIL_SECRET`, para que só o provedor consiga chamar a
   função.
2. O token do endereço, imprevisível, que identifica a conta.
3. **O remetente tem de ser o email da conta.** Sem isto, quem descobrisse o
   endereço de alguém escrevia na vida dessa pessoa — e, porque o corpo chega a
   um modelo, no prompt dela. Um remetente errado e um token inexistente
   devolvem a mesma resposta, para o endpoint não servir para descobrir que
   endereços existem.

### Escolher o provedor

A função aceita **JSON** e **multipart/form-data**, e lê os nomes de campo dos
provedores comuns. O que importa é o provedor conseguir fazer POST para um URL.

| Provedor | Formato | Nota |
|---|---|---|
| **CloudMailin** | JSON | **O que recomendo.** 10 000 emails/mês grátis, sem cartão, endereço no domínio deles. Limite de 512 KB por mensagem no plano gratuito, o que exclui anexos grandes |
| **Postmark** (inbound) | JSON | Formato excelente e `OriginalRecipient` é o endereço de entrega. **Mas o registo recusa endereços gratuitos** — não dá para criar conta com um Gmail |
| **SendGrid** Inbound Parse | multipart | O `envelope` vem como string JSON num campo; a função já o desdobra |
| **Mailgun** Routes | multipart | `body-plain` / `body-html` |
| **Cloudflare** Email Routing | — | **Não faz POST para um URL.** Só reencaminha para outro endereço, ou entrega a um *Email Worker*. Usá-lo obriga a escrever esse Worker (com um parser MIME) que depois chama esta função |

O que eu escrevi antes — "o Cloudflare Email Routing é gratuito e chega" — está
errado para este desenho. Chega para reencaminhar; não chega para chamar um
webhook sem código pelo meio.

### Porque é que o endereço de entrega é o que conta

Um email reencaminhado leva no cabeçalho `To:` o destinatário **original** — o
próprio utilizador — e não o endereço da Relya. Ler o cabeçalho procuraria a
conta errada, ou nenhuma. A função prefere sempre o endereço de entrega
(`OriginalRecipient`, `envelope.to`, `recipient`) e só cai no cabeçalho em
último recurso.

### Anexos

Quando o email traz um PDF ou uma imagem dentro dos tipos que o bucket aceita e
abaixo de 15 MB, o anexo é guardado no storage em `<user_id>/…` e a captura
fica com `kind: pdf`. A `analyze-capture` passou a descarregar sempre o
original quando a captura é um PDF — uma fatura enviada em anexo tem um corpo
que não diz nada, e antes era o corpo que ganhava.

### Sem domínio: testar de graça

Não é preciso domínio nenhum para isto funcionar de ponta a ponta. O Postmark
dá um endereço na conta gratuita — `<hash>@inbound.postmarkapp.com`, 100
emails/mês, sem expirar — e o token da conta viaja depois de um `+`:

```
<hash>+u-<token>@inbound.postmarkapp.com
```

`tokenFrom` procura o `u-<token>` em qualquer segmento do local part, por isso
tanto o endereço no domínio próprio como o partilhado do provedor funcionam sem
alterar nada.

Isto serve para desenvolver e para os primeiros utilizadores. O domínio próprio
(`u-<token>@in.relya.app`) só é preciso quando o endereço passar a ser algo que
se mostra a estranhos — e nessa altura é só mudar os MX e o
`EMAIL_INBOX_DOMAIN`, sem tocar em código.

> Não recomendar domínios "gratuitos" tipo Freenom (.tk, .ml, .ga): as
> registrações gratuitas foram suspensas e nada disso é sítio para pôr o
> endereço de correio de utilizadores.

### Configurar

> **O domínio registado é `relya.is-local.org`**, e existe só para isto:
> receber. Não sai correio dele. Onde este capítulo escreve `in.relya.app`
> como exemplo, o valor real a usar é `relya.is-local.org` — incluindo em
> `EMAIL_INBOX_DOMAIN`, que continua vazio em `env/prod.json` e por isso
> mantém a funcionalidade escondida na app.

1. **Migração:** aplicar `0007_email_inbox.sql` (idempotente, dá para colar no
   SQL Editor).
2. **Segredo:**
   ```bash
   supabase secrets set INBOUND_EMAIL_SECRET="$(openssl rand -hex 32)"
   ```
3. **Deploy** — sem verificação de JWT, porque quem chama é o provedor:
   ```bash
   supabase functions deploy inbound-email --no-verify-jwt
   ```
4. **DNS:** apontar os MX de um subdomínio (`in.relya.app`) para o provedor.
5. **Webhook** no provedor, a apontar para
   `https://<ref>.supabase.co/functions/v1/inbound-email`.

   Autenticação: se o provedor deixar definir headers, usa
   `Authorization: Bearer <segredo>`. Se só aceitar um URL — e vários só
   aceitam — mete o segredo na query, `...inbound-email?secret=<segredo>`. A
   função aceita as duas formas e compara em tempo constante.
6. **Cliente:** pôr o domínio em `env/*.json`:
   ```json
   "EMAIL_INBOX_DOMAIN": "in.relya.app"
   ```

Enquanto `EMAIL_INBOX_DOMAIN` estiver vazio, a definição não aparece na app.
Um endereço para onde ninguém consegue enviar é pior do que definição nenhuma.

### Testar sem DNS

Vale a pena fazer isto **antes** de mexer nos MX, porque separa "a função está
bem" de "o email não chega". O token está em
`select inbox_token from profiles where email = '<o teu email>'`:

```bash
curl -i -X POST "https://<ref>.supabase.co/functions/v1/inbound-email" \
  -H "Authorization: Bearer <INBOUND_EMAIL_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{
    "OriginalRecipient": "u-<token>@in.relya.app",
    "From": "<o teu email>",
    "Subject": "Fatura EDP",
    "TextBody": "Fatura de eletricidade, 48,20 EUR, vence a 12 de outubro."
  }'
```

Esperado: `{"accepted":true,"capture_id":"..."}` e a captura na Entrada da app.

Um `{"accepted":false}` é sempre uma das duas coisas: o token não existe, ou o
`From` não é o email da conta. Os logs da função dizem qual — a resposta, de
propósito, não diz.

---

## Correr, testar, compilar

```bash
cd mobile

# Desenvolvimento (fixtures, sem backend)
flutter run --dart-define-from-file=env/dev.json

# Qualidade — o que o CI corre
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test

# Edge functions
deno test supabase/functions/_tests
deno lint supabase/functions

# Release
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build ipa --release --dart-define-from-file=env/prod.json
```

---

## Localização

Quatro idiomas completos: inglês, português de Portugal, português do Brasil e
espanhol. Nenhuma string de interface está no código.

Acrescentar um idioma:

1. Copiar `lib/l10n/app_en.arb` para `app_<code>.arb` e traduzir.
2. Acrescentar uma linha em `lib/l10n/supported_locales.dart`.
3. `flutter gen-l10n`.

Não é preciso mais nada — nem para RTL, que a arquitetura já suporta
(`SupportedLocales.rtlLanguages`).

**Datas, horas e moedas** vêm sempre do locale, via ICU. Um utilizador
português vê `12/09/2026 15:30` e `149,99 €`; um americano vê `9/12/2026 3:30 PM`
e `$149.99`. Não há formato americano assumido em lado nenhum — há um teste que
o garante.

**O idioma da interface e o idioma do documento são independentes.** A interface
pode estar em inglês e a IA analisar um recibo em espanhol; o idioma do conteúdo
é detetado por captura.

---

## Marca e design

### O logótipo

O mark é **desenhado em código**, não é uma imagem: um `CustomPainter` em
[`relya_logo.dart`](mobile/lib/core/branding/relya_logo.dart) que pinta um
squircle com o gradiente da marca, um tick que resolve para cima, e a faísca
solta no canto — o que a app encontrou e tu não tinhas visto.

Ser código tem três consequências práticas: fica nítido em qualquer tamanho,
não pesa nada no bundle, e o ícone do telemóvel nunca pode divergir do que
aparece dentro da app, porque saem do mesmo painter.

```bash
flutter test tool/generate_brand_assets.dart   # gera os PNG a 1024
flutter pub run flutter_launcher_icons          # aplica-os ao iOS e Android
```

É um logótipo provisório e assumido como tal: é honesto, é distintivo, e é
substituível por um ficheiro.

### Temas

Quatro temas, em **Conta → Aspeto**, escolhidos a partir de miniaturas de si
próprios — um ponto de cor não consegue dizer que o Aconchego é quente e escuro
ou que o Pastel tinge as linhas.

| Tema | Carácter |
|---|---|
| **Suave** | Papel quente e índigo profundo. Calmo e neutro. O default |
| **Pastel** | Claro e acolhedor, com as linhas tingidas pela cor do tipo |
| **Aconchego** | Creme e preto quente com verde salva. Terroso e sossegado |
| **Meia-noite** | Azul profundo e violeta elétrico. Cantos justos, muito contraste |

Um tema aqui é um **desenho inteiro**, não uma paleta. Existe uma camada de
conceito ([`core/design/concept/`](mobile/lib/core/design/concept)) com um
*kit* por design: cada um implementa a mesma gramática — fundo de página,
cartão, linha de lista, cabeçalho de secção, badge, botão, chip, estado vazio,
tipografia, densidade — à sua maneira. Os ecrãs pedem as peças ao kit em vez de
as construírem, e onde os conceitos discordam do **layout** há uma vista por
conceito (`views/home_a.dart`, `home_d.dart`, `home_e.dart`, `home_f.dart`).

| | A · Meia-noite | D · Suave | E · Pastel | F · Aconchego |
|---|---|---|---|---|
| Carácter | IA premium | universal | ilustrado | lifestyle |
| Fundo | glows e um arco | wash mínimo | pétalas e folhas | luz quente e um ramo |
| Cantos | 14 | 18 | 24 | 18 |
| Margem | 18 | 20 | 22 | 20 |
| Ícones | outline em quadrado justo | outline arredondado | **preenchidos em círculo** | outline em quadrado |
| Linhas | densas e nuas | espaçadas e nuas | **tingidas pela categoria** | espaçadas e nuas |
| Secções | barra de acento + contagem | título + *Ver todos* | título + contagem em pílula | **VERSALETES** + contagem |
| Botão | **gradiente** azul→violeta | sólido, cantos suaves | **stadium** | sólido lavanda, sem gradiente |
| Títulos | sans bold | sans bold | sans bold | **Merriweather serif** |
| Botão + | acima da barra | acima da barra | **no meio da barra** | acima da barra |
| Início | poster + 4 contagens | cartão de foco + barra IA | cartão tingido + contagens | cartão azeitona + barra IA |
| Entrada | **fila de ficheiros** com estados | lista com separadores | cartões redondos | cartões quentes |
| Assistente | copilot: comandos + **insights** | pergunta simples | **mascote robot** | pills com serif |
| Adicionar | folha escura explicada | folha simples | folha simples | **ecrã inteiro** com círculos |
| Detalhe | título em banda de cor | título na página | título na página | título em banda, serif |
| Vida | grelha densa | cartões brancos | **cartões pastel cheios** | cartões azeitona e bronze |

Trocar de tema não muda a cor: muda onde está o botão de captura, quantos
destinos tem a barra, o que é o topo do Início, se as linhas são cartões, e se
os títulos são serif. Dois ficheiros de teste travam qualquer regressão para
"o mesmo ecrã noutra cor":
[`concept_kit_test.dart`](mobile/test/features/concept_kit_test.dart) e
[`skin_layout_test.dart`](mobile/test/features/skin_layout_test.dart).

A camada de dados, estado, backend, lógica e navegação é **uma só**. O que se
multiplica é a apresentação.

Cada tema existe em **claro e escuro** — um telemóvel que muda ao pôr do sol
não pode transformar a app em algo que ninguém desenhou.

**Cada tema tem a sua própria arte**, e toda ela é desenhada em código:

| Tema | Boas-vindas | Ficheiro |
|---|---|---|
| Suave | chávena, planta e dois cartões apanhados, sobre o wash | [`relya_scenes.dart`](mobile/lib/core/design/illustrations/relya_scenes.dart) |
| Pastel | a mesma ideia com as entradas a orbitar em bolhas | [`pastel_scene.dart`](mobile/lib/core/design/illustrations/pastel_scene.dart) |
| Aconchego | **fotografia a ocupar o ecrã** — café, manta e planta desfocada | [`cosy_backdrop.dart`](mobile/lib/core/design/illustrations/cosy_backdrop.dart) |
| Meia-noite | **aurora a ocupar o ecrã** — cúpula de luz, arcos e estrelas | [`midnight_aurora.dart`](mobile/lib/core/design/illustrations/midnight_aurora.dart) |

Nenhuma é um ficheiro de imagem. Uma imagem rasterizada teria de existir quatro
vezes — clara, escura, quente, fria — pesaria megabytes e seria a única
superfície da app a ignorar o tema. No Aconchego é o desfoque que faz o
trabalho: uma luz de janela quente, uma planta fora de foco e uma vinheta são o
que faz meia dúzia de formas lerem-se como fotografia em vez de como clip art.

Uma regra que não se quebra: **as cores de significado não mudam**.
Verde-sucesso, âmbar-aviso e vermelho-urgente são iguais nos quatro temas. Se
"em atraso" fosse verde salva num tema e vermelho noutro, a cor deixava de
significar alguma coisa — e há um teste que trava isso.

Além das paletas, cada **tipo de item tem a sua cor**
([`type_palette.dart`](mobile/lib/core/design/tokens/type_palette.dart)): uma
consulta, uma fatura e um voo são preocupações diferentes, e o olho deve poder
separá-las antes de o cérebro ler uma palavra. A cor nunca é o único sinal —
cada linha leva também ícone e texto.

### Rever o design sem telemóvel

```bash
flutter test tool/generate_screenshots.dart     # build/screenshots/*.png
```

Renderiza os ecrãs reais, com fixtures, a 390×844, em claro e escuro. Serve
para revisão de design, e mais tarde para as imagens das lojas. É repetível,
por isso uma alteração que parta um layout aparece num diff em vez de ser
descoberta no telemóvel de alguém.

### Rebranding

| O quê | Onde |
|---|---|
| Nome, tagline, emails, URLs, cores da marca | `brand.dart` (ou override por `--dart-define`) |
| Nome no ecrã inicial (Android) | `android/app/src/main/res/values/strings.xml` |
| Nome no ecrã inicial (iOS) | `ios/Runner/Info.plist` → `CFBundleDisplayName` |
| Esquema de URL | `brand.dart`, manifesto Android, `Info.plist` |
| Ícones | regenerar com os dois comandos acima |

A palavra "Relya" não aparece hardcoded em mais lado nenhum do código Dart.

---


---

## Segurança e privacidade

Isto é uma app que vê consultas médicas, passaportes e faturas. A privacidade é
uma funcionalidade, não uma página legal.

- **Nenhuma credencial de modelo no cliente.** Toda a IA passa por edge
  functions. O cliente só fala com o Supabase, com o JWT do utilizador.
- **RLS em todas as tabelas.** Um `WHERE` esquecido devolve vazio, não os dados
  de outra pessoa.
- **Storage privado**, com o `user_id` como primeiro segmento do caminho e
  policies a validá-lo. URLs sempre assinados e de curta duração.
- **Minimização.** OCR local primeiro: a maioria dos screenshots nunca sai do
  telefone como imagem. O utilizador pode escolher guardar só o que foi
  extraído e descartar o original.
- **Conteúdo é dados, nunca instruções.** Quatro camadas de defesa contra
  prompt injection, descritas em [`docs/AI_PIPELINE.md`](docs/AI_PIPELINE.md).
- **Nada acontece sem confirmação.** A app sugere; a pessoa decide. Não há
  caminho de código que pague, cancele, envie ou apague por iniciativa própria.
- **Apagar a conta apaga tudo** — linhas, ficheiros e o utilizador de auth.
- **Exportar** devolve um JSON com tudo o que guardamos.
- **Logs e crash reports** nunca levam conteúdo de capturas; o Sentry vai com
  `sendDefaultPii = false` e um scrubber antes do envio.
- **Analytics é opt-out** e, quando desligado, nada sai do dispositivo.

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Camadas, pastas, schema, dependências, mapa de ecrãs, design system, modelo de dados |
| [`docs/AI_PIPELINE.md`](docs/AI_PIPELINE.md) | Pipeline, prompts, defesa contra injeção, datas, confiança, controlo de custo |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Estado por fase, o que falta para submeter, decisões adiadas e porquê |
