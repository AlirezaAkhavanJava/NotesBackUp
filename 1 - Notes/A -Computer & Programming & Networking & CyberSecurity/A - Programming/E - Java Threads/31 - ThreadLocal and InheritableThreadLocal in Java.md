
`ThreadLocal` and `InheritableThreadLocal` in the `java.lang` package provide mechanisms for maintaining per-thread variables, ensuring thread isolation and context propagation in multi-threaded applications like web servers or microservices. This document explains their usage, key methods, context propagation in thread pools, and provides concise examples tailored for backend development.

---

## ThreadLocal

### Overview

- **Purpose**: Provides a separate copy of a variable for each thread, ensuring thread-local storage.
- **Key Features**:
    - Each thread accesses its own independent copy of the variable.
    - No synchronization required, as there’s no shared state.
    - Useful for per-thread context (e.g., user sessions, transaction IDs).

### Key Methods

- `ThreadLocal<T>()`: Creates a `ThreadLocal` instance.
- `T get()`: Returns the thread’s copy of the variable.
- `void set(T value)`: Sets the thread’s copy of the variable.
- `void remove()`: Removes the thread’s copy to prevent memory leaks.
- `T initialValue()`: Override to provide a default value (default is `null`).

### Example

```java
public class ThreadLocalExample {
    private static final ThreadLocal<String> userId = new ThreadLocal<>();

    public void processRequest(String id) {
        userId.set(id);
        System.out.println(Thread.currentThread().getName() + " processing user: " + userId.get());
        userId.remove(); // Prevent memory leaks
    }

    public static void main(String[] args) {
        ThreadLocalExample example = new ThreadLocalExample();
        Thread t1 = new Thread(() -> example.processRequest("User1"));
        Thread t2 = new Thread(() -> example.processRequest("User2"));
        t1.start();
        t2.start();
    }
}
```

- **Explanation**: Each thread maintains its own `userId`, isolated from others.
- **Use Case**: Storing user IDs in a web server for request processing.

### Where to Use

- Per-thread context like user sessions, logging IDs, or database connections.
- Example: Tracking request-specific metadata in a servlet.

### Limitations

- **Memory Leaks**: If `remove()` is not called, thread-local variables may persist in thread pools, causing leaks.
- **No Propagation**: Child threads do not inherit the parent’s `ThreadLocal` values.

---

## InheritableThreadLocal

### Overview

- **Purpose**: Extends `ThreadLocal` to allow child threads to inherit the parent thread’s value.
- **Key Features**:
    - Child threads get a copy of the parent’s thread-local value when created.
    - Useful for propagating context (e.g., security tokens) to child threads.
- **Use Case**: Passing context in hierarchical thread execution.

### Key Methods

- Inherits all `ThreadLocal` methods.
- `T childValue(T parentValue)`: Override to customize the value inherited by child threads.

### Example

```java
public class InheritableThreadLocalExample {
    private static final InheritableThreadLocal<String> context = new InheritableThreadLocal<>() {
        @Override
        protected String childValue(String parentValue) {
            return parentValue == null ? "Default" : parentValue + "-Child";
        }
    };

    public void process() {
        System.out.println(Thread.currentThread().getName() + " context: " + context.get());
        Thread child = new Thread(() -> {
            System.out.println(Thread.currentThread().getName() + " context: " + context.get());
            context.remove();
        });
        child.start();
        try { child.join(); } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        InheritableThreadLocalExample example = new InheritableThreadLocalExample();
        context.set("Parent");
        example.process();
        context.remove();
    }
}
```

- **Explanation**: The child thread inherits the parent’s `context` value with a modified value (`Parent-Child`).
- **Use Case**: Propagating request context to child threads in a server.

### Where to Use

- Propagating context to child threads (e.g., security credentials, transaction IDs).
- Example: Passing tracing IDs in a distributed system.

### Limitations

- **Thread Pools**: `InheritableThreadLocal` doesn’t work well with thread pools, as threads are reused and not newly created.
- **Custom Propagation Needed**: Thread pools require manual context propagation.

---

## Context Propagation in Thread Pools

### Challenge

- In thread pools (e.g., `ExecutorService`), threads are reused, so `InheritableThreadLocal` doesn’t propagate context automatically, as new threads aren’t created for each task.
- **Solution**: Wrap tasks to capture and propagate `ThreadLocal` or `InheritableThreadLocal` values.

### Example: ThreadLocal with Thread Pool

