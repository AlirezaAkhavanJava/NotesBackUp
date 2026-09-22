
## Mental Model First

Lombok doesn't touch Spring at all — it operates entirely at **compile time**, generating boilerplate bytecode (constructors, getters, `equals`/`hashCode`, etc.) before Spring ever sees your classes. Think of Lombok as a **code generator that runs before the compiler finishes**, and Spring as a runtime that operates **after** compilation. They never talk to each other directly — Lombok just makes the constructor-injection pattern we've been advocating for this whole conversation much less verbose to write by hand.

This matters because it reframes a common beginner misconception: Lombok isn't "Spring-aware" — `@RequiredArgsConstructor` doesn't know what `@Autowired` is. It just generates a constructor. Spring's constructor-injection detection (which we covered back when discussing DI — "if there's exactly one constructor, use it automatically") is what actually wires it up. Lombok and Spring are two independent tools that happen to compose beautifully.

---

## Part 1: The Core DI-Relevant Lombok Annotations

### `@RequiredArgsConstructor` — the one you'll use constantly

```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;
}
```

This generates **exactly** the constructor we've been writing by hand this whole conversation:

```java
public UserService(UserRepository userRepository, EmailService emailService) {
    this.userRepository = userRepository;
    this.emailService = emailService;
}
```

Rule: it generates a constructor parameter for **every `final` field** (and any field marked `@NonNull`). Non-final fields are skipped. This is precisely why we established constructor injection as the default earlier — Lombok is essentially built around rewarding that exact pattern with the least boilerplate.

### `@NonNull` on a field — adds a null-check to the generated constructor

```java
@Service
@RequiredArgsConstructor
public class UserService {
    @NonNull
    private final UserRepository userRepository;
}
```

Generated constructor now includes:

```java
public UserService(UserRepository userRepository) {
    if (userRepository == null) {
        throw new NullPointerException("userRepository is marked non-null but is null");
    }
    this.userRepository = userRepository;
}
```

Useful as a fail-fast guard, though in practice, if Spring itself can't resolve a bean, you already get a startup-time exception before this check would ever fire — so this mostly protects against someone manually calling `new UserService(null)` in a test or elsewhere.

### `@AllArgsConstructor` / `@NoArgsConstructor` — used for entities and DTOs, not services

```java
@Entity
@NoArgsConstructor  // JPA requires a no-arg constructor — we mentioned this back when defining User entities
@AllArgsConstructor // convenience full constructor
public class User {
    @Id @GeneratedValue
    private Long id;
    private String name;
    private String email;
}
```

Recall from our entity discussion: JPA **requires** a protected/public no-arg constructor to instantiate entities via reflection when loading from the database. `@NoArgsConstructor` generates exactly that, saving you from writing `protected User() {}` by hand.

### `@Data` — convenient, but genuinely dangerous on JPA entities

```java
@Data // generates getters, setters, toString, equals, hashCode, + required-args constructor
public class UserDto {
    private Long id;
    private String name;
}
```

This is fine on a **DTO** — plain data holder, no relationships, no lazy loading. It is a well-known anti-pattern on **`@Entity`** classes, and this connects directly back to something we covered earlier:

```java
@Entity
@Data // ⚠️ DANGEROUS on an entity
public class User {
    @Id
    private Long id;

    @OneToMany(mappedBy = "user")
    private List<Order> orders; // lazy-loaded relationship
}
```

Why this is a real problem, not just style pedantry:

1. **`@Data`'s generated `equals`/`hashCode` uses all fields**, including `orders` — calling `equals()` can trigger a lazy-load of the entire collection, and worse, can cause infinite recursion if `Order` has a back-reference to `User` that's also included in `Order`'s own Lombok-generated `equals`
2. **`toString()` has the same problem** — logging a `User` object accidentally triggers a lazy DB fetch, or an infinite loop if there's a bidirectional relationship
3. We already established the correct pattern for JPA `equals`/`hashCode` — ID-only comparison, with `hashCode()` based on `getClass()`, not fields. `@Data` overrides this with all-fields logic, silently reintroducing the exact bug we discussed as an advanced gotcha.

**Senior-level rule:** never use `@Data` on `@Entity` classes. Use targeted annotations instead:

```java
@Entity
@Getter
@Setter
@NoArgsConstructor
@ToString(exclude = "orders")           // exclude lazy relationships explicitly
@EqualsAndHashCode(of = "id")           // ID-only equality — matches the correct pattern from before
public class User {
    @Id @GeneratedValue
    private Long id;

    @OneToMany(mappedBy = "user")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private List<Order> orders;
}
```

