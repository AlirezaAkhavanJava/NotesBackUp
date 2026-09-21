


**Parent delegation** is the model Java's class loaders use to resolve a class request: before a class loader tries to load a class itself, it first asks its **parent** loader to try. Only if the parent can't find the class does the child attempt to load it itself.

In other words: **requests flow up, loading flows down.**

## The mechanism, step by step

When any class loader receives a request to load a class, it follows this algorithm (defined in `ClassLoader.loadClass()`):

1. Check if the class is already loaded (cached) — if so, return it immediately.
2. If not cached, **delegate to the parent first** (recursively — the parent does the same check, and asks _its_ parent, all the way up).
3. Only if the parent chain returns "not found" does the current loader attempt to load the class itself, from its own source (its own classpath/module path).

## Applied to the three loaders you already know

```
Application ClassLoader   ← loads YOUR code
        ↑ delegates first
Platform ClassLoader      ← loads java.sql, java.desktop, etc.
        ↑ delegates first
Bootstrap ClassLoader     ← loads java.base (no parent — top of chain)
```

So when your code does `new ArrayList<>()`:

1. Application loader gets the request for `java.util.ArrayList`.
2. It doesn't try to load it itself yet — it asks Platform.
3. Platform doesn't try either — it asks Bootstrap.
4. Bootstrap checks: "Is `ArrayList` part of `java.base`? Yes." → **Bootstrap loads it.**
5. The result travels back down to Application, which returns it to your code.

Your own loader (Application) never even gets a chance to load `ArrayList` — the request never reaches that point, because Bootstrap already satisfied it.

## Why this design exists

**Security and integrity.** This prevents a malicious or accidental class from shadowing a core JDK class. Imagine you (or a rogue dependency) created your own class named `java.lang.String`. Without parent delegation, your Application loader might load _your_ fake `String` and the JVM would use it everywhere instead of the real one — a serious security hole.

With parent delegation, when a request comes in for `java.lang.String`:

- Application asks Platform, Platform asks Bootstrap.
- Bootstrap already has the real `java.lang.String` loaded (it's foundational) → returns that.
- Your fake `String.class` file sitting in your classpath is **never even considered** — Bootstrap already won the race before delegation ever reached your loader.

This is why you can't accidentally (or maliciously) override `java.lang.String`, `java.lang.Object`, etc., no matter what you put on your classpath.

## A simple analogy

Think of it like asking a question in a company hierarchy where you're required to ask your manager first, who asks _their_ manager first, and so on up to the CEO:

- The CEO (Bootstrap) answers first if they know the answer.
- Only if it goes all the way up and nobody above you knows, do _you_ get to answer it yourself.

This guarantees the most "authoritative" source always wins, and no one below can quietly override an answer that a higher authority already knows.

## Quick code demonstration

```java
public class DelegationDemo {
    public static void main(String[] args) throws Exception {
        // Try to load java.lang.String via the Application loader directly
        ClassLoader appLoader = DelegationDemo.class.getClassLoader();
        Class<?> stringClass = appLoader.loadClass("java.lang.String");

        // Even though we asked the Application loader,
        // delegation means Bootstrap actually loaded it
        System.out.println(stringClass.getClassLoader()); // prints: null (Bootstrap!)
    }
}
```

Even though you explicitly called `loadClass` _on the Application loader_, the actual loader that ends up owning `String` is still Bootstrap — proof that delegation happened before Application ever got to act.

## One important nuance: this is a _convention_, not a JVM law

Parent delegation is the **default behavior** built into `java.lang.ClassLoader`, but it's not physically enforced by the JVM — a custom class loader _can_ override `loadClass()` and break the delegation order (some frameworks do this intentionally). This is exactly what Spring Boot's `LaunchedURLClassLoader` does in certain cases, and it's part of how plugin systems and app servers achieve isolation between modules that would otherwise conflict. But by default, and for the vast majority of code, the parent-first rule is what governs how every class in your program gets resolved.


[[Java]]