# How the JVM Works with Annotations

Annotations feel "magical" because they seem to change behavior. In reality, **the JVM itself does almost nothing with annotations**. It stores them as **structured metadata** in the class file and exposes them through reflection. Everything else — DI, validation, routing, ORM mapping — is done by **your code or a framework** reading that metadata.

This chapter explains the full pipeline: compile time → class file → class loading → runtime → reflection.

---

## 1. The Big Picture

```
┌──────────────┐   javac    ┌──────────────────┐   ClassLoader   ┌──────────────┐
│  .java       │──────────▶ │  .class file     │───────────────▶ │  JVM runtime │
│  source with │            │  bytecode +      │                 │  Class<?>    │
│  @Anno       │            │  RuntimeVisible- │                 │  objects     │
│              │            │  Annotations     │                 │              │
└──────────────┘            └──────────────────┘                 └──────┬───────┘
                                                                       │
                                                          reflection API
                                                                       │
                                                                       ▼
                                                        getAnnotation(...)
                                                        invoke / get / set
                                                                       │
                                                          your framework
                                                          does the work
```

**Key insight:** The JVM treats annotations as **data**, not as code. It has no idea what `@Inject`, `@Test`, or `@Entity` mean. It only knows how to *store* and *retrieve* them.

---

## 2. Compile Time — `javac` Turns Annotations into Bytes

When `javac` compiles a class, every annotation with a retention policy of `CLASS` or `RUNTIME` is written into the `.class` file as an **annotation attribute**. Source-only (`SOURCE`) annotations are discarded immediately.

### What the Class File Stores

The JVM spec defines three annotation-related attributes:

| Attribute | Applies To | Retention Policy |
|---|---|---|
| `RuntimeVisibleAnnotations` | class, field, method, parameter, etc. | `RUNTIME` |
| `RuntimeInvisibleAnnotations` | same | `CLASS` |
| `RuntimeVisibleParameterAnnotations` | method/constructor parameters | `RUNTIME` |
| `RuntimeInvisibleParameterAnnotations` | same | `CLASS` |
| `RuntimeVisibleTypeAnnotations` | type uses (`List<@NonNull String>`) | `RUNTIME` |
| `AnnotationDefault` | annotation interface methods | — |

Only `RuntimeVisible*` attributes are readable by reflection. `RuntimeInvisible*` attributes are still in the class file (used by tools like ProGuard and static analyzers) but invisible to `getAnnotation()`.

### Example

Source:
```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Column {
    String value();
}
```

```java
public class User {
    @Column("user_name")
    private String name;
}
```

After compilation, `User.class` contains (simplified pseudo-bytecode):

```
field name: java.lang.String
  RuntimeVisibleAnnotations:
    com.example.Column(value="user_name")
```

That's it. The JVM will never interpret `"user_name"` — it will only make it available to reflection.

### The Values Inside an Annotation

Annotation values are restricted to a fixed set of types the JVM can encode in the constant pool:

| Annotation member type | JVM encoding |
|---|---|
| `boolean`, `byte`, `char`, `short`, `int` | `const_value_index` → `CONSTANT_Integer` |
| `long` | `CONSTANT_Long` |
| `float` | `CONSTANT_Float` |
| `double` | `CONSTANT_Double` |
| `String` | `CONSTANT_Utf8` |
| `Class<?>` | `CONSTANT_Utf8` (descriptor) |
| enum constant | `CONSTANT_Utf8` (type + name) |
| another annotation | nested `annotation` structure |
| array of any of the above | `array_value` |

This is why **you cannot put a lambda, an object, or an instance in an annotation** — the class file format has no way to encode it. Anything "dynamic" must be referenced by a `Class<?>` that the framework instantiates later.

---

## 3. Class Loading — The JVM Reads the Attributes

When the class loader loads a class:

1. It parses the class file into an internal `InstanceKlass` (HotSpot).
2. It records `RuntimeVisibleAnnotations` on each member's metadata (`Method`, `FieldInfo`, etc.).
3. It **does not** resolve the annotation types eagerly — they are resolved lazily on first reflective access.

This means: **just annotating a class costs almost nothing at load time.** The cost is paid only when someone calls `getAnnotation(...)`.

### Resolution of Annotation Types

When you first call `method.getAnnotation(Column.class)`:

1. The JVM reads the raw annotation bytes from the class file.
2. It resolves the annotation type (`Column`) via the class loader.
3. It creates a **dynamic proxy** implementing `Column` and populating its methods with the stored values.
4. It caches the result so subsequent calls reuse the same instance.

