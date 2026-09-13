Date : 2025-09-02

In Spring Boot (and Spring Framework), **bean scopes** define the lifecycle and visibility of a bean managed by the Spring container. The scope determines how Spring creates, manages, and shares instances of a bean within the application context. The `@Scope` annotation, used in conjunction with `@Bean` or `@Component`, allows you to specify the scope of a bean. Below is a detailed explanation of bean scopes in Spring Boot, their types, and how they are configured, especially in the context of a configuration class with `@ComponentScan`.

### **What Are Bean Scopes?**
- A **bean scope** defines how long a bean lives, how many instances are created, and how those instances are shared across the application.
- By default, Spring beans are **singletons**, meaning a single instance is created and shared across the application context.
- Scopes can be customized to suit different use cases, such as creating a new instance for each request or maintaining a bean for the duration of a user session.

### **Available Bean Scopes in Spring**
Spring provides several built-in scopes, with additional scopes available in web applications. The main scopes are:

1. **Singleton (Default)**:
   - **Description**: A single instance of the bean is created per Spring IoC container (application context). This instance is shared across all requests for the bean.
   - **Use Case**: Suitable for stateless beans, such as services or repositories, where a single instance can handle all requests.
   - **Example**:
     ```java
     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         public GameService gameService() {
             return new GameService();
         }
     }
     ```
     - By default, `gameService` is a singleton. Only one instance is created and reused.

2. **Prototype**:
   - **Description**: A new instance of the bean is created each time it is requested or injected.
   - **Use Case**: Useful for stateful beans where each usage requires a fresh instance, such as temporary data holders or objects with changing state.
   - **Example**:
     ```java
     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         @Scope("prototype")
         public GameSession gameSession() {
             return new GameSession();
         }
     }
     ```
     - Each time `gameSession` is injected (e.g., via `@Autowired`), a new `GameSession` instance is created.
   - **Note**: Spring does not manage the full lifecycle of prototype beans (e.g., destruction callbacks are not called).

3. **Request (Web-Aware)**:
   - **Description**: A new instance of the bean is created for each HTTP request in a web application. The bean is available only for the duration of that request.
   - **Use Case**: Useful for web applications where you need a bean tied to a specific HTTP request, such as request-specific data.
   - **Example**:
     ```java
     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         @Scope("request")
         public RequestData requestData() {
             return new RequestData();
         }
     }
     ```
     - A new `RequestData` instance is created for each HTTP request.
   - **Requirement**: Requires a web-aware Spring application context (e.g., in a Spring Boot web application).

4. **Session (Web-Aware)**:
   - **Description**: A single instance of the bean is created for each HTTP session in a web application.
   - **Use Case**: Suitable for user-specific data that persists across multiple requests in a user session, such as user preferences or authentication details.
   - **Example**:
     ```java
     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         @Scope("session")
         public UserSession userSession() {
             return new UserSession();
         }
     }
     ```
     - A single `UserSession` instance is created per user session.

5. **Application (Web-Aware)**:
   - **Description**: A single instance of the bean is created for the entire lifecycle of the `ServletContext` in a web application.
   - **Use Case**: Useful for beans that need to be shared across the entire web application, such as configuration or global resources.
   - **Example**:
     ```java
     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         @Scope("application")
         public AppConfigData appConfigData() {
             return new AppConfigData();
         }
     }
     ```
     - The `appConfigData` bean is shared across the entire web application.

6. **WebSocket (Web-Aware)**:
   - **Description**: A single instance of the bean is created for the lifecycle of a WebSocket session.
   - **Use Case**: Used in WebSocket-based applications for beans tied to a WebSocket connection.
   - **Example**:
     ```java
     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         @Scope("websocket")
         public WebSocketSessionData webSocketSessionData() {
             return new WebSocketSessionData();
         }
     }
     ```
     - Requires a WebSocket-enabled Spring application.

7. **Custom Scopes**:
   - Spring allows you to define custom scopes by implementing the `org.springframework.beans.factory.config.Scope` interface.
   - Example use case: A custom scope for a multi-tenant application where beans are scoped to a specific tenant.

