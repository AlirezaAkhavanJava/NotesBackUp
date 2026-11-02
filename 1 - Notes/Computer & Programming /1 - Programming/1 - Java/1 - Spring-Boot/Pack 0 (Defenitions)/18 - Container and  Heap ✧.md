

**JVM memory management** is how the Java Virtual Machine gets memory from the operating system, divides it into areas, hands pieces to your code, and takes them back when your code is done with them. You never call `malloc` or `free` in Java. You write `new`, and the JVM does the rest, including cleaning up through a process called **garbage collection** (GC).

Spring and Spring Boot do not change these rules. They are ordinary Java programs, so everything in this lesson applies. What Spring changes is the _shape_ of your memory use: thousands of long-lived singleton beans, one thread per request in Tomcat, and plenty of short-lived objects for each request. Add a container with a memory limit, and you have a few extra things to get right. This lesson takes you through all of it.

---

## The big picture

When your Spring Boot app runs in a container, memory looks like this:

```
Container memory limit (for example 1 GB)
└── The JVM process
    ├── Heap                   ← your objects (beans, entities, DTOs)
    ├── Thread stacks          ← one per thread (Tomcat workers, etc.)
    ├── Metaspace              ← class definitions
    ├── Code cache             ← JIT-compiled machine code
    ├── Direct / native memory ← NIO buffers, Netty, JDBC drivers
    └── GC bookkeeping + JVM internals
```

The most important sentence in this lesson: **the heap is only a part of what the JVM uses.** The container limit covers _all_ of it. Many "my app was killed for no reason" stories come from forgetting this.

---

## The stack: one per thread

Every thread has its own **stack**. It is a pile of **frames**, and each method call pushes one frame. When the method returns, its frame is popped.

A frame holds the method's **local variables** and the **references** it is using. Primitives such as `int` live directly in the frame. For objects, the frame holds only the _reference_ (an address), and the object itself lives on the heap.

Here is a Spring controller:

```java
@RestController
class OrderController {

    private final OrderService service;

    OrderController(OrderService service) {
        this.service = service;
    }

    @GetMapping("/orders/{id}")
    OrderDto get(@PathVariable long id) {
        int attempts = 1;
        Order order = service.find(id);
        return new OrderDto(order);
    }
}
```

Line by line, where does each thing live?

|Item|Lives in|Why|
|---|---|---|
|`service` (the field)|Heap, inside the controller object|Fields belong to the object|
|The controller object itself|Heap|It is a singleton bean|
|`id` (a `long`)|Stack frame of `get`|A primitive parameter|
|`attempts`|Stack frame of `get`|A primitive local|
|`order` (the variable)|Stack frame of `get`|A local _reference_|
|The `Order` object it points to|Heap|All objects live on the heap|
|The `OrderDto` created by `new`|Heap|Same|

When `get` returns, its frame disappears. `order` and `attempts` vanish with it. The `Order` object stays on the heap until nothing refers to it anymore, and then the GC may remove it. (This is the same idea as the pass-by-value lesson: a method receives a copy of the reference, not the object.)

**Stack facts to remember:**

- Default stack size is about **1 MB per thread** on 64-bit Linux, set with `-Xss`.
- Tomcat uses a pool of up to **200 threads** by default (`server.tomcat.threads.max`). That is up to ~200 MB of stack space reserved, though the OS only commits what is used.
- Spring stack traces are deep. A request passes through filters, `DispatcherServlet`, proxies (AOP, transactions), your controller, your service, and the repository. A hundred frames is normal, and infinite recursion gives you `StackOverflowError`.
- With **virtual threads** (`spring.threads.virtual.enabled=true`, Spring Boot 3.2+ with Java 21), a thread's stack is stored on the heap while the thread waits. That lets you have huge numbers of threads without huge stack memory.

---

## The heap: where all objects live

The heap is shared by all threads. Every `new` allocates here. Modern collectors treat it as **generational**, based on one observation: _most objects die young._

