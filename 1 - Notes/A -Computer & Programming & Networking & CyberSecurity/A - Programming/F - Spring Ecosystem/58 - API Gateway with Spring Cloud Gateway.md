# API Gateway with Spring Cloud Gateway

## Overview

**Spring Cloud Gateway** is a powerful, flexible API gateway built on Spring Boot and Spring WebFlux, designed to route requests, apply filters, and handle cross-cutting concerns like authentication, rate-limiting, and logging in microservices architectures. It acts as a single entry point for client requests, directing them to appropriate microservices while providing additional features like security and monitoring.

**Why Use Spring Cloud Gateway?**

- **Centralized Routing**: Simplifies client interaction by routing requests to multiple microservices.
- **Cross-Cutting Concerns**: Handles authentication, rate-limiting, and logging in one place.
- **Scalability**: Supports reactive, non-blocking request handling.
- **Integration**: Works seamlessly with Spring Cloud tools like Eureka for service discovery.

**How It Works**:

- Add `spring-cloud-starter-gateway` to your project.
- Configure routes to map incoming requests to microservices.
- Apply filters for tasks like authentication (e.g., JWT validation) or logging.
- Integrate with Eureka for dynamic service discovery.

**Resources**:

- [Spring Cloud Gateway Documentation](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)
- [Baeldung: Spring Cloud Gateway](https://www.baeldung.com/spring-cloud-gateway)
- _Spring Microservices in Action_ by John Carnell (Chapter 6)

**Prerequisites**:

- Familiarity with Spring Boot, Spring Cloud, and microservices concepts.
- Existing microservices (e.g., Todo Service and User Service from previous steps).
- Basic understanding of JWT (JSON Web Tokens) for authentication.

**Practice Goal**: Set up a Spring Cloud Gateway to route requests to the Todo Service and User Service, integrating with Eureka for service discovery. Add a custom JWT validation filter to secure endpoints.

---

## Setting Up Spring Cloud Gateway

### Project Structure

Extend the microservices architecture from the previous step by adding a gateway service:

```
todo-microservices/
├── config-server/
├── eureka-server/
├── todo-service/
├── user-service/
├── gateway-service/
│   ├── src/main/java/com/example/gateway/
│   ├── src/main/resources/bootstrap.yml
│   ├── pom.xml
├── config-repo/
│   ├── todo-service.yml
│   ├── user-service.yml
│   ├── gateway-service.yml
```

### 1. Gateway Service Setup

#### `gateway-service/pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>gateway-service</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-config</artifactId>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt</artifactId>
            <version>0.12.6</version>
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

**Notes**:

- `spring-cloud-starter-gateway`: Provides gateway functionality.
- `spring-cloud-starter-netflix-eureka-client`: Enables service discovery with Eureka.
- `spring-cloud-starter-config`: Fetches configuration from Config Server.
- `jjwt`: Handles JWT validation.

#### `gateway-service/src/main/resources/bootstrap.yml`

```yaml
spring:
  application:
    name: gateway-service
  cloud:
    config:
      uri: http://localhost:8888
```

#### `config-repo/gateway-service.yml`

Add to the `config-repo` directory:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: todo-service
          uri: lb://todo-service
          predicates:
            - Path=/api/todos/**
          filters:
            - AddRequestHeader=X-Request-Source, Gateway
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/users/**
          filters:
            - AddRequestHeader=X-Request-Source, Gateway
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

**Notes**:

- `lb://todo-service`: Uses Eureka to resolve the `todo-service` instance.
- `Path=/api/todos/**`: Routes requests matching this path to Todo Service.
- `AddRequestHeader`: Adds a header to track requests passing through the gateway.

#### `gateway-service/src/main/java/com/example/gateway/GatewayApplication.java`

```java
package com.example.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }
}
```

### 2. JWT Validation Filter

Create a custom filter to validate JWT tokens for secured endpoints.

#### `gateway-service/src/main/java/com/example/gateway/filter/JwtFilter.java`

```java
package com.example.gateway.filter;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class JwtFilter extends AbstractGatewayFilterFactory<JwtFilter.Config> {
    public JwtFilter() {
        super(Config.class);
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                return exchange.getResponse().setComplete();
            }

            String token = authHeader.substring(7);
            try {
                Jwts.parser()
                        .setSigningKey("secret-key".getBytes()) // Replace with secure key in production
                        .build()
                        .parseClaimsJws(token);
                return chain.filter(exchange);
            } catch (JwtException e) {
                exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                return exchange.getResponse().setComplete();
            }
        };
    }

    public static class Config {
        // Configuration properties if needed
    }
}
```

**Notes**:

- Checks for a `Bearer` token in the `Authorization` header.
- Validates the JWT using a secret key (hardcoded here for simplicity; use a secure key in production).
- Returns HTTP 401 if the token is missing or invalid.

#### Update `config-repo/gateway-service.yml`

Apply the JWT filter to secured routes:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: todo-service
          uri: lb://todo-service
          predicates:
            - Path=/api/todos/**
          filters:
            - AddRequestHeader=X-Request-Source, Gateway
            - JwtFilter
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/users/**
          filters:
            - AddRequestHeader=X-Request-Source, Gateway
            - JwtFilter
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

### 3. Update Existing Services

Ensure `todo-service` and `user-service` are configured as in the previous microservices setup:

- Both use `spring-cloud-starter-netflix-eureka-client` and `spring-cloud-starter-config`.
- Both register with Eureka and fetch configs from Config Server.
- Update `todo-service.yml` and `user-service.yml` in `config-repo` if needed.

---

## Running and Testing the Application

### 1. Setup Config Repository

- Ensure `config-repo` contains `todo-service.yml`, `user-service.yml`, and `gateway-service.yml`.
- Initialize as a Git repository (if not already done):
    
    ```bash
    cd ~/config-repo
    git add .
    git commit -m "Add gateway config"
    ```
    

### 2. Start Services

Run each service in a separate terminal:

1. **Config Server**:
    
    ```bash
    cd config-server
    mvn spring-boot:run
    ```
    
    - Access: `http://localhost:8888/gateway-service/default`
2. **Eureka Server**:
    
    ```bash
    cd eureka-server
    mvn spring-boot:run
    ```
    
    - Access: `http://localhost:8761`
3. **User Service**:
    
    ```bash
    cd user-service
    mvn spring-boot:run
    ```
    
4. **Todo Service**:
    
    ```bash
    cd todo-service
    mvn spring-boot:run
    ```
    
5. **Gateway Service**:
    
    ```bash
    cd gateway-service
    mvn spring-boot:run
    ```
    

### 3. Generate a JWT Token

For testing, generate a JWT token using a tool like [jwt.io](https://jwt.io/) or a simple Java program:

```java
import io.jsonwebtoken.Jwts;

public class JwtGenerator {
    public static void main(String[] args) {
        String token = Jwts.builder()
                .setSubject("user1")
                .signWith(io.jsonwebtoken.SignatureAlgorithm.HS256, "secret-key".getBytes())
                .compact();
        System.out.println("JWT: " + token);
    }
}
```

Run this to get a token (e.g., `eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyMSJ9...`).

### 4. Test with Postman

1. **Create a User (via Gateway)**:
    
    ```bash
    curl -X POST http://localhost:8080/api/users \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyMSJ9..." \
    -d '{"username":"john"}'
    ```
    
    **Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "username": "john"
    }
    ```
    
2. **Create a Todo (via Gateway)**:
    
    ```bash
    curl -X POST http://localhost:8080/api/todos \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyMSJ9..." \
    -d '{"title":"Learn Gateway","completed":false,"userId":1}'
    ```
    
    **Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "title": "Learn Gateway",
        "completed": false,
        "userId": 1
    }
    ```
    
3. **Test Invalid JWT**:
    
    ```bash
    curl -X POST http://localhost:8080/api/todos \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer invalid-token" \
    -d '{"title":"Test","completed":false,"userId":1}'
    ```
    
    **Response**: HTTP 401 Unauthorized
    
4. **Verify in Eureka**:
    
    - Access `http://localhost:8761` to confirm `gateway-service`, `todo-service`, and `user-service` are registered.

---

## How It Works

1. **Spring Cloud Gateway**:
    
    - Routes requests based on predicates (e.g., `Path=/api/todos/**`).
    - Uses `lb://` URIs to resolve services via Eureka.
    - Applies filters like `AddRequestHeader` and `JwtFilter`.
2. **JWT Filter**:
    
    - Intercepts requests to check for a valid `Authorization` header.
    - Validates the JWT using the `jjwt` library.
    - Allows or blocks requests based on token validity.
3. **Eureka Integration**:
    
    - Gateway discovers `todo-service` and `user-service` via Eureka.
    - `lb://todo-service` resolves to the actual host/port of the service.
4. **Config Server**:
    
    - Provides `gateway-service.yml` for route configuration.
    - Centralizes configuration for all services.

**Flow**:

- Client sends request to `http://localhost:8080/api/todos`.
- Gateway validates JWT via `JwtFilter`.
- Gateway routes request to `todo-service` using Eureka.
- Todo Service processes the request and queries `user-service` if needed.

---

## Advanced Features

1. **Rate Limiting**:  
    Add rate-limiting with Redis:
    
    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
    </dependency>
    ```
    
    Update `gateway-service.yml`:
    
    ```yaml
    spring:
      cloud:
        gateway:
          routes:
            - id: todo-service
              uri: lb://todo-service
              predicates:
                - Path=/api/todos/**
              filters:
                - name: RequestRateLimiter
                  args:
                    redis-rate-limiter.replenishRate: 10
                    redis-rate-limiter.burstCapacity: 20
    spring.redis.host: localhost
    spring.redis.port: 6379
    ```
    
2. **Logging Filter**:  
    Add a custom logging filter:
    
    ```java
    @Component
    public class LoggingFilter extends AbstractGatewayFilterFactory<LoggingFilter.Config> {
        public LoggingFilter() {
            super(Config.class);
        }
    
        @Override
        public GatewayFilter apply(Config config) {
            return (exchange, chain) -> {
                System.out.println("Request: " + exchange.getRequest().getURI());
                return chain.filter(exchange).doOnSuccess(v -> {
                    System.out.println("Response: " + exchange.getResponse().getStatusCode());
                });
            };
        }
    
        public static class Config {}
    }
    ```
    
    Update `gateway-service.yml`:
    
    ```yaml
    filters:
      - LoggingFilter
    ```
    
3. **Circuit Breaker**:  
    Add Resilience4j for fallback routes:
    
    ```xml
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-circuitbreaker-reactor-resilience4j</artifactId>
    </dependency>
    ```
    
    Update `gateway-service.yml`:
    
    ```yaml
    filters:
      - name: CircuitBreaker
        args:
          name: todoService
          fallbackUri: forward:/fallback
    ```
    
    Add fallback endpoint:
    
    ```java
    @RestController
    public class FallbackController {
        @GetMapping("/fallback")
        public Mono<String> fallback() {
            return Mono.just("Service unavailable");
        }
    }
    ```
    

---

## Best Practices

- **Secure Endpoints**: Use JWT or OAuth2 for authentication.
- **Monitor Gateway**: Integrate with Spring Boot Actuator for metrics.
- **Centralize Configuration**: Use Config Server for consistent route management.
- **Test Routes**:
    
    ```java
    @SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
    class GatewayTest {
        @Autowired
        private TestRestTemplate restTemplate;
    
        @Test
        void testTodoRoute() {
            ResponseEntity<String> response = restTemplate.exchange(
                    "/api/todos", HttpMethod.POST,
                    new HttpEntity<>(new Todo("Test", false, 1L),
                    new HttpHeaders() {{ set("Authorization", "Bearer valid-token"); }}),
                    String.class);
            assertEquals(HttpStatus.CREATED, response.getStatusCode());
        }
    }
    ```
    

---

## Conclusion

Spring Cloud Gateway provides a robust solution for routing and filtering requests in a microservices architecture. The practice application sets up a gateway to route requests to Todo Service and User Service, integrating with Eureka for service discovery and applying a JWT validation filter for security. Advanced features like rate-limiting and circuit breakers enhance resilience and scalability. Explore Spring Cloud Gateway’s documentation for further customization and integration options.

[[0 - Spring Framework]]