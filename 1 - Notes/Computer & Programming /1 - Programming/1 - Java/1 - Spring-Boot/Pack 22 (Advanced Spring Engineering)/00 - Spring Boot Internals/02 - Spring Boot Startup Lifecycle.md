
You've already got the _bean_ lifecycle down (constructor → `Aware` → `BeanPostProcessor` → init/destroy). This topic is one level up: the **application** lifecycle — everything that happens from the moment you call `SpringApplication.run()` to the moment your app is fully serving requests, and back down again on shutdown. The bean lifecycle you know happens _inside_ one phase of this bigger picture.

## The entry point

```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

`SpringApplication.run()` isn't a single step — it's an orchestrator that runs a fixed sequence of phases, firing events at each one. Understanding this sequence is what lets you answer questions like "where do I hook in to run code before the web server starts" or "why did my `CommandLineRunner` run after all my beans were created."

## Phase 1 — Create the `SpringApplication` instance

Before `run()` even executes its logic, a `SpringApplication` object is built. During construction, it:

- Deduces the application type — **servlet**, **reactive**, or **none** — by checking which classes are on the classpath (`DispatcherServlet` present → servlet app, etc.). This ties directly back to `@ConditionalOnWebApplication` from your conditional annotations lesson — this deduction is _why_ that condition can even answer the question later.
- Loads `ApplicationContextInitializer` and `ApplicationListener` implementations registered via `META-INF/spring.factories` (or the newer imports-file mechanism) — these are extension points that run very early, often used by Boot's own internals and by libraries like Spring Cloud.
- Figures out the "main" class by inspecting the stack trace (used for logging/banner purposes).

## Phase 2 — Run listeners: `ApplicationStartingEvent`

Once `run()` is actually called, Boot creates a `SpringApplicationRunListeners` object and starts firing a sequence of events. The first is `ApplicationStartingEvent` — fired before almost anything else (before the `Environment` is even prepared). This is as early as you can hook into the process.

## Phase 3 — Prepare the `Environment`: `ApplicationEnvironmentPreparedEvent`

Boot builds the `ConfigurableEnvironment` — this is where `application.properties`/`.yml`, command-line args, environment variables, and active profiles all get merged into one property source hierarchy, in the precedence order you'd expect (command-line args beat properties files, etc.). Once this is assembled, `ApplicationEnvironmentPreparedEvent` fires.

This happens _before_ the `ApplicationContext` exists. That timing matters: it's why `EnvironmentPostProcessor` implementations (a Boot extension point for programmatically modifying properties before anything reads them) can run here — the environment is ready, but nothing has consumed it yet.

## Phase 4 — Print the banner

Small but visible step: the ASCII-art Spring Boot banner you see on every app startup gets printed here, using the now-ready `Environment` (so you can customize it via `banner.txt` or properties).

## Phase 5 — Create the `ApplicationContext`

Based on the application type decided in Phase 1, Boot instantiates the matching context implementation — `AnnotationConfigServletWebServerApplicationContext` for a servlet app, `AnnotationConfigReactiveWebServerApplicationContext` for reactive, or a plain `AnnotationConfigApplicationContext` for neither. The `Environment` from Phase 3 is attached to it immediately.

## Phase 6 — Prepare the context: `ApplicationContextInitializedEvent`

The `ApplicationContextInitializer` instances found back in Phase 1 run now, against the freshly created (but still empty) context. Then `ApplicationContextInitializedEvent` fires. Still no beans exist yet — this phase is about wiring up the context object itself, not populating it.

## Phase 7 — Load bean definitions: `ApplicationPreparedEvent`

This is where your `@SpringBootApplication` class gets registered as a configuration class, component scanning runs, and — tying directly into your last two lessons — `@EnableAutoConfiguration` triggers, `AutoConfigurationImportSelector` reads the `.imports` files, and every `@Conditional*` check you just learned about gets evaluated. By the end of this phase, every bean _definition_ (not instance) that will exist in the app is registered. `ApplicationPreparedEvent` fires right after.

Important distinction: this is still just **definitions** — blueprints, like your `BeanDefinition` lesson covered. No constructors have run yet.

## Phase 8 — Refresh the context: this is where bean lifecycle lives

Now Boot calls `context.refresh()` — the single Spring Framework method that does the heaviest lifting. This is exactly where your existing bean-lifecycle knowledge plugs in:

```
refresh()
 ├─ invoke BeanFactoryPostProcessors
 ├─ register BeanPostProcessors
 ├─ instantiate every non-lazy singleton bean:
 │    constructor → populate properties → Aware callbacks →
 │    BeanPostProcessor (before) → @PostConstruct/afterPropertiesSet →
 │    BeanPostProcessor (after)
 ├─ if a servlet app: create and start the embedded web server (Tomcat/etc.)
 └─ publish ContextRefreshedEvent
```

That embedded web server creation is worth calling out specifically: it happens as _part of_ `refresh()`, as just another singleton bean being instantiated (a `ServletWebServerFactory` bean produces it). This is why a `@Bean` method that throws an exception during startup can prevent your web server from ever binding to a port — the server itself is downstream of ordinary bean creation, not a separate pre-step.

## Phase 9 — `ApplicationStartedEvent`

The context has fully refreshed — every bean exists, the web server (if any) is listening. `ApplicationStartedEvent` fires. The app is technically "started" but Boot distinguishes this from "ready."

## Phase 10 — Run the runners

Immediately after, Boot looks up every bean implementing `CommandLineRunner` or `ApplicationRunner` and invokes them, in order (respecting `@Order` if present):

```java
@Component
public class StartupTask implements CommandLineRunner {
    @Override
    public void run(String... args) {
        System.out.println("App is up, running startup task");
    }
}
```

This answers a question that confuses a lot of people: these runners execute _after_ every bean is fully created and the web server is already listening — not before. If you need something to run strictly before the app accepts traffic, a runner is the wrong tool; you'd use a `BeanPostProcessor`/`InitializingBean`/`@EventListener(ApplicationStartedEvent.class)` hook instead, depending on exactly how early you need it.

## Phase 11 — `ApplicationReadyEvent`

Once the runners finish, `ApplicationReadyEvent` fires. This is the true "fully operational" signal — the one Boot's own health-check and readiness-probe support waits for, and the one you should listen for if you want to react only once the app is _completely_ ready, runners included:

```java
@Component
public class ReadyListener {
    @EventListener(ApplicationReadyEvent.class)
    public void onReady() {
        // safe: everything is up, including runners
    }
}
```

## What happens if something fails

If any phase throws an exception, Boot fires `ApplicationFailedEvent` instead of continuing, prints the failure analysis (the readable "Description / Action" error reports you've probably seen for things like a missing `DataSource` property), and exits. No partial "almost ready" state is left hanging — the context that failed to refresh is closed.

## Shutdown: the mirror image

On JVM shutdown (normal exit, or `SIGTERM`), a registered shutdown hook calls `context.close()`, which:

- Publishes `ContextClosedEvent`
- Runs `@PreDestroy` methods and `DisposableBean.destroy()` on every singleton bean, in reverse of their creation order
- Stops the embedded web server
- Releases resources held by the context itself

This is the same destroy-phase machinery from your bean lifecycle lesson — the startup lifecycle doesn't replace that, it's just the outer frame that calls `refresh()` to start it and `close()` to end it.


[[Spring Framework]]
