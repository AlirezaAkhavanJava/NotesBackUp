
# Understanding Java's Class Loader Hierarchy (JDK 25)

A tutorial on the Bootstrap, Platform, and Application class loaders — what they are, why there are three of them, and why the design is built this way.

---

## 1. What Is the Bootstrap Class Loader?

The **Bootstrap Class Loader** (also called the "primordial" class loader) is part of the JVM's core implementation. Unlike the other class loaders, it is written in **native code** (typically C/C++), not in Java.

### Key characteristics

- **Not a Java object.** Unlike Platform or Application class loaders (which are real instances of `java.lang.ClassLoader` subclasses), the Bootstrap Class Loader has no corresponding Java object.
- **Returns `null`.** If you call `getClassLoader()` on a class it loaded (like `java.lang.String`), you get `null` back — because there's no Java-level representation of it.

```java
System.out.println(String.class.getClassLoader()); // prints: null
```

- **What it loads.** The core Java API classes — mainly the `java.base` module (or historically, the bootstrap classpath / `rt.jar` before Java 9). Think `java.lang.*`, `java.util.*`, and the fundamental building blocks the JVM itself needs.
- **Why native code.** It has to load the foundational classes the JVM depends on — including `Object`, `Class`, and `ClassLoader` itself — before any Java code can run at all. This is a chicken-and-egg problem: you can't write a Java-based loader for `Object` if `Object` doesn't exist yet. So it has to be native.
- **Top of the hierarchy.** It sits at the root of the class loader delegation model, with no parent of its own.

---

## 2. Does It Still Exist in Modern Java (JDK 25)?

**Yes.** The three-tier class loader architecture hasn't fundamentally changed since Java 9 introduced the module system (JPMS), and that structure carries through to JDK 25.

### The three loaders today

|Loader|Role|Java Object?|
|---|---|---|
|**Bootstrap Class Loader**|Loads `java.base` and other foundational JDK internals|No — native code, returns `null`|
|**Platform Class Loader**|Loads other built-in JDK modules (`java.sql`, `java.desktop`, etc.)|Yes|
|**Application/System Class Loader**|Loads your app's classes and classpath/modulepath dependencies|Yes|

### What's changed since Java 9 (cumulative, not JDK-25-specific)

- **No more `rt.jar`** — JDK internals now live in the module system (`jrt:/` filesystem), not a flat jar.
- **Extension mechanism removed** — the old `ext` directories / `-Djava.ext.dirs` mechanism is gone. This is why "Extension Class Loader" became "Platform Class Loader."
- **Strong encapsulation** — the module system restricts what's reachable via reflection across loaders (internal JDK APIs are hidden unless explicitly opened via `--add-opens`), but this doesn't remove or replace the bootstrap loader itself.

The mental model stays the same: bootstrap loader is still native, still parentless, still the root of delegation.

---

## 3. Understanding the Platform Class Loader

### The core idea

Think of the JDK in layers of "how essential" something is:

- **Absolute core** (`Object`, `String`, `ArrayList`) → **Bootstrap**
- **Built into Java, but more specialized/optional** (SQL support, GUI, XML processing) → **Platform**
- **Your own code and libraries** → **Application**

The Platform Class Loader exists because not every JDK module is needed by every program. A simple console app doesn't need database drivers or GUI classes loaded — but they still ship as part of the JDK for programs that do need them.

### Concretely: what lives where

```java
// Core — Bootstrap
String.class.getClassLoader();          // null
ArrayList.class.getClassLoader();       // null

// Platform modules — Platform ClassLoader
java.sql.Connection.class.getClassLoader();          // platform loader
java.awt.Frame.class.getClassLoader();               // platform loader (GUI)
javax.xml.parsers.SAXParser.class.getClassLoader();  // platform loader

// Your code — Application ClassLoader
YourMainClass.class.getClassLoader();   // app/system loader
```

### Try it yourself

```java
public class LoaderDemo {
    public static void main(String[] args) {
        System.out.println("String: " + String.class.getClassLoader());
        System.out.println("Connection: " + java.sql.Connection.class.getClassLoader());
        System.out.println("MyClass: " + LoaderDemo.class.getClassLoader());
    }
}
```

Expected output:

```
String: null
Connection: jdk.internal.loader.ClassLoaders$PlatformClassLoader@...
MyClass: jdk.internal.loader.ClassLoaders$AppClassLoader@...
```

### Why "Platform" and not "Extension"?

Before Java 9, this same role was played by the **Extension Class Loader**. You could drop `.jar` files into `$JAVA_HOME/lib/ext` and they'd auto-load as "extensions" — that mechanism was removed.

Since Java 9's module system, the JDK is broken into named modules:

