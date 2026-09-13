

---

# 🧠 Spring Boot Starter Validation — The Complete Guide (Basic → Advanced)

---

## ⚙️ 1. What It Is

The dependency:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

This starter adds:

- `jakarta.validation` (Bean Validation API)
    
- `hibernate-validator` (default implementation)
    
- Works automatically in Spring Boot REST controllers, services, DTOs, etc.
    

---

## 🧩 2. Core Concepts

**Goal:** Automatically validate incoming data (e.g., JSON body) using annotations on your Java classes (Entities or DTOs).

You just add annotations → Spring automatically validates before method execution.

Example:

```java
public class StudentDTO {
    @NotNull
    private String name;

    @Email
    private String email;
}
```

If invalid JSON is sent, Spring returns a `400 Bad Request` with the validation errors.

---

## 🚀 3. Enable Validation in Controllers

Use `@Valid` or `@Validated` before parameters:

```java
@PostMapping("/students")
public ResponseEntity<StudentDTO> create(@Valid @RequestBody StudentDTO dto) {
    return ResponseEntity.ok(dto);
}
```

💡 `@Valid` = basic JSR validation.  
💡 `@Validated` = adds Spring’s group-based validation features.

---

## 📋 4. Common Validation Annotations (Core Set)

|Annotation|Target|Description|Example|
|---|---|---|---|
|`@NotNull`|Any type|Value must not be null|`@NotNull private String name;`|
|`@NotEmpty`|String, Collection|Not null **and** not empty|`@NotEmpty private String name;`|
|`@NotBlank`|String|Not null, not empty, no whitespace|`@NotBlank private String name;`|
|`@Size(min, max)`|String, Collection|Length/size constraint|`@Size(min=2, max=30)`|
|`@Email`|String|Must be valid email|`@Email private String email;`|
|`@Pattern(regexp="...")`|String|Must match regex|`@Pattern(regexp="^[A-Z].*")`|
|`@Min(value)`|Number|Must be ≥ value|`@Min(18)`|
|`@Max(value)`|Number|Must be ≤ value|`@Max(100)`|
|`@Positive` / `@Negative`|Number|Must be positive/negative|`@Positive private int score;`|
|`@PositiveOrZero` / `@NegativeOrZero`|Number|≥ 0 or ≤ 0||
|`@Past`|Date/LocalDate|Must be in the past|`@Past private LocalDate birthDate;`|
|`@Future`|Date/LocalDate|Must be in the future|`@Future private LocalDate deadline;`|
|`@PastOrPresent`|Date|Past or today||
|`@FutureOrPresent`|Date|Future or today||
|`@Digits(integer, fraction)`|BigDecimal|Numeric precision|`@Digits(integer=6, fraction=2)`|
|`@DecimalMin(value, inclusive)`|Decimal|Must be ≥ value|`@DecimalMin("0.1")`|
|`@DecimalMax(value, inclusive)`|Decimal|Must be ≤ value|`@DecimalMax("100.0")`|
|`@AssertTrue` / `@AssertFalse`|Boolean|Must be true/false|`@AssertTrue private boolean accepted;`|

---

## 🧱 5. Example DTO (All in One)

```java
public class StudentDTO {

    @NotNull(message = "ID is required")
    private Long id;

    @NotBlank(message = "Name cannot be blank")
    @Size(min = 2, max = 50)
    private String name;

    @Email(message = "Invalid email format")
    private String email;

    @Min(value = 18, message = "Age must be at least 18")
    @Max(value = 120, message = "Age must be less than 120")
    private int age;

    @Pattern(regexp = "^(US|UK|IN|DE|FR)$", message = "Invalid country code")
    private String country;

    @AssertTrue(message = "You must accept the policy")
    private boolean acceptedPolicy;
}
```

---

## 🧾 6. Validation on Path Variables and Params

For method parameters, use `@Validated` on the class:

```java
@RestController
@Validated
@RequestMapping("/students")
public class StudentController {

    @GetMapping("/{id}")
    public Student getStudentById(@PathVariable @Min(1) Long id) {
        // ...
    }

    @GetMapping
    public List<Student> findByAge(@RequestParam @Max(120) int age) {
        // ...
    }
}
```

---

## ⚡ 7. Handling Validation Errors

When validation fails, Spring throws `MethodArgumentNotValidException`.  
You can customize the response using `@ControllerAdvice`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationErrors(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(err -> errors.put(err.getField(), err.getDefaultMessage()));
        return ResponseEntity.badRequest().body(errors);
    }
}
```

👉 Output example:

```json
{
  "name": "Name cannot be blank",
  "email": "Invalid email format"
}
```

---

## 🧠 8. Validation Groups (Advanced)

You can define **validation groups** for different contexts (e.g., Create vs Update).

### Define groups:

```java
public interface OnCreate {}
public interface OnUpdate {}
```

### Use them in DTO:

```java
public class StudentDTO {

