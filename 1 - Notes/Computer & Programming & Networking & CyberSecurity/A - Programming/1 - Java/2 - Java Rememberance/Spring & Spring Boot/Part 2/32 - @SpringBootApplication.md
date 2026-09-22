
`@SpringBootApplication` is a convenience annotation you put on your main class — the one with the `main()` method that starts your app. It's actually a combination of three other annotations bundled into one:

**1. `@SpringBootConfiguration`**  
Marks the class as a source of bean definitions for the application context. It's a specialized form of `@Configuration`, so you can define `@Bean` methods inside this class if you want.

**2. `@EnableAutoConfiguration`**  
This is the "magic" part. Spring Boot looks at the dependencies (jars) on your classpath and tries to automatically configure your application based on what it finds. For example, if it sees `spring-boot-starter-web` on the classpath, it auto-configures an embedded Tomcat server, Spring MVC, a `DispatcherServlet`, etc. This is what saves you from writing tons of XML or Java config by hand.

**3. `@ComponentScan`**  
Tells Spring to scan the current package and all sub-packages for components — classes annotated with `@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController`, etc. — and register them as beans in the application context.

### Typical usage

```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

Here, `SpringApplication.run(...)` bootstraps the app: it creates the `ApplicationContext`, triggers the auto-configuration, runs the component scan, and starts the embedded server if it's a web app.

### Why it matters for package placement

Because `@ComponentScan` scans the current package downward, it's a convention in Spring Boot to put your main class in the **root package** (e.g., `com.example.demo`), with everything else in sub-packages (`com.example.demo.controller`, `com.example.demo.service`, etc.). If you put it in a sub-package, classes in sibling packages won't get picked up automatically.




[[0 - Spring Framework]]
[[Java]]