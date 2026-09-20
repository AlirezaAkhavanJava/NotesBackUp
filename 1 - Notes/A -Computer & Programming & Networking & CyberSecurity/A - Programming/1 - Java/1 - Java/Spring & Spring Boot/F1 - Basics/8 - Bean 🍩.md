Date : 2025-08-24
Concept : Spring boot beans
Tags : [[0 - Spring Framework]]

### What is a Bean ? 

*A **bean** is simply an object that is instantiated, assembled, and managed by the **Spring IoC Container**. In a Spring application, the objects that form the backbone of your business logic and application components are typically managed as beans.*

*The container is responsible for the entire **lifecycle** of a bean, from its creation and dependency injection to its destruction. This central management is the foundation of Spring's Inversion of Control (IoC) principle.*

----

### Ways to Create a Bean

There are two primary ways to create and register a bean in Spring:

1. **Annotation-based Configuration**: This is the most common and modern approach. You annotate a class or a method with a stereotype annotation, and Spring automatically discovers and manages it as a bean.
    
    - **Stereotype Annotations**: You place these annotations on a class to mark it as a Spring component. Spring's **component scanning** feature automatically finds and registers these classes as beans.
        
        - `@Component`: A generic annotation for any Spring-managed component.
            
        - `@Service`: A specialized `@Component` for the service layer, typically containing business logic.
            
        - `@Repository`: A specialized `@Component` for the data access layer (DAO), used for database interaction.
            
        - `@Controller` and `@RestController`: Specialized `@Component` for the web layer, handling incoming requests.
            


2. **Java-based Configuration**: This approach involves creating a **configuration class** that manually defines beans using methods. It's often used when you need to create beans from third-party libraries or when you need more control over the bean's creation logic.
    
    - **`@Configuration`**: You annotate a class with `@Configuration` to indicate that it's a source of bean definitions.
        
    - **`@Bean`**: You annotate a *method* within a `@Configuration` class with `@Bean`. The method's return value will be registered as a Spring bean, and the method name will be the default bean name.


``` java
// Java-based Configuration
@Configuration
public class AppConfig {

    @Bean
    public MyService myService() {
        return new MyServiceImpl();
    }
}
```

