### 람다 클로저

~~~java
public class ClosureExample {
    public static void main(String[] args) {
        int base = 10; // 1

        Function<Integer, Integer> adder = (x) -> x + base; // 2

        // base = 15; // 3

        System.out.println(adder.apply(5));
    }
}
~~~

- 2번 줄에서 람다 adder가 정의될 때, 1번줄 base 변수의 값인 10이 캡처된다.
<br>

- 3번줄에서 base의 값을 바꾸려고하면 컴파일 에러가 난다. 람다에서 base를 캡쳐하기때문에 base의 변수는 `effectively final 변수`로 변경되어 값을 바꿀 수 없다.

<br>

Java에서 람다 표현식이 `effectively final` 변수만 캡처하도록 강제하는 이유는 몇 가지 깊은 JVM 내부 처리 방식과 설계 원칙에 기반한다.

- 스택(Stack)과 힙(Heap) 메모리의 차이:
  - base같은 지역 변수는 메서드가 호출될때 스레드의 스택 메모리에 할당되고, 메서드가 끝나면 스텍 프레임이 사라질때 지역변수도 같이 소멸된다. 하지만 람다 표현식은 결국 Function 인터페이스의 익명 클래스 인스턴스로 컴파일되고 이건 Heap 영역에 생성된다. 이때 힙에 있는 객체가 스택에 있는 지역변수를 **직접 참조**한다면, 지역변수가 사라져도 계속 참조를 하려고 하기때문에 **댕글링 포인터**와 유사한 문제가 발생할 수 있다. 이러한 문제를 해결하기 위해서 Java는 람다가 지역 변수를 참조할때 값을 복사하여 람다 객체 내부에 저장한다. 이를 **값 캡처** 또는 **람다 캡처링** 이라고 한다. 이렇게 해서 지역변수가 바뀌더라도(일반적으로 바꿀 수 없지만) 상관없이 람다는 처음 캡처한 변수를 갖고 기능을 수행한다.
