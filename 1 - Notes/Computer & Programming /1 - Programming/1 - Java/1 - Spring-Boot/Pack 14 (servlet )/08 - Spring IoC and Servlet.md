
# IoC Container, ApplicationContext, and Spring Boot

**Definition.** **Inversion of Control (IoC)** is a design principle in which your objects do not create or look up the objects they depend on. Something else does that work and hands them in. The **IoC container** is the part of Spring that performs this work. It creates objects (called **beans**), wires them together, manages their lifecycle, and destroys them at shutdown. The **ApplicationContext** is the main interface for the container, and it is the object you hold when you need to ask Spring for something.

## The problem it solves

Consider a service that needs a payment gateway:

```java
public class OrderService {

    private final PaymentGateway gateway = new StripeGateway();  // OrderService decides

    public void placeOrder(Order order) {
        gateway.charge(order.total());
    }
}
```

This code works, but `OrderService` makes two decisions that are not its business. It chooses the concrete class, `StripeGateway`, and it creates the object. Three problems follow:

1. **Changing the implementation means editing `OrderService`.** Switching to a test gateway or a different provider requires code changes in every class that creates one.
2. **Testing is difficult.** You cannot pass a fake gateway, so every test would charge a real card.
3. **Dependency chains get long.** If `StripeGateway` needs an HTTP client, which needs a configuration object, `OrderService` must build the whole chain by hand, and every class in the chain repeats that work.

Inversion of Control moves those decisions out of the class. `OrderService` declares what it needs, and something else supplies it.

## The same code with IoC

```java
public interface PaymentGateway {
    void charge(BigDecimal amount);
}

@Component
public class StripeGateway implements PaymentGateway {
    @Override
    public void charge(BigDecimal amount) {
        // calls the real payment API
    }
}

@Service
public class OrderService {

    private final PaymentGateway gateway;

    public OrderService(PaymentGateway gateway) {   // declares the need
        this.gateway = gateway;
    }

    public void placeOrder(Order order) {
        gateway.charge(order.total());
    }
}
```

What this does:

- `@Component` on `StripeGateway` tells Spring to create one instance of it and manage it as a bean.
- `@Service` on `OrderService` does the same, and marks the class as business logic. The annotation is a specialization of `@Component` and behaves identically for wiring.
- `OrderService` has a constructor that asks for a `PaymentGateway`. It never mentions `StripeGateway`. The field is `final`, so the dependency must be supplied before the object exists.
- At startup, Spring sees that `OrderService` needs a `PaymentGateway`, finds the one bean that implements it, and passes it into the constructor.

In a test, you bypass the container entirely:

```java
@Test
void chargesTheOrderTotal() {
    PaymentGateway fake = amount -> recorded.add(amount);   // no real charge
    OrderService service = new OrderService(fake);          // plain constructor call
    service.placeOrder(new Order(new BigDecimal("42.00")));
    // assert on recorded
}
```

Constructor injection is what makes this possible. The class does not depend on the container to work, so the container is needed only in the running application.

## The IoC container as a dependency graph

The container's core job is to build a graph of objects in the right order. Here is the graph for the example:

```
StripeGateway  (no dependencies)
      │
      ▼
OrderService   (needs PaymentGateway, so it waits for StripeGateway)
      │
      ▼
OrderController (needs OrderService)
```

Spring creates objects from the bottom of this graph upward. You never write the order, and you never call `new` for any of these classes. If you add a dependency that creates a loop, such as `A` needing `B` while `B` needs `A` through constructors, the container cannot pick a starting point and fails at startup with a circular dependency error. That failure is useful, because it reveals a design problem early.

## Where the bean definitions come from

The container needs to know which classes to manage. It learns this in three ways:

|Source|How it works|Typical use|
|---|---|---|
|Component scanning|Finds `@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController` under the main package|Your own classes|
|`@Bean` methods in `@Configuration` classes|You write the creation code yourself|Third-party classes you cannot annotate, or objects that need setup|
|Auto-configuration|Spring Boot registers beans based on what is on the classpath|Things like the embedded Tomcat, JSON converters, and the `DataSource`|

