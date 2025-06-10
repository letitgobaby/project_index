
### # Runtime Data Area

<br>

##### MetaSpace(= Method Area)

- MetaSpace는 클래스 로딩 시점에 해당 클래스의 구조(필드, 메서드, 인터페이스 등)를 저장하는 공간이다. 이를 통해 JVM은 런타임에 클래스의 동작을 이해하고 실행할 수 있다. 예를 들어, static 변수나 메서드 정보, 상속 구조, 상수 풀(Constant Pool) 등이 여기에 포함된다. 이는 모든 인스턴스에 공통되는 클래스 단위 정보를 저장한다는 점에서, 객체의 인스턴스가 저장되는 힙 메모리와 구분된다.
<br>

- Java 8부터 MetaSpace는 native memory 영역에서 할당되며, XX:MaxMetaspaceSize 옵션을 통해 최대 크기를 제한할 수 있다. 설정하지 않으면 기본적으로 시스템의 가용 메모리까지 확장될 수 있다. 이로 인해 PermGen 시절보다 OOM(OutOfMemoryError: PermGen space) 오류가 줄었지만, 여전히 클래스 로더 누수(ClassLoader Leak) 등의 문제가 발생하면 native memory를 모두 소모해 OutOfMemoryError: Metaspace 가 발생할 수 있다.
<br>

- Metaspace에 저장되는 정보들
  - **클래스 메타데이터 (Class Metadata)**
    - 클래스 이름 (java.lang.String 등)
    - 클래스의 필드 정보 (이름, 타입, 접근 제어자 등)
    - 메서드 정보 (이름, 시그니처, 접근 제어자 등)
    - 상속 관계 (슈퍼 클래스, 인터페이스 등)
    - 어노테이션 정보
    - 메서드 테이블 (가상 메서드 디스패치용)
    <br>

  - **런타임 상수 풀 (Runtime Constant Pool)**
    - 문자열, 클래스 이름, 메서드 이름, 필드 이름, 숫자 상수 등 컴파일 타임에 확정되는 상수값들을 저장
    <br>

    - JVM은 중복 데이터 저장을 막고 메모리를 효율적으로 사용하기 위해서, 실행 시점에 모든 문자열, 클래스 이름, 메서드 시그니처를 상수 풀에 있는 동일한 참조 하나로 재사용한다.

  - **Method 및 Field Descriptor**
    - JVM이 .class 파일을 해석하고 메서드나 필드의 타입을 이해하기 위해 JVM 내부에서 메서드와 필드의 타입 정보를 기술하는 문자열 포맷. 바이트코드 수준에서 사용되는 약속된 형식
    <br>

    ~~~java
    String format(String s, int x, boolean b) {...}
      -> (Ljava/lang/String;IZ)Ljava/lang/String;
    ~~~

    <br>

  - **클래스 로더에 대한 참조**
    - 어떤 클래스로더가 이 클래스를 로딩 했는지 정보 저장
    <br>

  - **JVM 내부 구조체**
    - JVM이 .class 파일을 내부적으로 분석해서 만든 메타데이터 객체(C++ 기반). 예를들어 InstanceKlass, ConstantPool, Method 등
    <br>

<br>

##### Heap

- Heap은 자바 애플리케이션에서 동적으로 생성되는 객체 인스턴스가 저장되는 메모리 공간이다. 클래스가 인스턴스화될 때 생성된 객체들은 모두 힙에 저장되며, GC(Garbage Collector)는 이 영역을 대상으로 불필요해진 객체들을 자동으로 정리한다. 이는 JVM이 관리하는 가장 큰 메모리 영역 중 하나이며, Java 프로그램의 상태(state)를 주로 구성하는 데이터들이 위치한다.
<br>

- 힙 메모리는 JVM 옵션 -Xms, -Xmx를 통해 초기 및 최대 크기를 설정할 수 있다. JVM은 애플리케이션이 실행되는 동안 필요에 따라 Heap 메모리를 확장할 수 있으며 객체 저장 공간을 유연하게 관리한다. 다만, 설정된 최대 크기를 초과하면 OutOfMemoryError: Java heap space가 발생한다.
<br>

- 객체 인스턴스 데이터, 배열 객체, 박싱된 기본형(Boxed Primitive: Wrapper Class), 내부 클래스(익명 포함)의 객체 등이 Heap 영역에 저장된다. 다만, 객체를 참조하는 **참조값(Reference)** 자체는 스택 또는 다른 객체의 필드에 위치하며, 참조 대상 객체만이 Heap에 존재한다.
<br>

- heap의 구조는 GC에 따라 다르다.
<br>

