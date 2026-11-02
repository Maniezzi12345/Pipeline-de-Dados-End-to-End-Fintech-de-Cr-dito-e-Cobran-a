select
    cast(cliente_id as integer)                            as cliente_id,
    lower(trim(dominio_email))                             as dominio_email,
    split_part(lower(trim(dominio_email)), '.', 1)         as provedor_email,   -- terra.com.br -> terra
    upper(trim(uf))                                        as uf,
    initcap(trim(nome))                                    as nome,
    split_part(initcap(trim(nome)), ' ', 1)                as primeiro_nome,
    nullif(trim(substr(initcap(trim(nome)),
        length(split_part(trim(nome), ' ', 1)) + 2)), '')  as sobrenome,
    initcap(trim(cidade))                                  as cidade,
    trim(faixa_risco)                                      as faixa_risco,
    cast(nullif(
        case
            when cast(renda_mensal as text) like '%,%'                    -- formato BR: R$ 5.962,34
                then replace(regexp_replace(cast(renda_mensal as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(renda_mensal as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                         as renda_mensal,
    case
        when data_cadastro is null or trim(cast(data_cadastro as text)) = '' then null
        when cast(data_cadastro as text) ~ '^\d{2}/\d{2}/\d{4}'
            then to_date(left(cast(data_cadastro as text), 10), 'DD/MM/YYYY')
        else cast(left(cast(data_cadastro as text), 10) as date)
    end                                                    as data_cadastro
from {{ source('cobranca', 'clientes') }}