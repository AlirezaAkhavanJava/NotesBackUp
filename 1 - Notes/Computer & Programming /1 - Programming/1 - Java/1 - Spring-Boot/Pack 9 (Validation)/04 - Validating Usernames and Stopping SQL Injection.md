



`@Pattern` does **not** prevent SQL injection. What prevents it is never building SQL by gluing user input into a string, which means using parameterized queries. `@Pattern` is still worth using on a username, but as a second layer of defense and as input hygiene, not as the thing that makes your database safe.

That might sound like bad news, but it's good news: the real fix is easier than writing a clever regex.

## What `@Pattern` is

`@Pattern` is a Bean Validation annotation (`jakarta.validation.constraints.Pattern`) that checks whether a `String` matches a regular expression. If it doesn't, validation fails and Spring throws the exception your handler already catches.

You need the validation starter in your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

## A mental model: the door check and the lock

Think of `@Pattern` as a check at the front door of your app: "usernames here are only letters, digits, and underscores, 3 to 20 characters. Anything else, turn around." It makes sure what enters has the right _shape_.

Parameterized queries are the lock on the database itself. Even if something strange gets past the door, the database never treats it as SQL code.

The analogy breaks down in one important way: a door check can be wrong, bypassed, or forgotten on one endpoint (a developer adds a new controller and skips `@Valid`). The lock sits at the one place that matters and works no matter how the input arrived. So you want both, but only one of them is the actual defense.

## How SQL injection works

SQL injection happens when user input becomes part of the SQL _code_ rather than being treated as _data_. Here's the vulnerable version:

```java
public User findByUsername(String username) {
    String sql = "SELECT * FROM users WHERE username = '" + username + "'";
    return jdbcTemplate.queryForObject(sql, new UserRowMapper());
}
```

If the client sends `alice`, the SQL is:

```sql
SELECT * FROM users WHERE username = 'alice'
```

If the client sends `' OR '1'='1`, the SQL becomes:

```sql
SELECT * FROM users WHERE username = '' OR '1'='1'
```

That condition is always true, so the query returns every user. The attacker's text escaped the quotes and became part of the command. The problem lives in line 2, the string concatenation. Nothing about the username itself is "dangerous" in the abstract; the danger comes from how you used it.

## The real fix: parameters

With a parameterized query, you send the SQL structure and the values separately. The database compiles the structure first, and the values can never change it.

```java
public User findByUsername(String username) {
    String sql = "SELECT * FROM users WHERE username = ?";
    return jdbcTemplate.queryForObject(sql, new UserRowMapper(), username);
}
```

Line by line:

- `?` is a placeholder. The SQL text is fixed and contains no user data.
- `username` is passed as a separate argument, and the JDBC driver sends it as a value. If it contains `' OR '1'='1`, the database simply looks for a user whose name is literally that odd string, and finds none.

With Spring Data JPA, you're mostly safe by default:

```java
public interface UserRepository extends JpaRepository<User, Long> {

    // Derived query: Spring generates a parameterized query for you
    Optional<User> findByUsername(String username);

    // Custom query with a named parameter: also safe
    @Query("SELECT u FROM User u WHERE u.username = :username")
    Optional<User> searchByUsername(@Param("username") String username);
}
```

Both of these are parameterized. The unsafe version in JPA looks like this:

```java
// DON'T: concatenation inside a query string
entityManager.createQuery("SELECT u FROM User u WHERE u.username = '" + username + "'");
```

The rule is simple: **if user input ever appears inside a string that becomes a query, that's the bug**, no matter which library you use.

## Now, `@Pattern` on the username

Put the annotation on a field of the request object:

```java
public record RegisterRequest(

        @NotBlank(message = "username is required")
        @Pattern(
            regexp = "^[a-zA-Z0-9_]{3,20}$",
            message = "username must be 3-20 characters: letters, digits, or underscore"
        )
        String username,

        @NotBlank
        String password
) {}
```

And in the controller, trigger validation with `@Valid`:

```java
@PostMapping("/register")
public ResponseEntity<Void> register(@Valid @RequestBody RegisterRequest request) {
    userService.register(request);
    return ResponseEntity.status(HttpStatus.CREATED).build();
}
```

Walking through the regex `^[a-zA-Z0-9_]{3,20}$`:

- `^` means start of the string.
- `[a-zA-Z0-9_]` is one character from this allowed set: lowercase letters, uppercase letters, digits, underscore.
- `{3,20}` means between 3 and 20 of those characters.
- `$` means end of the string.

A small detail: `@Pattern` already requires the _entire_ string to match, so `^` and `$` are technically optional here. Many people keep them anyway because they make the intent obvious, and it's harmless.

Here is what happens with different inputs:

|Input|Result|
|---|---|
|`alice_99`|valid|
|`al`|too short, rejected|
|`' OR '1'='1`|has spaces and quotes, rejected|
|`admin'--`|has `'` and `-`, rejected|
|`null` (field missing)|**passes `@Pattern`**, caught by `@NotBlank`|

