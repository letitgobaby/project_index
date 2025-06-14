
### # Execution Engine

##### Interpreter

- 인터프리터 테이블(JVM 초기화때 생성)은 각 **바이트코드(opcode)** 에 대응하는 **네이티브 루틴(C/C++ 함수 포인터)** 들을 저장해 둔 매핑 테이블이다. 이 방식은 Dispatch Table 또는 Threaded Code 방식이라고도 하며, 매우 빠른 바이트코드 해석을 가능하게 한다.
  <br>

- 인터프리터 루틴(=템플릿)은 JVM이 실행될때(초기화 과정) TemplateInterpreter가 각 바이트코드에 맞는 native 루틴을 세팅한다. 이를 테이블에 등록하고, 런타임에 해당 opcode가 실행되면 해당 루틴을 실행한다. 루틴은 Data Area와는 다른 별도의 공간에 적재된다.
  <br>

- 인터프리터는 “하나의 실행 주체”가 아니라, **“JVM 바이트코드를 해석하는 루틴(os 네이티브)들의 집합(라이브러리/함수 저장소)”** 이고, 각 스레드가 자신의 실행 흐름에 따라 MetaSpace 내부의 Method* 객체의 entry_point을 인터프리터 테이블에서 찾고, 루틴을 호출하며 바이트코드를 한 줄씩 실행

<br>

##### JIT Compiler

- 앱 스레드가 인터프리터 테이블의 루틴을 참조해 실행하는 과정에서, MetaSpace 영역에 저장되어 있는 Method*, MethodData* 영역의 **Invocation Counter** 값을 카운팅 시킨다. 카운트가 특정 **임계값(threshold)** 을 넘게되거나, 임계값을 넘지 않더라도 메서드 내에서 반복(loop)이 특정 값을 넘게되면, 그때 최적화를 위해 CompileBroker객체가 JIT 컴파일러 큐에 루틴을 집어 넣어 트리거 시킨다. JIT Compiler Thread가 백그라운드 비동기로 수행되는 JIT 컴파일된 네이티브 코드는 JVM의 **Code Cache**라는 영역에 저장되고, 컴파일된 네이티브 코드의 주소는 Metaspace영역 안에있는 Method* 객체의 entry_point 필드에 덮어씌워진다. 이후 스레드가 같은 코드를 실행할때(메서드의 entry_point를 참조), JIT 컴파일된 네이티브 코드를 직접 실행하게 된다(=테이블 점프).
<br>

- **디옵트(Deoptimization)**
  - 디옵트는 JIT 컴파일러가 가정을 깨뜨리는(=기존과 다른 방식으로 동작) 실행 흐름을 만나면서 JIT 컴파일된 코드 대신 인터프리터로 실행을 넘기는 것. 일반적인 상황으로 리플렉션으로, 메서드를 실행하거나 객체의 다형성이 늘어나는 경우, 조건문 분기의 빈도가 바뀌거나, 예외가 새롭게 발생하는 경우, synchronized 영역의 경쟁 증가 등이 있다.

<br>

##### Tiered Compilation [-참조-](https://devblogs.microsoft.com/java/how-tiered-compilation-works-in-openjdk/)

- 대부분의 프로그램은 전체 실행 시간의 90%를 전체 코드의 10% 미만에서 소비 (90/10 법칙). 이러한 **핫 메서드(hot methods)** 를 식별하여, 자주 실행되는 메서드에 대해서만 고비용의 최적화 컴파일을 수행함으로써 성능을 향상시키는 것이 티어드 컴파일의 핵심 목표
<br>

- Tiered Compilation란 인터프리터로 먼저 실행하다가, 코드가 자주 호출되면 점점 더 최적화된 JIT 단계로 옮겨가는 방식을 말한다. JIT는 실행 전 바이트코드를 컴파일해야 하므로 애플리케이션 시작이 느림, 인터프리터는 빠르게 시작하지만, 장기 실행 시 성능이 낮음.
<br>

- JVM 내부에 존재하는 **TieredPolicy** 클래스가 각 메서드의 호출 횟수, 컴파일 상태, 프로파일 데이터 등을 종합해 어떤 Tier에서 실행할지를 동적으로 결정한다.
<br>

