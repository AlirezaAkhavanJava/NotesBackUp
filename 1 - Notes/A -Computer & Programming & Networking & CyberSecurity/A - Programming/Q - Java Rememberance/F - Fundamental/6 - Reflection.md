
# Java Reflection — The Complete Guide

Reflection is the ability of a running Java program to **inspect and manipulate** its own classes, methods, fields, constructors, and annotations at runtime. It is the mechanism behind nearly all of Spring's "magic": dependency injection, bean scanning, AOP proxies, `@Transactional`, `@RequestMapping`, JSON serialization (Jackson), ORM mapping (Hibernate), and testing frameworks (JUnit).

The core package is `java.lang.reflect`, with `java.lang.Class` as the entry point.

---

## Part 1 — What Reflection Is and Why It Exists

### Definition
Reflection lets you:
- Discover the structure of a class at runtime (fields, methods, constructors, annotations).
- Create instances without knowing the class at compile time.
- Invoke methods and access fields dynamically.
- Bypass normal access checks (with caveats).
- Inspect generic type information, modifiers, and hierarchies.

### Why it exists
- **Frameworks** need to work with user classes they have never seen at compile time. Spring cannot `new` your `UserService` directly — it discovers it via reflection.
- **Serialization libraries** (Jackson, Gson) map objects to/from JSON by reading fields and methods.
- **ORM frameworks** (Hibernate, JPA) map classes to database tables.
- **Testing** (JUnit) discovers and invokes test methods annotated with `@Test`.
- **IDEs and debuggers** inspect running programs.
- **Dynamic proxies** enable AOP.

### The trade-off
Reflection is powerful but:
- **Slower** than direct calls (though modern JVMs and `MethodHandle`/`VarHandle` mitigate this).
- **Breaks compile-time safety** — errors become runtime exceptions.
- **Can break encapsulation** — `setAccessible(true)` bypasses access checks.
- **Complicates refactoring** — string-based lookups are not caught by the compiler.

---

## Part 2 — The `Class` Object — The Entry Point

Everything in reflection starts with a `java.lang.Class<T>` object, which represents a loaded type.

### Ways to obtain a `Class` object

```java
// 1. From an instance
Class<?> c1 = "hello".getClass();

// 2. From a class literal
Class<?> c2 = String.class;

// 3. From the class name (throws ClassNotFoundException)
Class<?> c3 = Class.forName("java.lang.String");

// 4. From a classloader
Class<?> c4 = ClassLoader.getSystemClassLoader().loadClass("java.lang.String");

// 5. From a primitive type
Class<?> c5 = int.class;

// 6. From an array type
Class<?> c6 = String[].class;
```

### Key facts about `Class`
- One `Class` object per loaded type per classloader.
- `Class` is `final` — you cannot subclass it.
- `Class` is generic: `Class<T>` where `T` is the represented type.
- Primitive types have `Class` objects (`int.class`), but no instances.
- `void.class` and `Void.TYPE` are the same.

### Useful `Class` methods

| Method | Returns |
|---|---|
| `getName()` | Fully qualified name (`java.lang.String`) |
| `getSimpleName()` | Simple name (`String`) |
| `getCanonicalName()` | Canonical name (`java.util.Map.Entry`) |
| `getPackage()` | Package object |
| `getSuperclass()` | Superclass `Class` |
| `getInterfaces()` | Directly implemented interfaces |
| `getModifiers()` | Encoded modifiers (`Modifier.toString(...)`) |
| `isInterface()` | Whether it is an interface |
| `isEnum()` | Whether it is an enum |
| `isArray()` | Whether it is an array |
| `isPrimitive()` | Whether it is a primitive |
| `isAnnotation()` | Whether it is an annotation type |
| `isRecord()` | Whether it is a record (Java 16+) |
| `isSealed()` | Whether it is sealed (Java 17+) |
| `isAssignableFrom(Class)` | Whether one type can be assigned to another |
| `isInstance(Object)` | Runtime `instanceof` |
| `cast(Object)` | Runtime cast |
| `getClassLoader()` | The classloader |
| `getComponentType()` | Element type of an array |

### `isAssignableFrom` vs `isInstance`

