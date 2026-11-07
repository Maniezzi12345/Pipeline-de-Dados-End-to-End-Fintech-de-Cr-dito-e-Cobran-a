with interacoes as (
    select *
    from {{ ref('silver_interacoes_cobranca') }}
    where interacao_id not like '%-R'
),

interacoes_com_cliente as (
    select
        si.interacao_id,
        coalesce(si.cliente_id, sc.cliente_id)          as cliente_id,
        si.contrato_id,
        si.parcela_id,
        si.canal,
        si.data_hora,
        cast(si.data_hora as date)                      as data_contato,
        si.tentativa,
        si.dias_atraso,
        si.respondeu,
        si.resultado,
        si.data_promessa,
        si.valor_promessa,

        case
            when si.canal in ('Whatsapp', 'Sms') and si.respondeu = 'Sim'
                then true
            when si.canal = 'Ligacao' and cast(si.ligacao as jsonb) ->> 'atendeu' = 'true'
                then true
            else false
        end                                             as contato_efetivo

    from interacoes as si
    left join {{ ref('silver_contratos') }} as sc
        on si.contrato_id = sc.contrato_id
),

pagamentos as (
    select
        fp.parcela_id,
        fp.data_pagamento
    from {{ ref('fct_pagamento') }} as fp
)

select
    i.*,

    case
        when i.data_promessa is null                  then null
        when pg.data_pagamento <= i.data_promessa     then true
        else false
    end                                               as promessa_cumprida

from interacoes_com_cliente i
left join pagamentos pg
    on i.parcela_id = pg.parcela_id