- `java.base` — core, loaded by Bootstrap
- `java.sql` — loaded by Platform
- `java.desktop` — loaded by Platform
- `java.xml` — loaded by Platform

The loader's job is the same as the old Extension loader's — "load JDK stuff that isn't core" — just renamed and reworked to fit the module system.

### Delegation: how a class request travels

When your code asks for a class, the request goes **up** the chain first:

```
Application ClassLoader
        ↑ (asks parent first)
Platform ClassLoader
        ↑ (asks parent first)
Bootstrap ClassLoader
```

So `import java.sql.Connection;` doesn't get loaded by the Application loader directly — it delegates up to Platform, which recognizes `java.sql` as one of its modules and loads it from there.

---

## 4. Why Three Separate Class Loaders?

### Why more than one at all?

**1. Security — trust boundaries**

Class loaders separate "trusted" code from "untrusted" code. The JVM uses _which loader loaded a class_ as a security signal. A single loader would give no way to distinguish trusted JDK internals from some jar downloaded off the internet.

**2. Namespace isolation**

Two classes with the _same fully-qualified name_ can coexist in a JVM if loaded by different class loaders — the JVM treats `(ClassName, ClassLoader)` as the real identity, not just the name. This is how app servers, plugin systems, and Spring Boot's fat-jar mechanism isolate dependencies from each other.

**3. Lazy/on-demand loading of optional modules**

Not every program needs `java.desktop` or `java.sql`. Splitting into independently loaded modules means the JVM only loads what's referenced, saving startup time and memory.

**4. Clean delegation for class resolution**

Because loaders ask their parent first, you get a predictable, hierarchical search order — a single flat loader would need some other mechanism to decide precedence.

### Why can't Bootstrap just load Platform's modules too?

This is a **design/engineering choice**, not a hard technical impossibility — but there are solid reasons behind it:

**A. Bootstrap is native code on purpose, and extending it is expensive**

Bootstrap is C/C++ inside the JVM because it has to load the classes the JVM itself depends on (`Object`, `Class`, `ClassLoader`, `String`) before any Java bytecode can run — a chicken-and-egg problem.

But `java.sql`, `java.desktop`, `java.xml`, etc. don't have that problem — they depend on `java.base` already being up and running. Once `java.base` exists, the rest can be loaded with ordinary Java-level class loader logic, which is easier to write, debug, and maintain than native code.

Keeping Bootstrap minimal (just `java.base`) means most of the JDK's loading logic lives in normal, maintainable Java code instead of native code.

**B. Keeping Bootstrap minimal reduces the trusted attack surface**

Anything loaded by Bootstrap is maximally trusted and has no parent to delegate to. Minimizing what's loaded at that tier is a deliberate security posture — fewer classes means a smaller trusted computing base at the most privileged level.

**C. Historical continuity**

The 3-tier shape (Bootstrap → Extension/Platform → Application) predates the module system, going back to early Java. Java 9 reused and adapted this existing structure (renaming Extension → Platform) rather than inventing something new, to avoid breaking code and tooling that already relied on this hierarchy.

### Could it have been designed with just 2 loaders?

Technically yes — nothing requires exactly 3. But a 2-loader design (Bootstrap + Application) would lose:

- The ability to keep Bootstrap as pure, minimal native code
- A finer-grained trust tier between "absolutely core" and "optional but JDK-shipped"
- The flexibility for modules like `java.desktop` to be conditionally excluded

That last point has a strong modern justification: **`jlink`** (Java 9+) lets you build a minimal custom JRE with only the modules your app needs, stripping out things like `java.desktop` entirely. This only works cleanly because non-core module loading is flexible, Java-level logic in the Platform loader — not hardcoded into native Bootstrap code.

---

## Summary

- **Bootstrap Class Loader**: native code, loads `java.base`, no parent, returns `null` from `getClassLoader()`.
- **Platform Class Loader**: Java object, loads other built-in JDK modules (`java.sql`, `java.desktop`, `java.xml`), replaced "Extension Class Loader" in Java 9.
- **Application Class Loader**: Java object, loads your code and dependencies.
- This hierarchy is unchanged in JDK 25.
- The separation exists for **security (trust boundaries)**, **namespace isolation**, **on-demand module loading**, and a **clean delegation model** — and keeping Bootstrap minimal keeps the JVM's most trusted, native-code layer as small and maintainable as possible.

## Next Steps

- Explore `jlink` to build a stripped-down custom Java runtime excluding unused modules.
- Look at how Spring Boot's `LaunchedURLClassLoader` (a child of the Application ClassLoader) loads your app and its bundled dependencies from nested jars in an executable fat jar.

[[Java]]