```java
Number.class.isAssignableFrom(Integer.class); // true
Integer.class.isAssignableFrom(Number.class); // false
Number.class.isInstance(42);                  // true
Number.class.isInstance("hello");             // false
```

Use `isAssignableFrom` when you have `Class` objects. Use `isInstance` when you have an object.

---

## Part 3 — Fields — `java.lang.reflect.Field`

### Retrieving fields

| Method | Behavior |
|---|---|
| `getFields()` | All **public** fields, including inherited |
| `getDeclaredFields()` | All fields declared in **this class only**, any access |
| `getField(String)` | Public field by name (including inherited) |
| `getDeclaredField(String)` | Field by name in this class only |

```java
class Person {
    public String name;
    private int age;
    protected String email;
}

for (Field f : Person.class.getDeclaredFields()) {
    System.out.println(f.getName() + " : " + f.getType().getSimpleName());
}
// name : String
// age : int
// email : String
```

### Reading and writing fields

```java
Person p = new Person();
Field nameField = Person.class.getField("name");
nameField.set(p, "Alice");
Object value = nameField.get(p);
```

### Accessing private fields

```java
Field ageField = Person.class.getDeclaredField("age");
ageField.setAccessible(true); // bypass access check
ageField.set(p, 30);
int age = (int) ageField.get(p);
```

`setAccessible(true)`:
- Suppresses Java language access checks for that `Field`, `Method`, or `Constructor`.
- Since Java 9, it is subject to **module system restrictions**. Code in a named module can only open packages it owns, or packages that are `open` to it.
- Reflection into `java.base` internals (e.g., `String.value`) is blocked by strong encapsulation in Java 17+.

### Field metadata

```java
Field f = Person.class.getDeclaredField("age");

f.getName();                       // "age"
f.getType();                       // int.class
f.getGenericType();                // Type (handles generics)
f.getModifiers();                  // encoded int
Modifier.isPrivate(f.getModifiers()); // true
f.isSynthetic();                   // compiler-generated?
f.isEnumConstant();                // enum constant?
```

### Primitive-specific accessors

`Field` provides typed getters/setters that avoid autoboxing:

```java
f.getInt(obj);    f.setInt(obj, 42);
f.getLong(obj);   f.setLong(obj, 42L);
f.getDouble(obj); f.setDouble(obj, 3.14);
f.getBoolean(obj);f.setBoolean(obj, true);
f.getChar(obj);   f.setChar(obj, 'a');
f.getByte(obj);   f.setByte(obj, (byte) 1);
f.getShort(obj);  f.setShort(obj, (short) 1);
f.getFloat(obj);  f.setFloat(obj, 1.0f);
```

### Generic field types

```java
class Box {
    List<String> items;
}

Field f = Box.class.getDeclaredField("items");
Type t = f.getGenericType();       // java.util.List<java.lang.String>
if (t instanceof ParameterizedType pt) {
    Type arg = pt.getActualTypeArguments()[0]; // class java.lang.String
}
```

`getGenericType()` returns a `Type` that can be:
- `Class<?>` — non-generic.
- `ParameterizedType` — `List<String>`.
- `GenericArrayType` — `T[]`.
- `TypeVariable<?>` — `T`.
- `WildcardType` — `? extends Number`.

---

## Part 4 — Methods — `java.lang.reflect.Method`

### Retrieving methods

| Method | Behavior |
|---|---|
| `getMethods()` | All **public** methods, including inherited |
| `getDeclaredMethods()` | All methods declared in **this class only** |
| `getMethod(String, Class...)` | Public method by name and parameter types |
| `getDeclaredMethod(String, Class...)` | Method in this class by name and parameter types |

```java
Method m = Person.class.getMethod("setName", String.class);
```

### Invoking methods

```java
Person p = new Person();
Method setter = Person.class.getMethod("setName", String.class);
setter.invoke(p, "Alice");

Method getter = Person.class.getMethod("getName");
Object result = getter.invoke(p); // "Alice"
```

### Static method invocation

```java
Method abs = Math.class.getMethod("abs", int.class);
Object result = abs.invoke(null, -5); // 5
```

Pass `null` as the target for static methods.

### Private method invocation

