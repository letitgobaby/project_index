
public class LambdaTest {
    public static void main(String[] args) {
        String message = "Hello from Lamda!";

        Runnable r = () -> System.out.println(message);
        r.run();
    }
}