`@EqualsAndHashCode(of = "id")` is the Lombok-native way to express exactly the manual `equals`/`hashCode` pattern we wrote out by hand earlier in this conversation.

### `@Builder` — useful for DTOs and complex object construction, not injected beans

```java
@Builder
@Getter
public class CreateUserRequest {
    private final String name;
    private final String email;
}
```

```java
CreateUserRequest request = CreateUserRequest.builder()
    .name("Alireza")
    .email("a@example.com")
    .build();
```

Not related to DI directly, but very common alongside DTOs in the controller layer we discussed — useful when a DTO has many optional fields and you want named-parameter clarity instead of a long constructor argument list.

### `@Slf4j` — a small but very common one, worth knowing

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {
    private final UserRepository userRepository;

    public UserDto getUser(Long id) {
        log.info("Fetching user {}", id); // 'log' field is generated by Lombok
        ...
    }
}
```

Generates `private static final Logger log = LoggerFactory.getLogger(UserService.class);` — this has nothing to do with DI (it's a `static final` field, not an injected bean), but it's ubiquitous in the exact `@Service` classes we've been writing, so worth knowing it composes cleanly with everything else.

---

## Part 2: A Real, Senior-Level Class With All of This Combined

```java
@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = "user")
@EqualsAndHashCode(of = "id")
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private User user;

    private BigDecimal amount;
}
```

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final PaymentGateway paymentGateway; // recall: this could be @Primary/@Qualifier resolved

    @Transactional
    public OrderDto placeOrder(CreateOrderRequest request) {
        log.info("Placing order for amount {}", request.amount());
        Order order = new Order();
        order.setAmount(request.amount());
        Order saved = orderRepository.save(order);
        paymentGateway.charge(saved.getAmount());
        return toDto(saved);
    }

    private OrderDto toDto(Order order) {
        return new OrderDto(order.getId(), order.getAmount());
    }
}
```

Notice: **no `@Autowired` anywhere** — with a single Lombok-generated constructor, Spring 4.3+'s "exactly one constructor → auto-detect" rule kicks in automatically, exactly as covered before. This is the modern idiomatic style you'll see in essentially every senior Spring Boot codebase today.

---

## Part 3: Senior-Level Project Structure

There are two dominant philosophies here. I'll give you both, be explicit about the trade-off, and then give you a concrete recommended structure.

### Philosophy A: Package by Layer (traditional, what most tutorials teach)

```
com.example.orderapp
├── controller
│   ├── UserController.java
│   └── OrderController.java
├── service
│   ├── UserService.java
│   └── OrderService.java
├── repository
│   ├── UserRepository.java
│   └── OrderRepository.java
├── entity
│   ├── User.java
│   └── Order.java
└── dto
    ├── UserDto.java
    └── OrderDto.java
```

**Problem at scale:** everything related to "Order" is scattered across 5 different folders. Adding one feature means touching 5 different packages. In a large codebase, this becomes genuinely painful to navigate — you're constantly jumping folders to see one feature's full picture.

### Philosophy B: Package by Feature (what most senior/large-scale codebases actually use)

```
com.example.orderapp
├── user
│   ├── User.java                    (entity)
│   ├── UserController.java
│   ├── UserService.java
│   ├── UserRepository.java
│   ├── UserDto.java
│   └── UserNotFoundException.java
├── order
│   ├── Order.java
│   ├── OrderController.java
│   ├── OrderService.java
│   ├── OrderRepository.java
│   ├── OrderDto.java
│   └── CreateOrderRequest.java
├── payment
│   ├── PaymentGateway.java           (interface — the abstraction we discussed)
│   ├── StripePaymentGateway.java
│   └── PaypalPaymentGateway.java
├── common
│   ├── exception
│   │   └── GlobalExceptionHandler.java   (@RestControllerAdvice)
│   ├── config
│   │   ├── SecurityConfig.java
│   │   └── AopConfig.java
│   └── util
└── OrderAppApplication.java
```

**Why senior teams prefer this:** everything about "orders" lives in one place. You can often make a package-private class (not `public`) if it's only used within its own feature package — this actually **restores real encapsulation at the module level**, which ties back to something worth noting: package-by-layer tends to force everything `public` (since the controller in one package needs the service in another package), while package-by-feature lets you genuinely hide internal collaborators from other features.

