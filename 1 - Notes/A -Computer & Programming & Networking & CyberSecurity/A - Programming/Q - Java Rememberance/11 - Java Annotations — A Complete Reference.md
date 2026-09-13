


Annotations are **metadata tags** you attach to code. The compiler, tools, or frameworks read them and change behavior. Below is a categorized list of the **standard JDK annotations** plus the most important third-party ones you'll meet in real projects.

For each: **what it means (plain English)**, **where it goes**, and a **short example**.

---

## 1. Core Language Annotations (`java.lang`)

These come built into every Java program.

### `@Override`
**Definition:** Tells the compiler "I intend to override a method from a superclass or interface." If you got the signature wrong, compilation fails.
**Target:** Method
**Retention:** SOURCE

```java
class Animal { void speak() {} }
class Dog extends Animal {
    @Override void speak() { System.out.println("Woof"); }
    // @Override void speek() {}   ← compile error, nothing to override
}
```

### `@Deprecated`
**Definition:** Marks an API as obsolete. Using it produces a compiler warning.
**Target:** Class, method, field, constructor, package, etc.

```java
@Deprecated(since = "9", forRemoval = true)
public void oldApi() { }
```

### `@SuppressWarnings`
**Definition:** Silences specific compiler warnings (unchecked, deprecation, rawtypes, etc.).
**Target:** Class, method, field, parameter, local variable

```java
@SuppressWarnings({"unchecked", "deprecation"})
List<String> raw = new ArrayList();
```

### `@SafeVarargs`
**Definition:** Promises the compiler that a varargs method doesn't perform unsafe operations on its generic array. Removes the "possible heap pollution" warning.
**Target:** Method, constructor (must be `static`, `final`, or `private`)

```java
@SafeVarargs
static <T> List<T> listOf(T... items) { return List.of(items); }
```

### `@FunctionalInterface`
**Definition:** Declares that an interface has exactly one abstract method — safe to use as a lambda target. Compilation fails if you add a second abstract method.
**Target:** Interface

```java
@FunctionalInterface
interface Calculator { int apply(int a, int b); }
Calculator add = (a, b) -> a + b;
```

### `@Native`
**Definition:** Hint to tools that a `static final` field is backed by a native constant (rarely used directly).
**Target:** Field

---

## 2. Meta-Annotations (`java.lang.annotation`)

These annotations **annotate other annotations**. You use them when writing your own annotation types.

### `@Retention`
**Definition:** Says how long the annotation is kept — `SOURCE` (discarded by compiler), `CLASS` (kept in class file but invisible to reflection), or `RUNTIME` (visible to reflection). Default is `CLASS`.

```java
@Retention(RetentionPolicy.RUNTIME)
@interface Audited { }
```

### `@Target`
**Definition:** Restricts where the annotation may be applied (fields, methods, types, parameters, etc.). Without it, the annotation can go anywhere.

```java
@Target({ElementType.METHOD, ElementType.FIELD})
@interface Tracked { }
```

### `@Documented`
**Definition:** Includes the annotation in generated Javadoc.

```java
@Documented @Retention(RUNTIME) @interface PublicApi { }
```

### `@Inherited`
**Definition:** Class-level annotations are automatically inherited by subclasses. Works **only** on class annotations, never on methods or fields.

```java
@Inherited @Retention(RUNTIME) @Target(TYPE)
@interface Entity { }

@Entity class Base {}
class Sub extends Base {}   // Sub.class.getAnnotation(Entity.class) != null
```

### `@Repeatable`
**Definition:** Lets you apply the same annotation multiple times to one element. The compiler wraps them in a container annotation.

```java
@Repeatable(Schedules.class) @interface Schedule { String cron(); }
@interface Schedules { Schedule[] value(); }

@Schedule(cron = "0 0 * * *")
@Schedule(cron = "0 12 * * *")
class Job { }
```

### `@Native` (also in `java.lang`)
See above.

---

## 3. Compile-Time / Override Helpers

### `@Override`, `@Deprecated`, `@SuppressWarnings`, `@SafeVarargs`, `@FunctionalInterface`
Covered in section 1 — these are the everyday "compiler hints."

---

## 4. Common JDK Library Annotations

### `@Serial`
**Package:** `java.io`
**Definition:** Marks fields and methods that are part of Java's built-in serialization contract. Helps the compiler catch typos in `serialVersionUID`, `writeObject`, `readObject`, etc.
**Target:** Field, method

```java
class User implements Serializable {
    @Serial private static final long serialVersionUID = 1L;
    @Serial private void writeObject(ObjectOutputStream out) throws IOException { ... }
}
```

