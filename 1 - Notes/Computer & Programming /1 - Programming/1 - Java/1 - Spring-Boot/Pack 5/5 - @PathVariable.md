

## Simple mental model

A URL path is like a **postal address**: `/users/5/orders/12` reads as "user number 5, order number 12". The numbers are not fixed text; they change per request. `@PathVariable` tells Spring: _"Take the piece of the URL sitting in this slot and hand it to me as a Java variable."_

```
URL:  /api/users/5/orders/12
              │        │
              ▼        ▼
   {userId} = 5    {orderId} = 12
```

## Definition

`@PathVariable` binds a **URI template variable** (a `{placeholder}` in the mapping's path) to a method parameter. Spring extracts the matching segment from the actual URL and converts it from text to the parameter's Java type.

```java
@GetMapping("/api/users/{id}")
public User getOne(@PathVariable Long id) {
    return service.findById(id);
}
```

Request `GET /api/users/42` → `id` is `42L`.

Test it:

```bash
curl http://localhost:8080/api/users/42
```

## Its parameters

|Parameter|Default|Meaning|
|---|---|---|
|`name` / `value`|(variable name)|Which `{placeholder}` to bind (aliases of each other)|
|`required`|`true`|If `false`, the variable may be absent (only useful with multiple paths)|

### 1. `name` / `value`: which placeholder

If the Java variable name equals the placeholder, you can omit it:

```java
@GetMapping("/users/{id}")
public User a(@PathVariable Long id) { ... }               // implicit
public User b(@PathVariable("id") Long userId) { ... }     // explicit, different Java name
public User c(@PathVariable(name = "id") Long userId) { ... } // same as above
```

**Why implicit works:** Spring reads parameter names through the `-parameters` compiler flag, which Spring Boot's Maven/Gradle plugins enable for you. In a plain `javac` setup, without that flag, you must write the name explicitly or you get an error.

### 2. `required`: optional path variables

A path variable is normally mandatory, because the URL wouldn't match without it. `required = false` only makes sense when you map **several paths to one method**:

```java
@GetMapping({"/users", "/users/{id}"})
public Object get(@PathVariable(required = false) Long id) {
    return id == null ? service.findAll() : service.findById(id);
}
```

A cleaner modern alternative is `Optional`:

```java
@GetMapping({"/users", "/users/{id}"})
public Object get(@PathVariable Optional<Long> id) { ... }
```

## Multiple variables

```java
@GetMapping("/users/{userId}/orders/{orderId}")
public Order getOrder(@PathVariable Long userId,
                      @PathVariable Long orderId) {
    return service.findOrder(userId, orderId);
}
```

## Capture all variables in a Map

```java
@GetMapping("/users/{userId}/orders/{orderId}")
public String all(@PathVariable Map<String, String> vars) {
    // {"userId": "5", "orderId": "12"}
    return vars.toString();
}
```

## Supported types (automatic conversion)

The URL is text, so Spring converts it for you:

```java
@PathVariable Long id               // "42" → 42
@PathVariable int year              // "2026" → 2026
@PathVariable UUID token            // "550e8400-..." → UUID
@PathVariable String username       // stays text
@PathVariable LocalDate date        // needs @DateTimeFormat (see gotchas)
@PathVariable Status status         // enum: "ACTIVE" → Status.ACTIVE
```

## Regex constraints inside the placeholder

Syntax: `{name:regex}`

```java
@GetMapping("/users/{id:[0-9]+}")        // digits only
public User byId(@PathVariable Long id) { ... }

@GetMapping("/users/{name:[a-zA-Z]+}")   // letters only
public User byName(@PathVariable String name) { ... }
```

This lets you have **two methods on the same URL shape**, distinguished by what the segment looks like. `/users/42` goes to `byId`, `/users/alireza` goes to `byName`.

## Nuances and gotchas

**1. Type mismatch gives 400, not 500.** `/users/abc` for a `Long` throws `MethodArgumentTypeMismatchException`, which Spring turns into **400 Bad Request**.

**2. Missing resource is your job.** `/users/999` matches the mapping fine. Whether user 999 exists is for your service to decide. Throw a custom `UserNotFoundException` and map it to 404 in a `@RestControllerAdvice`.

**3. Dots are not part of the match by default in modern Spring.** In older versions `/files/report.pdf` could silently drop `.pdf` (suffix pattern matching). Spring Boot 3 / Spring 6 no longer does this, so the whole `report.pdf` is captured. If you read old tutorials, this is a known difference.

**4. A variable matches exactly one segment.** `{name}` never matches a `/`. To capture the rest of a path, use `{*path}`:

```java
@GetMapping("/files/{*path}")
public String file(@PathVariable String path) {
    return path;   // /files/docs/a/b.txt → "/docs/a/b.txt"
}
```

**5. Encoded characters.** A space arrives as `%20` and Spring decodes it for you. But an encoded slash `%2F` is **rejected by default** by Spring Security's firewall and many servers, so avoid putting slashes inside values.

**6. Dates need a format hint:**

```java
@GetMapping("/reports/{date}")
public Report r(@PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) { ... }
// /reports/2026-10-03
```

**7. Specific beats generic.** `/users/me` wins over `/users/{id}`, so you can safely define both.

**8. Don't put sensitive data in the path.** URLs end up in logs, browser history, and proxies.

## `@PathVariable` vs `@RequestParam` (design rule)

||`@PathVariable`|`@RequestParam`|
|---|---|---|
|Location|`/users/5`|`/users?id=5`|
|Purpose|**Identifies** a specific resource|**Filters / modifies** a collection|
|Required by default|Yes (URL wouldn't match)|Yes (but easily made optional)|
|Example|`/users/5/orders/12`|`/orders?status=paid&page=2`|

Rule of thumb: if removing the value makes the URL point to a _different thing_, use the path. If removing it just changes _how a list is filtered or shown_, use a query param.


[[06 - @PathVariable 🍋‍🟩]]
[[Spring Framework]]