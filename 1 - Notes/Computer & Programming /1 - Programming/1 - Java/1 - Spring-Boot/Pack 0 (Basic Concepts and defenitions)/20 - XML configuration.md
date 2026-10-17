
## Core intuition

Before Java annotations existed, Spring configuration lived entirely in XML files. You'd write an XML document saying "here's a bean named `userService`, it's built from this class, here's what to inject into it" — and Spring would parse that file, build the objects, and wire them together exactly like `@Component`/`@Bean` do today.

You're learning this for a few real reasons: a lot of legacy enterprise Java still runs on XML config, some interview questions assume you know it, and — importantly — seeing the _explicit_ version makes annotation-based config click harder, because autowiring conflicts that feel mysterious with `@Autowired` become obvious when you see the raw XML resolving them.

Mental model: an XML config file is just a **list of bean recipes** + **wiring instructions**, read top to bottom by the container at startup, instead of being scattered as annotations across your classes.

## The basic structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="gameRepository" class="com.arcade.repository.GameRepository" />

    <bean id="gameService" class="com.arcade.service.GameService">
        <constructor-arg ref="gameRepository" />
    </bean>

</beans>
```

Loading it:

```java
ApplicationContext context =
    new ClassPathXmlApplicationContext("applicationContext.xml");
GameService service = (GameService) context.getBean("gameService");
```

Each `<bean>` tag = one bean definition. `id` is the bean's name in the container (what you'd pass to `getBean()`). `class` is the fully-qualified class Spring instantiates with `new` behind the scenes.

## Wiring dependencies manually

This is the XML equivalent of `@Autowired`. Three ways to inject:

**1. Constructor injection** (`<constructor-arg>`)

```xml
<bean id="gameService" class="com.arcade.service.GameService">
    <constructor-arg ref="gameRepository" />
</bean>
```

`ref` points to another bean's `id`. For primitives/Strings, use `value` instead of `ref`:

```xml
<constructor-arg value="arcade-mode" />
```

**2. Setter injection** (`<property>`)

```xml
<bean id="gameService" class="com.arcade.service.GameService">
    <property name="gameRepository" ref="gameRepository" />
</bean>
```

Requires a `setGameRepository(...)` method on the class. `name` must match the property name (JavaBean convention).

**3. Multiple constructor args, ordered or by index**

```xml
<bean id="gameService" class="com.arcade.service.GameService">
    <constructor-arg index="0" ref="gameRepository" />
    <constructor-arg index="1" value="5" />
</bean>
```

## Enabling component scanning from XML

You can still mix auto-discovery into an XML file instead of hand-writing every `<bean>`:

```xml
<context:component-scan base-package="com.arcade" />
```

(requires the `context` XML namespace declared at the top)

This is the direct XML ancestor of `@ComponentScan` — it finds `@Service`/`@Repository`/`@Component` classes in the package and registers them, same as the annotation version. You can combine this with explicit `<bean>` tags for anything not annotated.

---

## Autowiring — the `autowire` attribute

Instead of manually wiring every `<constructor-arg>`/`<property>`, XML supports an `autowire` attribute that tells Spring "figure out the dependency yourself":

```xml
<bean id="gameService" class="com.arcade.service.GameService" autowire="byType" />
```

|Mode|Behavior|
|---|---|
|`no` (default)|No autowiring — you must wire explicitly|
|`byType`|Finds a bean whose **type** matches the constructor/setter parameter|
|`byName`|Finds a bean whose **id** matches the property name|
|`constructor`|Like `byType`, but specifically for constructor args|

Example of `byName`:

```xml
<bean id="gameRepository" class="com.arcade.repository.GameRepository" />

<bean id="gameService" class="com.arcade.service.GameService" autowire="byName">
    <!-- Spring looks for a bean named exactly "gameRepository" 
         to match setGameRepository(...) -->
</bean>
```

## Fixing autowiring conflicts

This is where it gets real, and where the XML version makes the _mechanism_ obvious in a way `@Autowired` hides.

**Problem: `byType` finds more than one matching bean**

```xml
<bean id="mysqlRepo" class="com.arcade.repository.MysqlGameRepository" />
<bean id="mongoRepo" class="com.arcade.repository.MongoGameRepository" />

<bean id="gameService" class="com.arcade.service.GameService" autowire="byType" />
```

If both beans implement `GameRepository`, Spring can't pick — `NoUniqueBeanDefinitionException` at startup. Three fixes:

**Fix 1 — switch to `byName`** and make the bean id match the property/parameter name exactly. Deterministic, but brittle (renaming breaks it silently).

**Fix 2 — mark one as primary:**

```xml
<bean id="mysqlRepo" class="com.arcade.repository.MysqlGameRepository" primary="true" />
<bean id="mongoRepo" class="com.arcade.repository.MongoGameRepository" />
```

`primary="true"` is the XML twin of `@Primary` — "use this one unless told otherwise."

**Fix 3 — drop autowiring for just this bean and wire explicitly:**

```xml
<bean id="gameService" class="com.arcade.service.GameService">
    <constructor-arg ref="mongoRepo" />
</bean>
```

Explicit `ref` always overrides ambiguity — it's the XML equivalent of `@Qualifier`.

**Problem: no matching bean found**

If `autowire="byType"` finds _zero_ candidates, you get `NoSuchBeanDefinitionException`. Usual causes: the bean class was never declared with `<bean>`, the implementing class isn't in the component-scanned package, or there's a typo in `basePackage`.

**Problem: circular dependency (A needs B, B needs A)**

```xml
<bean id="beanA" class="com.arcade.BeanA">
    <constructor-arg ref="beanB" />
</bean>
<bean id="beanB" class="com.arcade.BeanB">
    <constructor-arg ref="beanA" />
</bean>
```

Constructor injection **cannot** resolve this — Spring needs to fully construct A before B, but B needs a finished A first. You get a `BeanCurrentlyInCreationException`.

Fix: switch at least one side to **setter injection**, since Spring can create a half-built bean, register it, then fill in the setter later:

```xml
<bean id="beanA" class="com.arcade.BeanA">
    <property name="beanB" ref="beanB" />
</bean>
```

This works because setter injection happens _after_ the object already exists, breaking the chicken-and-egg deadlock. (Same story as circular deps with `@Autowired` field/setter injection in annotation-based config — this is literally the same underlying mechanism, just visible.)

**Problem: duplicate bean `id`**

```xml
<bean id="gameService" class="com.arcade.service.GameServiceV1" />
<bean id="gameService" class="com.arcade.service.GameServiceV2" />
```

Spring doesn't error — by default the **second definition silently overrides the first**. This is a classic silent bug: no exception, just the wrong implementation wired in. Always grep for duplicate `id`s when debugging "wrong bean got injected" issues.

## Nuances/gotchas worth knowing

- **XML config and annotation config can coexist.** `<context:component-scan>` plus hand-written `<bean>` tags plus `@Autowired` inside the scanned classes all work together in the same app — common in legacy codebases mid-migration to annotations.
- **`byType` autowiring ignores bean `id` entirely** — it's purely about assignability to the target type/interface. This surprises people coming from `byName`.
- **Scope still applies** — add `scope="prototype"` to a `<bean>` tag exactly like `@Scope("prototype")` does in annotation config; same singleton-by-default rule holds.
- **Spring Boot apps almost never use XML today** — this is genuinely legacy knowledge now, but understanding it is what makes `@Autowired`'s "magic" conflict-resolution (`@Primary`, `@Qualifier`) feel mechanical instead of mysterious, since it's the exact same resolution algorithm underneath.





[[Spring Framework]]