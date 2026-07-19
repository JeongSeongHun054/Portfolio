# gameduo_analytics dbt 프로젝트

게임듀오 포트폴리오 프로젝트의 BigQuery 데이터 변환(Transform) 계층을 dbt로 재구성한 것입니다.
기존에 BigQuery 콘솔에서 직접 실행했던 CREATE TABLE AS SELECT 쿼리들을,
버전 관리·테스트·문서화가 가능한 dbt 모델로 옮겼습니다.

## 구조

- `models/staging/` : 원본(raw) 테이블을 최소한으로 정제한 1:1 뷰 (staging layer)
- `models/marts/` : 실제 분석/대시보드에서 쓰는 집계 테이블 (mart layer)

staging → marts로 이어지는 계층 구조는 dbt/데이터 엔지니어링에서 표준적으로 쓰는 패턴입니다.
원본 테이블이 바뀌어도 staging만 수정하면 되고, marts는 staging의 `ref()`만 보고 있어서 변경 영향 범위가 명확합니다.

## 실행 방법 (실제 GCP 서비스 계정으로 연결 시)

```bash
pip install dbt-bigquery
cp profiles.yml.example ~/.dbt/profiles.yml   # 키 경로 수정 후
dbt debug     # 연결 확인
dbt run       # 전체 모델 실행
dbt test      # 데이터 품질 테스트 실행
dbt docs generate && dbt docs serve   # 문서 사이트 생성
```

## 참고

이 프로젝트에서는 BigQuery MCP 커넥터(OAuth 기반)로 연결되어 있어서, 이 리포지토리 자체에서
서비스 계정 키 파일을 갖고 있지 않습니다. 그래서 이 dbt 프로젝트는 코드로는 완성되어 있지만,
이 세션에서 직접 `dbt run`을 실행해 검증하지는 못했습니다. 실제로 실행하려면 GCP 서비스 계정 키를
발급받아 `profiles.yml`에 연결해야 합니다.
