
By default, Spring just hands you whatever text was in that URL segment — `@PathVariable String username` means "bind whatever's there, I'm not checking it." That's fine until someone requests `/user/' OR '1'='1` or a 300-character garbage string, and your service and database end up dealing with input nobody validated. Production code needs a boundary that rejects bad input _before_ it reaches your service layer, not inside it.

## Layer 1: let the type do some filtering for free

If the path variable has a natural non-String type — an ID, a UUID, a date — just declare it as that type:

```java
@GetMapping("/user/{id}")
public ResponseEntity<AccountOwnerResponse> findById(@PathVariable Long id) { ... }
```

Spring's conversion layer tries to turn the path segment into a `Long` before your method ever runs. If someone sends `/user/abc`, it throws `MethodArgumentTypeMismatchException` and your method body never executes — you get this for free, no annotation needed.

But `username` is a String by nature, so this trick doesn't apply to your case. You need real constraint validation.

## Layer 2: Bean Validation on the path variable itself

This is the part people get wrong: `@Valid` only works on method _bodies_ (like a `@RequestBody` DTO) because it validates an object's fields. A `@PathVariable` isn't an object with fields — it's a single value. For that, Spring uses **method parameter validation**, which needs two things:

1. `@Validated` on the **controller class** (not the method) — this tells Spring "wrap this controller in a proxy that checks constraint annotations on method parameters."
2. A Bean Validation constraint annotation directly on the parameter.

```java
@Validated
@RestController
@RequestMapping("/account-owners")
public class AccountOwnerController {

    private final AccountOwnerService accountOwnerService;

    @GetMapping("/user/{username}")
    public ResponseEntity<AccountOwnerResponse> findByUserName(
            @PathVariable
            @Pattern(regexp = "^[a-zA-Z0-9_]{3,20}$",
                     message = "username must be 3-20 characters: letters, digits, or underscore")
            String username) {

        AccountOwnerResponse owner = accountOwnerService.findByUsername(username);
        return ResponseEntity.ok(owner);
    }
}
```

`@Pattern` is the Bean Validation annotation you'd normally reach for on a DTO field — here it's just sitting directly on the parameter instead. The regex above is a whitelist: only the characters you explicitly allow get through, everything else is rejected before `findByUsername` is ever called.

If the pattern fails, Spring throws `ConstraintViolationException` — not the `MethodArgumentNotValidException` you'd see from a `@Valid @RequestBody` failure. They look similar but come from two different validation paths (method-parameter validation vs. object validation), so your exception handler needs a separate `@ExceptionHandler` for each.

## Wiring it into your existing exception handling

Since you already have an `ApiExceptionHandler` built on `ProblemDetail`, this slots in as one more handler method there:

```java
@ExceptionHandler(ConstraintViolationException.class)
public ProblemDetail handleConstraintViolation(ConstraintViolationException ex) {
    ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
    problem.setTitle("Invalid request parameter");
    problem.setDetail(ex.getConstraintViolations().iterator().next().getMessage());
    return problem;
}
```

Now a bad username returns a clean `400` with your standard `problem+json` shape, instead of a stack trace or a generic `500`.

## The production-standard pattern, pulled together

The design professional Spring Boot apps converge on is:

- **Validate at the edge, trust inside.** Once a value passes the controller's constraint, the service and repository layers treat it as already-safe. You don't re-validate `username` inside `AccountOwnerService` — that would be duplicated logic and duplicated regexes going stale independently.
- **Whitelist, don't blacklist.** `@Pattern` describes what's _allowed_ (`[a-zA-Z0-9_]{3,20}`), not a blocklist of bad characters you're trying to think of in advance. Blacklists always miss something.
- **Make reusable constraints a custom annotation** once you use the same pattern in more than one place (a `RegisterRequest` DTO _and_ this path variable, say):

```java
@Target({ElementType.PARAMETER, ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Pattern(regexp = "^[a-zA-Z0-9_]{3,20}$", message = "must be 3-20 characters: letters, digits, or underscore")
@Constraint(validatedBy = {})
public @interface ValidUsername {
    String message() default "must be 3-20 characters: letters, digits, or underscore";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

Then both places just say `@ValidUsername String username` — one source of truth for the rule.

- **Validation is not a substitute for parameterized queries.** `@Pattern` stops obviously malicious or malformed input from reaching your code at all, but your repository should still be using `PreparedStatement`/Spring Data's parameter binding regardless — that's a second, independent layer, not something the regex replaces.

That combination — type coercion where it applies, `@Validated` + constraint annotations at the controller boundary, centralized handling through your existing `ProblemDetail` setup, and parameterized persistence underneath — is what you'll see in any Spring Boot codebase built to a professional standard.



[[Spring Security]]