- 실행 5단계 (HotSpot 기준)
  - Level 0 / **인터프리터**
    - 그냥 바이트코드를 한 줄씩 해석하며 실행

  - Level 1 / **C1 (no Profiling)**
    - 간단한 최적화만 수행

  - Level 2 / **C1 (basic Profiling)**
    - 기본적인 프로파일링 포함

  - Level 3 / **C1 (full Profiling)**
    - C1을 이용해서 전체 프로파일링 정보 수집하여 C2 컴파일을 유도

  - Level 4 / **C2**
    - 최종적으로 고급 최적화 수행

<br>

##### Gabage Collector (GC)

- JVM의 Heap 영역에서 동적으로 할당했던 메모리 중 필요 없게 된 메모리 객체(garbage)를 모아 주기적으로 제거하는 프로세스를 말한다.

<br>

- GC Root
  - GC Root는 JVM 내부에서 “도달 가능성 분석”의 시작점이 되는 객체 집합. GC Root에 직,간접적으로 참조되는 모든 객체들은 "살아있다" 라고 판단하여 GC 대상이 아니게 된다.
  <br>

  - GC Root의 대상
    - **Java Class** : 클래스 로딩 시 생성된 java.lang.Class 객체 자체도 GC Root (해당 Class 객체는 static 필드를 포함함)

    - **Stack Local** : 각 스레드의 스택 프레임 내 로컬 변수(Local Variables) 또는 파라미터로 존재하는 객체 참조

    - **Active Java Threads** : 현재 실행 중인 스레드 자체도 GC Root로 간주되며, 해당 스레드 객체에서 접근 가능한 참조도 함께 탐색

    - **Static Fields** : 클래스의 static 필드들은 Method Area에 저장되고, 이 static 필드의 참조도 GC Root

    - **JNI Reference** : 네이티브 코드(C/C++ 등)에서 등록한 Global Reference, Weak Global Reference, Local Reference 등

    - **Synchronization Monitors** : synchronized 블록/메서드에서 모니터링되고 있는 객체. 현재 모니터를 가지고 있는 객체 참조도 GC Root

    - **JVM System Structures** : JVM에 직접적으로 관리되고 있는 예외 클래스, 시스템 클래스로더, 유저 정의 클래스로더

    - **Code Cache Roots (JIT)** : JIT 컴파일된 코드 안에서 사용 중인 객체 참조 (예: inline된 참조)

<br>

- **Copy 알고리즘**
  - GC Root에서 도달 가능한 객체만 식별해 Survivor 또는 Old 영역으로 이동시키고, 나머지는 명시적 제거 없이 버려진 공간으로 간주한다. 이렇게 함으로써 불필요한 객체는 자연스럽게 제거되고, 단편화 없는 연속된 메모리 확보가 가능하다.
  <br>

  - **Minor GC(Young GC)** 에서 주로 사용되며, Eden이 가득 차거나 Survivor(from → to) 복사 도중 공간이 부족하면, STW 후 살아있는 객체만 복사한다(Young gc). 이때 Eden, From-Survivor 영역은 완전히 비워진다. 이 과정에서 살아있는 객체는 age 값을 갖고 승격(Promotion) 여부가 판단된다. 이 알고리즘은 간단하면서도 빠르며, 힙 영역을 정리하면서 동시에 **compact 효과**도 얻을 수 있는 효율적인 방식이다.

<br>

- **Mark-Sweep-Compact 알고리즘**
  - 먼저 살아있는 객체를 **Mark(표시)** 하고, 그 외의 객체는 **Sweep(제거)** 한 다음, 남은 객체들을 **한쪽으로 압축(Compact)** 해 메모리 단편화를 해소하는 방식
  <br>

  - 이 방식은 메모리 회수율이 높고 조각화에 강하지만, Compact 과정에서 객체 이동 비용이 크고 STW 시간이 길어지는 단점이 있다. 따라서 응답성보다는 Throughput이 중요한 서비스에 적합하다.

<br>

