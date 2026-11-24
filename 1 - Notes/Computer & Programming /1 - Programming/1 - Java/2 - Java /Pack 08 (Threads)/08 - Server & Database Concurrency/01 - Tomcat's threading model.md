

When your Spring Boot app receives an HTTP request, one Tomcat **worker thread** takes it and runs everything: the filters, your controller, the service, the repository call. That thread stays busy until the response is written. The number of worker threads is the number of requests your app can run at the same moment.

So the question to ask about any slow piece of code is: _is a Tomcat worker sitting idle inside it?_ This lesson shows how to see that in your logs and when you can release the worker. (How the pool itself is sized and what happens when all 200 are busy was covered in the Tomcat thread pool lesson, so this one focuses on your code's side.)

## See the worker thread

Log the thread name and you'll see which thread you're on:

```java
log.info("controller on {}", Thread.currentThread().getName());
// controller on http-nio-8080-exec-3
```

`http-nio-8080-exec-N` is a Tomcat worker. Any other prefix means your code is on a different thread. Everything below is about that name changing, or not changing.

## Version 1: blocking, one call after another

```java
@Service
public class StudentService {
    private final StudentInfoService info;

    public StudentService(StudentInfoService info) { this.info = info; }

    public Student getStudentInfo() throws Exception {
        String name    = info.getName().get();     // waits ~2s
        String college = info.getCollege().get();  // waits ~2s
        String id      = info.getId().get();       // waits ~2s
        return new Student(name, college, id);
    }
}
```

`Future.get()` blocks the calling thread until the result is ready. Each call finishes before the next one starts, so the total is 2 + 2 + 2 = **6 seconds**, and the whole time one worker thread is held. At 6 seconds per request, 200 workers serve about 33 requests per second.

## Version 2: parallel, but the worker is still blocked

Start all three first, then wait for all of them:

```java
CompletableFuture<String> name    = info.getName();
CompletableFuture<String> college = info.getCollege();
CompletableFuture<String> id      = info.getId();

CompletableFuture.allOf(name, college, id).join();   // waits ~2s total

return new Student(name.join(), college.join(), id.join());
```

Line by line:

- Each `info.getX()` call returns immediately with a `CompletableFuture`, and the real work runs on another thread.
- `allOf(...)` creates one future that completes when all three are done.
- `.join()` blocks the current thread until that happens. It's like `get()` but throws unchecked exceptions, so you don't need try/catch.

The time drops from 6 seconds to about **2 seconds**, because the three tasks overlap. But look at which thread is waiting on `join()`: the Tomcat worker, `exec-N`. The work is parallel, yet the worker is still held for the full 2 seconds. Version 2 is faster for the user and does nothing for how many requests Tomcat can serve at once. Running work on another thread and _releasing_ the worker are two separate things.

## What `@Async` needs to work

`@Async` runs a method on a Spring-managed executor through a proxy (the same proxy mechanism you saw in AOP and `@Transactional`, including the self-invocation gotcha: calling an `@Async` method from the _same class_ runs it synchronously). Three requirements, each easy to get wrong:

```java
@Configuration
@EnableAsync                                   // 1. without this, @Async is silently ignored
public class ThreadConfig {

    @Bean
    public ThreadPoolTaskExecutor jobExecutor() {
        var ex = new ThreadPoolTaskExecutor();
        ex.setCorePoolSize(4);
        ex.setMaxPoolSize(10);
        ex.setQueueCapacity(6);
        ex.setThreadNamePrefix("jobExec-");
        ex.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy()); // 3.
        return ex;                             // Spring calls initialize() for a @Bean
    }
}

@Service
public class StudentInfoService {
    @Async("jobExecutor")                      // 2. name the executor explicitly
    public CompletableFuture<String> getName() throws InterruptedException {
        Thread.sleep(2000);
        return CompletableFuture.completedFuture("Abc");
    }
    // getCollege(), getId() are the same shape
}
```

1. **`@EnableAsync`** switches the feature on. Without it the methods run on the calling thread and nothing tells you.
2. **Name the executor.** With several executor-like beans in the context (a `TaskScheduler` is one too), Spring may pick the wrong one or fail to choose. `@Async("jobExecutor")` removes the guess.
3. **Never use an empty rejection handler.** When the pool and its queue are full, a handler that does nothing _drops the task_, its future never completes, and `join()` waits forever. `CallerRunsPolicy` runs the task on the caller instead, which slows the caller down and creates back-pressure, and `AbortPolicy` (the default) throws an exception. Both fail visibly, which is what you want.

A pool detail worth knowing: a `ThreadPoolExecutor` only grows past `corePoolSize` _after the queue is full_. With core 4 and queue 6, you effectively have 4 threads until 6 tasks are waiting, and only then does it grow toward 10.

## Version 3: actually free the worker

Return the future from the controller instead of waiting on it:

```java
@GetMapping("/info")
public CompletableFuture<Student> info() {
    log.info("controller on {}", Thread.currentThread().getName());

    var name    = info.getName();
    var college = info.getCollege();
    var id      = info.getId();

    return CompletableFuture.allOf(name, college, id)
            .thenApply(v -> new Student(name.join(), college.join(), id.join()));
}
```

```java
public record Student(String name, String college, String id) {}
```

- `thenApply` says "when all three finish, build the `Student`". It doesn't wait, it registers a step.
- `join()` inside `thenApply` is safe, because that code only runs after `allOf` has completed.
- Returning a `CompletableFuture` tells Spring MVC to start **async request processing** (a Servlet 3 feature, `request.startAsync()`). The worker returns to the pool right away, and the HTTP connection stays open. When the future completes, Spring dispatches back to a container thread to write the response.

Your logs now show `controller on http-nio-8080-exec-1` followed by `jobExec-1`, `jobExec-2`, `jobExec-3` doing the sleeping. The `exec-1` thread is free for other requests while those 2 seconds pass.

One honest caveat: you moved the bottleneck. The worker pool is no longer the limit, but `jobExecutor` is. Four core threads running 2-second tasks complete about 2 tasks per second, so size this pool for your real workload. Async doesn't remove waiting, it chooses where the waiting happens.

## Other ways to release the worker

Return types Spring MVC treats as async: `CompletableFuture<T>`, `Callable<T>` (Spring runs it on its own executor), and `DeferredResult<T>` (you complete it later from any thread, useful for event-driven results). The virtual threads setting from the previous lesson attacks the same problem differently: you keep simple blocking code, and blocking stops costing a platform thread.

## Shared beans and thread safety

Many workers run at once, and your controllers, services and repositories are **singletons**, so all of those threads call the _same object_. That means Spring beans are **not** automatically thread-safe. The original idea that they are is wrong. A singleton is safe only if it is **stateless**:

```java
@Service
public class CounterService {
    private int count = 0;                  // shared by every request thread
    public int next() { return ++count; }   // race condition, lost updates
}
```

Two threads can read the same `count` and both write back the same value. This is exactly the race condition from the concurrency hazards lesson. The fixes are the usual ones: keep request data in method parameters and local variables (each thread has its own stack), or use `AtomicInteger` when you genuinely need shared state. Immutable configuration values (a URL, a username) are safe to share because nothing changes them.

## Connector modes, briefly

The connector decides how Tomcat reads sockets. **NIO** is the default: a few poller threads watch idle connections without tying up workers, but once a request is _ready_, a worker still handles it from start to end. **NIO2** uses asynchronous channels, and **APR/native** uses OS-level libraries and is optional. The old **BIO** connector (one blocking thread per connection) was removed in Tomcat 8.5. "Non-blocking" here refers to socket reading, not to your service code, which is why Version 2 still held a worker.

[[Threads]]
[[Spring Framework]]
