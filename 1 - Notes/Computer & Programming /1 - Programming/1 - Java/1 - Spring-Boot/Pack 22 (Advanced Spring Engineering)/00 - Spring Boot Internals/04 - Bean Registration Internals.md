You already know what a `BeanDefinition` is and how to register one programmatically. This lesson is about what happens _after_ a `BeanDefinition` is registered — how Spring actually stores it, names it, and turns it into a living singleton when `refresh()` runs. This is the machinery sitting between "I have a blueprint" and "I have an object I can inject."

## The registry is just maps

`DefaultListableBeanFactory` is the concrete class that implements `BeanDefinitionRegistry` (which you've already used) and does the real work. Internally, it's built around a small number of concurrent maps — conceptually:

```java
// simplified — not the real field names, but the real idea
Map<String, BeanDefinition> beanDefinitionMap;   // name -> blueprint
List<String> beanDefinitionNames;                // registration order
Map<String, Object> singletonObjects;            // name -> fully created bean
Set<String> registeredSingletons;
```

`registerBeanDefinition(name, definition)` just puts an entry into the first map. Nothing about the bean exists yet — no object, no dependencies resolved. This is the step `ConfigurationClassPostProcessor` and component-scanning both funnel into: by the end of your "Configuration Class Processing" lesson's Phase 7, this map is fully populated. The singleton map, on the other hand, stays empty until instantiation actually happens.

## Where bean names come from

When you write `@Bean public ServiceA serviceA()`, you never explicitly register a name — Spring generates one. The rule, handled by `BeanNameGenerator`:

- For `@Bean` methods, the default name is the **method name** itself (`serviceA`).
- For component-scanned classes (`@Component`, `@Service`, etc.), the default is the **class name with the first letter lowercased** (`UserService` → `userService`).
- You can always override either with an explicit name: `@Bean("customName")` or `@Component("customName")`.

Name collisions matter here: if two `@Bean` methods produce the same name, the _later_-processed one overrides the earlier one's `BeanDefinition` in the map — no error is thrown by default, which is a common source of "why is my bean not what I expected" bugs. Boot does add a check (`spring.main.allow-bean-definition-overriding=false` is the default since Spring Boot 2.1) that turns this into a startup failure instead of a silent override, specifically because of how surprising the silent version is.

## Aliases

A `BeanDefinitionRegistry` also tracks aliases — alternate names pointing at the same bean definition, via `registerAlias(name, alias)`. This is what lets `@Primary` and XML `<alias>` style indirection work: multiple names can resolve to the one underlying definition without duplicating it.

## `preInstantiateSingletons()`: where objects actually get created

Registering definitions is cheap and happens early. Actually creating beans is the expensive part, and it happens in one specific method, called once during `refresh()`: `DefaultListableBeanFactory.preInstantiateSingletons()`. This is the method responsible for the "instantiate every non-lazy singleton" box from your startup lifecycle lesson. Its logic, in outline:

```java
for (String beanName : beanDefinitionNames) {
    BeanDefinition bd = getBeanDefinition(beanName);
    if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
        getBean(beanName); // triggers full creation if not already created
    }
}
```

It walks the definition list **in registration order** and calls `getBean()` for each eligible one. `getBean()` is the single entry point used both here and for your own `@Autowired` lookups — there's no separate "startup creation" code path versus "runtime lookup" code path; it's the same method either way.

## What `getBean()` actually does

Simplified, resolving a singleton bean goes through roughly this sequence:

1. Check `singletonObjects` — if it already exists, return it immediately (this is the cache that makes singleton scope actually singleton).
2. If not found, look up the `BeanDefinition` and resolve the bean's `Class`.
3. Select a constructor (or factory method, for `@Bean`-produced beans) and resolve its arguments — this is where dependency injection actually happens, recursively calling `getBean()` for each dependency.
4. Instantiate the object.
5. Run the rest of the lifecycle you already know: populate properties, `Aware` callbacks, `BeanPostProcessor` before-hooks, init callbacks, `BeanPostProcessor` after-hooks.
6. Store the finished object in `singletonObjects`.
7. Return it.

Because step 3 recursively calls `getBean()` for dependencies, bean creation order isn't strictly the registration order from `preInstantiateSingletons()` — if bean A (processed first) depends on bean B (registered later), B gets created early, out of turn, the moment A needs it.

## Circular dependencies: the three-level cache

This recursive creation raises an obvious problem: what if A depends on B, and B depends on A? Step 3 for A triggers creation of B, which triggers creation of A again — infinite loop, in theory. Spring solves this for **singleton, field/setter-injected** beans using what's commonly called the "three-level cache," which is really three separate maps:

```java
Map<String, Object> singletonObjects;               // level 1: fully finished beans
Map<String, Object> earlySingletonObjects;           // level 2: raw, not-fully-initialized instances
Map<String, ObjectFactory<?>> singletonFactories;    // level 3: factories that can produce early references
```

The trick: right after a bean is instantiated (constructor called) but _before_ its dependencies are injected, Spring exposes a reference to it early, via level 3. So when A's constructor finishes and A needs B, and B's constructor finishes and B needs A — B can grab A's _early, not-yet-fully-populated_ reference from the cache instead of trying to create A from scratch again. By the time both finish their property population, both references point to the same fully-formed objects, and the circularity resolves itself.

This mechanism **only works for singleton beans with no constructor-injection cycle** — if A's _constructor_ directly requires an already-built B, and B's constructor directly requires an already-built A, there's no early reference to hand over (the object doesn't exist yet at all, not even in raw form), and Spring throws `BeanCurrentlyInCreationException`. This is the actual reason "use constructor injection" sometimes conflicts with "break circular dependencies" — constructor-injected circular dependencies are a hard design problem Spring won't paper over, while field/setter-injected ones get this early-reference trick.

## `FactoryBean`: when a bean produces a different bean

One more registration wrinkle worth knowing: implementing `FactoryBean<T>` lets a registered bean act as a factory for a _different_ object, rather than being the object itself:

```java
public class MyServiceFactoryBean implements FactoryBean<MyService> {
    @Override
    public MyService getObject() {
        return new MyService(); // the thing actually injected elsewhere
    }

    @Override
    public Class<?> getObjectType() {
        return MyService.class;
    }
}
```

When you `getBean("myServiceFactoryBean")`, you get the result of `getObject()` — the `MyService`, not the factory. To get the factory itself (rare, but sometimes needed for introspection), you prefix the name with `&`: `getBean("&myServiceFactoryBean")`. This is how things like `LocalContainerEntityManagerFactoryBean` work in JPA setup — the bean you "see" injected as `EntityManagerFactory` is actually the _product_ of a `FactoryBean`, not a directly-constructed object.

[[Spring Framework]]
