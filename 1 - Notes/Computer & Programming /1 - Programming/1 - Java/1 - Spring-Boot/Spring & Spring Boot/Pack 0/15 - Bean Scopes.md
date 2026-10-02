In Spring Boot, **bean scopes** define the **lifecycle and visibility of a Spring Bean**: how many instances Spring creates and how long they live.

A **Bean** is an object managed by the **Spring IoC Container**.

Example:

```java
@Component
public class EmailService {
}
```

Spring creates and manages an instance of `EmailService`. The scope decides **how that instance is reused**.

---

## 1. Singleton (Default)

**One instance per Spring Container.**

This is the default scope.

```java
@Component
@Scope("singleton")
public class UserService {
}
```

Usage:

```java
UserService a = context.getBean(UserService.class);
UserService b = context.getBean(UserService.class);

System.out.println(a == b); // true
```

Memory:

```
Spring Container

+----------------+
| UserService    |
| instance #1    |
+----------------+

a ----\
       ---> same object
b ----/
```

Common use:

- Services
    
- Repositories
    
- Controllers
    
- Configuration classes
    

Example:

```java
@Service
public class UserService {
    public void createUser() {
    }
}
```

Usually you want only one service object.

---

# 2. Prototype

**A new instance every time you request the bean.**

```java
@Component
@Scope("prototype")
public class ReportGenerator {
}
```

Example:

```java
ReportGenerator a = context.getBean(ReportGenerator.class);
ReportGenerator b = context.getBean(ReportGenerator.class);

System.out.println(a == b); // false
```

Memory:

```
Spring Container

Request 1
   |
   v
ReportGenerator #1


Request 2
   |
   v
ReportGenerator #2
```

Use when:

- Object has temporary state
    
- Object should not be shared
    

Example:

```java
public class ShoppingCart {

    private List<Item> items = new ArrayList<>();

}
```

Each user needs a different cart.

---

# 3. Request Scope (Web)

**One bean per HTTP request.**

Only exists in web applications.

```java
@Component
@Scope("request")
public class UserRequestData {
}
```

Example:

```
Browser Request 1
        |
        v
UserRequestData #1


Browser Request 2
        |
        v
UserRequestData #2
```

Useful for:

- Request information
    
- Request metadata
    
- Temporary user data
    

Example:

```java
@Component
@RequestScope
public class RequestContext {

    private String requestId;

}
```

---

# 4. Session Scope

**One bean per HTTP session.**

```java
@Component
@SessionScope
public class ShoppingCart {
}
```

Example:

```
User A Session

ShoppingCart #1


User B Session

ShoppingCart #2
```

Used for:

- Shopping carts
    
- User preferences
    
- Login session data
    

---

# 5. Application Scope

**One bean per ServletContext.**

Similar to singleton, but tied to the web application.

```java
@Component
@ApplicationScope
public class AppConfig {
}
```

Difference:

|Singleton|Application|
|---|---|
|Spring Container|Servlet Context|
|Spring concept|Web application concept|

---

# 6. WebSocket Scope

For WebSocket connections.

```java
@Component
@Scope("websocket")
public class ChatSession {
}
```

One bean per WebSocket session.

---

# Summary Table

|Scope|Instances|Lifetime|Common Usage|
|---|---|---|---|
|singleton|1|Application lifetime|Services, Repositories|
|prototype|Many|Until garbage collected|Stateful objects|
|request|1/request|HTTP request|Request data|
|session|1/session|User session|Shopping carts|
|application|1/application|Web app lifetime|Global web data|
|websocket|1/socket|WebSocket lifetime|Real-time communication|

---

## How Spring decides

When you write:

```java
@Service
public class PaymentService {
}
```

Spring assumes:

```java
@Scope("singleton")
```

Equivalent:

```java
@Service
@Scope(ConfigurableBeanFactory.SCOPE_SINGLETON)
public class PaymentService {
}
```

---

## Important professional note

Singleton beans should usually be **stateless**.

Bad:

```java
@Service
public class CounterService {

    private int count;

    public void increase(){
        count++;
    }
}
```

Because every user shares the same `count`.

Better:

```java
@Service
public class CounterService {

    public int calculate(int value){
        return value + 1;
    }
}
```

No shared mutable state.

---

## In real Spring Boot applications

Most of your classes are:

```
Controller      -> singleton
Service         -> singleton
Repository      -> singleton
Component       -> singleton
Configuration   -> singleton
```

You rarely use:

```
prototype
request
session
websocket
```

unless you specifically need different lifecycles.

[[Spring Framework]]