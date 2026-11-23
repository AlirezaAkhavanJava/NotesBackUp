
This is the nickname for **Inversion of Control (IoC)** — the idea that instead of your code deciding when to create objects and call methods on them, you hand control to a framework, and the framework calls _your_ code when it decides the time is right. Your code becomes a set of plug-in points rather than the thing driving the program. In Spring Boot, this principle is everywhere: it's not just "Spring creates your beans," it's a recurring pattern Spring uses anytime it needs to hand control back to you at a specific moment.

### The contrast that makes it click

In a normal, non-framework program, your code is in charge of the whole sequence:

```java
Connection conn = DriverManager.getConnection(url, user, pass);
PreparedStatement ps = conn.prepareStatement(sql);
ResultSet rs = ps.executeQuery();
while (rs.next()) {
    process(rs);
}
conn.close();
```

Every line here is _you_ calling a library method, in an order _you_ chose. The library (JDBC) never calls into your code — it just answers when asked. That's normal, non-inverted control: "call us" — you ring the library up.

The Hollywood Principle flips that relationship. Instead of your code calling the framework, the framework runs the overall flow, and it calls back into your code only when it reaches a point that needs your logic. You register (plug in) your code ahead of time, and then you wait — the framework will call you.

### Spring Boot as the "Hollywood" side

Think about what happens when your app starts up:

```java
@SpringBootApplication
public class MyApp {
    public static void main(String[] args) {
        SpringApplication.run(MyApp.class, args);
    }
}
```

You never write `new OrderService()`, `new OrderController()`, or wire them together by hand. You hand Spring the authority to scan, construct, and connect every bean. From that point forward, _Spring_ is in charge of the sequence of events: it decides when your beans get built, when they get wired, and when they get destroyed. You only supply the pieces — the classes, the annotations describing how they should be treated — and Spring calls them at the right moment.

This shows up concretely in a few recurring Spring mechanisms, all expressions of the same principle:

**1. Bean creation and injection**

```java
@Service
public class OrderService {

    private final PaymentGateway paymentGateway;

    public OrderService(PaymentGateway paymentGateway) {
        this.paymentGateway = paymentGateway;
    }
}
```

You never call `new PaymentGateway()` inside `OrderService`, and you never call `new OrderService(...)` anywhere in your own code either. You just declare the dependency through the constructor. Spring's container calls _this_ constructor for you, at a time of its choosing (during context startup), supplying the `PaymentGateway` bean it already built. `OrderService` doesn't request or fetch anything — it just waits to be constructed.

**2. Lifecycle callback interfaces**

Spring gives you several interfaces whose entire purpose is "implement this method, and we'll call it for you at the right stage of the bean's life":

```java
@Component
public class CacheWarmer implements InitializingBean {

    @Override
    public void afterPropertiesSet() {
        // runs automatically once Spring finishes setting this bean's properties
        warmCache();
    }
}
```

You never call `afterPropertiesSet()` yourself. Spring's container calls it, once, right after it finishes populating the bean's dependencies. The method name is even a tell: it's a callback, not an API you invoke.

**3. Event listeners**

```java
@Component
public class OrderPlacedListener {

    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        sendConfirmationEmail(event.getOrderId());
    }
}
```

You register interest by writing the method and annotating it. Somewhere else entirely, a totally different piece of code publishes an `OrderPlacedEvent`:

```java
applicationEventPublisher.publishEvent(new OrderPlacedEvent(orderId));
```

The publisher doesn't know `OrderPlacedListener` exists, and `OrderPlacedListener` doesn't know who publishes the event. Spring's `ApplicationEventPublisher` is the "Hollywood studio" sitting in the middle — it calls your listener when the right event shows up. Neither side calls the other directly.

**4. The Template Method pattern (`JdbcTemplate`, `RestTemplate`, etc.)**

This is the same principle at a smaller, single-call scale. Compare it to the raw JDBC loop above:

```java
jdbcTemplate.query(
    "SELECT id, name FROM customers",
    (rs, rowNum) -> new Customer(rs.getLong("id"), rs.getString("name"))
);
```

`JdbcTemplate` owns the entire sequence — opening the connection, creating the statement, running the query, looping over the `ResultSet`, closing everything, handling exceptions. You only supply the one piece of logic it can't know in advance: how to turn a row into a `Customer`. It calls your lambda, once per row, exactly when it needs that logic. You never touch `ResultSet.next()` or `Connection.close()` — Spring calls you back for the one part that's yours.

**5. `@Controller` methods in Spring MVC**

```java
@RestController
public class OrderController {

    @GetMapping("/orders/{id}")
    public Order getOrder(@PathVariable Long id) {
        return orderService.findById(id);
    }
}
```

You don't call `getOrder(...)` anywhere. `DispatcherServlet`, running inside the servlet container, receives the actual HTTP request, matches it to this method based on the `@GetMapping`, and calls it for you — supplying the `id` argument by parsing it out of the URL. You just registered a handler; the framework decides when to ring you up.

### Why Spring is built this way

Every one of these examples lets the framework own the parts that are repetitive, error-prone, or need to happen in a precise order (lifecycle sequencing, resource cleanup, HTTP routing, object wiring), while your code stays focused purely on the one decision only _you_ can make. That separation is the entire payoff of the Hollywood Principle: your classes stop needing to know how to find their collaborators, when to run, or who's going to use them — they just expose a hook, and the framework calls it exactly when needed.


[[Spring Framework]]