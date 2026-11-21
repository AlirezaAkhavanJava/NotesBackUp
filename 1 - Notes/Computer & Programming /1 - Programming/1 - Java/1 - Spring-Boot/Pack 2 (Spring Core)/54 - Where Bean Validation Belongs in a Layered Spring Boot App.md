


**Definition:** Bean Validation (Jakarta Validation) is a standard way to declare constraints like `@NotBlank` or `@Size` as annotations. The annotations only describe the rules. Something else has to trigger the check.

**Mental model:** Separate _declaring_ a rule from _triggering_ it, and separate _shape rules_ from _business rules_.

- **Shape rules** ask whether the data is well-formed on its own: not blank, within length, valid email format, positive number. These can be checked without touching the database or any other state.
- **Business rules** need context: "email must be unique", "user must own this order", "can't cancel a shipped order". These belong in code in the service layer, not in annotations.

Annotations are for shape rules.

## Layer by layer

|Layer|Put constraint annotations here?|Role|
|---|---|---|
|Request DTO|**Yes, this is the main place**|Declares the rules|
|Controller|Trigger only (`@Valid`)|Runs the check at the boundary|
|Service|Sometimes (`@Validated` on the class)|Safety net when there are other entry points|
|Mapper|**No**|Pure transformation|
|Entity|Minimal|Last-resort guard before persisting|

### 1. DTO declares, controller triggers

Add the dependency first: `spring-boot-starter-validation`. Without it the annotations compile but nothing runs.

```java
public record CreateUserRequest(
        @NotBlank @Size(max = 50) String name,
        @NotBlank @Email String email,
        @NotNull @Min(18) Integer age,
        @NotEmpty List<@Valid AddressRequest> addresses
) {}

public record AddressRequest(
        @NotBlank String city,
        @Pattern(regexp = "\\d{5}") String zip
) {}
```

```java
@RestController
@RequestMapping("/users")
class UserController {

    private final UserService userService;

    UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.create(request));
    }
}
```

Line by line:

- `record CreateUserRequest(...)`: The DTO is the contract of your HTTP API, so rules live here, next to the fields they describe. A record works because constraints on components apply to the fields.
- `@NotBlank`: Rejects null, empty, and whitespace-only strings. It is only for `String`. `@NotEmpty` is for strings, collections, and maps (null or size 0 fails, but `" "` passes for strings). `@NotNull` only rejects null. Picking the wrong one is a common bug.
- `@Min(18) Integer age`: Most constraints treat `null` as **valid**. `@Min`, `@Size`, `@Email`, and `@Pattern` all skip null, so you need `@NotNull` as well. That's why the example uses `Integer` plus `@NotNull` rather than a primitive `int` (which would silently default to 0 when the field is missing).
- `List<@Valid AddressRequest>`: Validation does **not cascade** into nested objects automatically. Without `@Valid` on the nested type, the `zip` rule is never checked.
- `@Valid @RequestBody`: This is the trigger. Spring runs the validator after JSON deserialization, before your method body executes. On failure it throws `MethodArgumentNotValidException`, which Spring maps to HTTP 400 by default.

The controller is the right trigger point because it's the **trust boundary**. Everything beyond it can assume the data is well-formed.

### 2. Service: `@Validated` for non-HTTP entry points

If a service is only called from controllers that already validated the input, re-validating is redundant. But if it's also called from a scheduler, a message listener (Kafka/RabbitMQ), or another service, nothing at the boundary protected it. Then you can validate at the service:

```java
@Service
@Validated
class UserService {

    UserResponse create(@Valid CreateUserRequest request) {
        // ...
    }

    UserResponse findById(@Positive Long id) {
        // ...
    }
}
```

- `@Validated` on the class: Spring wraps the bean in an AOP proxy that intercepts method calls and checks constraints on parameters and return values. Without this class-level annotation, the constraints on method parameters are ignored.
- `@Valid CreateUserRequest request`: Triggers validation of the DTO's own constraints, same as in the controller.
- `@Positive Long id`: A constraint directly on a parameter, which is how you validate simple values with no DTO.
- Failure here throws `ConstraintViolationException` (not `MethodArgumentNotValidException`), so your error handler must deal with both types.

Where this breaks down: it's proxy-based, so **self-invocation** (calling `this.create(...)` from another method in the same class) bypasses validation. It also doesn't help for `private` or `final` methods.

Note that the unique-email check does **not** belong in an annotation like this. It's a business rule, so do it explicitly in the service:

```java
if (userRepository.existsByEmail(request.email())) {
    throw new EmailAlreadyUsedException(request.email());
}
```

Writing a custom `@UniqueEmail` constraint that queries the database is possible, but it hides a DB call inside validation and is still racy (two concurrent requests can both pass). A DB unique constraint is the real guarantee.

### 3. Mapper: no validation

A mapper converts DTO ↔ entity. Validating there mixes responsibilities, and by that point the input has already been validated at the boundary. If a mapper receives invalid data, that's a programming bug, not a user error, and should not produce a 400.

### 4. Entity: keep it minimal

Hibernate runs Bean Validation on `@PrePersist` and `@PreUpdate` if the validator is on the classpath. Constraints like `@NotNull` and `@Size` on entities act as a last guard that mirrors your DB schema:

```java
@Entity
class User {
    @Column(nullable = false, length = 50)
    @NotBlank @Size(max = 50)
    private String name;
}
```

Failures here surface as `ConstraintViolationException` at flush time, usually wrapped in a transaction exception. That is too late for a clean 400 response, so don't make the entity your primary validation. Also avoid putting request-specific rules on entities, because create and update often need different rules (e.g. password required on create, optional on update). Separate DTOs let you model that cleanly.

## Edge cases to know

- **Controller params without a DTO:** For `@RequestParam` and `@PathVariable`, put the constraint directly on the parameter: `@PathVariable @Positive Long id`. In Spring 6.1+ (Boot 3.2+), this is handled by built-in method validation and throws `HandlerMethodValidationException`. If the controller class also has `@Validated`, the older AOP path is used instead and you get `ConstraintViolationException`. Don't mix the two without knowing which one you'll catch.
- **Imports:** Boot 3+ uses `jakarta.validation.*`. Old tutorials with `javax.validation.*` won't compile.
- **`@Valid` vs `@Validated`:** `@Valid` is the standard annotation and supports cascading. `@Validated` is Spring's and adds **validation groups** and class-level method validation.

## Alternatives

- Manual checks in the service with explicit exceptions, which is better for business rules and context-dependent logic.
- A Spring `Validator` implementation for complex cross-field logic.
- A custom constraint annotation plus `ConstraintValidator` for reusable rules (e.g. `@StrongPassword`, or class-level `@PasswordsMatch`).
- Database constraints (`UNIQUE`, `NOT NULL`, `CHECK`) as the final authority. Application-level validation gives good error messages, while the DB guarantees correctness under concurrency.

**Rule of thumb:** declare shape rules on the request DTO, trigger at the controller, enforce business rules in the service with plain code, and use DB constraints as the ultimate backstop.




[[Spring Framework]]