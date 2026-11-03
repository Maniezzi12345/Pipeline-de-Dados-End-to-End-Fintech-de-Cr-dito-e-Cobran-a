select
    ic._id                                          as interacao_id,
    cast(ic.cliente_id as integer)                  as cliente_id,
    cast(ic.contrato_id as integer)                 as contrato_id,
    cast(ic.parcela_id as integer)                  as parcela_id,
    initcap(trim(ic.canal))                         as canal,
    upper(trim(ic.operadora))                       as operadora,
    ic.assunto,
    ic.resultado,
    ic.tags,
    ic.ligacao,
    cast(ic.tentativa as integer)                   as tentativa,
    cast(ic.dias_atraso as integer)                 as dias_atraso,

    -- data_hora: aceita formato brasileiro e internacional
    case
        when ic.data_hora is null or trim(ic.data_hora) = '' then null
        when ic.data_hora ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}'
            then to_timestamp(ic.data_hora, 'DD/MM/YYYY HH24:MI:SS')::timestamp
        when ic.data_hora ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}'
            then to_timestamp(ic.data_hora, 'DD/MM/YYYY HH24:MI')::timestamp
        when ic.data_hora ~ '^\d{2}/\d{2}/\d{4}$'
            then to_timestamp(ic.data_hora, 'DD/MM/YYYY')::timestamp
        else cast(ic.data_hora as timestamp)
    end                                             as data_hora,

    -- respondeu: Sim / Não
    case
        when ic.respondeu is null then null
        when lower(cast(ic.respondeu as text)) in ('true','t','1','sim','s') then 'Sim'
        else 'Não'
    end                                             as respondeu,

    -- dados de dentro do JSON "mensagem": {"lida": true, "entregue": true, "template": "..."}
    case
        when ic.mensagem is null then null
        when lower(cast(ic.mensagem as jsonb) ->> 'entregue') in ('true','t','1','sim','s') then 'Sim'
        else 'Não'
    end                                             as entregue,
    case
        when ic.mensagem is null then null
        when lower(cast(ic.mensagem as jsonb) ->> 'lida') in ('true','t','1','sim','s') then 'Sim'
        else 'Não'
    end                                             as mensagem_lida,
    cast(ic.mensagem as jsonb) ->> 'template'       as mensagem_template,

    -- data da promessa (JSON "promessa")
    case
        when coalesce(cast(ic.promessa as jsonb) ->> 'data_promessa',
                      cast(ic.promessa as jsonb) ->> 'data') is null then null
        when coalesce(cast(ic.promessa as jsonb) ->> 'data_promessa',
                      cast(ic.promessa as jsonb) ->> 'data') ~ '^\d{2}/\d{2}/\d{4}'
            then to_date(left(coalesce(cast(ic.promessa as jsonb) ->> 'data_promessa',
                                       cast(ic.promessa as jsonb) ->> 'data'), 10), 'DD/MM/YYYY')
        else cast(left(coalesce(cast(ic.promessa as jsonb) ->> 'data_promessa',
                                cast(ic.promessa as jsonb) ->> 'data'), 10) as date)
    end                                             as data_promessa,

    -- valor da promessa (JSON "promessa")
    cast(nullif(
        regexp_replace(
            replace(
                coalesce(
                    cast(ic.promessa as jsonb) ->> 'valor_promessa',
                    cast(ic.promessa as jsonb) ->> 'valor'
                ),
            ',', '.'),
        '[^0-9.]', '', 'g'),
    '') as numeric(12,2))                           as valor_promessa,

    -- metadado do Airbyte (CDC): data da última alteração na origem
    cast(ic._ab_cdc_updated_at as timestamptz)      as data_atualizacao_origem

from {{ source('cobranca', 'interacoes_cobranca') }} ic
where ic._ab_cdc_deleted_at is null   -- só registros que ainda existem na origemic 