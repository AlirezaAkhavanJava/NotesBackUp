

Jakarta Bean Validation (formerly JSR 380, the javax/jakarta `validation` spec) is a specification — not a library on its own. It defines a standard way to declare constraints on Java objects using annotations (`@NotNull`, `@Size`, `@Email`, etc.) and a standard API (`Validator`, `ValidatorFactory`) to actually run those constraints and collect violations. Spring Boot doesn't implement this spec itself; it pulls in **Hibernate Validator**, which is the reference implementation, via the `spring-boot-starter-validation` dependency.

So there are really two layers to understand:

1. **The Validation API** — the `jakarta.validation` package: the annotations, the `ConstraintValidator` interface, the `Validator` interface, `ConstraintViolation`.
2. **Spring's integration** — how Spring MVC and Spring itself hook into that API so violations get triggered automatically and turned into HTTP errors, without you ever calling `Validator.validate()` yourself in most cases.

You already know how validation messages get shown via `ProblemDetail` and how `@PathVariable` gets locked down, so I'll build around those rather than repeat them — the focus here is the plumbing underneath.

## The Core Pieces of the API

```java
public interface ConstraintValidator<A extends Annotation, T> {
    default void initialize(A constraintAnnotation) {}
    boolean isValid(T value, ConstraintValidatorContext context);
}
```

Every constraint annotation (`@NotNull`, `@Size`, etc.) is backed by one or more classes implementing this interface. `A` is the annotation type, `T` is the type of field it validates. For example, `@Size` has separate `ConstraintValidator` implementations for `CharSequence`, `Collection`, `Map`, and arrays — the annotation is one declaration, but the validator dispatches by type.

```java
public interface Validator {
    <T> Set<ConstraintViolation<T>> validate(T object, Class<?>... groups);
    <T> Set<ConstraintViolation<T>> validateProperty(T object, String propertyName, Class<?>... groups);
    <T> Set<ConstraintViolation<T>> validateValue(Class<T> beanType, String propertyName, Object value, Class<?>... groups);
}
```

This is the interface you'd call directly if you ever needed to validate something manually (outside a controller flow). Spring auto-configures a `Validator` bean (backed by Hibernate Validator) as soon as `spring-boot-starter-validation` is on the classpath, so you can `@Autowired Validator validator` if you ever need manual validation — for example, validating an object built dynamically rather than bound from a request.

## Where Validation Actually Gets Triggered

This is the part that trips people up, because there are **two separate trigger mechanisms** in Spring, and they produce different exceptions.

### 1. `@Valid` on a method argument (request body / model attribute)

```java
@PostMapping("/accounts")
public ResponseEntity<AccountOwnerDto> create(@Valid @RequestBody AccountOwnerDto dto) {
    ...
}
```

`@Valid` here is a _Jakarta_ annotation (`jakarta.validation.Valid`), not a Spring one. Spring MVC's `RequestResponseBodyMethodProcessor` (the `HandlerMethodArgumentResolver` that resolves `@RequestBody` arguments) sees `@Valid` on the parameter, runs the bound object through the `Validator`, and if violations exist, throws `MethodArgumentNotValidException`. This is the exception your `@RestControllerAdvice` catches to build a `ProblemDetail`.

Key point: `@Valid` only triggers validation because the _argument resolver_ checks for it. It's not magic — it's specific argument resolvers (for `@RequestBody`, `@ModelAttribute`) that look for `@Valid`/`@Validated` and call into the validator.

### 2. `@Validated` at the class level (method parameter validation)

```java
@RestController
@Validated
public class AccountOwnerController {

    @GetMapping("/accounts/{username}")
    public AccountOwnerDto find(@PathVariable @Size(min = 3, max = 20) String username) {
        ...
    }
}
```

Here there's no object to cascade into — `username` is a bare `String` with a constraint directly on the parameter. This only works because `@Validated` (Spring's own annotation, `org.springframework.validation.annotation.Validated`) is on the class. That triggers Spring AOP: a `MethodValidationInterceptor` proxy wraps the bean and validates method parameters/return values before/after invocation. This is why it's a _proxy-based_ mechanism — same category as `@Transactional` — rather than an argument-resolver mechanism.

Violations here throw `ConstraintViolationException` (or, since Spring 6.1, `HandlerMethodValidationException` for web layer parameter validation specifically), which is a **different exception** from `MethodArgumentNotValidException`. If your `@RestControllerAdvice` only has an `@ExceptionHandler` for the latter, path/query parameter violations won't be caught by it — you need a handler for both.

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ProblemDetail handleBody(MethodArgumentNotValidException ex) { ... }

