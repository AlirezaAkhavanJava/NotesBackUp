Date: 2025-08-24  
Concept: Spring Controllers and Their Types  
Course: Java Language Fundamentals  
Tags:  [[0 - Spring Framework]]

# Terms

- **Controller**: A Spring class that handles HTTP requests and returns responses (e.g., HTML, JSON, redirects) in a web application, part of the Spring MVC framework.
- **Spring MVC**: A framework for building web applications, with controllers as the core for request handling.
- **Bean**: A Spring-managed object, created and wired by the ApplicationContext.
- **Request Mapping**: Annotations like `@GetMapping`, `@PostMapping` that link URLs and HTTP methods to controller methods.
- **@Controller**: Annotation for controllers returning views (e.g., HTML, Thymeleaf) or redirects.
- **@RestController**: Annotation for controllers returning data (e.g., JSON, XML) for REST APIs.
- **Dependency Injection**: Injecting dependencies (e.g., services) into controllers using `@Autowired`.

# Notes

## Overview

A **Controller** in Spring handles HTTP requests in the presentation layer, delegating business logic to services. It’s a Spring bean, managed by the `ApplicationContext`, and uses annotations to map requests and process responses. Spring supports two controller types: `@Controller` for web pages and `@RestController` for APIs.

## Types of Controllers

1. **@Controller**
    
    - **Purpose**: Handles HTTP requests, returns views (e.g., HTML, JSP, Thymeleaf) or redirects for traditional web apps.
    - **Use Case**: Rendering server-side templates or redirecting URLs.
    - **Features**: Returns view names (e.g., `"index"`) resolved by a view resolver; supports form handling and session management.
    - **Where Used**: In `@Component`-scanned packages for MVC web apps.
2. **@RestController**
    
    - **Purpose**: Handles HTTP requests, returns data (e.g., JSON, XML) for REST APIs.
    - **Use Case**: Building APIs for frontend frameworks or microservices.
    - **Features**: Combines `@Controller` and `@ResponseBody`, serializing returns to JSON/XML.
    - **Where Used**: In `@Component`-scanned packages for API-driven apps.

## Key Annotations

1. **@RequestMapping**: Maps HTTP requests to methods at class/method level (e.g., `@RequestMapping("/api")`).
2. **@GetMapping, @PostMapping, @PutMapping, @DeleteMapping, @PatchMapping**: Shorthands for specific HTTP methods.
3. **@RequestBody**: Binds request body (e.g., JSON) to a parameter.
4. **@PathVariable**: Extracts variables from URL paths (e.g., `/users/{id}`).
5. **@RequestParam**: Extracts query parameters (e.g., `?name=Alice`).
6. **@ResponseBody**: Sends return value as response body (included in `@RestController`).

## Common Issues

- **404 Errors**: Wrong URL or missing `@RequestMapping`. Fix: Verify paths and `@ComponentScan`.
- **Ambiguous Mappings**: Same URL mapped multiple times. Fix: Use unique paths/methods.
- **Serialization Errors**: Complex objects failing JSON conversion. Fix: Add `spring-boot-starter-web`.
- **Missing Beans**: Dependencies not injected. Fix: Ensure `@Service`/`@Repository` are scanned.

## Best Practices

1. Use `@RestController` for APIs, `@Controller` for web pages.
2. Keep controllers thin; delegate logic to `@Service`.
3. Use specific mappings (e.g., `@GetMapping`) for clarity.
4. Handle errors with `@ExceptionHandler` or `@ControllerAdvice`.
5. Use constructor injection with `@Autowired`.
6. Test with `MockMvc` or Postman.

# Summary

Spring controllers, marked with `@Controller` (for views like HTML) or `@RestController` (for data like JSON), handle HTTP requests in the presentation layer. Annotations like `@GetMapping`, `@PostMapping`, `@RequestBody`, and `@PathVariable` map and process requests. Keep controllers thin, delegate to `@Service`, use constructor injection, and handle errors properly for robust Spring Boot web applications.