### **Configuring Bean Scopes**

1. **Using `@Scope` with `@Bean`**:
   - In a `@Configuration` class, you can specify the scope of a bean defined with `@Bean` using the `@Scope` annotation.
   - Example:
     ```java
     import org.springframework.context.annotation.Bean;
     import org.springframework.context.annotation.Configuration;
     import org.springframework.context.annotation.ComponentScan;
     import org.springframework.context.annotation.Scope;
     import com.Arcade.service.GameService;

     @Configuration
     @ComponentScan(basePackages = "com.Arcade")
     public class AppConfig {
         @Bean
         @Scope("prototype")
         public GameService gameService() {
             return new GameService();
         }
     }
     ```
     - The `gameService` bean is created as a new instance each time it is requested.

2. **Using `@Scope` with Component Scanning**:
   - When using `@ComponentScan`, you can apply `@Scope` to classes annotated with `@Component`, `@Service`, `@Repository`, or `@Controller`.
   - Example:
     ```java
     package com.Arcade.service;

     import org.springframework.context.annotation.Scope;
     import org.springframework.stereotype.Service;

     @Service
     @Scope("prototype")
     public class GameService {
         public void startGame() {
             System.out.println("New game started!");
         }
     }
     ```
     - With `@ComponentScan(basePackages = "com.Arcade")` in a `@Configuration` class, Spring detects `GameService` and creates a new instance each time it is injected.

3. **Using `ConfigurableBeanFactory` Constants**:
   - The `@Scope` annotation accepts scope names as strings, typically defined in `ConfigurableBeanFactory`:
     - `SCOPE_SINGLETON` ("singleton")
     - `SCOPE_PROTOTYPE` ("prototype")
   - Example:
     ```java
     @Bean
     @Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
     public GameService gameService() {
         return new GameService();
     }
     ```

4. **Proxy Mode for Web-Aware Scopes**:
   - For web-aware scopes (`request`, `session`, `application`, `websocket`), you may need to specify a proxy mode to handle dependencies correctly, especially when a singleton bean depends on a scoped bean.
   - Options for `proxyMode` in `@Scope`:
     - `ScopedProxyMode.TARGET_CLASS` (default): Creates a CGLIB proxy for the bean.
     - `ScopedProxyMode.INTERFACES`: Creates a JDK dynamic proxy if the bean implements an interface.
     - `ScopedProxyMode.NO`: No proxy is created (may cause issues if a singleton depends on a scoped bean).
   - Example:
     ```java
     @Bean
     @Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
     public RequestData requestData() {
         return new RequestData();
     }
     ```
     - This ensures that a proxy is used to resolve the `requestData` bean for each HTTP request.

### **Key Considerations for Bean Scopes**

1. **Default Scope**:
   - The default scope for all Spring beans is `singleton`. You must explicitly specify other scopes using `@Scope`.

2. **Lifecycle Management**:
   - **Singleton**: Fully managed by Spring (creation, initialization, destruction).
   - **Prototype**: Spring creates the bean but does not manage its destruction (e.g., no `@PreDestroy` callbacks).
   - **Web-Aware Scopes**: Managed for the duration of the request, session, or application lifecycle.

3. **Thread Safety**:
   - Singleton beans are shared across threads, so ensure they are thread-safe if used in a multi-threaded environment.
   - Prototype beans are not shared, so thread safety is less of a concern.

4. **Web-Aware Scopes**:
   - Scopes like `request`, `session`, and `application` require a web-aware application context (e.g., `AnnotationConfigWebApplicationContext` in a Spring Boot web application).
   - Ensure the `spring-web` dependency is included in your project:
     ```xml
     <dependency>
         <groupId>org.springframework</groupId>
         <artifactId>spring-web</artifactId>
         <version>${spring.version}</version>
     </dependency>
     ```

