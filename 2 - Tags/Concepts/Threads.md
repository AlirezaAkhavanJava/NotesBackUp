
# Threads in Java and Spring Boot

A comprehensive guide covering threading fundamentals in Java and how Spring Boot manages threads.

---

## 1. Java Threading Fundamentals

### Creating Threads

**Option 1: Extend `Thread`**
```java
class MyThread extends Thread {
    public void run() {
        System.out.println("Running in: " + Thread.currentThread().getName());
    }
}
new MyThread().start();
```

**Option 2: Implement `Runnable`** (preferred)
```java
Runnable task = () -> System.out.println("Running in: " + Thread.currentThread().getName());
new Thread(task).start();
```

**Option 3: `Callable` + `Future`** (returns a result)
```java
ExecutorService executor = Executors.newFixedThreadPool(4);
Future<Integer> future = executor.submit(() -> 42);
Integer result = future.get(); // blocks
executor.shutdown();
```

### Thread Lifecycle
```
NEW → RUNNABLE → (BLOCKED / WAITING / TIMED_WAITING) → TERMINATED
```

### Key Concepts
| Concept | Description |
|---------|-------------|
| **Race condition** | Multiple threads accessing shared mutable state |
| **Deadlock** | Two+ threads waiting on each other's locks |
| **Visibility** | Changes by one thread may not be seen by another (use `volatile`) |
| **Atomicity** | Use `AtomicInteger`, `AtomicReference`, etc. |

---

## 2. Java Concurrency Utilities (`java.util.concurrent`)

- **`ExecutorService`** — thread pool management
- **`CompletableFuture`** — async pipelines & composition
- **`ConcurrentHashMap`** — thread-safe map
- **`BlockingQueue`** — producer-consumer patterns
- **`CountDownLatch`, `CyclicBarrier`, `Semaphore`** — synchronization helpers
- **`ReentrantLock`, `ReadWriteLock`** — advanced locking

**Example — `CompletableFuture`:**
```java
CompletableFuture.supplyAsync(() -> fetchUser())
    .thenApply(user -> enrich(user))
    .thenAccept(System.out::println)
    .exceptionally(ex -> { ex.printStackTrace(); return null; });
```

---

## 3. Spring Boot Threading Model

### The Default: One Request = One Thread
Spring Boot (with embedded Tomcat) uses a **thread pool per connector**:
- Default: **200 max threads**, **10 min spare**
- Each incoming HTTP request is handled by one thread from the pool
- Configurable in `application.yml`:

```yaml
server:
  tomcat:
    threads:
      max: 200
      min-spare: 10
    accept-count: 100
    max-connections: 8192
```

Other embedded servers:
```yaml
server:
  jetty:
    threads:
      max: 200
      min: 8
  undertow:
    threads:
      worker: 64
      io: 8
```

---

## 4. Async Execution in Spring Boot

### Enable `@Async`
```java
@Configuration
@EnableAsync
public class AsyncConfig {
    @Bean(name = "taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor ex = new ThreadPoolTaskExecutor();
        ex.setCorePoolSize(10);
        ex.setMaxPoolSize(50);
        ex.setQueueCapacity(500);
        ex.setThreadNamePrefix("async-");
        ex.initialize();
        return ex;
    }
}
```

### Use `@Async`
```java
@Service
public class ReportService {

    @Async("taskExecutor")
    public CompletableFuture<String> generateReport() {
        // runs on separate thread
        return CompletableFuture.completedFuture("done");
    }
}
```

**Rules for `@Async`:**
- Method must be `public`
- Must be called from **another bean** (self-invocation bypasses the proxy)
- Return `void`, `Future<T>`, or `CompletableFuture<T>`

### Programmatic Async
```java
@Autowired
private TaskExecutor taskExecutor;

public void doWork() {
    taskExecutor.execute(() -> System.out.println("async work"));
}
```

---

## 5. Scheduling Threads

Spring uses a **single-threaded** scheduler by default. Configure it:

```java
@Configuration
@EnableScheduling
public class SchedulerConfig implements SchedulingConfigurer {
    @Override
    public void configureTasks(ScheduledTaskRegistrar registrar) {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(10);
        scheduler.setThreadNamePrefix("sched-");
        scheduler.initialize();
        registrar.setTaskScheduler(scheduler);
    }
}
```

```java
@Scheduled(fixedRate = 5000)
public void runEvery5s() { /* ... */ }
```

---

## 6. Virtual Threads (Java 21+ / Spring Boot 3.2+)

**Huge game changer** — lightweight threads managed by the JVM.

```yaml
spring:
  threads:
    virtual:
      enabled: true
```

Or programmatically:
```java
@Bean
public TomcatProtocolHandlerCustomizer<?> protocolHandlerVirtualThreadExecutor() {
    return handler -> handler.setExecutor(
        Executors.newVirtualThreadPerTaskExecutor()
    );
}
```

```java
Thread.startVirtualThread(() -> System.out.println("virtual!"));
```

**Benefits:** Millions of concurrent tasks, minimal memory, ideal for I/O-bound workloads (DB calls, HTTP calls).

**Caveats:** Don't use for CPU-bound work; avoid `synchronized` blocks holding long operations (use `ReentrantLock` instead — pinning).

---

## 7. Thread Safety in Spring Beans

| Scope | Thread Safety |
|-------|---------------|
| `singleton` (default) | **Shared across threads** — must be stateless or synchronized |
| `prototype` | New instance per injection |
| `request` | One per HTTP request |
| `session` | One per HTTP session |

**Rule of thumb:** Keep singleton beans **stateless**. Use `ThreadLocal` for per-request state (Spring's `RequestContextHolder` does this internally).

```java
private static final ThreadLocal<SimpleDateFormat> fmt =
    ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));
```
Or better — use `DateTimeFormatter` (immutable, thread-safe).

---

## 8. Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| `@Async` self-invocation | Call from a different bean |
| Unbounded thread pool | Always set `queueCapacity` / `maxPoolSize` |
| Blocking inside `@Async` on virtual threads | Use `ReentrantLock`, not `synchronized` |
| Sharing mutable state in singleton | Use immutable objects / synchronization |
| `ThreadLocal` leaks in pools | Always `remove()` in `finally` |
| Forgetting `executor.shutdown()` | Use `@PreDestroy` or Spring-managed executors |

---

## 9. Choosing the Right Tool

| Use Case | Recommendation |
|----------|----------------|
| HTTP request handling | Server thread pool (Tomcat/Jetty) |
| Fire-and-forget background job | `@Async` with `ThreadPoolTaskExecutor` |
| I/O-heavy concurrent calls (Java 21+) | Virtual threads |
| CPU-bound parallel computation | `ForkJoinPool` / bounded platform pool |
| Scheduled tasks | `@Scheduled` + `ThreadPoolTaskScheduler` |
| Complex async pipelines | `CompletableFuture` |

---

## Quick Reference: Key Classes

| Java | Spring Boot |
|------|-------------|
| `Thread`, `Runnable`, `Callable` | `@Async`, `@EnableAsync` |
| `ExecutorService` | `ThreadPoolTaskExecutor` |
| `ScheduledExecutorService` | `ThreadPoolTaskScheduler` |
| `CompletableFuture` | `AsyncResult`, `CompletableFuture` return |
| `Executors.newVirtualThreadPerTaskExecutor()` | `spring.threads.virtual.enabled=true` |





[[Computer & Programming]]
[[Java]]
[[Spring Framework]]