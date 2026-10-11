

**Definition:** Validation annotations are constraint declarations. Each one describes a rule a validator can check on a field, parameter, or return value. They come from three sources, and knowing the source tells you the package, whether it needs extra dependencies, and whether it is portable.

**Mental model:** Think of them as three layers.

1. **Jakarta Bean Validation (`jakarta.validation.constraints.*`)** is the standard, a specification.
2. **Hibernate Validator (`org.hibernate.validator.constraints.*`)** is the reference implementation, which adds extra constraints beyond the spec.
3. **Spring (`org.springframework.validation.annotation.*`)** adds triggers and grouping, not constraints.

The most important fact in this whole topic is how each constraint treats `null`. Most constraints consider `null` **valid**, and only three reject it. Most validation bugs come from missing this.

## 1. Standard constraints (`jakarta.validation.constraints`)

Dependency: `spring-boot-starter-validation`. Boot 3+ uses `jakarta.*`, and older tutorials with `javax.validation.*` won't compile.

### Null and emptiness

|Annotation|Passes when|Types|`null`|
|---|---|---|---|
|`@Null`|Value is null|Any|Valid (it requires null)|
|`@NotNull`|Value is not null|Any|**Rejects**|
|`@NotEmpty`|Not null, and size > 0|`String`, `Collection`, `Map`, arrays|**Rejects**|
|`@NotBlank`|Not null, and has at least one non-whitespace character|`CharSequence` only|**Rejects**|

The three are cumulative in strength for strings: `@NotNull` < `@NotEmpty` < `@NotBlank`. For `" "`, `@NotNull` passes, `@NotEmpty` passes, and `@NotBlank` fails.

### Booleans

|Annotation|Passes when|
|---|---|
|`@AssertTrue`|Value is `true`|
|`@AssertFalse`|Value is `false`|

Both treat `null` as valid. `@AssertTrue` has a second use: put it on a boolean method like `isPasswordsMatch()` to validate a rule across several fields (see the example below).

### Numbers

|Annotation|Passes when|Notes|
|---|---|---|
|`@Min(n)` / `@Max(n)`|Value ≥ n / ≤ n|`long` parameter. **Not supported on `double`/`float`** because of rounding|
|`@DecimalMin("x")` / `@DecimalMax("x")`|Value ≥ x / ≤ x|Takes a **String**; `inclusive = false` makes it strict. Works with `BigDecimal`|
|`@Positive` / `@PositiveOrZero`|> 0 / ≥ 0|Supports `float` and `double` too|
|`@Negative` / `@NegativeOrZero`|< 0 / ≤ 0|Same|
|`@Digits(integer = 5, fraction = 2)`|At most 5 integer digits and 2 fraction digits|Good for money in `BigDecimal`|

### Text and collections

|Annotation|Passes when|Notes|
|---|---|---|
|`@Size(min, max)`|Length or size is in range|`String`, `Collection`, `Map`, arrays. Null is valid|
|`@Pattern(regexp)`|Whole string matches the regex|Full match, not "contains". Null is valid|
|`@Email`|Looks like an email address|**Lenient**: `a@b` passes. Use `regexp` for stricter checks|

### Dates and times

|Annotation|Passes when|
|---|---|
|`@Past` / `@PastOrPresent`|Date is before now / not after now|
|`@Future` / `@FutureOrPresent`|Date is after now / not before now|

They support `java.time` types (`LocalDate`, `LocalDateTime`, `Instant`, `ZonedDateTime`, ...). "Now" comes from a `ClockProvider`, and you can supply a fixed clock in tests.

### Structural annotations

- `@Valid`: Not a rule. It tells the validator to **cascade** into a nested object, collection element, or map value.
- Container element constraints: `List<@NotBlank String>`, `Map<@NotNull String, @Positive Integer>`. The constraint goes on the type argument.

## 2. Hibernate Validator extras (`org.hibernate.validator.constraints`)

These are non-standard, so your code depends on the implementation. In a Spring Boot project that is not a practical problem, because Hibernate Validator is what the starter brings.

|Annotation|Checks|
|---|---|
|`@Range(min, max)`|Number in range (a combined `@Min` + `@Max`)|
|`@Length(min, max)`|String length (overlaps with `@Size`). Check your version, since newer releases deprecate it in favor of `@Size`|
|`@URL`|Valid URL|
|`@UUID`|String is a well-formed UUID (HV 8+)|
|`@UniqueElements`|Collection has no duplicates|
|`@CreditCardNumber`|Passes the Luhn check|
|`@ISBN`, `@EAN`|Book and barcode formats|
|`@CodePointLength`|Length in Unicode code points|
|`@DurationMin` / `@DurationMax`|Bounds on a `Duration`|
|`@Currency`|Value is a valid currency code|
|`@ScriptAssert`|Class-level expression. Avoid it, because scripting is fragile and hard to debug|

## 3. Spring and meta-annotations

|Annotation|Package|Purpose|
|---|---|---|
|`@Validated`|Spring|Class-level: enables method validation via a proxy. Also selects **validation groups**|
|`@Valid`|Jakarta|Trigger on a parameter, and cascade marker on fields|
|`@Constraint(validatedBy = ...)`|Jakarta|Marks your own annotation as a constraint|
|`@GroupSequence`|Jakarta|Orders group validation (check cheap rules first)|
|`@ConvertGroup`|Jakarta|Maps one group to another during cascading|
|`@ReportAsSingleViolation`|Jakarta|Combines a composed constraint into one error message|

