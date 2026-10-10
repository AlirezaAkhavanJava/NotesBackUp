
# Deep Dive: `Method`, `Field`, and `Constructor` Classes

These three classes live in `java.lang.reflect` and are the **executable/metadata handles** for the three kinds of class members Java allows. Each is a **final class** implementing `Member` (and `AnnotatedElement`), so they all share annotation access but differ in what they *do*.

---

## 1. `java.lang.reflect.Field`

**Definition:** A `Field` is a reflective handle to a **single variable declared in a class or interface** — either an instance field or a `static` field. It lets you read and write that variable's value on a given object (or class, for statics), inspect its type, and read its annotations.

```java
public final class Field extends AccessibleObject implements Member
```

### Behavior Table

| Method | Signature | What It Does |
|---|---|---|
| `getName()` | `String` | Returns the field's simple name (e.g., `"timeout"`). |
| `getType()` | `Class<?>` | Returns the declared type of the field. |
| `getGenericType()` | `Type` | Returns the type with generics info (`List<String>` vs raw `List`). |
| `getModifiers()` | `int` | Returns encoded modifiers (`private`, `static`, `final`, `volatile`, `transient`) — decode with `Modifier.toString()`. |
| `get(Object obj)` | `Object` | Reads the field's value from instance `obj` (or `null` for static). Auto-boxes primitives. |
| `getInt/getLong/getBoolean/...` | primitive | Typed reads — no boxing, faster for primitives. |
| `set(Object obj, Object v)` | `void` | Writes value `v` into the field of `obj`. Auto-unboxes. |
| `setInt/setLong/setBoolean/...` | `void` | Typed writes — no boxing. |
| `getDeclaringClass()` | `Class<?>` | The class that actually declares this field. |
| `isEnumConstant()` | `boolean` | True if the field is a constant of an enum type. |
| `isSynthetic()` | `boolean` | True if compiler-generated (e.g., `this$0` in inner classes). |
| `getAnnotation(Class<A>)` | `A` | Reads annotation `A` from this field (needs `@Retention(RUNTIME)`). |
| `getAnnotations()` | `Annotation[]` | All annotations (including inherited). |
| `getDeclaredAnnotations()` | `Annotation[]` | Only annotations directly on this field. |
| `setAccessible(boolean)` | `void` | (From `AccessibleObject`) Unlocks access to non-public fields. |
| `trySetAccessible()` | `boolean` | Safe variant for the module system — returns `false` instead of throwing. |
| `equals/hashCode` | | Structural — two `Field`s are equal if same declaring class + name + type. |

### Key Rules

- `get`/`set` on a `static` field ignore the `obj` argument (pass `null`).
- `final` fields can be `set` after `setAccessible(true)` **only for non-static, non-record** fields, and only if the JIT hasn't constant-folded it — **never rely on this in production**.
- Primitive reads via `getInt` etc. throw `IllegalArgumentException` if the field is a different primitive type.
- `getType()` for a field of type `int` returns `int.class`, not `Integer.class`.

---

## 2. `java.lang.reflect.Method`

**Definition:** A `Method` is a reflective handle to a **single method or static method declared in a class or interface**. It lets you invoke that method on an instance (or class), inspect its signature (parameters, return type, exceptions), and read its annotations.

```java
public final class Method extends Executable   // Java 8+
// Executable extends AccessibleObject implements Member, GenericDeclaration
```

### Behavior Table