The `@Bean` form shows the container's responsibility most clearly:

```java
@Configuration
public class AppConfig {

    @Bean
    public Clock clock() {                  // third-party class, cannot be annotated
        return Clock.systemUTC();
    }

    @Bean
    public OrderService orderService(PaymentGateway gateway, Clock clock) {
        return new OrderService(gateway, clock);   // Spring supplies both arguments
    }
}
```

What this does: each `@Bean` method is a factory. Spring calls it once and stores the result. The parameters of the method are themselves dependencies, so Spring fills them in from other beans. This is the same wiring idea as the constructor example, expressed in code instead of annotations.

## Bean lifecycle

A bean passes through defined stages, and you can hook into them.

```
1. Instantiate        constructor runs
2. Populate           dependencies are injected
3. Initialize         @PostConstruct runs
4. Ready              the bean serves requests
5. Destroy            @PreDestroy runs at shutdown
```

```java
@Component
public class ConnectionCache {

    private Map<String, String> cache;

    @PostConstruct
    void warmUp() {                 // runs after dependencies are injected
        cache = new ConcurrentHashMap<>();
        cache.put("version", "1.0");
    }

    @PreDestroy
    void shutdown() {               // runs once when the application stops
        cache.clear();
    }
}
```

What this does: `@PostConstruct` runs after every dependency is in place, so it is safe to use injected fields there. `@PreDestroy` runs when the context closes, which gives you a place to release resources. Beans are created and destroyed by the container, so your code does not need to track them.

## ApplicationContext: the container you talk to

Spring has a small hierarchy of container interfaces. Each adds capabilities.

```
BeanFactory                          basic: getBean, dependency wiring
  └── ApplicationContext             adds events, message sources, resource loading,
        │                            and the environment (properties and profiles)
        └── WebApplicationContext    adds knowledge of a ServletContext
              └── AnnotationConfigServletWebServerApplicationContext
                                     what Spring Boot creates for a web app
```

- **`BeanFactory`** is the core. It knows how to create and wire beans. It is the minimal container.
- **`ApplicationContext`** extends it with features that applications need: publishing and receiving events, reading `application.properties`, and selecting beans by profile. In practice, when people say "the container," they mean an `ApplicationContext`.
- **`WebApplicationContext`** adds a link to the `ServletContext`, the object that represents your web application inside the servlet container.
- **`AnnotationConfigServletWebServerApplicationContext`** is the concrete class Spring Boot uses. Its name describes what it does: it reads annotations, runs in a servlet environment, and can start an embedded web server.

You can ask the context for beans directly:

```java
@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext ctx = SpringApplication.run(DemoApplication.class, args);

        OrderService service = ctx.getBean(OrderService.class);  // ask for a bean by type
        System.out.println("Got: " + service.getClass().getName());

        System.out.println("Beans: " + ctx.getBeanDefinitionCount());
    }
}
```

What this does: `SpringApplication.run` builds the context, refreshes it (which creates all the beans), starts the web server, and returns the context. `getBean` retrieves the managed instance. You rarely call this in real code, because injection is cleaner. It is useful for learning, because it shows that the container really exists and holds the objects.

## Where the container meets the servlet

This is the connection you asked about. The IoC container and the servlet world are separate systems that meet at specific points.

**Point 1: Spring Boot creates the context, then starts Tomcat inside it.** When `SpringApplication.run` reaches the refresh step, the context's `onRefresh` method creates the embedded web server. Tomcat is therefore started by the container, as one of its beans, and it begins accepting traffic only after the other beans exist. This ordering is why a controller is never called before its dependencies are ready.

**Point 2: The context is stored on the ServletContext.** Spring attaches the `WebApplicationContext` to the `ServletContext` as an attribute, so anything running inside the servlet world can reach the container. This is the bridge.

**Point 3: `DispatcherServlet` is a bean-aware servlet.** Earlier you saw that `DispatcherServlet` is an `HttpServlet`. It finds its controllers, interceptors, and converters by asking the context. Its routing tables are built from the beans the container holds.

