Date : 2025-09-12




### Available Constructors



---

### 1. **`Thread()`**

Creates a thread with no target (`Runnable` = `null`).  
Name is auto-generated like `"Thread-0"`.

```java
Thread t1 = new Thread() {
    @Override
    public void run() {
        System.out.println("t1 running: default constructor");
    }
};
t1.start();
```

>Instantiation type → **Anonymous inner class instantiation of Thread**.
---

### 2. **`Thread(Runnable target)`**

Creates a thread associated with a `Runnable`.

```java
Thread t2 = new Thread(() -> System.out.println("t2 running: Runnable target"));
t2.start();
```

---

### 3. **`Thread(Runnable target, String name)`**

Creates a thread with a task and a custom name.

```java
Thread t3 = new Thread(() -> System.out.println("t3 running: Runnable + name"), "Worker-1");
t3.start();
System.out.println("t3 name: " + t3.getName());
```

---

### 4. **`Thread(String name)`**

No `Runnable`, but custom name.

```java
Thread t4 = new Thread("Idle-Thread") {
    @Override
    public void run() {
        System.out.println("t4 running: Named thread without Runnable");
    }
};
t4.start();
```

---

### 5. **`Thread(ThreadGroup group, Runnable target)`**

Associates the thread with a `ThreadGroup`.

```java
ThreadGroup group = new ThreadGroup("MyGroup");
Thread t5 = new Thread(group, () -> System.out.println("t5 running in group"));
t5.start();
```

---

### 6. **`Thread(ThreadGroup group, Runnable target, String name)`**

Group + task + name.

```java
Thread t6 = new Thread(group, 
    () -> System.out.println("t6 running with group + name"), 
    "Group-Worker");
t6.start();
System.out.println("t6 group: " + t6.getThreadGroup().getName());
```

---

### 7. **`Thread(ThreadGroup group, Runnable target, String name, long stackSize)`**

Adds a stack size hint (mostly ignored by JVMs today).

```java
Thread t7 = new Thread(group,
    () -> System.out.println("t7 running with stack size hint"),
    "Stack-Thread",
    1024 * 1024 // 1 MB stack size hint
);
t7.start();
```

---

### 8. **`Thread(ThreadGroup group, String name)`**

Group + name only, no `Runnable`.

```java
Thread t8 = new Thread(group, "Group-Only") {
    @Override
    public void run() {
        System.out.println("t8 running with group + name only");
    }
};
t8.start();
```

---

### Quick Notes

- If no `Runnable` is passed, the thread executes its own `run()` (you can override `Thread.run()`).
    
- If both a `Runnable` is passed and `Thread.run()` is overridden, **the `Runnable` takes priority**.
    
- Naming threads is important for debugging/logging in real apps.
    
- `ThreadGroup` is legacy — replaced by `ExecutorService` and thread pools.
    




##### *Tags : [[44 - Threads 🧀]]