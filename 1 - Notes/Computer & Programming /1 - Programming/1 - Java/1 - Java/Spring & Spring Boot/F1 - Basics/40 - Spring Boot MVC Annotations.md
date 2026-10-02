## Overview

Spring Boot MVC (Model-View-Controller) is a framework for building web applications. It uses annotations to simplify configuration and define how the app handles web requests, responses, and data. Annotations mark classes, methods, or fields to tell Spring what they do. This note lists the main Spring Boot MVC annotations, explains their purpose, where they’re used, and which annotations they’re often paired with.

## Key Annotations

Below is a list of the most common Spring Boot MVC annotations, organized for clarity.

1. **@Controller**
    
    - **What it does**: Marks a class as a web controller to handle HTTP requests and return responses (e.g., web pages or data).
    - **Where it’s used**: On a class that processes web requests, typically returning a view (like a webpage).
    - **Related annotations**:
        - `@RequestMapping`: Defines the URL path for the controller.
        - `@ResponseBody`: Returns data (e.g., JSON) instead of a view.
    - **Example**:
        
        ```java
        import org.springframework.stereotype.Controller;
        import org.springframework.web.bind.annotation.RequestMapping;
        
        @Controller
        public class HomeController {
            @RequestMapping("/home")
            public String showHomePage() {
                return "home"; // Returns the name of a view (e.g., home.html)
            }
        }
        ```
        
2. **@RestController**
    
    - **What it does**: A special version of `@Controller` that automatically adds `@ResponseBody` to all methods, returning data (like JSON or XML) instead of views.
    - **Where it’s used**: On a class for REST APIs that send data to clients (e.g., mobile apps or web apps).
    - **Related annotations**:
        - `@RequestMapping`: Maps URLs to the controller or its methods.
        - `@GetMapping`, `@PostMapping`, etc.: Handle specific HTTP methods.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.RestController;
        import org.springframework.web.bind.annotation.GetMapping;
        
        @RestController
        public class ApiController {
            @GetMapping("/api/users")
            public List<User> getUsers() {
                return List.of(new User(1, "John"));
            }
        }
        ```
        
3. **@RequestMapping**
    
    - **What it does**: Maps HTTP requests to a controller or method based on the URL and HTTP method (e.g., GET, POST).
    - **Where it’s used**: On a class or method to define the URL path and HTTP method.
    - **Related annotations**:
        - `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`: Shortcuts for specific HTTP methods.
        - `@PathVariable`, `@RequestParam`: Handle URL or query parameters.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.RequestMapping;
        import org.springframework.web.bind.annotation.RequestMethod;
        
        @Controller
        @RequestMapping("/products")
        public class ProductController {
            @RequestMapping(value = "/list", method = RequestMethod.GET)
            public String listProducts() {
                return "product-list";
            }
        }
        ```
        
4. **@GetMapping, @PostMapping, @PutMapping, @DeleteMapping, @PatchMapping**
    
    - **What they do**: Shortcuts for `@RequestMapping` to handle specific HTTP methods (GET, POST, PUT, DELETE, PATCH).
    - **Where they’re used**: On controller methods to handle specific types of HTTP requests.
    - **Related annotations**:
        - `@RequestMapping`: The parent annotation.
        - `@PathVariable`, `@RequestBody`: Pass data from the request.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.GetMapping;
        import org.springframework.web.bind.annotation.PostMapping;
        
        @RestController
        public class UserController {
            @GetMapping("/users")
            public List<User> getAllUsers() {
                return List.of(new User(1, "John"));
            }
        
            @PostMapping("/users")
            public User createUser(@RequestBody User user) {
                return user;
            }
        }
        ```
        
5. **@RequestParam**
    
    - **What it does**: Binds a query parameter from the URL to a method parameter.
    - **Where it’s used**: On method parameters to extract query parameters (e.g., `?name=John`).
    - **Related annotations**:
        - `@GetMapping`: Often used with GET requests.
        - `@RequestMapping`: Used in methods with custom mappings.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.GetMapping;
        import org.springframework.web.bind.annotation.RequestParam;
        
        @RestController
        public class SearchController {
            @GetMapping("/search")
            public String search(@RequestParam("query") String query) {
                return "Searching for: " + query;
            }
        }
        ```
        
6. **@PathVariable**
    
    - **What it does**: Binds a URL path variable to a method parameter (e.g., `/users/{id}`).
    - **Where it’s used**: On method parameters to extract values from the URL path.
    - **Related annotations**:
        - `@GetMapping`, `@PutMapping`, etc.: Used with path-based requests.
        - `@RequestMapping`: Defines the URL pattern.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.GetMapping;
        import org.springframework.web.bind.annotation.PathVariable;
        
        @RestController
        public class UserController {
            @GetMapping("/users/{id}")
            public User getUser(@PathVariable Long id) {
                return new User(id, "John");
            }
        }
        ```
        
7. **@RequestBody**
    
    - **What it does**: Binds the body of an HTTP request (e.g., JSON or XML) to a method parameter.
    - **Where it’s used**: On method parameters in REST APIs to accept data sent by clients.
    - **Related annotations**:
        - `@PostMapping`, `@PutMapping`: Used with methods that accept data.
        - `@RestController`: Common in REST APIs.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.PostMapping;
        import org.springframework.web.bind.annotation.RequestBody;
        
        @RestController
        public class UserController {
            @PostMapping("/users")
            public User createUser(@RequestBody User user) {
                return user;
            }
        }
        ```
        
