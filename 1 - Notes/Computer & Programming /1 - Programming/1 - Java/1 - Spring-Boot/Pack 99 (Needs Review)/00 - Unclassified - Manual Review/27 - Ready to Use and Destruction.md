

We've reached the final two stages of the Spring Bean Lifecycle! At this point, Spring has created the bean, injected its dependencies, executed its initialization callbacks, and applied any necessary post-processing. Now the bean is ready to perform its actual responsibilities in the application.

Eventually, when the Spring IoC Container shuts down, Spring must clean up resources associated with the beans it manages. This is called **Bean Destruction**, and Spring provides three main mechanisms for it: `@PreDestroy`, `DisposableBean.destroy()`, and a custom `destroyMethod`.

---

## 1. Ready to Use — The Bean Is Fully Initialized

**Ready to Use** is the stage where a bean has completed its creation and initialization lifecycle and can now serve the application. For a normal singleton bean, Spring maintains a reference to the initialized bean (or its proxy) inside the IoC Container so that other components can use it through dependency injection.

For example:

```
@Service
public class UserService {

    public void createUser() {
        System.out.println("Creating a user...");
    }
}
```

And our controller:

```
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public void createUser() {
        userService.createUser();
    }
}
```

### What Happens?

1. Spring creates and initializes `UserService`.
    
2. Spring injects it into `UserController`.
    
3. The application becomes ready to accept requests.
    
4. A client sends an HTTP POST request to `/users`.
    
5. The controller calls `userService.createUser()`.
    

The important point is that **Spring does not normally recreate a singleton bean for every HTTP request**.

The same bean instance is reused while the application runs.

Also, Spring doesn't automatically execute the bean's business methods. Those methods execute when something calls them.

### How Long Does a Bean Live?

That depends on its scope.

|Scope|Lifetime|
|---|---|
|Singleton|Normally until its container is closed|
|Prototype|Created on request; the caller manages its subsequent lifetime|
|Request|For one HTTP request|
|Session|For one HTTP session|

For now, let's focus on singleton beans because they are Spring's default.

---

# 2. Bean Destruction — The Final Phase

**Bean Destruction** is the phase where Spring gives managed beans an opportunity to release resources before removing them from service. This happens when the IoC Container closes or when a supported scope ends. Destruction is important because some beans manage resources that require explicit cleanup, such as background executors, files, sockets, or connections.

### When Does Destruction Happen?

Imagine your Spring Boot application is running:

```
Spring Boot Started
        |
        v
IoC Container Created
        |
        v
Beans Created and Initialized
        |
        v
Application Running
        |
        |  Handling HTTP requests
        |  Executing business logic
        |  Using managed resources
        |
        v
Application Shutdown Requested
        |
        v
ApplicationContext Closes
        |
        v
Destruction Callbacks Execute
        |
        v
Resources Released
```

For example, pressing `Ctrl+C` in the terminal normally triggers a graceful shutdown in a Spring Boot application.

**Important:** Destruction callbacks are not guaranteed to execute if the JVM crashes or the process is forcibly killed, such as with `SIGKILL`.

## 3. @PreDestroy — Annotation-Based Cleanup

`@PreDestroy` is a Jakarta annotation that tells Spring to execute a method when a managed bean is about to be destroyed.

It's the counterpart of `@PostConstruct`.

- `@PostConstruct` → Perform initialization.
    
- `@PreDestroy` → Perform cleanup.
    

### Actual Example

Suppose our application manages a background worker.

```
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Service
public class BackgroundJobService {

    private ExecutorService executor;

    @PostConstruct
    public void initialize() {
        executor = Executors.newSingleThreadExecutor();

        System.out.println("Worker initialized!");
    }

    public void executeJob(Runnable job) {
        executor.submit(job);
    }

    @PreDestroy
    public void cleanup() {
        executor.shutdown();

        System.out.println("Worker shutdown requested!");
    }
}
```

### What Happens?

**During initialization:**

```
Spring creates BackgroundJobService
             |
             v
@PostConstruct executes
             |
             v
ExecutorService is created
             |
             v
Bean ready to use
```

**During destruction:**

```
ApplicationContext closing
             |
             v
Spring invokes @PreDestroy
             |
             v
executor.shutdown()
             |
             v
Worker stops accepting new jobs
```

