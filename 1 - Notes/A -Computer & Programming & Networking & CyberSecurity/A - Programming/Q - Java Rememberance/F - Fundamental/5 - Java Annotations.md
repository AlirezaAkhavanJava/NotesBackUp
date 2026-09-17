
# Java Annotations — Built-in, Custom, and Reflection-Based Processing

Annotations are metadata attached to Java code elements (classes, methods, fields, parameters, etc.). They do not change program behavior directly — they are **read** by the compiler, by annotation processors at build time, or by frameworks via **reflection** at runtime. Spring is built almost entirely on this mechanism: `@Autowired`, `@RestController`, `@Transactional`, `@RequestMapping` are all annotations that Spring discovers and acts upon via reflection.

---

## Part 1 — What Annotations Are (and Are Not)

### What they are
- A form of **metadata** with a defined type.
- Applied to declarations (and since Java 8, to types via type annotations).
- Retained at source, class, or runtime level depending on policy.
- Read by the compiler, tools, or runtime reflection.

### What they are not
- Not executable code.
- Not inherited in the class-hierarchy sense unless marked `@Inherited`.
- Not a replacement for interfaces or design patterns.
- Not inherently processed — something must read them.

### Syntax

```java
@Override
public String toString() { ... }

@SuppressWarnings("unchecked")
List<String> list = (List<String>) rawList;

@Deprecated
public void oldMethod() { ... }
```

Annotations can have **elements** (key-value pairs):

```java
@RequestMapping(path = "/users", method = RequestMethod.GET)
public List<User> getUsers() { ... }
```

If an annotation has only one element named `value`, the name can be omitted:

```java
@SuppressWarnings("unchecked")  // same as @SuppressWarnings(value = "unchecked")
```

---

## Part 2 — Built-in Annotations in `java.lang`

These are available without imports.

### `@Override`
- Tells the compiler the method **must** override a superclass method or implement an interface method.
- Compile error if no such method exists.
- Prevents silent bugs from typos or signature mismatches.

```java
class Parent { void greet() {} }
class Child extends Parent {
    @Override
    void greet() {} // OK

    // @Override
    // void greett() {} // compile error — no such method to override
}
```

### `@Deprecated`
- Marks an API as discouraged for use.
- Compiler warns on usage.
- Since Java 9, supports `since` and `forRemoval` elements:

```java
@Deprecated(since = "9", forRemoval = true)
public void legacyMethod() { ... }
```

- Pair with Javadoc `@deprecated` tag for documentation.
- `@deprecated` (Javadoc) and `@Deprecated` (annotation) are distinct but conventionally used together.

### `@SuppressWarnings`
- Suppresses specific compiler warnings.
- Takes a `String[]` of warning categories.

```java
@SuppressWarnings("unchecked")
@SuppressWarnings({"unchecked", "rawtypes"})
@SuppressWarnings("deprecation")
```

Common categories: `unchecked`, `deprecation`, `rawtypes`, `serial`, `unused`, `all`.

Apply at the **narrowest scope possible** — a local variable or method, not an entire class, unless justified.

### `@SafeVarargs`
- Suppresses unchecked warnings for generic varargs.
- Can only be applied to `static`, `final`, or `private` methods, and constructors (Java 9+).
- Asserts that the method does not perform unsafe operations on its varargs array.

```java
@SafeVarargs
static <T> List<T> of(T... elements) {
    return Arrays.asList(elements);
}
```

### `@FunctionalInterface`
- Asserts the interface has exactly one abstract method.
- Compile error otherwise.
- Enables lambda and method reference usage.

```java
@FunctionalInterface
interface Transformer<T, R> {
    R apply(T t);
}
```

### `@Native`
- Indicates a field is a constant that may be referenced from native code.
- Rare; used by tools like `javah`/`javac -h`.

---

## Part 3 — Meta-Annotations

Meta-annotations annotate other annotations. They define how an annotation behaves.

Located in `java.lang.annotation`.

### `@Retention`
Defines **how long** the annotation is retained.