|Region|What lives there|How it is cleaned|
|---|---|---|
|**Young generation** (Eden + Survivor spaces)|New objects|Often, and fast (minor GC)|
|**Old generation**|Objects that survived many young collections|Less often, more costly|

An object starts in **Eden**. If it survives a young collection, it moves to a **Survivor** space and gets an **age**. After surviving enough collections (the default maximum age is 15), it is **promoted** to the old generation.

### How Spring objects fit this model

|Object|Lifetime|Where it ends up|
|---|---|---|
|Singleton beans (controllers, services, repositories)|The whole app run|Old generation, forever|
|`ApplicationContext`, bean definitions, proxies|The whole app run|Old generation|
|Request DTOs, JSON strings, `List`s you return|One request|Young gen, then collected|
|Entities loaded by Hibernate|One transaction (or whole request, see below)|Mostly young gen|
|`@SessionScope` beans, `HttpSession` data|Until the session expires|Often old gen|
|`@Cacheable` data, static `Map`s|As long as they are referenced|Old gen|

This is why a healthy Spring Boot app has a typical **saw-tooth** heap graph. Memory grows with each request, a young GC drops it back down, and a stable base of old-generation data (your beans and caches) stays underneath.

---

## Memory outside the heap

These areas are not controlled by `-Xmx`, but they count toward the container limit:

|Area|What it holds|Grows with|
|---|---|---|
|**Metaspace**|Class metadata (every loaded class)|Number of classes. Spring generates many (CGLIB proxies, Hibernate proxies, lambdas)|
|**Code cache**|JIT-compiled machine code|Hot code in your app|
|**Thread stacks**|Frames of every thread|Number of threads|
|**Direct buffers**|Off-heap I/O buffers|Netty, NIO, some JDBC drivers|
|**GC and JVM internals**|Card tables, remembered sets, symbol tables|Heap size and class count|

A rough rule is that **non-heap memory is often 100 to 300 MB or more** for a typical Spring Boot app. Plan for it. A 512 MB container with `-Xmx512m` will be killed.

---

## How garbage collection works

### Step 1: deciding what is garbage

The GC does not ask "is this object unused?" It asks "**can this object still be reached?**" It starts from **GC roots** and follows references:

- local variables and parameters on every thread's stack
- static fields
- active threads themselves
- JNI references

Any object it can reach is **live**. Everything else is **garbage**.

Here is why this matters in Spring. Your singleton `OrderService` is referenced by the `ApplicationContext`, which is referenced from a long-lived root. So it is always reachable and never collected. The `Order` from the controller above was referenced only from a stack frame that has returned. So it is unreachable and collectible.

This also explains **memory leaks in Java**. A leak is not "forgotten `free`." It is an object that is still _reachable_ by accident, such as a `static List` that only grows, a cache with no eviction, or a `ThreadLocal` never cleared. The GC cannot remove it, because by its rules it is still in use.

### Step 2: G1, the default collector

Since Java 9, the default is **G1** (Garbage-First), as long as the JVM believes it has enough resources (more on that in the container section). G1 splits the heap into many equal-sized **regions** (1 to 32 MB each). Each region is Eden, Survivor, Old, or Humongous at a given moment.

G1 works in cycles:

1. **Young collection** (stop-the-world, short). When Eden fills, the JVM pauses your app threads briefly, copies live objects from Eden into Survivor regions (or promotes them to Old), and frees all of Eden. Since most objects are dead, this is cheap.
2. **Concurrent marking.** When heap usage passes a threshold (about 45% by default), G1 starts marking live objects in the old regions **while your app keeps running**.
3. **Mixed collections.** G1 then cleans young regions _plus_ the old regions with the most garbage ("garbage first," hence the name).
4. **Full GC** (stop-the-world, slow). If G1 cannot keep up, it falls back to a full collection of the whole heap. This is the pause you want to avoid.