- **Snapshot At The Beginning (SATB) 알고리즘**
  - Marking을 시작한 순간의 객체 그래프를 기준으로, 그 당시 살아있는 객체만 남기겠다는 철학. 마킹 시작시점의 힙 상태(GC Root)를 기준(Snapshot)을 잡고, 도중 애플리케이션이 객체의 참조를 변경한다면 **Write Barrier** 시점을 삽입하고 **SATB 큐**에 기록을 남겨 초기 스냅샵 시점에 살아있던 객체들을 빠짐없이 식별할 수 있게 한다.
  <br>

  - STW 시간을 최대한 줄이기 위해서 Concurrent Marking 방식을 사용하는데, 이때 앱스레드에 의해서 객체 참조가 변경될 위험이 있다. 이때 객체의 참조를 잃어버리지 않기 위해서 SATB 방식을 보조로 활용한다.

<br>

- **Load Barrier (Memory Barrier)**
  - G1이나 ZGC 같은 Concurrent GC들은 STW를 최소화 하기 위해 앱 스레드와 병렬로 마킹작업을 수행한다. GC가 모든 객체들의 참조를 찾아가면 마킹하면 STW가 너무 오래걸리기 때문에, GC Root가 되는 객체들을 지정 해놓고 백그라운드로 객체의 참조들을 마킹한다. 이 시점에서 앱 스레드가 객체의 참조를 바꿀 수 있는 경우가 있는데, 이러한 점을 보안하기 위해서 JVM은 Memory Barrier기술의 Load Barrier, Write Barrier를 적용한다. .class 코드에서 네이티브 코드로 변환하는 과정에서 객체코드 주변에 읽기, 쓰기 지점에 해당 베리어들을 삽입해서 네이티브 코드로 변환시킨다. 결국 실행되는 네이티브 코드에는 GC 보조를 위한 로직이 함께 들어 있다. 이 덕분에 GC는 대부분의 작업을 Concurrent하게 처리하면서도 안정적이고 정확한 참조 추적이 가능해진다.

<br>

- **GC 분류**
  
|GC 이름|힙 구조|주요 알고리즘|특징|
|------|------|------|------|
|Serial|Eden + Survivor + Old|Copy (Young), Mark-Sweep-Compact (Old)|단일 스레드|
|Parallel|Eden + Survivor + Old|병렬 Copy / 병렬 Mark-Sweep-Compact|병렬처리|
|CMS|Eden + Survivor + Old|Copy (Young), Mark-Sweep (Old)|Low Pause, Fragmentation|
|G1|Region (E/S/O 구분 있음)|Copy (Young), SATB (Old)|예측 가능한 Pause Time 설정|
|ZGC|Region (Chunk), 구분 없음|SATB + Load Barrier, Concurrent Move|< 10ms Pause|
|Shenandoah|Region, 구분 없음|SATB + Write Barrier, Concurrent Move|Pause-independent|

<br>

- **Serial GC**
  - new로 객체 생성시 Eden 영역에 할당된다. Eden 영역이 꽉 찼을때 Minor GC가 시작된다. 맨 처음 STW 발생하고, GC Root로부터 참조되는 객체만 Survivor 영역(S0 or S1)로 복사(Copy)한다. 다음으로 S0 or S1에 이전 GC에서 살아남은 객체가 있다면 S1 or S0 으로 객체Header에 있는 age값 증가와 함께 이동시킨다. 이때 만약 age가 임계값에 도달했다거나 객체의 크기가 대상 S 공간보다 큰 경우, 다른 S 영역으로 이동시키지 않고 Old 영역으로 이동시킨다(Promotion).
  <br>

  - Old 영역이 가득 찬 경우 Major GC가 시작된다. 맨 처음 STW가 발생한다. GC Root부터 시작하여 도달 가능한 객체들을 Mark(식별)한다. Mark된 객체를 제외한 나머지 객체들을 Sweep(제거)한다. 제거한 뒤에는 메모리가 조각화(Fragmentation) 되어있기 때문에 남은 객체들을 한쪽으로 밀어붙여(Compaction) 연속된 메모리공간을 확보하는 과정을 거친다. 이후 어플리케이션이 재개된다.

<br>

- **Parallel GC**
  - Parallel는 Serial GC와 로직은 동일하지만, **병렬 스레드**로 수행한다는 점이 차이점이다. 병렬로 실행하기 때문에 STW 시간이 더 짧다.

<br>

