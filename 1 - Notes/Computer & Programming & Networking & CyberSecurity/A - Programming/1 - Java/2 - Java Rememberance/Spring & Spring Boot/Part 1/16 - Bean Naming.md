
## Mental Model First

Every bean lives in that `Map<String, Object>` we talked about back when we discussed the IoC container internals — and just like any `Map`, it needs a **key**. Bean naming is simply: _what string does Spring use as the key for this particular bean in that map?_ Everything else — defaults, overrides, aliases — is just different ways of controlling that one string.

---

## Part 1: Default Naming Rules

### For `@Component` (and its specializations: `@Service`, `@Repository`, `@Controller`, `@RestController`)

The default bean name is the **class name with the first letter lowercased** (technically: standard Java Beans decapitalization, via `java.beans.Introspector.decapitalize()`):

```java
@Service
public class UserService { }
// bean name: "userService"

@Repository
public class OrderRepository { }
// bean name: "orderRepository"
```

### The acronym edge case — a genuine gotcha

```java
@Component
public class URLParser { }
// bean name: "URLParser"  — NOT "uRLParser"!
```

`Introspector.decapitalize()` has a special rule: **if the first two characters are both uppercase, the name is left unchanged.** This mirrors a long-standing Java Beans convention (so `URLParser.getURL()` doesn't turn into an awkward `uRLParser.getURL()` when treated as a property). This trips people up because it looks inconsistent at first glance — it isn't; it's a documented rule, just not one people expect until they hit it.

```java
@Component
public class DBConnection { }
// bean name: "DBConnection" — first two chars "DB" both uppercase → unchanged

@Component
public class DbConnection { }
// bean name: "dbConnection" — only first char uppercase → normal decapitalization
```

### For `@Bean` methods

The default bean name is simply the **method name, unchanged**:

```java
@Configuration
public class AppConfig {

    @Bean
    public RestTemplate restTemplate() { ... }
    // bean name: "restTemplate"

    @Bean
    public ObjectMapper objectMapper() { ... }
    // bean name: "objectMapper"
}
```

No decapitalization logic needed here — the method name is already whatever you wrote.

---

## Part 2: Manually Overriding the Name

### On `@Component` / `@Service` / `@Repository` / etc. — pass a value

```java
@Service("userServiceV2")
public class UserService { }
// bean name: "userServiceV2", NOT "userService"
```

This is literally just the `value` attribute of `@Component` (all the stereotype annotations are meta-annotated with `@Component` and inherit this):

```java
public @interface Service {
    @AliasFor(annotation = Component.class)
    String value() default "";
}
```

### On `@Bean` methods — pass `name` (or the shorthand `value`)

```java
@Bean(name = "primaryRestTemplate")
public RestTemplate restTemplate() { ... }

// shorthand — identical effect, value maps to name
@Bean("primaryRestTemplate")
public RestTemplate restTemplate() { ... }
```

### Multiple names — aliases for the same bean

`@Bean` accepts an **array** of names, meaning one bean can be looked up under several keys:

```java
@Bean(name = {"userRepo", "userRepository", "primaryUserRepo"})
public UserRepository userRepository() { ... }
```

All three strings now resolve to the **same singleton instance** — this is Spring's `alias` mechanism. It matters when you're injecting by name (via `@Qualifier`) from different parts of a large codebase that historically used different naming conventions, and you don't want to break existing references while renaming.

---

## Part 3: Using the Name — Where It Actually Matters

Naming is invisible most of the time because `@Autowired` resolves **by type**, not by name — as we covered when discussing how `@Autowired` picks a bean. The name only becomes relevant in two situations:

### 1. Ambiguity — multiple beans of the same type

```java
public interface PaymentGateway { }

@Service("stripeGateway")
public class StripePaymentGateway implements PaymentGateway { }

@Service("paypalGateway")
public class PaypalPaymentGateway implements PaymentGateway { }
```

```java
@Service
public class OrderService {
    private final PaymentGateway paymentGateway;

    public OrderService(@Qualifier("stripeGateway") PaymentGateway paymentGateway) {
        this.paymentGateway = paymentGateway;
    }
}
```

`@Qualifier`'s string argument is matched against the **bean name** (or against `@Qualifier` values you've explicitly attached elsewhere — see below). This is the exact scenario we set up earlier with `@Primary`/`@Qualifier` — now you can see precisely _what string_ `@Qualifier("stripeGateway")` is actually matching against: the bean's registered name in that internal map.

### 2. Manual lookup

```java
UserService service = context.getBean("userService", UserService.class);
```

