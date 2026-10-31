

`@Autowired` is the annotation that tells Spring: "I need an object of this type here. Find the matching bean in your container and hand it to me." You don't create the object with `new`, and you don't look it up yourself. Spring does the finding and the handing over, and this is the everyday form of **dependency injection**.

The word "wiring" means connecting one bean to another. "Auto" means Spring does the connecting for you, based on **type**. So when you write `@Autowired` above a field, constructor, or setter, you are saying: "Wire this to whatever bean matches my type." Once you understand how Spring picks the match, and what goes wrong when it can't, you'll understand most injection errors you'll ever see.

---

## A first look

```java
@Repository
public class UserRepository { }

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;
}
```

Line by line:

1. `UserRepository` is a bean, because of `@Repository`. Spring creates it at startup.
2. `UserService` is also a bean, because of `@Service`.
3. `@Autowired` on the field says: "Fill this field with a bean of type `UserRepository`."
4. After Spring creates `UserService`, it looks in its container, finds the one `UserRepository` bean, and sets the field.

You never wrote `new UserRepository()`. That's the point.

---

## The three places you can put it

You can put `@Autowired` in three places. They all work, but they are not equally good.

### 1. On a constructor (the best choice)

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

Spring calls this constructor and passes in the bean. **Since Spring 4.3, if a class has only one constructor, you can leave off `@Autowired` completely** and Spring still injects it:

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {   // no annotation needed
        this.userRepository = userRepository;
    }
}
```

This is also what your Lombok `@AllArgsConstructor` or `@RequiredArgsConstructor` classes rely on. Lombok writes the constructor, and Spring injects through it.

### 2. On a field (short, but weaker)

```java
@Autowired
private UserRepository userRepository;
```

Quick to type, but it has problems we'll cover below.

### 3. On a setter

```java
private UserRepository userRepository;

@Autowired
public void setUserRepository(UserRepository userRepository) {
    this.userRepository = userRepository;
}
```

Spring calls the setter after creating the object. This is useful for **optional** dependencies that can be changed later.

---

## Why constructor injection wins

||Constructor|Field|Setter|
|---|---|---|---|
|Can the field be `final`?|Yes|No|No|
|Object is always fully built?|Yes|No (fields are filled afterward)|No|
|Easy to test without Spring?|Yes: `new UserService(mockRepo)`|Hard: needs reflection or Spring|Yes|
|Shows all dependencies clearly?|Yes, in one place|Hidden among fields|Spread across setters|
|Detects circular dependencies early?|Yes, fails at startup|Hides them|Hides them|

With field injection, you can't write `new UserService(...)` in a plain unit test, because there's no constructor that accepts the repository. You'd have to use Spring or reflection tricks. With constructor injection, a test is one line. This is why the Spring team recommends constructor injection for required dependencies.

---

## How Spring chooses the bean (the part that matters most)

Spring picks by this order:

1. **By type.** It finds all beans assignable to the requested type.
2. **If exactly one matches**, it uses it. Done.
3. **If several match**, it narrows down using `@Primary`, then `@Qualifier`, then, as a last step, it compares the **field or parameter name** with the bean name.
4. **If none match**, it throws an error (unless the dependency is optional).

### Zero matches

```
NoSuchBeanDefinitionException: No qualifying bean of type 'UserRepository'
```

Usually means the class isn't a bean: you forgot `@Component`/`@Repository`, or it's outside the scanned package.

### Two or more matches

```java
public interface PaymentService { }

@Service class CardPaymentService implements PaymentService { }
@Service class PaypalPaymentService implements PaymentService { }

@Service
class OrderService {
    @Autowired
    private PaymentService paymentService;   // which one?
}
```

Spring sees two `PaymentService` beans and fails with `NoUniqueBeanDefinitionException`. You have three fixes.

**Fix 1: `@Primary` on the default one**

```java
@Service
@Primary
class CardPaymentService implements PaymentService { }
```

**Fix 2: `@Qualifier` at the injection point**

```java
@Autowired
@Qualifier("paypalPaymentService")
private PaymentService paymentService;
```

**Fix 3: match the name.** If the field is named `cardPaymentService`, Spring falls back to matching the bean name `cardPaymentService`. It works, but it is fragile because renaming a variable changes behavior.

---

## Injecting many beans at once

If you ask for a collection, Spring gives you **all** matching beans:

```java
@Autowired
private List<PaymentService> allServices;     // both card and paypal

@Autowired
private Map<String, PaymentService> byName;   // key = bean name
```

This is handy for strategy patterns: loop over all implementations and pick the right one.

---

## Optional dependencies

By default, `@Autowired` is **required**. If no bean exists, startup fails. You can relax that in three ways:

```java
@Autowired(required = false)
private AuditService auditService;        // stays null if missing

@Autowired
private Optional<AuditService> auditService;   // empty Optional if missing

@Autowired
public void setAuditService(@Nullable AuditService auditService) { ... }
```

`Optional<T>` is usually the cleanest because it forces you to handle the "missing" case in code.

---

## Circular dependencies

```java
@Service
class A { A(B b) { } }

@Service
class B { B(A a) { } }
```

Spring can't create `A` without `B`, or `B` without `A`. With constructor injection it fails at startup with a `BeanCurrentlyInCreationException`. That is a _good_ failure, because it tells you your design has a loop. Since Spring Boot 2.6, circular references are forbidden by default. You can fix it by breaking the loop (move shared logic to a third bean), or as a last resort, add `@Lazy` on one parameter.

---

## What `@Autowired` actually is behind the scenes

The annotation itself does nothing. A Spring component called **`AutowiredAnnotationBeanPostProcessor`** scans each bean as it's being created, finds the `@Autowired` spots, and does the injection. This ties directly to the bean lifecycle you've been learning: injection happens **after the constructor runs** (for fields and setters) and **before** `@PostConstruct` callbacks.

---

## Related concept in short: `@Resource` and `@Inject`

Two other annotations do a similar job:

- **`@Inject`** (Jakarta Inject, from the Jakarta EE family you just learned about) is the standard version of `@Autowired`. It also matches by type, and Spring supports it if the `jakarta.inject` library is on the classpath. It has no `required` flag.
- **`@Resource`** (Jakarta Annotations) matches by **name first**, then falls back to type.

In a Spring Boot project, `@Autowired` or plain constructor injection is the norm.

---

## Takeaways

- `@Autowired` asks Spring to inject a bean, matched by **type**.
- Prefer **constructor injection**. With a single constructor, `@Autowired` is optional.
- Field injection is short but hides dependencies and makes testing harder.
- Several matches? Use `@Primary` or `@Qualifier`. No match? The class isn't a bean, or you can make the dependency optional.
- Ask for a `List` or `Map` to receive all matching beans.
- A `BeanPostProcessor` does the work, which links back to the bean lifecycle.





[[Spring Framework]]