```java
Method secret = Person.class.getDeclaredMethod("secretMethod");
secret.setAccessible(true);
secret.invoke(p);
```

### Handling `InvocationTargetException`

If the invoked method throws an exception, `Method.invoke` wraps it in `InvocationTargetException`. You must unwrap it:

```java
try {
    method.invoke(target, args);
} catch (InvocationTargetException e) {
    Throwable cause = e.getCause(); // the actual exception
    throw cause;
}
```

This is a critical detail that trips up many developers. The exception you see is not the real one.

### Method metadata

```java
Method m = Person.class.getMethod("setName", String.class);

m.getName();                   // "setName"
m.getReturnType();             // void.class
m.getParameterTypes();         // [String.class]
m.getParameterCount();         // 1
m.getGenericParameterTypes();  // generic info
m.getGenericReturnType();      // generic return type
m.getExceptionTypes();         // declared checked exceptions
m.getModifiers();              // encoded
m.isVarArgs();                 // varargs?
m.isDefault();                 // default interface method?
m.isBridge();                  // compiler-generated bridge?
m.isSynthetic();               // compiler-generated?
m.getDeclaringClass();         // the class that declares it
```

### Type parameters and annotations

```java
TypeVariable<Method>[] typeParams = m.getTypeParameters();
Annotation[][] paramAnns = m.getParameterAnnotations();
Annotation[] methodAnns = m.getAnnotations();
```

### Records (Java 16+)

```java
record Point(int x, int y) {}

for (RecordComponent rc : Point.class.getRecordComponents()) {
    System.out.println(rc.getName() + " : " + rc.getType());
    Method accessor = rc.getAccessor();
}
```

---

## Part 5 — Constructors — `java.lang.reflect.Constructor`

### Retrieving constructors

| Method | Behavior |
|---|---|
| `getConstructors()` | All **public** constructors |
| `getDeclaredConstructors()` | All constructors, any access |
| `getConstructor(Class...)` | Public constructor with matching signature |
| `getDeclaredConstructor(Class...)` | Constructor in this class with matching signature |

### Creating instances

```java
Constructor<Person> ctor = Person.class.getConstructor(String.class, int.class);
Person p = ctor.newInstance("Alice", 30);
```

This is the reflective equivalent of `new Person("Alice", 30)`.

### Private constructors

```java
Constructor<Person> ctor = Person.class.getDeclaredConstructor();
ctor.setAccessible(true);
Person p = ctor.newInstance();
```

This is how **singletons** are broken by reflection, and how frameworks instantiate classes with private constructors.

### Handling exceptions

`Constructor.newInstance` wraps constructor exceptions in `InvocationTargetException`, same as `Method.invoke`.

### No-arg constructor and `newInstance()` deprecation

```java
Class<?> c = Class.forName("com.example.Person");
Person p = (Person) c.newInstance(); // deprecated since Java 9
```

The idiomatic modern form:

```java
Person p = Person.class.getDeclaredConstructor().newInstance();
```

`Class.newInstance()` is deprecated because it propagates checked exceptions incorrectly and does not wrap them properly.

### Records

```java
record Point(int x, int y) {}
Constructor<Point> ctor = Point.class.getDeclaredConstructor(int.class, int.class);
Point p = ctor.newInstance(1, 2);
```

---

## Part 6 — Modifiers — `java.lang.reflect.Modifier`

Modifiers are stored as a bitmask `int` on `Class`, `Field`, `Method`, `Constructor`, and `Parameter`.

```java
int mods = Person.class.getModifiers();

Modifier.isPublic(mods);
Modifier.isPrivate(mods);
Modifier.isProtected(mods);
Modifier.isStatic(mods);
Modifier.isFinal(mods);
Modifier.isAbstract(mods);
Modifier.isSynchronized(mods);
Modifier.isVolatile(mods);
Modifier.isTransient(mods);
Modifier.isNative(mods);
Modifier.isStrict(mods);
Modifier.isInterface(mods);
```

Human-readable:

```java
String s = Modifier.toString(mods); // "public final"
```

There is **no** `isPackagePrivate` — a member is package-private if it is none of public, private, or protected.

---

