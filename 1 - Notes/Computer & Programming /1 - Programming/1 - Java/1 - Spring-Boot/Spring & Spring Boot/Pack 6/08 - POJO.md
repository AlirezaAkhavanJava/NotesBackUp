

**POJO** stands for:

> **Plain Old Java Object**

A POJO is a normal Java class that does **not depend on any special framework class, interface, or annotation**.

It is just a Java object containing:

- fields (state)
    
- constructors
    
- getters/setters
    
- methods (behavior)
    

Example:

```java
public class User {

    private Long id;
    private String username;
    private String email;

    public User() {
    }

    public User(Long id, String username, String email) {
        this.id = id;
        this.username = username;
        this.email = email;
    }

    public Long getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public String getEmail() {
        return email;
    }
}
```

This is a POJO because it is just Java. It does not know anything about Spring.

---

## Why does Spring Boot use POJOs?

Spring is built around the idea of **POJO-based development**.

Instead of forcing you to extend framework classes:

```java
public class User extends SpringUserFrameworkClass {
}
```

Spring lets you write simple Java objects:

```java
public class User {
}
```

Then Spring adds behavior around them using:

- Dependency Injection
    
- Reflection
    
- Proxies
    
- Annotations
    

---

# POJO vs Spring Bean

A POJO is just a Java object.

A **Spring Bean** is a POJO that is **managed by the Spring Container**.

Example:

### Normal POJO

```java
public class EmailService {

    public void sendEmail() {
        System.out.println("Sending...");
    }
}
```

Nobody manages this object:

```java
EmailService service = new EmailService();
```

---

### Spring Bean

```java
@Service
public class EmailService {

    public void sendEmail() {
        System.out.println("Sending...");
    }
}
```

Now Spring creates and manages it:

```java
@Service
```

tells Spring:

> "Create an object of this class and keep it inside the ApplicationContext."

You inject it:

```java
@RestController
public class UserController {

    private final EmailService emailService;

    public UserController(EmailService emailService) {
        this.emailService = emailService;
    }
}
```

Spring creates:

```
ApplicationContext
        |
        |
        +---- EmailService object
        |
        +---- UserController object
```

---

# Common POJOs in Spring Boot

## 1. Entity POJO

Represents database data.

```java
@Entity
public class User {

    @Id
    private Long id;

    private String username;
}
```

Technically it is still a POJO, but now JPA uses annotations to map it.

Database:

```
users table

id | username
-------------
1  | ali
```

Object:

```
User
 |
 +-- id = 1
 +-- username = "ali"
```

---

## 2. DTO POJO

Used for transferring data.

Example request:

```java
public record CreateUserRequest(
        String username,
        String email
) {}
```

JSON:

```json
{
    "username": "ali",
    "email": "ali@test.com"
}
```

Spring converts JSON → DTO object:

```
HTTP Request

      |
      v

CreateUserRequest POJO

username = ali
email = ali@test.com
```

---

## 3. Configuration POJO

Example:

```java
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private String name;
}
```

Spring fills this object from:

```properties
app.name=DoItLater
```

---

# POJO vs JavaBean

People often confuse these.

A **JavaBean** is a special type of POJO.

JavaBean rules:

1. Has a no-argument constructor
    
2. Fields are private
    
3. Uses getters/setters
    

Example:

```java
public class User {

    private String name;

    public User() {}

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

This is:

```
JavaBean
    |
    |
    +---- POJO
```

But:

```
POJO
    |
    +---- does not have to follow JavaBean rules
```

---

# In a Spring Boot application

A typical architecture:

```
Controller
    |
    |
    v
DTO (POJO)
    |
    |
    v
Service (Spring Bean)
    |
    |
    v
Repository (Spring Bean)
    |
    |
    v
Entity (POJO)
    |
    |
    v
Database
```

Example:

```
CreateUserRequest  <-- POJO
        |
        v
UserService        <-- Spring Bean
        |
        v
UserRepository     <-- Spring Bean
        |
        v
User Entity        <-- POJO
```

---

## The important idea

Spring Boot is not about making special Spring objects.

It is about:

> **Writing normal Java objects and letting the Spring Container manage their lifecycle and relationships.**

That is why you see so many simple classes in Spring projects:

- Entity
    
- DTO
    
- Request
    
- Response
    
- Configuration objects
    

They are mostly POJOs.


[[Spring Framework]]