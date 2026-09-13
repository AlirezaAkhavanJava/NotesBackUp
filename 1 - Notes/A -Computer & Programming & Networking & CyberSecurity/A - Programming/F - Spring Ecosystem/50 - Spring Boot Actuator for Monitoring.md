
## Overview

**Spring Boot Actuator** is a module of Spring Boot that provides production-ready features for monitoring and managing applications. It exposes endpoints for health checks, metrics, application information, and more, enabling developers to monitor application health and performance in production environments.

**Why Use Spring Boot Actuator?**

- **Health Monitoring**: Check the status of application components (e.g., database, disk space).
- **Metrics Collection**: Gather performance metrics (e.g., CPU, memory, request counts).
- **Production Readiness**: Integrates with tools like Prometheus for observability.
- **Troubleshooting**: Provides insights into application behavior and configuration.

**How It Works**:

- Add `spring-boot-starter-actuator` to enable Actuator endpoints.
- Access endpoints like `/actuator/health`, `/actuator/metrics`, etc.
- Customize health checks and integrate with monitoring tools like Prometheus.

**Resources**:

- [Spring Boot Actuator Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- _Spring in Action_ by Craig Walls (Chapter 5)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)

**Prerequisites**:

- Basic Spring Boot knowledge (e.g., REST APIs, Spring Data JPA).
- Familiarity with HTTP and REST endpoints.

**Practice Goal**: Enhance the Todo API (from previous steps) by adding Spring Boot Actuator to expose `/actuator/health` and `/actuator/metrics` endpoints, customize a health check, and integrate with a simple Prometheus setup for metrics monitoring.

---

## Setting Up Spring Boot Actuator

### 1. Project Setup

Extend the Todo API with Spring Boot Actuator and Micrometer for Prometheus integration.

#### `pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-actuator-app</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

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
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>
    </dependencies>

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

**Notes**:

- `spring-boot-starter-actuator`: Adds Actuator endpoints.
- `micrometer-registry-prometheus`: Enables Prometheus metrics export.
- Other dependencies support REST APIs and database operations.

### 2. Configure Application

Set up Actuator and H2 database in `src/main/resources/application.properties`.

```properties
spring.datasource.url=jdbc:h2:mem:tododb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.h2.console.enabled=true

# Actuator configuration
management.endpoints.web.exposure.include=health,metrics
management.endpoint.health.show-details=always
management.metrics.tags.application=todo-app
```

**Notes**:

- `management.endpoints.web.exposure.include`: Exposes `/actuator/health` and `/actuator/metrics`.
- `management.endpoint.health.show-details=always`: Shows detailed health information.
- `management.metrics.tags.application`: Adds a custom tag for Prometheus metrics.

---

## Building the Todo Application with Actuator

### Project Structure

```
todo-actuator-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── com/example/
│   │   │   │   ├── TodoApplication.java
│   │   │   │   ├── model/
│   │   │   │   │   ├── Todo.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── TodoRepository.java
│   │   │   │   ├── controller/
│   │   │   │   │   ├── TodoController.java
│   │   │   │   ├── health/
│   │   │   │   │   ├── CustomHealthIndicator.java
│   │   ├── resources/
│   │   │   ├── application.properties
├── prometheus/
│   ├── prometheus.yml
├── pom.xml
```

### 1. Entity Class (`Todo.java`)

```java
package com.example.model;

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

    public Todo() {}

    public Todo(String title, boolean completed) {
        this.title = title;
        this.completed = completed;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }
}
```

### 2. Repository (`TodoRepository.java`)

```java
package com.example.repository;

import com.example.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, Long> {
}
```

### 3. Controller (`TodoController.java`)

```java
package com.example.controller;

import com.example.model.Todo;
import com.example.repository.TodoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/todos")
public class TodoController {
    private final TodoRepository todoRepository;

    public TodoController(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @GetMapping
    public List<Todo> getAllTodos() {
        return todoRepository.findAll();
    }

    @PostMapping
    public ResponseEntity<Todo> createTodo(@RequestBody Todo todo) {
        return new ResponseEntity<>(todoRepository.save(todo), HttpStatus.CREATED);
    }
}
```

### 4. Custom Health Indicator (`CustomHealthIndicator.java`)

Create a custom health check to monitor the number of todos.

