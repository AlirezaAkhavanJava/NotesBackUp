
## Overview

**Microservices** are an architectural style where an application is broken into small, independent services that communicate over a network. **Spring Boot** and **Spring Cloud** simplify building microservices by providing tools for configuration management, service discovery, and inter-service communication. This guide focuses on splitting a monolithic Todo application into microservices using **Spring Cloud Config** for centralized configuration and **Eureka** for service discovery.

**Why Use Microservices?**

- **Scalability**: Scale individual services independently.
- **Independent Deployments**: Deploy services without affecting others.
- **Resilience**: Isolate failures to specific services.
- **Flexibility**: Use different technologies for each service.

**How It Works**:

- Use `spring-boot-starter` for core microservices.
- Add `spring-cloud-starter-config` for centralized configuration.
- Use `spring-cloud-starter-netflix-eureka-client` and `spring-cloud-starter-netflix-eureka-server` for service discovery.
- Communicate between services using REST or messaging.

**Resources**:

- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- _Spring Microservices in Action_ by John Carnell
- [Baeldung: Spring Cloud](https://www.baeldung.com/spring-cloud)

**Prerequisites**:

- Completion of steps 1-10 (Spring MVC, Security, AOP, Actuator, Messaging).
- Basic understanding of microservices concepts (e.g., service boundaries, REST APIs).

**Practice Goal**: Split the Todo application into two microservices: **Todo Service** (manages todos) and **User Service** (manages users). Use Spring Cloud Config for configuration and Eureka for service discovery. Communicate between services via REST.

---

## Microservices Architecture

### Monolith vs. Microservices

- **Monolith**: Single codebase with all functionality (e.g., Todo app with UI, business logic, and data access).
- **Microservices**: Independent services, each handling a specific domain (e.g., Todo Service for tasks, User Service for authentication).

### Components

1. **Todo Service**: Manages `Todo` entities and exposes REST endpoints.
2. **User Service**: Manages `User` entities and provides user information.
3. **Config Server**: Centralizes configuration for both services.
4. **Eureka Server**: Registers services for discovery and load balancing.
5. **REST Communication**: Todo Service queries User Service for user details.

---

## Setting Up the Microservices

### Project Structure

```
todo-microservices/
├── config-server/
│   ├── src/main/java/com/example/configserver/
│   ├── src/main/resources/application.properties
│   ├── pom.xml
├── eureka-server/
│   ├── src/main/java/com/example/eurekaserver/
│   ├── src/main/resources/application.properties
│   ├── pom.xml
├── todo-service/
│   ├── src/main/java/com/example/todoservice/
│   ├── src/main/resources/bootstrap.yml
│   ├── pom.xml
├── user-service/
│   ├── src/main/java/com/example/userservice/
│   ├── src/main/resources/bootstrap.yml
│   ├── pom.xml
├── config-repo/
│   ├── todo-service.yml
│   ├── user-service.yml
```

### 1. Config Server

Centralizes configuration for microservices.

#### `config-server/pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>config-server</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-config-server</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>2023.0.3</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

#### `config-server/src/main/resources/application.properties`

```properties
spring.application.name=config-server
server.port=8888
spring.cloud.config.server.git.uri=file:///${user.home}/config-repo
```

#### `config-server/src/main/java/com/example/configserver/ConfigServerApplication.java`

```java
package com.example.configserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
```

#### Configuration Repository (`config-repo/`)

- Create a `config-repo` directory in your home directory.
- Add `todo-service.yml`:
    
    ```yaml
    spring:
      datasource:
        url: jdbc:h2:mem:tododb
        driverClassName: org.h2.Driver
        username: sa
        password:
      jpa:
        database-platform: org.hibernate.dialect.H2Dialect
        hibernate:
          ddl-auto: update
    eureka:
      client:
        service-url:
          defaultZone: http://localhost:8761/eureka/
    ```
    
- Add `user-service.yml`:
    
    ```yaml
    spring:
      datasource:
        url: jdbc:h2:mem:userdb
        driverClassName: org.h2.Driver
        username: sa
        password:
      jpa:
        database-platform: org.hibernate.dialect.H2Dialect
        hibernate:
          ddl-auto: update
    eureka:
      client:
        service-url:
          defaultZone: http://localhost:8761/eureka/
    ```
    

**Notes**:

- `@EnableConfigServer`: Enables the Config Server.
- `spring.cloud.config.server.git.uri`: Points to a local Git repository (replace with a remote repo in production).

### 2. Eureka Server

Handles service discovery.

#### `eureka-server/pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>eureka-server</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>2023.0.3</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

#### `eureka-server/src/main/resources/application.properties`

```properties
spring.application.name=eureka-server
server.port=8761
eureka.client.register-with-eureka=false
eureka.client.fetch-registry=false
```

#### `eureka-server/src/main/java/com/example/eurekaserver/EurekaServerApplication.java`

```java
package com.example.eurekaserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
```

**Notes**:

- `@EnableEurekaServer`: Enables the Eureka Server.
- `register-with-eureka=false`: Prevents the server from registering itself.

### 3. Todo Service

Manages `Todo` entities and queries User Service.

#### `todo-service/pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-service</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-config</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>2023.0.3</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

#### `todo-service/src/main/resources/bootstrap.yml`

```yaml
spring:
  application:
    name: todo-service
  cloud:
    config:
      uri: http://localhost:8888
```

#### `todo-service/src/main/java/com/example/todoservice/model/Todo.java`

```java
package com.example.todoservice.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Todo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private boolean completed;
    private Long userId;

    public Todo() {}

    public Todo(String title, boolean completed, Long userId) {
        this.title = title;
        this.completed = completed;
        this.userId = userId;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
}
```

#### `todo-service/src/main/java/com/example/todoservice/repository/TodoRepository.java`

```java
package com.example.todoservice.repository;

import com.example.todoservice.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, Long> {
}
```

#### `todo-service/src/main/java/com/example/todoservice/model/User.java`

```java
package com.example.todoservice.model;

public class User {
    private Long id;
    private String username;

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}
```

#### `todo-service/src/main/java/com/example/todoservice/service/TodoService.java`

```java
package com.example.todoservice.service;

import com.example.todoservice.model.Todo;
import com.example.todoservice.model.User;
import com.example.todoservice.repository.TodoRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Service
public class TodoService {
    private final TodoRepository todoRepository;
    private final WebClient webClient;

    public TodoService(TodoRepository todoRepository, WebClient.Builder webClientBuilder) {
        this.todoRepository = todoRepository;
        this.webClient = webClientBuilder.baseUrl("http://user-service").build();
    }

    public Todo createTodo(Todo todo) {
        // Validate user exists
        Mono<User> user = webClient.get()
                .uri("/api/users/{id}", todo.getUserId())
                .retrieve()
                .bodyToMono(User.class);
        user.block(); // For simplicity; use reactive in production
        return todoRepository.save(todo);
    }
}
```

#### `todo-service/src/main/java/com/example/todoservice/controller/TodoController.java`

```java
package com.example.todoservice.controller;

import com.example.todoservice.model.Todo;
import com.example.todoservice.service.TodoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/todos")
public class TodoController {
    private final TodoService todoService;

    public TodoController(TodoService todoService) {
        this.todoService = todoService;
    }

    @PostMapping
    public ResponseEntity<Todo> createTodo(@RequestBody Todo todo) {
        return new ResponseEntity<>(todoService.createTodo(todo), HttpStatus.CREATED);
    }
}
```

#### `todo-service/src/main/java/com/example/todoservice/TodoServiceApplication.java`

```java
package com.example.todoservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.web.reactive.function.client.WebClient;

@SpringBootApplication
public class TodoServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoServiceApplication.class, args);
    }

    @Bean
    @LoadBalanced
    public WebClient.Builder webClientBuilder() {
        return WebClient.builder();
    }
}
```

**Notes**:

- `spring-cloud-starter-config`: Fetches configuration from Config Server.
- `spring-cloud-starter-netflix-eureka-client`: Registers with Eureka.
- `WebClient`: Makes REST calls to User Service, using Eureka for service discovery.
- `@LoadBalanced`: Enables client-side load balancing via Eureka.

### 4. User Service

Manages `User` entities.

#### `user-service/pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>user-service</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-config</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>2023.0.3</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

#### `user-service/src/main/resources/bootstrap.yml`

```yaml
spring:
  application:
    name: user-service
  cloud:
    config:
      uri: http://localhost:8888
```

#### `user-service/src/main/java/com/example/userservice/model/User.java`

```java
package com.example.userservice.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String username;

    public User() {}

    public User(String username) {
        this.username = username;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}
```

#### `user-service/src/main/java/com/example/userservice/repository/UserRepository.java`

```java
package com.example.userservice.repository;

import com.example.userservice.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
}
```

#### `user-service/src/main/java/com/example/userservice/service/UserService.java`

```java
package com.example.userservice.service;

import com.example.userservice.model.User;
import com.example.userservice.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    public User createUser(User user) {
        return userRepository.save(user);
    }
}
```

#### `user-service/src/main/java/com/example/userservice/controller/UserController.java`

```java
package com.example.userservice.controller;

import com.example.userservice.model.User;
import com.example.userservice.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) {
        return new ResponseEntity<>(userService.createUser(user), HttpStatus.CREATED);
    }
}
```

#### `user-service/src/main/java/com/example/userservice/UserServiceApplication.java`

```java
package com.example.userservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class UserServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }
}
```

---

## Running and Testing the Application

### 1. Setup Config Repository

- Create a `config-repo` directory in your home directory.
- Add `todo-service.yml` and `user-service.yml` as shown above.
- Initialize as a Git repository:
    
    ```bash
    cd ~/config-repo
    git init
    git add .
    git commit -m "Initial config"
    ```
    

### 2. Start Services

Run each service in a separate terminal:

1. **Config Server**:
    
    ```bash
    cd config-server
    mvn spring-boot:run
    ```
    
    - Access: `http://localhost:8888/todo-service/default` (returns `todo-service.yml`).
2. **Eureka Server**:
    
    ```bash
    cd eureka-server
    mvn spring-boot:run
    ```
    
    - Access: `http://localhost:8761` (Eureka dashboard).
3. **User Service**:
    
    ```bash
    cd user-service
    mvn spring-boot:run
    ```
    
    - Runs on a random port (check Eureka dashboard).
4. **Todo Service**:
    
    ```bash
    cd todo-service
    mvn spring-boot:run
    ```
    
    - Runs on a random port (check Eureka dashboard).

### 3. Test with Postman

1. **Create a User**:
    
    ```bash
    curl -X POST http://localhost:8081/api/users \
    -H "Content-Type: application/json" \
    -d '{"username":"john"}'
    ```
    
    **Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "username": "john"
    }
    ```
    
2. **Create a Todo**:
    
    ```bash
    curl -X POST http://localhost:8082/api/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"Learn Microservices","completed":false,"userId":1}'
    ```
    
    **Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "title": "Learn Microservices",
        "completed": false,
        "userId": 1
    }
    ```
    
