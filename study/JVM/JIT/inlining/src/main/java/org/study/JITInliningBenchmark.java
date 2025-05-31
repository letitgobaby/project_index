package org.study;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.CompilerControl;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.infra.Blackhole;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;
import org.openjdk.jmh.runner.options.TimeValue;

@State(Scope.Thread)
public class JITInliningBenchmark {

    public static void main(String[] args) throws Exception {
        Options opt = new OptionsBuilder()
                .include(JITInliningBenchmark.class.getSimpleName())
                .mode(Mode.Throughput) // 처리량 측정
                .warmupIterations(5) // 웜업 5번
                .warmupTime(TimeValue.milliseconds(1000)) // 웜업 1초
                .measurementIterations(5) // 측정 반복 5번
                .measurementTime(TimeValue.milliseconds(1000)) // 측정 시간 1초
                .threads(1)
                .forks(1) // 포크 1회
                .build();

        new Runner(opt).run();
    }

    private int x = 99;
    private int y = 89;

    /**
     * JIT 최적화와 관계없이 작성 된 경우
     * 
     * @param blackhole
     */
    @Benchmark
    public void standardCode(Blackhole blackhole) {
        int result = 0;
        for (int i = 0; i < x; i++) {
            for (int j = 0; j < y; j++) {
                result += (j % 3 == 0) ? j : i;
            }
        }
        blackhole.consume(result);
    }

    /**
     * JIT 인라인이 허용된 경우
     * 
     * @param blackhole
     */
    @Benchmark
    public void inline(Blackhole blackhole) {
        blackhole.consume(loopDoInline(x, y));
    }

    public int loopDoInline(int a, int b) {
        int result = 0;
        for (int i = 0; i < a; i++) {
            for (int j = 0; j < b; j++) {
                result += calculateDoInline(i, j);
            }
        }

        return result;
    }

    private int calculateDoInline(int a, int b) {
        int x = a, y = b;
        return (y % 3 == 0) ? y : x;
    }

    /**
     * JIT 인라인을 하지 않도록 설정한 경우
     * 
     * @param blackhole
     */
    @Benchmark
    public void notInline(Blackhole blackhole) {
        blackhole.consume(addWithLoopDontInline(x, y));
    }

    @CompilerControl(CompilerControl.Mode.DONT_INLINE)
    public int addWithLoopDontInline(int a, int b) {
        int result = 0;
        for (int i = 0; i < a; i++) {
            for (int j = 0; j < b; j++) {
                result += calculateDontInline(i, j);
            }
        }

        return result;
    }

    @CompilerControl(CompilerControl.Mode.DONT_INLINE)
    private int calculateDontInline(int a, int b) {
        int x = a, y = b;
        return (y % 3 == 0) ? y : x;
    }
}
