
### 실행

```bash
mvn clean install
java -jar target/benchmarks.jar
```

### 결과

~~~
Benchmark                           Mode  Cnt       Score      Error  Units
JITInliningBenchmark.standardCode  thrpt    5  157085.856 ± 3741.975  ops/s
JITInliningBenchmark.inline        thrpt    5  156471.121 ± 2874.248  ops/s
JITInliningBenchmark.notInline     thrpt    5   48510.825 ± 3178.523  ops/s
~~~
