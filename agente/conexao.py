import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conexao = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

cursor = conexao.cursor()

cursor.execute("""
    select posicao_fila, primeiro_nome, valor_em_atraso, acao_sugerida
    from analytics_gold.gold_fila_cobranca
    order by posicao_fila
    limit 5
""")

linhas = cursor.fetchall()

for linha in linhas:
    print(linha)

cursor.close()
conexao.close()