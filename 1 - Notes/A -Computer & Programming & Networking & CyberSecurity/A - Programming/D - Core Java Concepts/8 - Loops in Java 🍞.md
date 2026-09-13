Date : 2025-09-04

This document explains **loops in Java** and includes modern features up to Java 25.

---

## 1. `for` Loop

- Standard loop with **initialization, condition, and increment/decrement**.
    

```java
for (int i = 0; i < 5; i++) {
    System.out.println(i);
}
```

### Enhanced `for-each` Loop

- Iterates over **arrays or Iterable collections**.
    

```java
int[] arr = {1, 2, 3, 4};
for (int num : arr) {
    System.out.println(num);
}
```

### Java 8+ Streams Alternative

- Functional iteration.
    

```java
List<Integer> list = List.of(1,2,3,4);
list.stream().forEach(System.out::println);
```

---

## 2. `while` Loop

- Executes **while condition is true**.
    

```java
int i = 0;
while (i < 5) {
    System.out.println(i);
    i++;
}
```

### `do-while` Loop

- Executes **at least once**, then checks condition.
    

```java
i = 0;
do {
    System.out.println(i);
    i++;
} while (i < 5);
```

---

## 3. `break` and `continue`

- `break` → exits loop immediately.
    
- `continue` → skips current iteration.
    

```java
for (int i = 0; i < 10; i++) {
    if (i == 5) break;
    if (i % 2 == 0) continue;
    System.out.println(i);
}
```

---

## 4. Labeled Loops (Java 5+)

- Allows **breaking/continuing outer loops**.
    

```java
outer:
for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
        if (i == 1 && j == 1) break outer;
        System.out.println(i + "," + j);
    }
}
```

---

## 5. Modern Features in Loops (Java 21-25)

### 5.1 Pattern Matching with `for` (Java 21+)

- Iterate and **match types** in collections.
    

```java
List<Object> items = List.of(1, "Java", 3.0);
for (Object obj : items) {
    if (obj instanceof String s) {
        System.out.println("String found: " + s);
    }
}
```

### 5.2 Record Pattern in Loops (Java 21+)

- Destructure records while iterating.
    

```java
record Point(int x, int y) {}
List<Point> points = List.of(new Point(1,2), new Point(3,4));
for (Point(int x, int y) p : points) {
    System.out.println(x + "," + y);
}
```

### 5.3 Virtual Threads (Project Loom, Java 21+)

- Loops can now spawn lightweight threads efficiently.
    

```java
Runnable task = () -> System.out.println(Thread.currentThread());
Thread.startVirtualThread(task);
```

### 5.4 Enhanced Collections Iteration (Java 25 preview)

- `for` with pattern matching and destructuring directly in iteration (preview feature).
    

```java
Map<String, Integer> map = Map.of("a",1,"b",2);
for (var (key, value) : map.entrySet()) {
    System.out.println(key + "=" + value);
}
```

---

## 6. Summary

- **Traditional loops**: `for`, `while`, `do-while`
    
- **Control**: `break`, `continue`, labels
    
- **Modern loops**:
    
    - Stream-based iteration
        
    - Pattern matching and record destructuring
        
    - Virtual threads for parallel loop tasks
        
    - Enhanced `for` with deconstruction (Java 25 preview)
        

Loops in modern Java are **more expressive, type-safe, and concurrency-friendly**.


##### *Tags : [[Java]]