**Humongous objects** are objects bigger than half a region, such as a huge `byte[]` from reading a whole file. They go straight into special regions and are costly. In a Spring app, a large `findAll()` result or a big uploaded file in memory can trigger this.

### Step 3: reading a GC log

Start your app with `-Xlog:gc` and you see lines like:

```
[12.345s][info][gc] GC(7) Pause Young (Normal) (G1 Evacuation Pause) 210M->45M(512M) 8.123ms
```

- `Pause Young` is a young collection.
- `210M->45M(512M)` means heap use was 210 MB before, 45 MB after, with a current total heap size of 512 MB.
- `8.123ms` is the pause. Your request threads stopped for about 8 ms.

Healthy: many short young pauses, "after" values that stay steady. Unhealthy: "after" values that creep upward (a leak), or many `Pause Full` lines.

### Which collector?

|Collector|Flag|Good for|
|---|---|---|
|**Serial**|`-XX:+UseSerialGC`|Tiny containers, 1 CPU|
|**Parallel**|`-XX:+UseParallelGC`|Throughput over latency (batch jobs)|
|**G1**|`-XX:+UseG1GC`|The sensible default for most Spring apps|
|**ZGC**|`-XX:+UseZGC`|Very low pauses, big heaps. On Java 21 add `-XX:+ZGenerational`. Newer Java versions use generational mode by default|
|**Shenandoah**|`-XX:+UseShenandoahGC`|Low pauses, available in some JDK builds|

For a normal REST API, start with G1 and change only when you have measured a problem.

---

## Now put it in a container

### The JVM sees the container

Modern JVMs (Java 10+, and 8u191+) are **container-aware**. They read the limits set by the container (cgroups), not the host's total RAM. Two defaults surprise people:

1. **Default max heap = 25% of the container's memory.** In a 1 GB container, the heap is about 256 MB. That is safe but often too small.
2. **Tiny containers get Serial GC.** The JVM only picks G1 if it sees at least 2 CPUs and about 1.8 GB of memory. With less, it quietly chooses Serial.

See what your JVM decided:

```bash
docker run -m 1g --cpus 2 eclipse-temurin:21-jre \
  java -XX:+PrintFlagsFinal -version | grep -E 'MaxHeapSize|UseG1GC|UseSerialGC'
```

### Sizing the heap

