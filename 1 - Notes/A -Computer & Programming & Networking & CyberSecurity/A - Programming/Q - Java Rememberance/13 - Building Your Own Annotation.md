

Think of an annotation as a **sticky note** you paste on code. On its own, the note does nothing — but if *something* reads it, magic happens. This blueprint shows you how to create, place, and read your own sticky notes step by step.

We'll build a real one along the way: **`@RunOnce`** — a note that says *"run this method only one time."* Simple, useful, and it teaches every concept.

---

## Step 0 — Know What You're Building

Before touching code, answer three questions:

| Question | Why it matters |
|---|---|
| **What will this note mean?** | Keeps the design focused. |
| **Where will it go?** (class / method / field / parameter) | Determines `@Target`. |
| **Who will read it, and when?** (compiler / reflection / runtime) | Determines `@Retention`. |

For `@RunOnce`:
- **Meaning:** "Call this method at most once per instance."
- **Where:** On methods.
- **Who reads it:** Our own code, at runtime, via reflection.
- **Retention:** `RUNTIME`.

Answer these **before writing any code** — it saves a lot of rework.

---

## Step 1 — Create the Annotation Type

Make a new file. The name of the file matches the annotation. It looks like an interface, but starts with `@`.

```java
// RunOnce.java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)   // keep it visible at runtime
@Target(ElementType.METHOD)           // only on methods
public @interface RunOnce {
    // members go here (we'll add them next)
}
```

**Three things to notice:**

1. `@interface` — that's how you declare an annotation. Not `class`, not `interface`.
2. `@Retention(RUNTIME)` — a **meta-annotation** (a note on a note). Tells the compiler how long to keep it.
3. `@Target(METHOD)` — another meta-annotation. Tells the compiler where the note is allowed.

That's the minimum skeleton. Compile it and you already have a working annotation.

---

## Step 2 — Add Fields (Called "Members")

Members look like methods, but they're really **fields with defaults**.

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RunOnce {
    String reason() default "no reason given";
    int maxCalls()  default 1;
}
```

Use them like this:

```java
@RunOnce(reason = "init database", maxCalls = 1)
public void init() { ... }

@RunOnce                      // uses defaults
public void warmCache() { ... }
```

### Rules for Members (memorize these)

- Only these types are allowed:
  - primitives (`int`, `boolean`, …), `String`, `Class<?>`, enums, other annotations, and **arrays** of those.
- **No** objects, no lambdas, no `null` defaults.
- Every member **must** have a value when used — either in the annotation or via `default`.
- If the annotation has **only one member named `value`**, you can write `@MyAnno("hi")` instead of `@MyAnno(value = "hi")`.

---

## Step 3 — Choose the Right `@Retention`

This is the most important decision. Pick one:

| Value | Meaning | Use when… |
|---|---|---|
| `SOURCE` | Compiler sees it, then throws it away. | Compiler/lint hints (`@Override`). |
| `CLASS` | Stored in `.class` file, invisible to reflection. | Bytecode tools (ProGuard, AspectJ). |
| `RUNTIME` | Stored and visible via reflection. | Frameworks, our `@RunOnce`. |

**Friendly rule:** if in doubt and you'll read it at runtime, use `RUNTIME`. If you only need a compiler check, use `SOURCE`.

---

## Step 4 — Choose the Right `@Target`

Restrict where the note can go, so mistakes happen at compile time, not in production.

```java
@Target(ElementType.METHOD)
```

You can list multiple:

```java
@Target({ElementType.FIELD, ElementType.METHOD})
```

Common targets:

| Target | Where the note can live |
|---|---|
| `TYPE` | Classes, interfaces, enums |
| `FIELD` | Instance/static fields |
| `METHOD` | Methods |
| `CONSTRUCTOR` | Constructors |
| `PARAMETER` | Method/constructor parameters |
| `LOCAL_VARIABLE` | Local variables (⚠️ not readable by reflection) |
| `ANNOTATION_TYPE` | On other annotations (meta-annotations) |
| `PACKAGE` | `package-info.java` |

---

## Step 5 — (Optional) Add Meta-Annotations for Polish

You don't need these, but they make your annotation behave like a pro's.

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@Documented                                       // shows in Javadoc
@Inherited                                        // (only meaningful on classes)
public @interface RunOnce {
    String reason() default "";
    int maxCalls()  default 1;
}
```

