**DTOs are usually the primary place for input validation**, especially request DTOs. But there are two different kinds of validation you should keep separate:

```text
Request DTO validation
        ↓
"Is this input structurally valid?"
        ↓
Business/domain validation
        ↓
"Is this operation allowed?"
```

Let's build it from the ground up.

# 1. What is validation?

Validation is the process of checking whether data satisfies **defined constraints** before your application processes it.

For example, an API receives:

```json
{
    "email": "hello",
    "password": "x"
}
```

You might require:

```text
email    → valid email format
password → at least 8 characters
```

Instead of manually doing:

```java
if (email == null || email.isBlank()) {
    ...
}

if (!email.contains("@")) {
    ...
}

if (password.length() < 8) {
    ...
}
```

Spring uses **Bean Validation / Jakarta Validation** annotations to declaratively describe those constraints.

---

# 2. The main annotations

You'll encounter these constantly:

```java
@NotNull
@NotBlank
@NotEmpty

@Size
@Min
@Max
@Positive
@PositiveOrZero
@Negative
@NegativeOrZero

@Email
@Pattern

@Past
@PastOrPresent
@Future
@FutureOrPresent
```

There are also validation annotations for things like:

```java
@AssertTrue
@AssertFalse
@DecimalMin
@DecimalMax
@Digits
```

---

# 3. Where should validation go?

For a REST API, your **request DTO is usually the first validation boundary**.

Example:

```java
public record CreateUserRequest(

    @NotBlank
    @Email
    String email,

    @NotBlank
    @Size(min = 8)
    String password

) {}
```

Then:

```java
@PostMapping
public UserResponse create(
        @Valid @RequestBody CreateUserRequest request
) {
    return userService.create(request);
}
```

The important part is:

```java
@Valid
```

Without it, the validation annotations on the DTO aren't automatically triggered by Spring MVC in this request-binding flow.

---

# 4. What happens internally?

Suppose the client sends:

```json
{
    "email": "hello",
    "password": "123"
}
```

Flow:

```text
HTTP Request
     ↓
JSON
     ↓
Jackson
     ↓
CreateUserRequest
     ↓
@Valid
     ↓
Bean Validation
     ↓
constraints checked
     ↓
validation failure
     ↓
HTTP 400 response
```

So the controller can reject invalid input **before it reaches your business logic**.

---

# 5. What does `@NotNull` mean?

```java
@NotNull
String username
```

means:

> The value must not be `null`.

But:

```java
""
```

is allowed.

And:

```text
"   "
```

is allowed.

That's why `@NotNull` isn't enough for most user-entered strings.

---

# 6. `@NotEmpty`

```java
@NotEmpty
String username
```

means:

```text
not null
AND
not empty
```

So:

```text
null  ❌
""    ❌
"abc" ✅
```

But whitespace is still technically a non-empty string:

```text
"   " → allowed
```

---

# 7. `@NotBlank`

For normal textual user input, this is often what you want:

```java
@NotBlank
String username
```

It rejects:

```text
null
""
"   "
```

So:

```text
@NotNull
    ↓
only cares about null

@NotEmpty
    ↓
null + empty

@NotBlank
    ↓
null + empty + whitespace
```

---

# 8. `@Size`

Controls the size/length of a value.

```java
@Size(min = 8, max = 64)
String password
```

Means:

```text
8 ≤ length ≤ 64
```

It can apply to strings and also collections/arrays/maps depending on the constraint.

---

# 9. `@Email`

```java
@Email
String email
```

checks whether the value conforms to the validator's definition of an email-like format.

Usually combine it with:

```java
@NotBlank
@Email
String email
```

Why both?

Because `@Email` and null/blank handling aren't the same concern.

---

# 10. Numeric validation

For:

```java
int age;
```

you might have:

```java
@Min(18)
int age;
```

or:

```java
@Positive
BigDecimal price;
```

Examples:

```java
@Positive
private BigDecimal price;
```

means:

```text
price > 0
```

Whereas:

```java
@PositiveOrZero
```

means:

```text
price >= 0
```

---

# 11. `@Pattern`

For custom string formats:

```java
@Pattern(regexp = "^[A-Z]{2}\\d{4}$")
String code;
```

For example:

```text
AB1234   ✅
XY9999   ✅
abc123   ❌
```

Don't use regex for everything, though. Prefer a dedicated constraint when one exists.

---

# 12. Validation doesn't modify your data

This is important.

Given:

```java
@NotBlank
String email;
```

the validator doesn't "fix" the email.

It checks it.

Conceptually:

```text
value
  ↓
constraint validator
  ↓
valid? ───── yes → continue
  │
  no
  ↓
ConstraintViolation
```

---

# 13. What happens when validation fails?

Suppose:

```java
public record CreateUserRequest(

    @NotBlank
    @Email
    String email,

    @Size(min = 8)
    String password

) {}
```

Client sends:

```json
{
    "email": "not-an-email",
    "password": "123"
}
```

Validation detects violations.

Spring MVC can then produce a `400 Bad Request` response, commonly through its validation/exception handling infrastructure.

