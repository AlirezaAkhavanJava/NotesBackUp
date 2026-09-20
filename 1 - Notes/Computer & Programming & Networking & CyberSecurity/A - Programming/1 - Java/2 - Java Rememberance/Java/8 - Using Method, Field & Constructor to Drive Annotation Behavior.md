# Using Method, Field & Constructor to Drive Annotation Behavior

The three core classes in `java.lang.reflect` — `Method`, `Field`, and `Constructor` — are all **`AnnotatedElement`** implementations. This means each one exposes the same annotation-reading API, but each targets a **different kind of program element**. In this guide we'll:

1. Learn the shared `AnnotatedElement` API.
2. See how annotations are **targeted** to each element type.
3. Build a working example that reads annotations from **methods, fields, and constructors** and **executes** behavior for each.
4. Compare **access types** (public / protected / package-private / private) and how to reach into each.

---

## Part 1: The Shared API — `AnnotatedElement`

`Method`, `Field`, `Constructor`, `Class`, `Parameter`, and `Package` all implement `java.lang.reflect.AnnotatedElement`:

```java
public interface AnnotatedElement {
    boolean isAnnotationPresent(Class<? extends Annotation> annotationClass);
    <T extends Annotation> T getAnnotation(Class<T> annotationClass);
    Annotation[] getAnnotations();                  // includes @Inherited from super
    Annotation[] getDeclaredAnnotations();          // only on this element
    <T extends Annotation> T[] getAnnotationsByType(Class<T> annotationClass);
    <T extends Annotation> T[] getDeclaredAnnotationsByType(Class<T> annotationClass);
}
```

So once you obtain a `Method`, `Field`, or `Constructor` object, reading annotations is uniform:

```java
@MyAnno String doWork();
Field f = clazz.getDeclaredField("name");
MyAnno a = f.getAnnotation(MyAnno.class);
```

What differs is **how you obtain the element**, **what its `@Target` allows**, and **how you invoke/read/write it**.

---

## Part 2: Targeting — Which Annotation Goes Where

Every annotation declares where it may appear via `@Target`:

```java
@Target(ElementType.METHOD)     // → Method
@Target(ElementType.FIELD)      // → Field
@Target(ElementType.CONSTRUCTOR)// → Constructor
@Target(ElementType.PARAMETER)  // → Parameter (of Method/Constructor)
@Target(ElementType.TYPE)       // → Class, interface, enum
@Target(ElementType.ANNOTATION_TYPE)
@Target(ElementType.LOCAL_VARIABLE)  // not visible via reflection!
@Target(ElementType.PACKAGE)
```

**Reflection can read annotations on**: `TYPE`, `FIELD`, `METHOD`, `CONSTRUCTOR`, `PARAMETER`, `ANNOTATION_TYPE`, `PACKAGE`, `TYPE_USE`, `MODULE`.
**Reflection cannot read**: `LOCAL_VARIABLE` (no runtime object holds it).

### Define Three Annotations, One Per Element

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Inject {
    String value() default "";       // a key / bean name
    boolean required() default true;
}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Invoke {
    String action();
    int order() default 0;
}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.CONSTRUCTOR)
public @interface Factory {
    String produces();
}
```

### Apply Them to a Class

```java
public class Service {

    @Inject(value = "db.url", required = true)
    private String dbUrl;

    @Inject(value = "db.timeout")
    protected int timeout = 30;      // non-private field

    @Inject                          // package-private
    String region = "eu-west-1";

    @Factory(produces = "primary")
    public Service(@Inject("ctor.arg") String name) {  // ctor + param annotation
        this.dbUrl = name;
    }

    public Service() {}

    @Invoke(action = "start", order = 1)
    public void start() { System.out.println("starting with " + dbUrl); }

    @Invoke(action = "ping", order = 2)
    private String ping(String echo) { return "pong:" + echo; }
}
```

---

## Part 3: Reading Annotations from Each Element Type

### 3.1 `Field` — Read and Write Values

```java
Class<?> clazz = Service.class;
Object svc = clazz.getDeclaredConstructor().newInstance();

