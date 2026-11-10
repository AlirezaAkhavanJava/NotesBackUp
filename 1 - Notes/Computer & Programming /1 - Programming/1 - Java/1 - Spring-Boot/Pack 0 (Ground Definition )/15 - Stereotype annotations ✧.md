

A **stereotype annotation** is a label you put on a class to tell Spring two things: "create an object of this class and manage it" (make it a bean), and "this is the role it plays in the app." Spring ships a family of them: `@Component` is the generic one, and `@Service`, `@Repository`, `@Controller` and `@RestController` are specialized versions for the business, data and web layers.

---

## 1. The family: one base annotation, four flavors

`@Component` is the base. The others are **meta-annotated** with it, which means each of them has `@Component` written on its own definition:

```java
@Component
public @interface Service { ... }       // so a @Service IS a @Component
```

Spring's scan doesn't look for `@Component` literally. It looks for anything that is annotated with `@Component`, **directly or through another annotation**. That is why all of them are found by the same scan, and why you can build your own (see the related concept at the end).

|Annotation|Extra behavior beyond `@Component`?|Layer|
|---|---|---|
|`@Component`|None|Generic helpers (validators, formatters, utilities)|
|`@Service`|None. Purely a label for intent|Business logic|
|`@Repository`|**Yes**: exception translation|Data access|
|`@Controller`|**Yes**: Spring MVC treats it as a request handler|Web, returns views|
|`@RestController`|`@Controller` + `@ResponseBody`|Web, returns data (JSON)|

The label still matters even where there is no extra behavior. It tells every reader what a class is for, and tools (AOP pointcuts, IDE navigation, architecture-test rules) can target "all services." Swapping `@Service` for `@Component` would run, but it throws that information away.

 `@Configuration` is a `@Component` too. The difference is who builds the object: with a stereotype, **Spring** calls the constructor, and with a `@Bean` method, **you** do.

---

## 2. How Spring finds them: component scanning

`@SpringBootApplication` includes `@ComponentScan`, and the scan works like this:

1. It starts at the **package of your main class** and goes **downward** through all sub-packages.
2. It reads the class files and checks each for `@Component` (or an annotation that carries it).
3. For each match, it registers a `BeanDefinition`, the recipe you saw in the bean-declaration note. The beans are created later.

What follows from that:

- **Sibling and parent packages are not scanned.** Put a class in `org.other` while your main class is in `com.example`, and it's silently ignored.
- **Never put your main class in the default package** (no `package` line). Scanning breaks or covers too much.
- **A library's `@Component` classes aren't found automatically** unless they sit under your app's package. Libraries register their beans through auto-configuration instead, which is also how Spring Boot's own beans work. It lists its `@Configuration` classes explicitly in a file rather than scanning the whole classpath, so startup stays fast.
- For native images, Spring Boot's build-time processing (AOT) generates registration code, so it doesn't need to scan at runtime.

---

## 3. Injecting them: what every stereotype shares

All of these are beans, so they get dependencies through the container (see your `@Autowired` note).

```java
@Component
public class OrderService {
    private final PaymentService payment;            // final: set once
    public OrderService(PaymentService payment) {   // constructor injection
        this.payment = payment;
    }
}
```

Constructor injection is the preferred style:

- Fields can be `final`.
- A missing dependency fails the app at startup, not on first use.
- You can create the object in a test with `new OrderService(mockPayment)`, with no Spring needed.
- It exposes circular dependencies instead of hiding them. (Boot rejects circular references by default.)

**Which constructor does Spring use?**

- **One constructor:** Spring uses it, and `@Autowired` is optional (since Spring 4.3).
- **Several constructors, one marked `@Autowired`:** that one.
- **Several, none marked:** the no-argument constructor, and it fails if there isn't one. This can silently ignore the constructor you wanted, so mark it.

**Two beans of the same type?**

```java
@Component @Primary
public class StripePayment implements Payment { }     // the default winner

@Component
public class PaypalPayment implements Payment { }

public OrderService(@Qualifier("paypalPayment") Payment p) { ... }   // pick by name
```

You can also inject `List<Payment>` (all of them, ordered by `@Order`) or `Map<String, Payment>` (keyed by bean name).

For settings, use `@ConfigurationProperties` rather than many `@Value` fields (your `@ConfigurationProperties` note).

---

## 4. `@Service`: where business logic lives

