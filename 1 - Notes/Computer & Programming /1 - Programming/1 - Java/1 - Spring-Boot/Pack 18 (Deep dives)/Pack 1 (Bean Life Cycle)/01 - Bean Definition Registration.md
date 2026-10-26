

After Spring Boot creates the **IoC Container (**`**ApplicationContext**`**)**, Spring needs to discover which classes should be managed as beans. This is where **Component Scanning** comes in. Spring searches specific packages for classes annotated with `@Component`, `@Service`, `@Repository`, `@Controller`, and other component annotations.

When Spring discovers these classes, it registers their **[^1]Bean Definitions** inside the IoC Container. Remember, at this stage, Spring is generally **not creating the actual application objects yet**. It is collecting the metadata (instructions) needed to create and manage them later.

## 1. How Does Component Scanning Start?

When you write:

```java
@SpringBootApplication
public class MyApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

The `@SpringBootApplication` annotation includes three important annotations:

```
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan
```

The `@ComponentScan` annotation tells Spring to search for components in the package containing your main application class ***and its subpackages by default***.

For example:

```
com.example.myapp
│
├── MyApplication.java
│
├── controller/
│   └── UserController.java
│
├── service/
│   └── UserService.java
│
└── repository/
    └── UserRepository.java
```

Spring automatically scans these packages because they are located under `com.example.myapp`.

## 2. Which Annotations Does Spring Discover?

|Annotation|Purpose|
|---|---|
|`@Component`|General-purpose Spring component|
|`@Service`|Business logic component|
|`@Repository`|Data access component|
|`@Controller`|Spring MVC controller|
|`@RestController`|REST controller|
|`@Configuration`|Class containing Spring configuration|

All these annotations are either directly or indirectly based on `@Component`, making their classes eligible for component scanning.

## 3. How Are Bean Definitions Registered?

Imagine we have this class:

```java
@Service
public class UserService {

    public void sayHello() {
        System.out.println("Hello!");
    }
}
```

During component scanning, Spring discovers `UserService` because of its `@Service` annotation.

Spring then registers a Bean Definition containing metadata such as:

```
Bean Definition
│
├── Bean Name: userService
├── Bean Class: UserService
├── Scope: singleton (default)
├── Lazy Initialization: false (default)
├── Autowiring Information
└── Other Configuration Metadata
```

The definition is registered in the container's internal **BeanDefinitionRegistry**, which is commonly implemented by `DefaultListableBeanFactory`.

At this point:

- Spring knows `UserService` exists.
    
- Spring knows how it should be created.
    
- Spring knows its scope and configuration.
    
- The actual `UserService` instance generally has not been created yet.
    

## 4. What About the @Bean Annotation?

Spring can also register Bean Definitions from `@Bean` methods.

```java
@Configuration
public class AppConfig {

    @Bean
    public UserService userService() {
        return new UserService();
    }
}
```

Here, component scanning discovers `AppConfig`, and Spring's configuration processing discovers the `@Bean` method and registers a Bean Definition for `userService`.

So **component scanning is one way to discover beans, but not the only way**.

## 5. What Happens Internally?

An important Spring component called `ConfigurationClassPostProcessor` processes configuration classes and their `@ComponentScan` instructions.

It implements `BeanDefinitionRegistryPostProcessor`, an extension of `BeanFactoryPostProcessor`, allowing it to register additional Bean Definitions.

The simplified flow is:

```
IoC Container Created
         |
         v
Configuration Processing Begins
         |
         v
@ComponentScan Is Processed
         |
         v
Spring Scans Packages
         |
         v
Discovers @Component, @Service, etc.
         |
         v
Registers Bean Definitions
         |
         v
Container Has Metadata About Beans
```

## 6. The Whole Picture

At the end of this stage, the IoC Container has a collection of **Bean Definitions** describing which beans it needs to manage and how.

One important distinction:

**Bean Definition Registration ≠ Bean Instantiation**

Registration means Spring knows _how to create_ an object. Instantiation means Spring actually _creates_ that object in memory.

Spring will use these definitions during the following stages of the lifecycle.


---
## BeanFactoryPostProcessor 

The `**BeanFactoryPostProcessor**` interface allows Spring to inspect or modify **Bean Definitions before actual bean objects are created**. During this stage, Spring registers Bean Definitions discovered through component scanning and other configuration mechanisms. After registration, Spring invokes `BeanFactoryPostProcessor` implementations to adjust their metadata if necessary. For example, you can change a bean's scope from `singleton` to `prototype`. **Important:** `BeanFactoryPostProcessor` does not create beans or modify actual bean instances; it works with their definitions.

## Example :

Imagine you have this service:

```java
@Service
public class UserService {
}
```

By default, Spring registers `UserService` as a **singleton**.

Now, let's modify its Bean Definition:

```java
@Component
public class CustomBeanFactoryPostProcessor
        implements BeanFactoryPostProcessor {

    @Override
    public void postProcessBeanFactory(
            ConfigurableListableBeanFactory beanFactory) {

        BeanDefinition definition =
                beanFactory.getBeanDefinition("userService");

        definition.setScope(BeanDefinition.SCOPE_PROTOTYPE);
    }
}
```

### What Happens?

1. Component scanning discovers `UserService`.
    
2. Spring registers its Bean Definition with singleton scope.
    
3. Spring invokes our `BeanFactoryPostProcessor`.
    
4. Our processor changes the scope to `prototype`.
    
5. Later, when Spring creates the bean, it follows the updated definition.
    

**Result:** Instead of managing one shared `UserService` instance, Spring now creates a new instance whenever that prototype bean is requested from the container.

**Remember:** `BeanFactoryPostProcessor` modifies the **instructions for creating beans**, not the beans themselves. Also, Spring uses its specialized `BeanDefinitionRegistryPostProcessor` extension during this broader stage to register additional definitions, including those discovered through component scanning.

---
In Spring, Lazy Initialization is a setting that tells the IoC Container not to create a bean immediately during application startup, but to create it only when it is first needed. By default, Spring eagerly creates singleton beans when the application context starts, even if they aren't used right away. However, when you use `@Lazy` or set `lazyInit(true)` in a Bean Definition, Spring delays creating that bean until something requests it. This can reduce startup time and memory usage, but it also means initialization errors might appear later when the bean is first used. Remember: Lazy initialization delays bean creation, not bean definition registration. Also, if a non-lazy singleton depends on a lazy bean, Spring may still create that bean during startup to satisfy the dependency.


[[Spring Framework]]

[^1]: In Spring, a Bean Definition is a set of metadata (instructions) that tells the Spring IoC Container how to create, configure, and manage a bean (an object managed by Spring). Think of it as a blueprint or recipe for an object, rather than the actual object itself. It contains information such as the bean's class, scope (singleton or prototype), dependencies, initialization methods, and other configuration details. When Spring starts, it discovers bean definitions through annotations like `@Component`, methods annotated with `@Bean`, or XML configuration, and registers them in the container. Spring then uses these definitions to create and manage the actual bean instances when needed. In simple terms, Bean Definition = instructions for creating and managing an object; Bean = the actual object managed by Spring.
