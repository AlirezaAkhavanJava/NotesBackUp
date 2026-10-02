# Java Reflection API & Custom Functional Annotations

## Part 1: Java Reflection API Fundamentals

Reflection lets you inspect and manipulate classes, methods, fields, and annotations **at runtime** — even when you don't know them at compile time.

### The Entry Points

```java
// Three ways to get a Class<?> object
Class<?> c1 = String.class;              // literal
Class<?> c2 = "hello".getClass();        // from instance
Class<?> c3 = Class.forName("java.lang.String"); // from name
```

### Inspecting a Class

```java
public class Demo {
    public static void main(String[] args) throws Exception {
        Class<?> clazz = Class.forName("java.util.ArrayList");

        System.out.println("Name: " + clazz.getName());
        System.out.println("Simple: " + clazz.getSimpleName());
        System.out.println("Modifiers: " + Modifier.toString(clazz.getModifiers()));
        System.out.println("Superclass: " + clazz.getSuperclass());

        // Interfaces
        for (Class<?> i : clazz.getInterfaces()) {
            System.out.println("Implements: " + i.getName());
        }

        // Constructors
        for (Constructor<?> ctor : clazz.getConstructors()) {
            System.out.println("Ctor: " + ctor);
        }

        // Methods (public only with getMethods; all with getDeclaredMethods)
        for (Method m : clazz.getDeclaredMethods()) {
            System.out.println("Method: " + m.getName()
                + " -> " + m.getReturnType().getSimpleName());
        }

        // Fields
        for (Field f : clazz.getDeclaredFields()) {
            System.out.println("Field: " + f.getName());
        }
    }
}
```

### Creating Instances and Invoking Methods

```java
Class<?> clazz = Class.forName("com.example.Person");
Constructor<?> ctor = clazz.getConstructor(String.class, int.class);
Object person = ctor.newInstance("Alice", 30);

Method getName = clazz.getMethod("getName");
String name = (String) getName.invoke(person);

Method setName = clazz.getMethod("setName", String.class);
setName.invoke(person, "Bob");
```

### Accessing Private Members

```java
Field secret = clazz.getDeclaredField("apiKey");
secret.setAccessible(true);          // bypass access checks
String key = (String) secret.get(person);
secret.set(person, "new-key");
```

> ⚠️ **Caveats**: Reflection is slower than direct calls, breaks compile-time safety, can break with modules (Java 9+), and `setAccessible(true)` may fail under a SecurityManager.

---

## Part 2: Annotations — The Basics

Annotations are **metadata**. Declared with `@interface`:

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)   // keep at runtime for reflection
@Target(ElementType.METHOD)           // where it can be applied
public @interface MyAnnotation {
    String value() default "";
    int priority() default 0;
}
```

### Key Meta-Annotations

| Meta-Annotation | Purpose |
|---|---|
| `@Retention` | SOURCE / CLASS / RUNTIME |
| `@Target` | METHOD, FIELD, TYPE, PARAMETER, etc. |
| `@Inherited` | Subclasses inherit the annotation |
| `@Documented` | Include in Javadoc |
| `@Repeatable` | Allow multiple instances |

### Reading Annotations via Reflection

```java
Method m = MyClass.class.getMethod("doWork");

if (m.isAnnotationPresent(MyAnnotation.class)) {
    MyAnnotation a = m.getAnnotation(MyAnnotation.class);
    System.out.println(a.value() + " / " + a.priority());
}

// All annotations
for (Annotation ann : m.getAnnotations()) {
    System.out.println(ann);
}
```

---

## Part 3: Custom Functional Annotations

A **functional annotation** here means an annotation whose value is a **behavior** — typically a lambda or method reference — that the framework invokes via reflection.

Java annotations can only hold these types as members: primitives, `String`, `Class`, enums, other annotations, and **arrays of those**. So you *cannot* directly put a lambda in an annotation. Instead, the common pattern is:

> **Annotation points to a class that implements a functional interface.**

### Step 1: Define a Functional Interface

```java
@FunctionalInterface
public interface Validator<T> {
    boolean isValid(T value);
}
```

### Step 2: Define the Annotation

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface ValidateWith {
    Class<? extends Validator<?>> value();
    String message() default "Invalid value";
}
```

### Step 3: Provide Validator Implementations

```java
public class NotEmptyValidator implements Validator<String> {
    @Override
    public boolean isValid(String value) {
        return value != null && !value.trim().isEmpty();
    }
}

public class PositiveValidator implements Validator<Integer> {
    @Override
    public boolean isValid(Integer value) {
        return value != null && value > 0;
    }
}
```

### Step 4: Apply the Annotation

```java
public class User {
    @ValidateWith(value = NotEmptyValidator.class, message = "Name required")
    private String name;

    @ValidateWith(value = PositiveValidator.class, message = "Age must be > 0")
    private int age;

    // getters/setters...
}
```

### Step 5: Build the Reflection-Based Engine

```java
public class ValidatorEngine {

    public static List<String> validate(Object obj) throws Exception {
        List<String> errors = new ArrayList<>();
        Class<?> clazz = obj.getClass();

        for (Field field : clazz.getDeclaredFields()) {
            ValidateWith ann = field.getAnnotation(ValidateWith.class);
            if (ann == null) continue;

            field.setAccessible(true);
            Object value = field.get(obj);

            // Instantiate the validator class reflectively
            Validator<Object> validator =
                (Validator<Object>) ann.value().getDeclaredConstructor().newInstance();

            if (!validator.isValid(value)) {
                errors.add(field.getName() + ": " + ann.message());
            }
        }
        return errors;
    }
}
```

