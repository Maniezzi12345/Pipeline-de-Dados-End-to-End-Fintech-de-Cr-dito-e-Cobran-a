import time
from datetime import datetime

import requests
from airflow.sdk import dag, task, Variable
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator

AIRBYTE_API = "https://api.airbyte.com/v1"
DBT_CLOUD_CONN_ID = "dbt-conn"
DBT_JOB_ID = 70506183144282
STATUS_FINAIS = {"succeeded", "failed", "cancelled", "incomplete"}


def gerar_token_airbyte():
    resposta = requests.post(
        f"{AIRBYTE_API}/applications/token",
        json={
            "client_id": Variable.get("AIRBYTE_CLIENT_ID"),
            "client_secret": Variable.get("AIRBYTE_CLIENT_SECRET"),
            "grant-type": "client_credentials",
        },
        timeout=30,
    )
    resposta.raise_for_status()
    return resposta.json()["access_token"]


def sincronizar_airbyte(connection_id):
    cabecalho = {"Authorization": f"Bearer {gerar_token_airbyte()}", "Accept": "application/json"}
    inicio = requests.post(
        f"{AIRBYTE_API}/jobs",
        headers=cabecalho,
        json={"connectionId": connection_id, "jobType": "sync"},
        timeout=30,
    )
    inicio.raise_for_status()
    job_id = inicio.json()["jobId"]
    print(f"Sync iniciado: job {job_id}")

    for _ in range(60):
        time.sleep(30)
        cabecalho["Authorization"] = f"Bearer {gerar_token_airbyte()}"
        status = requests.get(f"{AIRBYTE_API}/jobs/{job_id}", headers=cabecalho, timeout=30).json()["status"]
        print(f"Job {job_id}: {status}")
        if status in STATUS_FINAIS:
            if status != "succeeded":
                raise RuntimeError(f"Sync do Airbyte terminou com status {status}")
            return job_id

    raise TimeoutError("Sync do Airbyte passou de 30 minutos")


@dag(
    dag_id="pipeline_cobranca",
    start_date=datetime(2026, 11, 1),
    schedule="@daily",
    catchup=False,
    tags=["airbyte", "dbt", "cobranca"],
)
def pipeline_cobranca():

    @task
    def sync_sheets():
        return sincronizar_airbyte(Variable.get("AIRBYTE_CONN_SHEETS"))

    @task
    def sync_mongo():
        return sincronizar_airbyte(Variable.get("AIRBYTE_CONN_MONGO"))

    rodar_dbt = DbtCloudRunJobOperator(
        task_id="rodar_dbt",
        dbt_cloud_conn_id=DBT_CLOUD_CONN_ID,
        job_id=DBT_JOB_ID,
        check_interval=60,
        timeout=1800,
    )

    [sync_sheets(), sync_mongo()] >> rodar_dbt


pipeline_cobranca()