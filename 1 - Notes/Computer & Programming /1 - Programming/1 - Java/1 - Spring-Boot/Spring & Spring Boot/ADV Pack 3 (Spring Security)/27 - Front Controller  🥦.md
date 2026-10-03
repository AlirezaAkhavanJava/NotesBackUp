
### What is the Front Controller in Spring Boot?

The **Front Controller** pattern is a central design pattern used in web applications where **a single servlet (or handler)** receives **all incoming HTTP requests** and delegates them to appropriate controllers/services. 

In Spring Boot (which is built on Spring MVC), the front controller is **DispatcherServlet**.

![[Pasted image 20251123113004.png]]

### DispatcherServlet – The Heart of Spring Boot Web Apps

```xml
<!-- In a traditional web.xml deployment (rare in Spring Boot) -->
<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>/WEB-INF/spring-mvc-config.xml</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
<servlet-mapping>
    <servlet-name>dispatcher</servlet-name>
    <url-pattern>/</url-pattern>   <!-- This makes it the front controller -->
</servlet-mapping>
```

But in **Spring Boot**, you almost never see `web.xml` or manual servlet registration because Spring Boot **auto-configures** the `DispatcherServlet` for you.

### How Spring Boot Sets Up the Front Controller Automatically

When you include `spring-boot-starter-web` dependency:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

Spring Boot does the following behind the scenes (`SpringBootServletInitializer` and auto-configuration):

1. Registers **DispatcherServlet** automatically.
2. Maps it to `/` (root path) → catches all requests.
3. Creates an application context and loads your `@Controller`, `@RestController`, beans, etc.
4. Configures essential components (HandlerMapping, HandlerAdapter, ViewResolver, etc.).

### Key Components That DispatcherServlet Uses

| Component                  | Role |
|----------------------------|------|
| HandlerMapping             | Maps request → controller method (e.g., `@RequestMapping("/users")`) |
| HandlerAdapter             | Executes the controller method (supports `@Controller`, functional endpoints, etc.) |
| HandlerExceptionResolver   | Handles exceptions (e.g., `@ExceptionHandler`, `@ControllerAdvice`) |
| ViewResolver               | Resolves logical view name → actual view (Thymeleaf, JSP, etc.) |
| LocaleResolver / ThemeResolver | Internationalization & theming |

### Typical Request Flow in Spring Boot

```
Client Request
     ↓
DispatcherServlet (Front Controller)
     ↓
┌─────────────────────────────┐
│ 1. HandlerMapping           │ → finds @RequestMapping method
│ 2. HandlerAdapter           │ → invokes controller method
│ 3. Controller returns       │ → ModelAndView or @ResponseBody (JSON)
│ 4. ViewResolver (if needed) │ → resolves view (e.g., Thymeleaf template)
│ 5. Response rendered        │
└─────────────────────────────┘
     ↓
Response to Client
```

### Customizing the DispatcherServlet in Spring Boot (Optional)

Most apps don’t need this, but you can customize it:

```java
@Bean
public DispatcherServlet dispatcherServlet() {
    DispatcherServlet servlet = new DispatcherServlet();
    servlet.setThrowExceptionIfNoHandlerFound(true); // useful for custom 404
    return servlet;
}

@Bean
public ServletRegistrationBean<DispatcherServlet> dispatcherServletRegistration(
        DispatcherServlet dispatcherServlet) {
    ServletRegistrationBean<DispatcherServlet> registration =
            new ServletRegistrationBean<>(dispatcherServlet, "/api/*"); // change base path
    registration.setName("dispatcherServlet");
    return registration;
}
```

### Common Questions

| Question                                | Answer |
|----------------------------------------|--------|
| Can I have multiple DispatcherServlets? | Yes (e.g., one for `/api/*`, one for web UI), but rare in Spring Boot |
| Is DispatcherServlet thread-safe?      | Yes – it’s a single instance, but all components it uses must be thread-safe |
| What replaced web.xml in Spring Boot?   | `WebMvcConfigurer`, `@Configuration` classes, and auto-configuration |

### Summary

- Spring Boot’s **front controller** = **DispatcherServlet**
- It’s **automatically configured** when you use `spring-boot-starter-web`
- It intercepts **all requests** (mapped to `/`) and routes them to your `@Controller`/`@RestController` methods
- You rarely touch it directly – Spring Boot handles everything for you




##### Tags [[1 - Spring Security 🍌]]