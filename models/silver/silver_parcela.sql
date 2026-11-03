select
    cast(p.parcela_id as integer)                      as parcela_id,
    cast(p.contrato_id as integer)                     as contrato_id,
    cast(nullif(
        case
            when cast(p.valor_parcela as text) like '%,%'
                then replace(regexp_replace(cast(p.valor_parcela as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(p.valor_parcela as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                     as valor_parcela,
    cast(p.numero_parcela as integer)                  as numero_parcela,

    -- status: padroniza as variações (A_VENCER, a vencer, PAGA_COM_ATRASO, paga com atraso...)
    case lower(trim(replace(cast(p.status_parcela as text), '_', ' ')))
        when 'a vencer'        then 'A vencer'
        when 'vencida'         then 'Vencida'
        when 'paga'            then 'Paga'
        when 'paga com atraso' then 'Paga com atraso'
        when ''                then null
        else 'Não identificado'
    end                                                as status_parcela,

    -- data de vencimento: aceita formato brasileiro e internacional
    case
        when p.data_vencimento is null or trim(cast(p.data_vencimento as text)) = '' then null
        when cast(p.data_vencimento as text) ~ '^\d{2}/\d{2}/\d{4}'
            then to_date(left(cast(p.data_vencimento as text), 10), 'DD/MM/YYYY')
        else cast(left(cast(p.data_vencimento as text), 10) as date)
    end                                                as data_vencimento
from {{ source('cobranca', 'parcelas') }} p