    @NotNull(groups = OnUpdate.class)
    private Long id;

    @NotBlank(groups = {OnCreate.class, OnUpdate.class})
    private String name;
}
```

### Apply group in controller:

```java
@PostMapping
public ResponseEntity<?> create(@Validated(OnCreate.class) @RequestBody StudentDTO dto) {
    ...
}

@PutMapping
public ResponseEntity<?> update(@Validated(OnUpdate.class) @RequestBody StudentDTO dto) {
    ...
}
```

---

## 🧮 9. Custom Validation Annotations

When built-ins aren’t enough, define your own:

### Step 1: Define annotation

```java
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = AgeValidator.class)
public @interface ValidAge {
    String message() default "Invalid age";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

### Step 2: Create validator

```java
public class AgeValidator implements ConstraintValidator<ValidAge, Integer> {
    @Override
    public boolean isValid(Integer value, ConstraintValidatorContext context) {
        return value != null && value >= 18 && value <= 120;
    }
}
```

### Step 3: Use it

```java
@ValidAge
private int age;
```

---

## 🧩 10. Cross-Field Validation

You can validate multiple fields together (e.g., password confirmation):

```java
@PasswordMatches
public class RegisterDTO {
    private String password;
    private String confirmPassword;
}
```

Validator:

```java
public class PasswordMatchesValidator implements ConstraintValidator<PasswordMatches, RegisterDTO> {
    @Override
    public boolean isValid(RegisterDTO dto, ConstraintValidatorContext context) {
        return dto.getPassword().equals(dto.getConfirmPassword());
    }
}
```

---

## 🧱 11. Nested Object Validation

If your DTO has nested objects, annotate with `@Valid`:

```java
public class StudentDTO {
    @Valid
    private AddressDTO address;
}
```

---

## 🧰 12. Validation in Service Layer (Manual Validation)

You can programmatically validate using `Validator` bean:

```java
@Service
public class StudentService {
    @Autowired private Validator validator;

    public void validate(StudentDTO dto) {
        Set<ConstraintViolation<StudentDTO>> violations = validator.validate(dto);
        if (!violations.isEmpty()) {
            throw new ConstraintViolationException(violations);
        }
    }
}
```

---

## 🧩 13. Enable Message Interpolation (Localization)

In `src/main/resources/messages.properties`:

```properties
NotNull.student.name=Name is required
Email.student.email=Invalid email format
```

Then Spring will automatically use your custom messages.

---

## 🧠 14. Advanced Tips

|Use Case|Solution|
|---|---|
|Different rules for create/update|Validation groups|
|Custom logic validation|Custom constraint|
|Multiple validation profiles|`@Validated` with groups|
|Custom error JSON|`@ControllerAdvice`|
|Nested DTOs|`@Valid` inside parent DTO|
|List validation|`@Valid List<ChildDTO>`|
|Optional fields|Don’t use `@NotNull`|

---

## 🧾 15. Full Example: REST Validation Flow

### DTO:

```java
public class StudentDTO {
    @NotBlank private String name;
    @Email private String email;
    @Positive private int age;
}
```

### Controller:

```java
@PostMapping("/students")
public ResponseEntity<?> createStudent(@Valid @RequestBody StudentDTO dto) {
    return ResponseEntity.ok(dto);
}
```

### Request JSON:

```json
{
  "name": "",
  "email": "wrong-email",
  "age": -2
}
```

### Response:

```json
{
  "name": "must not be blank",
  "email": "must be a well-formed email address",
  "age": "must be greater than 0"
}
```

---

## 🧾 16. Full List of Built-in Constraints (Jakarta / Hibernate Validator)

|Category|Annotations|
|---|---|
|**Null checks**|`@Null`, `@NotNull`, `@NotEmpty`, `@NotBlank`|
|**String**|`@Size`, `@Pattern`, `@Email`|
|**Number**|`@Min`, `@Max`, `@Positive`, `@Negative`, `@Digits`, `@DecimalMin`, `@DecimalMax`|
|**Date/Time**|`@Past`, `@Future`, `@PastOrPresent`, `@FutureOrPresent`|
|**Boolean**|`@AssertTrue`, `@AssertFalse`|
|**Custom/Composite**|`@Valid`, `@Constraint`, `@GroupSequence`|

---

## ✅ Summary

|Feature|Annotation|Scope|
|---|---|---|
|Validate Request Body|`@Valid`|Method params|
|Controller Validation|`@Validated`|Class level|
|Custom Rules|`@Constraint`|Custom annotation|
|Nested DTO|`@Valid`|On nested fields|
|Error Handling|`@ControllerAdvice`|Global|
|Validation Groups|`@Validated(Group.class)`|Multi-context validation|

---

### Tags : [[0 - Spring Framework]]