Use percentages instead of fixed numbers. Then the same image works with any limit:

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dumps"
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
docker run -m 1g --cpus 2 -p 8080:8080 -v /tmp/dumps:/dumps myapp
```

Line by line:

- `JAVA_TOOL_OPTIONS` is an environment variable every JVM reads, so you do not need to change the `ENTRYPOINT`.
- `-XX:MaxRAMPercentage=75` allows the heap to use up to 75% of the container limit.
- `-XX:+HeapDumpOnOutOfMemoryError` writes a snapshot of the heap if the app runs out of memory, so you can inspect it afterwards.
- `-XX:HeapDumpPath=/dumps` is where the dump goes. The `-v /tmp/dumps:/dumps` volume keeps it after the container dies.
- `-m 1g` is the container limit. `--cpus 2` gives it 2 CPUs, which also lets the JVM pick G1.

Example math for a 1 GB container:

|Part|Size|
|---|---|
|Max heap (75%)|~768 MB|
|Left for Metaspace, stacks, code cache, direct buffers, JVM|~256 MB|

If your app needs more than that for non-heap, lower the percentage (60 to 70%) or raise the container limit. Setting 90% or more is how containers get killed.

### Two different "out of memory" failures

|Symptom|What happened|
|---|---|
|`java.lang.OutOfMemoryError: Java heap space`|The **heap** is full and the GC could not free enough. A Java exception, with a stack trace|
|`OutOfMemoryError: Metaspace`|Too many classes loaded|
|`OutOfMemoryError: unable to create native thread`|Too many threads, or no OS memory left for stacks|
|Container exits with code **137**, `OOMKilled: true`|The **whole process** went over the container limit. The Linux kernel killed it. No Java exception at all|

Check the last one with `docker inspect <container> --format '{{.State.OOMKilled}}'`. If it says `true`, the JVM used more than the limit in total, even if the heap was fine.

---

## Spring-specific memory traps

|Trap|What happens|Fix|
|---|---|---|
|`repository.findAll()` on a big table|Whole table loaded into heap, possibly humongous|Use paging (`Pageable`) or streaming|
|Open Session in View (`spring.jpa.open-in-view`, **on by default**)|Entities and the persistence context stay alive for the whole request|Turn off if you do not need lazy loading in views|
|Unbounded `@Cacheable` or static `Map`|Reachable forever, so heap grows until OOM|Use a cache with size limits and expiry (Caffeine)|
|Big `@SessionScope` beans or `HttpSession` data|Held until session expiry, piles up in old gen|Keep sessions small, shorten timeout|
|`ThreadLocal` not cleared in a thread pool|Value outlives the request|Always `remove()` in a `finally` block|
|Too many Tomcat threads|200 stacks plus per-thread objects|Tune `server.tomcat.threads.max`, or use virtual threads|
|Reading whole uploads into `byte[]`|Large humongous objects|Stream to disk or storage|

---

## Watching it live

### With Spring Boot Actuator

Add `spring-boot-starter-actuator`, then in `application.properties`:

```properties
management.endpoints.web.exposure.include=health,metrics
```

Now you can query these metrics:

|URL|What it shows|
|---|---|
|`/actuator/metrics/jvm.memory.used?tag=area:heap`|Heap use now|
|`/actuator/metrics/jvm.memory.max`|Maximum sizes|
|`/actuator/metrics/jvm.gc.pause`|Count and time of GC pauses|
|`/actuator/metrics/jvm.threads.live`|Number of live threads|

### With JDK tools

Find the process ID with `jps`, then:

```bash
jcmd <pid> GC.heap_info
jstat -gcutil <pid> 1000
jcmd <pid> GC.class_histogram | head -20
jcmd <pid> GC.heap_dump /tmp/heap.hprof
jcmd <pid> Thread.print
```

- `GC.heap_info` is a quick view of heap regions.
- `jstat -gcutil <pid> 1000` prints percentages for Eden, Survivor, Old, and Metaspace every second.
- `GC.class_histogram` lists which classes have the most instances. This is the fastest way to spot a leak.
- `GC.heap_dump` writes a snapshot you can open in Eclipse MAT or VisualVM.
- `Thread.print` shows every thread's stack.

If the total process memory looks bigger than the heap, turn on native tracking with `-XX:NativeMemoryTracking=summary`, then run `jcmd <pid> VM.native_memory summary`.

---

## Related concepts, in short

- **Metaspace** is where class definitions live (native memory, outside the heap). It grows as classes load. Spring's proxies and Hibernate's generated classes make it bigger than in a plain Java app. By default it is not capped, so set `-XX:MaxMetaspaceSize` only if you want a hard limit.
- **cgroups** are the Linux feature behind container limits. Docker's `-m` flag sets a cgroup memory limit. The kernel enforces it, and the JVM reads it to size itself.

---

## Quick recap

- The **stack** is per thread and holds local variables and references. The **heap** is shared and holds every object.
- Spring singletons live in the old generation for the whole run. Per-request objects are short-lived and collected in young GCs.
- The GC frees what is **unreachable** from the roots. A "leak" is something reachable by accident.
- **G1** is the default collector. Watch for `Pause Full` and for "after" numbers that keep rising.
- In containers, the JVM sees the limit, but the default heap is only 25%. Use `-XX:MaxRAMPercentage` (around 60 to 75%), and leave room for Metaspace, stacks, and native memory.
- Exit code 137 means the container was killed from outside. `OutOfMemoryError` means the JVM ran out inside.
- Measure with Actuator, `-Xlog:gc`, and `jcmd` before tuning anything.





[[Spring Framework]]