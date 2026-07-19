"""
게임듀오 포트폴리오 - 일일 데이터 파이프라인 DAG

매일 새벽, 전날 쌓인 raw 로그를 정제해서 대시보드/모델이 참조하는
요약 테이블(dbt marts)을 갱신하고, 이상치가 있으면 실패 알림을 보낸다.

주의: 이 DAG는 실제 Airflow 서버에 배포되어 운영되고 있지 않다.
파이프라인을 코드로 어떻게 설계하는지 보여주기 위한 산출물이며,
실제로 매일 스케줄 실행되려면 Airflow 환경(예: Cloud Composer)에 배포해야 한다.
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryCheckOperator

default_args = {
    "owner": "gameduo-analytics",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
    "email": ["gnsl1465@gmail.com"],
}

with DAG(
    dag_id="gameduo_daily_pipeline",
    description="raw 로그 -> dbt 변환 -> 데이터 품질 체크 -> 대시보드 데이터 갱신",
    default_args=default_args,
    schedule_interval="0 3 * * *",  # 매일 새벽 3시 (전날 데이터가 다 쌓인 뒤)
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["gameduo", "analytics", "portfolio"],
) as dag:

    # 1. 원본 데이터가 오늘 새벽 기준으로 정상 적재됐는지 체크
    check_source_freshness = BigQueryCheckOperator(
        task_id="check_source_freshness",
        sql="""
            SELECT COUNT(*) > 0
            FROM `newproject-502815.dungeon_game_analytics.sessions`
            WHERE DATE(session_start) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
        """,
        use_legacy_sql=False,
    )

    # 2. dbt로 staging -> marts 전체 재계산
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="cd /opt/dbt/gameduo_analytics && dbt run --profiles-dir .",
    )

    # 3. dbt 테스트(not_null, unique, accepted_values 등) 실행 -- 실패하면 다음 단계로 안 넘어감
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/dbt/gameduo_analytics && dbt test --profiles-dir .",
    )

    # 4. 이상치 체크: 전날 DAU가 최근 7일 평균 대비 30% 이상 급락하면 실패 처리 (운영 알림용)
    check_dau_anomaly = BigQueryCheckOperator(
        task_id="check_dau_anomaly",
        sql="""
            WITH recent AS (
                SELECT date, dau
                FROM `newproject-502815.dungeon_game_analytics.daily_kpi_summary`
                WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 8 DAY)
            )
            SELECT
                (SELECT dau FROM recent ORDER BY date DESC LIMIT 1)
                >= 0.7 * (SELECT AVG(dau) FROM recent WHERE date < (SELECT MAX(date) FROM recent))
        """,
        use_legacy_sql=False,
    )

    def refresh_dashboard_data(**context):
        """요약 테이블에서 최신 데이터를 뽑아 대시보드 HTML에 임베드된 JSON을 갱신한다."""
        # 실제 구현에서는 BigQuery 클라이언트로 daily_kpi_summary 등을 조회한 뒤
        # gameduo_dashboard.html 안의 DAILY_RAW / RETENTION_DATA 등을 재생성해서 덮어쓴다.
        print("대시보드용 데이터 갱신 (실제 구현 시 BigQuery -> HTML 임베드 스크립트 연결)")

    refresh_dashboard = PythonOperator(
        task_id="refresh_dashboard_data",
        python_callable=refresh_dashboard_data,
    )

    check_source_freshness >> dbt_run >> dbt_test >> check_dau_anomaly >> refresh_dashboard