| Policy | Meaning | Available at |
|---|---|---|
| `SOURCE` | Discarded by compiler | Source only |
| `CLASS` | Stored in `.class` file, not visible at runtime | Compile time; **default** |
| `RUNTIME` | Stored in `.class` file, visible via reflection | Runtime |

```java
@Retention(RetentionPolicy.RUNTIME)
@interface MyAnnotation { }
```

**Critical for Spring**: Spring reads annotations at runtime, so Spring annotations use `RUNTIME`.

### `@Target`
Restricts **where** the annotation can be applied.

```java
@Target(ElementType.METHOD)
@interface MyMethodAnnotation { }
```

`ElementType` values:

| Value | Applies to |
|---|---|
| `TYPE` | Class, interface, enum, record, annotation |
| `FIELD` | Field (including enum constants) |
| `METHOD` | Method |
| `PARAMETER` | Method/constructor parameter |
| `CONSTRUCTOR` | Constructor |
| `LOCAL_VARIABLE` | Local variable |
| `ANNOTATION_TYPE` | Annotation type declaration |
| `PACKAGE` | Package declaration |
| `TYPE_PARAMETER` | Generic type parameter (Java 8+) |
| `TYPE_USE` | Any type use (Java 8+) |
| `MODULE` | Module declaration (Java 9+) |
| `RECORD_COMPONENT` | Record component (Java 16+) |

If `@Target` is absent, the annotation can be applied anywhere (except type-use contexts).

```java
@Target({ElementType.METHOD, ElementType.FIELD})
@interface Injectable { }
```

### `@Documented`
- Includes the annotation in Javadoc-generated documentation.
- Purely cosmetic.

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@interface PublicApi { }
```

### `@Inherited`
- Makes the annotation **inherited by subclasses**.
- Only works for **class-level** annotations.
- Does **not** apply to interfaces, methods, or fields.

```java
@Inherited
@Retention(RetentionPolicy.RUNTIME)
@interface Audited { }

@Audited
class Base { }

class Child extends Base { } // Child is considered @Audited via reflection
```

`getClass().getAnnotation(Audited.class)` on `Child` returns the annotation if `@Inherited` is present. `getDeclaredAnnotation` does not.

### `@Repeatable`
- Allows the annotation to be applied multiple times to the same element.
- Requires a **container annotation**.

```java
@Retention(RetentionPolicy.RUNTIME)
@Repeatable(Schedules.class)
@interface Schedule {
    String day();
}

@Retention(RetentionPolicy.RUNTIME)
@interface Schedules {
    Schedule[] value();
}
```

Usage:

```java
@Schedule(day = "Monday")
@Schedule(day = "Wednesday")
class Meeting { }
```

Reading via reflection:

```java
Schedule[] schedules = Meeting.class.getAnnotationsByType(Schedule.class);
Schedules container = Meeting.class.getAnnotation(Schedules.class);
```

---

## Part 4 — Writing Custom Annotations

### Declaration syntax

```java
public @interface MyAnnotation {
    String value() default "";
    int count() default 0;
    Class<?> type() default Object.class;
    String[] tags() default {};
    RetentionPolicy policy() default RetentionPolicy.CLASS;
}
```

Rules:
- Declared with `@interface`.
- Elements are declared like methods with no parameters.
- Element types allowed: primitives, `String`, `Class`, enums, annotations, and **arrays of these**.
- **Not allowed**: generic types, `null` defaults, arbitrary objects.
- `default` provides an optional value.
- If an element is named `value` and is the only one specified, the name can be omitted at use site.
- Annotation types are implicitly `public` (if top-level) or follow access rules.
- Annotation types cannot be generic.
- Annotation types cannot extend anything (implicitly extend `Annotation`).
- Methods cannot have parameters or `throws` clauses.

### Example: a simple marker annotation

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Component {
}
```

