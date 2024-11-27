# AWS RDS MariaDB -> EC2 MariaDB로 데이터 Replication 설정하기

이 문서는 AWS RDS의 MariaDB 데이터를 EC2 MariaDB 인스턴스로 복제하는 과정을 설명합니다. 이 과정은 서비스 중단 없이 RDS와 EC2 사이에 실시간 복제를 설정하여 데이터를 안전하게 이관하는 데 중점을 둡니다.

### 사전 요구 사항
- AWS RDS에 바이너리 로그(binary log)가 활성화되어 있어야 합니다.
- EC2 MariaDB 인스턴스에 접근할 수 있는 환경이 설정되어 있어야 합니다.
- 보안 그룹 및 방화벽 설정을 통해 RDS와 EC2 MariaDB 인스턴스 간 네트워크 통신이 가능해야 합니다.

---

### 1. RDS의 바이너리 로그 활성화하기

Replication을 위해서는 RDS의 바이너리 로그가 활성화되어 있어야 합니다.

1. RDS 파라미터 그룹에서 다음과 같이 파라미터를 설정합니다:
   - `binlog_format` : `ROW`
   - `log_bin` : `ON`
2. 파라미터 그룹을 적용한 후 RDS 인스턴스를 **재시작**하여 설정을 반영합니다.

> **참고**: RDS 인스턴스를 재시작하면 약간의 다운타임이 발생할 수 있습니다.

---

### 2. RDS에서 복제 사용자 계정 생성

복제를 위해 RDS MariaDB에 **REPLICATION** 권한이 있는 사용자 계정을 생성합니다.

```sql
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'your_password';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
FLUSH PRIVILEGES;
```

---

### 3. 초기 데이터 덤프

데이터 일관성을 위해 RDS의 모든 데이터를 EC2 MariaDB로 덤프하고 가져옵니다.
	
1.	RDS MariaDB에서 데이터 덤프 생성:

```bash
mysqldump -h your-rds-endpoint -u admin -p --all-databases --master-data=2 > initial_dump.sql
```

--master-data=2 옵션은 덤프 파일에 바이너리 로그 파일 및 위치 정보를 포함합니다.

2.	EC2 MariaDB로 덤프 파일 가져오기:

```bash
mysql -u root -p < initial_dump.sql
```

---

### 4. RDS의 현재 바이너리 로그 파일 및 위치 확인

Replication 시작 지점을 지정하기 위해 RDS의 바이너리 로그 파일과 위치를 확인합니다.

```sql
SHOW MASTER STATUS;
```

---

### 5. EC2 MariaDB에서 Replication 설정

EC2 MariaDB 인스턴스에 Replication을 설정하여 RDS의 변경 사항을 받아올 수 있도록 합니다.

1.	EC2 MariaDB에서 복제 시작 지점 설정:

```sql
CHANGE MASTER TO
  MASTER_HOST='your-rds-endpoint',
  MASTER_USER='replication_user',
  MASTER_PASSWORD='your_password',
  MASTER_LOG_FILE='mysql-bin.000001', -- RDS의 로그 파일 이름
  MASTER_LOG_POS=123456;              -- RDS의 로그 파일 위치
```

2.	Replication 시작:

```sql
START SLAVE;
```

---

### 6. Replication 상태 확인

Replication이 정상적으로 작동하는지 확인하기 위해 EC2 MariaDB에서 상태를 확인합니다.

```sql
SHOW SLAVE STATUS;
```

확인해야 할 주요 항목:
- Seconds_Behind_Master: 이 값이 0에 가까울수록 실시간에 가깝게 동기화되고 있음을 의미합니다.
- Slave_IO_Running 및 Slave_SQL_Running: 두 값이 Yes여야 합니다.

만약 에러가 발생할 경우, Last_Error 항목을 확인하고 적절한 조치를 취합니다.