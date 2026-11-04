

Validation is the act of checking that incoming data obeys a set of rules before your application acts on it. In Spring Boot you describe those rules declaratively, as annotations such as `@NotBlank` or `@Size` on the fields of a request DTO, and the framework enforces them for you at the controller boundary. The key idea to hold onto is that **there are three different kinds of validation, each answering a different question**: "is this input well-formed?", "is this operation allowed by our business rules?", and "will this data satisfy the database's integrity rules?". Most validation confusion comes from mixing these up, so we'll build each one and then see how they fit together.

## The problem: bad input should never reach your logic

Imagine a client sends this:

```json
{ "email": "hello", "password": "x" }
```

Without declarative validation, you write checks by hand:

```java
if (email == null || email.isBlank()) { ... }
if (!email.contains("@")) { ... }
if (password.length() < 8) { ... }
```

This is repetitive, easy to forget, and clutters your service with noise. Worse, if you skip it, garbage travels deep into the system and fails late, often as an ugly database exception. Validation at the edge lets you reject bad input immediately with a clear `400 Bad Request`.

## Setting it up

Add the starter (it brings the Jakarta Bean Validation API plus Hibernate Validator, the implementation):

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

Then annotate the request DTO and trigger validation with `@Valid`:

```java
public record CreateUserRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 72) String password) {}
```

```java
@PostMapping
public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
    return userService.create(request);
}
```

`@Valid` is the trigger. Without it, the annotations on the DTO are just decoration and nothing checks them.

What happens on a request: Jackson converts the JSON into a `CreateUserRequest`, then Spring runs the validator against it. If any constraint fails, Spring throws a `MethodArgumentNotValidException` before your controller method body runs, and by default that becomes a `400`. If instead the JSON itself is malformed, you get a different exception (`HttpMessageNotReadableException`), because that failure happens earlier, during parsing rather than validation.

## The constraints you will use constantly

**The three "is it there?" constraints** are the most commonly confused, so compare them directly:

|Constraint|Rejects `null`|Rejects `""`|Rejects `" "`|
|---|---|---|---|
|`@NotNull`|yes|no|no|
|`@NotEmpty`|yes|yes|no|
|`@NotBlank`|yes|yes|yes|

`@NotBlank` applies only to strings and is usually what you want for user-typed text. `@NotEmpty` also works on collections, arrays, and maps (a list that must have at least one element). `@NotNull` works on anything.

**Important detail that explains why we stack annotations:** almost every other constraint treats `null` as valid. `@Size(min = 8)` on a `null` password passes, and `@Email` on `null` passes too. These constraints only judge a value if one exists, and presence is a separate concern. That is why you write `@NotBlank @Email` together.

**Size and range:**

```java
@Size(min = 8, max = 72) String password;   // length of a string, or size of a collection/map/array
@Min(18) @Max(120) Integer age;             // numeric bounds
@Positive BigDecimal price;                 // > 0
@PositiveOrZero BigDecimal discount;        // >= 0
```

**Format:**

```java
@Email String email;
@Pattern(regexp = "[A-Z]{2}\\d{4}") String code;   // e.g. AB1234
```

Two corrections worth knowing: `@Pattern` must match the **entire** value, so the `^` and `$` anchors are unnecessary. And `@Email` is lenient by default. Hibernate Validator accepts `user@localhost`, so if you need a real domain, add a `@Pattern` or a custom constraint.

**Dates:** `@Past`, `@PastOrPresent`, `@Future`, `@FutureOrPresent`.  
**Others you will meet:** `@AssertTrue`, `@AssertFalse`, `@DecimalMin`, `@DecimalMax`, `@Digits`.

Prefer a dedicated constraint over regex whenever one exists, since it is clearer and less error-prone.

## Validation checks; it never fixes

A validator only answers yes or no. It will not trim whitespace or correct an email. If a constraint fails, you get a set of `ConstraintViolation` objects describing what went wrong, and the request is rejected. If you want to normalize input (trim, lowercase), do it explicitly in the mapper or service.

## Controlling the error response

