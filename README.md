# ✈️ FirstAirline — 인천공항 실시간 대시보드

> **Azure 기반 실시간 데이터 파이프라인 + ML 항공 지연 예측 서비스**  
> 6인 팀 프로젝트 · 2주 · Azure PaaS · Python · Flask · Power BI

![FirstAirline Demo](docs/images/항공편검색.gif)

<br>

## 📌 프로젝트 개요

인천공항 이용객에게 **실시간 혼잡도 · 항공편 지연 · 주차장 현황** 등 필요한 정보를 한 곳에서 제공하는 **데이터 대시보드 서비스**입니다.

공항 Open API에서 초 단위로 발생하는 데이터를 Azure 클라우드 위에서 **자동 수집 → 정제 → 적재 → 예측** 하는 엔드-투-엔드 파이프라인을 구축하고, Flask 웹 앱 및 Power BI 대시보드에 연동했습니다.

<br>

## 🏗️ 시스템 아키텍처

<img width="9778" height="5024" alt="프로젝트 아키텍처" src="https://github.com/user-attachments/assets/09c2ee1b-1164-4a6a-b37e-3f3afaf70cd0" />

```
📡 공항 Open API / 정적 CSV
        │
        ▼
🔁 실시간 수집 레이어
   Azure Function App  →  Event Hub  →  Stream Analytics
        │
        ▼
💾 메달리온 아키텍처 (PostgreSQL)
   Bronze (원본) → Silver (정제) → Gold (분석용)
        │
        ├── 🧠 Azure ML / Databricks  (항공 지연 예측 모델)
        │
        ▼
📊 서비스 레이어
   Flask Web App  ·  Power BI Dashboard
```

<br>

## 🛠️ 기술 스택

| 구분 | 사용 기술 |
|---|---|
| **실시간 파이프라인** | Azure Function App · Event Hub · Stream Analytics |
| **배치 파이프라인** | Azure Data Factory · Databricks |
| **데이터 저장** | PostgreSQL (메달리온 아키텍처) |
| **머신러닝** | Azure ML Studio · Databricks (MLflow) |
| **웹 서비스** | Python · Flask |
| **시각화** | Power BI · Fabric |
| **AI** | Azure AI Foundry (다국어 챗봇) |
| **버전 관리** | Git · GitHub |

<br>

## 🙋 본인 담당 역할

> **실시간 ETL 파이프라인 구축 + 항공 지연 예측 ML 모델 개발 + 트러블슈팅**

### 1. Azure PaaS 기반 실시간 ETL 파이프라인 구축

공항 API → **Bronze(원본 저장) → Silver(정제) → Gold(분석용)** 흐름을 Azure PaaS 서비스만으로 완성했습니다.

| 단계 | 사용 서비스 | 역할 |
|---|---|---|
| 수집 | Azure **Function App** | HTTP 트리거로 공항 API 호출 → Event Hub 전송 |
| 스트리밍 | Azure **Event Hub** | 실시간 이벤트 스트림 수신 버퍼 |
| 변환·적재 | Azure **Stream Analytics** | 윈도우 집계·필터링 후 PostgreSQL Bronze 테이블 적재 |
| 정제 | Azure **Data Factory** | Bronze → Silver 배치 변환 파이프라인 오케스트레이션 |

**관련 코드 위치**
- 수집: [src/data_pipeline/realTime_data/datacollection/](src/data_pipeline/realTime_data/datacollection/)
- Bronze 처리: [src/data_pipeline/realTime_data/processed_bronze/](src/data_pipeline/realTime_data/processed_bronze/)
- Silver 처리: [src/data_pipeline/realTime_data/processed_silver/](src/data_pipeline/realTime_data/processed_silver/)

<br>

### 2. 항공기 지연 시간 예측 ML 모델 개발 및 서비스 연동

수집된 실시간·배치 데이터를 기반으로 **항공편별 지연 시간 예측 모델**을 개발하고 Flask 앱에 연동했습니다.

