
# `@DependsOn` in Spring

`@DependsOn` is an annotation that tells Spring: "Before you create this bean, make sure these other beans are already created." It lets you control the **order in which beans are initialized** when that order matters but isn't visible in the code through normal injection.

Normally Spring figures out the order on its own. If `OrderService` takes a `PaymentService` in its constructor, Spring knows to create `PaymentService` first. That dependency is _visible_. `@DependsOn` is for the cases where one bean needs another to be ready, but there is no field, constructor parameter, or setter connecting them. You use it sparingly, but when you need it, nothing else does the job as cleanly.

---

## How Spring decides creation order (the part you need first)

When the container starts, it creates singleton beans one by one. For each bean, it looks at what that bean _references_ (constructor arguments, `@Autowired` fields, setter injection) and creates those first. So the order comes from **injection links**.

Now picture two beans with no link between them:

```java
@Component
class DatabaseInitializer {
    DatabaseInitializer() {
        System.out.println("Creating tables...");
    }
}

@Component
class CacheLoader {
    CacheLoader() {
        System.out.println("Loading cache from tables...");
    }
}
```

`CacheLoader` reads from tables that `DatabaseInitializer` creates. But `CacheLoader` never _injects_ `DatabaseInitializer`, so Spring sees no reason to prefer an order. It might print "Loading cache" first and your app breaks. That hidden, invisible dependency is exactly what `@DependsOn` makes visible.

---

## The basic usage

```java
@Component
@DependsOn("databaseInitializer")
class CacheLoader {
    CacheLoader() {
        System.out.println("Loading cache from tables...");
    }
}
```

Line by line:

1. `@Component` registers `CacheLoader` as a bean.
2. `@DependsOn("databaseInitializer")` says: create the bean named `databaseInitializer` first.
3. The constructor runs only after `DatabaseInitializer` is fully created, so the output is always:

```
Creating tables...
Loading cache from tables...
```

**The value is a bean _name_, not a class.** For `@Component` classes, the default name is the class name with a lowercase first letter (`DatabaseInitializer` becomes `databaseInitializer`). For `@Bean` methods, the name is the method name.

---

## Depending on several beans

You can pass an array. Spring creates all of them first, in the order listed:

```java
@Component
@DependsOn({"databaseInitializer", "configLoader"})
class CacheLoader { }
```

---

## Using it on `@Bean` methods

This is very common in `@Configuration` classes:

```java
@Configuration
class AppConfig {

    @Bean
    public DataSourceMigrator migrator() {
        return new DataSourceMigrator();
    }

    @Bean
    @DependsOn("migrator")
    public ReportService reportService() {
        return new ReportService();
    }
}
```

Here, `reportService` is only created after the bean named `migrator` exists. The name `"migrator"` matches the method name `migrator()`.

---

## What `@DependsOn` really guarantees

This is the part people often get wrong, so read it slowly.

**Creation order.** The depended-on bean is created and initialized first. That includes its constructor and its `@PostConstruct` / `afterPropertiesSet` callbacks.

**Shutdown order (reversed).** When the app closes, Spring destroys beans in the **opposite** order. So `CacheLoader` is destroyed _before_ `DatabaseInitializer`. This is useful: the dependent bean can still use its dependency while shutting down.

**What it does NOT do:**

- It does not **inject** the other bean. You still can't call `databaseInitializer.something()` unless you also inject it.
- It does not **wait for async work**. If `DatabaseInitializer` starts a background thread, `@DependsOn` only guarantees the _bean_ is initialized, not that the thread has finished.
- It does not work well with **prototype** beans. Prototype beans are created on demand, and Spring doesn't manage their full lifecycle, so the ordering and destruction guarantees don't apply the same way.

---

## Circular `@DependsOn` is an error

```java
@Component
@DependsOn("b")
class A { }

@Component
@DependsOn("a")
class B { }
```

Spring throws a `BeanCreationException` about a circular depends-on relationship at startup. It can't create either one first. Unlike circular _injection_, which Spring sometimes works around, circular `@DependsOn` is never allowed.

---

## When to use it, and when not to

**Good reasons:**

- A bean depends on a **side effect** of another bean (tables created, a file written, a system property set, a driver registered).
- A bean uses a **static** resource that another bean initializes.
- Integration with legacy code where you can't change the constructors.

**Better alternatives first:**

|If your situation is...|Prefer|
|---|---|
|Bean A truly _uses_ bean B|Inject B through the constructor (order comes for free)|
|Run something once after startup|`ApplicationRunner`, `CommandLineRunner`, or `ApplicationReadyEvent`|
|Database schema setup|Flyway or Liquibase, which Spring Boot orders automatically before JPA|
|Several steps in a strict sequence|One bean that calls the steps in order|

A good rule: if you find yourself adding many `@DependsOn` annotations, your design probably has hidden coupling that should be made explicit with injection.

---

## A quick check you can try

Add print statements to constructors like the first example, then run with and without `@DependsOn`. Without it, the order may look right by luck (Spring often creates beans in classpath-scan order, which is typically alphabetical), and it can silently break later when you rename a class. With `@DependsOn`, the order is guaranteed no matter what you rename.

---

## A related concept in short: `@Order`

`@Order` is often confused with `@DependsOn`, but it does something different. `@Order` controls the **position inside a collection** of beans (for example, the order of several `Filter` beans or `List<Validator>` injections) and the order of AOP advice. It does **not** control which bean is _created_ first. Use `@DependsOn` for creation order, and `@Order` for ordering within lists.

---

## Takeaways

- `@DependsOn` forces Spring to create the named beans **before** this bean, even without an injection link.
- It takes **bean names**, not classes, and works on `@Component` classes and `@Bean` methods.
- Shutdown happens in **reverse** order.
- It doesn't inject anything, doesn't wait for async work, and circular uses fail at startup.
- Prefer real injection or startup events when they fit. Use `@DependsOn` for hidden, side-effect-based dependencies.




[[Spring Framework]]