- **CMS GC (Concurrent Mark Sweep GC)**
  - Young 영역(Eden + Survivor)이 꽉 차면 발생. Serial 또는 Parallel 방식으로 수행되며 STW가 발생한다. Eden 영역에서 살아 있는 객체는 Survivor 영역 또는 Old 영역으로 복사되며, Survivor 간 객체는 age 값 증가와 함께 이동됩니다.
  <br>

  - Major GC (Old 영역 수집: CMS 수집 사이클)
    1. **Initial Mark (STW)** : GC Root에서 도달 가능한 Old 객체를 표면적으로 마킹. 짧은 STW로 수행.
    2. **Concurrent Mark** : 앱 스레드와 병행으로 마킹을 진행하며, 도달 가능한 객체 그래프 전체를 추적. 이때 **SATB**기법을 사용하여, 마킹 시작 시점 이후의 참조 변경도 안전하게 추적
    3. **Remark (STW)** : Concurrent Mark 중 변경된 참조를 다시 확인하여, 마킹 누락을 보완. 상대적으로 짧은 STW가 발생하지만, GC 정확도를 위해 필수
    4. **Concurrent Sweep** : 살아있지 않은 객체(= 마킹되지 않은 객체)를 앱 스레드와 병행하여 제거. 객체만 제거할 뿐, 메모리 정리는 하지 않기 때문에 **단편화(Fragmentation)** 가 발생할 수 있음 -> 단편화 누적되면 Full GC 발생

<br>

- **G1 GC (Garbage First GC)**
  - G1 GC는 힙을 동일한 크기의 **Region**(기본 1~32MB) 단위로 나눠 Region Pool을 만든다. Eden, Survivor, Old 모든 영역이 **정해진 고정 크기의 Region(리전)** 으로 나뉘어 관리된다. 각 Region은 GC가 Eden / Survivor / Old / Humongous 중 하나로 **동적**으로 지정한다.
  <br>

  - new 객체 생성 시, Eden 역할을 하는 Young Region에 메모리가 할당된다. 이 영역이 가득 차면 **Young GC**가 시작되며, STW가 발생한다. 이때 **GC Root로부터 도달 가능한 객체만 Survivor Region으로 복사(Copy)** 한다. 이전 GC에서 살아남은 객체가 있다면 다른 Survivor Region으로 age 값을 증가시키며 이동된다. age가 임계값에 도달하거나 Survivor Region보다 객체 크기가 큰 경우 Promotion 되어 Old Region으로 이동한다.
  <br>

  - Old 영역의 리전들이 일정 수준 누적되면, G1은 **Concurrent Marking** 단계를 시작한다. STW 상태에서 Initial Mark를 짧게 수행하고, 이후 앱 스레드와 병렬로 Concurrent Mark가 진행된다. 이때 SATB(Snapshot At The Beginning) 알고리즘을 사용하여 마킹 시작 시점(Initial Mark)의 객체 참조 정보를 기준으로 살아있는 객체를 추적한다. 이때 앱 스레드에 의해서 객체의 참조가 바뀔경우, Write Barrier를 삽입하여, Marking Queue에 이전 참조값을 넣는다. Concurrent Mark 후, 살아있는 객체가 적은 Old Region을 선별하여 **Mixed GC** 를 수행한다. Mixed GC는 Young + 일부 Old Region을 동시에 수집하는 방식이며, JAVA 옵션으로 설정한 Pause Time 목표에 맞춰 대상 Region의 개수를 조절한다. Mixed GC 역시 STW로 수행되며 Copy 방식으로 살아있는 객체만 다른 Region으로 복사한다.
  <br>

  - 만약 전체 힙에 여유 공간이 부족하거나 수집 효율이 낮다고 판단되면, G1은 **Full GC**를 수행한다. 이때는 전체 힙을 대상으로 Mark → Sweep → Compact 순으로 실행되며, Pause Time과 상관없는 긴 STW 상태에서 진행된다.

<br>