5. **Performance**:
   - **Singleton**: Most efficient, as only one instance is created.
   - **Prototype**: Can impact performance if many instances are created frequently.
   - **Web-Aware Scopes**: May introduce overhead due to proxy creation or lifecycle management.

6. **Dependencies Between Scopes**:
   - If a singleton bean depends on a prototype or web-aware scoped bean, use `ScopedProxyMode` or dependency injection techniques (e.g., `@Lookup` for prototype beans) to ensure the correct instance is injected.
   - Example:
     ```java
     @Service
     public class GameController {
         private final GameSession gameSession;

         @Autowired
         public GameController(@Qualifier("gameSession") GameSession gameSession) {
             this.gameSession = gameSession; // gameSession is prototype-scoped
         }
     }
     ```

### **Example in a Spring Boot Application**
Here’s a complete example combining `@ComponentScan` and different bean scopes in a `@Configuration` class:
```java
package com.Arcade.config;

import com.Arcade.service.GameService;
import com.Arcade.session.GameSession;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;

@Configuration
@ComponentScan(basePackages = "com.Arcade")
public class GameConfig {

    @Bean
    @Scope("singleton") // Explicitly specifying default scope
    public GameService gameService() {
        return new GameService();
    }

    @Bean
    @Scope("prototype")
    public GameSession gameSession() {
        return new GameSession();
    }

    @Bean
    @Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
    public RequestData requestData() {
        return new RequestData();
    }
}
```
```java
package com.Arcade.controller;

import com.Arcade.service.GameService;
import com.Arcade.session.GameSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;

@Controller
public class GameController {
    private final GameService gameService;
    private final GameSession gameSession;

    @Autowired
    public GameController(GameService gameService, GameSession gameSession) {
        this.gameService = gameService; // Singleton scope
        this.gameSession = gameSession; // Prototype scope (new instance per injection)
    }

    public void startGame() {
        gameService.startGame();
        gameSession.initSession();
    }
}
```
- **Explanation**:
  - `@ComponentScan("com.Arcade")` scans for components like `GameController` (annotated with `@Controller`).
  - `gameService` is a singleton bean (one instance shared across the application).
  - `gameSession` is a prototype bean (a new instance is created each time it’s injected).
  - `requestData` is a request-scoped bean (a new instance per HTTP request, with a proxy to handle injection into singleton beans).
  - `GameController` is auto-detected via `@ComponentScan` and can inject both `gameService` and `gameSession`.

### **Common Pitfalls**
1. **Prototype Scope Misuse**:
   - Injecting a prototype bean into a singleton bean without a proxy or `@Lookup` method can result in the same prototype instance being reused, defeating the purpose of the prototype scope.
2. **Web-Aware Scopes Without Web Context**:
   - Attempting to use `request`, `session`, or `application` scopes in a non-web application will throw an error.
3. **Missing Proxy for Scoped Beans**:
   - If a singleton bean depends on a request-scoped bean without `proxyMode`, you may get lifecycle errors.
4. **Overusing Prototype Scope**:
   - Creating many prototype beans can lead to memory or performance issues if not managed carefully.

### **Summary**
- **Bean Scopes**: Define the lifecycle and instantiation behavior of Spring beans (`singleton`, `prototype`, `request`, `session`, `application`, `websocket`, or custom).
- **Configuration**: Use `@Scope` with `@Bean` in a `@Configuration` class or with `@Component`, `@Service`, etc., in classes detected by `@ComponentScan`.
- **Singleton**: Default scope, one instance per container.
- **Prototype**: New instance per request.
- **Web-Aware Scopes**: Tied to HTTP request, session, or application lifecycle; require a web context and often a proxy.
- **Integration with `@ComponentScan`**: Automatically detected components can have their scopes defined with `@Scope`, while `@Bean` methods in a `@Configuration` class provide explicit scope control.
- Always consider the application’s requirements (e.g., stateless vs. stateful, web vs. non-web) when choosing a scope, and use `proxyMode` or other techniques to handle dependencies between beans of different scopes.




##### *Tags : [[0 - Spring Framework]]