- Databricks 노트북에서 피처 엔지니어링 및 모델 학습 수행
- Azure ML Studio로 실험 관리 및 모델 버전 관리
- 예측 결과를 Gold 레이어에 저장 → 웹 서비스에서 실시간 조회

**관련 코드 위치**
- Databricks 노트북: [src/ml/Databricks_notebooks/](src/ml/Databricks_notebooks/)
- ML Studio 실험: [src/ml/MLstudio/](src/ml/MLstudio/)

<br>

### 3. 🔧 파이프라인 중복 실행 이슈 해결 (트러블슈팅)

#### 문제 상황

개발 초기, 잦은 배포와 설정 미흡으로 **Azure Data Factory 파이프라인이 과도하게 호출**되어 두 가지 문제가 동시에 발생했습니다.

- PostgreSQL 내 **데이터 중복 적재** → 분석 정합성 오염
- 불필요한 클라우드 리소스 호출 → **비용 누수**

#### 원인 분석

데이터 흐름을 단계별로 추적한 결과 두 가지 허점을 발견했습니다.

1. **Function App** — 초기 배포 시 `runOnStartup: true` 옵션이 활성화되어, 앱 재시작 때마다 트리거가 의도치 않게 발화
2. **Stream Analytics 쿼리** — 중복 이벤트 필터링 로직 부재로 동일 레코드가 여러 번 하류로 전달

#### 해결 방법

```
[Function App]  runOnStartup 옵션 비활성화
[Stream Analytics]  쿼리에 DISTINCT + GROUP BY 기반 중복 제거 로직 추가
                    → 단일 트랜잭션 처리 보장
```

#### 결과

- 데이터 중복 적재 **원천 차단** → 분석 데이터 정합성 확보
- 불필요한 리소스 호출 제거 → **클라우드 운영 비용 최적화**

<br>

## 📂 디렉토리 구조

```
├── README.md
├── LICENSE
│
├── data/                          # 데이터 파일 (메달리온 계층)
│   ├── bronze/                    # 원본 수집 데이터
│   ├── silver/                    # 정제된 데이터
│   ├── gold/                      # 분석/서비스용 데이터
│   └── docs/                      # 테이블 명세서
│
├── src/
│   ├── data_pipeline/
│   │   ├── realTime_data/         # 실시간 ETL 파이프라인
│   │   │   ├── datacollection/              # Function App 수집 코드
│   │   │   ├── processed_bronze/            # Stream Analytics 쿼리 · DDL
│   │   │   ├── processed_silver/            # Data Factory 설정 · DDL
│   │   │   └── processed_gold/              # PostgreSQL 트리거 · DDL
│   │   └── batch_data/            # 배치 ETL 파이프라인
│   │       ├── datacollection/
│   │       ├── processed_bronze/
│   │       ├── processed_silver/  # Databricks 노트북 · Data Factory
│   │       └── processed_gold/
│   │
│   ├── ml/                        # 머신러닝
│   │   ├── Databricks_notebooks/  # 학습 · 예측 노트북
│   │   ├── make_data_for_prediction/
│   │   └── MLstudio/
│   │
│   └── webapp/                    # Flask 웹 애플리케이션
│       ├── app.py
│       ├── templates/
│       └── static/
│
├── dashboard/                     # Power BI 대시보드 파일
└── docs/                          # 발표 자료 · 시연 영상
```

<br>

## 📈 주요 결과

| 기능 | 내용 |
|---|---|
| 실시간 혼잡도 예측 | 터미널별 · 시간대별 혼잡 상태 예측 제공 |
| 항공편 지연 안내 | ML 모델 기반 항공편별 지연 시간 예측 |
| 주차장 혼잡도 | 실시간 현황 및 추천 주차장 안내 |
| 맞춤 정보 조회 | 항공편 · 터미널 · 주차장 통합 검색 |
| 자동화 파이프라인 | 수집~적재 전 과정 무중단 자동화 |
| 다국어 챗봇 | Azure AI Foundry 연동 외국인 지원 |

<br>

```

> Azure 리소스(Function App, Event Hub 등) 연결이 없으면 실시간 데이터 수신은 동작하지 않습니다.