### Example: an annotation with elements

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Retry {
    int maxAttempts() default 3;
    long delayMs() default 1000;
    Class<? extends Throwable>[] on() default { Exception.class };
}
```

Usage:

```java
@Retry(maxAttempts = 5, delayMs = 500, on = { IOException.class })
public void fetchData() { ... }
```

### Example: `@Inherited` annotation

```java
@Inherited
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Entity {
    String table();
}
```

---

## Part 5 — Reading Annotations via Reflection

### Core reflection APIs on `Class`

| Method | Behavior |
|---|---|
| `getAnnotation(Class)` | Returns annotation or `null`; respects `@Inherited` |
| `getAnnotations()` | All annotations, including inherited |
| `getDeclaredAnnotation(Class)` | Only directly declared, ignores `@Inherited` |
| `getDeclaredAnnotations()` | Only directly declared |
| `getAnnotationsByType(Class)` | Handles `@Repeatable` |
| `isAnnotationPresent(Class)` | Boolean check |

The same methods exist on `Method`, `Field`, `Constructor`, `Parameter`, and `AnnotatedType`.

### Basic reading

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Loggable {
    String level() default "INFO";
}

class Service {
    @Loggable(level = "DEBUG")
    public void process() { }
}

Method m = Service.class.getMethod("process");
if (m.isAnnotationPresent(Loggable.class)) {
    Loggable log = m.getAnnotation(Loggable.class);
    System.out.println(log.level()); // DEBUG
}
```

### Processing annotations — a mini framework

```java
class RetryInvoker {
    static Object invokeWithRetry(Object target, Method method, Object[] args) throws Exception {
        Retry retry = method.getAnnotation(Retry.class);
        if (retry == null) {
            return method.invoke(target, args);
        }
        int attempts = 0;
        while (true) {
            try {
                return method.invoke(target, args);
            } catch (InvocationTargetException e) {
                attempts++;
                if (attempts >= retry.maxAttempts()) throw (Exception) e.getCause();
                Thread.sleep(retry.delayMs());
            }
        }
    }
}
```

This is the essence of how Spring’s `@Transactional`, `@Retryable`, and `@Cacheable` work — reflection reads the annotation, then a proxy intercepts the call.

### Reading parameter annotations

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.PARAMETER)
@interface Param {
    String name();
}

void createUser(@Param(name = "id") long id, @Param(name = "email") String email) { }

Method m = MyClass.class.getMethod("createUser", long.class, String.class);
Annotation[][] paramAnns = m.getParameterAnnotations();
for (Annotation[] anns : paramAnns) {
    for (Annotation a : anns) {
        if (a instanceof Param p) {
            System.out.println(p.name());
        }
    }
}
```

This is exactly how Spring MVC resolves `@RequestParam`, `@PathVariable`, and `@RequestBody`.

---

## Part 6 — Annotation Processing (Compile-Time)

### Pluggable Annotation Processing API (JSR 269)
- Runs during `javac`.
- Implemented by extending `AbstractProcessor`.
- Can generate code, validate constraints, or produce resources.
- Does **not** run at application runtime.

```java
@SupportedAnnotationTypes("com.example.Builder")
@SupportedSourceVersion(SourceVersion.RELEASE_17)
public class BuilderProcessor extends AbstractProcessor {
    @Override
    public boolean process(Set<? extends TypeElement> annotations,
                           RoundEnvironment env) {
        for (Element e : env.getElementsAnnotatedWith(Builder.class)) {
            // generate a builder class
        }
        return true;
    }
}
```

Used by libraries like **Lombok**, **MapStruct**, **Dagger**, **AutoValue**.

### Retention and processing

- `SOURCE` → visible only to annotation processors.
- `CLASS` → visible in bytecode but not at runtime.
- `RUNTIME` → visible to reflection and frameworks.

---

## Part 7 — How Spring Uses Annotations

Spring is fundamentally a **reflection + annotation** framework.

### Stereotype annotations

```java
@Component  // generic bean
@Service    // semantic specialization
@Repository // data access
@Controller // web controller
@RestController // = @Controller + @ResponseBody
```

All are `@Component`-meta-annotated and `RUNTIME`-retained. Spring scans the classpath, finds annotated classes, and registers them as beans.

### Dependency injection

```java
@Autowired
private UserRepository repo;
```

Spring reads `@Autowired` via reflection on fields, constructors, or setters, then injects the matching bean.

### Web mapping

```java
@RestController
@RequestMapping("/api/users")
class UserController {
    @GetMapping("/{id}")
    public User get(@PathVariable long id, @RequestParam String filter) { ... }
}
```

Spring scans methods, reads `@GetMapping`/`@RequestMapping`, and builds a handler mapping at startup.

### Meta-annotations in Spring

Spring uses meta-annotations heavily:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface Service {
    @AliasFor(annotation = Component.class)
    String value() default "";
}
```

