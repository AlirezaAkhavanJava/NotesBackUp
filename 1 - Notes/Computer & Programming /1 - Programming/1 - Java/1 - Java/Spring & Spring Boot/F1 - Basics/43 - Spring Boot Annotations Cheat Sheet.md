Date : 2025-09-04


This document explains the most common **Spring Boot annotations**, grouped by purpose.

---

## 1. Core Spring Annotations

### `@Component`

- Marks a class as a **Spring-managed bean**.
    
- Base annotation for stereotypes (`@Service`, `@Repository`, `@Controller`).
    

### `@Service`

- Specialized `@Component` for **service layer** classes.
    
- Used for business logic.
    

### `@Repository`

- Specialized `@Component` for **DAO / persistence layer**.
    
- Adds exception translation (converts JDBC exceptions to Spring’s `DataAccessException`).
    

### `@Controller`

- Specialized `@Component` for **web controllers**.
    
- Handles HTTP requests and returns a **view**.
    

### `@RestController`

- Combination of `@Controller` + `@ResponseBody`.
    
- Used in REST APIs. Methods return JSON or XML.
    

### `@Configuration`

- Marks a class that provides **bean definitions** using `@Bean`.
    
- Replaces XML configuration.
    

### `@Bean`

- Declares a bean explicitly inside `@Configuration` class.
    

---

## 2. Dependency Injection

### `@Autowired`

- Injects a bean by **type**.
    
- Can be applied to constructors, fields, or setters.
    

### `@Qualifier`

- Used with `@Autowired` when multiple beans of the same type exist.
    

### `@Value`

- Injects values from `application.properties` or `application.yml`.
    

### `@Primary`

- Marks a bean as the default choice when multiple candidates exist.
    

---

## 3. Spring Boot Specific

### `@SpringBootApplication`

- Shortcut for:
    
    - `@Configuration`
        
    - `@EnableAutoConfiguration`
        
    - `@ComponentScan`
        
- Marks the main class of a Spring Boot app.
    

### `@EnableAutoConfiguration`

- Tells Spring Boot to configure beans automatically based on classpath.
    

### `@ComponentScan`

- Scans packages for `@Component`, `@Service`, `@Repository`, `@Controller`.
    

### `@ConditionalOnProperty`

- Enables a bean only if a specific property is set.
    

### `@ConditionalOnClass`

- Enables a bean only if a specific class is present on the classpath.
    

---

## 4. Spring MVC Annotations

### `@RequestMapping`

- Maps HTTP requests to controller methods.
    
- Can define `path`, `method`, `params`, etc.
    

### `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@PatchMapping`

- Shorthand annotations for HTTP methods.
    

### `@PathVariable`

- Binds a URI template variable to a method parameter.
    

### `@RequestParam`

- Binds query parameters to method parameters.
    

### `@RequestBody`

- Maps JSON/XML request body to a Java object.
    

### `@ResponseBody`

- Returns method results directly as response body (JSON, XML, text).
    

### `@ModelAttribute`

- Binds request parameters to a model object.
    

---

## 5. Data & Persistence

### `@Entity`

- Marks a class as a **JPA entity** (maps to a DB table).
    

### `@Table`

- Customizes table name for a JPA entity.
    

### `@Id`

- Marks the **primary key** field.
    

### `@GeneratedValue`

- Defines primary key generation strategy (AUTO, IDENTITY, SEQUENCE, TABLE).
    

### `@Column`

- Customizes column mapping in a table.
    

### `@Transactional`

- Wraps method execution in a **database transaction**.
    

---

## 6. Validation

### `@Valid`

- Triggers validation on method parameters (e.g., request body).
    

### `@NotNull`, `@NotEmpty`, `@Size`, `@Email`

- Standard **Bean Validation (Jakarta Validation)** annotations.
    

---

## 7. Testing Annotations

### `@SpringBootTest`

- Boots up the entire Spring context for testing.
    

### `@DataJpaTest`

- Configures only **JPA components** for testing.
    

### `@WebMvcTest`

- Configures only **Spring MVC** components for testing controllers.
    

### `@MockBean`

- Adds a **Mockito mock** to the Spring context.
    

### `@ExtendWith(SpringExtension.class)`

- Integrates JUnit 5 with Spring TestContext framework.
    

---

## 8. Scheduling & Async

### `@EnableScheduling`

- Enables scheduled tasks in the app.
    

### `@Scheduled`

- Runs a method on a **cron schedule** or fixed interval.
    

### `@EnableAsync`

- Enables asynchronous method execution.
    

### `@Async`

- Runs a method in a separate thread asynchronously.
    

---

## 9. Security

### `@EnableWebSecurity`

- Enables Spring Security configuration.
    

### `@PreAuthorize`

- Secures a method with SpEL expressions (`@PreAuthorize("hasRole('ADMIN')")`).
    

### `@Secured`

- Alternative to `@PreAuthorize` for role-based security.
    

---

## Summary

Spring Boot annotations simplify development by:

- Managing beans & DI
    
- Handling web requests
    
- Configuring persistence & transactions
    
- Supporting scheduling, async, and security
    
- Enabling test-friendly contexts
    

Mastering these annotations is essential for real-world Spring Boot development.



##### *Tags : [[0 - Spring Framework]]