- **ZGC (Z Garbage Collector)** [-참조-](https://d2.naver.com/helloworld/0128759)
  - ZGC는 **초저지연(Garbage Collection Pause < 10ms)** 을 목표로 한다. 대부분 Concurrent 단계로 처리하며, 객체 복사는 **로드 배리어(Load Barrier)** 를 통해 안전하게 진행된다. ZGC는 객체를 **ZPage(Small / Medium / Large)** 단위로 관리하며, Copy 방식을 사용함으로써 메모리 단편화(조각화)를 자연스럽게 방지한다.
  <br>

  - 수행단계
    1. **Allocation** (할당)
    - 애플리케이션 스레드가 객체를 생성하면, ZGC는 객체 크기에 따라 적절한 ZPage(Small/Medium/Large) 영역에 객체를 할당한다. 이 과정은 매우 빠르며, 별도의 락 없이 수행된다.
    <br>

    2. **Concurrent Mark** (동시 마킹)
    - 특정 조건(메모리 사용량, 임계치 등)이 충족되면 GC가 시작된다. STW이 잠깐 발생하며, GC Root(스레드 스택, static 변수 등)를 기준으로 마킹이 시작된다. 이후에는 앱 스레드와 병행하여(Concurrent) 힙 내 객체를 추적하고 마킹한다. 이때 SATB(즉시 스냅샷 기법) 과 Load Barrier 기술을 사용하여 객체 참조 변경이나 이동 중인 객체도 정확히 추적할 수 있도록 한다.
    <br>

    - 각 객체는 마킹 상태에 따라 색상 비트(Color Bits) 를 갖는다. 객체 포인터의 여유 비트(최상위 비트 등)를 활용해 이 색상 정보를 표현한다.
      - White: 아직 방문되지 않음 → GC 대상일 수 있음
      - Gray: 방문했지만 참조한 자식 객체는 아직 확인되지 않음
      - Black: 마킹 완료된 생존 객체
    <br>

    3. **Concurrent Relocate** (동시 복사/이동)
    - 마킹이 완료되면, Snapshot 당시 객체들과 마킹 큐에 들어가 있는 객체도 함께 GC는 살아 있는 객체들로 판단하고 다른 ZPage로 이동(복사) 한다. 객체 복사는 앱 스레드와 동시에 이뤄지며, 원본 객체의 위치에는 **Forwarding Pointer**가 설정된다. 앱 스레드가 객체를 참조할때, 이 포워딩 포인터를 참고하여 변경된(복사/이동 된) 주소를 인식한다. 이때도 대부분의 작업은 앱 스레드와 동시에(Concurrent) 진행된다. 객체가 이동 중일 때 애플리케이션이 접근하더라도, Load Barrier가 동작하여 최신 주소로 자동 리다이렉션되므로 문제 없이 실행된다.
    <br>

    4. **Concurrent Remap** (참조 갱신)
    - 객체가 모두 새 위치로 복사된 이후, GC는 참조하고 있는 모든 포인터들을 새로운 위치로 갱신(Remapping) 한다. 이때 Forwarding Pointer를 기반으로 참조 갱신이 일어난다. 이 과정도 앱 스레드와 병행 처리된다. 이 덕분에 GC는 긴 정지 시간을 발생시키지 않고도 모든 참조를 업데이트할 수 있다.
    <br>

    5. **STW Cleanup** (정리 단계)
    - 모든 복사 및 참조 갱신이 완료되면, 짧은 STW 구간 동안 불필요한 ZPage를 해제하고 내부 상태를 정리한다. 이 과정은 매우 짧아(수 밀리초 이내), 실질적인 GC 지연이 거의 없다.  

<br>

- **Shenandoah GC**
  - ZGC와 비슷하게 Shenandoah GC는 초저지연(<10 ~ 20ms)을 목표로하는 GC이다. 또한 GC 작업을 대부분 앱 스레드와 동시에 수행한다. ZGC와 마찬가지로 객체 복사(Compacting) 를 지원하면서도 pause time을 힙 크기에 비례하지 않도록 유지하는 것이 핵심 목표. 전반적인 GC 수행흐름은 ZGC와 동일
  <br>

  - ZGC는 ZPage 기반으로 영역이 관리되며, Shenandoah는 Region 단위로 힙을 관리한다. 또 다른 주요 차이점은, ZGC는 앱 스레드가 동시 마킹 중 객체를 참조할 때 **Load Barrier**를 사용하여 **포워딩 메타데이터(포워딩 비트 및 포인터)** 를 통해 새로운 객체 주소를 확인한다. 반면 Shenandoah는 객체의 헤더에 **Brooks Pointer** 라는 추가 필드를 유지하여, 해당 객체의 현재 유효한 위치(복사된 주소) 를 참조할 수 있도록 한다.
  <br>
