with contratos as (
    select
        sc.contrato_id,
        sc.cliente_id,
        sc.produto,
        sc.data_contratacao,
        sc.valor_liberado,
        sc.taxa_juros_mensal,
        sc.qtd_parcelas,
        sc.valor_parcela,
        sc.status_contrato
    from {{ ref('silver_contratos') }} sc
),
atraso_contrato as (
    select
        fp.contrato_id,
        max(fp.dias_em_atraso) as max_dias_atraso
    from {{ ref('fct_parcela') }} fp
    group by fp.contrato_id
)
select
    c.*,
    case when a.max_dias_atraso > 90 then true else false end as inadimplente
from contratos c
left join atraso_contrato a on c.contrato_id = a.contrato_id