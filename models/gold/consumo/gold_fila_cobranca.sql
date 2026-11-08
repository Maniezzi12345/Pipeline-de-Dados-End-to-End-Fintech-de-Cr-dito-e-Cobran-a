with devedores as (
    select *
    from {{ ref('gold_cliente_360') }}
    where valor_em_atraso > 0
),
score as (
    select
        *,
        round(cast(
              40 * valor_em_atraso / max(valor_em_atraso) over ()
            + 30 * least(dias_atraso_mais_antigo, 90) / 90.0
            + 20 * case faixa_risco
                       when 'A' then 0.2 when 'B' then 0.4 when 'C' then 0.6
                       when 'D' then 0.8 when 'E' then 1.0 else 0.6
                   end
            + 10 * case when promessa_quebrada then 1 else 0 end
        as numeric), 1) as score_prioridade
    from devedores
)
select
    row_number() over (order by score_prioridade desc) as posicao_fila,
    cliente_id,
    primeiro_nome,
    faixa_risco,
    valor_em_atraso,
    dias_atraso_mais_antigo,
    score_prioridade,
    case
        when promessa_ativa                   then 'Aguardar promessa'
        when qtd_contatos_ultimos_7_dias >= 3 then 'Pausar'
        when dias_atraso_mais_antigo > 60     then 'Ligar'
        else 'WhatsApp'
    end as acao_sugerida
from score