| Method | Signature | What It Does |
|---|---|---|
| `getName()` | `String` | Simple method name. |
| `getReturnType()` | `Class<?>` | Declared return type (`void.class` for `void`). |
| `getGenericReturnType()` | `Type` | Return type with generics. |
| `getParameterTypes()` | `Class<?>[]` | The ordered parameter types. |
| `getParameterCount()` | `int` | Number of parameters. |
| `getParameters()` | `Parameter[]` | Parameter objects — each is an `AnnotatedElement` (read `@Inject` on args here). |
| `getExceptionTypes()` | `Class<?>[]` | Declared `throws` types. |
| `getModifiers()` | `int` | `public`, `static`, `final`, `synchronized`, `abstract`, `native`, etc. |
| `getDefaultValue()` | `Object` | For annotation-type methods: the default value. |
| `isVarArgs()` | `boolean` | True for `Object...`. |
| `isBridge()` / `isSynthetic()` | `boolean` | Compiler-generated (generics erasure / lambda). |
| `invoke(Object target, Object... args)` | `Object` | **Calls** the method. Wrap target with `null` for statics. Returns boxed result. |
| `getDeclaringClass()` | `Class<?>` | The class that declared this method. |
| `getAnnotation(Class<A>)` | `A` | Reads annotation `A`. |
| `getAnnotations()` / `getDeclaredAnnotations()` | `Annotation[]` | All vs directly declared. |
| `setAccessible(boolean)` / `trySetAccessible()` | | Unlock non-public invocation. |
| `equals/hashCode` | | Same declaring class + name + parameter types. |

### Key Rules

- **`invoke` wraps exceptions**: if the target method throws `IOException`, `invoke` throws `InvocationTargetException` whose `getCause()` is the real `IOException`. You must unwrap.
- **Boxing**: arguments are boxed/unboxed automatically; passing `null` for a primitive parameter throws `IllegalArgumentException`.
- **Varargs**: pass array elements directly — `m.invoke(obj, "a", "b")` for `foo(String...)`.
- **Static method**: pass `null` as target.
- **Overloads**: two methods with the same name but different parameter types are different `Method` objects.

---

## 3. `java.lang.reflect.Constructor`

**Definition:** A `Constructor` is a reflective handle to a **single constructor of a class**. It lets you create a new instance using that constructor, inspect its parameters/annotations, and read constructor-level annotations. Constructors have **no return type** and **no name of their own** (`getName()` returns the fully-qualified class name, per `Member` contract).

```java
public final class Constructor<T> extends Executable
```

> Note the **generic parameter `<T>`** — the type of the class this constructor builds, so `newInstance()` returns `T` (no cast needed).

### Behavior Table

| Method | Signature | What It Does |
|---|---|---|
| `getName()` | `String` | Returns the **fully-qualified class name** (constructors have no distinct name). |
| `getDeclaringClass()` | `Class<T>` | The class this constructor belongs to. |
| `getParameterTypes()` | `Class<?>[]` | Ordered parameter types. |
| `getParameterCount()` | `int` | Number of parameters. |
| `getParameters()` | `Parameter[]` | Each parameter is an `AnnotatedElement`. |
| `getExceptionTypes()` | `Class<?>[]` | Declared `throws` types. |
| `getModifiers()` | `int` | `public`, `protected`, `private`, `varargs`, `synthetic`. |
| `isVarArgs()` | `boolean` | True for `Object...`. |
| `newInstance(Object... args)` | `T` | **Creates** a new instance. Wraps target exceptions in `InvocationTargetException`. |
| `getAnnotation(Class<A>)` | `A` | Reads constructor-level annotation. |
| `getAnnotations()` / `getDeclaredAnnotations()` | `Annotation[]` | All vs directly declared. |
| `setAccessible(boolean)` / `trySetAccessible()` | | Unlock private/protected constructors. |
| `equals/hashCode` | | Same declaring class + parameter types. |

### Key Rules

- The **only** safe way to instantiate via reflection is `ctor.newInstance(...)` — `Class.newInstance()` is deprecated since Java 9 (it silently propagates checked exceptions and bypasses accessibility rules).
- To pick the right constructor when several exist: match `getParameterTypes()` exactly.
- Private constructors can be invoked after `setAccessible(true)` — this is how singletons/frameworks break encapsulation intentionally.
- For records, use `Class.getRecordComponents()` + the **canonical constructor** (`Class.getDeclaredConstructor(recordComponentTypes)`).

---

## 4. Side-by-Side Comparison

