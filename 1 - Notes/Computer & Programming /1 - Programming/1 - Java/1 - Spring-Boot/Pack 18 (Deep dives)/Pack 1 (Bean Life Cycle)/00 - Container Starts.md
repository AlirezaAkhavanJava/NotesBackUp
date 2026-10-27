

When you run your Spring Boot application, Spring Boot begins its [^2]startup process and creates the **IoC Container**, usually represented by an `ApplicationContext` object. This container is responsible for creating, configuring, managing, and eventually destroying Spring beans. At this stage, Spring is preparing the environment where all your application's beans will live.

![[Spring ApplicationContext Lifecycle Infographic.png]]

### How Does It Start?

```java
@SpringBootApplication
public class MyApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

When [^3]`SpringApplication.run()` executes, Spring Boot:

1. Prepares the application environment, including configuration properties and profiles.
    
2. Creates an appropriate `ApplicationContext` [^1]implementation.
    
3. Prepares the container for the next stages of initialization.
    

**Important:** Creating the container does not mean all beans have already been instantiated. Spring still needs to register their definitions, process configuration, and initialize beans.

**Remember:** The IoC Container is the manager, while beans are the objects it manages.



[[Spring Framework]]

[^1]: AnnotationConfigServletWebServerApplicationContext

[^2]: When you start a Spring Boot application, Java first executes the `main()` method, which calls `SpringApplication.run()`, and that's where the magic begins! Spring Boot prepares the application's Environment (configuration properties, profiles, environment variables, etc.), creates the ApplicationContext (the Spring IoC container), and scans your application to discover components and configuration classes. Next, Spring processes BeanDefinitions, creates and configures beans, performs Dependency Injection, and executes their initialization lifecycle (including `BeanPostProcessor` callbacks and `@PostConstruct`). During this process, Auto-Configuration helps configure things like DataSources, Spring MVC, and Spring Security based on your dependencies and settings. If it's a web application, Spring Boot also starts the embedded web server (such as Tomcat) as part of refreshing the context. Finally, it executes any `ApplicationRunner` or `CommandLineRunner` beans, publishes the `ApplicationReadyEvent`, and your application is officially ready to receive HTTP requests! In simple terms, Spring Boot takes your Java application, prepares its configuration, builds and connects its objects, initializes its infrastructure, and brings everything to life.

[^3]: `SpringApplication.run(MyApplication.class, args);` is the fundamental bootstrap method that launches a Spring Boot application from its standard Java `main` method. By passing `MyApplication.class`, you provide Spring with the primary configuration source to establish the root Application Context and determine the base package for component scanning, while the `args` array feeds command-line arguments directly into the Spring Environment. Behind the scenes, this single line of code performs immense heavy lifting: it initializes the Inversion of Control (IoC) container, triggers Spring Boot's auto-configuration based on your classpath dependencies, instantiates and wires all your beans, and starts an embedded web server (like Tomcat) if applicable, ultimately transforming a basic Java program into a fully configured, production-ready service.
