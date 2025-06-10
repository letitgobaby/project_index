
### # ClassLoader

```
# ClassLoader < Java Virtual Machine < Java Runtime Environment

- javac 로 컴파일된 .class 파일들을 JVM에 Lazy Loading 방식으로 '동적으로' 로드하는 역할 수행
```

##### ClassLoader System Process

- Main 메서드가 포함된 클래스를 시작으로 **로딩 -> 링킹 -> 초기화** 과정을 거친 후 main() 메서드가 실행된다. 이 메서드 안에서 다른 클래스들이 선언되어 있다면, 해당 클래스를 다시 로딩->링킹->초기화 과정을 통해 실행한다. <- Lazy Loading
<br>

- 로딩->링킹->초기화 과정중 얻어낸 정보들을 Method Area에 순차적으로 등록한다.
<br>

- 로딩이 완료된 클래스는, 내부적으로 클래스이름을 키값으로 key(이름):value(객체) 캐싱처리(in Method Area)를 하기 때문에, 다시 같은 클래스를 호출하면 캐싱된 객체를 반환한다.
<br>

</div>

##### 1. Loading

- 클래스로더의 로딩 과정은 기본적으로 **위임 모델(Parent Delegation Model)** 을 사용한다. ApplicationClassLoader가 클래스를 로딩할 때, 먼저 부모인 PlatformClassLoader, 그다음 BootstrapClassLoader에게 먼저 로딩 시도 권한을 위임하는 구조

~~~md
// 예시
ApplicationClassLoader.loadClass("TestA")
    → PlatformClassLoader.loadClass("TestA")      ❌ (못 찾음)
        → BootstrapClassLoader.loadClass("TestA") ❌ (못 찾음)
    ← PlatformClassLoader → 실패
← ApplicationClassLoader → ✅ 직접 findClass("TestA")
~~~

1. Bootstrap ClassLoader
    - 가장 기본적인 클래스 로더. JVM 자체에 내장된 네이티브 코드(C/C++)로 구현되어 있음
    - java.lang.\*, java.util.\* 등 JDK 핵심 클래스 로딩
<br>

2. Platform ClassLoader(= Extension ClassLoader, JDK 9+)
    - 확장 모듈이나 플랫폼 API 클래스 로딩
    - java.sql, javax.*, jdk.* 등의 JDK 플랫폼 API 모듈 로딩
<br>

3. Application ClassLoder(= System ClassLoader)
    - 우리가 만든 애플리케이션 클래스를 로딩
    - classpath에 있는 클래스: src, target/classes, lib 등 로딩
<br>

- User-Defined ClassLoader
  - 사용자가 직접 정의한 클래스 로더
  - 파일, 네트워크, DB 등 다양한 외부 경로의 클래스 로딩
  - 기존 클래스로더처럼 자동 로딩이 아니라, 개발자가 원하느 시점에 직접 로딩

<br>

##### 2. Linking

- ClassLoader가 클래스 파일(.class) 을 JVM의 Method Area (또는 Metaspace) 에 로드한 후, 클래스 파일이 JVM 스펙에 맞는지 확인, static 필드를 JVM 메모리에 기본값으로 초기화, 클래스 내부에서 참조하는 심볼릭 참조(Symbolic Reference) 들을 실제 메모리 주소로 바꾸는 작업을 진행하는 과정이다.

1. Verification
    - 바이트코드가 JVM 스펙에 맞는지 검증하는 단계. 보안, 형식 등
<br>

2. Preparation
    - static 필드들을 JVM 메모리(Method Area) 에 올리고 기본값(null, 0, false 등) 설정, 명시적 초기화는 초기화단계에서 진행
<br>

3. Resolution
    - 클래스 파일 내의 상징적 참조(Symbolic Reference, 이름만 있는 상태) 를 실제 메모리 주소로 치환
    - Resolve 중 필요한 클래스가 아직 로딩되지 않았다면 그 시점에서 ClassLoader가 해당 .class 파일 로딩
<br>

##### 3. Initialization

- Java 컴파일러(javac)는 클래스 안에 있는 모든 static 변수의 초기화 코드와 static 초기화 블록을 하나로 묶어, JVM이 인식하는 특별한 메서드 \<clinit> 으로 생성한다.
<br>

- \<clinit> 메서드는 직접 호출할 수 없고, JVM이 자동으로 호출한다. new 연산자로 객체 생성, static 필드나 메서드 접근, Class.forName() 호출 등 클래스가 최초로 사용될 때 단 한 번 실행되며, 정적(static) 초기화 작업을 수행. 실행은 Execution Engine이 담당한다.
<br>

- 이 과정에서 Linking의 Preparation 단계에서 할당된 기본값들이, 실제 초기화 값으로 치환된다. 초기화 작업이 끝나면 클래스 상태는 '사용 가능' 상태가 된다.
<br>