## Part 7 — Arrays — `java.lang.reflect.Array`

Reflection provides a dedicated utility for creating and manipulating arrays dynamically.

```java
int[] ints = (int[]) Array.newInstance(int.class, 5);
Array.setInt(ints, 0, 42);
int v = Array.getInt(ints, 0);
int len = Array.getLength(ints);
```

Object arrays:

```java
Object arr = Array.newInstance(String.class, 3);
Array.set(arr, 0, "a");
String s = (String) Array.get(arr, 0);
```

Multidimensional:

```java
int[][] matrix = (int[][]) Array.newInstance(int.class, 3, 3);
```

`Array` handles primitives, object arrays, and nested dimensions. It is used by serialization libraries to reconstruct arrays whose element type is only known at runtime.

---

## Part 8 — Parameter — `java.lang.reflect.Parameter`

Represents a method or constructor parameter.

```java
Method m = MyClass.class.getMethod("create", String.class, int.class);
for (Parameter p : m.getParameters()) {
    p.getName();                       // "arg0" unless -parameters
    p.getType();                       // String, int
    p.getParameterizedType();          // generic
    p.getModifiers();                  // final, etc.
    p.isNamePresent();                 // whether real name compiled in
    p.getAnnotations();                // @RequestParam, @PathVariable, ...
    p.isImplicit();                    // synthetic (inner class this)
    p.isSynthetic();                   // compiler-generated
}
```

### Parameter names

By default, parameter names are **not** retained in bytecode. You get `arg0`, `arg1`, etc. To keep them, compile with:

```
javac -parameters MyClass.java
```

Maven:

```xml
<compilerArgs>
    <arg>-parameters</arg>
</compilerArgs>
```

Spring Boot enables `-parameters` by default via the Spring Boot Maven plugin. This is why `@RequestParam` can infer names without explicit values.

---

## Part 9 — Generics and Reflection

Generics are erased at runtime, but **some** type information is retained in the bytecode as **signatures**. Reflection exposes it via `java.lang.reflect.Type`.

### The `Type` hierarchy

| Type | Represents |
|---|---|
| `Class<?>` | Non-generic type |
| `ParameterizedType` | `List<String>`, `Map<K,V>` |
| `GenericArrayType` | `T[]` |
| `TypeVariable<?>` | `T`, `E` |
| `WildcardType` | `? extends Number` |

### Reading a parameterized type

```java
class Repository {
    List<String> names;
    Map<String, List<Integer>> index;
}

Field f = Repository.class.getDeclaredField("index");
ParameterizedType pt = (ParameterizedType) f.getGenericType();
System.out.println(pt.getRawType());                  // interface java.util.Map
System.out.println(Arrays.toString(pt.getActualTypeArguments()));
// [class java.lang.String, java.util.List<java.lang.Integer>]
```

### Reading superclass generics (Spring pattern)

```java
abstract class BaseService<T> { }

class UserService extends BaseService<User> { }

Type superType = UserService.class.getGenericSuperclass();
if (superType instanceof ParameterizedType pt) {
    Class<?> entityType = (Class<?>) pt.getActualTypeArguments()[0];
    // User.class
}
```

This is exactly how Spring Data JPA resolves the entity type of a repository interface.

### Type erasure caveats

- You cannot do `new T()`.
- You cannot do `T.class`.
- You cannot do `instanceof List<String>`.
- You can read `List<String>` from a **field, method, or superclass declaration**, but not from a **variable** or a **runtime object**.

```java
List<String> list = new ArrayList<>();
list.getClass(); // class java.util.ArrayList — no <String> info
```

The generic argument is lost at runtime unless it appears in a declaration that reflection can read.

---

## Part 10 — Annotations via Reflection

Reflection is how frameworks read annotations. This was covered in depth in the annotation guide; here it is in the context of reflection.

```java
Method m = MyClass.class.getMethod("process");

if (m.isAnnotationPresent(Transactional.class)) {
    Transactional tx = m.getAnnotation(Transactional.class);
    // apply transaction advice
}
```

### Key methods

