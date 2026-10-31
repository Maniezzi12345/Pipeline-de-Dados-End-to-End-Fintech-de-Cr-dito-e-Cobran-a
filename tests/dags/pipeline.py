from time import sleep
from airflow.sdk import dag, task
from datetime import datetime

@dag(
     dag_id = "prod_etl",
     description = "Dag de ETL para meu projeto de pipeline/SQL",
     schedule=datetime(2024,3,24),
     catchup=False
)

def pipeline():

    @task
    def primeira_atividade():
        print("Extract")

    @task
    def segunda_atividade():
        print("Transform")

    @task
    def terceira_atividade():
        print("Load")


    t1 = primeira_atividade()
    t2 = segunda_atividade()
    t3 = terceira_atividade()

    t1 >> t2 >> t3

pipeline()