Yes — annotations at runtime are **JDK dynamic proxies**. Every `getAnnotation()` call returns a `Proxy` instance whose invocation handler reads values from a map.

You can prove this:

```java
Column c = field.getAnnotation(Column.class);
System.out.println(c.getClass());       // class com.sun.proxy.$Proxy4
System.out.println(c instanceof Column); // true
```

---

## 4. Retention — Where the JVM Cuts Off

`@Retention` controls how far an annotation travels:

| Retention | Stored in class file? | Visible to reflection? | When used |
|---|---|---|---|
| `SOURCE` | ❌ (discarded by javac) | ❌ | `@Override`, `@SuppressWarnings`, `@NotNull` — for compile-time checkers |
| `CLASS` | ✅ | ❌ (only `RuntimeInvisibleAnnotations`) | Bytecode analyzers, ProGuard, AspectJ weaving |
| `RUNTIME` | ✅ | ✅ | Spring, JUnit, Hibernate, Jackson — anything reflection-driven |

### Why This Matters

- `SOURCE` annotations have **zero runtime cost** — the JVM never sees them. They exist purely for the compiler and tools like Lombok/ErrorProne.
- `CLASS` annotations are visible to **bytecode processing tools** (ASM, Javassist, byte-buddy) but *not* to normal reflection. Frameworks doing compile-time or class-load-time instrumentation use this.
- `RUNTIME` annotations are what 99% of developers mean. They carry a small memory cost (stored in metadata) and a resolution cost (proxy creation on first read).

---

## 5. Runtime — What Happens on `getAnnotation()`

The `AnnotatedElement` API on `Class`, `Method`, `Field`, `Constructor`, and `Parameter` is where the JVM actually does something. The call chain is roughly:

```
Field.getAnnotation(Column.class)
   └── native → JVM reads RuntimeVisibleAnnotations from FieldInfo
       └── resolves Column.class via class loader
           └── builds a Map<String, Object> of memberName → value
               └── creates Proxy(Column, handler that reads from the Map)
                   └── caches the Proxy on the field's metadata
                       └── returns it
```

Subsequent calls return the **same cached proxy instance** — so `getAnnotation()` is cheap after the first call. This is why **caching your own reflection objects** (as covered in the previous chapter) is good, but caching the annotation itself is unnecessary: the JVM already does it.

### Inherited Annotations

`@Inherited` only works on **class-level** annotations, and only when querying via a subclass:

```java
@Inherited
@Retention(RUNTIME) @Target(TYPE)
@interface Entity {}

@Entity class Base {}
class Sub extends Base {}

Sub.class.getAnnotation(Entity.class);       // ✅ found (inherited)
Sub.class.getDeclaredAnnotation(Entity.class); // ❌ null (only declared on Base)
```

Method and field annotations are **never inherited**, regardless of `@Inherited`. That's why frameworks like Spring scan the superclass hierarchy manually.

### Repeatable Annotations

Since Java 8, an annotation marked `@Repeatable` is compiled into a **container annotation**:

```java
@Repeatable(Schedules.class)
@interface Schedule { String cron(); }

@interface Schedules { Schedule[] value(); }

@Schedule(cron = "0 0 * * *")
@Schedule(cron = "0 12 * * *")
class Job {}
```

At the class-file level this becomes:

```
RuntimeVisibleAnnotations:
    com.example.Schedules(
        value = [
            @Schedule(cron="0 0 * * *"),
            @Schedule(cron="0 12 * * *")
        ]
    )
```

The JVM only stores the container. Reflection offers two accessors:

```java
Schedule[] all = Job.class.getAnnotationsByType(Schedule.class); // unwraps the container
Schedules c   = Job.class.getAnnotation(Schedules.class);        // raw container
```

A good rule: use `getAnnotationsByType()` — it hides the container mechanism.

---

## 6. `@Target` — The Compiler Enforces It, Not the JVM

An important subtlety: `@Target` is enforced **at compile time by `javac`**. The JVM's class file format does not prevent an annotation from being attached to a location its `@Target` forbids — but a well-behaved compiler will never emit such a class file.

This matters for bytecode manipulation: tools like ASM and Byte Buddy can attach annotations to elements where `javac` wouldn't allow them. Reflection will happily return them.

---

## 7. `AnnotationProcessor` — The Other Half (Compile-Time)

There's a second, entirely separate mechanism most people conflate with runtime reflection: **annotation processors** (`javax.annotation.processing.Processor`).