### `@Override` on interface methods (Java 6+)
Same annotation — allowed on methods implementing interface methods, not just superclass methods.

### `@Deprecated` with `since` / `forRemoval`
Since Java 9, you can state *when* the API was deprecated and whether it will be removed.

```java
@Deprecated(since = "17", forRemoval = true)
public void legacy() { }
```

---

## 5. Reflection & Runtime Annotations

There are no `@Reflect`-style annotations in the JDK. The runtime visibility of annotations is controlled entirely by `@Retention(RUNTIME)` on the annotation's own definition (see section 2). Frameworks rely on that.

---

## 6. Java EE / Jakarta EE Annotations (`jakarta.*`)

Common in Spring Boot, Jakarta EE, and microservice projects. (Older code uses `javax.*`.)

### `@Inject`
**Definition:** "Please give me a dependency here." Used for dependency injection into fields, constructors, or methods.
**Target:** Field, constructor, method

```java
class OrderService {
    @Inject private PaymentGateway gateway;
}
```

### `@Named`
**Definition:** Gives a bean a name so it can be referenced by string.

```java
@Named("paypal")
class PayPalGateway implements PaymentGateway { }
```

### `@Singleton`
**Definition:** One instance per container.

```java
@Singleton
class Cache { }
```

### `@PostConstruct` / `@PreDestroy`
**Definition:** Lifecycle callbacks — run after injection completes / before the bean is destroyed.

```java
@PostConstruct void init() { /* open resources */ }
@PreDestroy  void close() { /* release resources */ }
```

### `@Resource`
**Definition:** Injects a named resource (JNDI lookup, data source, etc.).

```java
@Resource(name = "jdbc/orders") DataSource ds;
```

### `@Transactional`
**Definition (Spring):** Wraps the method in a database transaction.

```java
@Transactional
public void transfer(Account from, Account to, BigDecimal amount) { ... }
```

### `@Qualifier`
**Definition:** Disambiguates when multiple beans match the same type.

```java
@Autowired @Qualifier("paypal") PaymentGateway gateway;
```

### `@Autowired` (Spring-specific, but ubiquitous)
**Definition:** Spring's equivalent of `@Inject`.

---

## 7. Web Layer (`jakarta.ws.rs.*` / Spring MVC)

### `@Path`
**Definition:** Maps a class or method to a URL path.

```java
@Path("/users")
class UserResource {
    @GET @Path("/{id}")
    public User get(@PathParam("id") long id) { ... }
}
```

### `@GET`, `@POST`, `@PUT`, `@DELETE`
**Definition:** Bind a method to an HTTP verb.

### `@Produces` / `@Consumes`
**Definition:** Declare the media types a method produces or accepts.

```java
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
```

### `@PathParam`, `@QueryParam`, `@HeaderParam`, `@FormParam`
**Definition:** Bind method parameters to parts of the HTTP request.

```java
public User get(@PathParam("id") long id,
                @QueryParam("expand") String expand) { ... }
```

### Spring MVC equivalents
`@RestController`, `@Controller`, `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PathVariable`, `@RequestParam`, `@RequestBody`, `@ResponseBody`, `@ResponseStatus`.

```java
@RestController
@RequestMapping("/users")
class UserController {
    @GetMapping("/{id}")
    User get(@PathVariable long id) { ... }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    User create(@RequestBody User user) { ... }
}
```

---

## 8. Persistence — JPA / Hibernate (`jakarta.persistence.*`)

### `@Entity`
**Definition:** "This class maps to a database table."

```java
@Entity @Table(name = "users")
class User { ... }
```

### `@Table`
**Definition:** Specifies the table name and schema.

### `@Id`
**Definition:** Marks the primary key field.

```java
@Id @GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```

### `@GeneratedValue`
**Definition:** Says the DB (or provider) generates the ID.

### `@Column`
**Definition:** Maps a field to a specific column with options (nullable, length, unique).

```java
@Column(name = "user_name", nullable = false, length = 100)
private String name;
```

### `@Transient`
**Definition:** "Don't persist this field."

### `@Enumerated`
**Definition:** How to store an enum — `ORDINAL` (int) or `STRING`.

```java
@Enumerated(EnumType.STRING)
private Status status;
```

### `@Temporal`
**Definition:** How to map `Date` / `Calendar` (DATE / TIME / TIMESTAMP).

### `@OneToMany`, `@ManyToOne`, `@OneToOne`, `@ManyToMany`
**Definition:** Relationship mapping between entities.

