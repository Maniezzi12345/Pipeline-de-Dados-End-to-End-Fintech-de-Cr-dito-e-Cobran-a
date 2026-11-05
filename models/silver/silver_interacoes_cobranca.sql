select
    _id                                          as interacao_id,
    cast(cliente_id as integer)                  as cliente_id,
    cast(contrato_id as integer)                 as contrato_id,
    cast(parcela_id as integer)                  as parcela_id,
        case
        when initcap(trim(canal)) in ('Whatsapp', 'Wpp')                        then 'Whatsapp'
        when initcap(trim(canal)) in ('Sms')                                    then 'Sms'
        when initcap(trim(canal)) in ('Email', 'E-Mail')                        then 'Email'
        when initcap(trim(canal)) in ('Ligacao', 'Ligação', 'Telefone')         then 'Ligacao'
        else initcap(trim(canal))
    end as canal,
    upper(trim(operadora))                       as operadora,
    assunto,
    resultado,
    tags,
    ligacao,
    cast(tentativa as integer)                   as tentativa,
    cast(dias_atraso as integer)                 as dias_atraso,

    -- data_hora: aceita formato brasileiro e internacional
    case
        when data_hora is null or trim(data_hora) = '' then null
        when data_hora ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}'
            then to_timestamp(data_hora, 'DD/MM/YYYY HH24:MI:SS')::timestamp
        when data_hora ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}'
            then to_timestamp(data_hora, 'DD/MM/YYYY HH24:MI')::timestamp
        when data_hora ~ '^\d{2}/\d{2}/\d{4}$'
            then to_timestamp(data_hora, 'DD/MM/YYYY')::timestamp
        else cast(data_hora as timestamp)
    end                                             as data_hora,

    -- respondeu: Sim / Não
    case
        when respondeu is null then null
        when lower(cast(respondeu as text)) in ('true','t','1','sim','s') then 'Sim'
        else 'Não'
    end                                             as respondeu,

    -- dados de dentro do JSON "mensagem": {"lida": true, "entregue": true, "template": "..."}
    case
        when mensagem is null then null
        when lower(cast(mensagem as jsonb) ->> 'entregue') in ('true','t','1','sim','s') then 'Sim'
        else 'Não'
    end                                             as entregue,
    case
        when mensagem is null then null
        when lower(cast(mensagem as jsonb) ->> 'lida') in ('true','t','1','sim','s') then 'Sim'
        else 'Não'
    end                                             as mensagem_lida,
    cast(mensagem as jsonb) ->> 'template'       as mensagem_template,

    -- data da promessa (JSON "promessa")
    case
        when coalesce(cast(promessa as jsonb) ->> 'data_promessa',
                      cast(promessa as jsonb) ->> 'data') is null then null
        when coalesce(cast(promessa as jsonb) ->> 'data_promessa',
                      cast(promessa as jsonb) ->> 'data') ~ '^\d{2}/\d{2}/\d{4}'
            then to_date(left(coalesce(cast(promessa as jsonb) ->> 'data_promessa',
                                       cast(promessa as jsonb) ->> 'data'), 10), 'DD/MM/YYYY')
        else cast(left(coalesce(cast(promessa as jsonb) ->> 'data_promessa',
                                cast(promessa as jsonb) ->> 'data'), 10) as date)
    end                                             as data_promessa,

    -- valor da promessa (JSON "promessa")
    cast(nullif(
        regexp_replace(
            replace(
                coalesce(
                    cast(promessa as jsonb) ->> 'valor_promessa',
                    cast(promessa as jsonb) ->> 'valor'
                ),
            ',', '.'),
        '[^0-9.]', '', 'g'),
    '') as numeric(12,2))                           as valor_promessa,

    -- metadado do Airbyte (CDC): data da última alteração na origem
    cast(_ab_cdc_updated_at as timestamptz)      as data_atualizacao_origem

from {{ source('cobranca', 'interacoes_cobranca') }} ic
where _ab_cdc_deleted_at is null   -- só registros que ainda existem na origemic 