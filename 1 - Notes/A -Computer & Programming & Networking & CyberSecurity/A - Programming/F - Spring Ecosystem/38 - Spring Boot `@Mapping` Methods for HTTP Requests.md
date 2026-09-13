In **Spring Boot**, the `@Mapping` annotations are used in the Spring Web module (part of `spring-web` or `spring-webmvc`) to map HTTP requests to specific controller methods. These annotations, provided by the Spring Framework, allow developers to handle different types of HTTP requests (e.g., GET, POST, PUT) in a RESTful or MVC application. They are typically used in `@Controller` or `@RestController` classes to define endpoints and their behavior.

This document explains the key `@Mapping` annotations, their purpose, and how they correspond to HTTP request methods, presented in a simple and clear way.

---
## Overview

- **Purpose**: Map HTTP requests to Java methods in controllers, specifying the HTTP method, URL path, and other request details.
- **Key Package**: `org.springframework.web.bind.annotation`.
- **Use Case**: Building RESTful APIs or web applications to handle client requests (e.g., browser, API clients).
- **Key Annotations**: Spring provides specific annotations for each HTTP method, plus a generic `@RequestMapping` for flexibility.

## Key `@Mapping` Annotations

The `@Mapping` annotations are applied at the method or class level in controllers to define how HTTP requests are handled. Below are the main annotations and their associated HTTP methods.

### 1. **`@RequestMapping`**

- **Purpose**: A generic annotation to map HTTP requests of any method (GET, POST, etc.) to a controller method or class.
- **Attributes**:
    - `value` or `path`: Specifies the URL path (e.g., `/api/users`).
    - `method`: Specifies the HTTP method(s) (e.g., `RequestMethod.GET`, `RequestMethod.POST`).
    - `produces`: Specifies the response media type (e.g., `application/json`).
    - `consumes`: Specifies the request media type (e.g., `application/json`).
    - `params`: Matches requests with specific parameters.
    - `headers`: Matches requests with specific headers.
- **Use Case**: Flexible mapping for any HTTP method or when multiple methods are supported.
- **Example**:

```java
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class UserController {
    @RequestMapping(value = "/users", method = RequestMethod.GET)
    public String getUsers() {
        return "List of users";
    }
}
```

- **Output**: A GET request to `/api/users` returns `"List of users"`.

### 2. **`@GetMapping`**

- **Purpose**: Maps HTTP GET requests to a controller method. Used to retrieve resources.
- **Attributes**: Same as `@RequestMapping` (e.g., `value`, `produces`).
- **Use Case**: Fetching data, such as retrieving a list of users or a specific resource.
- **Example**:

```java
@GetMapping("/users")
public String getUsers() {
    return "List of users";
}
```

- **Output**: A GET request to `/api/users` returns `"List of users"`.

### 3. **`@PostMapping`**

- **Purpose**: Maps HTTP POST requests to a controller method. Used to create new resources.
- **Attributes**: Same as `@RequestMapping`.
- **Use Case**: Submitting data to create a new resource (e.g., adding a user).
- **Example**:

```java
@PostMapping("/users")
public String createUser(@RequestBody String user) {
    return "Created user: " + user;
}
```

- **Output**: A POST request to `/api/users` with a JSON body (e.g., `{"name":"Alice"}`) returns `"Created user: {\"name\":\"Alice\"}"`.

### 4. **`@PutMapping`**

- **Purpose**: Maps HTTP PUT requests to a controller method. Used to update existing resources.
- **Attributes**: Same as `@RequestMapping`.
- **Use Case**: Updating a resource by replacing it or modifying specific fields.
- **Example**:

```java
@PutMapping("/users/{id}")
public String updateUser(@PathVariable String id, @RequestBody String user) {
    return "Updated user " + id + ": " + user;
}
```

- **Output**: A PUT request to `/api/users/1` with a JSON body returns `"Updated user 1: {...}"`.

### 5. **`@DeleteMapping`**

- **Purpose**: Maps HTTP DELETE requests to a controller method. Used to delete resources.
- **Attributes**: Same as `@RequestMapping`.
- **Use Case**: Removing a resource (e.g., deleting a user).
- **Example**:

```java
@DeleteMapping("/users/{id}")
public String deleteUser(@PathVariable String id) {
    return "Deleted user " + id;
}
```

- **Output**: A DELETE request to `/api/users/1` returns `"Deleted user 1"`.