```java
import java.util.concurrent.*;

public class ThreadLocalThreadPoolExample {
    private static final ThreadLocal<String> requestId = new ThreadLocal<>();
    private final ExecutorService executor = Executors.newFixedThreadPool(2);

    public Runnable wrap(Runnable task) {
        String id = requestId.get(); // Capture context
        return () -> {
            requestId.set(id); // Propagate to thread
            try {
                task.run();
            } finally {
                requestId.remove(); // Prevent leaks
            }
        };
    }

    public void process(String id) {
        requestId.set(id);
        executor.submit(wrap(() -> {
            System.out.println(Thread.currentThread().getName() + " processing: " + requestId.get());
        }));
        requestId.remove();
    }

    public void shutdown() throws InterruptedException {
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
    }

    public static void main(String[] args) throws InterruptedException {
        ThreadLocalThreadPoolExample example = new ThreadLocalThreadPoolExample();
        example.process("Request1");
        example.process("Request2");
        example.shutdown();
    }
}
```

- **Explanation**: Wraps tasks to propagate `requestId` in a thread pool, ensuring each task sees the correct context.
- **Use Case**: Propagating request IDs in a web server using a thread pool.

### Context Propagation with InheritableThreadLocal

- **Approach**: Similar to `ThreadLocal`, capture the parent’s value and set it in the task.
- **Note**: `InheritableThreadLocal` is less useful in thread pools due to thread reuse; manual propagation is still required.

---

## Best Practices

- **Use ThreadLocal for Isolation**:
    - Store per-thread data like user IDs or transaction IDs.
    - Example: `ThreadLocal<String> userId`.
- **Always Call remove()**:
    - Prevent memory leaks in thread pools.
    - Example: `userId.remove()` after task completion.
- **Use InheritableThreadLocal for Child Threads**:
    - Propagate context to newly created threads.
    - Example: Security tokens in child tasks.
- **Manual Propagation in Thread Pools**:
    - Wrap tasks to capture and set `ThreadLocal` values.
    - Example: `Runnable wrap(Runnable task)` to propagate context.
- **Avoid Overuse**:
    - Use only when per-thread storage is necessary; prefer shared thread-safe structures (`ConcurrentHashMap`) otherwise.
- **Handle Edge Cases**:
    - Ensure `null` checks for `ThreadLocal.get()` if no initial value is set.
    - Example: `String id = userId.get() != null ? userId.get() : "Default"`.
- **Test Context Propagation**:
    - Verify context consistency in thread pools under load.

---

## Pros and Cons

### Pros

- **ThreadLocal**:
    - Simple thread-local storage with no synchronization overhead.
    - Ideal for isolating per-thread context.
- **InheritableThreadLocal**:
    - Automatic context propagation to child threads.
    - Customizable with `childValue`.

### Cons

- **ThreadLocal**:
    - Risk of memory leaks if `remove()` is not called.
    - No automatic propagation in thread pools.
- **InheritableThreadLocal**:
    - Limited utility in thread pools due to thread reuse.
    - Adds complexity for custom child value logic.

---

## Practical Example: Request Context in Thread Pool

```java
import java.util.concurrent.*;

public class RequestContextExample {
    private static final ThreadLocal<String> requestContext = new ThreadLocal<>();
    private final ExecutorService executor = Executors.newFixedThreadPool(2);

    public Runnable wrap(Runnable task) {
        String context = requestContext.get();
        return () -> {
            requestContext.set(context);
            try {
                task.run();
            } finally {
                requestContext.remove();
            }
        };
    }

    public void handleRequest(String contextId) {
        requestContext.set(contextId);
        executor.submit(wrap(() -> {
            System.out.println(Thread.currentThread().getName() + " handling request: " + requestContext.get());
            try { Thread.sleep(500); } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }));
        requestContext.remove();
    }

    public void shutdown() throws InterruptedException {
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
    }

    public static void main(String[] args) throws InterruptedException {
        RequestContextExample example = new RequestContextExample();
        example.handleRequest("Request1");
        example.handleRequest("Request2");
        example.shutdown();
    }
}
```

- **Components**:
    - `ThreadLocal`: Stores request context per thread.
    - `wrap`: Propagates context to thread pool tasks.
    - `ExecutorService`: Manages task execution.
- **Use Case**: Propagating request IDs in a web server’s thread pool.

---

## Resources

- ThreadLocal: ThreadLocal API
- InheritableThreadLocal: InheritableThreadLocal API
- Java Concurrency in Practice: Java Concurrency in Practice


[[44 - Threads 🧀]]