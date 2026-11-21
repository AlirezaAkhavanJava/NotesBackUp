`@Size` and `@Length` both restrict how long a string (or how many elements a collection) can be, but they come from two different validation worlds that happen to overlap. `@Size` is part of **Jakarta Bean Validation** (the standard, `jakarta.validation.constraints` package) — it works on `String`, `Collection`, `Map`, and arrays. `@Length` is a **Hibernate Validator-specific** extension (`org.hibernate.validator.constraints`) that only works on `String`, and it exists mostly for historical reasons, from back before Bean Validation had a mature standard annotation for this.

**The core difference in code**

```java
import jakarta.validation.constraints.Size;
import org.hibernate.validator.constraints.Length;

public record UserDto(
    @Size(min = 3, max = 20, message = "Username must be 3–20 characters")
    String username,

    @Length(min = 3, max = 20, message = "Username must be 3–20 characters")
    String altUsername,

    @Size(max = 5)
    List<String> tags   // @Length can't do this — no collection support
) {}
```

Functionally, for a `String`, `@Size` and `@Length` behave identically — same `min`/`max` semantics, same failure trigger (character count outside range). The real differences are about **where each one comes from and what it can be used on**:

||`@Size`|`@Length`|
|---|---|---|
|Package|`jakarta.validation.constraints`|`org.hibernate.validator.constraints`|
|Spec|Part of the Jakarta Bean Validation standard|Hibernate Validator-only extension|
|Works on|String, Collection, Map, array|String only|
|Portability|Works with any Bean Validation provider|Only works if your provider is Hibernate Validator|

**Why this matters in practice**

Spring Boot's `spring-boot-starter-validation` pulls in Hibernate Validator as its default Bean Validation implementation, so `@Length` _will_ work out of the box in a typical Spring Boot project. But it's tying your DTO to a specific vendor's extension instead of the Jakarta standard. If a validation provider were ever swapped (rare, but it happens in some enterprise setups), code using `@Length` would break, while `@Size` wouldn't, because it's part of the spec itself, not a Hibernate add-on.

There's also a design signal here: `@Length` was effectively Hibernate Validator filling a gap in old JSR-303 (the first Bean Validation spec) before it fully matured. The modern Jakarta Bean Validation spec (which Spring Boot now targets) considers `@Size` the "correct" general-purpose constraint for this. `@Length` still exists for backward compatibility and because some people like its name being more semantically obvious for strings specifically.

**The practical convention**

Use `@Size` by default. Only reach for `@Length` if you have a very specific reason tied to Hibernate Validator features (for example, some older codebases paired it with `@NotEmpty` conventions before Jakarta's `@NotBlank` existed). For new code, `@Size` is the standard, portable, and recommended choice — and it's the one that also scales to lists, sets, and maps, which `@Length` can never do.




[[Spring Framework]]