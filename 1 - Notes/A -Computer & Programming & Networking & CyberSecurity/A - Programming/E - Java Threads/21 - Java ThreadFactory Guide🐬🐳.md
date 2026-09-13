Date : 2025-09-04
## Overview

`ThreadFactory` is an interface in Java used by executors to **create new threads**. Instead of letting the executor create threads with default settings, you can provide a custom `ThreadFactory` to control thread properties.

---

## 1. Why Use ThreadFactory

- Customize **thread names** for easier debugging.
    
- Set **daemon** or user thread status.
    
- Adjust **priority**.
    
- Assign **uncaught exception handlers**.
    

---

## 2. Default Behavior

If you don’t provide a `ThreadFactory`, the executor uses `DefaultThreadFactory`:

- Names threads as `pool-N-thread-M`.
    
- Non-daemon threads.
    
- Normal priority (`Thread.NORM_PRIORITY`).
    
- No custom exception handler.
    

Example:

```java
ExecutorService service = Executors.newFixedThreadPool(3);
```

- Threads are created automatically with default settings.
    
- No control over names or other properties.
    

---

## 3. Custom ThreadFactory Example

```java
ExecutorService service = Executors.newFixedThreadPool(3, new ThreadFactory() {
    private int count = 0;

    @Override
    public Thread newThread(Runnable r) {
        Thread t = new Thread(r);
        t.setName("MyThread-" + count++);
        t.setDaemon(false);
        return t;
    }
});

service.submit(() -> System.out.println(Thread.currentThread().getName()));
```

- Every thread created by the executor uses your factory.
    
- You control names, daemon status, etc.
    

---

## 4. Lambda Shortcut (Java 8+)

```java
ExecutorService service = Executors.newFixedThreadPool(2, r -> new Thread(r, "WorkerThread"));
```

- Cleaner syntax for simple customization.
    
- Still replaces the default factory.
    

---

## 5. How It Works

```
ExecutorService (pool) ---> ThreadFactory.newThread() ---> Thread
```

- The pool **requests new threads** via the factory.
    
- Factory decides thread properties.
    
- Threads are then managed by the pool.
    

---

## Summary

- `ThreadFactory` = a way to **customize threads** created by an executor.
    
- Default threads have standard names, priority, and daemon status.
    
- Custom factories are useful for debugging, logging, and production settings.



##### *Tags : [[44 - Threads 🧀]]