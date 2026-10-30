
## Core intuition

Think of your Spring application as a big workshop full of tools (objects) that need to work together — a `UserService` needs a `UserRepository`, which needs a `DataSource`, and so on. Someone has to:

1. **Build** all these tools in the right order
2. **Hand each tool the other tools it depends on** (wiring)
3. **Keep track of them** so anyone who needs a tool later can just ask for it

That "someone" is the **ApplicationContext**. It's Spring's container — the thing that creates your objects, wires their dependencies together, manages their lifecycle, and hands them out on request. You almost never build objects with `new SomeService()` in a Spring app; instead you let the context do it, and you just ask for what you need.

This is the practical face of **Inversion of Control (IoC)**: instead of your code controlling object creation, you hand that control over to the container — hence "inversion."

## Formal picture

`ApplicationContext` is an interface (in `org.springframework.context`). At startup, Spring:

1. Scans for **bean definitions** — recipes describing what objects to create and how (via `@Component`, `@Service`, `@Repository`, `@Configuration` + `@Bean` methods, or XML in older apps)
2. Instantiates those beans
3. Performs **dependency injection** — if Bean A needs Bean B, the context passes B into A (constructor, setter, or field injection)
4. Manages their **scope and lifecycle** (singleton by default — one shared instance per context)
5. Keeps the whole graph of beans in memory, ready to serve

```java
ApplicationContext context = SpringApplication.run(MyApp.class, args);
UserService service = context.getBean(UserService.class);
```

In a Spring Boot app, you rarely touch `ApplicationContext` directly like this — `SpringApplication.run()` creates it for you behind the scenes, and you get beans injected automatically via `@Autowired` or constructor injection instead of pulling them out manually.

`ApplicationContext` extends a simpler interface, **`BeanFactory`**, which is the most basic container (lazy, bare-bones bean lookup). `ApplicationContext` builds on top of it and adds:

- Automatic bean creation at startup (not lazy by default)
- Internationalization (message sources)
- Event publishing (`ApplicationEvent` / `@EventListener`)
- Easy access to environment properties
- AOP integration support

So: `BeanFactory` = the engine. `ApplicationContext` = the engine plus everything a real application needs around it. In practice you always use `ApplicationContext` (or its Boot-specific subtype, `ConfigurableApplicationContext`).

## Nuances and gotchas

- **Bean scope matters.** Default is `singleton` — the context creates one instance and reuses it everywhere. If you want a new instance per injection, you need `@Scope("prototype")`. This trips people up when they assume every injected object is "fresh."
- **Circular dependencies** (A needs B, B needs A) can break constructor injection — Spring can't resolve who to build first. Field/setter injection can work around it, but it's usually a sign of bad design.
- **The context is a graph, not a flat list.** Beans can depend on beans that depend on beans. Spring resolves the whole dependency graph at startup, which is why a single typo in a `@Qualifier` or missing bean can cause the _entire app_ to fail to start, not just the broken part.
- **`getBean()` manually is usually a smell.** Reaching into the context yourself (service locator pattern) defeats the purpose of DI. Prefer constructor injection — let Spring push dependencies to you.
- **Child contexts exist.** Spring MVC's `DispatcherServlet` can have its own child `ApplicationContext` (web-layer beans) nested under a parent (shared/business-layer beans) — mostly historical in older XML-based apps, less common in pure Spring Boot.




[[Spring Framework]]
[[Java]]