Calling `shutdown()` begins an orderly executor shutdown. Existing tasks may continue executing until they finish.

This illustrates an important responsibility: **if your bean creates a resource, it may also need to release it**.

In production Spring Boot applications, you would often prefer Spring-managed executors rather than creating them manually.

---

## 4. DisposableBean.destroy() — Interface-Based Cleanup

Spring also provides an interface named `DisposableBean`.

It defines one method:

```
public interface DisposableBean {

    void destroy() throws Exception;
}
```

If a bean implements this interface, Spring invokes `destroy()` when the bean is destroyed through the container's normal destruction lifecycle.

### Example

```
import org.springframework.beans.factory.DisposableBean;
import org.springframework.stereotype.Service;

@Service
public class ConnectionService implements DisposableBean {

    @Override
    public void destroy() {
        System.out.println("Cleaning up resources!");
    }
}
```

When Spring closes the container, it invokes the method automatically.

### Why Does It Exist?

It provides a standard lifecycle contract for Spring-managed resources.

However, there is a disadvantage:

**Your class becomes directly dependent on the Spring Framework.**

Because of that, `@PreDestroy` is generally preferred for ordinary application classes.

---

## 5. destroyMethod — Configuration-Based Cleanup

The third approach is configuring a custom destruction method using `@Bean(destroyMethod = "...")`.

This is useful when working with classes that you don't want to modify, including third-party libraries.

### Example

Imagine this plain Java class:

```
public class ExternalClient {

    public void connect() {
        System.out.println("Connected!");
    }

    public void disconnect() {
        System.out.println("Disconnected!");
    }
}
```

It doesn't use Spring annotations or implement Spring interfaces.

But we can configure its lifecycle externally:

```
@Configuration
public class AppConfig {

    @Bean(
        initMethod = "connect",
        destroyMethod = "disconnect"
    )
    public ExternalClient externalClient() {
        return new ExternalClient();
    }
}
```

Spring now knows:

- During initialization → Call `connect()`.
    
- During destruction → Call `disconnect()`.
    

Notice that `destroyMethod` is configuration metadata in the Bean Definition. It does not require the class itself to know anything about Spring.

---

## 6. In What Order Do Destruction Callbacks Execute?

Just like initialization, Spring supports multiple destruction mechanisms on the same bean.

When all three mechanisms are configured with different methods, Spring invokes them in this order:

```
ApplicationContext Closing
           |
           v
1. @PreDestroy
           |
           v
2. DisposableBean.destroy()
           |
           v
3. Custom destroyMethod
           |
           v
Bean Destruction Completed
```

However, you normally **don't need all three mechanisms**.

One well-chosen cleanup method is usually enough.

## 7. Comparison — Initialization vs. Destruction

|Initialization|Destruction|
|---|---|
|`@PostConstruct`|`@PreDestroy`|
|`InitializingBean`|`DisposableBean`|
|`afterPropertiesSet()`|`destroy()`|
|`initMethod`|`destroyMethod`|
|Prepares resources|Releases resources|

## 8. Important — Not Every Bean Gets Destruction Callbacks

Spring automatically manages destruction callbacks for singleton beans when the container closes normally.

But **prototype-scoped beans are different**.

Spring creates and initializes prototype beans, but it does not automatically execute their destruction callbacks.

After handing a prototype bean to the caller, Spring generally leaves responsibility for its cleanup to the caller.

For request-scoped and session-scoped beans, destruction is tied to their respective scope lifecycle.

---

# 9. The Complete Spring Bean Lifecycle

Now that we've studied all three phases, here is the complete simplified lifecycle of a typical Spring singleton bean.

```
SPRING BOOT STARTUP
         |
         v
IoC Container Creation
         |
         v
Bean Definition Registration
         |
         v
BeanFactoryPostProcessor
         |
         v
========== PHASE 1: CREATION ==========
         |
         v
Bean Instantiation
(Constructor Injection)
         |
         v
Dependency Population
(Field / Setter Injection)
         |
         v
BeanNameAware / BeanFactoryAware
         |
         v
======= PHASE 2: INITIALIZATION =======
         |
         v
BeanPostProcessor
postProcessBeforeInitialization()
         |
         |-- ApplicationContextAware
         |-- @PostConstruct
         |
         v
Initializing
```



[[Spring Framework]]