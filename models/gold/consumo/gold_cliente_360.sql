with parcelas as (
    select
        cliente_id,
        count(*) filter (where em_atraso)                        as qtd_parcelas_em_atraso,
        coalesce(sum(valor_parcela) filter (where em_atraso), 0) as valor_em_atraso,
        coalesce(max(dias_em_atraso), 0)                         as dias_atraso_mais_antigo
    from {{ ref('fct_parcela') }}
    group by cliente_id
),
acionamentos as (
    select
        cliente_id,
        bool_or(data_promessa >= cast('{{ var("data_referencia") }}' as date) and not promessa_cumprida) as promessa_ativa,
        bool_or(data_promessa <  cast('{{ var("data_referencia") }}' as date) and not promessa_cumprida) as promessa_quebrada,
        max(data_hora) as data_ultimo_contato,
        count(*) filter (where data_contato > cast('{{ var("data_referencia") }}' as date) - 7) as qtd_contatos_ultimos_7_dias
    from {{ ref('fct_acionamento') }}
    group by cliente_id
)
select
    c.cliente_id,
    c.nome,
    c.primeiro_nome,
    c.cidade,
    c.uf,
    c.faixa_risco,
    coalesce(p.qtd_parcelas_em_atraso, 0)      as qtd_parcelas_em_atraso,
    coalesce(p.valor_em_atraso, 0)             as valor_em_atraso,
    coalesce(p.dias_atraso_mais_antigo, 0)     as dias_atraso_mais_antigo,
    coalesce(a.promessa_ativa, false)          as promessa_ativa,
    coalesce(a.promessa_quebrada, false)       as promessa_quebrada,
    a.data_ultimo_contato,
    coalesce(a.qtd_contatos_ultimos_7_dias, 0) as qtd_contatos_ultimos_7_dias
from {{ ref('dim_clientes') }} c
left join parcelas p     on c.cliente_id = p.cliente_id
left join acionamentos a on c.cliente_id = a.cliente_id