| Method | Inherited? | Repeatable? |
|---|---|---|
| `getAnnotation(Class)` | Yes | No |
| `getDeclaredAnnotation(Class)` | No | No |
| `getAnnotations()` | Yes | Container only |
| `getDeclaredAnnotations()` | No | Container only |
| `getAnnotationsByType(Class)` | Yes | Yes |
| `getDeclaredAnnotationsByType(Class)` | No | Yes |

Same methods exist on `Class`, `Field`, `Method`, `Constructor`, `Parameter`, `Package`, `Module`, and `RecordComponent`.

---

## Part 11 — Dynamic Proxies — `java.lang.reflect.Proxy`

Dynamic proxies let you create a class at runtime that implements one or more interfaces and delegates all method calls to a handler. This is the mechanism behind **JDK dynamic proxies** used by Spring AOP.

### Basic usage

```java
interface Greeter {
    String greet(String name);
}

class GreeterInvocationHandler implements InvocationHandler {
    private final Object target;

    GreeterInvocationHandler(Object target) { this.target = target; }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("Before: " + method.getName());
        Object result = method.invoke(target, args);
        System.out.println("After: " + method.getName());
        return result;
    }
}

Greeter target = name -> "Hello, " + name;
Greeter proxy = (Greeter) Proxy.newProxyInstance(
    Greeter.class.getClassLoader(),
    new Class<?>[] { Greeter.class },
    new GreeterInvocationHandler(target)
);

System.out.println(proxy.greet("Alice"));
// Before: greet
// After: greet
// Hello, Alice
```

### How Spring uses it
- If a bean implements an interface, Spring uses a **JDK dynamic proxy**.
- If not, Spring uses **CGLIB** (bytecode-generated subclass).
- The proxy intercepts calls and applies advice: transactions, security, caching, async, etc.

### Limitations
- JDK proxies can only proxy **interfaces**, not classes.
- `final` classes and methods cannot be proxied by CGLIB.
- Self-invocation bypasses the proxy (`this.method()` is a direct call).
- `equals`, `hashCode`, and `toString` are also routed to the handler — handle them carefully.

### CGLIB proxies
Not part of `java.lang.reflect` but part of Spring. CGLIB generates a subclass at runtime and overrides methods. It requires a non-final class with a non-final, accessible constructor.

---

## Part 12 — `MethodHandles` and `VarHandles` — The Modern Alternative

`java.lang.invoke` provides a faster, safer alternative to reflection.

### `MethodHandle`

```java
MethodHandles.Lookup lookup = MethodHandles.lookup();
MethodHandle mh = lookup.findVirtual(String.class, "length", MethodType.methodType(int.class));

int len = (int) mh.invoke("hello"); // 5
```

### Advantages over `Method.invoke`
- **Faster** — JIT can inline method handles.
- **Type-safe** at the handle level (signature checked at lookup).
- **Access-checked** once at lookup, not per call.
- Plays well with `invokedynamic` and lambdas.

### `VarHandle` (Java 9+)
Provides low-level access to fields, array elements, and off-heap memory with memory-ordering semantics. Used by `java.util.concurrent` and `AtomicXxx` internals.

### `MethodHandles.Lookup`
Access is governed by the lookup context. `MethodHandles.privateLookupIn(targetClass, lookup)` allows deep reflection in a controlled way.

### When to use which
- **Reflection (`Class`, `Method`, `Field`)**: framework-level discovery, annotations, dynamic invocation where speed is not critical.
- **`MethodHandle`**: hot-path invocation, performance-sensitive code.
- **`VarHandle`**: low-level concurrent/atomic field access.

---

## Part 13 — The Module System and Strong Encapsulation (Java 9+)

The Java Platform Module System (JPMS) restricts reflective access to JDK internals.

### What changed
- `setAccessible(true)` on a member of a **non-open** package in another module throws `InaccessibleObjectException`.
- Deep reflection into `java.base` internals is blocked by default.
- `sun.misc.Unsafe` and internal APIs are increasingly restricted.

### Workarounds
- `--add-opens java.base/java.lang=ALL-UNNAMED` on the command line.
- `opens` directives in `module-info.java`.

```java
module com.example {
    opens com.example.model to com.fasterxml.jackson.databind;
}
```