3. **Verify in Eureka**:
    
    - Access `http://localhost:8761` to confirm `todo-service` and `user-service` are registered.
4. **Test Invalid User**:
    
    ```bash
    curl -X POST http://localhost:8082/api/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"Invalid User","completed":false,"userId":999}'
    ```
    
    **Response**: HTTP 500 (User not found).
    

---

## How It Works

1. **Config Server**:
    
    - Hosts centralized configuration in `config-repo`.
    - Services fetch their configs (`todo-service.yml`, `user-service.yml`) via `spring.cloud.config.uri`.
2. **Eureka Server**:
    
    - Acts as a registry for microservices.
    - `todo-service` and `user-service` register with Eureka, allowing dynamic discovery.
3. **Todo Service**:
    
    - Manages `Todo` entities with a `userId` field.
    - Uses `WebClient` with `@LoadBalanced` to call `user-service` via Eureka (e.g., `http://user-service/api/users/{id}`).
    - Validates user existence before saving a todo.
4. **User Service**:
    
    - Manages `User` entities and exposes REST endpoints.
    - Persists data to an H2 database.
5. **Communication**:
    
    - Todo Service queries User Service via REST to validate `userId`.
    - Eureka resolves `user-service` to the correct host/port.

**Flow**:

- POST `/api/todos` → Todo Service → Checks user via `WebClient` to `user-service` → Saves todo if user exists.
- Config Server provides configurations.
- Eureka enables service discovery.

