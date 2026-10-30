

---
### 1. Library

A **library** is a collection of pre-written code that **your program calls** to perform specific tasks.

> A library is a collection of classes, not a single class.

> **Your code → calls → Library**

Example in Java:

```java
List<String> names = new ArrayList<>();
Collections.sort(names);
```

`java.util` provides library classes such as `ArrayList` and `Collections`.

**Key idea:** **You control the flow.** You decide when and how to call the library.

Examples:

- Jackson — JSON processing
    
- Lombok — compile-time code generation
    
- Apache Commons — utility functions
    
- Java Collections Framework — data structures and algorithms
    

---

### 2. Framework

A **framework** is a larger software structure that provides an architecture and **controls the execution flow of your application**.

> **Framework → calls → Your code**

This is commonly called **Inversion of Control (IoC)**.

For example, in Spring Boot:

```java
@RestController
public class UserController {

    @GetMapping("/users")
    public String users() {
        return "users";
    }
}
```

You don't write:

```java
while (serverIsRunning) {
    if (request.path.equals("/users")) {
        users();
    }
}
```

Spring's infrastructure handles the HTTP server, request routing, object creation, dependency injection, etc., and calls your `users()` method when appropriate.

**Key idea:** **The framework controls the flow; you provide components that fit into its architecture.**

Examples:

- Spring Framework
    
- Spring Boot
    
- Angular
    
- Django
    
- Ruby on Rails
    

---

### 3. API

An **API (Application Programming Interface)** is a **defined interface/contract through which software can interact with another piece of software**.

It specifies things like:

- what operations are available
    
- what inputs they accept
    
- what outputs they produce
    
- how they should be called
    

For example:

```java
String text = "hello";
int length = text.length();
```

`String.length()` is part of Java's API.

APIs aren't necessarily libraries.

For example, a REST API:

```http
GET /api/users/42
```

might return:

```json
{
    "id": 42,
    "name": "Alireza"
}
```

Your application interacts with another application through that API.

---

## The important distinction

Think of them like this:

|Concept|What it is|Who controls the flow?|
|---|---|---|
|**Library**|Reusable implementation/code|**Your application**|
|**Framework**|Application structure + infrastructure|**Framework**|
|**API**|Interface/contract for interaction|Neither; defines **how to interact**|

### A useful mental model

Imagine you're building a house:

**Library** = a toolbox.

You pick up a hammer whenever **you** need it.

**Framework** = a construction system.

It tells you where the walls, doors, wiring, etc. fit, and you build your components according to its rules.

**API** = the interface/specification.

It tells you:

> "Give me these inputs, and I'll provide this output."

---

### One important detail

A framework can **use libraries**, and a library can **expose an API**.

For example:

```text
Spring Boot
    │
    ├── uses many libraries
    │
    ├── provides APIs
    │
    └── controls application lifecycle
             │
             └── calls your code
```

So **library, framework, and API aren't mutually exclusive categories**. They describe different aspects of software.

The most important distinction to remember is:

> **Library = you call it.**  
> **Framework = it calls you.**  
> **API = the interface/contract you use to communicate with it.**


[[Java]]
[[Spring Framework]]