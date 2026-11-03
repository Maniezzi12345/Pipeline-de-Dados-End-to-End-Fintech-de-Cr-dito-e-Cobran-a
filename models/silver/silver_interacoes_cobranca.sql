select
    initcap(trim(canal))                                as canal,
    cast(nullif(
        case
            when cast(custo_total as text) like '%,%'
                then replace(regexp_replace(cast(custo_total as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(custo_total as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                      as custo_total,
    cast(nullif(
        case
            when cast(custo_unitario as text) like '%,%'
                then replace(regexp_replace(cast(custo_unitario as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(custo_unitario as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                      as custo_unitario,
    cast(qtd_acionamentos as integer)                   as qtd_acionamentos,
    to_date(left(cast(mes as text), 7), 'YYYY-MM')      as mes_referencia          -- 2026-10-01
from {{ source('cobranca', 'custos_cobranca') }}