```java
@OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
private List<Order> orders;
```

### `@JoinColumn`, `@JoinTable`
**Definition:** Specify the FK or join table.

### `@NamedQuery`, `@NamedQueries`
**Definition:** Predefined JPQL queries attached to an entity.

### `@Version`
**Definition:** Optimistic-locking column.

---

## 9. Validation — Jakarta Bean Validation (`jakarta.validation.*`)

### `@NotNull`, `@Null`
**Definition:** Field must not / must be null.

### `@NotEmpty`, `@NotBlank`
**Definition:** String/collection must have content. `@NotBlank` also trims whitespace.

### `@Size(min, max)`
**Definition:** Length/size constraint on strings, collections, maps, arrays.

### `@Min`, `@Max`, `@DecimalMin`, `@DecimalMax`
**Definition:** Numeric bounds.

### `@Positive`, `@PositiveOrZero`, `@Negative`, `@NegativeOrZero`
**Definition:** Sign constraints.

### `@Email`, `@Pattern(regexp = ...)`
**Definition:** Format constraints.

### `@Past`, `@PastOrPresent`, `@Future`, `@FutureOrPresent`
**Definition:** Temporal constraints.

### `@Valid`, `@Validated`
**Definition:** Triggers cascading validation on a parameter or field.

```java
class SignupRequest {
    @NotBlank @Size(min = 3, max = 20) String username;
    @Email @NotNull String email;
    @Min(18) int age;
}
```

---

## 10. JSON — Jackson (`com.fasterxml.jackson.annotation.*`)

### `@JsonProperty`
**Definition:** Renames a field in JSON.

```java
@JsonProperty("first_name") private String firstName;
```

### `@JsonIgnore`
**Definition:** Skip this field during serialization/deserialization.

### `@JsonIgnoreProperties`
**Definition:** Class-level list of fields to ignore (also ignores unknown JSON props).

```java
@JsonIgnoreProperties(ignoreUnknown = true)
class User { ... }
```

### `@JsonInclude`
**Definition:** Include only non-null / non-empty values.

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
```

### `@JsonFormat`
**Definition:** Format for dates, numbers, etc.

```java
@JsonFormat(pattern = "yyyy-MM-dd")
private LocalDate birthDate;
```

### `@JsonCreator` / `@JsonProperty` on constructor params
**Definition:** Tell Jackson how to build an immutable object.

```java
@JsonCreator
public User(@JsonProperty("id") long id,
            @JsonProperty("name") String name) { ... }
```

### `@JsonTypeInfo`, `@JsonSubTypes`
**Definition:** Polymorphic serialization — include a type discriminator and map subtypes.

---

## 11. Testing — JUnit 5 (`org.junit.jupiter.api.*`)

### `@Test`
**Definition:** Marks a method as a test case.

### `@BeforeEach` / `@AfterEach`
**Definition:** Run before / after each test.

### `@BeforeAll` / `@AfterAll`
**Definition:** Run once before / after all tests (must be `static` unless using `@TestInstance(PER_CLASS)`).

### `@Disabled`
**Definition:** Skip this test (with optional reason).

### `@DisplayName`
**Definition:** Human-readable test name.

### `@Nested`
**Definition:** Groups inner test classes logically.

### `@ParameterizedTest` + `@ValueSource` / `@CsvSource` / `@MethodSource`
**Definition:** Run the same test with multiple inputs.

```java
@ParameterizedTest
@CsvSource({"1,2,3", "4,5,9"})
void adds(int a, int b, int expected) {
    assertEquals(expected, a + b);
}
```

### `@Tag`
**Definition:** Categorize tests (e.g., "slow", "integration").

### `@ExtendWith`
**Definition:** Register a JUnit extension (like Mockito's `MockitoExtension`).

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock UserRepository repo;
    @InjectMocks UserService service;
    @Test void findsById() { ... }
}
```

---

## 12. Lombok (`lombok.*`)

Compile-time annotation processor that generates boilerplate.

### `@Getter` / `@Setter`
**Definition:** Generate getters/setters for fields.

### `@ToString`
**Definition:** Generate `toString()`.

### `@EqualsAndHashCode`
**Definition:** Generate `equals()` and `hashCode()`.

### `@Data`
**Definition:** Shortcut for `@Getter @Setter @ToString @EqualsAndHashCode @RequiredArgsConstructor`.

### `@Value`
**Definition:** Immutable version of `@Data` (all fields `final`, class `final`).

### `@Builder`
**Definition:** Generate a builder.

