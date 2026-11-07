with pagamentos as (
    select
        pagamento_id,
        parcela_id,
        valor_pago,
        data_pagamento,
        forma_pagamento
    from {{ ref('silver_pagamentos') }}
),

pagamentos_numerados as (
    select
        *,
        row_number() over (
            partition by parcela_id
            order by pagamento_id
        ) as rn
    from pagamentos
),

parcelas as (
    select
        parcela_id,
        contrato_id,
        cliente_id,
        data_vencimento
    from {{ ref('fct_parcela') }}
),

base as (
    select
        pg.pagamento_id,
        pg.parcela_id,
        p.contrato_id,
        p.cliente_id,
        p.data_vencimento,
        pg.data_pagamento,
        pg.valor_pago,
        pg.forma_pagamento,
        greatest(pg.data_pagamento - p.data_vencimento, 0) as dias_atraso
    from pagamentos_numerados pg
    join parcelas p
        on pg.parcela_id = p.parcela_id
    where pg.rn = 1
)

select
    *,
    (dias_atraso > 0) as recuperado
from base