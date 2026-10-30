
# Contexts and Dependency Injection

CDI is the Jakarta EE specification that creates your objects, wires them together, and manages how long they live. You declare what a class needs, and the container hands it over. You never write `new` for your services. If you have used Spring's IoC container, CDI is the same idea, written as a standard that any Jakarta runtime must follow.

The name has two halves, and both matter. **Dependency Injection** is the part you already know: the container fills in the objects your class needs. **Contexts** is the part that makes CDI special: every object lives inside a _context_ (a request, a session, the whole application), and the container creates it when that context starts and throws it away when the context ends. So CDI manages both _who gets what_ and _how long it lives_. On top of that, CDI adds events, interceptors, and decorators, so it works as the backbone of the whole Jakarta EE platform.

---

## 1. The core vocabulary

|Term|Meaning|
|---|---|
|**Bean**|An object the container creates and manages (like a Spring bean)|
|**Injection point**|A place where you ask for a bean: a field, constructor, or method marked `@Inject`|
|**Scope**|How long a bean lives and who shares it|
|**Qualifier**|A label that picks one bean when several match|
|**Producer**|A method that builds a bean for you|
|**Contextual instance**|The actual object living in a given context|

---

## 2. Your first bean

```java
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class GreetingService {
    public String greet(String name) {
        return "Hello, " + name;
    }
}
```

```java
import jakarta.inject.Inject;

@Path("/hello")
public class HelloResource {

    private final GreetingService service;

    @Inject
    public HelloResource(GreetingService service) {
        this.service = service;
    }

    @GET
    public String hello() {
        return service.greet("Ana");
    }
}
```

Line by line:

1. `@ApplicationScoped` on `GreetingService` does two jobs. It tells CDI "this class is a bean", and it says "keep one instance for the whole application".
2. In `HelloResource`, the constructor is marked `@Inject`. CDI looks at the parameter type, finds a bean of type `GreetingService`, and passes it in.
3. You never call `new GreetingService()`. That is the whole point: your class depends on the type, not on how it is built.

You can also inject into a field (`@Inject GreetingService service;`) or a setter method. **Constructor injection** is the best choice, the same advice as in Spring, because the dependency is clear and can be `final`.

---

## 3. Bean discovery: how CDI finds your beans

CDI has to scan your code to find beans. In modern CDI, the default is `annotated` mode: a class becomes a bean only if it has a **bean-defining annotation**, such as a scope annotation (`@ApplicationScoped`, `@RequestScoped`, and so on).

You enable scanning for a module with a file called `beans.xml`:

```xml
<beans xmlns="https://jakarta.ee/xml/ns/jakartaee" version="4.0"
       bean-discovery-mode="annotated"/>
```

It goes in `META-INF/` (or `WEB-INF/` in a web app). In many runtimes, an empty file or even no file works, but keeping it makes your intent clear. A plain class with no scope annotation, in `annotated` mode, is **not** a bean.

---

## 4. Scopes: the "Contexts" part

This is the part to learn well, because it behaves differently from Spring.

|Scope|Lives for|Shared by|Spring cousin|
|---|---|---|---|
|`@ApplicationScoped`|The whole application|Everyone|`singleton`|
|`@SessionScoped`|One HTTP session|One user|`session`|
|`@RequestScoped`|One HTTP request|One request|`request`|
|`@ConversationScoped`|A span you start and end yourself|One user's multi-step flow|(no direct match)|
|`@Dependent`|The life of whoever injects it|Only its owner|`prototype` (roughly)|

### The default scope is `@Dependent`

If you give a bean no scope, it is `@Dependent`. That means: every injection point gets its **own new instance**, and it dies when its owner dies. In Spring, the default is a singleton. This difference surprises many people, so remember it.

### Normal scopes and client proxies

`@ApplicationScoped`, `@SessionScoped`, `@RequestScoped`, and `@ConversationScoped` are called **normal scopes**. For these, CDI does not inject the real object. It injects a **client proxy**, a thin stand-in.

Why? Imagine an `@ApplicationScoped` bean that holds a `@RequestScoped` bean. The application bean lives forever, but each request needs a _different_ request bean. With a proxy, every method call goes through the proxy, and the proxy looks up the right instance for the _current_ request. So injecting a short-lived bean into a long-lived one just works.

Two rules follow from proxies:

- The class needs a **non-private no-argument constructor** (the proxy subclasses it). If you use constructor injection, add a package-private or protected no-arg constructor as well.
- The class and its methods cannot be `final`.

`@Dependent` beans have no proxy, so these rules do not apply to them.

---

## 5. Qualifiers: choosing between several beans