```java
@Builder
class User { String name; int age; }

User u = User.builder().name("Ana").age(30).build();
```

### `@NoArgsConstructor`, `@AllArgsConstructor`, `@RequiredArgsConstructor`
**Definition:** Generate constructors.

### `@Slf4j`
**Definition:** Inject a `private static final Logger log` field.

---

## 13. Concurrency / Utility JDK Annotations

### `@Contended`
**Package:** `jdk.internal.vm.annotation` (internal, use with care)
**Definition:** Pad a field to prevent false sharing in concurrent code.

### `@ForceInline`, `@DontInline`
Internal HotSpot annotations controlling JIT inlining.

### `@Stable`, `@Stable`-like
Hints that a field rarely changes — helps JIT optimizations.

These are **not for application code**; they're used inside the JDK.

---

## 14. Other Noteworthy Framework Annotations

### Spring Core
- `@Component`, `@Service`, `@Repository`, `@Controller` — stereotype markers.
- `@Configuration`, `@Bean` — Java-based configuration.
- `@Value("${prop}")` — inject a property.
- `@Profile("dev")` — activate beans per environment.
- `@Scheduled(cron = "...")` — schedule a method.
- `@Async` — run method on a thread pool.
- `@EventListener` — subscribe to application events.
- `@Cacheable`, `@CacheEvict`, `@CachePut` — caching.

### Spring Boot
- `@SpringBootApplication` — combines `@Configuration` + `@EnableAutoConfiguration` + `@ComponentScan`.
- `@EnableAutoConfiguration`.
- `@ConfigurationProperties(prefix = "...")` — bind external config to a bean.

### Spring Security
- `@PreAuthorize("hasRole('ADMIN')")` — method-level access control.
- `@Secured`, `@RolesAllowed`, `@PostAuthorize`, `@PostFilter`.

### Micrometer / Observability
- `@Timed`, `@Counted`, `@Metered` — metrics around methods.

### MapStruct
- `@Mapper` — declare a bean mapper.
- `@Mapping(source = "...", target = "...")` — field mapping rules.

### Async / Reactive
- `@NonBlocking` (Vert.x), `@Blocking`, `@Route`, `@Consumes` (Quarkus REST).

---

## 15. Choosing the Right Retention (Rule of Thumb)

| If the annotation is meant for… | Use |
|---|---|
| The compiler only (`@Override`, `@SuppressWarnings`) | `SOURCE` |
| Bytecode tools (AspectJ, ProGuard, byte-buddy) | `CLASS` |
| Runtime reflection (Spring, JPA, JUnit, Jackson) | `RUNTIME` |

**Good developer habit:** always set `@Retention` and `@Target` explicitly on your own annotations. Defaults are `CLASS` and "anywhere," which silently hides annotations from reflection — the #1 source of "why isn't my annotation working?" bugs.

---

## 16. Quick Cheat Sheet

| Purpose | Annotation |
|---|---|
| Override | `@Override` |
| Obsolete API | `@Deprecated` |
| Silence warnings | `@SuppressWarnings` |
| Lambda interface | `@FunctionalInterface` |
| Varargs safety | `@SafeVarargs` |
| Meta | `@Retention`, `@Target`, `@Inherited`, `@Repeatable`, `@Documented` |
| Serialization | `@Serial` |
| DI | `@Inject`, `@Autowired`, `@Resource`, `@Qualifier`, `@Named` |
| Lifecycle | `@PostConstruct`, `@PreDestroy` |
| Web | `@Path`, `@GET`, `@PostMapping`, `@RestController` |
| Persistence | `@Entity`, `@Id`, `@Column`, `@OneToMany` |
| Validation | `@NotNull`, `@Size`, `@Email`, `@Min` |
| JSON | `@JsonProperty`, `@JsonIgnore`, `@JsonFormat` |
| Testing | `@Test`, `@BeforeEach`, `@ParameterizedTest`, `@Mock` |
| Boilerplate | `@Data`, `@Builder`, `@Slf4j` (Lombok) |

---

## Closing Thought

The JDK ships only **~12 annotations** that do anything by themselves (`@Override`, `@Deprecated`, `@SuppressWarnings`, `@SafeVarargs`, `@FunctionalInterface`, plus the six meta-annotations). Everything else — DI, ORM, web, validation, JSON — is a *contract* between you and a library. The library uses **reflection** (or an **annotation processor**) to read those annotations and produce behavior.

Once you know which retention a library needs, which target it expects, and how it reads them, you can predict — and debug — any annotation-driven framework.


[[Java]]