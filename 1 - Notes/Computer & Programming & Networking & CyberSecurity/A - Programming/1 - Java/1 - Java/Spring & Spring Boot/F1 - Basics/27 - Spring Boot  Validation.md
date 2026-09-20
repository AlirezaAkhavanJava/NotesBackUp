Date: 2025-09-07

This guide provides a comprehensive overview of Spring Boot validation, from basic to advanced topics, with clear examples to help you implement robust validation in your applications.

---

## Introduction

Spring Boot Starter Validation leverages Hibernate Validator (JSR-380) to provide seamless validation for Java objects. It integrates effortlessly with Spring Boot, enabling declarative and programmatic validation for REST APIs, forms, and more.

---

## Setup Spring Boot Validation

1. Add the dependency to your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

2. For Gradle:

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-validation'
}
```

3. Spring Boot auto-configures the validation framework, so no additional configuration is required unless you need custom settings.

---

## Validation Annotations

Spring Boot uses annotations from the `javax.validation.constraints` and `jakarta.validation.constraints` packages (depending on your Java version) to validate fields, methods, or classes. Below is a comprehensive list of commonly used annotations:

|Annotation|Description|
|---|---|
|`@NotNull`|Ensures the field is not null.|
|`@NotEmpty`|Ensures a string, collection, or array is not empty.|
|`@NotBlank`|Ensures a string is not null, empty, or all whitespace.|
|`@Size` or `@Length`|Specifies min/max size for strings, collections, or arrays.|
|`@Email`|Validates that a string follows a valid email format.|
|`@Min`|Ensures a number is greater than or equal to a value.|
|`@Max`|Ensures a number is less than or equal to a value.|
|`@Positive`|Ensures a number is strictly positive (> 0).|
|`@PositiveOrZero`|Ensures a number is positive or zero (≥ 0).|
|`@Negative`|Ensures a number is strictly negative (< 0).|
|`@NegativeOrZero`|Ensures a number is negative or zero (≤ 0).|
|`@Digits`|Validates that a number has a specific number of integer and fractional digits.|
|`@Pattern`|Ensures a string matches a regular expression.|
|`@Past`|Ensures a date/time is in the past.|
|`@PastOrPresent`|Ensures a date/time is in the past or present.|
|`@Future`|Ensures a date/time is in the future.|
|`@FutureOrPresent`|Ensures a date/time is in the future or present.|
|`@AssertTrue`|Ensures a boolean field is true.|
|`@AssertFalse`|Ensures a boolean field is false.|
|`@DecimalMin`|Ensures a number is greater than or equal to a specified value (with decimal support).|
|`@DecimalMax`|Ensures a number is less than or equal to a specified value (with decimal support).|
|`@Null`|Ensures the field is null (rarely used).|

### Example: Basic Validation

```java
import jakarta.validation.constraints.*;

public class User {
    @NotBlank(message = "Name is mandatory")
    @Size(min = 2, max = 50, message = "Name must be between 2 and 50 characters")
    private String name;

    @Email(message = "Invalid email format")
    @NotBlank(message = "Email is mandatory")
    private String email;

    @Min(value = 18, message = "Age must be at least 18")
    @Max(value = 100, message = "Age must be below 100")
    private int age;

    @Pattern(regexp = "\\d{10}", message = "Phone number must be 10 digits")
    private String phone;

    @Past(message = "Birth date must be in the past")
    private LocalDate birthDate;

    @Positive(message = "Salary must be positive")
    private double salary;

    @AssertTrue(message = "User must agree to terms")
    private boolean agreedToTerms;

    // getters and setters
}
```

---

## Custom Validation

For requirements not covered by built-in annotations, you can create custom validators.

### Step 1: Create a Custom Annotation

```java
import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = PhoneValidator.class)
@Target({ ElementType.METHOD, ElementType.FIELD })
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidPhone {
    String message() default "Invalid phone number";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

### Step 2: Create the Validator

```java
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class PhoneValidator implements ConstraintValidator<ValidPhone, String> {

    @Override
    public boolean isValid(String phoneField, ConstraintValidatorContext context) {
        return phoneField != null && phoneField.matches("\\d{10}");
    }
}
```

### Step 3: Apply the Custom Annotation

```java
public class User {
    @ValidPhone(message = "Please provide a valid 10-digit phone number")
    private String phone;
}
```

### Composing Annotations

You can combine multiple annotations into a single custom annotation for reusability.

```java
import jakarta.validation.constraints.*;
import java.lang.annotation.*;

@NotBlank
@Size(min = 2, max = 50)
@Target({ ElementType.FIELD, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = {})
public @interface ValidName {
    String message() default "Invalid name";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

Apply it:

```java
@ValidName
private String name;
```

---

## Validation in REST Controllers

Spring Boot simplifies validation in REST APIs using the `@Valid` or `@Validated` annotations.

### Example: Validating a Request Body

```java
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/users")
public class UserController {

    @PostMapping
    public ResponseEntity<String> addUser(@Valid @RequestBody User user) {
        return ResponseEntity.ok("User is valid");
    }
}
```

Invalid data triggers a `MethodArgumentNotValidException`, which can be handled globally.

### Global Exception Handling

```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            errors.put(error.getField(), error.getDefaultMessage())
        );
        return new ResponseEntity<>(errors, HttpStatus.BAD_REQUEST);
    }
}
```

---

## Groups and Conditional Validation

Validation groups allow you to apply different validation rules based on the context (e.g., create vs. update).

### Define Groups

```java
public interface Create {}
public interface Update {}
```

### Apply Groups to Fields

```java
public class User {
    @NotBlank(groups = Create.class, message = "Username is required for creation")
    @Size(min = 3, max = 20, groups = {Create.class, Update.class})
    private String username;