- 일부 경우 JIT 컴파일러는 Escape Analysis를 통해 `new`로 생성된 객체가 메서드 내에서만 사용된다고 판단되면, Heap이 아닌 스택에 할당할 수 있다. 이를 **Stack Allocation**이라 하며, 성능 최적화에 활용된다.
<br>

<br>

##### Thread

- 자바에서 각 쓰레드는 독립적인 실행 흐름을 가지며, JVM은 쓰레드마다 고유의 메모리 공간을 할당한다. 이 메모리 공간은 해당 쓰레드의 실행 흐름, 메서드 호출 상태, 로컬 변수 저장, 연산 결과 저장 등을 관리하는 데 사용된다. 대표적으로 J**VM Stack, Program Counter(PC) Register, Native Method Stack**이 있다. 이러한 Thread 관련 메모리 구조는 모두 **Thread-private 영역**이며, 다른 쓰레드와 공유되지 않는다. 쓰레드가 종료되면 이 메모리들도 함께 정리된다.  
<br>

- **JVM Stack (Java Virtual Machine Stack)**
  - 각 쓰레드마다 독립적으로 할당되는 스택 메모리로, 메서드 호출 시마다 새로운 **스택 프레임(Frame)** 이 생성된다. 프레임은 메서드가 종료되면 제거된다.
  <br>
  - JVM Stack은 세 가지 주요 구조로 구성된다:

    - **Local Variable Table (로컬 변수 테이블)**  
      - 메서드 내 지역 변수, 파라미터, 참조값 등이 저장된다. 인덱스로 접근한다.

    - **Operand Stack (오퍼랜드 스택)**  
      - 연산을 수행하기 위한 스택 구조의 공간. 바이트코드 명령어가 실행될 때 피연산자를 여기서 꺼내고, 결과를 다시 여기에 넣는다.

    - **Frame Data (메서드 호출 프레임 메타데이터)**  
      - 예외 처리 정보, 리턴 주소, 상위 호출자 정보 등 메서드 실행 상태 관련 데이터를 저장한다.
    <br>

    ~~~java
      void add(int x, int y) {
        int sum = x + y;
        System.out.println(sum);
      }
      /**
        1. 메서드 호출과 스택 프레임 생성 
        2. Local Variable Table에 매개변수 저장 -> {1:x, 2:y}
        3. 바이트코드 실행: iload_1 명령 -> 인덱스 1 위치에 있는 x 값을 꺼내 Operand Stack에 push
        4. 바이트코드 실행: iload_2 명령 -> 인덱스 2 위치에 있는 y 값을 꺼내 Operand Stack에 push
        5. 바이트코드 실행: iadd 명령
          -> Operand Stack에서 가장 위에 있는 두 값을 꺼내서 더한 후, 다시 Operand Stack에 결과를 push
        6. 바이트코드 실행: istore_3 명령 -> Operand Stack에서 최상단 값을 꺼내서 Local Variable Table의 인덱스 3 위치에 저장
        7. sum 값이 Local Variable Table에 저장되었고, 이후 System.out.println(sum); 호출 같은 다른 명령들이 실행
       *
       */
    ~~~

  <br>

  - 이 영역은 GC의 대상이 아니며, 메서드의 재귀 호출이 너무 깊거나 무한 루프 등으로 스택이 넘치면 `StackOverflowError`가 발생한다.
<br>

- **Program Counter (PC Register)**
  - 각 쓰레드마다 하나씩 존재하는 작은 메모리 공간으로, **현재 실행 중인 바이트코드 명령어의 주소(오프셋)** 를 저장한다.
  <br>

  - JVM이 멀티스레딩을 지원하기 위해 쓰레드마다 개별적인 PC 레지스터를 유지하며, 컨텍스트 스위칭 시 해당 값으로 다시 실행 흐름을 이어간다.
  <br>

  - **네이티브 메서드를 실행 중일 때는 정의되지 않은 값을 가질 수 있다.**
<br>

- **Native Method Stack**
  - 자바 코드가 아닌 **JNI(Java Native Interface)** 를 통해 호출된 네이티브 코드(C/C++ 등)를 실행할 때 사용하는 스택이다.
  <br>

  - 플랫폼에 따라 구조와 동작이 다르며, C 스택과 거의 유사하게 동작한다.
  <br>

  - 네이티브 메서드 호출 시 로컬 변수나 임시 데이터를 저장하는 데 사용되며, 이 영역이 부족하면 `StackOverflowError` 또는 `UnsatisfiedLinkError`가 발생할 수 있다.
  <br>