- **`@Documented`** → include in Javadoc.
- **`@Inherited`** → subclasses inherit the annotation (class-level only).
- **`@Repeatable`** → allow the same note more than once (see Step 8).

---

## Step 6 — Write the "Reader" (This Is the Real Work)

An annotation without a reader is a note no one reads. The reader uses **reflection** to inspect the annotated element and act.

Here's a tiny framework for `@RunOnce`:

```java
import java.lang.reflect.Method;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class RunOnceInvoker {

    // Tracks which methods have already run per instance
    private static final Set<String> DONE = ConcurrentHashMap.newKeySet();

    public static Object call(Object target, String methodName, Object... args)
            throws Exception {

        Class<?> clazz = target.getClass();
        Method method = findMethod(clazz, methodName, args);
        RunOnce ann = method.getAnnotation(RunOnce.class);

        // No note? Just call it.
        if (ann == null) {
            return method.invoke(target, args);
        }

        // Build a unique key: instance identity + method name
        String key = System.identityHashCode(target) + "#" + method.getName();

        // If already done, skip silently
        if (DONE.contains(key)) {
            System.out.println("Skipping " + methodName + " (" + ann.reason() + ")");
            return null;
        }

        try {
            Object result = method.invoke(target, args);
            DONE.add(key);   // mark success
            return result;
        } catch (Exception e) {
            throw e;
        }
    }

    private static Method findMethod(Class<?> c, String name, Object[] args) {
        for (Method m : c.getDeclaredMethods()) {
            if (m.getName().equals(name) && m.getParameterCount() == args.length) {
                m.trySetAccessible();
                return m;
            }
        }
        throw new IllegalArgumentException("No method " + name);
    }
}
```

**What this reader does, in order:**

1. Finds the `Method` by name + argument count.
2. Asks: "Is there a `@RunOnce` on it?" (`method.getAnnotation(RunOnce.class)`)
3. If yes → checks whether it has already run, uses the annotation's `reason()` for logging.
4. If no → just invokes the method as normal.

That's the entire idea of an annotation-driven framework in 40 lines.

---

## Step 7 — Use It

```java
public class Database {

    @RunOnce(reason = "open connection pool")
    public void connect() {
        System.out.println("Connecting…");
    }

    public void query() {
        System.out.println("Running query");
    }
}
```

```java
public class Demo {
    public static void main(String[] args) throws Exception {
        Database db = new Database();

        RunOnceInvoker.call(db, "connect");   // Connecting…
        RunOnceInvoker.call(db, "connect");   // Skipping connect (open connection pool)
        RunOnceInvoker.call(db, "query");     // Running query
    }
}
```

🎉 You just built an annotation **and** the framework that gives it meaning.

---

## Step 8 — Going Further: `@Repeatable`

Sometimes one sticky note isn't enough. Suppose we want **multiple** `@RunOnce` notes with different reasons:

```java
// The container (holds an array of the repeatable one)
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RunOnceList {
    RunOnce[] value();
}
```

```java
// The repeatable one
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@Repeatable(RunOnceList.class)
public @interface RunOnce {
    String reason();
}
```

Usage:

```java
@RunOnce(reason = "first")
@RunOnce(reason = "second")
public void multi() { }
```

Reading them:

```java
RunOnce[] all = method.getAnnotationsByType(RunOnce.class);
```

No need to touch the container directly — `getAnnotationsByType` unwraps it for you.

---

## Step 9 — The Complete Blueprint (Checklist)