### 6. **`@PatchMapping`**

- **Purpose**: Maps HTTP PATCH requests to a controller method. Used to partially update resources.
- **Attributes**: Same as `@RequestMapping`.
- **Use Case**: Applying partial updates to a resource (e.g., updating a user’s email).
- **Example**:

```java
@PatchMapping("/users/{id}")
public String patchUser(@PathVariable String id, @RequestBody String updates) {
    return "Patched user " + id + ": " + updates;
}
```

- **Output**: A PATCH request to `/api/users/1` with a JSON body returns `"Patched user 1: {...}"`.

### 7. **`@HeadMapping`** (Less Common)

- **Purpose**: Maps HTTP HEAD requests to a controller method. Used to retrieve headers without a response body.
- **Attributes**: Same as `@RequestMapping`.
- **Use Case**: Checking resource metadata or availability.
- **Example**:

```java
@HeadMapping("/users")
public void checkUsers() {
    // Headers set by framework, no body returned
}
```

- **Output**: A HEAD request to `/api/users` returns headers without a body.

### 8. **`@OptionsMapping`** (Less Common)

- **Purpose**: Maps HTTP OPTIONS requests to a controller method. Used to describe allowed methods for a resource.
- **Attributes**: Same as `@RequestMapping`.
- **Use Case**: Supporting CORS or API discovery.
- **Example**:

```java
@OptionsMapping("/users")
public String getOptions() {
    return "GET, POST, PUT, DELETE";
}
```

- **Output**: An OPTIONS request to `/api/users` returns `"GET, POST, PUT, DELETE"`.

## HTTP Request Types

The `@Mapping` annotations correspond to standard HTTP methods:

- **GET**: Retrieve a resource (`@GetMapping`).
- **POST**: Create a new resource (`@PostMapping`).
- **PUT**: Update or replace a resource (`@PutMapping`).
- **DELETE**: Remove a resource (`@DeleteMapping`).
- **PATCH**: Partially update a resource (`@PatchMapping`).
- **HEAD**: Retrieve headers only (`@HeadMapping`).
- **OPTIONS**: Retrieve allowed methods (`@OptionsMapping`).

## Common Attributes for All `@Mapping` Annotations

- `value` or `path`: The URL path (e.g., `/users/{id}`).
- `produces`: Response content type (e.g., `application/json`).
- `consumes`: Expected request content type (e.g., `application/json`).
- `params`: Matches requests with specific query parameters.
- `headers`: Matches requests with specific headers.

## Supporting Annotations

These annotations are often used with `@Mapping` methods:

- `@PathVariable`: Binds URL path variables to method parameters.
- `@RequestBody`: Binds the request body to a method parameter (e.g., JSON).
- `@RequestParam`: Binds query parameters to method parameters.
- `@ResponseStatus`: Sets the HTTP response status (e.g., `HttpStatus.CREATED`).
- `@RestController`: Combines `@Controller` and `@ResponseBody` for REST APIs.

## Example Combining Multiple HTTP Methods

```java
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    @GetMapping
    public String getUsers() {
        return "List of users";
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public String createUser(@RequestBody String user) {
        return "Created: " + user;
    }

    @PutMapping("/{id}")
    public String updateUser(@PathVariable String id, @RequestBody String user) {
        return "Updated user " + id + ": " + user;
    }

    @DeleteMapping("/{id}")
    public String deleteUser(@PathVariable String id) {
        return "Deleted user " + id;
    }

    @PatchMapping("/{id}")
    public String patchUser(@PathVariable String id, @RequestBody String updates) {
        return "Patched user " + id + ": " + updates;
    }
}
```

## Benefits

- **Simplicity**: Specific annotations (`@GetMapping`, `@PostMapping`) are more concise than `@RequestMapping`.
- **RESTful Design**: Aligns with REST principles for clear API endpoints.
- **Flexibility**: Supports complex mappings with attributes like `produces` and `consumes`.
- **Type Safety**: Integrates with Spring’s type conversion and validation.

## Limitations

- **Learning Curve**: Requires understanding of HTTP methods and REST principles.
- **Verbosity**: Complex mappings with multiple attributes can become verbose.
- **Error Handling**: Requires additional configuration for consistent error responses.

## Resources

- Oracle Documentation: [Spring Web Annotations](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/package-summary.html)
- Spring Boot Reference: [Spring Boot Web](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#web)


[[0 - Spring Framework]]