```java
// inside order package — package-private, not accessible from user package
class OrderValidator {
    boolean isValid(Order order) { ... }
}
```

This is a subtle but real OOP-encapsulation benefit that's easy to miss until you've worked in a large package-by-layer codebase and watched encapsulation slowly erode because everything had to be `public` to cross layer-package boundaries.

### A more advanced structure: Hexagonal / Ports & Adapters (for genuinely complex domains)

For a senior/enterprise-scale project — especially one where business logic is complex and you want it fully decoupled from Spring/JPA/web concerns — the structure often looks like this:

```
com.example.orderapp
├── domain                          ← pure business logic, ZERO Spring/JPA annotations
│   ├── order
│   │   ├── Order.java               (plain Java class — not @Entity!)
│   │   ├── OrderService.java        (business rules, no @Service annotation)
│   │   └── OrderRepository.java     (interface — a "port")
│   └── payment
│       └── PaymentGateway.java      (interface — a "port")
│
├── application                     ← use-case orchestration
│   └── order
│       └── PlaceOrderUseCase.java
│
└── infrastructure                  ← "adapters" — where Spring/JPA/HTTP actually live
    ├── web
    │   └── OrderController.java     (@RestController)
    ├── persistence
    │   ├── OrderJpaEntity.java      (@Entity — separate from domain.Order!)
    │   ├── OrderRepositoryImpl.java (@Repository, implements domain's OrderRepository)
    │   └── OrderMapper.java         (maps between OrderJpaEntity ↔ domain.Order)
    └── payment
        └── StripePaymentGatewayImpl.java (@Service, implements domain's PaymentGateway)
```

**The core idea:** your actual business logic (`domain` package) has **no dependency on Spring or JPA at all** — it's plain Java, fully testable with zero framework, and the `PaymentGateway`/`OrderRepository` interfaces defined there are pure abstractions (exactly the Dependency Inversion pattern from before, taken to its logical extreme). The `infrastructure` layer depends on `domain`, never the other way around — Spring, JPA, and HTTP are treated as **implementation details plugged in from the outside**, not as the foundation everything else builds on.

**When to actually use this:** genuinely complex business domains (banking, insurance, logistics) where business rules are the valuable, long-lived core and the tech stack (maybe you swap JPA for something else in 5 years) is comparatively disposable. For most CRUD-heavy apps, **this is overkill** — package-by-feature (Philosophy B) is the pragmatic senior default; hexagonal is a deliberate, heavier investment you reach for when domain complexity genuinely justifies it.

---

## Recommended Structure for You Right Now

Given where you are in this journey, **package-by-feature** is the right level of sophistication to practice — it's genuinely what most professional teams use day-to-day, without the heavier ceremony of full hexagonal architecture:

```
com.example.orderapp
├── OrderAppApplication.java
├── user/
│   ├── User.java
│   ├── UserController.java
│   ├── UserService.java
│   ├── UserRepository.java
│   └── dto/
│       ├── UserDto.java
│       └── CreateUserRequest.java
├── order/
│   ├── Order.java
│   ├── OrderController.java
│   ├── OrderService.java
│   ├── OrderRepository.java
│   └── dto/
│       ├── OrderDto.java
│       └── CreateOrderRequest.java
├── payment/
│   ├── PaymentGateway.java
│   └── impl/
│       └── StripePaymentGateway.java
└── common/
    ├── exception/
    │   ├── GlobalExceptionHandler.java
    │   ├── ResourceNotFoundException.java
    │   └── ErrorResponse.java
    └── config/
        └── SecurityConfig.java
```

Every class in here uses `@RequiredArgsConstructor` for its dependencies, `@EqualsAndHashCode(of = "id")` on entities instead of `@Data`, and DTOs live as `record`s where possible (as we discussed under modern MVC) or `@Builder`-annotated classes when construction is more complex.

---

## One Question to Test Understanding

You refactor this entity to use `@Data` instead of the targeted `@Getter`/`@Setter`/`@EqualsAndHashCode(of = "id")` combination we recommended:

```java
@Entity
@Data
public class User {
    @Id @GeneratedValue
    private Long id;
    private String name;

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    private List<Order> orders;
}
```

A colleague calls `userRepository.findById(1L).get().toString()` in a log statement, in a context where the transaction/Hibernate session has **already closed** by the time this line runs. What specifically goes wrong at runtime, and why does it trace back to `@Data` generating a `toString()` that includes the `orders` field — connect it to the lazy-proxy discussion from earlier in this conversation?


[[Java]]
[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]