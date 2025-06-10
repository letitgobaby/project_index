import java.util.function.Function;

public class ClosureExample {
    public static void main(String[] args) {
        // effectively final 변수
        int base = 10;

        // Lamda 표현
        Function<Integer, Integer> adder = (x) -> x + base;

        // !! base 값을 변경하려고 시도하면 컴파일 오류 발생
        // base = 15;

        System.out.println(adder.apply(5));
    }
}