```java
package com.example.health;

import com.example.repository.TodoRepository;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class CustomHealthIndicator implements HealthIndicator {
    private final TodoRepository todoRepository;

    public CustomHealthIndicator(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @Override
    public Health health() {
        long todoCount = todoRepository.count();
        if (todoCount > 100) {
            return Health.down()
                    .withDetail("reason", "Too many todos: " + todoCount)
                    .build();
        }
        return Health.up()
                .withDetail("todoCount", todoCount)
                .build();
    }
}
```

**Notes**:

- `HealthIndicator`: Defines a custom health check.
- Checks if the number of todos exceeds 100; if so, reports the application as "down."

### 5. Main Application (`TodoApplication.java`)

```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoApplication.class, args);
    }
}
```

---

## Integrating with Prometheus

### 1. Configure Prometheus

Create a `prometheus.yml` file in the `prometheus/` directory to scrape metrics from the application.

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'todo-app'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['localhost:8080']
        labels:
          application: 'todo-app'
```

### 2. Run Prometheus

- Download Prometheus from [prometheus.io](https://prometheus.io/download/).
- Run Prometheus with the configuration:
    
    ```bash
    ./prometheus --config.file=prometheus.yml
    ```
    
- Access Prometheus UI at `http://localhost:9090`.

### 3. Query Metrics

- Open `http://localhost:9090/graph`.
- Example queries:
    - `http_server_requests_seconds_count{application="todo-app"}`: Counts HTTP requests.
    - `jvm_memory_used_bytes{application="todo-app"}`: JVM memory usage.

---

## Running and Testing the Application

### 1. Run the Application

```bash
mvn spring-boot:run
```

### 2. Test Actuator Endpoints

Use a browser or cURL to access Actuator endpoints.

- **Health Endpoint**:
    
    ```bash
    curl http://localhost:8080/actuator/health
    ```
    
    **Response** (if todo count < 100):
    
    ```json
    {
        "status": "UP",
        "components": {
            "custom": {
                "status": "UP",
                "details": {
                    "todoCount": 0
                }
            },
            "db": {
                "status": "UP",
                "details": {
                    "database": "H2",
                    "validationQuery": "isValid()"
                }
            },
            "diskSpace": {
                "status": "UP",
                "details": {
                    "total": 1000000000,
                    "free": 900000000,
                    "threshold": 10485760
                }
            },
            "ping": {
                "status": "UP"
            }
        }
    }
    ```
    
- **Metrics Endpoint**:
    
    ```bash
    curl http://localhost:8080/actuator/metrics
    ```
    
    **Response** (partial):
    
    ```json
    {
        "names": [
            "application.ready.time",
            "http.server.requests",
            "jvm.memory.used",
            "jvm.threads.live"
        ]
    }
    ```
    
- **Specific Metric**:
    
    ```bash
    curl http://localhost:8080/actuator/metrics/http.server.requests
    ```
    
    **Response** (partial):
    
    ```json
    {
        "name": "http.server.requests",
        "measurements": [
            {
                "statistic": "COUNT",
                "value": 10
            },
            {
                "statistic": "TOTAL_TIME",
                "value": 0.123
            }
        ],
        "availableTags": [
            {
                "tag": "method",
                "values": ["GET", "POST"]
            },
            {
                "tag": "uri",
                "values": ["/api/todos"]
            }
        ]
    }
    ```
    
- **Prometheus Metrics**:
    
    ```bash
    curl http://localhost:8080/actuator/prometheus
    ```
    
    **Response** (partial):
    
    ```
    # HELP http_server_requests_seconds_count Total number of requests
    # TYPE http_server_requests_seconds_count counter
    http_server_requests_seconds_count{application="todo-app",method="GET",uri="/api/todos"} 5.0
    ```
    

### 3. Test Custom Health Check

- Add todos via POST requests until the count exceeds 100:
    
    ```bash
    for i in {1..101}; do
        curl -X POST http://localhost:8080/api/todos \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"Todo $i\",\"completed\":false}"
    done
    ```
    
