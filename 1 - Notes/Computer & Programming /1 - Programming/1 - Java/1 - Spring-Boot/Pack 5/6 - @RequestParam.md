

## Simple mental model

If `@PathVariable` is the **address** of a house (`/users/5`), `@RequestParam` is the **sticky notes attached to the request**: "sort by name", "page 2", "only active ones". They don't say _which_ thing you want, they adjust _how_ you want it.

```
URL:  /api/users?role=admin&page=2&size=10
                 │          │      │
                 ▼          ▼      ▼
            role="admin"  page=2  size=10
```

The part after `?` is the **query string**: `key=value` pairs joined by `&`.

## Definition

`@RequestParam` binds a **request parameter** to a method parameter. Spring looks up the key by name, then converts the text value to the parameter's Java type. It reads from two sources:

1. The **query string** (`?page=2`)
2. **Form data** (`application/x-www-form-urlencoded` or `multipart/form-data` bodies)

```java
@GetMapping("/api/users")
public List<User> list(@RequestParam String role) {
    return service.findByRole(role);
}
```

```bash
curl "http://localhost:8080/api/users?role=admin"
```

(Quote the URL in the terminal, otherwise bash treats `&` as "run in background".)

## Its parameters

|Parameter|Default|Meaning|
|---|---|---|
|`name` / `value`|(Java variable name)|The query parameter key (aliases)|
|`required`|`true`|Missing → **400 Bad Request**|
|`defaultValue`|none|Fallback when the key is missing **or empty**|

### 1. `name` / `value`

```java
@RequestParam String role                 // key "role" (implicit, needs -parameters flag)
@RequestParam("q") String searchText      // key "q" → Java variable searchText
@RequestParam(name = "q") String text     // same as above
```

### 2. `required`

```java
@GetMapping("/users")
public List<User> list(@RequestParam(required = false) String name) {
    // /users          → name == null
    // /users?name=ali → name == "ali"
}
```

Equivalent, and often cleaner:

```java
public List<User> list(@RequestParam Optional<String> name) { ... }
```

### 3. `defaultValue`

```java
@GetMapping("/users")
public Page<User> list(
        @RequestParam(defaultValue = "0")  int page,
        @RequestParam(defaultValue = "10") int size) { ... }
```

- `/users` → page=0, size=10
- `/users?page=3` → page=3, size=10
- `/users?page=` (empty) → page=0 (empty counts as missing)

Setting `defaultValue` **implicitly sets `required = false`**. Always a `String` in the annotation; Spring converts it to the target type.

## Supported types

```java
@RequestParam int page                     // "2" → 2
@RequestParam boolean active               // "true" → true
@RequestParam LocalDate from               // needs @DateTimeFormat
@RequestParam Status status                // enum: "ACTIVE" → Status.ACTIVE
@RequestParam List<Long> ids               // ?ids=1,2,3  OR  ?ids=1&ids=2&ids=3
@RequestParam String[] tags                // same multi-value handling
@RequestParam Map<String, String> all      // captures ALL query params
@RequestParam MultiValueMap<String, String> allMulti  // all params, multiple values per key
@RequestParam("file") MultipartFile file   // file upload
```

### Multi-value example

```java
@GetMapping("/users")
public List<User> byIds(@RequestParam List<Long> ids) { ... }
```

Both `/users?ids=1,2,3` and `/users?ids=1&ids=2&ids=3` give `[1, 2, 3]`.

### Capture everything

```java
@GetMapping("/search")
public Map<String, String> all(@RequestParam Map<String, String> filters) {
    return filters;   // /search?color=red&size=M → {color=red, size=M}
}
```

Useful for dynamic filtering where you don't know the keys in advance.

### File upload

```java
@PostMapping(path = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public String upload(@RequestParam("file") MultipartFile file,
                     @RequestParam(defaultValue = "") String description) {
    return file.getOriginalFilename() + " (" + file.getSize() + " bytes)";
}
```

```bash
curl -F "file=@photo.jpg" -F "description=My photo" http://localhost:8080/upload
```

## Full example: filtering + paging + sorting

```java
@GetMapping("/api/users")
public List<User> search(
        @RequestParam(required = false) String name,
        @RequestParam(required = false) Boolean active,
        @RequestParam(defaultValue = "name") String sortBy,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size) {
    return service.search(name, active, sortBy, page, size);
}
```

`GET /api/users?name=ali&active=true&page=1` works, and every other parameter falls back to its default.

## Nuances and gotchas

**1. Primitives cannot be null.** `@RequestParam(required = false) int page` with no `page` in the URL throws an error, because Spring would have to assign `null` to an `int`. Fix it with `Integer`, `Optional<Integer>`, or `defaultValue`.

**2. Type mismatch → 400.** `?page=abc` for an `int` gives `MethodArgumentTypeMismatchException` → **400**, not 500.

**3. Missing required param → 400.** The exception is `MissingServletRequestParameterException`. Customize the message in a `@RestControllerAdvice` if you want friendly JSON errors.

**4. Empty vs missing.** `?name=` (key present, empty value) gives `""` for a `String`, not `null`. With `defaultValue` set, though, empty is replaced by the default.

**5. Implicit naming, again.** Omitting `name` relies on the `-parameters` compiler flag. Spring Boot's build plugins set it. If you ever compile with plain `javac`, write the name explicitly.

**6. It's optional to even write `@RequestParam` on simple types?** Technically, for a simple type like `String` or `int` with **no annotation at all**, Spring treats it as an implicit `@RequestParam(required = false)`. This surprises people: a parameter with no annotation is _not_ an error. Being explicit is clearer and recommended.

**7. Dates need a hint:**

```java
@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from
// ?from=2026-10-03
```

**8. Don't use it for sensitive data.** Query strings land in server logs, browser history, and proxy logs. Passwords and tokens belong in headers or the body.

**9. Don't use it to receive JSON.** If the client sends a JSON body, you need `@RequestBody`. `@RequestParam` only understands query string and form data.

**10. It can bind a complex object, but via a different annotation.** If you have many params, instead of 8 `@RequestParam` arguments, use a plain object (`@ModelAttribute` is implied):

```java
public record UserFilter(String name, Boolean active, Integer page) {}

@GetMapping("/users")
public List<User> search(UserFilter filter) { ... }
```

Spring fills the fields from the matching query keys.

## The three annotations compared

||`@PathVariable`|`@RequestParam`|`@RequestBody`|
|---|---|---|---|
|Reads from|URL path|query string / form|HTTP body|
|Example|`/users/5`|`/users?role=admin`|`{ "name": "Ali" }`|
|Best for|identifying a resource|filter, sort, paging|creating/updating data|
|Missing value|no URL match (404)|400 (or default)|400|




[[Spring Framework]]
[[07 - @RequestParam]]