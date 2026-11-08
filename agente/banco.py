import os
import pandas as pd
import psycopg2
from dotenv import load_dotenv

load_dotenv()


def conectar():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


def consultar(sql, parametros=None):
    conexao = conectar()
    cursor = conexao.cursor()
    cursor.execute(sql, parametros)
    colunas = [coluna[0] for coluna in cursor.description]
    linhas = cursor.fetchall()
    cursor.close()
    conexao.close()
    return pd.DataFrame(linhas, columns=colunas)


def buscar_fila(limite=10):
    return consultar("""
        select posicao_fila, cliente_id, primeiro_nome, faixa_risco,

               valor_em_atraso, dias_atraso_mais_antigo, score_prioridade, acao_sugerida
        from analytics_gold.gold_fila_cobranca
        order by posicao_fila
        limit %s
    """, (limite,))

def buscar_resumo():
    tabela = consultar("""
        select
            count(*)                                                    as clientes,
            coalesce(sum(valor_em_atraso), 0)                           as valor_em_atraso,
            count(*) filter (where acao_sugerida = 'Ligar')             as ligar,
            count(*) filter (where acao_sugerida = 'Aguardar promessa') as aguardando
        from analytics_gold.gold_fila_cobranca
    """)
    return tabela.iloc[0]


def buscar_contexto():
    return consultar("""
        select posicao_fila, cliente_id, primeiro_nome, faixa_risco, valor_em_atraso,
               dias_atraso_mais_antigo, score_prioridade, acao_sugerida
        from analytics_gold.gold_fila_cobranca
        order by posicao_fila
        limit 30
    """)