What if two beans share the same type?

```java
public interface PaymentProcessor {
    void pay(int cents);
}
```

```java
@ApplicationScoped
public class CardProcessor implements PaymentProcessor { /* ... */ }

@ApplicationScoped
public class PaypalProcessor implements PaymentProcessor { /* ... */ }
```

If you write `@Inject PaymentProcessor p;`, CDI fails at startup with an **ambiguous dependency** error. It is a _deployment-time_ error, so you find out before the app runs. To fix it, create your own qualifier:

```java
import jakarta.inject.Qualifier;
import java.lang.annotation.*;

@Qualifier
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.FIELD, ElementType.METHOD, ElementType.PARAMETER})
public @interface Paypal { }
```

```java
@Paypal
@ApplicationScoped
public class PaypalProcessor implements PaymentProcessor { /* ... */ }
```

```java
@Inject @Paypal
PaymentProcessor processor;
```

How it works: `@Qualifier` marks your annotation as a label. A bean carrying the label only matches injection points asking for that label. A bean with no qualifier gets the built-in `@Default` qualifier.

This is **type-safe**: a typo in the label is a compile error, not a silent string mismatch. Spring's `@Qualifier("paypal")` uses a string, so this is a real difference.

There is also `@Named("paypal")`, which uses a string. It exists mainly so a bean can be used by name in web pages (Expression Language, like `#{paypal}`). For normal injection, prefer your own qualifier annotation.

---

## 6. Producers: building beans that aren't plain classes

Sometimes you cannot just annotate a class, because it comes from a library, or it needs setup code. For that, use a **producer method**:

```java
import jakarta.enterprise.inject.Produces;

@ApplicationScoped
public class ClockProducer {

    @Produces
    @ApplicationScoped
    public java.time.Clock clock() {
        return java.time.Clock.systemUTC();
    }
}
```

Now anyone can write `@Inject Clock clock;`. The method's return type is the bean type, and the annotation on it is the scope.

If the object needs cleanup, add a **disposer**:

```java
public void close(@Disposes Connection conn) throws Exception {
    conn.close();
}
```

When the producing context ends, CDI calls this method with the object. This equals Spring's `@Bean` method with a destroy hook.

A producer can also **inject information about where it is being used**, via `InjectionPoint`:

```java
@Produces
public Logger logger(InjectionPoint ip) {
    return Logger.getLogger(ip.getMember().getDeclaringClass().getName());
}
```

Each class that asks for a `Logger` gets one named after itself. This is a neat trick that Spring does differently.

---

## 7. Lifecycle callbacks

Use the standard annotations:

```java
@ApplicationScoped
public class CacheService {

    @PostConstruct
    void init() { /* runs after injection is done */ }

    @PreDestroy
    void cleanup() { /* runs before the bean is removed */ }
}
```

These are the same `jakarta.annotation` callbacks you have seen in Spring. They run once the bean is fully wired, and once more when its context ends.

---

## 8. Events: beans that talk without knowing each other

CDI has a built-in publish/subscribe system. The sender and the receiver never reference each other.

**Fire an event:**

```java
@ApplicationScoped
public class OrderService {

    @Inject
    Event<OrderPlaced> events;

    public void place(Order order) {
        // save the order...
        events.fire(new OrderPlaced(order.id()));
    }
}
```

**Observe it:**

```java
@ApplicationScoped
public class EmailNotifier {

    void onOrder(@Observes OrderPlaced event) {
        // send a confirmation email
    }
}
```

- `Event<OrderPlaced>` is injected like any other bean.
- `fire(...)` sends the object to every method that has an `@Observes` parameter of that type.
- `OrderService` knows nothing about `EmailNotifier`. You can add a second observer (say, for analytics) without touching `OrderService`.

You can also use `fireAsync` and `@ObservesAsync` for asynchronous delivery. The Spring parallel is `ApplicationEventPublisher` with `@EventListener`.

---

## 9. Interceptors: wrapping methods with extra behavior

An interceptor runs code before and after a method. It is what you use for logging, timing, or security checks, and it is the CDI version of Spring AOP.

```java
@InterceptorBinding
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface Timed { }
```

```java
@Timed
@Interceptor
@Priority(Interceptor.Priority.APPLICATION)
public class TimingInterceptor {

    @AroundInvoke
    public Object measure(InvocationContext ctx) throws Exception {
        long start = System.nanoTime();
        try {
            return ctx.proceed();
        } finally {
            long ms = (System.nanoTime() - start) / 1_000_000;
            System.out.println(ctx.getMethod().getName() + " took " + ms + " ms");
        }
    }
}
```

