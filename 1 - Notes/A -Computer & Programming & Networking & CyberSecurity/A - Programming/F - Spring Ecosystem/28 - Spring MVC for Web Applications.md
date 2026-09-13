
## Overview

**Spring MVC** (Model-View-Controller) is a module of the Spring Framework for building web applications, particularly server-side rendered applications. It follows the MVC pattern to separate concerns: **Model** (data), **View** (UI), and **Controller** (business logic). Combined with **Thymeleaf**, a modern server-side Java template engine, Spring MVC simplifies creating dynamic web pages and handling form submissions.

**Why Use Spring MVC?**

- Ideal for traditional web applications requiring server-side rendering (e.g., dashboards, admin panels).
- Provides a structured approach to handle HTTP requests, form processing, and validation.
- Integrates seamlessly with Spring’s ecosystem (e.g., Spring Data JPA, Spring Security).

**How It Works**:

- Use `spring-boot-starter-thymeleaf` for Thymeleaf integration.
- Create controllers with `@Controller` to handle requests.
- Use Thymeleaf templates for rendering HTML.
- Handle form submissions with `@ModelAttribute` and validate inputs with `@Valid`.

**Resources**:

- [Spring MVC Documentation](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html)
- [Thymeleaf Documentation](https://www.thymeleaf.org/documentation.html)
- _Spring in Action_ by Craig Walls (Chapter 2)

**Prerequisites**:

- Basic HTML/CSS knowledge.
- Familiarity with Spring Data JPA (for database integration).

**Practice Goal**: Build a Spring Boot web application to manage a `Todo` list, with a form to add/edit todos, including validation for a non-empty title, using Spring MVC and Thymeleaf.

---

## Setting Up Spring MVC with Thymeleaf

### 1. Project Setup

Create a Spring Boot project with Maven, adding dependencies for Spring MVC, Thymeleaf, and Spring Data JPA (with H2 for simplicity).

#### `pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-mvc-app</artifactId>
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
            <artifactId>spring-boot-starter-thymeleaf</artifactId>
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
            <artifactId>spring-boot-starter-validation</artifactId>
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

- `spring-boot-starter-web`: Includes Spring MVC.
- `spring-boot-starter-thymeleaf`: Adds Thymeleaf for templating.
- `spring-boot-starter-validation`: Enables form validation with Hibernate Validator.
- `spring-boot-starter-data-jpa` and `h2`: For database operations.

### 2. Configure Application

Set up the H2 database in `src/main/resources/application.properties`.

```properties
spring.datasource.url=jdbc:h2:mem:tododb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.h2.console.enabled=true
spring.thymeleaf.cache=false
```

**Notes**:

- `spring.thymeleaf.cache=false`: Disables caching for development to reflect template changes instantly.
- H2 console is accessible at `http://localhost:8080/h2-console`.

---

## Building the Todo Application

### Project Structure

```
todo-mvc-app/
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
│   │   ├── resources/
│   │   │   ├── templates/
│   │   │   │   ├── todo-list.html
│   │   │   │   ├── todo-form.html
│   │   │   ├── application.properties
├── pom.xml
```

### 1. Entity Class (`Todo.java`)

Define the `Todo` entity with validation constraints.

```java
package com.example.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.validation.constraints.NotBlank;

@Entity
public class Todo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Title is required")
    private String title;

    private boolean completed;

    // Default constructor for JPA
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

**Notes**:

- `@NotBlank`: Ensures the `title` field is not empty or null.
- Hibernate Validator integrates with Spring MVC for form validation.

### 2. Repository (`TodoRepository.java`)

Create a repository for database operations.

```java
package com.example.repository;

import com.example.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, Long> {
}
```

### 3. Controller (`TodoController.java`)

Handle HTTP requests and render Thymeleaf templates.

```java
package com.example.controller;

import com.example.model.Todo;
import com.example.repository.TodoRepository;
import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/todos")
public class TodoController {
    private final TodoRepository todoRepository;

    public TodoController(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @GetMapping
    public String listTodos(Model model) {
        model.addAttribute("todos", todoRepository.findAll());
        return "todo-list";
    }

    @GetMapping("/new")
    public String showTodoForm(Model model) {
        model.addAttribute("todo", new Todo());
        return "todo-form";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable Long id, Model model) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Invalid todo ID: " + id));
        model.addAttribute("todo", todo);
        return "todo-form";
    }

    @PostMapping
    public String saveTodo(@Valid @ModelAttribute("todo") Todo todo, BindingResult result, Model model) {
        if (result.hasErrors()) {
            model.addAttribute("todo", todo);
            return "todo-form";
        }
        todoRepository.save(todo);
        return "redirect:/todos";
    }

    @GetMapping("/delete/{id}")
    public String deleteTodo(@PathVariable Long id) {
        todoRepository.deleteById(id);
        return "redirect:/todos";
    }
}
```

**Notes**:

- `@Controller`: Marks the class as a Spring MVC controller for server-side rendering.
- `@ModelAttribute`: Binds form data to the `Todo` object.
- `@Valid`: Triggers validation of the `Todo` object.
- `BindingResult`: Captures validation errors.
- `redirect:/todos`: Redirects to the todo list after form submission to prevent duplicate submissions.

### 4. Thymeleaf Templates

#### `todo-list.html` (List Todos)

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Todo List</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Todo List</h1>
    <a th:href="@{/todos/new}">Add New Todo</a>
    <table>
        <tr>
            <th>ID</th>
            <th>Title</th>
            <th>Completed</th>
            <th>Actions</th>
        </tr>
        <tr th:each="todo : ${todos}">
            <td th:text="${todo.id}"></td>
            <td th:text="${todo.title}"></td>
            <td th:text="${todo.completed}"></td>
            <td>
                <a th:href="@{/todos/edit/{id}(id=${todo.id})}">Edit</a>
                <a th:href="@{/todos/delete/{id}(id=${todo.id})}" onclick="return confirm('Are you sure?')">Delete</a>
            </td>
        </tr>
    </table>
</body>
</html>
```

#### `todo-form.html` (Add/Edit Form)

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Todo Form</title>
    <style>
        .error { color: red; }
        form { max-width: 400px; margin: 20px; }
        label, input { display: block; margin-bottom: 10px; }
    </style>
</head>
<body>
    <h1 th:text="${todo.id} ? 'Edit Todo' : 'Add Todo'"></h1>
    <form th:object="${todo}" th:action="@{/todos}" method="post">
        <input type="hidden" th:field="*{id}"/>
        <label for="title">Title:</label>
        <input type="text" th:field="*{title}" id="title"/>
        <span th:if="${#fields.hasErrors('title')}" th:errors="*{title}" class="error"></span>
        
        <label for="completed">Completed:</label>
        <input type="checkbox" th:field="*{completed}" id="completed"/>
        
        <button type="submit">Save</button>
    </form>
    <a th:href="@{/todos}">Back to List</a>
</body>
</html>
```

**Notes**:

- `th:each`: Iterates over the list of todos.
- `th:object` and `th:field`: Bind form fields to the `Todo` object.
- `th:errors`: Displays validation errors (e.g., "Title is required").
- `th:href`: Generates dynamic URLs for navigation.

---

## Running and Testing the Application

### 1. Run the Application

```bash
mvn spring-boot:run
```

### 2. Test in Browser

- **List Todos**: Visit `http://localhost:8080/todos`
    - Displays a table of todos with Edit/Delete links.
- **Add Todo**: Click "Add New Todo" (`http://localhost:8080/todos/new`)
    - Submit a form with a title (e.g., "Learn Spring MVC").
    - Leave the title empty to see the validation error ("Title is required").
- **Edit Todo**: Click "Edit" on a todo (`http://localhost:8080/todos/edit/1`)
    - Update the title or completion status.
- **Delete Todo**: Click "Delete" and confirm to remove a todo.

### 3. Test with H2 Console

- URL: `http://localhost:8080/h2-console`
- JDBC URL: `jdbc:h2:mem:tododb`
- Username: `sa`
- Password: (empty)
- Verify the `todos` table and data.

---

## How It Works

- **Spring MVC**:
    - `@Controller` handles HTTP requests and returns Thymeleaf template names.
    - `@GetMapping` and `@PostMapping` map to specific HTTP methods.
    - `@ModelAttribute` binds form data to the `Todo` entity.
    - `@Valid` and `BindingResult` handle form validation.
- **Thymeleaf**:
    - Renders dynamic HTML using data from the model.
    - Supports form binding, iteration, and error display.
- **Hibernate/JPA**:
    - Maps `Todo` to the `todos` table.
    - Persists data via `TodoRepository`.
- **Validation**:
    - `@NotBlank` ensures the title is not empty.
    - Validation errors are displayed in the form.

**Example Flow**:

1. User visits `/todos/new` → `showTodoForm` adds a new `Todo` to the model → `todo-form.html` renders.
2. User submits the form → `saveTodo` validates the input → Saves to database or shows errors.
3. On success, redirects to `/todos` → `listTodos` fetches all todos → `todo-list.html` renders.

---

## Advanced Features

1. **Custom Validation**:  
    Create a custom validator for complex rules:
    
    ```java
    @Component
    public class TodoValidator implements Validator {
        @Override
        public boolean supports(Class<?> clazz) {
            return Todo.class.equals(clazz);
        }
    
        @Override
        public void validate(Object target, Errors errors) {
            Todo todo = (Todo) target;
            if (todo.getTitle().length() > 50) {
                errors.rejectValue("title", "Size.todo.title", "Title cannot exceed 50 characters");
            }
        }
    }
    ```
    
    Use in controller:
    
    ```java
    @InitBinder
    protected void initBinder(WebDataBinder binder) {
        binder.addValidators(todoValidator);
    }
    ```
    
2. **Pagination in List View**:  
    Modify `listTodos` to support pagination:
    
    ```java
    @GetMapping
    public String listTodos(@RequestParam(defaultValue = "0") int page, Model model) {
        Pageable pageable = PageRequest.of(page, 5);
        model.addAttribute("todos", todoRepository.findAll(pageable));
        return "todo-list";
    }
    ```
    
    Update `todo-list.html`:
    
    ```html
    <div th:each="todo : ${todos.content}">
        <span th:text="${todo.title}"></span>
    </div>
    <a th:href="@{/todos(page=${todos.number - 1})}" th:if="${todos.hasPrevious()}">Previous</a>
    <a th:href="@{/todos(page=${todos.number + 1})}" th:if="${todos.hasNext()}">Next</a>
    ```
    
3. **CSRF Protection**:  
    Spring Security (included by default) enables CSRF protection. Ensure forms include the CSRF token:
    
    ```html
    <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
    ```
    

---

## Best Practices

- **Use Redirect After POST**: Prevent form resubmission with `redirect:`.
- **Validate Inputs**: Always use `@Valid` and handle `BindingResult`.
- **Keep Templates Clean**: Use Thymeleaf fragments for reusable components:
    
    ```html
    <th:fragment name="header">
        <h1>My App</h1>
    </th:fragment>
    ```
    
- **Optimize Performance**: Enable `spring.thymeleaf.cache=true` in production.
- **Test Controllers**:  
    Use `@WebMvcTest` for testing:
    
    ```java
    @WebMvcTest(TodoController.class)
    class TodoControllerTest {
        @Autowired
        private MockMvc mockMvc;
    
        @MockBean
        private TodoRepository todoRepository;
    
        @Test
        void testListTodos() throws Exception {
            mockMvc.perform(get("/todos"))
                    .andExpect(status().isOk())
                    .andExpect(view().name("todo-list"));
        }
    }
    ```
    

---

## Conclusion

Spring MVC with Thymeleaf enables building robust server-side rendered web applications. The Todo application demonstrates form handling, validation, and database integration using Spring Data JPA. By leveraging `@Controller`, `@ModelAttribute`, `@Valid`, and Thymeleaf templates, you can create dynamic, user-friendly web interfaces. Explore advanced features like custom validators and pagination, and refer to the Spring MVC and Thymeleaf documentation for deeper insights.


[[0 - Spring Framework]]