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