```java
@ApplicationScoped
public class ReportService {
    @Timed
    public void build() { /* ... */ }
}
```

Walk through it:

1. `@InterceptorBinding` creates a label (`@Timed`) you can put on classes or methods.
2. `TimingInterceptor` is marked `@Timed` too, so it answers to that label. `@Interceptor` says "I am an interceptor", and `@Priority` turns it on and sets its order.
3. `@AroundInvoke` marks the method that wraps the call. `ctx.proceed()` runs the real method. Code before it runs first, code after it runs last.
4. Putting `@Timed` on `build()` means every call goes through the interceptor.

---

## 10. Smaller features worth knowing

|Feature|One-line meaning|
|---|---|
|**Decorators**|Like interceptors, but they wrap a specific _interface_ and understand business meaning|
|**Alternatives**|`@Alternative` beans are switched off until you enable them (good for test or mock versions)|
|**Stereotypes**|One custom annotation that bundles scope, qualifiers, and interceptors together|
|**`Instance<T>`**|Look up beans programmatically at runtime, and loop over all beans of a type|
|**Specializes / `@Vetoed`**|Replace a bean, or hide a class from CDI entirely|

`Instance<T>` is the one you will use most, so here is a quick look:

```java
@Inject
Instance<PaymentProcessor> processors;

for (PaymentProcessor p : processors) {
    // every PaymentProcessor bean in the app
}
```

---

## 11. CDI Lite and CDI Full

Since CDI 4, there are two flavors:

- **CDI Lite** has the core features: injection, scopes, qualifiers, producers, events, and **build-time extensions** (the work is done at build time, which helps Quarkus-style fast startup and native images).
- **CDI Full** adds everything else, such as portable runtime extensions, decorators, and conversation scope.

The Jakarta EE Core Profile uses Lite. Web Profile and Platform use Full.

---

## 12. CDI vs Spring at a glance

Since you know Spring well, this table is the fastest way to map the two.

|Idea|CDI|Spring|
|---|---|---|
|Inject|`@Inject`|`@Autowired`|
|Default scope|`@Dependent` (new each time)|Singleton|
|One shared instance|`@ApplicationScoped`|`@Component` / `@Service`|
|Pick one of many|Your own `@Qualifier` annotation|`@Qualifier("name")` / `@Primary`|
|Factory method|`@Produces`|`@Bean`|
|Events|`Event<T>` + `@Observes`|`ApplicationEventPublisher` + `@EventListener`|
|Method wrapping|Interceptors|Spring AOP|
|Container object|`BeanManager`|`ApplicationContext`|
|Unsatisfied or ambiguous|Fails at deployment|Fails at startup (similar)|

Note that Spring can also read `@Inject` and `@PostConstruct`, because those come from the standard `jakarta.inject` and `jakarta.annotation` packages.

---

## 13. Related concept: Jakarta Inject (JSR-330)

**Jakarta Inject** is a tiny specification with only a few annotations: `@Inject`, `@Qualifier`, `@Named`, `@Scope`, `@Singleton`, and `Provider<T>`. It defines just the basics of injection and nothing else. CDI builds on top of it and adds scopes with real lifecycles, events, interceptors, and producers. That is why `@Inject` lives in `jakarta.inject`, while `@ApplicationScoped` lives in `jakarta.enterprise.context`. Spring supports Jakarta Inject too, so code written with these annotations can move between the two.

---

## 14. Common mistakes

1. **Forgetting the scope.** A class with no scope annotation is not a bean in `annotated` mode.
2. **Assuming singleton.** The default is `@Dependent`, so you get a new instance each time.
3. **Ambiguous dependencies.** Two beans of one type and no qualifier will stop deployment.
4. **Proxy problems.** A `final` class or a missing no-arg constructor on a normally scoped bean fails at startup.
5. **Mixing annotations.** `@Singleton` (from Jakarta Inject) is _not_ the same as `@ApplicationScoped`. `@Singleton` has no proxy, so it is a plain shared instance without a client proxy.

---

## Summary

- CDI = injection plus _contexts_ that control a bean's lifetime.
- Scopes: `@ApplicationScoped`, `@SessionScoped`, `@RequestScoped`, `@ConversationScoped`, and the default `@Dependent`.
- Normal scopes inject a client proxy, which is why short-lived beans can sit inside long-lived ones.
- Qualifiers are type-safe annotations that pick between beans of the same type.
- Producers build beans you cannot annotate; events, interceptors, and decorators add behavior without tight coupling.
- Spring maps closely to it, with the biggest difference being the default scope.




[[Spring Framework]]