| Aspect | `Field` | `Method` | `Constructor` |
|---|---|---|---|
| Represents | A variable | A callable method | A way to build an instance |
| Has a name? | Yes (`getName`) | Yes (`getName`) | No (returns FQCN) |
| Return type? | `getType()` | `getReturnType()` | None |
| Parameters? | No | Yes | Yes |
| Throws? | No | `getExceptionTypes()` | `getExceptionTypes()` |
| Primary action | `get` / `set` | `invoke` | `newInstance` |
| Works on statics? | Yes (pass `null`) | Yes (pass `null`) | N/A |
| Generic signature | No | Yes (`Constructor<T>`) | Yes (`Constructor<T>`) |
| Can modify `final`? | Only via `setAccessible` (fragile) | N/A | N/A |
| Superclass of | `AccessibleObject` | `Executable` | `Executable` |

All three implement **`Member`** (`getDeclaringClass`, `getName`, `getModifiers`, `isSynthetic`) and **`AnnotatedElement`** (`getAnnotation`, etc.), plus **`AccessibleObject`** (`setAccessible`, `trySetAccessible`, `canAccess`).

---

## 5. How a Good Developer Uses Them

### Principle 1 — Prefer direct calls; use reflection only at boundaries

Reflection is for **frameworks, plugins, and generic infrastructure** — not for everyday code. A good developer reaches for it when:
- The class/method isn't known at compile time (plugin loading, DI, ORMs, test runners).
- Behavior must be driven by annotations/metadata.
- You're writing tooling (serializers, mappers, debuggers).

Otherwise: call the method, read the field, use the constructor. Direct code is faster, type-safe, refactorable.

### Principle 2 — Cache reflective lookups, never in loops

`getDeclaredField` / `getDeclaredMethod` are expensive (linear scan + access checks). Cache them once:

```java
// Bad
for (Object o : objects) {
    Field f = clazz.getDeclaredField("id");  // lookup every iteration!
    f.setAccessible(true);
    f.set(o, nextId());
}

// Good
Field idField = clazz.getDeclaredField("id");
idField.trySetAccessible();
for (Object o : objects) idField.set(o, nextId());
```

For hot paths, upgrade to `MethodHandle` (constant-folds, JIT-friendly):

```java
MethodHandles.Lookup lookup = MethodHandles.lookup();
MethodHandle mh = lookup.unreflect(method);     // bind once
Object result = mh.invokeWithArguments(target, arg);  // near-direct speed
```

### Principle 3 — Always unwrap `InvocationTargetException`

A bad developer lets the wrapper escape; a good developer surfaces the real cause:

```java
try {
    method.invoke(target, args);
} catch (InvocationTargetException e) {
    Throwable real = e.getCause();
    if (real instanceof RuntimeException re) throw re;
    if (real instanceof Error err) throw err;
    throw new RuntimeException("Method threw checked exception", real);
}
```

### Principle 4 — Use `trySetAccessible`, not blind `setAccessible(true)`

Under Java 9+ modules, `setAccessible(true)` throws `InaccessibleObjectException` on non-open packages. A resilient helper checks first:

```java
static boolean tryAccess(AccessibleObject ao) {
    return ao.trySetAccessible();   // Java 9+
}
```

### Principle 5 — Walk the hierarchy when necessary

`getDeclaredField` only sees the class you called it on. Superclass fields/methods must be discovered by climbing `getSuperclass()`:

```java
static Field findField(Class<?> c, String name) throws NoSuchFieldException {
    for (Class<?> cur = c; cur != null; cur = cur.getSuperclass()) {
        try { return cur.getDeclaredField(name); }
        catch (NoSuchFieldException ignored) {}
    }
    throw new NoSuchFieldException(name);
}
```

Same pattern for methods, except you must also match parameter types to disambiguate overloads.

### Principle 6 — Match parameters exactly; don't rely on `getMethod` name-only

```java
// Wrong: overloaded methods with same name
clazz.getMethod("set");  // NoSuchMethodException / wrong one

// Right: full signature
clazz.getMethod("set", String.class, int.class);
```

### Principle 7 — Check for annotations before acting; don't NPE

```java
Inject inj = field.getAnnotation(Inject.class);
if (inj == null) continue;
```

Also prefer `getDeclaredAnnotations()` when you want *only* what's on this element (avoids `@Inherited` surprises on classes).