### Why this matters
Frameworks like Jackson and Hibernate rely on deep reflection. If your module does not open the right packages, they fail at runtime. This is why Spring Boot and Jackson documentation emphasize `opens` and `--add-opens`.

### `AccessibleObject`
`Class`, `Field`, `Method`, and `Constructor` all extend `AccessibleObject`, which provides:
- `setAccessible(boolean)`
- `isAccessible()`
- `trySetAccessible()` (Java 9+) — returns `false` instead of throwing.

---

## Part 14 — Performance Considerations

### Costs of reflection
- **Lookup** — finding a `Method`/`Field` by name is relatively expensive. **Cache it.**
- **Access check** — checked on each call unless `setAccessible(true)` is set and cached.
- **Autoboxing** — `Method.invoke` takes `Object[]`, so primitives are boxed.
- **Exception wrapping** — `InvocationTargetException` allocation.
- **No inlining** — the JIT often cannot inline reflective calls as aggressively as direct calls.

### Mitigations
- **Cache** `Method`, `Field`, `Constructor`, and `Class` objects.
- Use `setAccessible(true)` once and reuse.
- Use `MethodHandle` for hot paths.
- Use `LambdaMetafactory` to generate call sites for maximum performance.
- Avoid reflection in tight loops.

### `LambdaMetafactory` example (advanced)

```java
MethodHandles.Lookup lookup = MethodHandles.lookup();
MethodHandle target = lookup.findVirtual(Person.class, "getName", MethodType.methodType(String.class));
Function<Person, String> f = (Function<Person, String>) LambdaMetafactory.metafactory(
    lookup, "apply",
    MethodType.methodType(Function.class),
    MethodType.methodType(Object.class, Object.class),
    target, MethodType.methodType(String.class, Person.class)
).getTarget().invokeExact();
```

This generates a lambda that calls the method directly — near-native speed. Used by frameworks in performance-critical paths.

---

## Part 15 — Full Example: A Mini Serializer

This example uses reflection to serialize any object to JSON-like output, mirroring what Jackson does.

```java
import java.lang.reflect.*;
import java.util.*;

public class MiniJson {

    public static String toJson(Object obj) throws Exception {
        if (obj == null) return "null";
        Class<?> clazz = obj.getClass();

        if (clazz == String.class) return "\"" + obj + "\"";
        if (Number.class.isAssignableFrom(clazz) || clazz == Boolean.class) return obj.toString();
        if (clazz.isArray()) {
            StringBuilder sb = new StringBuilder("[");
            int len = Array.getLength(obj);
            for (int i = 0; i < len; i++) {
                if (i > 0) sb.append(",");
                sb.append(toJson(Array.get(obj, i)));
            }
            return sb.append("]").toString();
        }
        if (Collection.class.isAssignableFrom(clazz)) {
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            for (Object item : (Collection<?>) obj) {
                if (!first) sb.append(",");
                sb.append(toJson(item));
                first = false;
            }
            return sb.append("]").toString();
        }
        if (Map.class.isAssignableFrom(clazz)) {
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<?, ?> e : ((Map<?, ?>) obj).entrySet()) {
                if (!first) sb.append(",");
                sb.append("\"").append(e.getKey()).append("\":").append(toJson(e.getValue()));
                first = false;
            }
            return sb.append("}").toString();
        }

        // POJO: read fields reflectively
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Field f : clazz.getDeclaredFields()) {
            if (Modifier.isStatic(f.getModifiers()) || Modifier.isTransient(f.getModifiers())) continue;
            f.setAccessible(true);
            if (!first) sb.append(",");
            sb.append("\"").append(f.getName()).append("\":").append(toJson(f.get(obj)));
            first = false;
        }
        return sb.append("}").toString();
    }
}
```

Usage:

```java
record Address(String city) {}
class Person {
    private String name = "Alice";
    private int age = 30;
    private Address address = new Address("Paris");
    private List<String> tags = List.of("a", "b");
}

System.out.println(MiniJson.toJson(new Person()));
// {"name":"Alice","age":30,"address":{"city":"Paris"},"tags":["a","b"]}
```

This is a toy version of Jackson. Jackson adds: annotation handling (`@JsonProperty`, `@JsonIgnore`), generic type resolution, caching, custom serializers, and much more.

