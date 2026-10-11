
# MVC Pattern (Model–View–Controller)

**MVC** is an architectural pattern that separates an application into three parts:

```text
              User
               |
               v
          Controller
               |
               v
            Model
               |
               v
             View
```

The goal is **separation of responsibilities**:

- **Model** → Data + business rules
    
- **View** → Presentation/UI
    
- **Controller** → Handles requests and coordinates between Model and View
    

---

# 1. Model

The **Model** represents the application's data and business logic.

It does not know about the UI.

Example:

```java
public class User {

    private Long id;
    private String username;
    private String email;

}
```

The Model contains:

- Entities
    
- Database representation
    
- Business rules
    
- State
    

In Spring Boot:

```
Model
 |
 +-- Entity
 +-- DTO
 +-- Service logic
 +-- Repository
```

Example:

```java
@Entity
public class Product {

    @Id
    private Long id;

    private String name;

    private double price;
}
```

---

# 2. View

The **View** is what the user sees.

Examples:

- HTML page
    
- React UI
    
- Angular UI
    
- Thymeleaf template
    
- Mobile screen
    

Example:

```html
<h1>
    Welcome Alireza
</h1>
```

The View should not contain business logic.

Bad:

```html
<!-- calculating prices inside HTML -->
```

Good:

```html
<p>
    Price: ${product.price}
</p>
```

The View only displays data.

---

# 3. Controller

The Controller receives user input and decides what happens.

Example:

User requests:

```
GET /users/10
```

Controller:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService service;


    public UserController(UserService service) {
        this.service = service;
    }


    @GetMapping("/{id}")
    public User getUser(
            @PathVariable Long id
    ) {
        return service.findById(id);
    }
}
```

Flow:

```
HTTP Request
      |
      v
 Controller
      |
      v
 Service
      |
      v
 Repository
      |
      v
 Database
```

---

# Traditional MVC flow

Example: Login page

```
User enters username/password
              |
              v
        Controller
              |
              v
          Model
              |
              v
       Check database
              |
              v
          View
              |
              v
    Show dashboard
```

---

# MVC in Spring Boot

Spring MVC architecture:

```
Browser
   |
   |
 HTTP Request
   |
   v
DispatcherServlet
   |
   v
Controller
   |
   v
Service
   |
   v
Repository
   |
   v
Database
```

Then:

```
Database
    |
    v
Repository
    |
    v
Service
    |
    v
Controller
    |
    v
JSON / HTML Response
```

---

# Spring MVC components

## DispatcherServlet

The front controller of Spring MVC.

It receives every request:

```
GET /api/users

        |
        v

DispatcherServlet

        |
        v

UserController
```

---

## Controller

Handles HTTP:

```java
@GetMapping("/users")
public List<User> users() {

}
```

---

## Service

Business logic:

```java
@Service
public class UserService {

    public User createUser(User user) {

        // validation
        // business rules

    }
}
```

---

## Repository

Database communication:

```java
@Repository
public interface UserRepository
        extends JpaRepository<User, Long> {

}
```

---

# MVC vs REST API

Traditional MVC:

```
Controller
    |
    v
Model
    |
    v
View (HTML)
```

Example:

```
GET /profile

returns:

profile.html
```

---

REST API style:

```
Controller
    |
    v
Service
    |
    v
Repository
```

returns:

```json
{
  "id": 1,
  "username": "ali"
}
```

The "View" is usually replaced by a frontend application:

```
Spring Boot API
        |
        |
        v
Angular / React / Mobile App
```

---

# Why MVC is useful

Without MVC:

```
Controller
 |
 +-- SQL queries
 |
 +-- HTML generation
 |
 +-- Business rules
 |
 +-- Validation
```

One huge class.

With MVC:

```
Controller
    |
    | handles HTTP
    v

Service
    |
    | business logic
    v

Repository
    |
    | database
    v

Database
```

Each part has one responsibility.

---

# Common Spring Boot project structure

```
src/main/java/com/example/app

├── controller
│     └── UserController.java
│
├── service
│     └── UserService.java
│
├── repository
│     └── UserRepository.java
│
├── entity
│     └── User.java
│
├── dto
│     └── UserResponse.java
│
└── config
      └── SecurityConfig.java
```

---

## Mental model

```
Controller  = "What request came in?"
Service     = "What should happen?"
Repository  = "Where is the data?"
Model       = "What is the data?"
View        = "How do we show it?"
```

For modern Spring Boot REST applications, MVC usually becomes:

```
Controller → Service → Repository → Database
```

with the frontend acting as the View.



[[Spring Framework]]