### Principle 8 — Respect access as a contract

Only break encapsulation when the framework's job demands it (DI into private fields, testing private methods). Prefer:
1. Public API first.
2. If not available, check `canAccess()` / open packages in `module-info`.
3. Only then `trySetAccessible()`.
4. Document *why* you're reaching into non-public members.

### Principle 9 — Beware performance-sensitive primitives

`Field.get` boxes every primitive. In hot loops:

```java
// Slower — boxes every call
int v = (int) field.get(obj);

// Faster — primitive overload, no boxing
int v = field.getInt(obj);
```

### Principle 10 — Prefer `MethodHandles`/`VarHandle` for the hot path

For high-performance serializers / ORMs:

```java
// Field → VarHandle (Java 9+)
VarHandle vh = MethodHandles
    .privateLookupIn(clazz, MethodHandles.lookup())
    .findVarHandle(clazz, "id", long.class);

vh.set(instance, 42L);           // as fast as a direct field write
long id = (long) vh.get(instance);
```

`VarHandle` and `MethodHandle` are the "reflection 2.0" — same reach, JIT-inlinable, no boxing.

---

## 6. A Realistic Example — A Minimal ORM Row Mapper

Bringing it all together — a good developer's mental model:

```java
public class RowMapper {

    // Cache per class: fields that carry @Column, plus their column names
    private static final Map<Class<?>, List<ColumnBinding>> CACHE =
        new ConcurrentHashMap<>();

    record ColumnBinding(Field field, String column) {}

    public static <T> T fromRow(Class<T> type, ResultSet rs) throws Exception {
        // 1) Constructor: pick the canonical no-arg ctor, cache accessible
        Constructor<T> ctor = type.getDeclaredConstructor();
        if (!ctor.trySetAccessible()) throw new IllegalStateException("ctor sealed");
        T instance = ctor.newInstance();

        // 2) Fields: resolve once, reuse forever
        List<ColumnBinding> bindings = CACHE.computeIfAbsent(type, t -> {
            List<ColumnBinding> list = new ArrayList<>();
            for (Field f : t.getDeclaredFields()) {
                Column col = f.getAnnotation(Column.class);
                if (col != null) {
                    f.trySetAccessible();
                    list.add(new ColumnBinding(f, col.value()));
                }
            }
            return list;
        });

        for (ColumnBinding b : bindings) {
            Class<?> ft = b.field().getType();
            Object value = rs.getObject(b.column());
            // 3) Type-aware write — typed setters avoid boxing where possible
            if (ft == int.class)          b.field().setInt(instance, ((Number) value).intValue());
            else if (ft == long.class)    b.field().setLong(instance, ((Number) value).longValue());
            else if (ft == boolean.class) b.field().setBoolean(instance, (Boolean) value);
            else                          b.field().set(instance, value);
        }

        // 4) Optional: run any @PostLoad method
        for (Method m : type.getDeclaredMethods()) {
            if (m.isAnnotationPresent(PostLoad.class)) {
                m.trySetAccessible();
                try {
                    m.invoke(instance);
                } catch (InvocationTargetException e) {
                    Throwable cause = e.getCause();
                    if (cause instanceof RuntimeException re) throw re;
                    throw new RuntimeException(cause);
                }
            }
        }
        return instance;
    }
}
```

This example embodies every principle: caching, `trySetAccessible`, constructor + field + method handles working together, exception unwrapping, and typed primitive writes.

---

## TL;DR

- **`Field`** = read/write a variable on an instance.
- **`Method`** = invoke a method on an instance; unwrap `InvocationTargetException`.
- **`Constructor`** = create an instance; the only correct reflective instantiation path.
- All three are **`AnnotatedElement`** + **`AccessibleObject`**, which is why the same annotation-reading and access-unlocking code works across them.
- A good developer: **uses reflection only at boundaries, caches lookups, unwraps exceptions, prefers `trySetAccessible`, matches signatures exactly, uses `VarHandle`/`MethodHandle` for hot paths, and respects the module system**.


[[Java]]