for (Field field : clazz.getDeclaredFields()) {
    Inject ann = field.getAnnotation(Inject.class);
    if (ann == null) continue;

    // Read current value
    field.setAccessible(true);              // needed for private/protected
    Object current = field.get(svc);

    System.out.printf("Field %s (key=%s, required=%s) = %s%n",
        field.getName(), ann.value(), ann.required(), current);

    // Write a new value based on the annotation key
    if (field.getType() == String.class) {
        field.set(svc, "resolved:" + ann.value());
    }
}
```

**Key `Field` methods**:
- `get(Object)`, `set(Object, Object)` — read/write an instance field.
- `getType()` — the declared type.
- `setAccessible(true)` — required for non-public fields.
- For primitives, use `getInt/setInt`, `getBoolean/setBoolean`, etc., to avoid boxing.

### 3.2 `Method` — Invoke Behavior

```java
// Sort by the annotation's "order" so we control execution sequence
List<Method> invokables = new ArrayList<>();
for (Method m : clazz.getDeclaredMethods()) {
    if (m.isAnnotationPresent(Invoke.class)) invokables.add(m);
}
invokables.sort(Comparator.comparingInt(m ->
    m.getAnnotation(Invoke.class).order()));

for (Method m : invokables) {
    Invoke ann = m.getAnnotation(Invoke.class);
    m.setAccessible(true);                    // allow private methods

    // Build arguments for the method
    Object[] args = new Object[m.getParameterCount()];
    Class<?>[] types = m.getParameterTypes();
    for (int i = 0; i < types.length; i++) {
        args[i] = defaultValueFor(types[i]);  // helper for primitives/refs
    }

    Object result = m.invoke(svc, args);
    System.out.printf("@Invoke(%s) → %s() = %s%n",
        ann.action(), m.getName(), result);
}
```

**Key `Method` methods**:
- `invoke(Object target, Object... args)` — call it.
- `getParameterTypes()`, `getParameterCount()`, `getReturnType()`.
- `getParameters()` — returns `Parameter[]`, each an `AnnotatedElement` (useful when annotations are on parameters).
- `getExceptionTypes()` — checked exceptions you must handle.

### 3.3 `Constructor` — Instantiate with Metadata

```java
for (Constructor<?> ctor : clazz.getDeclaredConstructors()) {
    Factory factory = ctor.getAnnotation(Factory.class);
    if (factory == null) continue;

    // Read parameter annotations directly
    Parameter[] params = ctor.getParameters();
    Object[] args = new Object[params.length];
    for (int i = 0; i < params.length; i++) {
        Inject p = params[i].getAnnotation(Inject.class);   // same @Inject, different target
        args[i] = (p != null) ? "ctor:" + p.value() : null;
    }

    ctor.setAccessible(true);
    Object instance = ctor.newInstance(args);
    System.out.printf("@Factory(%s) → %s%n", factory.produces(), instance);
}
```

**Key `Constructor` methods**:
- `newInstance(Object... args)` — the only way to construct via reflection (replaces deprecated `Class.newInstance()`).
- `getParameterTypes()`, `getParameters()`, `getExceptionTypes()`.
- Same `setAccessible(true)` rule applies.

> To make `@Inject` legal on both fields **and** parameters, broaden its target:
> ```java
> @Target({ElementType.FIELD, ElementType.PARAMETER})
> ```

---

## Part 4: Access Types — What `setAccessible` Actually Unlocks

Access is governed at two levels: (1) which members `Class`'s getters return, and (2) whether you can touch them.

### 4.1 Choosing the Right Getter

| Getter | Returns | Includes |
|---|---|---|
| `getFields()` | `Field[]` | **public only**, including inherited |
| `getDeclaredFields()` | `Field[]` | **all access levels** of this class only |
| `getMethods()` | `Method[]` | public (this + inherited) |
| `getDeclaredMethods()` | `Method[]` | all access levels, this class only |
| `getConstructors()` | `Constructor<?>[]` | public only |
| `getDeclaredConstructors()` | `Constructor<?>[]` | all access levels |
| `getField(name)` / `getMethod(name, ...)` | single | public (+ inherited) |
| `getDeclaredField(name)` / `getDeclaredMethod(...)` | single | any access, this class only |

Rule of thumb: **if you need private/protected/package-private, use the `getDeclared*` variants.**

### 4.2 The Four Access Levels in Action

| Modifier | `getDeclared*` finds it? | `get*` finds it? | Needs `setAccessible(true)`? |
|---|---|---|---|
| `public` | ✅ | ✅ | ❌ |
| `protected` | ✅ | ❌ | ✅ |
| *(package-private)* | ✅ | ❌ | ✅ |
| `private` | ✅ | ❌ | ✅ |

### 4.3 Demonstration

```java
public class AccessDemo {
    public    int pub = 1;
    protected int prot = 2;
              int pkg = 3;
    private   int priv = 4;