## Every attribute you will meet

All standard constraints share three attributes:

```java
@Size(min = 2, max = 50,
      message = "name must be between {min} and {max} characters",
      groups = OnCreate.class)
private String name;
```

- `message`: The error text. `{min}` and `{max}` are replaced with the annotation's own attribute values. A message in braces like `{validation.name.size}` is looked up in `ValidationMessages.properties`, which is how you internationalize messages. Without a custom message you get the default, such as "must not be blank".
- `groups`: Assigns the rule to a named group. Rules are only checked when their group is active. By default everything is in the `Default` group.
- `payload`: Attaches metadata (like a severity) to the constraint. It's rarely used.

## One DTO using the common ones

```java
public record RegisterRequest(

        @NotBlank @Size(min = 3, max = 30)
        @Pattern(regexp = "^[a-z0-9_]+$", message = "only lowercase letters, digits and _")
        String username,

        @NotBlank @Email
        String email,

        @NotNull @Past
        LocalDate birthDate,

        @NotNull @DecimalMin("0.01") @Digits(integer = 8, fraction = 2)
        BigDecimal initialDeposit,

        @NotEmpty @Size(max = 5)
        List<@NotBlank @Size(max = 20) String> tags,

        @NotNull @AssertTrue(message = "terms must be accepted")
        Boolean acceptedTerms
) {}
```

Line by line:

- `username`: `@NotBlank` rejects null and blanks. `@Size` bounds the length. Both are needed, since `@Size` alone lets null through and `@NotBlank` alone allows 10,000 characters. `@Pattern` must match the **entire** string, so no `.*` is needed at the ends. The custom `message` replaces the unhelpful default.
- `email`: `@NotBlank` for presence, `@Email` for format. `@Email` alone would let `""`... actually, an empty string passes `@Email`, which is another reason to add `@NotBlank`.
- `birthDate`: `@NotNull` is needed because `@Past` treats null as valid.
- `initialDeposit`: `@DecimalMin("0.01")` takes a string to avoid floating-point issues. `@Digits(integer = 8, fraction = 2)` limits it to 8 whole digits and 2 decimals, which matches a `DECIMAL(10,2)` column. This ties back to keeping DTO and DB limits in sync.
- `tags`: `@NotEmpty @Size(max = 5)` constrains the **list** (at least one, at most five). The constraints inside `<...>` apply to **each element**. Those are different levels, so putting `@Size(max = 20)` on the list itself would limit the number of tags, not their length.
- `acceptedTerms`: Uses `Boolean` (wrapper) so that "field missing" is distinguishable from `false`. With a primitive `boolean`, a missing field silently becomes `false`, and `@NotNull` would be meaningless.

## A cross-field rule using `@AssertTrue`

```java
public record ChangePasswordRequest(
        @NotBlank @Size(min = 12) String newPassword,
        @NotBlank String confirmPassword
) {
    @AssertTrue(message = "passwords do not match")
    public boolean isPasswordsMatch() {
        return newPassword == null || newPassword.equals(confirmPassword);
    }
}
```

- The validator treats `isPasswordsMatch()` as a boolean property and checks that it is `true`.
- The `newPassword == null ||` guard matters. If the other constraints already caught the null, this method must not throw a `NullPointerException`.
- This is fine for small rules. For anything reusable, write a class-level custom constraint (a future lesson).

## Where they can be placed

Constraints can go on fields, getters, parameters, return values, container type arguments, and (for custom ones) other annotations or classes. Where you put them depends on what you validate:

```java
public record Dto(@NotBlank String name) {}          // record component (applies to the field)
void find(@PathVariable @Positive Long id) {}        // controller/service parameter
@NotNull Product load(Long id) {}                    // return value (needs @Validated on the class)
```

## Edge cases that cause real bugs

- **The null trap.** Only `@NotNull`, `@NotEmpty`, and `@NotBlank` reject null. Pair every other constraint with `@NotNull` if the field is required.
- **`@NotBlank` on a non-string.** It only supports `CharSequence`. On an `Integer` it throws `UnexpectedTypeException` at validation time, not at compile time.
- **Unsupported type combinations** fail the same way. `@Min` on a `String` or `@Size` on an `Integer` is a runtime error.
- **No cascade by default.** A nested DTO needs `@Valid`, or its constraints are never checked.
- **`@Email` is permissive.** Treat it as a sanity check, not as proof the address exists or can receive mail.
- **Message source of truth.** Default messages are localized according to the request's `Locale`, so tests that assert on English text fail on a machine with another locale. Assert on the field name, not the message.
- **Triggers differ.** The constraint does nothing until something runs the validator: `@Valid` on a controller body, `@Validated` on a service class, or Hibernate's persist-time check on entities.

## Alternatives when annotations are not enough

- A custom constraint (`@interface` + `ConstraintValidator`) for reusable rules.
- A Spring `Validator` implementation for complex logic.
- Plain `if` checks in the service for business rules that need the database or other state.
- Database constraints as the final guarantee, as covered earlier.

**Rule of thumb:** for each required field decide three things: is null allowed (`@NotNull` / `@NotBlank`), what shape must it have (`@Size`, `@Pattern`, `@Min`...), and does it contain nested objects that need `@Valid`.




[[Spring Framework]]
