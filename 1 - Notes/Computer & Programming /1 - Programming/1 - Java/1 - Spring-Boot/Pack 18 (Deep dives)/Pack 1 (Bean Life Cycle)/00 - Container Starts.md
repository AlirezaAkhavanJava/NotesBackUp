

When you run your Spring Boot application, Spring Boot begins its startup process and creates the **IoC Container**, usually represented by an `ApplicationContext` object. This container is responsible for creating, configuring, managing, and eventually destroying Spring beans. At this stage, Spring is preparing the environment where all your application's beans will live.

### How Does It Start?

```java
@SpringBootApplication
public class MyApplication {

    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

When `SpringApplication.run()` executes, Spring Boot:

1. Prepares the application environment, including configuration properties and profiles.
    
2. Creates an appropriate `ApplicationContext` [^1]implementation.
    
3. Prepares the container for the next stages of initialization.
    

**Important:** Creating the container does not mean all beans have already been instantiated. Spring still needs to register their definitions, process configuration, and initialize beans.

**Remember:** The IoC Container is the manager, while beans are the objects it manages.



[[Spring Framework]]

[^1]: AnnotationConfigServletWebServerApplicationContext