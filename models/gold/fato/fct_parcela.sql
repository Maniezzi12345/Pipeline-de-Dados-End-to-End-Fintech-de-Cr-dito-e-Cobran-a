with parcelas as (
    select distinct *
    from {{ ref('silver_parcelas') }}
),

pagamentos_numerados as (
    select
        *,
        row_number() over (partition by parcela_id order by pagamento_id) as ordem
    from {{ ref('silver_pagamentos') }}
),

pagamentos as (
    select *
    from pagamentos_numerados
    where ordem = 1
)

select
    p.parcela_id,
    p.contrato_id,
    c.cliente_id,
    c.produto,
    p.numero_parcela,
    p.data_vencimento,
    p.valor_parcela,
    p.status_parcela,
    pg.data_pagamento,
    pg.valor_pago,
    pg.forma_pagamento,
    (p.status_parcela = 'Vencida') as em_atraso,
    case
        when p.status_parcela = 'Vencida' 
             then cast ('{{ var("data_referencia")}}' as date ) - p.data_vencimento
    end  as dias_em_atraso
from parcelas p

join {{ ref('silver_contratos') }} c
    on p.contrato_id = c.contrato_id

left join pagamentos pg
    on p.parcela_id = pg.parcela_id