@ExceptionHandler(HandlerMethodValidationException.class)
public ProblemDetail handlePathOrParam(HandlerMethodValidationException ex) { ... }
```

### Why the split exists

`@Valid` + argument resolvers only know how to validate the _object being bound_ (request body, form object). They have no mechanism to validate loose scalar parameters like `@PathVariable` or `@RequestParam`. `@Validated` + AOP proxy fills that gap by intercepting the method call itself and validating every parameter against its own annotations, regardless of where that parameter came from.

## Constraint Annotations Are Just Metadata

A built-in constraint like `@Size` is nothing more than this:

```java
@Target({ FIELD, METHOD, PARAMETER })
@Retention(RUNTIME)
@Constraint(validatedBy = { SizeValidatorForCharSequence.class, SizeValidatorForCollection.class, ... })
public @interface Size {
    String message() default "size must be between {min} and {max}";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
    int min() default 0;
    int max() default Integer.MAX_VALUE;
}
```

The `@Constraint(validatedBy = ...)` meta-annotation is what links the annotation to its `ConstraintValidator` implementation(s). Every constraint annotation must declare `message()`, `groups()`, and `payload()` — this is required by the spec, not optional convention. `message()` is the default message template (what `{min}`/`{max}` placeholders resolve against), `groups()` supports conditional validation, `payload()` lets you attach metadata for custom severity levels (rarely used in practice).

## Writing a Custom Constraint

When the built-in constraints (`@NotNull`, `@NotBlank`, `@Email`, `@Pattern`, `@Size`, `@Min`/`@Max`, `@Positive`, `@Past`/`@Future`, etc.) aren't enough — say, validating that a username matches your app's specific rules beyond a regex, or cross-field validation — you write your own:

```java
@Target({ FIELD, PARAMETER })
@Retention(RUNTIME)
@Constraint(validatedBy = UsernameFormatValidator.class)
public @interface ValidUsername {
    String message() default "username must be 3-20 chars, alphanumeric with underscores only";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

```java
public class UsernameFormatValidator implements ConstraintValidator<ValidUsername, String> {

    private static final Pattern PATTERN = Pattern.compile("^[a-zA-Z0-9_]{3,20}$");

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null) return true; // let @NotNull handle nullability separately
        return PATTERN.matcher(value).matches();
    }
}
```

Two things worth noting here. First, the convention is that a `ConstraintValidator` treats `null` as valid and delegates null-checking to `@NotNull` — constraints are meant to compose, not duplicate each other's job. Second, `ConstraintValidator` is a Spring bean candidate too: if you autowire a dependency into it (say, a repository to check uniqueness against the database), Spring will inject it as long as the validator is picked up by component scanning or instantiated via `ConstraintValidatorFactory`, which Spring Boot auto-configures to use the application context — so `@Autowired` works inside a `ConstraintValidator` out of the box.

### Cross-field validation (class-level constraints)

For validating a relationship between two fields (e.g. `password` and `confirmPassword` must match), you put the constraint on the class, not a field, and let `T` in `ConstraintValidator<A, T>` be the whole bean:

```java
@Target(TYPE)
@Retention(RUNTIME)
@Constraint(validatedBy = PasswordsMatchValidator.class)
public @interface PasswordsMatch {
    String message() default "passwords do not match";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

```java
public class PasswordsMatchValidator implements ConstraintValidator<PasswordsMatch, RegisterRequest> {
    @Override
    public boolean isValid(RegisterRequest request, ConstraintValidatorContext context) {
        return request.password().equals(request.confirmPassword());
    }
}
```

```java
@PasswordsMatch
public record RegisterRequest(String username, String password, String confirmPassword) {}
```

## Cascading Validation

By default, `@Valid` on a top-level object does **not** automatically validate nested objects unless you mark the nested field with `@Valid` too:

```java
public class OrderDto {

    @NotNull
    private AccountOwnerDto owner;

    @Valid   // without this, owner's own constraints are never checked
    private AccountOwnerDto ownerValidated;

    @Valid
    private List<@Valid LineItemDto> items; // @Valid inside the generic cascades into each element
}
```

This is a common source of silent bugs: a nested DTO has perfectly good constraints, but because the parent object forgot `@Valid` on that field, they never fire. The rule is simple but easy to forget: **validation only cascades through fields explicitly marked `@Valid`.** It doesn't walk the whole object graph automatically — that's a deliberate design choice in the spec to avoid infinite recursion on circular references and to keep validation scope explicit.

## Validation Groups

Groups let the same DTO apply different constraints depending on context — most commonly, "create" vs "update" (where `id` must be absent on create but present on update):

```java
public interface OnCreate {}
public interface OnUpdate {}

public record AccountOwnerDto(
    @Null(groups = OnCreate.class)
    @NotNull(groups = OnUpdate.class)
    Long id,

    @NotBlank(groups = { OnCreate.class, OnUpdate.class })
    String username
) {}
```

```java
@PostMapping
public ResponseEntity<?> create(@Validated(OnCreate.class) @RequestBody AccountOwnerDto dto) { ... }

@PutMapping("/{id}")
public ResponseEntity<?> update(@Validated(OnUpdate.class) @RequestBody AccountOwnerDto dto) { ... }
```

Important subtlety: when you specify a group explicitly like `@Validated(OnCreate.class)`, **only** constraints belonging to that group run. Any constraint with no `groups()` specified belongs to the implicit `Default` group, and that `Default` group is _not_ automatically included once you specify another group — if you want a constraint to always apply regardless of context, put it in `Default.class` explicitly or specify `groups = { Default.class, OnCreate.class }`. In practice, groups are used sparingly; most teams instead model create/update as separate DTOs (which you've already seen in your entity/DTO/mapper work) because it's more explicit than juggling group interfaces.

## Summary of the Moving Parts

|Trigger|Annotation|Where it applies|Exception thrown|Mechanism|
|---|---|---|---|---|
|Request body / model object|`@Valid`|Controller method parameter|`MethodArgumentNotValidException`|Argument resolver|
|Path variable / request param (bare value)|`@Validated` (class) + constraint on param|Controller class + parameter|`ConstraintViolationException` / `HandlerMethodValidationException`|AOP proxy|
|Manual validation|none (direct call)|Anywhere you inject `Validator`|`ConstraintViolationException` if you throw it yourself|Direct API call|
|Nested object|`@Valid` on the field|DTO field referencing another validated type|same as parent trigger|Cascading|
|Conditional constraints|`groups()`|Any constraint|same as parent trigger|Group filtering|

That table is really the whole mental model: one specification (`jakarta.validation`), one reference implementation (Hibernate Validator) that Spring Boot wires in via the starter, and two distinct Spring-side trigger paths depending on whether you're validating a bound object or a loose method parameter.


[[Spring Framework]]