    @NotNull(groups = Update.class, message = "ID is required for updates")
    private Long id;
}
```

### Validate in Controller

```java
@PostMapping
public ResponseEntity<String> createUser(@Validated(Create.class) @RequestBody User user) {
    return ResponseEntity.ok("User created");
}

@PutMapping("/{id}")
public ResponseEntity<String> updateUser(@Validated(Update.class) @RequestBody User user) {
    return ResponseEntity.ok("User updated");
}
```

---

## Advanced Features

### Cross-Field Validation

Validate relationships between fields using a class-level custom validator.

```java
@Documented
@Constraint(validatedBy = PasswordMatchValidator.class)
@Target({ ElementType.TYPE })
@Retention(RetentionPolicy.RUNTIME)
public @interface PasswordMatch {
    String message() default "Passwords do not match";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

public class PasswordMatchValidator implements ConstraintValidator<PasswordMatch, User> {
    @Override
    public boolean isValid(User user, ConstraintValidatorContext context) {
        return user.getPassword() != null && user.getPassword().equals(user.getConfirmPassword());
    }
}

@PasswordMatch
public class User {
    private String password;
    private String confirmPassword;
}
```

### Programmatic Validation

Manually validate objects using the `Validator` bean.

```java
import jakarta.validation.Validator;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.Set;

@Service
public class UserService {

    @Autowired
    private Validator validator;

    public void validateUser(User user) {
        Set<ConstraintViolation<User>> violations = validator.validate(user);
        if (!violations.isEmpty()) {
            throw new ConstraintViolationException(violations);
        }
    }
}
```

### Cascading Validation

Validate nested objects using `@Valid`.

```java
public class Order {
    @NotNull
    private Long id;

    @Valid
    @NotNull
    private User user;
}
```

---

## Internationalization (i18n) for Validation Messages

Use resource bundles for localized validation messages.

1. Create `messages.properties`:

```
user.name.blank=Name is required
user.email.invalid=Invalid email format
```

2. Reference in annotations:

```java
@NotBlank(message = "{user.name.blank}")
private String name;

@Email(message = "{user.email.invalid}")
private String email;
```

3. Add additional locale files (e.g., `messages_fr.properties`) for other languages.

---

## Bean Validation in Spring Boot Configuration

Customize validation behavior by configuring the `Validator` bean.

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

@Configuration
public class ValidationConfig {

    @Bean
    public LocalValidatorFactoryBean validator() {
        return new LocalValidatorFactoryBean();
    }
}
```

---

## Testing Validation

Write unit tests to verify validation logic using `Validator`.

```java
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
public class UserValidationTest {

    @Autowired
    private Validator validator;

    @Test
    public void testInvalidUser() {
        User user = new User();
        user.setName(""); // Invalid: blank
        user.setEmail("invalid"); // Invalid: not an email
        user.setAge(15); // Invalid: below 18

        Set<ConstraintViolation<User>> violations = validator.validate(user);
        assertEquals(3, violations.size());
    }
}
```

---

## Best Practices

- Provide clear, user-friendly error messages.
- Use validation groups for context-specific rules.
- Handle exceptions globally with `@ControllerAdvice`.
- Prefer built-in annotations before creating custom ones.
- Keep validations close to the data model.
- Use cascading validation (`@Valid`) for nested objects.
- Test validation logic thoroughly.
- Use internationalization for multilingual applications.
- Avoid overly complex custom validators; break them into smaller, reusable annotations.

---

## Common Pitfalls

- **Forgetting `@Valid`**: Without `@Valid` or `@Validated`, Spring won't trigger validation in controllers.
- **Null Fields**: `@NotEmpty` and `@NotBlank` don’t check for null; combine with `@NotNull` if needed.
- **Overusing Custom Validators**: Use built-in annotations where possible to reduce complexity.
- **Ignoring Groups**: Not using groups can lead to applying validations in the wrong context.
- **Missing Exception Handling**: Always handle `MethodArgumentNotValidException` for REST APIs.

---

This guide covers Spring Boot Starter Validation comprehensively, from basic annotations to advanced custom validations, groups, and best practices, empowering you to build robust, validated applications.

##### _Tags: [[0 - Spring Framework]]_