# 🎮 GameSalesPortfolio - 모바일 게임 & GCP BigQuery 매출 분석 프로젝트

이 리포지토리는 **Godot 4.x** 엔진으로 개발한 클릭커 모바일 게임 클라이언트와 **GCP (Google Cloud Platform)** 인프라를 실시간 연동하고, 유저 행동 및 광고 매출 데이터를 수집하여 **PowerBI / Tableau**로 분석하는 클라우드 데이터 파이프라인 포트폴리오 템플릿입니다.

---

## 🏗️ 전체 아키텍처 및 데이터 흐름

```
[Godot 4 모바일 게임] 
       ↓ (인게임 플레이, 상점 구매, 보상형 광고 시청)
       ↓ HTTP POST 요청 (JSON Payload)
[Google Cloud Function (Python 3.10)]  <-- API 게이트웨이 및 보안 서빙
       ↓ insert_rows_json() (Streaming Insert)
[Google BigQuery (Data Warehouse)] 
       ↓ Native Connection (Google Account OAuth)
[PowerBI Desktop / Tableau Desktop]
       ↓ (데이터 모델링, 시각화 대시보드 구축)
[포트폴리오 대시보드 완성]
```

---

## 🚀 1단계: Google BigQuery 테이블 설정
1. [Google Cloud Console](https://console.cloud.google.com/)에 로그인하고 새 프로젝트를 생성합니다.
2. 콘솔에서 **BigQuery** 페이지로 이동합니다.
3. 자신의 프로젝트 ID 옆의 삼점(⋮) 메뉴를 누르고 **데이터셋 만들기 (Create Dataset)**를 클릭합니다.
   * 데이터셋 ID: `game_analytics`
   * 데이터 위치: `asia-northeast3 (서울)` 또는 `us (멀티 리전)` 추천
4. 쿼리 편집기(Query Editor)를 열고 본 프로젝트에 포함된 [bigquery_schema.sql](file:///c:/Users/gnsl1/Desktop/Portfolio_Repo/GameSalesPortfolio/bigquery_schema.sql) 파일의 내용을 그대로 복사해 실행(Run)하여 4개의 테이블을 만듭니다.

---

## ⚡ 2단계: Google Cloud Function (서버리스 API) 배포
게임 클라이언트가 안전하게 BigQuery로 데이터를 보낼 수 있도록 Python 게이트웨이를 생성합니다.

### 방법 A: Google Cloud Console UI에서 배포하기 (가장 쉬움)
1. GCP 콘솔에서 **Cloud Functions**로 이동하여 **함수 만들기 (Create Function)**를 클릭합니다.
2. **기본 설정**:
   * 환경: `2세대 (2nd gen)`
   * 함수 이름: `log_event`
   * 리전: BigQuery와 동일한 리전 선택
   * 트리거 유형: `HTTPS` (인증되지 않은 호출 허용 선택)
3. **코드 구성**:
   * 런타임: `Python 3.10` (혹은 최신)
   * 진입점(Entry point): `log_event`
   * [cloud_function/main.py](file:///c:/Users/gnsl1/Desktop/Portfolio_Repo/GameSalesPortfolio/cloud_function/main.py)의 코드를 복사하여 콘솔의 `main.py`에 붙여넣습니다.
   * [cloud_function/requirements.txt](file:///c:/Users/gnsl1/Desktop/Portfolio_Repo/GameSalesPortfolio/cloud_function/requirements.txt)의 내용을 복사하여 콘솔의 `requirements.txt`에 붙여넣습니다.
4. **배포 (Deploy)**를 클릭합니다. 몇 분 후 초록색 체크마크와 함께 생성되는 **트리거 URL**을 복사합니다.

---

## 🎮 3단계: Godot 클라이언트 연동
1. Godot 프로젝트의 [AnalyticsManager.gd](file:///c:/Users/gnsl1/Desktop/Portfolio_Repo/GameSalesPortfolio/AnalyticsManager.gd) 파일을 엽니다.
2. **(완료됨)** 구글 클라우드 함수 배포가 완료되어 실시간 수집 URL이 이미 코드에 자동으로 적용되어 있습니다.
   ```gdscript
   const CLOUD_FUNCTION_URL = "https://asia-northeast3-portfolio-498701.cloudfunctions.net/log_event"
   ```
3. Godot 4 엔진으로 프로젝트를 실행하여 게임을 플레이합니다. (탭 버튼 클릭, 업그레이드 상점 이용, 보상형 광고 시청 등)
4. BigQuery 콘솔로 돌아와 각 테이블에 쿼리를 실행하여 데이터가 실시간으로 스트리밍 적재되었는지 확인합니다.
   * 예: `SELECT * FROM game_analytics.ad_clicks LIMIT 10`

---

## 📊 PowerBI / Tableau 시각화 및 데이터 전처리 가이드

### 1. PowerBI 연결 방법
1. **PowerBI Desktop** 실행 ➔ **데이터 가져오기 -> Google BigQuery** 선택.
2. GCP 계정으로 로그인(Sign in)하고 권한을 허용합니다.
3. 생성했던 프로젝트 및 `game_analytics` 데이터셋 아래의 4개 테이블을 가져옵니다.

### 💡 2. 데이터 엔지니어링 꿀팁: 중복 데이터 제거 (Deduplication)
BigQuery는 대용량 분석에 특화되어 대개 실시간 업데이트(`UPDATE`) 대신 데이터를 계속 누적 적재(`Append-only`)하는 방식으로 로그를 쌓습니다.

따라서 PowerBI에서 데이터를 집계할 때는 아래와 같이 **최신 레코드만 필터링하는 전처리(Deduplication)** 과정이 필수적이며, 이를 대시보드에 구현하면 포트폴리오의 실무 전문성을 크게 높일 수 있습니다.

#### A. 유저 정보 테이블 (최신 프로필만 선택)
한 유저가 여러 번 접속하거나 설문조사를 완료하면 `users` 테이블에 여러 행이 추가됩니다. 가장 최신의 정보만 남기려면 BigQuery SQL 뷰(View)를 만들거나 PowerBI의 파워 쿼리에서 필터링합니다:
```sql
-- BigQuery 뷰를 만들어 PowerBI에서 조회하는 추천 SQL
SELECT 
    user_id, created_at, device_os, device_model, gender, age_group, country, city
FROM (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
    FROM game_analytics.users
)
WHERE rn = 1
```

#### B. 세션 테이블 (시작과 종료 기록 병합)
세션은 시작할 때 한 번(`ended_at IS NULL`), 종료할 때 플레이 타임을 계산하여 한 번 더 적재됩니다. PowerBI에서는 `session_id`를 기준으로 그룹화하여 `ended_at`이 있고 `playtime_seconds`가 가장 큰 값을 남겨 사용합니다.
```sql
SELECT 
    session_id, user_id, MIN(started_at) as started_at, MAX(ended_at) as ended_at, MAX(playtime_seconds) as playtime_seconds
FROM game_analytics.sessions
GROUP BY session_id, user_id
```

### 📈 추천 시각화 포트폴리오 대시보드 구성
* **매출 대시보드**: 누적 광고 수익, 일별 매출 추이, 코호트별 LTV(유저 평생 가치) 추정.
* **유저 세그먼트 분석**: 성별 및 연령대(Profile)에 따른 잔존율(Retention) 차이, 국가별 DAU 비율.
* **유저 이탈 분석 (광고 퍼널)**: 보상형 광고의 시작(`started`) 대비 완료(`completed`) 비율을 파악하여 광고 노출에 의한 이탈율(Drop-off Rate) 파악.