- Check `/actuator/health`:
    
    ```bash
    curl http://localhost:8080/actuator/health
    ```
    
    **Response**:
    
    ```json
    {
        "status": "DOWN",
        "components": {
            "custom": {
                "status": "DOWN",
                "details": {
                    "reason": "Too many todos: 101"
                }
            },
            "db": {
                "status": "UP",
                "details": {
                    "database": "H2",
                    "validationQuery": "isValid()"
                }
            }
        }
    }
    ```
    

### 4. Test Prometheus

- Access `http://localhost:9090/graph`.
- Query `http_server_requests_seconds_count{application="todo-app"}` to see request counts.
- Verify that metrics are updated as you make API calls.

---

## How It Works

- **Spring Boot Actuator**:
    - Exposes endpoints like `/actuator/health` and `/actuator/metrics`.
    - `CustomHealthIndicator` checks the todo count and contributes to the health status.
- **Micrometer**:
    - Integrates with Actuator to export metrics in Prometheus format (`/actuator/prometheus`).
    - Adds application-specific tags (e.g., `application=todo-app`).
- **Prometheus**:
    - Scrapes metrics from `/actuator/prometheus` every 15 seconds.
    - Provides a UI to query and visualize metrics.

**Example Metrics**:

- `http_server_requests_seconds_count`: Tracks HTTP request counts.
- `jvm_memory_used_bytes`: Monitors JVM memory usage.

---

## Advanced Features

1. **Custom Metrics**:  
    Create a custom counter for todo creations:
    
    ```java
    @Service
    public class TodoService {
        private final TodoRepository todoRepository;
        private final MeterRegistry meterRegistry;
    
        public TodoService(TodoRepository todoRepository, MeterRegistry meterRegistry) {
            this.todoRepository = todoRepository;
            this.meterRegistry = meterRegistry;
        }
    
        public Todo saveTodo(Todo todo) {
            meterRegistry.counter("todo.created", "application", "todo-app").increment();
            return todoRepository.save(todo);
        }
    }
    ```
    
    Query in Prometheus: `todo_created_total{application="todo-app"}`.
    
2. **Secure Actuator Endpoints**:  
    Add Spring Security to restrict access:
    
    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    ```
    
    Configure `SecurityFilterChain`:
    
    ```java
    @Configuration
    @EnableWebSecurity
    public class SecurityConfig {
        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
            http
                .authorizeHttpRequests(authz -> authz
                    .requestMatchers("/actuator/health").permitAll()
                    .requestMatchers("/actuator/**").hasRole("ADMIN")
                    .anyRequest().authenticated()
                )
                .httpBasic();
            return http.build();
        }
    
        @Bean
        public UserDetailsService userDetailsService() {
            var admin = User.withUsername("admin")
                    .password("{noop}adminpass")
                    .roles("ADMIN")
                    .build();
            return new InMemoryUserDetailsManager(admin);
        }
    }
    ```
    
3. **Health Group**:  
    Group health checks for specific use cases:
    
    ```properties
    management.health.group.custom.include=custom,db
    ```
    
    Access: `curl http://localhost:8080/actuator/health/custom`.
    

---

## Best Practices

- **Expose Minimal Endpoints**: Only enable necessary endpoints (`health`, `metrics`) in production.
- **Secure Actuator**: Restrict access to sensitive endpoints (e.g., `/actuator/env`) with Spring Security.
- **Use Prometheus and Grafana**: Combine Prometheus with Grafana for advanced visualization.
- **Monitor Custom Metrics**: Add application-specific metrics for business logic.
- **Test Health Checks**:
    
    ```java
    @SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
    class ActuatorTest {
        @Autowired
        private TestRestTemplate restTemplate;
    
        @Test
        void testHealthEndpoint() {
            ResponseEntity<String> response = restTemplate.getForEntity("/actuator/health", String.class);
            assertEquals(HttpStatus.OK, response.getStatusCode());
            assertTrue(response.getBody().contains("\"status\":\"UP\""));
        }
    }
    ```
    

---

## Conclusion

Spring Boot Actuator provides essential tools for monitoring application health and performance through endpoints like `/actuator/health` and `/actuator/metrics`. By customizing health checks and integrating with Prometheus, you can gain deep insights into your application’s behavior. The Todo application demonstrates these capabilities, and advanced features like custom metrics and security enhance production readiness. Explore the Actuator and Prometheus documentation for further customization and monitoring strategies.


[[0 - Spring Framework]]