    public    void pubM() {}
    protected void protM() {}
              void pkgM() {}
    private   void privM() {}
}
```

```java
Class<?> c = AccessDemo.class;
Object o = c.getDeclaredConstructor().newInstance();

System.out.println("getFields() → " + Arrays.stream(c.getFields())
        .map(Field::getName).toList());
// [pub]

System.out.println("getDeclaredFields() → " + Arrays.stream(c.getDeclaredFields())
        .map(Field::getName).toList());
// [pub, prot, pkg, priv]

for (Field f : c.getDeclaredFields()) {
    f.setAccessible(true);               // unlocks non-public
    System.out.println(f.getName() + "=" + f.get(o));
}
// pub=1, prot=2, pkg=3, priv=4
```

### 4.4 `setAccessible` vs `trySetAccessible` (Java 9+)

With the module system, `setAccessible(true)` on a member of a **non-open** package of another module throws `InaccessibleObjectException`. Use:

```java
if (field.trySetAccessible()) {
    Object v = field.get(target);
}
```

Or add `opens` in `module-info.java`:

```java
module my.app {
    opens com.example.model to my.framework;
}
```

### 4.5 A Uniform Helper: Reach Any Element at Any Access Level

```java
public final class Reflection {

    public static Field field(Class<?> c, String name) {
        Class<?> cur = c;
        while (cur != null) {
            try {
                Field f = cur.getDeclaredField(name);
                if (!f.trySetAccessible()) {
                    throw new IllegalStateException("Cannot access " + f);
                }
                return f;
            } catch (NoSuchFieldException e) {
                cur = cur.getSuperclass();  // walk up hierarchy
            }
        }
        throw new IllegalArgumentException("No field " + name + " on " + c);
    }

    public static Method method(Class<?> c, String name, Class<?>... params) {
        Class<?> cur = c;
        while (cur != null) {
            try {
                Method m = cur.getDeclaredMethod(name, params);
                if (!m.trySetAccessible()) {
                    throw new IllegalStateException("Cannot access " + m);
                }
                return m;
            } catch (NoSuchMethodException e) {
                cur = cur.getSuperclass();
            }
        }
        throw new IllegalArgumentException("No method " + name + " on " + c);
    }

    @SuppressWarnings("unchecked")
    public static <T> Constructor<T> ctor(Class<T> c, Class<?>... params) {
        try {
            Constructor<T> k = c.getDeclaredConstructor(params);
            if (!k.trySetAccessible()) {
                throw new IllegalStateException("Cannot access " + k);
            }
            return k;
        } catch (NoSuchMethodException e) {
            throw new IllegalArgumentException("No ctor on " + c, e);
        }
    }
}
```

---

## Part 5: Putting It All Together — A Tiny Annotation Runner

The following engine scans a class, resolves **fields** with `@Inject`, chooses a **constructor** with `@Factory` (falling back to no-arg), then runs **methods** with `@Invoke` in order. It transparently handles every access level.

```java
public class AnnotationEngine {

