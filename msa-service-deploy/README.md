### msa-service-deploy-scripts
- 하나의 호스트에서 N개의 MSA 서비스를 구동하며 무중단 배포를 구현한 샘플

#### 프로젝트 요구사항
```
 - 단일 호스트에서 특정 MSA 서비스 Scale-Out
 - 배포 과정중 다운타임 없이 사용자 요청 처리
```

#### 프로젝트 목표
- 서비스 중단 없이 새로운 버전을 배포하는 프로세스를 자동화하여, 운영 중 발생할 수 있는 요청 손실을 최소화
- 호스트 내에서 특정 서비스의 스케일 아웃(SCALE-OUT)을 자동화

#### 프로젝트 사용 기술
 - docker (도커설치 필수)
 - spring boot3
 - spring cloud gateway
 - spring cloud discovery (Eureka)
 - Shell Script

#### 프로젝트 아키텍처
- sample-Eureka  / 1개 port:8761
- sample-gateway / 1개 port:8080
- sample-service / n개 port:1024-65535

#### 프로젝트 구동 및 테스트
```
# 1. 유레카, 게이트웨이 컨테이너 실행
./sample-init.sh

# 2. prod 환경 3개 서비스 배포 ./deploy.sh ('local' or 'prod')
./deploy.sh prod

# 3. 테스트 요청 실행
./request-test.sh

# 4. local환경 1개 재배포
./deploy.sh local

# 5. 테스트 요청 로그에서 에러 없이 리턴값 바뀌는 것 확인
```

#### 테스트 결과
<img width="700" alt="Screenshot 2024-12-23 at 15 27 46" src="https://github.com/user-attachments/assets/0c6d724f-02bd-4225-a903-a75563c18167" />

---

#### 이슈 및 해결
- Gateway에서 변경된 Eureka 서비스 목록을 즉시 가져오지 못해, down된 이전 서비스로 요청 전달하여 타임아웃 지연 현상 발생
- Gateway에서 새로 갱신된 서비스 리스트를 받기까지 30s (Default) 사이에 발생하는 이슈
<br>
- 생각한 해결방안
  case 1 -- Gateway에서 Eureka 클라이언트 캐시 갱신 주기 단축
  case 2 -- Eureka에서 상태 변경을 감지하여 Gateway 리프레시
  case 3 -- Gateway 요청이 실패할 때마다 백오프(backoff) 정책에 따라 재시도 간의 시간 간격을 조정 ***( 선택 )***
<br>
- 선택 이유
  - case1의 경우, 갱신 시간을 1초로 등록해도 1초의 시간 + 갱신시간 동안 down된 서비스로 요청이 들어갈 가능성이 있다.
  <br>
  - case2의 경우, Eureka에 새로운 서비스가 등록되는 시점에 Gateway에게 갱신을 알려줄 수 있지만, 과정에서 Eureka 서버쪽에 갱신 할 서비스를 특정 해야하는 하드코딩이 들어가고, 추가적인 API와 인증과정이 필요하기 때문에 선택하지 않았다. 제일 자연스러운 방법이긴 하다.
  <br>
  - case3을 선택 한 이유는, Gateway Global Filter 기능으로 down된 서비스로 요청을 보내 오류를 반환 받는다면, 즉시 다른 서비스로 LB를 할 수 있고, 이 필터가 무중단 배포를 할때 뿐 아니라 다른 요인으로 인해 서비스가 정상적이지 않을때도 동작할 수 있는 기능이이서 선택했다. 
  Retry 시간을 backoff 정책을 통해 짧게 유지를 하며, 점진적으로 증가하도록 설정했다.

---

#### deploy.sh 실행 과정

1. **프로파일 설정(.env) 변수 읽어오기**
~~~
ENV=${1:-prod}  # Default to 'prod' if no argument is provided
CONFIG_FILE="${ENV}.env"

if [ -f "$CONFIG_FILE" ]; then
  echo "Loading configuration for '$ENV' environment..."
  source "$CONFIG_FILE"
else
  echo "Configuration file for '$ENV' environment not found. Aborting deployment."
  exit 1
fi
~~~

2. **변수 설정 및 새로운 Docker 이미지 빌드**
~~~
TIMESTAMP=$(date +%Y%m%d-%H%M)
NEW_IMAGE_TAG="${APP_NAME}:${TIMESTAMP}"
NEW_CONTAINER_NAME="${APP_NAME}-${TIMESTAMP}"

docker build -t "$NEW_IMAGE_TAG" .
if [ $? -ne 0 ]; then
  echo "Docker image build failed. Aborting deployment."
  exit 1
fi

// 새로 빌드된 이미지에 latest 태그 달아줌
docker tag "$NEW_IMAGE_TAG" "${APP_NAME}:latest"
~~~

3. **새로운 Docker 컨테이너 실행**
~~~
for i in $(seq 1 $INSTANCE_NUM); do
  NEW_CONTAINER_NAME="${APP_NAME}-${TIMESTAMP}-${i}"
  HTTP_PORT=$(find_unused_port) -- 포트 중복을 피하기 위해 랜덤포트 할당

  docker run --name "$NEW_CONTAINER_NAME" \
    --network sample-net \
    -e SERVER_PORT=$HTTP_PORT \
    -e SPRING_PROFILE=$ENV \
    -p $HTTP_PORT:$HTTP_PORT \
    -d "${APP_NAME}:latest"
done
~~~

4. **새로운 컨테이너 Health Check**
~~~
HEALTH=""
for i in {1..10}; do
  HEALTH=$(curl -s http://localhost:$HTTP_PORT/actuator/health)
  if [ "$HEALTH" == "$SUCCESS_HEALTH_CHECK" ]; then
    echo "New container $NEW_CONTAINER_NAME is healthy."
    break
  fi
  sleep 3
done
~~~

5. **Health Check 실패 처리**
~~~
if [ "$HEALTH" != "$SUCCESS_HEALTH_CHECK" ]; then
  echo "Health check failed for $NEW_CONTAINER_NAME. Stopping and removing the failed container."
  docker logs $NEW_CONTAINER_NAME > $LOG_FILE
  echo "$NEW_CONTAINER_NAME failed" >> $FAILED_LOG_FILE
fi

if [ -s $FAILED_LOG_FILE ]; then
  echo "Health check failed for one or more containers. Stopping and removing all new containers."
  while IFS= read -r line; do
    CONTAINER_NAME=$(echo $line | awk '{print $1}')
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
  done < $FAILED_LOG_FILE

  exit 1  # 배포 실패 처리
fi
~~~

6. **기존 컨테이너 종료 및 제거**
~~~
OLD_CONTAINER_NAMES=$(docker ps -a --filter "name=${APP_NAME}-" --format "{{.Names}}" | grep -v -E "$(echo ${NEW_CONTAINER_NAMES[@]} | sed 's/ /|/g')")

if [ -n "$OLD_CONTAINER_NAMES" ]; then
  docker stop $OLD_CONTAINER_NAMES
  docker rm $OLD_CONTAINER_NAMES
else
  echo "No old containers found."
fi
~~~
