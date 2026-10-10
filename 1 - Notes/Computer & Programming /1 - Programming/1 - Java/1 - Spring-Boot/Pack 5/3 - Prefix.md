
A **prefix** is something placed **at the beginning of something else** to give it additional meaning or identify it.

### In general

```text
PREFIX + WORD
```

For example:

```text
un + happy = unhappy
re + build = rebuild
```

`un-` and `re-` are prefixes because they come **before** the original word.

### In Spring REST endpoints

When we say a **URL prefix**, we mean a common path placed at the beginning of multiple endpoints.

```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    @GetMapping
    public List<User> getUsers() {}

    @PostMapping
    public User createUser() {}

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {}
}
```

Here:

```text
/api/v1/users
```

is the **prefix/base path**.

So Spring combines it with the method mappings:

```text
@RequestMapping("/api/v1/users")
             +
@GetMapping
             ↓
GET /api/v1/users

@RequestMapping("/api/v1/users")
             +
@PostMapping
             ↓
POST /api/v1/users

@RequestMapping("/api/v1/users")
             +
@GetMapping("/{id}")
             ↓
GET /api/v1/users/123
```

So in this context, you can think of **prefix = common beginning of a path**.


[[Spring Framework]]