Conceptually:

```text
Client
  │
  │ invalid JSON data
  ▼
Controller
  │
  ▼
@Valid
  │
  ▼
Validator
  │
  ├── email → invalid
  └── password → too short
          │
          ▼
      400 Bad Request
```

Your service doesn't need to contain basic input checks for those constraints.

---

# 14. Why is DTO validation useful?

Imagine you don't validate the DTO.

Your service could receive:

```java
email = null
password = ""
age = -500
```

Then business logic starts executing.

You get:

```text
Controller
    ↓
Service
    ↓
business logic
    ↓
database
    ↓
database exception
```

That's backwards.

With validation:

```text
Controller
    ↓
DTO validation
    │
    ├── invalid → 400
    │
    └── valid
          ↓
       Service
          ↓
       Repository
          ↓
       Database
```

The service gets data that has passed the **basic input constraints**.

---

# 15. But don't put ALL validation in DTOs

This is where beginners often go too far.

Suppose:

```java
@Size(min = 8)
String password;
```

That's an excellent DTO constraint.

But imagine the rule:

> A user cannot transfer more money than their account balance.

That's **business logic**, not simple DTO validation.

You shouldn't try to encode it as:

```java
@SomeAnnotation
BigDecimal amount;
```

Instead:

```java
@Service
public class TransferService {

    public void transfer(...) {

        if (amount.compareTo(account.getBalance()) > 0) {
            throw new InsufficientFundsException();
        }

        // business operation
    }
}
```

So distinguish:

### Input validation

```text
"Is this data structurally acceptable?"
```

Examples:

```java
@NotBlank
@Email
@Size
@Positive
@Pattern
```

### Business validation

```text
"Does this operation make sense according to our domain rules?"
```

Examples:

```text
Account has insufficient balance
User cannot delete their own organization
Order cannot be cancelled after shipment
Username is already taken
```

---

# 16. What about Entity validation?

You **can** put validation annotations on entities:

```java
@Entity
public class User {

    @NotBlank
    private String email;
}
```

But don't make the mistake of thinking:

> "I'll put all validation on the Entity and I'm done."

Your entity and API DTO have different responsibilities.

For example:

```java
public record CreateUserRequest(

    @NotBlank
    @Email
    String email,

    @NotBlank
    @Size(min = 8)
    String password

) {}
```

The Entity might contain persistence constraints:

```java
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;
}
```

Notice the separation:

```text
DTO
 │
 ├── API/input constraints
 │
 └── What client is allowed to send

Entity
 │
 ├── persistence mapping
 │
 └── What the application persists
```

---

# 17. Validation has several layers

As your Spring knowledge grows, think about validation as multiple boundaries:

```text
                CLIENT
                   │
                   ▼
          ┌─────────────────┐
          │   Request DTO   │
          │                 │
          │ @NotBlank       │
          │ @Email          │
          │ @Size           │
          └────────┬────────┘
                   │
                   ▼
             @Valid passes
                   │
                   ▼
          ┌─────────────────┐
          │     Service     │
          │                 │
          │ Business rules  │
          └────────┬────────┘
                   │
                   ▼
          ┌─────────────────┐
          │     Entity      │
          │                 │
          │ JPA constraints │
          └────────┬────────┘
                   │
                   ▼
               DATABASE
```

Each layer protects a different boundary.

---

# 18. The dependencies behind validation

There are a few concepts you should learn together:

```text
Jakarta Bean Validation
        │
        ├── Constraint annotations
        │       ├── @NotBlank
        │       ├── @Email
        │       ├── @Size
        │       └── @Positive
        │
        ├── Validator
        │
        ├── ConstraintViolation
        │
        └── @Valid
                │
                ▼
          Spring MVC
                │
                ▼
        Controller method
```

In Spring Boot, the usual dependency is:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

Spring Boot uses a Bean Validation implementation (commonly Hibernate Validator) behind the Jakarta Validation API.

---

# 19. A pattern I'd recommend for your projects

Request:

```java
public record CreateUserRequest(

    @NotBlank
    @Email
    String email,

    @NotBlank
    @Size(min = 8, max = 72)
    String password

) {}
```

Controller:

```java
@PostMapping
public UserResponse create(
        @Valid @RequestBody CreateUserRequest request
) {
    return userService.create(request);
}
```

Service:

```java
public UserResponse create(CreateUserRequest request) {

    // business rules
    // password hashing
    // entity construction

}
```

Entity:

```java
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;
}
```

The architecture becomes:

```text
JSON
 ↓
Request DTO
 ↓
@Valid
 ↓
Input validation
 ↓
Service
 ↓
Business rules
 ↓
Entity
 ↓
JPA
 ↓
Database
```

### The core rule

**DTO validation answers:**

> "Is the request acceptable as input?"

**Service validation answers:**

> "Is this operation valid according to the business?"

**Database constraints answer:**

> "Will the persisted data satisfy the database's integrity rules?"

Those three are complementary. You don't replace one with another.



[[Java]]
[[0 - Spring Framework]]