`@Service` is itself annotated with `@Component`. Spring’s `AnnotatedElementUtils` performs **meta-annotation searches** — finding annotations on annotations.

### Spring’s annotation utilities

- `AnnotationUtils.findAnnotation(...)` — meta-annotation aware.
- `AnnotatedElementUtils.findMergedAnnotation(...)` — handles `@AliasFor` and attribute overrides.
- `MergedAnnotations` (Spring 5+) — modern API for aggregated annotation views.

### AOP and proxying

- `@Transactional`, `@Cacheable`, `@Async`, `@PreAuthorize` are read at runtime.
- Spring creates a **proxy** (JDK dynamic proxy or CGLIB subclass).
- The proxy intercepts method calls and applies advice before/after the target method.

This is why `@Transactional` on a private method or self-invocation does not work — the proxy is bypassed.

### Conditional configuration

```java
@ConditionalOnClass(DataSource.class)
@ConditionalOnMissingBean
@Profile("prod")
```

Spring Boot evaluates these via reflection and environment state.

---

## Part 8 — Full Custom Example: A Mini DI Framework

### The annotations

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Component {
}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Inject {
}
```

### The classes

```java
@Component
class UserRepository {
    public String findUser() { return "Alice"; }
}

@Component
class UserService {
    @Inject
    private UserRepository repository;

    public String greet() { return "Hello, " + repository.findUser(); }
}
```

### The container

```java
class MiniContainer {
    private final Map<Class<?>, Object> beans = new HashMap<>();

    void scan(String packageName) throws Exception {
        // In a real framework: classpath scanning.
        // Here we hardcode the classes for illustration.
        Class<?>[] classes = { UserRepository.class, UserService.class };
        for (Class<?> c : classes) {
            if (c.isAnnotationPresent(Component.class)) {
                beans.put(c, c.getDeclaredConstructor().newInstance());
            }
        }
        for (Object bean : beans.values()) {
            injectFields(bean);
        }
    }

    private void injectFields(Object bean) throws Exception {
        for (Field f : bean.getClass().getDeclaredFields()) {
            if (f.isAnnotationPresent(Inject.class)) {
                Object dependency = beans.get(f.getType());
                if (dependency == null) throw new IllegalStateException("No bean for " + f.getType());
                f.setAccessible(true);
                f.set(bean, dependency);
            }
        }
    }

