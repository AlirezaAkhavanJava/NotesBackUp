![[Spring Bean Lifecycle Fantasy Map.png]]

The **Spring Bean Lifecycle** describes how the Spring IoC Container creates, configures, initializes, manages, and eventually destroys beans. Spring handles most of these operations automatically, allowing developers to focus on business logic rather than manually managing objects.

The lifecycle can be divided into **three main phases: Creation, Initialization, and Destruction**, with a Ready-to-Use period between initialization and destruction.

## Phase 1 — Bean Creation

|Step|What Happens|
|---|---|
|1. Container Startup|Spring Boot creates and prepares the IoC Container (`ApplicationContext`).|
|2. Component Scanning|Spring discovers `@Component`, `@Service`, `@Repository`, etc., and registers their Bean Definitions.|
|3. BeanFactoryPostProcessor|Inspects or modifies Bean Definition metadata before normal bean instantiation.|
|4. Instantiation|Spring creates the actual object by invoking its constructor.|
|5. Dependency Injection|Spring injects required dependencies (constructor injection happens during instantiation).|
|6. Aware Callbacks|Spring supplies container information using interfaces such as `BeanNameAware` and `BeanFactoryAware`.|

**Key idea:** Spring moves from Bean Definitions (metadata) to actual Java objects.

## Phase 2 — Bean Initialization

|Step|What Happens|
|---|---|
|7. Before-Initialization|`postProcessBeforeInitialization()` processes the bean. `ApplicationContextAware` and `@PostConstruct` callbacks are handled here by specialized processors.|
|8. Initialization|`afterPropertiesSet()` and custom `initMethod` execute.|
|9. After-Initialization|`postProcessAfterInitialization()` processes the initialized bean and may return an AOP proxy.|

**Key idea:** Initialization provides an opportunity to prepare the bean for normal use. Spring may also wrap it with a proxy for features such as `@Transactional`.

## Ready to Use

The bean is fully initialized and available to the application.

For singleton beans, Spring normally reuses the same instance throughout the container's lifetime.

## Phase 3 — Bean Destruction

When the IoC Container closes normally, Spring executes applicable destruction callbacks to release resources.

|Order|Mechanism|
|---|---|
|1|`@PreDestroy`|
|2|`DisposableBean.destroy()`|
|3|Custom `destroyMethod`|

**Key idea:** Destruction allows beans to release resources such as threads, sockets, and connections. Automatic destruction callbacks are not provided for prototype beans.

---

## Complete Lifecycle — Quick Diagram

```
       SPRING BOOT STARTS
               |
               v
       IoC Container Created
               |
               v
       Bean Definitions Registered
               |
               v
       BeanFactoryPostProcessor
               |
               v
        [ PHASE 1: CREATION ]
               |
               v
          Instantiation
               |
               v
       Dependency Injection
               |
               v
         Aware Callbacks
               |
               v
     [ PHASE 2: INITIALIZATION ]
               |
               v
   postProcessBeforeInitialization()
               |
               v
         @PostConstruct
               |
               v
       afterPropertiesSet()
               |
               v
         Custom initMethod
               |
               v
   postProcessAfterInitialization()
               |
               v
         READY TO USE
               |
               v
       Application Running
               |
               v
      ApplicationContext Closes
               |
               v
      [ PHASE 3: DESTRUCTION ]
               |
               v
          @PreDestroy
               |
               v
   DisposableBean.destroy()
               |
               v
       Custom destroyMethod
               |
               v
       LIFECYCLE COMPLETE
```

_Note:_ `_@PostConstruct_` _is executed within before-initialization processing, not as a separate processor phase._

## Five Things to Remember

1. **Bean Definition ≠ Bean:** A definition contains metadata; a bean is the actual managed object.
    
2. **BeanFactoryPostProcessor ≠ BeanPostProcessor:** The first works with definitions; the second works with instances.
    
3. **Instantiation ≠ Initialization:** Instantiation creates the object; initialization performs additional setup.
    
4. **Constructor Injection:** Happens during instantiation, whereas field and setter injection normally happen afterward.
    
5. **Spring Manages the Lifecycle:** Creation, dependency injection, initialization, and destruction are coordinated by the IoC Container.
    

## Final Mental Model

**Creation → Initialization → Ready to Use → Destruction**

Spring's IoC Container is more than an object factory. It is an **object lifecycle manager**, responsible for coordinating how beans are constructed, connected, initialized, exposed to the application, and cleaned up.



[[Spring Framework]]