```java
@Service
public class OrderService {

    private final OrderRepository orders;

    public OrderService(OrderRepository orders) { this.orders = orders; }

    @Transactional
    public OrderDto place(CreateOrderRequest request) {
        // validate rules, calculate, coordinate several repository calls
        Order saved = orders.save(new Order(request.customerId(), request.total()));
        return new OrderDto(saved.getId(), saved.getTotal());
    }
}
```

A service sits between the controller (HTTP) and the repository (database). It owns:

- **Business rules**: validation beyond field checks, calculations, decisions.
- **Transactions**: `@Transactional` goes here, so several repository calls succeed or fail together. It is proxy-based, so the self-call rule from your AOP note applies.
- **Mapping to DTOs**, inside the transaction, so controllers never touch entities.
- **Throwing domain exceptions** (such as `UserNotFoundException`) that your `@RestControllerAdvice` turns into HTTP responses.

Good habits:

- **Keep services stateless.** The default scope is **singleton**, one instance shared by every request. A field holding per-request data would be shared between users. (`@Scope("prototype")` gives a new instance on each injection, not "per request", so it isn't the fix for state.)
- **One service per domain** (`UserService`, `OrderService`), and split a service that grows huge.
- **Test it without Spring.** Because of constructor injection, plain Mockito is enough and is much faster than `@SpringBootTest`:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock UserRepository repo;
    @InjectMocks UserService service;

    @Test
    void returnsTheUser() {
        when(repo.findById(1L)).thenReturn(Optional.of(new User(1L, "John")));
        assertEquals("John", service.getUser(1L).name());
    }
}
```

(If you do need a Spring test with a mock bean, newer Spring versions replace `@MockBean` with `@MockitoBean`.)

---

## 5. `@Controller` and `@RestController`: the web layer

The difference is what the **return value means**.

||`@Controller`|`@RestController`|
|---|---|---|
|Return value is|A **view name** (or `redirect:/...`)|The **response body** itself|
|Is|Plain stereotype for MVC|`@Controller` + `@ResponseBody`|
|Typical returns|`String`, `ModelAndView`|DTOs, `ResponseEntity<T>`, `List<T>`|
|Request body|`@ModelAttribute` (form data)|`@RequestBody` (JSON)|
|Pairs with|Thymeleaf templates in `src/main/resources/templates/`|An Angular/React front end or any HTTP client|

```java
@Controller
public class BookViewController {
    @GetMapping("/books")
    public String list(Model model) {
        model.addAttribute("books", bookService.findAll());
        return "books";                       // → templates/books.html
    }
}

@RestController
@RequestMapping("/api/books")
public class BookController {
    @GetMapping
    public List<BookDto> list() { return bookService.findAll(); }   // → JSON
}
```

Key facts:

- `@ResponseBody` is what changes the meaning. Without it, a returned `String` goes to a **`ViewResolver`**. With it, Spring serializes the value (Jackson, for JSON) straight into the response. You can apply it per method, but mixing styles in one class is rare.
- `Model` and `ModelAndView` carry data into a template. `ResponseEntity` only makes sense when you build a response body, so it belongs in `@RestController` methods.
- `redirect:` is a `@Controller`-only instruction. It underlies the **Post-Redirect-Get** pattern, so refreshing after a form submit doesn't resubmit it.
- For a Spring Boot API with an Angular front end, you'll use `@RestController` almost always. `@Controller` with Thymeleaf suits server-rendered sites such as admin tools and SEO-heavy pages.

---

## 6. `@Repository` and Spring Data

`@Repository` marks the data-access layer, and it adds one real behavior: **exception translation**. A post-processor wraps your `@Repository` bean in a proxy that catches technology-specific errors (`SQLException`, Hibernate's `ConstraintViolationException`) and rethrows them as Spring's unified `DataAccessException` family. Your service can then handle one exception type, whichever persistence technology sits underneath.

### With Spring Data you rarely write it

```java
public interface UserRepository extends JpaRepository<User, Long> {

    List<User> findByLastName(String lastName);                       // derived query