That last row is an edge case people miss and it deserves its own section.

## Edge cases and the "why it works this way"

**`null` passes `@Pattern`.** By Bean Validation convention, most constraints treat `null` as valid, on the idea that "is it present?" and "is it well-formed?" are separate questions. That's why `@NotBlank` sits beside `@Pattern`. `@NotBlank` also rejects `""` and `" "`, which `@NotNull` would allow.

**Whitelist, never blacklist.** Notice the regex describes what is _allowed_, not what is forbidden. The tempting alternative, rejecting usernames that contain `'`, `--`, `DROP`, `;`, is a trap. Attackers have endless encodings and tricks, and you will always miss one. Whitelists are short and complete: anything outside the set is rejected, period.

**It can't protect fields that must allow anything.** A bio, a comment, a last name like `O'Brien`: these legitimately contain quotes and punctuation, so no restrictive pattern can apply. For those fields, parameterized queries are your _only_ defense, which is exactly why they're the real answer. If you built your safety around `@Pattern`, those fields would be wide open.

**Java's `\w` is ASCII-only by default.** `\w` means `[a-zA-Z0-9_]` unless you enable Unicode flags. If you want to allow letters from any language, use `\p{L}`: `^[\p{L}0-9_]{3,20}$`. Decide this on purpose, because allowing Unicode also opens up look-alike characters (a Cyrillic `а` that looks like a Latin `a`), which matters for impersonation.

**Beware catastrophic regexes.** A pattern with nested quantifiers like `^(a+)+$` can take exponential time on certain inputs (ReDoS), letting an attacker freeze a thread with one request. Simple character-class patterns like the one above are safe.

**Whitespace.** `" alice"` fails the pattern because of the leading space. That's usually right for usernames, but if you'd rather be forgiving, trim in your service before validation or normalize to lowercase to avoid `Alice` and `alice` being two accounts.

**Don't echo the input back.** Your message says "username must be 3-20 characters...", not "`admin'--` is invalid". Reflecting raw input into responses can create other problems (log injection, XSS if a front-end renders it carelessly).

## Validating path variables and query parameters

The `@Valid @RequestBody` approach only works for request bodies. For `GET /users/{username}`, put the constraint directly on the parameter and `@Validated` on the class:

```java
@RestController
@RequestMapping("/users")
@Validated
public class UserController {

    @GetMapping("/{username}")
    public UserResponse getUser(
            @PathVariable
            @Pattern(regexp = "^[a-zA-Z0-9_]{3,20}$", message = "invalid username format")
            String username) {
        return userService.getByUsername(username);
    }
}
```

This throws a different exception than the body case: `ConstraintViolationException` (and in Spring 6.1+ / Boot 3.2+, if you _don't_ use class-level `@Validated`, built-in method validation throws `HandlerMethodValidationException` instead). Your existing handler for `MethodArgumentNotValidException` won't catch either, so add one:

```java
@ExceptionHandler(ConstraintViolationException.class)
public ResponseEntity<Map<String, String>> handleConstraintViolation(
        ConstraintViolationException ex) {

    Map<String, String> errors = new LinkedHashMap<>();
    ex.getConstraintViolations().forEach(v ->
            errors.putIfAbsent(v.getPropertyPath().toString(), v.getMessage()));

    return ResponseEntity.badRequest().body(errors);
}
```

- `getConstraintViolations()` returns the set of failed rules.
- `getPropertyPath()` gives something like `getUser.username` (method name plus parameter name), so you may want to trim it to the last segment for a cleaner response.

## Reusing the rule: a custom annotation

If the username rule appears in three DTOs, copy-pasting the regex invites inconsistencies. Bundle it into one annotation:

```java
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = {})
@NotBlank
@Pattern(regexp = "^[a-zA-Z0-9_]{3,20}$")
public @interface ValidUsername {
    String message() default "username must be 3-20 characters: letters, digits, or underscore";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

Now `@ValidUsername String username` applies both rules everywhere. This is called a _composed constraint_: `@Constraint(validatedBy = {})` says there's no custom validator class, and the annotation just combines the ones stacked on it.

## Alternatives and companions

- **`@Size(min = 3, max = 20)`**: simpler if you only care about length, and gives a clearer message than a regex failure.
- **A custom `ConstraintValidator`**: when the rule needs logic a regex can't express, like checking a reserved-words list (`admin`, `root`) or querying the database for uniqueness.
- **Least-privilege database user**: the account your app connects with should not be able to `DROP TABLE`. If something does go wrong, the damage is limited.
- **Stored procedures**: not automatically safe. If the procedure builds dynamic SQL from its arguments, it has the same bug inside the database.
- **ORM or query builders** (JPA, jOOQ): safe when you use their parameter features, unsafe if you concatenate strings into them.

## Where this leaves you

Think of the layers like this: `@Pattern` keeps junk and attacks from getting far (and gives users friendly error messages), while parameterized queries make injection structurally impossible. Use both, but if you could only have one, keep the parameters.




[[Spring Framework]]