8. **@ResponseBody**
    
    - **What it does**: Tells Spring to return a method’s result as data (e.g., JSON or XML) instead of a view.
    - **Where it’s used**: On controller methods when you want to return data directly.
    - **Related annotations**:
        - `@Controller`: Used when the class isn’t a `@RestController`.
        - `@GetMapping`, `@PostMapping`: Used with methods returning data.
    - **Example**:
        
        ```java
        import org.springframework.stereotype.Controller;
        import org.springframework.web.bind.annotation.GetMapping;
        import org.springframework.web.bind.annotation.ResponseBody;
        
        @Controller
        public class DataController {
            @GetMapping("/data")
            @ResponseBody
            public String getData() {
                return "Hello, World!";
            }
        }
        ```
        
9. **@ModelAttribute**
    
    - **What it does**: Binds form data or query parameters to an object, making it available to a view.
    - **Where it’s used**: On method parameters or methods to prepare data for a view in `@Controller` classes.
    - **Related annotations**:
        - `@Controller`: Used in view-based controllers.
        - `@RequestMapping`: Defines the URL.
    - **Example**:
        
        ```java
        import org.springframework.stereotype.Controller;
        import org.springframework.web.bind.annotation.GetMapping;
        import org.springframework.web.bind.annotation.ModelAttribute;
        
        @Controller
        public class FormController {
            @GetMapping("/form")
            public String showForm(@ModelAttribute("user") User user) {
                return "user-form";
            }
        }
        ```
        
10. **@ExceptionHandler**
    
    - **What it does**: Defines a method to handle specific exceptions thrown by controller methods.
    - **Where it’s used**: In a controller or a global `@ControllerAdvice` class to manage errors.
    - **Related annotations**:
        - `@ControllerAdvice`: Used for global exception handling.
        - `@ResponseStatus`: Sets the HTTP status code for the error.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.ExceptionHandler;
        import org.springframework.web.bind.annotation.RestController;
        
        @RestController
        public class ErrorController {
            @ExceptionHandler(IllegalArgumentException.class)
            public String handleError(IllegalArgumentException e) {
                return "Error: " + e.getMessage();
            }
        }
        ```
        
11. **@ControllerAdvice**
    
    - **What it does**: Defines a class to handle exceptions or provide shared logic across all controllers.
    - **Where it’s used**: On a class for global exception handling or to add shared data to models.
    - **Related annotations**:
        - `@ExceptionHandler`: Handles exceptions globally.
        - `@ModelAttribute`: Adds shared data to all controllers.
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.ControllerAdvice;
        import org.springframework.web.bind.annotation.ExceptionHandler;
        
        @ControllerAdvice
        public class GlobalExceptionHandler {
            @ExceptionHandler(Exception.class)
            public String handleAllExceptions(Exception e) {
                return "error-page";
            }
        }
        ```
        
12. **@ResponseStatus**
    
    - **What it does**: Sets the HTTP status code for a response, often used with exceptions or methods.
    - **Where it’s used**: On methods or exception classes to specify the HTTP status (e.g., 404, 500).
    - **Related annotations**:
        - `@ExceptionHandler`: Used to handle exceptions with a specific status.
        - `@RestController`, `@Controller`: Used with methods returning responses.
    - **Example**:
        
        ```java
        import org.springframework.http.HttpStatus;
        import org.springframework.web.bind.annotation.GetMapping;
        import org.springframework.web.bind.annotation.ResponseStatus;
        
        @RestController
        public class StatusController {
            @GetMapping("/not-found")
            @ResponseStatus(HttpStatus.NOT_FOUND)
            public String notFound() {
                return "Resource not found";
            }
        }
        ```
        
13. **@Valid**
    
    - **What it does**: Validates an object’s fields (e.g., ensuring required fields aren’t empty) using validation rules.
    - **Where it’s used**: On method parameters (like `@RequestBody` or `@ModelAttribute`) to validate input data.
    - **Related annotations**:
        - `@RequestBody`, `@ModelAttribute`: Used with objects that need validation.
        - Bean Validation annotations (e.g., `@NotNull`, `@Size` from `javax.validation`).
    - **Example**:
        
        ```java
        import org.springframework.web.bind.annotation.PostMapping;
        import org.springframework.web.bind.annotation.RequestBody;
        import jakarta.validation.Valid;
        
        @RestController
        public class UserController {
            @PostMapping("/users")
            public User createUser(@Valid @RequestBody User user) {
                return user;
            }
        }
        ```
        

## Best Practices

- Use `@RestController` for REST APIs and `@Controller` for web pages.
- Keep URLs clear and consistent with `@RequestMapping`, `@GetMapping`, etc.
- Handle errors gracefully with `@ExceptionHandler` or `@ControllerAdvice`.
- Validate input data with `@Valid` and Bean Validation annotations.
- Use `@ResponseBody` only when needed in `@Controller` classes.

## Project Structure

Organize your project with folders:

- **Controllers**: Handle web requests (e.g., `UserController.java`).
- **Services**: Manage business logic.
- **Repositories**: Handle database tasks.
- **Models**: Define entities or DTOs.
- **Exceptions**: Define custom exceptions.

## Resources

- [Spring Boot MVC Documentation](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#web)
- [Baeldung Spring MVC Tutorials](https://www.baeldung.com/spring-mvc-tutorial)
- [Spring Guides: Building a RESTful Web Service](https://spring.io/guides/gs/rest-service/)

## Tags

[[0 - Spring Framework]]