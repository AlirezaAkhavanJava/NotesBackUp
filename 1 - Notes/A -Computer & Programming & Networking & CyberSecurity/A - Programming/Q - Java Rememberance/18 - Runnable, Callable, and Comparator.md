
# Java Interfaces Tutorial: Runnable, Callable, and Comparator

## Introduction

This tutorial will teach you three important Java interfaces: **Runnable**, **Callable**, and **Comparator**. Don't worry if you're a beginner — I'll explain everything in plain English with simple analogies, then show you how to use them with real code examples.

---

## 1. Runnable

### Simple English Explanation

Think of **Runnable** as a **task card** that says "do this job, but don't tell me the result." It's like giving someone a chore to do — you just want them to do it, you don't expect them to report back with anything. In Java terms, a Runnable is a piece of code that can be run by a thread, but it **cannot return a value** and **cannot throw a checked exception**. It's the simplest way to say "here's some work to do."

### Additions (What It Brings)

| Feature | Supported? |
|---|---|
| Returns a value | ❌ No (returns `void`) |
| Throws checked exceptions | ❌ No |
| Used with `Thread` class | ✅ Yes |
| Used with `ExecutorService` | ✅ Yes (`execute()` and `submit()`) |
| Has only one method | ✅ `run()` |

### Code Example

```java
public class RunnableExample {
    public static void main(String[] args) {
        // Using a lambda (Java 8+)
        Runnable task = () -> {
            System.out.println("Runnable is running on: " 
                + Thread.currentThread().getName());
        };

        // Run it with a Thread
        Thread thread = new Thread(task);
        thread.start();
    }
}
```

**Output:**
```
Runnable is running on: Thread-0
```

### Another Example — Using an Executor

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class RunnableExecutorExample {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        
        Runnable task = () -> System.out.println("Task executed!");
        
        executor.execute(task); // no return value
        executor.shutdown();
    }
}
```

---

## 2. Callable

### Simple English Explanation

Think of **Callable** as a **task card that also gives you a receipt**. You assign someone a job, and when they're done, they hand you back a result. Unlike Runnable, a Callable **returns a value** (like a number, string, or object) and **can throw exceptions**. It's like ordering food at a restaurant — you place the order, wait, and get your meal back. Callable works with the `ExecutorService`, and the result is wrapped in a `Future` object (a "promise" that the result will arrive later).

### Additions (What It Brings)

| Feature | Supported? |
|---|---|
| Returns a value | ✅ Yes (any type `V`) |
| Throws checked exceptions | ✅ Yes |
| Used with `Thread` class | ❌ No |
| Used with `ExecutorService` | ✅ Yes (`submit()` only) |
| Has only one method | ✅ `call()` |
| Result wrapped in | ✅ `Future<V>` |

### Code Example

```java
import java.util.concurrent.*;

public class CallableExample {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newSingleThreadExecutor();

        Callable<Integer> task = () -> {
            System.out.println("Calculating...");
            return 42; // returning a value
        };

        Future<Integer> future = executor.submit(task);
        
        // Block until result is ready
        Integer result = future.get();
        System.out.println("Result: " + result);

        executor.shutdown();
    }
}
```

**Output:**
```
Calculating...
Result: 42
```

### Example with Exception

```java
Callable<String> riskyTask = () -> {
    if (Math.random() > 0.5) {
        throw new Exception("Something went wrong!");
    }
    return "Success!";
};

Future<String> future = executor.submit(riskyTask);
try {
    System.out.println(future.get());
} catch (ExecutionException e) {
    System.out.println("Caught: " + e.getCause().getMessage());
}
```

---

## 3. Comparator

### Simple English Explanation

Think of **Comparator** as a **custom sorting rule**. Imagine you have a pile of books and you want to sort them — by title, by author, by year, or by how thick they are. Java doesn't know how *you* want them sorted, so you provide a Comparator that says "compare book A and book B like this." A Comparator has a single method called `compare()` that takes two objects and returns a **negative number** (first is smaller), **zero** (equal), or **positive number** (first is bigger). You can create as many comparators as you want for different sorting rules.

### Additions (What It Brings)

| Feature | Supported? |
|---|---|
| Sorts objects by a custom rule | ✅ Yes |
| Can have multiple comparators per class | ✅ Yes |
| Uses `compare(T a, T b)` | ✅ Yes |
| Can be chained | ✅ Yes (`.thenComparing()`) |
| Works with `Collections.sort()` and `List.sort()` | ✅ Yes |
| Can be reversed | ✅ Yes (`.reversed()`) |

### Code Example

```java
import java.util.*;

class Person {
    String name;
    int age;

    Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    @Override
    public String toString() {
        return name + " (" + age + ")";
    }
}

public class ComparatorExample {
    public static void main(String[] args) {
        List<Person> people = new ArrayList<>();
        people.add(new Person("Alice", 30));
        people.add(new Person("Bob", 25));
        people.add(new Person("Charlie", 35));

        // Sort by age (ascending)
        Comparator<Person> byAge = (p1, p2) -> p1.age - p2.age;
        people.sort(byAge);
        System.out.println("By age: " + people);

        // Sort by name (alphabetical)
        Comparator<Person> byName = (p1, p2) -> p1.name.compareTo(p2.name);
        people.sort(byName);
        System.out.println("By name: " + people);
    }
}
```

**Output:**
```
By age: [Bob (25), Alice (30), Charlie (35)]
By name: [Alice (30), Bob (25), Charlie (35)]
```

### Advanced Example — Chaining and Reversing

```java
// Sort by age, then by name
Comparator<Person> chained = Comparator
        .comparingInt((Person p) -> p.age)
        .thenComparing(p -> p.name);

people.sort(chained);

// Reverse order
people.sort(byAge.reversed());
```

---

## Quick Comparison Table

| Feature | Runnable | Callable | Comparator |
|---|---|---|---|
| **Purpose** | Run a task | Run a task and get a result | Define sorting rules |
| **Single method** | `run()` | `call()` | `compare(T, T)` |
| **Returns value** | ❌ | ✅ | ✅ (int: -1, 0, 1) |
| **Throws checked exceptions** | ❌ | ✅ | ❌ |
| **Works with Thread** | ✅ | ❌ | ❌ |
| **Works with ExecutorService** | ✅ | ✅ | ❌ |
| **Works with sorting** | ❌ | ❌ | ✅ |

---

## When to Use Which?

- **Use Runnable** when you just need to run a task in the background and don't care about a result (e.g., logging, sending an email, cleaning up files).
- **Use Callable** when your task produces a result or may throw an exception (e.g., fetching data from a server, computing a value).
- **Use Comparator** when you need to sort a collection of objects by a rule other than their natural order (e.g., sorting employees by salary, students by grade).

---

## Final Tips for Dummies

1. **Runnable and Callable** are both about *doing work in another thread*. The only real difference: Callable gives you a result, Runnable doesn't.
2. **Comparator** has nothing to do with threads — it's purely about *sorting*.
3. In modern Java (8+), all three can be written as **lambdas** because they are **functional interfaces** (interfaces with one abstract method).
4. A class can implement more than one of these — they're not mutually exclusive.

Happy coding! 🎉

[[Java]]