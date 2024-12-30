### OpenTelemetry 기반 메트릭, 로깅, 트레이싱 모니터링 구성

---
#### 구성도

![image](https://github-production-user-asset-6210df.s3.amazonaws.com/48303144/399272257-439ae604-c33b-492f-89ce-c9acedd70a8f.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20241230%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20241230T102930Z&X-Amz-Expires=300&X-Amz-Signature=602af187487a9bc0302fd748f1d8f84b2085cce62c89e74730e6573d2aff6121&X-Amz-SignedHeaders=host)

---

#### 샘플 실행
~~~
 # docker-compose 설치 필요
 docker-compose up -d
~~~

---
#### 사용한 오픈소스 Observability 도구
- ***Otel-Collector*** / 데이터 수집기
    - OpenTelemetry 기반의 데이터를 중앙에서 관리하고 Exporter( Prometheus Exporter, Loki Exporter, Jaeger Exporter 등)을 통해 데이터를 전달

- ***Grafana*** / 시각화
    - 수집된 성능 데이터를 기반으로 시스템 상태를 직관적으로 확인할 수 있는 시각화 대시보드를 제공

- ***Prometheus*** / 메트릭
    - 애플리케이션과 시스템에서 발생하는 다양한 메트릭 데이터를 효율적으로 수집, 저장, 분석하는 도구

- ***Grafana Loki*** / 로깅
    - Loki는 로그 데이터를 효율적으로 수집 및 저장하며, Grafana와 연동하여 각 서비스의 로그를 시각적으로 분석 가능

- ***Jaeger*** / 트레이싱
    - Jaeger는 각 서비스 간의 호출 트레이스를 수집하고 병목 현상을 식별할 수 있도록 지원

- ***Redis-Exporter*** / 메트릭
    - Redis 서버에서 발생하는 메트릭 데이터를 수집하고 이를 Prometheus 형식으로 변환하여 제공하는 도구

- ***Mariadb-Exporter*** / 메트릭
    - MariaDB 데이터베이스에서 발생하는 메트릭 데이터를 수집하고 Prometheus로 전달하는 도구

---

##### Otel-Collector 사용 이유

1.	***애플리케이션과 모니터링 도구의 직접 연결 제거***
애플리케이션이 특정 모니터링 도구와 직접 연결되지 않으므로, 특정 도구에 대한 의존성을 제거하고 시스템 설계를 유연하게 유지할 수 있습니다.

2.	***표준화된 데이터 형식 지원***
OpenTelemetry 프로토콜을 사용하여 다양한 형식의 데이터를 수집하고 이를 통합, 변환, 라우팅하여 다양한 모니터링 도구(Prometheus, Jaeger, Loki 등)로 전달할 수 있습니다.

3.	***다양한 데이터 유형 수집***
Otel-Collector는 메트릭, 로그, 트레이싱 데이터를 모두 처리하며, 이를 통해 시스템의 성능, 상태, 호출 흐름에 대한 종합적인 모니터링이 가능합니다.

4.	***확장성***
Otel-Collector를 통해 새로운 모니터링 도구를 추가하거나 기존 도구를 교체할 때 애플리케이션 코드를 수정할 필요가 없습니다. 이를 통해 시스템의 확장성과 유지보수가 용이해집니다.

5.	***중앙 집중식 관리***
여러 애플리케이션에서 수집된 데이터를 중앙에서 통합 관리하고, 필요한 대로 데이터를 필터링하거나 여러 도구에 동시에 전달할 수 있습니다.

6.	***성능 최적화***
데이터를 필요한 도구로만 전달하거나 사전에 필터링함으로써 데이터 처리 및 전송에 필요한 리소스를 효율적으로 사용할 수 있습니다.