---

## Part 16 — Full Example: A Mini DI + AOP Framework

Combining reflection, annotations, and dynamic proxies.

### Annotations

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface Component {}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
@interface Inject {}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Logged {}
```

### Container

```java
class Container {
    private final Map<Class<?>, Object> beans = new HashMap<>();

    void register(Class<?>... classes) throws Exception {
        for (Class<?> c : classes) {
            if (c.isAnnotationPresent(Component.class)) {
                beans.put(c, c.getDeclaredConstructor().newInstance());
            }
        }
        for (Object bean : beans.values()) injectFields(bean);
        for (Class<?> c : beans.keySet()) beans.put(c, wrapWithLogging(beans.get(c)));
    }

    private void injectFields(Object bean) throws Exception {
        for (Field f : bean.getClass().getDeclaredFields()) {
            if (f.isAnnotationPresent(Inject.class)) {
                f.setAccessible(true);
                f.set(bean, beans.get(f.getType()));
            }
        }
    }

    private Object wrapWithLogging(Object target) {
        Class<?> clazz = target.getClass();
        boolean hasLogged = Arrays.stream(clazz.getDeclaredMethods())
            .anyMatch(m -> m.isAnnotationPresent(Logged.class));
        if (!hasLogged) return target;

        return Proxy.newProxyInstance(
            clazz.getClassLoader(),
            clazz.getInterfaces(),
            (proxy, method, args) -> {
                if (method.isAnnotationPresent(Logged.class)) {
                    System.out.println(">> " + method.getName());
                    Object result = method.invoke(target, args);
                    System.out.println("<< " + method.getName());
                    return result;
                }
                return method.invoke(target, args);
            }
        );
    }

