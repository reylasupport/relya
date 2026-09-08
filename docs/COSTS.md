# Custos

Quanto custa correr a Relya, e onde ver isso sem esperar pela fatura.

---

## Onde estão os números

Cada chamada ao modelo grava uma linha em `ai_usage`: tokens de entrada e
saída, custo em USD, latência, se usou imagem e se teve sucesso. A tabela de
preços vive junto de cada adapter
([`_shared/ai/`](../supabase/functions/_shared/ai)), para não haver duas fontes
de verdade a divergir.

A migração [`0005_cost_views.sql`](../supabase/migrations/0005_cost_views.sql)
cria duas vistas. Corre-as no SQL editor da Supabase, autenticado como
serviço, para veres todos os utilizadores.

```sql
-- A forma da fatura ao longo do tempo
select * from ai_cost_daily limit 30;

-- A pergunta que decide o preço da subscrição
select
  month,
  count(*)                       as utilizadores,
  round(avg(cost_usd), 4)        as custo_medio,
  round(percentile_cont(0.5) within group (order by cost_usd)::numeric, 4)
                                 as mediana,
  round(percentile_cont(0.95) within group (order by cost_usd)::numeric, 4)
                                 as p95,
  round(max(cost_usd), 4)        as pior_caso
from ai_cost_per_user_month
group by month
order by month desc;
```

A **mediana** é o número a olhar, não a média: um utilizador que digitalizou
400 páginas num mês distorce a média e não representa ninguém. O **p95** é o
que dita se a quota do plano gratuito está bem calibrada.

---

## Antes de abrir ao público

Três números, e uma decisão em cada um.

| Número | Onde | O que decide |
|---|---|---|
| Custo mediano de um utilizador gratuito por mês | `ai_cost_per_user_month` | Se o plano gratuito é sustentável |
| Custo p95 | a query acima | Se a quota está bem calibrada |
| Custo por captura | `cost_per_capture_usd` | Se vale a pena o OCR local poupar mais |

Se o custo mediano de um utilizador gratuito se aproximar da margem do plano
pago, há três travões já implementados que se podem apertar sem tocar em
código de produto:

1. **Quota** — `consume_capture_quota()` já limita capturas por mês.
2. **Modelo pequeno** — `preferSmallModel` já evita o modelo grande abaixo de
   1500 caracteres. O limiar é um número.
3. **OCR local** — quanto mais texto o ML Kit resolver no dispositivo, menos
   chamadas multimodais. A taxa de sucesso do OCR é o que mais move o custo.

---

## Alertas

Não há alertas automáticos. O mínimo antes de escalar é uma consulta semanal
às vistas acima; o passo seguinte seria uma função agendada que compara o
custo dos últimos sete dias com os sete anteriores e envia um email quando
sobe mais de 50%. Ainda não está escrito, e está registado aqui para não ser
redescoberto como esquecimento.
