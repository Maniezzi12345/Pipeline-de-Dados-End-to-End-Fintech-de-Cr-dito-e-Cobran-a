PERGUNTAS = {
    "Quem devo cobrar primeiro hoje?": """
        select posicao_fila, primeiro_nome, faixa_risco, valor_em_atraso,
               dias_atraso_mais_antigo, acao_sugerida
        from analytics_gold.gold_fila_cobranca
        order by posicao_fila
        limit 10
    """,
    "Quantos clientes há em cada ação?": """
        select acao_sugerida, count(*) as clientes, sum(valor_em_atraso) as valor_total
        from analytics_gold.gold_fila_cobranca
        group by acao_sugerida
        order by clientes desc
    """,
    "Quanto temos em atraso por faixa de risco?": """
        select faixa_risco, count(*) as clientes, sum(valor_em_atraso) as valor_total
        from analytics_gold.gold_fila_cobranca
        group by faixa_risco
        order by faixa_risco
    """,
    "Quais clientes quebraram promessa?": """
        select cliente_id, primeiro_nome, valor_em_atraso, dias_atraso_mais_antigo
        from analytics_gold.gold_cliente_360
        where promessa_quebrada
        order by valor_em_atraso desc
        limit 20
    """,
    "Quem devo pausar por excesso de contato?": """
        select cliente_id, primeiro_nome, qtd_contatos_ultimos_7_dias, valor_em_atraso
        from analytics_gold.gold_cliente_360
        where qtd_contatos_ultimos_7_dias >= 3 and valor_em_atraso > 0
        order by qtd_contatos_ultimos_7_dias desc
    """,
}