### Step 6: Use It

```java
User u = new User();
u.setName("");        // invalid
u.setAge(-5);         // invalid

for (String err : ValidatorEngine.validate(u)) {
    System.out.println(err);
}
// Output:
// name: Name required
// age: Age must be > 0
```

---

## Part 4: A More Powerful Pattern — Method-Level "Command" Annotations

This pattern is the basis of frameworks like JUnit (`@Test`), Spring (`@RequestMapping`), and Jackson (`@JsonProperty`).

### Define the Functional Interface

```java
@FunctionalInterface
public interface Handler {
    Object handle(Object... args) throws Exception;
}
```

### Define the Annotation

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface RegisterHandler {
    String name();
}
```

### A Concrete Handler

```java
@RegisterHandler(name = "greet")
public class GreetHandler implements Handler {
    @Override
    public Object handle(Object... args) {
        return "Hello, " + args[0] + "!";
    }
}
```

### A Registry Driven by Classpath Scanning

```java
public class HandlerRegistry {
    private final Map<String, Handler> handlers = new HashMap<>();

    public void scan(String packageName) throws Exception {
        // In real code use ClassGraph / Reflections library.
        // Here we hardcode for brevity:
        List<Class<?>> classes = List.of(GreetHandler.class);

        for (Class<?> c : classes) {
            RegisterHandler ann = c.getAnnotation(RegisterHandler.class);
            if (ann == null) continue;
            if (!Handler.class.isAssignableFrom(c)) continue;

            Handler h = (Handler) c.getDeclaredConstructor().newInstance();
            handlers.put(ann.name(), h);
        }
    }

    public Object dispatch(String name, Object... args) throws Exception {
        Handler h = handlers.get(name);
        if (h == null) throw new IllegalArgumentException("No handler: " + name);
        return h.handle(args);
    }
}
```

### Usage

```java
HandlerRegistry registry = new HandlerRegistry();
registry.scan("com.example.handlers");

Object result = registry.dispatch("greet", "World");
System.out.println(result); // Hello, World!
```

---

## Part 5: Real-World Recipe — Retry Annotation

A practical "functional" annotation with a lambda-like behavior configured via class reference:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Retry {
    int times() default 3;
    long delayMs() default 100;
    Class<? extends Exception>[] on() default {Exception.class};
}
```

```java
public class RetryInvoker {

    public static Object invoke(Object target, String methodName, Object... args)
            throws Exception {
        Class<?> clazz = target.getClass();
        Method method = findMethod(clazz, methodName, args);
        Retry retry = method.getAnnotation(Retry.class);
        if (retry == null) return method.invoke(target, args);

        Exception last = null;
        for (int i = 0; i < retry.times(); i++) {
            try {
                return method.invoke(target, args);
            } catch (InvocationTargetException e) {
                Throwable cause = e.getCause();
                if (!matches(cause, retry.on())) throw e;
                last = (Exception) cause;
                Thread.sleep(retry.delayMs());
            }
        }
        throw last;
    }

    private static boolean matches(Throwable t, Class<? extends Exception>[] types) {
        for (Class<?> c : types) if (c.isInstance(t)) return true;
        return false;
    }

    private static Method findMethod(Class<?> c, String name, Object[] args) {
        for (Method m : c.getDeclaredMethods()) {
            if (m.getName().equals(name) && m.getParameterCount() == args.length)
                return m;
        }
        throw new IllegalArgumentException("Method not found: " + name);
    }
}
```

```java
public class Service {
    private int attempts = 0;

    @Retry(times = 3, delayMs = 50, on = {RuntimeException.class})
    public String fetch() {
        attempts++;
        if (attempts < 3) throw new RuntimeException("flaky");
        return "OK after " + attempts + " tries";
    }
}
```

---

## Part 6: Performance & Best Practices

| Concern | Recommendation |
|---|---|
| **Speed** | Cache `Method`/`Constructor`/`Field` objects; use `MethodHandles` for hot paths |
| **Access** | Prefer public APIs; `setAccessible(true)` has module restrictions in Java 9+ |
| **Errors** | Wrap checked reflection exceptions; unwrap `InvocationTargetException.getCause()` |
| **Safety** | Validate `Class<?>` references (e.g., ensure they implement your interface) |
| **Scanning** | Use **ClassGraph** or **Reflections** library instead of hand-rolled scanning |
| **Records/Sealed** | `Class.getRecordComponents()` works for records; sealed classes via `isSealed()` |
| **Type safety** | Always bound the annotation's `Class<?>` with an interface (`Class<? extends Validator<?>>`) |

### Bonus: Invocation with `MethodHandles` (faster than `Method.invoke`)

```java
MethodHandles.Lookup lookup = MethodHandles.lookup();
MethodHandle mh = lookup.unreflect(method);
Object result = mh.invokeWithArguments(target, arg1, arg2);
```

---

## Summary

1. **Reflection** lets you inspect and invoke code at runtime — the backbone of every Java framework.
2. **Annotations** are typed metadata; with `@Retention(RUNTIME)` they become visible to reflection.
3. A **custom functional annotation** typically points to a class implementing a **functional interface** — that's how you inject behavior (the closest Java gets to "lambda in an annotation").
4. Build small engines (`ValidatorEngine`, `RetryInvoker`, `HandlerRegistry`) that read annotations via reflection and drive behavior — this is exactly how JUnit, Spring, and Hibernate work under the hood.

**Next steps to explore**: `MethodHandles`, dynamic proxies (`java.lang.reflect.Proxy`) for interface-based AOP, `AnnotationProcessor` for compile-time codegen, and ClassGraph for classpath scanning.

[[Java]]