    <T> T getBean(Class<T> type) {
        return type.cast(beans.get(type));
    }
}
```

### Usage

```java
MiniContainer container = new MiniContainer();
container.scan("com.example");
UserService service = container.getBean(UserService.class);
System.out.println(service.greet()); // Hello, Alice
```

This is a microcosm of Spring: classpath scanning + annotation reading + reflection-based injection.

---

## Part 9 — Best Practices and Pitfalls

### Best practices

- Always specify `@Retention` and `@Target` explicitly.
- Use `RUNTIME` only when reflection is needed; prefer `CLASS` or `SOURCE` otherwise.
- Use `@Documented` for public APIs.
- Use `@Inherited` sparingly — only for class-level semantics.
- Keep annotation element types simple and serializable.
- Provide sensible `default` values.
- Use `@Repeatable` instead of array elements when the annotation may repeat.
- Prefer meta-annotations for composability (as Spring does).
- Document the semantic meaning and the processor that reads the annotation.
- Validate annotation usage in the processor/reader, not in the annotation itself.

### Pitfalls

| Pitfall | Consequence |
|---|---|
| Forgetting `@Retention(RUNTIME)` | Annotation invisible to Spring/reflection |
| Forgetting `@Target` | Annotation applicable where it shouldn’t be |
| Relying on `@Inherited` for methods | Does not work — only class-level |
| Mutating annotation arrays | `getAnnotations()` returns copies, but element arrays can be shared; treat as immutable |
| Using annotations for behavior without a processor | Nothing happens |
| Assuming `getAnnotation` sees meta-annotations | It does not; use `AnnotationUtils`/`AnnotatedElementUtils` in Spring |
| `@Transactional` on private/self-invoked methods | Proxy bypassed; no transaction |
| Overusing `RUNTIME` retention | Slower startup, more memory |
| Annotation with `null` default | Not allowed — compile error |
| Generic annotation elements | Not allowed |

### Performance notes

- Reflection is slower than direct calls, but annotation reads are typically cached by frameworks.
- Spring caches annotation metadata per class.
- Excessive classpath scanning at startup can be slow — Spring Boot uses indexing (`@Indexed`, `spring-context-indexer`) to mitigate.

---

## Part 10 — Quick Reference

### Built-in annotations

| Annotation | Purpose | Retention |
|---|---|---|
| `@Override` | Enforce overriding | SOURCE |
| `@Deprecated` | Mark discouraged API | RUNTIME |
| `@SuppressWarnings` | Suppress compiler warnings | SOURCE |
| `@SafeVarargs` | Suppress varargs warnings | RUNTIME |
| `@FunctionalInterface` | Enforce single abstract method | RUNTIME |
| `@Native` | Native-accessible constant | SOURCE |

### Meta-annotations

| Annotation | Purpose |
|---|---|
| `@Retention` | How long the annotation is kept |
| `@Target` | Where it can be applied |
| `@Documented` | Include in Javadoc |
| `@Inherited` | Inherit to subclasses (class-level only) |
| `@Repeatable` | Allow multiple applications |

### Retention policies

| Policy | Visible to compiler | In bytecode | Visible at runtime |
|---|---|---|---|
| `SOURCE` | Yes | No | No |
| `CLASS` | Yes | Yes | No |
| `RUNTIME` | Yes | Yes | Yes |

### Reflection methods

| Method | Inherited? | Repeatable? |
|---|---|---|
| `getAnnotation` | Yes | No |
| `getDeclaredAnnotation` | No | No |
| `getAnnotationsByType` | Yes | Yes |
| `getDeclaredAnnotationsByType` | No | Yes |
| `getAnnotations` | Yes | Container only |
| `getDeclaredAnnotations` | No | Container only |

### Spring’s key annotation utilities

| Utility | Use |
|---|---|
| `AnnotationUtils.findAnnotation` | Meta-annotation aware lookup |
| `AnnotatedElementUtils.findMergedAnnotation` | Handles `@AliasFor`, attribute overrides |
| `MergedAnnotations.from(...)` | Aggregated view of all annotations |
| `ClassPathScanningCandidateComponentProvider` | Classpath scanning for `@Component` |

---

## The Big Picture

Annotations are **metadata with types**. They do nothing on their own. Their power comes from **who reads them**:

- The **compiler** reads `@Override`, `@SuppressWarnings`, `@FunctionalInterface`.
- **Annotation processors** read `SOURCE`-retained annotations at build time (Lombok, MapStruct).
- **Frameworks** read `RUNTIME`-retained annotations via reflection (Spring, JPA, Jackson).
- **Your own code** can read them too — that is how you build mini-frameworks.

Spring is essentially a large, well-engineered annotation reader: it scans the classpath, reads annotations via reflection (with meta-annotation and `@AliasFor` support), builds a bean graph, and wires everything together. Understanding annotations and reflection is therefore not optional for Spring — it is the foundation.


[[Java]]