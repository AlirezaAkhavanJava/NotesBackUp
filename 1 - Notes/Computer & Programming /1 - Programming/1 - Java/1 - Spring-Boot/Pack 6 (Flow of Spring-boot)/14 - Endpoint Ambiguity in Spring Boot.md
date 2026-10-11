

**Endpoint ambiguity** happens when Spring MVC cannot determine **which controller method should handle an incoming HTTP request** because multiple methods match the same request.

In simple terms:

> Two or more endpoints have the same "address" from Spring's perspective.

Spring needs a unique mapping:

```
HTTP Method + URL Path + Parameters + Headers + Content-Type
```

to select exactly one handler.

---

## Example of ambiguous endpoints

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping("/{name}")
    public User getUserByName(@PathVariable String name) {
        return service.findByName(name);
    }
}
```

Both create:

```
GET /users/{something}
```

Spring sees:

```
GET /users/123
```

Could be:

```
getUser(123)
```

or:

```
getUserByName("123")
```

Spring cannot decide.

Error:

```
Ambiguous mapping.
Cannot map 'userController' method
```

---

# How Spring matches endpoints

Spring checks:

## 1. HTTP Method

Different methods are OK:

```java
@GetMapping("/users")
public List<User> getUsers()

@PostMapping("/users")
public User createUser()
```

They are different:

```
GET  /users
POST /users
```

No ambiguity.

---

## 2. Path

Bad:

```java
@GetMapping("/users/{id}")
@GetMapping("/users/{username}")
```

Good:

```java
@GetMapping("/users/id/{id}")

@GetMapping("/users/name/{username}")
```

Now:

```
GET /users/id/10

GET /users/name/ali
```

are unique.

---

## 3. Use query parameters

Instead of:

```java
@GetMapping("/users/{value}")
```

Use:

```java
@GetMapping("/users")
public User findUser(
        @RequestParam Long id
)
```

Request:

```
GET /users?id=10
```

Another:

```java
@GetMapping("/users")
public User findUser(
        @RequestParam String username
)
```

Request:

```
GET /users?username=ali
```

---

However, this can still be ambiguous:

```java
@GetMapping("/users")
public User findById(
    @RequestParam String id
)

@GetMapping("/users")
public User findByName(
    @RequestParam String username
)
```

because:

```
GET /users
```

matches both.

Use parameter mapping:

```java
@GetMapping(
    value="/users",
    params="id"
)
public User findById(
    @RequestParam Long id
)
```

and:

```java
@GetMapping(
    value="/users",
    params="username"
)
public User findByUsername(
    @RequestParam String username
)
```

Now Spring knows:

```
GET /users?id=10

       |
       v
findById()


GET /users?username=ali

       |
       v
findByUsername()
```

---

# 4. Use PathVariable constraints

Example:

```java
@GetMapping("/{id}")
public User getUser(
    @PathVariable Long id
)
```

Spring cannot automatically know:

```
/users/123
```

means ID.

You can separate:

```java
@GetMapping("/users/{id:\\d+}")
public User getById(
    @PathVariable Long id
)
```

Regex:

```
\d+
```

means:

```
only numbers
```

Matches:

```
/users/123
```

Does not match:

```
/users/ali
```

Then:

```java
@GetMapping("/users/{username:[a-zA-Z]+}")
public User getByUsername(
    @PathVariable String username
)
```

Matches:

```
/users/ali
```

---

# 5. Avoid overly generic paths

Bad API design:

```
GET /api/{something}
```

because everything matches.

Example:

```java
@GetMapping("/{value}")
```

Could mean:

```
/users
/products
/orders
/settings
```

Better:

```
GET /users/{id}

GET /products/{id}

GET /orders/{id}
```

---

# REST API design approach

A clean Spring Boot API usually follows:

```
/api/v1/resource
```

Example:

```
GET    /api/v1/users
POST   /api/v1/users

GET    /api/v1/users/{id}
PUT    /api/v1/users/{id}
DELETE /api/v1/users/{id}
```

Controller:

```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {


    @GetMapping
    public List<User> findAll()


    @GetMapping("/{id}")
    public User findById(
        @PathVariable Long id
    )


    @PostMapping
    public User create(
        @RequestBody CreateUserRequest request
    )
}
```

This is almost impossible to confuse.

---

# Professional rule

Avoid designing endpoints where the **same position means different things**.

Bad:

```
/users/{value}
```

where value can be:

```
id
username
email
```

Good:

```
/users/id/{id}

/users/username/{username}

/users/email/{email}
```

or:

```
/users/{id}
```

and search:

```
/users?username=ali
```

---

In large Spring Boot projects, endpoint ambiguity is usually prevented by:

1. Clear resource naming
    
2. API versioning
    
3. Consistent REST conventions
    
4. Avoiding overloaded paths
    
5. Using DTOs and explicit request parameters
    
6. Keeping Controller mappings simple and predictable


[[Spring Framework]]