    public static Object run(Class<?> clazz) throws Exception {
        // 1) Choose a constructor annotated with @Factory, else no-arg
        Constructor<?> chosen = null;
        for (Constructor<?> c : clazz.getDeclaredConstructors()) {
            if (c.isAnnotationPresent(Factory.class)) { chosen = c; break; }
        }
        if (chosen == null) chosen = clazz.getDeclaredConstructor();
        chosen.trySetAccessible();

        // 2) Build arguments from constructor parameter annotations
        Parameter[] cparams = chosen.getParameters();
        Object[] cargs = new Object[cparams.length];
        for (int i = 0; i < cparams.length; i++) {
            Inject p = cparams[i].getAnnotation(Inject.class);
            cargs[i] = (p != null) ? resolve(p.value()) : null;
        }

        // 3) Instantiate
        Object instance = chosen.newInstance(cargs);

        // 4) Inject fields
        for (Field f : clazz.getDeclaredFields()) {
            Inject inj = f.getAnnotation(Inject.class);
            if (inj == null) continue;
            f.trySetAccessible();
            Object value = resolve(inj.value());
            if (value == null && inj.required()) {
                throw new IllegalStateException("Missing required: " + inj.value());
            }
            if (value != null) f.set(instance, value);
        }

        // 5) Invoke @Invoke methods in order
        List<Method> steps = new ArrayList<>();
        for (Method m : clazz.getDeclaredMethods())
            if (m.isAnnotationPresent(Invoke.class)) steps.add(m);
        steps.sort(Comparator.comparingInt(m -> m.getAnnotation(Invoke.class).order()));

        for (Method m : steps) {
            m.trySetAccessible();
            Object[] margs = new Object[m.getParameterCount()];
            Class<?>[] types = m.getParameterTypes();
            for (int i = 0; i < types.length; i++) margs[i] = defaultValueFor(types[i]);
            Object out = m.invoke(instance, margs);
            System.out.printf("→ %s() = %s%n", m.getName(), out);
        }

        return instance;
    }

    // Very small "container"
    private static final Map<String, Object> BEANS = Map.of(
        "db.url", "jdbc:h2:mem:test",
        "db.timeout", 60,
        "ctor.arg", "from-annotation"
    );

    private static Object resolve(String key) { return BEANS.get(key); }

    private static Object defaultValueFor(Class<?> t) {
        if (!t.isPrimitive()) return null;
        if (t == int.class)     return 0;
        if (t == long.class)    return 0L;
        if (t == boolean.class) return false;
        if (t == double.class)  return 0d;
        if (t == float.class)   return 0f;
        if (t == short.class)   return (short) 0;
        if (t == byte.class)    return (byte) 0;
        if (t == char.class)    return '\0';
        return null;
    }

    public static void main(String[] args) throws Exception {
        Service s = (Service) run(Service.class);
        System.out.println("dbUrl=" + s.dbUrl + ", timeout=" + s.timeout
            + ", region=" + s.region);
    }
}
```

**Expected output** (order depends on source order, but sorted by `order`):

```
starting with jdbc:h2:mem:test
→ start() = null
→ ping() = pong:null
dbUrl=jdbc:h2:mem:test, timeout=60, region=eu-west-1
```

Notice the engine:
- Reads **constructor parameter annotations** via `Constructor.getParameters()`.
- Reads **field annotations** via `Field.getAnnotation(...)` and injects private/protected/package-private fields.
- Reads **method annotations** via `Method.getAnnotation(...)` and invokes even the `private ping(...)`.
- Uses `trySetAccessible()` so the same code works under the module system.

---

## Part 6: Cheat Sheet

| Task | API |
|---|---|
| Find a public field | `clazz.getField("name")` |
| Find any-access field | `clazz.getDeclaredField("name")` |
| Read a field | `field.get(target)` (after `trySetAccessible`) |
| Write a field | `field.set(target, value)` |
| Find a public method | `clazz.getMethod("m", String.class)` |
| Find any-access method | `clazz.getDeclaredMethod("m", String.class)` |
| Call a method | `method.invoke(target, args...)` |
| Get its parameter annotations | `method.getParameters()[i].getAnnotation(...)` |
| Find a public constructor | `clazz.getConstructor(String.class)` |
| Find any-access constructor | `clazz.getDeclaredConstructor(String.class)` |
| Instantiate | `ctor.newInstance(args...)` |
| Read annotation on any element | `element.getAnnotation(X.class)` |
| Enumerate all annotations | `element.getAnnotations()` / `getDeclaredAnnotations()` |
| Unlock non-public access | `element.trySetAccessible()` (Java 9+) / `setAccessible(true)` |

### Rule of Thumb

> **`getDeclared*` + `trySetAccessible()` is the universal recipe** when you don't know the visibility. Use `get*` (no `Declared`) only when you specifically want public + inherited members — that's what framework code does when it treats user classes as black boxes.

Once you internalize that **`Method`, `Field`, and `Constructor` are just three flavors of `AnnotatedElement` that also happen to be *invokable*/*readable*/*constructible***, you can build any annotation-driven engine: dependency injection, ORM mapping, test runners, serializers, and more.


[[API]]
[[Java]]