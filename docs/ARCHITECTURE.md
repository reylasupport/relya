# Relya — Arquitetura Técnica

> Documento de referência. Responde aos 10 pontos da secção 82 da especificação.
> `Relya` é nome de trabalho — ver [1.5 Branding substituível](#15-branding-substituível).

---

## 1. Arquitetura técnica

### 1.1 Visão geral

```
┌──────────────────────────────────────────────────────────────┐
│  MOBILE (Flutter)                                            │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────────┐  │
│  │ Share Ext.   │  │ App (UI)      │  │ OCR local (MLKit) │  │
│  │ iOS/Android  │→ │ Riverpod +    │← │ texto + metadata  │  │
│  └──────────────┘  │ GoRouter      │  └───────────────────┘  │
│                    └───────┬───────┘                         │
│      Repositories (interface) ── LocalCache (Prefs/ficheiro) │
└────────────────────────────┼─────────────────────────────────┘
                             │ HTTPS/TLS · JWT do utilizador
┌────────────────────────────┼─────────────────────────────────┐
│  SUPABASE                  ▼                                 │
│  ┌─────────┐ ┌─────────┐ ┌────────────────────────────────┐  │
│  │ Auth    │ │ Storage │ │ Edge Functions (Deno)          │  │
│  │ Apple/  │ │ buckets │ │  · analyze-capture             │  │
│  │ Google  │ │ privados│ │  · revenuecat-webhook          │  │
│  └─────────┘ └─────────┘ │  · delete-account              │  │
│  ┌────────────────────┐  │  · export-data                 │  │
│  │ PostgreSQL + RLS   │← └───────────────┬────────────────┘  │
│  └────────────────────┘                  │                   │
└──────────────────────────────────────────┼───────────────────┘
                                           │ chaves só no servidor
                          ┌────────────────┴─────────────────┐
                          │ AIProvider (adapters)            │
                          │  Anthropic · OpenAI · Gemini     │
                          └──────────────────────────────────┘
```

**Regra invariável:** nenhuma chave de IA, `service_role` ou webhook secret existe no
cliente. O cliente fala apenas com o Supabase, autenticado com o JWT do utilizador.

### 1.2 Camadas no cliente

| Camada | Responsabilidade | Depende de |
|---|---|---|
| `presentation` (screens, widgets) | UI. Zero lógica de negócio | controllers |
| `application` (controllers, notifiers) | orquestração, estado de ecrã | repositories (interface) |
| `domain` (models, enums) | dados puros, sem I/O | — |
| `data` (repository impl, datasources) | Supabase, cache, ficheiros | domain |

Nenhum ecrã importa `supabase_flutter` directamente.

### 1.3 Injecção de dependências

Riverpod puro, sem codegen. Todos os serviços são expostos como `Provider`, o que permite
substituir qualquer implementação em testes com `ProviderScope(overrides: [...])`.
`AppEnv.useMockData` troca o grafo inteiro para repositórios mock — é assim que a UI
corre sem backend configurado.

### 1.4 Modelos de dados

Escritos à mão (classes imutáveis com `copyWith` / `fromJson` / `toJson`) em vez de
freezed + json_serializable. Motivo: elimina `build_runner` do ciclo de desenvolvimento e
do CI para um conjunto pequeno e estável de modelos. A migração para freezed, se algum dia
fizer sentido, é mecânica. A única geração de código usada é a nativa do Flutter
(`gen_l10n`, para as traduções).

### 1.5 Branding substituível

Zero ocorrências de "Relya" hardcoded fora de `lib/core/branding/brand.dart`:

```dart
class Brand {
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'Relya');
  static const tagline = ...;   // "Send anything. I'll remember."
  static const supportEmail, website, privacyUrl, termsUrl;
  static const seedColor = Color(0xFF3D5AFE);
}
```

Mudar nome / cor / URLs = editar um ficheiro, mais `env/*.json` e os assets do ícone.

---

## 2. Estrutura de pastas

```
Relya/                          # raiz do repositório
├── docs/
│   ├── ARCHITECTURE.md          # este ficheiro
│   ├── AI_PIPELINE.md           # prompts, schema, defesa contra injection
│   └── ROADMAP.md
├── supabase/
│   ├── migrations/              # SQL versionado
│   ├── functions/
│   │   ├── _shared/             # cors, auth, providers de IA, schema, quotas
│   │   ├── analyze-capture/
│   │   ├── revenuecat-webhook/
│   │   ├── delete-account/
│   │   └── export-data/
│   └── seed.sql
├── .env.example
├── .github/workflows/ci.yaml
└── mobile/
    ├── env/example.json         # --dart-define-from-file
    ├── l10n.yaml
    ├── assets/demo/
    ├── lib/
    │   ├── main.dart
    │   ├── bootstrap.dart       # init de serviços, error zone
    │   ├── app.dart             # MaterialApp.router
    │   ├── core/
    │   │   ├── branding/
    │   │   ├── config/          # app_env.dart, feature_flags.dart
    │   │   ├── design/          # tokens, tema, componentes
    │   │   ├── errors/          # AppException, Result
    │   │   ├── formatting/      # datas, moeda, tempo relativo (locale-aware)
    │   │   ├── logging/
    │   │   └── utils/
    │   ├── l10n/                # app_en.arb, app_pt.arb, app_pt_BR.arb, app_es.arb
    │   ├── navigation/          # router.dart, routes.dart, shell
    │   ├── services/            # transversais, não pertencem a uma feature
    │   │   ├── analytics/  calendar/  connectivity/  notifications/
    │   │   ├── ocr/  secure_storage/  share_intake/  supabase/
    │   ├── shared/
    │   │   ├── domain/          # LifeItem, Capture, Reminder, Entity, ...
    │   │   ├── data/            # repositórios: interface + supabase + mock
    │   │   └── widgets/
    │   └── features/
    │       ├── onboarding/  auth/  home/  inbox/  capture/  analysis/
    │       ├── upcoming/  life/  assistant/  search/  settings/  subscription/
    ├── test/                    # unit + widget
    └── integration_test/
```

Regra: uma feature nunca importa de outra feature. A partilha faz-se por `shared/` ou `core/`.

---

## 3. Database schema

PostgreSQL. **Todas** as tabelas de dados têm `user_id uuid references auth.users` e RLS
`using (auth.uid() = user_id)`. Timestamps em `timestamptz` (UTC), com uma coluna `*_tz`
(IANA) quando o fuso do próprio evento importa.

### Tabelas

| Tabela | Papel |
|---|---|
| `profiles` | 1:1 com `auth.users`. Locale, timezone, plano, quotas |
| `user_preferences` | Notificações, antecedências, quiet hours, política de retenção |
| `captures` | Tudo o que entrou (share, foto, PDF, texto). Estado do pipeline |
| `attachments` | Ficheiros no Storage ligados a um capture |
| `life_items` | **Tabela central**: o que a IA percebeu, depois de confirmado |
| `reminders` | Lembretes agendados (locais e/ou push) |
| `entities` | Life Graph: vehicle, home, product, person, org, subscription, document, trip |
| `entity_relationships` | Arestas do grafo (`belongs_to`, `covers`, `contains`) |
| `devices` | Push tokens, plataforma, locale |
| `extraction_feedback` | Correcções do utilizador ("Relya got this wrong") |
| `ai_usage` | Tokens, custo, modelo, latência por capture. Base do cost control |
| `audit_events` | Trilho de eventos sensíveis (export, delete, acesso a documento) |

### `life_items` (núcleo)

```sql
id              uuid primary key
user_id         uuid not null
capture_id      uuid                 -- null = criado manualmente
type            life_item_type       -- enum, ver secção 8
title           text not null
description     text
status          life_item_status     -- pending_confirmation | active | done | snoozed | archived
start_at        timestamptz
start_tz        text                 -- IANA, ex. 'Europe/Lisbon'
end_at          timestamptz
deadline_at     timestamptz
all_day         boolean default false
amount          numeric(14,2)
currency        char(3)
location        text
organization    text
confidence      real                 -- 0..1 da extracção
source_language text
metadata        jsonb default '{}'   -- campos específicos do tipo
search_vector   tsvector generated   -- pesquisa universal
created_at, updated_at
```

`metadata` é o ponto de extensão: um voo guarda `{flight_number, terminal, pnr}`, uma
garantia guarda `{warranty_months, receipt_attachment_id}`, sem alterar o schema.

### Índices

`(user_id, deadline_at)`, `(user_id, start_at)`, `(user_id, status)`, GIN em
`search_vector` e em `metadata`.

### Storage

Bucket privado `captures`, caminho `{user_id}/{capture_id}/{filename}`. Policy: só o dono
lê e escreve. URLs sempre assinados e de curta duração.

---

## 4. Packages / dependências

| Package | Porquê |
|---|---|
| `flutter_riverpod` | Estado + DI, testável, sem codegen |
| `go_router` | Rotas declarativas, deep links, share-intake por rota |
| `supabase_flutter` | Auth, DB, Storage, Edge Functions |
| `sign_in_with_apple`, `google_sign_in` | Login nativo (obrigatório na App Store) |
| `receive_sharing_intent` | Share Sheet iOS + Share Intent Android (**core**) |
| `google_mlkit_text_recognition` | OCR no dispositivo — corta custo e exposição de dados |
| `image_picker`, `file_picker` | Câmara, galeria, PDF |
| `flutter_local_notifications`, `timezone`, `flutter_timezone` | Lembretes correctos ao viajar |
| `add_2_calendar` | Adiciona ao calendário do sistema sem pedir permissão de leitura |
| `purchases_flutter` | RevenueCat |
| `posthog_flutter` | Analytics (self-host possível, GDPR-friendly) |
| `sentry_flutter` | Crash reporting |
| `flutter_secure_storage` | Keychain / Keystore |
| `connectivity_plus` | Modo offline |
| `intl` | Formatação regional |

Dev: `flutter_lints`, `mocktail`, `integration_test`.

---

## 5. Mapa de ecrãs

```
/onboarding            3 slides + demo interactiva
/auth                  Criar conta ou Entrar, no mesmo ecrã
                       Apple / Google / email+password / magic link

(shell com bottom navigation)
/home                  "O que é importante agora?" + campo de pergunta
/inbox                 Captures a precisar de confirmação
/upcoming              Calendário mensal + agenda do dia, ou timeline em lista
/life                  Entidades: casa, carro, documentos, compras, saúde, viagens
/life/:entityId        Detalhe de uma entidade
/assistant             Chat

(fora do shell — modais / full-screen)
/capture               Folha de opções: scan, foto, galeria, PDF, texto, manual
/capture/manual        Criação manual
/capture/text          Colar texto
/analysis/:captureId   ⭐ ECRÃ DE CONFIRMAÇÃO — o coração do produto
/item/:id              Detalhe, editar, "isto está errado"
/search                Pesquisa universal
/settings              Hub da conta: perfil, plano, quota, preferências, dados
  /settings/appearance     Modo claro/escuro/sistema + 7 paletas
  /settings/notifications  /privacy
/paywall               Contextual, nunca antes do primeiro momento de valor
```

**~23 ecrãs no MVP.** O ecrã crítico é `/analysis/:captureId`: é onde a promessa
"Found 3 important things → Add all" se cumpre.

---

## 6. Navegação

`GoRouter` com um `StatefulShellRoute.indexedStack` para as 5 áreas (Home, Inbox,
Upcoming, Life, Assistant) — cada tab mantém a sua própria pilha.

- **Redirects**: estado de autenticação → `/onboarding` (primeiro arranque) → `/auth`
  (sem sessão) → `/home`.
- **Share intake**: `receive_sharing_intent` entrega o payload, cria-se um capture local
  e navega-se para `/analysis/:id`. Funciona com a app fechada (cold start) e em background.
- **Botão de captura** persistente no shell, sempre a um toque.
- **Deep links** de notificações: `relya://item/{id}`.

---

## 7. Design system

Tokens em `core/design/tokens/`, tema em `core/design/theme/`, componentes em
`core/design/components/`. Nenhum widget usa cores ou espaçamentos literais.

- **Espaçamento**: escala de 4pt (`AppSpacing.xs 4 … xxl 48`). Muito espaço vazio.
- **Raios**: 12 (controlos), 16 (cartões), 28 (folhas modais).
- **Cor**: cada tema (`AppSkin`) traz a sua paleta completa — acento, gradiente
  e as quatro superfícies — em versão clara e escura, mais
  `AppSemanticColors` (success / warning / danger / info) exposto via `ThemeExtension`.
  As cores semânticas são fixas em todas as paletas: se "em atraso" fosse turquesa
  num tema e vermelho noutro, a cor deixava de significar alguma coisa.
- **Elevação**: praticamente nula. A separação faz-se por cor de superfície e por espaço,
  não por sombra.
- **Tipografia**: escala de 9 estilos, sensível a `MediaQuery.textScaler` (Dynamic Type).
- **Movimento**: 150–250 ms, `Curves.easeOutCubic`. Nada decorativo.
- **Componentes**: `AppScaffold`, `SectionHeader`, `LifeItemTile`, `ConfidenceBadge`,
  `EmptyState`, `AppButton`, `AppCard`, `ProgressiveLoader`.
- Dark mode é primeira classe, não uma inversão.

O tom de voz vive no `l10n`: curto, calmo, sem exclamações.
"Added. I'll remind you tomorrow."

---

## 8. Modelo de dados (domínio)

```
Capture ──1:N── Attachment
   │
   └──1:N── LifeItem ──1:N── Reminder
                 │
                 └──N:1── Entity ──N:N── Entity   (via EntityRelationship)
```

**`LifeItemType`** (extensível, com `other` como fallback):
`appointment, bill, subscription, purchase, returnDeadline, warranty, travel, document,
insurance, vehicle, home, event, delivery, reservation, education, task, other`

**`CaptureStatus`**: `queued → processing → needsConfirmation → completed`
(+ `failed`, `archived`). Espelha os estados do Inbox pedidos na secção 25.

**`ExtractionResult`**: o objecto validado que vem da IA (secção 19), com confiança por
campo além da global — é o que alimenta o ecrã de confirmação.

**`Reminder`**: `{ itemId, fireAt (UTC), timezone, offsetDescription, channel, status }`.
Guardar sempre UTC + IANA e recalcular ao detectar mudança de fuso.

---

## 9. Arquitectura de processamento de IA

Detalhe completo em [`AI_PIPELINE.md`](AI_PIPELINE.md). Resumo:

```
input (imagem | pdf | texto | url)
  │
  ├─ [cliente] hash SHA-256 → já analisado? → devolve resultado em cache
  ├─ [cliente] OCR local (MLKit) se for imagem
  │     → texto extraído + metadata (locale, timezone, data de hoje)
  │
  ├─ upload do original só se: OCR falhou, é PDF, ou o utilizador quer guardar o original
  │
  └─ POST /functions/v1/analyze-capture      (JWT do utilizador)
        │
        ├─ rate limit + quota do plano → 429 se excedido
        ├─ escolha de modelo: texto curto → modelo pequeno
        │                     imagem ou ambíguo → multimodal
        ├─ prompt em 3 blocos separados e rotulados:
        │     SYSTEM   (regras, nunca sobreponíveis)
        │     CONTEXT  (locale, timezone, hoje, entidades já conhecidas)
        │     DOCUMENT (<untrusted_content> … </untrusted_content>)
        ├─ resposta forçada a JSON Schema estrito
        ├─ validação → normalização de datas e moedas → clamp de confiança
        ├─ grava ai_usage (tokens, custo, modelo, ms)
        └─ devolve ExtractionResult[]  (N items por capture)
              │
              └─ ecrã de confirmação → utilizador aceita ou corrige
                    → life_items + reminders
```

**Defesas obrigatórias** (secção 52): o conteúdo do documento nunca é tratado como
instrução; a função nunca escreve na base de dados com base no que o documento pede; não
existem ferramentas destrutivas neste caminho; qualquer "ignore previous instructions" é
apenas texto extraído.

**Datas** (secção 21): a IA devolve `date_raw` (como aparece), `date_iso` e
`ambiguous: bool`. `12/10` com locale `pt-PT` → `2026-10-12`; com `en-US` → `2026-12-10`.
Se o locale não resolver a ambiguidade, `ambiguous: true` e a UI pergunta. Nunca assumir
formato americano.

**Confiança** (secção 20): `>= 0.85` mostra normalmente · `0.55–0.85` pede confirmação
destacada · `< 0.55` mostra "Não consegui perceber isto completamente", com o texto
original à vista.

**Provider-agnóstico** (secção 39): `interface AIProvider { extract(input) }` com
`AnthropicProvider` (default), `OpenAIProvider` e `GeminiProvider`. Escolhido pela env var
`AI_PROVIDER`, sem alterações de código.

---

## 10. Roadmap de implementação

Segue a ordem da secção 81 da especificação.

| Fase | Conteúdo |
|---|---|
| 1 | Estrutura técnica, env, branding, core |
| 2 | Design system (tokens, tema, componentes) |
| 3 | Navegação + todos os ecrãs com dados mock |
| 4 | Autenticação (Apple, Google, magic link) |
| 5 | Supabase: schema, RLS, repositórios reais |
| 6 | Capture (câmara, galeria, PDF, texto, manual) |
| 7 | Share extension iOS + Android |
| 8 | Extracção por IA (edge function + adapters) |
| 9 | Fluxo de confirmação |
| 10 | Lembretes + integração com calendário |
| 11 | Subscrições (RevenueCat + paywall) |
| 12 | Localização (en, pt-PT, pt-BR, es) |
| 13 | Analytics + error reporting |
| 14 | Testes (unit, widget, fixtures de IA) |
| 15 | Preparação App Store / Play Store |

O estado actual de cada fase está em [`ROADMAP.md`](ROADMAP.md).