Rare in application code (you'd normally let DI handle this), but common in tests or low-level framework code.

---

## Part 4: `@Qualifier` as a Named Annotation — a cleaner alternative to string matching

String-based `@Qualifier("stripeGateway")` has a weakness: it's a **magic string** — no compile-time safety, easy to typo, refactoring tools won't catch a rename. Spring offers a more "OOP-correct" alternative: **custom qualifier annotations**, which ties back to the abstraction/polymorphism discussion from before — you're creating a small, typed contract instead of a stringly-typed one.

```java
@Qualifier
@Retention(RetentionPolicy.RUNTIME)
public @interface Stripe { }

@Qualifier
@Retention(RetentionPolicy.RUNTIME)
public @interface Paypal { }
```

```java
@Service
@Stripe
public class StripePaymentGateway implements PaymentGateway { }

@Service
@Paypal
public class PaypalPaymentGateway implements PaymentGateway { }
```

```java
@Service
public class OrderService {
    public OrderService(@Stripe PaymentGateway paymentGateway) { ... }
    // compiler-checked, refactor-safe — the IDE understands @Stripe as a real type
}
```

This is a meaningfully "more advanced OOP" solution than raw string qualifiers, because it turns an implicit string contract into an explicit type-level contract — closer in spirit to the `Shape`/`Circle`/`Square` interface-driven polymorphism from before than to name-based lookup.

---

## Part 5: Name Collisions — what actually happens

If two beans in the **same context** end up with the same name (e.g., two `@Component` classes both explicitly named `"userService"`, or a `@Component` class colliding with a `@Bean` method name), Spring's default behavior is:

```
BeanDefinitionStoreException: Annotation-specified bean name 'userService' for bean class
[com.example.UserServiceV2] conflicts with existing, non-compatible bean definition
```

Fails fast at startup — same philosophy as the circular dependency detection we covered: **surface the ambiguity loudly and early**, rather than silently letting one bean overwrite the other. (There are edge cases where `@Bean` overriding is explicitly allowed via `spring.main.allow-bean-definition-overriding=true`, but this is off by default precisely because silent overriding is a common source of very confusing bugs.)

---

## Part 6: Advanced — Customizing the Naming _Strategy_ Itself

Everything above changes names **per-bean**. For genuinely large codebases, you can instead override **how Spring generates default names globally**, by supplying a custom `BeanNameGenerator`:

```java
public class PrefixedBeanNameGenerator extends AnnotationBeanNameGenerator {

    @Override
    public String generateBeanName(BeanDefinition definition, BeanDefinitionRegistry registry) {
        String defaultName = super.generateBeanName(definition, registry);
        return "app_" + defaultName; // every scanned bean gets an "app_" prefix
    }
}
```

```java
@Configuration
@ComponentScan(basePackages = "com.example", nameGenerator = PrefixedBeanNameGenerator.class)
public class AppConfig { }
```

This is rarely needed in normal projects — it's the kind of thing you'd reach for in a large multi-module enterprise system where naming collisions across modules are a real operational risk, and you want a systematic, enforced convention rather than relying on developers remembering to add unique `@Service("...")` values by hand.

---

## Nuance: `FactoryBean` naming — the `&` prefix

One genuinely obscure but important edge case, connecting back to the Factory pattern we discussed earlier. If a bean implements `FactoryBean<T>` (a bean whose _job_ is to produce another bean, rather than being the useful object itself — common in library integration code), the name resolves to **the product**, not the factory, by default:

```java
@Component
public class MyServiceFactoryBean implements FactoryBean<MyService> {
    @Override
    public MyService getObject() { return new MyService(); }
    @Override
    public Class<?> getObjectType() { return MyService.class; }
}
```

```java
context.getBean("myServiceFactoryBean");        // returns the MyService instance (the PRODUCT)
context.getBean("&myServiceFactoryBean");        // returns the FactoryBean itself (rare — for inspecting the factory)
```

The `&` prefix is how you explicitly ask for the factory object rather than what it produces — you'll see this occasionally in framework-integration code (e.g., some ORM or messaging library setup), essentially never in typical application code.

---

## Quick Reference

|Bean source|Default name|Override syntax|
|---|---|---|
|`@Component`/`@Service`/`@Repository`/`@Controller`|Class name, decapitalized|`@Service("customName")`|
|`@Bean` method|Method name|`@Bean("customName")` or `@Bean(name = {"a","b"})`|
|Two-letter-acronym class (`URLParser`)|Unchanged (`"URLParser"`)|Same as above|
|Used for resolution when|Type is ambiguous|`@Qualifier("customName")` or a custom `@Qualifier`-meta-annotated annotation|

---

## One Question to Test Understanding

You have this setup:

```java
public interface MessageFormatter { }

@Component("jsonFormatter")
public class JSONFormatter implements MessageFormatter { }

@Component
public class XMLFormatter implements MessageFormatter { }
```

Two questions in one: **(a)** what is the default bean name Spring would generate for `XMLFormatter`, and why — trace it through the exact rule from Part 1? **(b)** If you now inject `@Autowired MessageFormatter formatter` with no `@Qualifier` anywhere into a third bean, what happens at startup, and why does explicitly naming `JSONFormatter` (via `@Component("jsonFormatter")`) _not_ prevent this problem?


[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]