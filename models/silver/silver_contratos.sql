select
    cast(contrato_id as integer)                        as contrato_id,
    cast(cliente_id as integer)                         as cliente_id,
    -- produto: normaliza rótulos diferentes para a mesma coisa
    case
        when translate(lower(trim(replace(cast(produto as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') like 'consignado%'
            then 'Consignado'
        when translate(lower(trim(replace(cast(produto as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') like 'antecip%fgts'
            then 'Antecipação FGTS'
        when translate(lower(trim(replace(cast(produto as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') like 'refin%'
            then 'Refinanciamento'
        when translate(lower(trim(replace(cast(produto as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') = 'credito pessoal'
            then 'Crédito Pessoal'
        when produto is null or trim(cast(produto as text)) = ''
            then null
        else 'Não identificado'
    end                                                 as produto,
    cast(qtd_parcelas as integer)                       as qtd_parcelas,
    cast(nullif(
        case
            when cast(valor_liberado as text) like '%,%'
                then replace(regexp_replace(cast(valor_liberado as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(valor_liberado as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                      as valor_liberado,
    cast(nullif(
        case
            when cast(valor_parcela as text) like '%,%'
                then replace(regexp_replace(cast(valor_parcela as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(valor_parcela as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                      as valor_parcela,
    case lower(trim(status_contrato))
        when 'quitado'      then 'Quitado'
        when 'inadimplente' then 'Inadimplente'
        when 'atrasado'     then 'Atrasado'
        when 'ativo'        then 'Ativo'
        else 'Não identificado'
    end                                                 as status_contrato,
    case
        when data_contratacao is null or trim(cast(data_contratacao as text)) = '' then null
        when cast(data_contratacao as text) ~ '^\d{2}/\d{2}/\d{4}'
            then to_date(left(cast(data_contratacao as text), 10), 'DD/MM/YYYY')
        else cast(left(cast(data_contratacao as text), 10) as date)
    end                                                 as data_contratacao,
    -- taxa de juros: aceita "2,90%", "2.9", "0.029"
    case
        when nullif(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g'), '') is null
            then null
        when cast(taxa_juros_mensal as text) like '%\%%'
          or cast(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g') as numeric) > 1
            then round(cast(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g') as numeric) / 100, 4)
        else round(cast(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g') as numeric), 4)
    end                                                 as taxa_juros_mensal,      -- 0.0290 (decimal)
    case
        when nullif(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g'), '') is null
            then null
        when cast(taxa_juros_mensal as text) like '%\%%'
          or cast(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g') as numeric) > 1
            then round(cast(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g') as numeric), 2)
        else round(cast(regexp_replace(replace(cast(taxa_juros_mensal as text), ',', '.'), '[^0-9.]', '', 'g') as numeric) * 100, 2)
    end                                                 as taxa_juros_mensal_pct   -- 2.90 (%)
from {{ source('cobranca', 'contratos') }}