    @Query("SELECT u FROM User u WHERE u.email = :email")
    Optional<User> findByEmail(@Param("email") String email);          // your own JPQL
}
```

- A repository **interface** needs no `@Repository`. Spring Data finds it through repository scanning, builds a proxy for it (your Spring Data proxy note), and handles exception translation itself.
- Use `@Repository` yourself only on a **hand-written class** that uses `EntityManager` or `JdbcTemplate` directly.
- `findByLastName` is a **derived query**: Spring parses the method name at startup. A misspelled property stops the app at startup. For anything complex, use `@Query`.

### Which interface to extend

|Interface|Gives you|
|---|---|
|`CrudRepository`|Basic create, read, update, delete|
|`PagingAndSortingRepository`|Paging and sorting (in current Spring Data it no longer extends `CrudRepository`)|
|`JpaRepository`|Everything above (CRUD, paging, sorting) plus JPA extras such as `flush` and batch deletes|

`JpaRepository` is the usual choice. For paging:

```java
Pageable pageable = PageRequest.of(page, size, Sort.by("lastName"));
Page<User> result = userRepository.findAll(pageable);
```

### The entity and the setup

```java
@Entity
@Table(name = "users")                                  // "user" is reserved in PostgreSQL
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String firstName, lastName, email;
}
```

Let the database generate the ID with `@GeneratedValue`. The starter you need is `spring-boot-starter-data-jpa`, plus your database driver. For PostgreSQL configuration, see your PostgreSQL config note, and keep `ddl-auto=update` to local learning only.

### Testing a repository

```java
@DataJpaTest
class UserRepositoryTest {
    @Autowired UserRepository repo;

    @Test
    void findsByLastName() {
        repo.save(new User("John", "Doe", "john@example.com"));
        assertFalse(repo.findByLastName("Doe").isEmpty());
    }
}
```

`@DataJpaTest` starts only the JPA parts, with an in-memory database by default. H2 behaves differently from PostgreSQL, so for queries that matter, run the test against a real PostgreSQL with Testcontainers.

---

## 7. How the layers fit together

```text
Client → @RestController → @Service → @Repository → Database
          (HTTP)            (rules,     (data access)
                             transactions)
```

Rules that keep this working:

- **A controller never calls a repository directly.** Spring doesn't enforce this, so your discipline does.
- **DTOs at the boundary**, not entities (your Entity/DTO/mapper note).
- **Transactions at the service level.** Repositories read and write.
- **Errors are thrown in the service** and **mapped to HTTP** in one `@RestControllerAdvice`.

A typical layout, either by layer or by feature:

```text
by layer:                          by feature (scales better):
controller/  service/  repository/ user/  UserController, UserService, UserRepository
model/  dto/  exception/           order/ OrderController, OrderService, OrderRepository
```

---

## 8. `@Component` or `@Bean`?

|You are making...|Use|
|---|---|
|Your own class with ordinary construction|A stereotype (`@Component`, `@Service`, ...)|
|A third-party class you can't annotate|`@Bean` in a `@Configuration` class|
|Several differently configured instances, or conditional creation|`@Bean`|
|A Boot starter or shared library|`@Configuration` + `@Bean` + `@ConditionalOnMissingBean`|

One trap: a `@Bean` method inside a plain `@Component` runs in **lite mode**, so calling `a()` from another `@Bean` method creates a **second, unmanaged** `A`. Use a `@Configuration` class for `@Bean` methods.

---

## 9. Proxy behavior that affects every stereotype

Annotations such as `@Transactional`, `@Async`, `@Cacheable` and `@PreAuthorize` work by wrapping the bean in a proxy (your AOP note).

```java
@Service
public class OrderService {
    public void outer() { inner(); }    // calls this.inner(): skips the proxy
    @Transactional
    public void inner() { ... }               // NO transaction starts
}
```

Fix it by moving `inner()` to another bean and injecting that. Also:

- **JDK versus CGLIB.** A JDK proxy implements your interface only, so injecting the concrete class fails. Spring Boot defaults to CGLIB, which avoids this.
- **`@Lazy`** delays creating a bean until first use. It speeds up startup, but it hides errors until runtime.
- **Request and session scopes** need `proxyMode = ScopedProxyMode.TARGET_CLASS` when injected into a singleton, so Spring injects a proxy that looks up the real bean on each call.

---

## 10. Mistakes to avoid

- A class outside the scanned package tree, so it is silently ignored.
- Field injection (`@Autowired` on a field): it hides dependencies and makes tests need Spring.
- Business logic in controllers, or controllers calling repositories.
- Stateful singleton services.
- `@Transactional` on a method called through `this`.
- Returning entities from controllers.
- Using `@Service` on everything, or `@Component` where a clearer stereotype exists.

---

## Related concept in short

**Custom stereotypes.** Because the scan follows meta-annotations, you can define your own label:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Service
public @interface DomainService { }
```

Anything annotated `@DomainService` is a `@Service`, and therefore a `@Component`, so it's scanned and becomes a bean. This is exactly how `@RestController` is built.



[[Spring Framework]]