---

## Advanced Features

1. **Circuit Breaker** (with Resilience4j):  
    Add `spring-cloud-starter-circuitbreaker-resilience4j` to handle User Service failures:
    
    ```xml
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
    </dependency>
    ```
    
    Update `TodoService`:
    
    ```java
    @CircuitBreaker(name = "userService", fallbackMethod = "fallback")
    public Todo createTodo(Todo todo) {
        Mono<User> user = webClient.get()
                .uri("/api/users/{id}", todo.getUserId())
                .retrieve()
                .bodyToMono(User.class);
        user.block();
        return todoRepository.save(todo);
    }
    
    public Todo fallback(Todo todo, Throwable t) {
        return todoRepository.save(new Todo(todo.getTitle(), todo.isCompleted(), -1L));
    }
    ```
    
2. **Distributed Tracing** (with Sleuth and Zipkin):  
    Add dependencies:
    
    ```xml
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-sleuth</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-zipkin</artifactId>
    </dependency>
    ```
    
    Run Zipkin:
    
    ```bash
    docker run -d -p 9411:9411 openzipkin/zipkin
    ```
    
    Access traces at `http://localhost:9411`.
    
3. **API Gateway**:  
    Use Spring Cloud Gateway to route requests:
    
    ```xml
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-gateway</artifactId>
    </dependency>
    ```
    

---

## Best Practices

- **Single Responsibility**: Each service handles one domain (e.g., todos, users).
- **Configuration Management**: Use Config Server for centralized, versioned configs.
- **Service Discovery**: Use Eureka for dynamic service resolution.
- **Resilience**: Implement circuit breakers and retries.
- **Testing**:
    
    ```java
    @SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
    class TodoServiceTest {
        @Autowired
        private TestRestTemplate restTemplate;
    
        @Test
        void testCreateTodo() {
            ResponseEntity<Todo> response = restTemplate.postForEntity("/api/todos",
                    new Todo("Test", false, 1L), Todo.class);
            assertEquals(HttpStatus.CREATED, response.getStatusCode());
        }
    }
    ```
    

---

## Conclusion

Spring Boot and Spring Cloud simplify microservices development with tools like Config Server and Eureka. The Todo application is split into Todo Service and User Service, using centralized configuration and service discovery. REST communication enables loose coupling, while advanced features like circuit breakers enhance resilience. Explore Spring Cloud’s additional tools (e.g., Gateway, Sleuth) for production-ready microservices.


[[0 - Spring Framework]]