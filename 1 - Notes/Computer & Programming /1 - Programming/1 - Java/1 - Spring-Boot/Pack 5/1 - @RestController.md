

In Spring MVC, `@RestController` is essentially a **specialized `@Controller` for HTTP APIs**.

### `@Controller`

`@Controller` marks a class as a Spring MVC controller. Its methods usually return a **view name**.

```java
@Controller
public class UserController {

    @GetMapping("/users")
    public String users() {
        return "users";
    }
}
```

Here, `"users"` means:

> Find and render a view/template called `users`.

For example, Spring might render:

```text
templates/users.html
```

---

### `@RestController`

`@RestController` is designed for REST APIs. Its methods return **data directly in the HTTP response body**.

```java
@RestController
public class UserController {

    @GetMapping("/users")
    public List<User> users() {
        return userService.findAll();
    }
}
```

Spring converts the returned `List<User>` into JSON:

```json
[
    {
        "id": 1,
        "name": "Alireza"
    },
    {
        "id": 2,
        "name": "John"
    }
]
```

---

## The important difference

Conceptually:

```java
@RestController
```

is equivalent to:

```java
@Controller
@ResponseBody
```

So:

```java
@RestController
public class UserController {

    @GetMapping("/users")
    public User getUser() {
        return new User(1, "Alireza");
    }
}
```

is effectively:

```java
@Controller
public class UserController {

    @GetMapping("/users")
    @ResponseBody
    public User getUser() {
        return new User(1, "Alireza");
    }
}
```

`@ResponseBody` tells Spring:

> Don't interpret this return value as a view name. Put it directly into the HTTP response body.

---

### Side-by-side

||`@Controller`|`@RestController`|
|---|---|---|
|Purpose|MVC web pages|REST APIs|
|Return value|Usually view name|Response data|
|`"users"`|View named `users`|String `"users"` in response|
|`User` object|Usually needs `@ResponseBody`|Automatically serialized|
|JSON API|Possible|Standard use|
|Equivalent|—|`@Controller + @ResponseBody`|

### Mental model

Think:

```text
@Controller
    ↓
HTTP request
    ↓
Controller method
    ↓
View name
    ↓
HTML page
```

versus:

```text
@RestController
    ↓
HTTP request
    ↓
Controller method
    ↓
Java object
    ↓
HttpMessageConverter
    ↓
JSON/XML/etc.
    ↓
HTTP response
```

For the **Spring Boot backend + Angular frontend** architecture you're working with, you'll normally use **`@RestController`**, because Angular consumes your backend's HTTP API rather than Spring rendering the HTML pages.


[[Spring Framework]]