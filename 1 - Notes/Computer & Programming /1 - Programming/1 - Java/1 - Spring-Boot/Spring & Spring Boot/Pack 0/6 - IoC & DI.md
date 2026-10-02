## IoC (Inversion of Control)

**IoC is a design principle where the control of object creation and object management is moved from your code to a framework/container.**

Normally:

```java
public class Main {

    public static void main(String[] args) {

        UserService service = new UserService();

    }
}
```

Your code controls:

- when the object is created
    
- how it is created
    
- what dependencies it receives
    

Flow:

```
Your Code
    |
    |
 creates
    |
    v
Object
```

---

With IoC:

```java
@Service
public class UserService {

}
```

You do not write:

```java
new UserService();
```

Spring does it.

Flow:

```
Spring Container
        |
        |
 creates
        |
        v
UserService Bean
        |
        |
 gives to your code
```

The control has been **inverted**.

Before:

```
Application --> creates --> Objects
```

After:

```
Spring Container --> creates --> Objects
```

That is **Inversion of Control**.

---

# DI (Dependency Injection)

**Dependency Injection is a technique used to implement IoC.**

A dependency is an object that another object needs.

Example:

```java
public class OrderService {

    private PaymentService paymentService;

}
```

`OrderService` depends on `PaymentService`.

Without DI:

```java
public class OrderService {

    private PaymentService paymentService;

    public OrderService() {
        this.paymentService = new PaymentService();
    }
}
```

Problem:

`OrderService` is tightly coupled to `PaymentService`.

```
OrderService
      |
      |
 creates
      |
      v
PaymentService
```

---

With DI:

```java
@Service
public class OrderService {

    private final PaymentService paymentService;


    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}
```

Spring provides the dependency:

```
Spring Container

PaymentService Bean
        |
        |
        injects
        |
        v

OrderService
```

`OrderService` does not know how `PaymentService` is created.

---

# Relationship between IoC and DI

Think of it like this:

```
                 IoC
                  |
                  |
      "Spring controls object creation"
                  |
                  |
                  v
                 DI
                  |
                  |
      "Spring gives objects what they need"
```

DI is a **way to achieve IoC**.

---

# Types of Dependency Injection

## 1. Constructor Injection (recommended)

```java
@Service
public class UserService {

    private final UserRepository repository;


    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

Advantages:

- dependencies are mandatory
    
- object can be immutable
    
- easy testing
    
- preferred by Spring team
    

---

## 2. Setter Injection

```java
@Service
public class UserService {

    private UserRepository repository;


    @Autowired
    public void setRepository(UserRepository repository) {
        this.repository = repository;
    }
}
```

Useful for optional dependencies.

---

## 3. Field Injection (not recommended)

```java
@Service
public class UserService {

    @Autowired
    private UserRepository repository;

}
```

Problems:

- harder testing
    
- hides dependencies
    
- uses reflection
    

---

# Real Spring Boot example

Repository:

```java
@Repository
public class UserRepository {

}
```

Service:

```java
@Service
public class UserService {

    private final UserRepository repository;


    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

Controller:

```java
@RestController
public class UserController {

    private final UserService service;


    public UserController(UserService service) {
        this.service = service;
    }
}
```

Spring creates:

```
ApplicationContext

UserRepository
        |
        v
UserService
        |
        v
UserController
```

This is the typical Spring Boot architecture:

```
Controller
     |
     | DI
     v
Service
     |
     | DI
     v
Repository
```

---

## Mental model

- **IoC** = "Spring owns the objects instead of you"
    
- **DI** = "Spring supplies the objects your classes need"
    
- **BeanFactory/ApplicationContext** = "The engine that performs IoC and DI"



[[Spring Framework]]