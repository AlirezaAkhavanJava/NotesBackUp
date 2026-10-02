Project Reactor is **Java’s reactive programming library**. Translation: it’s how you stop blocking threads like it’s 2005 and start writing apps that don’t collapse under load.

### Short, clean definition

**Project Reactor** is a **non-blocking, asynchronous, event-driven** library for building **reactive applications on the JVM**, based on the **Reactive Streams** specification.

It powers **Spring WebFlux**. Yes, that thing everyone pretends is “just Spring MVC but faster.” It’s not.

---

### Why it exists

Traditional Java:

- One request = one thread
    
- Threads block on I/O
    
- Enough users → thread starvation → sadness
    

Reactor:

- Few threads
    
- No blocking
    
- Work happens when data is ready
    
- System survives traffic spikes without crying
    

---

### Core concepts (the important stuff)

#### 1. Publisher

Something that **produces data over time**.

Reactor gives you two main ones:

- **Mono** → 0 or 1 item
    
- **Flux** → 0 to N items
    

If you remember only one thing, remember this.

#### 2. Subscriber

Consumes the data. Nothing happens until someone subscribes.  
Lazy execution. Like Java streams, but actually async.

#### 3. Backpressure

The consumer can say:

> “Slow down. I’m not ready.”

This prevents memory explosions and JVM funerals.

---

### Mono vs Flux (stop mixing them up)

|Type|Emits|Example|
|---|---|---|
|Mono|0 or 1|getUserById|
|Flux|many|streamOrders|

```java
Mono<User> user = userService.findById(1);

Flux<Order> orders = orderService.findAll();
```

If you return `List<T>` in WebFlux, you missed the point.

---

### Operators (the Lego bricks)

Reactor gives you operators like:

- `map`
    
- `flatMap`
    
- `filter`
    
- `zip`
    
- `retry`
    
- `timeout`
    

Example:

```java
Flux<Integer> result =
    Flux.just(1, 2, 3)
        .map(i -> i * 2)
        .filter(i -> i > 2);
```

Looks innocent. Runs async. Doesn’t block.

---

### Threads and schedulers

Reactor **does not create a thread per request**.

Common schedulers:

- `parallel()` – CPU work
    
- `boundedElastic()` – blocking I/O (database, files)
    
- `immediate()` – current thread (usually wrong)
    

Blocking inside Reactor without `boundedElastic()` is how bugs are born.

---

### Where you actually see Reactor

- **Spring WebFlux**
    
- **Spring Security (reactive)**
    
- **R2DBC** (reactive DB access)
    
- **Reactive Kafka / Mongo**
    

If it says “reactive” in Spring, Reactor is under the hood.

---

### When NOT to use Reactor

Be honest:

- Small CRUD app
    
- Blocking JDBC everywhere
    
- Team doesn’t understand async
    
- You like debugging nightmares
    

Reactor adds **power and complexity**. Not free.

---

### One-sentence truth

**Project Reactor lets Java handle massive concurrency using non-blocking streams instead of threads.**

##### Tags : [[44 - Threads 🧀]]