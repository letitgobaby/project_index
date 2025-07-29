
public class AnonymousClassTest {
    public static void main(String[] args) {
        Runnable r = new Runnable() {
            public void run() {
                System.out.println("Hello from anonymous class!");
            }
        };
        r.run();
    }
}
