with interacoes as (
    select * from {{ref ('silver_interacoes_cobranca')}} where interacao_id not like '%R'
),

interacoes_com_cliente as (
   SELECT
       si.interacao_id,
       si.cliente_id,
       si.contrato_id,
       si.parcela_id,
       si.canal,
       si.operadora,
       si.assunto,
       si.resultado,
       si.tags,
       si.ligacao,
       si.tentativa,
       si.dias_atraso,
       si.data_hora,
       si.respondeu,
       si.entregue,
       si.mensagem_lida,
       si.mensagem_template,
       si.data_promessa,
       si.valor_promessa,
       si.data_atualizacao,
       sc.produto,
       sc.qtd_parcela,
       sc.valor_liberado,
       sc.valor_parcela,
       sc.status_contrato,
       sc.data_contratacao,
       sc.taxa_juros_mensal,
       sc.taxa_juros_mensal_pct


FROM {{ ref('silver_interacoes_cobranca') }} AS si

LEFT JOIN {{ ref('silver_contratos') }} AS sc
    ON si.contrato_id_id = sc.contrato_id
)

pagamentos as (
    -- só as colunas necessárias da fct_pagamento
)

select
    -- passos 4, 5 e 6
from interacoes_com_cliente i
left join pagamentos pg
    on ...