from datetime import datetime

from airflow.sdk import dag
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator

DBT_CLOUD_CONN_ID = "dbt-conn"
JOB_ID = 70506183144282


@dag(
    dag_id="pipeline_cobranca",
    start_date=datetime(2026, 11, 1),
    schedule="@daily",
    catchup=False,
    tags=["dbt", "cobranca"],
)
def pipeline_cobranca():

    rodar_dbt = DbtCloudRunJobOperator(
        task_id="rodar_dbt",
        dbt_cloud_conn_id=DBT_CLOUD_CONN_ID,
        job_id=JOB_ID,
        check_interval=60,
        timeout=1800,
    )

    rodar_dbt


pipeline_cobranca()