- They run **inside `javac`**, before the class file is written.
- They can read `SOURCE`-retained annotations (reflection cannot).
- They can generate new source/class files.
- They have **no runtime cost** and **no runtime presence**.

Lombok, MapStruct, Dagger, and AutoValue work this way. Contrast:

| | `AnnotationProcessor` | Reflection |
|---|---|---|
| Runs | In `javac` (compile time) | In JVM (runtime) |
| Sees SOURCE annotations | ✅ | ❌ |
| Cost | Compile-time only | Startup + per-call |
| Failure mode | Compile error | `NullPointerException` or runtime exception |
| Examples | Lombok, MapStruct, Dagger | Spring, Hibernate, Jackson, JUnit |

A modern developer chooses processors when possible — they are faster, safer, and fail earlier.

---

## 8. End-to-End Trace — `@Inject` from Source to Action

Let's follow one annotation through the entire lifecycle:

```java
@Retention(RUNTIME)
@Target(FIELD)
@interface Inject { String value(); }

class Service {
    @Inject("db.url") String url;
}
```

1. **Compile**: `javac` sees `@Inject("db.url")` on the field and writes `RuntimeVisibleAnnotations: Inject(value="db.url")` into `Service.class`. The `Inject.class` itself is also compiled, containing an `AnnotationDefault` attribute for `value` if there were a default.

2. **Class load**: The JVM's class loader parses `Service.class`, stores the raw annotation bytes in the `FieldInfo` for `url`. No proxy created yet.

3. **First reflection call**:
   ```java
   Field f = Service.class.getDeclaredField("url");
   Inject inj = f.getAnnotation(Inject.class);
   ```
   The JVM resolves `Inject.class` via the class loader, reads `"db.url"` from the raw bytes, builds a `Map{"value" → "db.url"}`, creates a dynamic proxy implementing `Inject`, and caches it.

4. **Your framework acts**:
   ```java
   f.trySetAccessible();
   f.set(instance, container.resolve(inj.value()));
   ```
   The JVM performs the field write. The annotation has done its job — it steered *your* code, not the JVM's.

5. **Steady state**: All subsequent `getAnnotation(Inject.class)` calls return the same cached proxy. `Field.set` runs at near-native speed after JIT warmup.

---

## 9. Costs and Rules of Thumb

| Concern | Reality |
|---|---|
| Memory cost of a `RUNTIME` annotation | A few bytes in the class file + a cached proxy after first read |
| `SOURCE` retention cost | Zero at runtime |
| First `getAnnotation` | Resolves type, builds proxy, caches |
| Subsequent `getAnnotation` | Map lookup + return cached proxy — very cheap |
| `Field.set` / `Method.invoke` | Boxes primitives, does access checks; use `setInt`/`MethodHandle` for hot loops |
| Module system (Java 9+) | Reflection into a non-open package throws `InaccessibleObjectException`; use `trySetAccessible` or add `opens` in `module-info.java` |
| Annotation types resolution | Lazy — a class with `@Foo` doesn't force `Foo` to load until reflection needs it |

### Four rules a good developer follows

1. **Choose the right retention.** If a tool only needs to see the annotation at compile time, use `SOURCE`. If only bytecode tools need it, use `CLASS`. Reserve `RUNTIME` for reflection.
2. **Cache your `Field`/`Method`/`Constructor`, not the annotation.** The JVM caches the proxy for you.
3. **Prefer `getAnnotationsByType` over manually unwrapping repeatable containers.** It's the JVM's official API for this.
4. **Prefer compile-time processors over runtime reflection when feasible.** They fail at build time, run at zero runtime cost, and don't fight the module system.

---

## 10. Summary — What the JVM Actually Does vs. What You Do

| Step | Who does it |
|---|---|
| Parse `@Anno` from source | `javac` |
| Store as `RuntimeVisibleAnnotations` in class file | `javac` |
| Load annotation bytes into metadata | JVM class loader |
| Resolve annotation type on first read | JVM (lazily) |
| Build a dynamic proxy of the annotation | JVM |
| Cache the proxy per element | JVM |
| Return annotation from `getAnnotation()` | JVM |
| **Decide what the annotation means** | **Your code / framework** |
| **Invoke methods, set fields, route requests** | **Your code / framework** |

The JVM is a **storage and retrieval engine** for annotations. It never interprets them. Understanding this boundary is what separates someone who *uses* frameworks from someone who can *write* them.

Once you internalize this, the previous chapters on `Method`/`Field`/`Constructor` and custom functional annotations click into place: the JVM gives you the metadata cheaply and correctly; the framework turns that metadata into behavior via reflection.

[[Java]]