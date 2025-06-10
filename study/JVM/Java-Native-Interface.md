
### # Java Native Interface (JNI)

<br>

~~~java
class HelloWorld {
  // 네이티브 함수 선언
  private native void print();

  static{
    // 네이티브 라이브러리 호출
    System.loadLibrary("HelloWorld");
  }

  public static void main(String[] args) {
    new HelloWorld().print(); // 실제 호출 코드
  }
}
~~~

- Java와 C/C++ 같은 native code (기계어로 직접 컴파일된 코드) 간의 연결 다리 역할
<br>

- VM 내부에서는 네이티브 메서드가 실행될 때 JVM 힙과 분리된 네이티브 힙에서 작동하며, JVM이 관리하는 메모리(GC 대상 영역)와 네이티브 코드의 직접적인 메모리 접근을 조정하기 위해 객체 참조를 로컬 참조(Local Reference), 전역 참조(Global Reference), 약한 전역 참조(Weak Global Reference)로 구분하여 관리한다. 객체 참조는 Java쪽에서 컨트롤하지 않고, C/C++ 쪽 코드에서 관리한다.
<br>

- JVM은 각 JNI 호출이 시작될 때 스레드마다 **로컬 참조 테이블**을 생성하고, JNI 함수 내에서 생성된 객체 참조는 여기에 기록된다. JNI 호출이 끝나면 해당 테이블은 파기되며, 이에 따라 GC는 더 이상 참조되지 않는 객체를 안전하게 수거할 수 있다. **글로벌 참조 테이블**은 JVM 전역에서 공유되며, GC는 이 테이블의 모든 참조를 “루트”로 간주하고 참조 체인을 따라 객체 생존 여부를 판단한다. 따라서 네이티브 코드에서 Java 객체를 장기 보관할 경우 반드시 글로벌 참조를 명시적으로 생성하고, 필요가 없어진 시점에 해제해야 한다. 이러한 참조 테이블은 JVM 내부의 **참조 관리 인프라(reference management infrastructure)** 를 구성하며, GC의 정확성과 성능, 네이티브 메모리와 Java 힙 사이의 일관성 유지에 핵심적인 역할을 한다. 또한, JVM은 참조 테이블의 크기를 제한하거나 로컬 참조 오버플로우 방지를 위해 주기적으로 강제 릴리스도 수행할 수 있다.
<br>

1. **로컬 참조(Local Reference)** 는 JNI 함수 호출 중에 자동으로 생성되며, 현재 스레드의 로컬 참조 테이블에 저장된다. 이 테이블은 각 JNI 프레임(즉, C 메서드 호출)마다 독립적으로 존재하며, 메서드가 반환되면 해당 테이블의 모든 참조는 자동으로 무효화되어 GC의 대상이 될 수 있다. 따라서 메모리 누수를 방지하고 일시적인 객체 접근에 적합하지만, 장기 보존이 필요한 참조에는 사용할 수 없다.
 <br>

2. **전역 참조(Global Reference)** 는 NewGlobalRef()를 통해 생성되며, JVM의 글로벌 참조 테이블에 저장된다. 이 참조는 메서드가 종료된 후에도 유지되며, GC는 이 글로벌 참조를 따라 해당 Java 객체를 reachable로 판단하여 수집하지 않는다. 따라서 JNI 코드가 장기간 객체를 유지하려면 반드시 글로벌 참조를 사용해야 하며, DeleteGlobalRef()로 직접 해제하지 않으면 메모리 누수로 이어질 수 있다.
 <br>

3. **약한 전역 참조 (Weak Global Reference)** 는 NewWeakGlobalRef() 함수를 통해 생성되며, 전역 참조처럼 네이티브 코드에서 JVM 밖으로 객체를 유지할 수 있지만, GC가 해당 객체를 수거해도 막지 않는다는 점에서 다르다. VM이 GC를 수행할 때, weak global reference를 통해 참조된 객체가 다른 강한 참조(global/local)가 없다면 그 객체는 GC 대상이 됨. GC 이후에 해당 참조는 여전히 존재하지만, 객체 자체는 무효이므로 접근하면 nullptr로 간주되기 때문에 DeleteWeakGlobalRef을 통해 직접 삭제해야 한다. Java의 WeakReference와는 동작이 비슷하지만 전혀 다른 메커니즘
 <br>