**Point 4: Plain servlets can reach the container.** A servlet that Spring did not create cannot receive injected fields, but it can look up the context:

```java
@WebServlet("/status")
public class StatusServlet extends HttpServlet {

    private OrderService orders;

    @Override
    public void init() {
        ServletContext sc = getServletContext();
        WebApplicationContext ctx = WebApplicationContextUtils.getWebApplicationContext(sc);
        this.orders = ctx.getBean(OrderService.class);     // pulled from the container
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("text/plain");
        resp.getWriter().println("Service ready: " + (orders != null));
    }
}
```

What this does: `init()` runs once when the servlet is created. It gets the `ServletContext`, asks Spring's utility for the `WebApplicationContext` stored there, and retrieves an `OrderService` bean. The servlet is not managed by Spring, so this manual lookup is the only way to reach the container from it. This is also the reason the earlier `ServletRegistrationBean` approach is preferred. Injecting through a bean method is cleaner than this lookup.

**Point 5: Filters and the context.** A `Filter` registered as a bean is managed by the container. A filter created with `new` and handed to Tomcat by other means is not. This is the same distinction as before, now seen from the container's side.

## How Spring Boot starts the container

Putting it together, here is what happens when you run the application:

```
SpringApplication.run(DemoApplication.class, args)
  1. Create the ApplicationContext (AnnotationConfigServletWebServerApplicationContext)
  2. Load the Environment (application.properties, profiles, command-line args)
  3. Scan packages for @Component, @Service, @Configuration, ...
  4. Add auto-configuration beans based on the classpath
  5. refresh():
       a. Build bean definitions
       b. Create every singleton bean in dependency order
       c. Run @PostConstruct methods
       d. onRefresh(): create the embedded Tomcat and register DispatcherServlet
       e. Start Tomcat on port 8080
  6. Publish ApplicationReadyEvent
  7. Return the context to main()
```

Step 5 is the heart of it. The container does the work, and the web server is one of the things it creates. When you see a startup error such as `Error creating bean with name 'orderService'`, the message names the bean whose creation failed, and the cause chain names the dependency that could not be satisfied.

## Bean scopes and thread safety

By default, each bean is a **singleton**: one instance per container, shared by all threads. This connects directly to the thread-safety rules from the servlet lessons. A `@Service` or `@RestController` is shared across all request threads, just like one servlet instance, so it should hold no mutable per-request state.

Spring offers other scopes for cases where state belongs to a narrower lifetime:

|Scope|One instance per|Typical use|
|---|---|---|
|`singleton` (default)|Container|Services, repositories, controllers|
|`prototype`|Each time it is requested|Objects with mutable state that must not be shared|
|`request`|HTTP request|Per-request data such as an audit context|
|`session`|HTTP session|Per-user data such as a shopping cart|

The web scopes (`request` and `session`) are where the servlet and the container meet most directly. They use the `HttpSession` you learned about earlier, and the container creates and destroys the bean as the session or request begins and ends.

## Common mistakes

- **Using field injection everywhere.** `@Autowired` on a private field works, but the class cannot be built with `new` in a test. Prefer constructor parameters.
- **Calling `new` on a bean class.** The object you create is not managed. Its `@Autowired` fields stay null, and `@PostConstruct` never runs.
- **Mutable fields in a singleton.** The same field is shared by every request thread. Keep per-request data in local variables or use a request-scoped bean.
- **Expecting bean creation order to follow the file order.** Spring orders beans by dependency, not by where they appear in source.
- **Forgetting that a class is outside the scanned packages.** If `OrderService` lives in `com.example.other`, and the main class is in `com.example.demo`, it is never found. The error is `NoSuchBeanDefinitionException`, and the fix is to move the class or set `scanBasePackages`.
- **Confusing an `Optional` injection with a missing bean.** Injecting `Optional<T>` or using `@Nullable` changes what happens when no bean exists. Without it, startup fails.






[[Servlet]]
[[Spring Framework]]