
Date : 2025-08-24
Concept : Spring boot starter and components
Course : [Tulesko](https://www.youtube.com/watch?v=-Fe0zk-F4OA&t=29s)
Tags : [[0 - Spring Framework]]

### Ways to Create a Spring Container

In a typical Spring Boot application, you don't manually create the Spring container. It's automatically created and configured for you by the `SpringApplication.run()` method. However, for a more traditional Spring application, there are a few ways to create the container:

- **`AnnotationConfigApplicationContext`**: This is the most common way to create a container in a modern, annotation-driven Spring application. It takes one or more configuration classes marked with `@Configuration` as input.

- **`ClassPathXmlApplicationContext`**: Used for older, XML-based configurations. It loads the container's definitions from an XML file located on the classpath.

- **`FileSystemXmlApplicationContext`**: Similar to the above, but it loads the configuration from a file on the file system instead of the classpath.

---

##### `SpringApplication.run(DeveloperApplication.class, args);`

The `SpringApplication.run()` method is the heart of a Spring Boot application. It does much more than just create a container. It's a static method that bootstraps and launches a Spring application from the main method.

Here's a breakdown of what it does:

1. **Creates the Application Context**: It creates an `ApplicationContext`, which is the Spring container. The `DeveloperApplication.class` argument tells Spring which class to use as the primary source for the application's configuration.

2. **Performs Auto-Configuration**: It scans your classpath and configuration files and automatically configures your application based on the dependencies you've included in your project (e.g., if you have `spring-boot-starter-web` on your classpath, it automatically configures an embedded Tomcat server).

3. **Starts the Application**: It refreshes the context and starts the application, including any embedded servers (like Tomcat or Netty).

4. **Enables a Fluent API**: The method returns a fully configured `ApplicationContext` that you can use to programmatically access and manage your beans. The `args` parameter is used to pass command-line arguments into the application.

---
### Where the Spring Container is Created

The **Spring IoC Container**, like any other Java object, is created within the **Heap memory** of the JVM. When the `SpringApplication.run()` method is called in a Spring Boot application, it creates an `ApplicationContext` object, which is the actual container. This object and all the **beans** (the components it manages) are allocated memory in the Heap.

Since the Heap is a shared memory area, all the threads in the JVM can access the Spring container and its beans, which is essential for a web application where different requests are handled by different threads.

---

While Spring's dependency injection (DI) is the preferred way to get references to beans, there are times when you may need a direct reference to the Spring container, or `ApplicationContext`. This is generally discouraged as it tightly couples your code to the Spring framework, but it's a useful technique for specific situations, like legacy code integration or accessing beans dynamically.

### Ways to Get a Reference to the `ApplicationContext`

1. **Dependency Injection (`@Autowired`)**: The most straightforward way in a Spring-managed component is to simply inject the `ApplicationContext` itself. Spring recognizes the `ApplicationContext` as a special bean and will automatically inject a reference to it.

```
@Service
public class MyService {
    @Autowired
    private ApplicationContext applicationContext;
    public void doSomething() {
        MyOtherBean bean = applicationContext.getBean(MyOtherBean.class);
        // Use the bean
    }
}
```

2. **Implementing `ApplicationContextAware`**: Any bean that implements the `ApplicationContextAware` interface will have its `setApplicationContext()` method called by the Spring container during its lifecycle. This allows the bean to hold a reference to the container.


```
@Component
public class ApplicationContextProvider implements ApplicationContextAware {
    private static ApplicationContext applicationContext;
    @Override
    public void setApplicationContext(ApplicationContext context) throws BeansException {
        this.applicationContext = context;
    }
    public static ApplicationContext getApplicationContext() {
        return applicationContext;
    }
}
```

3. **From `SpringApplication.run()`**: In your main application class, the `run()` method returns a reference to the `ApplicationContext`. You can capture and use this reference directly.


```
@SpringBootApplication
public class MyApplication {
    public static void main(String[] args) {
        ApplicationContext context = SpringApplication.run(MyApplication.class, args);
        // Use the 'context' reference here
        MyOtherBean bean = context.getBean(MyOtherBean.class);
    }
}
```