The default `400` body is minimal and not very helpful to a client. In real projects you add a handler that turns violations into a clear, consistent payload:

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
          .forEach(e -> errors.put(e.getField(), e.getDefaultMessage()));
        return ResponseEntity.badRequest().body(errors);
    }
}
```

That produces something like `{"email": "must be a well-formed email address", "password": "size must be between 8 and 72"}`. You can also set your own messages: `@Size(min = 8, message = "Password must be at least 8 characters")`.

## Things the basics don't show you (but you will hit quickly)

**Nested objects need `@Valid` too.** Validation does not automatically descend into fields:

```java
public record CreateOrderRequest(
        @NotNull @Valid AddressRequest address,
        @NotEmpty List<@Valid OrderItemRequest> items) {}
```

Without `@Valid` on `address`, the constraints inside `AddressRequest` are silently ignored.

**Primitives can't be null, which hides missing fields.** If `age` is declared as `int` and the client omits it, Jackson fills in `0`, and `@NotNull` can never catch it. Use wrapper types (`Integer`) when "missing" must be distinguishable from a real value.

**Path variables and query parameters** are validated differently. Put `@Validated` on the controller class, and constraints go directly on the parameters:

```java
@Validated
@RestController
public class UserController {
    @GetMapping("/users/{id}")
    public UserResponse get(@PathVariable @Positive Long id) { ... }
}
```

**Validation groups** let the same DTO apply different rules in different situations (for example, `id` required on update but absent on create). Use them sparingly. Separate create and update DTOs are usually cleaner.

**Custom constraints** exist for rules the built-ins can't express, such as a `@StrongPassword` annotation backed by a `ConstraintValidator`. Learn these once your rules outgrow `@Pattern`.

## Input validation versus business validation

This is the most important distinction in the whole topic.

**Input validation** asks: "is this data structurally acceptable?" It needs only the DTO itself, with no database and no other state. `@NotBlank`, `@Email`, `@Size`, and `@Positive` all belong here, and a failure means `400 Bad Request`.

**Business validation** asks: "is this operation allowed, given the current state of the system?" It needs context. Examples: the account has insufficient balance, an order cannot be cancelled after shipping, a user cannot delete their own organization, the username is already taken. These live in the service layer as ordinary code:

```java
@Transactional
public void transfer(Long fromId, Long toId, BigDecimal amount) {
    Account from = accountRepository.findById(fromId).orElseThrow();
    if (amount.compareTo(from.getBalance()) > 0) {
        throw new InsufficientFundsException();
    }
    // perform transfer
}
```

A good test: if the check requires loading something from the database or consulting other state, it is business validation. Failures typically map to `409 Conflict` or `422 Unprocessable Entity` through your exception handler, not a plain `400`.

## Where entities and the database fit

You can put validation annotations on entities (`@NotBlank` on a field), and Hibernate will check them just before persisting. But the entity's real jobs are different from the DTO's: `@Column(nullable = false, unique = true)` is not validation, it is **schema mapping**, and the actual enforcement comes from the database itself.

The database is your last line of defense, and it is the only truly reliable one. Consider "username is already taken": your service can check `existsByUsername` first for a friendly error, but two simultaneous requests can both pass that check. Only the `unique` constraint guarantees correctness, so catch the resulting `DataIntegrityViolationException` and translate it into a proper response. Treat the service check as politeness and the database constraint as the law.

## The full picture

```text
JSON
  -> Request DTO         input rules:    @NotBlank, @Email, @Size     -> 400 on failure
  -> @Valid triggers the check
  -> Service             business rules: balance, state, ownership    -> 409 / 422
  -> Entity / JPA        mapping:        @Column, @Id
  -> Database            integrity:      NOT NULL, UNIQUE, FK         -> last line of defense
```

Each layer protects a different boundary, and they complement each other. Do not try to make one of them do everything.

## Common mistakes

- Forgetting `@Valid` and wondering why nothing is rejected.
- Using `@NotNull` on text fields and accepting empty or whitespace-only strings.
- Forgetting `@Valid` on nested objects and list elements.
- Putting business rules in custom annotations that query the database, which hides logic in a hard-to-find place.
- Relying only on a service-level uniqueness check without a database constraint.
- Reusing one DTO for create and update, then fighting with groups.

## Related concepts to study next

- **`@RestControllerAdvice` and `ProblemDetail`** (RFC 9457 error responses, built into Spring 6)
- **Custom `ConstraintValidator`** implementations
- **Validation groups** and when to avoid them
- **Method-level validation** with `@Validated` on services
- **Exception-to-status mapping** for business errors
- **Database constraints and migrations** (Flyway or Liquibase) as part of your validation strategy




[[Spring Framework]]