Print this. Tick as you go.

```
[ ] 1. Answer the three questions:
        - What does it mean?
        - Where does it go?
        - Who reads it, when?

[ ] 2. Create <Name>.java with:
        public @interface <Name> { }

[ ] 3. Add @Retention:
        SOURCE | CLASS | RUNTIME

[ ] 4. Add @Target:
        one or more ElementType values

[ ] 5. (Optional) Add meta-annotations:
        @Documented, @Inherited, @Repeatable

[ ] 6. Add members with defaults:
        type name() default value;
        (only primitives, String, Class, enums, annotations, arrays)

[ ] 7. Write the reader:
        - get Method / Field / Constructor
        - .getAnnotation(YourAnno.class)
        - if null → skip
        - if present → act using the member values

[ ] 8. (Optional) Support repetition:
        - a container annotation with T[] value()
        - @Repeatable(Container.class) on the leaf
        - read via getAnnotationsByType(...)

[ ] 9. Test it:
        - annotated and un-annotated cases
        - default vs. supplied members
        - private / protected members if reflection is used
        - module opens if on Java 9+

[ ] 10. Document it:
        - a Javadoc note explaining retention, target, and reader
```

---

## Step 10 — Common Mistakes (and How to Avoid Them)

| Mistake | Symptom | Fix |
|---|---|---|
| Forgot `@Retention(RUNTIME)` | `getAnnotation()` returns null | Add the meta-annotation. |
| Wrong `@Target` | Compiler error at use site | Add the missing `ElementType`. |
| Used an unsupported member type | Compile error | Stick to primitives/String/Class/enum/annotation/arrays. |
| No default and no value at use site | Compile error | Add `default` or supply the value. |
| Reader doesn't call `trySetAccessible()` | `IllegalAccessException` on private members | Call it before `invoke`/`get`/`set`. |
| Reflections into non-open modules (Java 9+) | `InaccessibleObjectException` | Add `opens` in `module-info.java`. |
| Reading annotation on `LOCAL_VARIABLE` | Always null | Reflection can't see locals. |
| Recreating the same proxy over and over | Minor overhead | JVM already caches it — no action needed. |
| Storing mutable state in the annotation | Impossible — members are constants | Move state to the reader. |

---

## Step 11 — Mental Model (The One Sentence to Remember)

> **You write the note; you write the reader. The JVM just stores and returns the note.**

That's the entire game. Frameworks like Spring, JUnit, and Hibernate are thousands of these little note-writer + note-reader pairs glued together.

---

## Bonus — Two More Quick Blueprints

### A) A Field Marker: `@Sensitive`

```java
@Retention(RUNTIME)
@Target(FIELD)
public @interface Sensitive { }
```

Reader (in a logger/serializer):

```java
for (Field f : obj.getClass().getDeclaredFields()) {
    if (f.isAnnotationPresent(Sensitive.class)) {
        f.trySetAccessible();
        f.set(obj, "***");
    }
}
```

### B) A Parameter Rule: `@Range`

```java
@Retention(RUNTIME)
@Target(PARAMETER)
public @interface Range { int min(); int max(); }
```

Reader (in a validator):

```java
for (Parameter p : method.getParameters()) {
    Range r = p.getAnnotation(Range.class);
    if (r != null) {
        int v = (int) args[p.getIndex()];
        if (v < r.min() || v > r.max()) throw new IllegalArgumentException();
    }
}
```

Same three ideas every time: **declare → place → read**.

---

## You Did It 🎉

You now know the full lifecycle of a custom annotation:

1. **Declare** it (`@interface` + meta-annotations + members).
2. **Place** it on code (respecting `@Target`).
3. **Read** it via reflection and act on its values.
4. **Optional:** make it repeatable, inherited, or documented.
5. **Ship** it with a reader that gives it meaning.

Once this clicks, every annotation-driven framework stops feeling magical — it's just people writing friendly sticky notes and other people reading them.

[[Java]]