

## 1. What Is Bean Initialization?

**Bean Initialization** is the stage in the Spring Bean Lifecycle where an already-created bean gets an opportunity to perform additional setup before it becomes ready for normal use. At this point, Spring has already instantiated the object and injected its dependencies. Now, Spring can execute special initialization methods to validate configuration, prepare internal data, initialize caches, or perform other necessary setup.

Spring provides **three main initialization mechanisms**: `@PostConstruct`, `InitializingBean.afterPropertiesSet()`, and a custom `initMethod`. All three serve a similar purpose, but they differ in how they are declared and how tightly they couple your code to Spring.

## 2. @PostConstruct — Annotation-Based Initialization

`@PostConstruct` is a Jakarta annotation that tells Spring to automatically execute a method after dependency injection is complete.

It's generally the preferred approach for initialization logic in your own Spring-managed classes.

```
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    public UserService() {
        System.out.println("Constructor executed!");
    }

    @PostConstruct
    public void initialize() {
        System.out.println("UserService initialized!");
    }
}
```

Output:

```
Constructor executed!
UserService initialized!
```

**Important details:**

- The method runs automatically; you don't call it yourself.
    
- It runs once per bean instance during normal initialization.
    
- It must not accept parameters.
    
- It must return `void`.
    
- It normally runs after dependency injection.
    

**Internally:** Spring uses `CommonAnnotationBeanPostProcessor` to detect and invoke `@PostConstruct` methods during the `postProcessBeforeInitialization()` stage.

## 3. InitializingBean.afterPropertiesSet() — Interface-Based Initialization

`InitializingBean` is a Spring interface containing one method: `afterPropertiesSet()`.

When your bean implements this interface, Spring automatically invokes that method after dependency injection and the before-initialization processing stage.

```
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Service;

@Service
public class UserService implements InitializingBean {

    @Override
    public void afterPropertiesSet() {
        System.out.println("UserService initialized!");
    }
}
```

### Why Does This Interface Exist?

It provides a standardized Spring-specific lifecycle contract for initialization.

However, implementing it directly couples your class to the Spring Framework.

For ordinary business services, `@PostConstruct` is usually preferable.

## 4. initMethod — Custom Initialization Method

A custom `initMethod` lets you tell Spring which method to execute during initialization without adding Spring-specific interfaces or lifecycle annotations to the class.

For example, imagine we have a plain Java class:

```
public class DatabaseClient {

    public DatabaseClient() {
        System.out.println("Client constructed");
    }

    public void initialize() {
        System.out.println("Client initialized");
    }
}
```

Nothing in this class tells Spring to execute `initialize()`.

We can configure that externally using `@Bean`:

```
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AppConfig {

    @Bean(initMethod = "initialize")
    public DatabaseClient databaseClient() {
        return new DatabaseClient();
    }
}
```

Now Spring knows that after creating the bean and injecting its dependencies, it should call `initialize()`.

This approach is particularly useful when working with third-party classes that you cannot modify.

## 5. In What Order Are These Methods Executed?

Suppose a bean uses all three initialization mechanisms.

Spring executes them in the following order:

```
Bean Instantiated
       |
       v
Dependency Injection Completed
       |
       v
Before-Initialization Processing
       |
       |-- @PostConstruct
       |
       v
InitializingBean.afterPropertiesSet()
       |
       v
Custom initMethod
       |
       v
After-Initialization Processing
       |
       v
Bean Ready to Use
```

This is the standard ordering when each callback is a different method. Notice that `@PostConstruct` executes during before-initialization processing, whereas `afterPropertiesSet()` and the custom init method execute afterward.

## 6. Comparison

|Mechanism|How it works|Recommended use|
|---|---|---|
|`@PostConstruct`|Annotation on a method|Normal application beans|
|`afterPropertiesSet()`|Implement Spring interface|Spring-specific components|
|`initMethod`|Configure method in `@Bean`|External or third-party classes|

## 7. The Whole Picture

Previously, we learned that Spring uses `BeanPostProcessor.postProcessBeforeInitialization()` to process beans before standard initialization methods.

Now we understand what happens inside and after that step:

1. Spring invokes the registered before-initialization processors, including the processor responsible for `@PostConstruct`.
    
2. Spring invokes `afterPropertiesSet()` if the bean implements `InitializingBean`.
    
3. Spring invokes the configured custom initialization method, if one exists.
    

You don't need to use all three. **One initialization mechanism is usually enough.**

Also, initialization callbacks are optional. If your bean doesn't require additional setup, Spring can simply proceed without any custom initialization logic.

**Remember:** The constructor creates the object, dependency injection supplies what it needs, and initialization callbacks allow it to perform additional setup before normal use.




[[Spring Framework]]