    <T> T getBean(Class<T> type) { return type.cast(beans.get(type)); }
}
```

This mirrors Spring's core: annotation scanning, reflective injection, and proxy-based AOP.

---

## Part 17 — Best Practices and Pitfalls

### Best practices
- **Cache** reflective lookups — never call `getMethod` in a loop.
- Use `setAccessible(true)` sparingly and only when necessary.
- Prefer `MethodHandle` for hot paths.
- Handle `InvocationTargetException` by unwrapping `getCause()`.
- Use `getDeclaredXxx` + walk the hierarchy when you need full coverage.
- Respect the module system — use `opens` instead of `--add-opens` when possible.
- Use `trySetAccessible()` (Java 9+) when you want a boolean instead of an exception.
- Log reflection failures with enough context to debug.
- Document why reflection is used — it is a code smell if avoidable.

### Pitfalls

| Pitfall | Consequence |
|---|---|
| Not unwrapping `InvocationTargetException` | Real exception lost |
| `getMethod` vs `getDeclaredMethod` confusion | `NoSuchMethodException` |
| Forgetting inherited members | Missing fields/methods |
| `getFields()` vs `getDeclaredFields()` | Public-only vs all |
| Not calling `setAccessible(true)` on private members | `IllegalAccessException` |
| Reflecting on `final` fields | May not change value (JIT constant-folds) |
| Using `Class.newInstance()` | Deprecated; bad exception handling |
| Assuming parameter names exist | `arg0` unless `-parameters` |
| Assuming generic types survive erasure | `List<String>` lost at runtime from variables |
| Breaking module encapsulation | `InaccessibleObjectException` |
| Proxying `final` classes | CGLIB fails |
| Self-invocation bypassing proxy | AOP advice not applied |
| Performance in hot loops | Severe slowdown |

### Reflection and `final` fields
Modifying `final` fields via reflection is unreliable:
- `Field.set` on a `final` instance field throws `IllegalAccessException` unless `setAccessible(true)` and certain conditions hold.
- Static `final` fields may have been constant-folded by the JIT.
- Since Java 17, `Field.set` on `final` fields of records and hidden classes is blocked.
- Even when it works, it is fragile and version-dependent.

---

## Part 18 — Reflection in the JDK and Ecosystem

| Library / API | How it uses reflection |
|---|---|
| `java.lang.Class` | Entry point |
| `Class.forName` | Loading classes by name |
| `ServiceLoader` | Discovering implementations of an interface |
| `java.beans.Introspector` | JavaBeans property discovery |
| JUnit | Finds and invokes `@Test` methods |
| Jackson | Maps JSON to objects via fields/getters/setters |
| Gson | Same, with generic type capture |
| Hibernate / JPA | Maps entities to tables via fields/annotations |
| Spring Core | Bean scanning, DI, AOP |
| Spring MVC | Handler mapping via annotations |
| Spring Data | Derives queries from repository interface generics |
| Lombok | Compile-time annotation processing (not runtime reflection) |
| Mockito | Creates mocks via bytecode generation + reflection |
| Gradle / Maven | Plugin discovery and execution |

---

## Part 19 — Quick Reference

### `Class` — key methods

| Method | Purpose |
|---|---|
| `forName(String)` | Load class |
| `getName()` / `getSimpleName()` | Names |
| `getSuperclass()` | Superclass |
| `getInterfaces()` | Interfaces |
| `getFields()` / `getDeclaredFields()` | Fields |
| `getMethods()` / `getDeclaredMethods()` | Methods |
| `getConstructors()` / `getDeclaredConstructors()` | Constructors |
| `getAnnotations()` / `getAnnotation(Class)` | Annotations |
| `isAssignableFrom(Class)` | Type compatibility |
| `isInstance(Object)` | Runtime instanceof |
| `cast(Object)` | Runtime cast |
| `newInstance()` | **Deprecated** |

### `Field` — key methods

| Method | Purpose |
|---|---|
| `get(Object)` / `set(Object, Object)` | Read/write |
| `getInt` / `setInt` etc. | Primitive access |
| `getType()` / `getGenericType()` | Type info |
| `getModifiers()` | Modifiers |
| `setAccessible(boolean)` | Bypass access |
| `getAnnotation(Class)` | Annotation |

### `Method` — key methods

| Method | Purpose |
|---|---|
| `invoke(Object, Object...)` | Call method |
| `getReturnType()` / `getGenericReturnType()` | Return type |
| `getParameterTypes()` / `getParameters()` | Parameters |
| `getExceptionTypes()` | Declared exceptions |
| `getModifiers()` | Modifiers |
| `setAccessible(boolean)` | Bypass access |
| `getAnnotation(Class)` | Annotation |

### `Constructor` — key methods

| Method | Purpose |
|---|---|
| `newInstance(Object...)` | Create instance |
| `getParameterTypes()` | Parameters |
| `getModifiers()` | Modifiers |
| `setAccessible(boolean)` | Bypass access |

### `Modifier` — checks

`isPublic`, `isPrivate`, `isProtected`, `isStatic`, `isFinal`, `isAbstract`, `isSynchronized`, `isVolatile`, `isTransient`, `isNative`, `isInterface`.

### Reflection vs `MethodHandle`

| Aspect | Reflection | `MethodHandle` |
|---|---|---|
| Ease of use | Easier | Steeper |
| Performance | Slower | Faster (JIT-friendly) |
| Access check | Per call unless cached | At lookup |
| Type safety | Runtime | Lookup-time |
| Best for | Framework discovery | Hot-path invocation |

---

## The Big Picture

Reflection is Java's mechanism for **runtime introspection and dynamic invocation**. It powers:

- **Frameworks** (Spring, Hibernate, Jackson) that must work with classes they have never seen.
- **Dependency injection** — scanning, instantiating, wiring beans.
- **AOP** — dynamic proxies that intercept method calls.
- **Serialization** — mapping objects to and from structured formats.
- **Testing** — discovering and invoking test methods.
- **Annotation processing** — reading metadata to drive behavior.

Its costs — performance, safety, encapsulation — are real but manageable with caching, `MethodHandle`, and disciplined use of `setAccessible`. The Java module system has tightened deep reflection, which is why modern frameworks emphasize `opens` and compile-time alternatives like annotation processors (Lombok) and code generation (Dagger, MapStruct).

For Spring specifically: **every piece of Spring's "magic" — bean discovery, `@Autowired`, `@Transactional`, `@RequestMapping`, `@Cacheable` — is reflection plus annotations plus proxies**. Understanding reflection is understanding how Spring actually works.


[[Java]]