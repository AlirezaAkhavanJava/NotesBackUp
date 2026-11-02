


A **DTO** (Data Transfer Object) is a small class whose only job is to carry data across a boundary, here between the outside world (JSON) and your code. A **mapper** is the code that converts one shape into another, for example a DTO into an entity. In a security flow these two ideas matter more than usual, because the entity holds your most sensitive data and the DTO is the only thing a stranger on the internet gets to fill in.

Your instincts are mostly right: records are a great DTO, Bean Validation belongs on them, and messages should be managed in one place. The part to adjust is the mapper. In the credentials flow, the direction of the mapping decides whether you want one at all. The rule to keep is **map outward automatically, map inward deliberately.**

## Part 1: Short answers to your three questions

|Question|Answer|Why|
|---|---|---|
|Records as DTOs?|**Yes**|Immutable, short, work with Jackson and Bean Validation|
|A mapper to join login and register credentials?|**No for inbound. Yes for outbound.**|Inbound needs hashing, normalizing and a server-chosen role. A blind field copy is a security risk|
|Validation messages with each constraint?|**Yes, but as keys plus a properties file**|One source of text, translatable, typo-safe|

## Part 2: Records as DTOs, and the gotchas that matter in production

Records work because Spring Boot 3's Jackson can build them from JSON, and Bean Validation reads annotations on the record components. Four things need care:

**1. A record's automatic `toString()` prints every field, including the password.** One `log.info("Request: {}", req)` and your logs contain passwords. Override it:

```java
@Override
public String toString() {
    return "RegisterRequest[email=" + email + ", username=" + username + ", password=***]";
}
```

**2. Records are your mass-assignment shield.** If a client sends `{"email":"a@b.com","role":"ADMIN"}`, a record without a `role` component simply has nowhere to put it. That is the entire reason you never bind JSON straight onto the entity. For extra strictness you can make unknown fields an error instead of silently ignoring them:

```properties
spring.jackson.deserialization.fail-on-unknown-properties=true
```

**3. Normalize in the compact constructor.** Jackson builds the record (running this constructor) _before_ validation runs, so validation sees clean values, and every later layer gets them too. Never touch the password here.

```java
public RegisterRequest {
    email    = CredentialRules.normalize(email);
    username = CredentialRules.normalize(username);
}
```

**4. Name DTOs by intent, one per use.** `RegisterRequest`, `LoginRequest`, `MeResponse`, `AuthResponse`. Avoid one generic `UserDto` used for input and output, because then every field is both writable and readable by everyone.

## Part 3: Should login and register share one DTO?

They both receive "credentials", which tempts people to share a class. Don't. They look similar but follow different rules:

||`RegisterRequest`|`LoginRequest`|
|---|---|---|
|Purpose|Create an identity|Prove an identity|
|Fields|email, username, password|identifier (email **or** username), password|
|Validation|Strict (formats, strength)|Light (not blank, length caps)|
|Reveal rules to the caller?|Yes, they need them to fix input|**No**, that helps attackers|
|Changes over time|New fields (terms accepted, name...)|Rarely, maybe a "remember me" flag|

One shared class would force either strict rules on login (locks out old users, leaks your rules) or loose rules on register (weak accounts). Records also can't inherit from each other. Instead, **share the rules, not the class**: the same constants, the same message keys and the same `@ValidUsername` annotation (Part 5).

## Part 4: Where mapping happens, and where it must not

|Direction|From|To|Tool|
|---|---|---|---|
|Register (in)|`RegisterRequest`|`UserCredentials`|Service plus an entity factory method (hash in the service)|
|Login (in)|`LoginRequest`|`UsernamePasswordAuthenticationToken`|One line in the service, no mapper|
|Profile (out)|`UserCredentials`|`MeResponse`|MapStruct, or a `from(...)` method|
|Token (out)|Strings|`AuthResponse`|Plain constructor|

### Why not a mapper for registration?

A generated mapper would copy fields by name. Registration needs five things a mapper should not do:

- Hash the password (a side effect that needs the `PasswordEncoder` bean).
- Pick the role (never from the client).
- Generate the id (the database or Hibernate does it).
- Set `enabled`, `locked`, `createdAt` defaults.
- Check duplicates (needs the repository).

**Mappers should be pure functions**: same input, same output, no beans, no database, no hashing. When a conversion needs decisions, write it in the service. To keep that safe and tidy, put a _factory method_ on the entity and stop using public setters for sensitive fields:

```java
@Entity
@Table(name = "user_credentials")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(exclude = "passwordHash")
public class UserCredentials {
    @Id @GeneratedValue
    @UuidGenerator(style = UuidGenerator.Style.VERSION_7)
    private UUID id;

    @Column(nullable = false, length = CredentialRules.EMAIL_MAX)    private String email;
    @Column(nullable = false, length = CredentialRules.USERNAME_MAX) private String username;
    @Column(name = "password_hash", nullable = false, length = 100)  private String passwordHash;

    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private Role role;

    @Column(nullable = false) private boolean enabled;
    @Column(nullable = false) private boolean locked;
    @Column(name = "created_at", nullable = false, updatable = false) private Instant createdAt;

    public static UserCredentials register(String email, String username, String passwordHash) {
        UserCredentials c = new UserCredentials();
        c.email = email;
        c.username = username;
        c.passwordHash = passwordHash;
        c.role = Role.USER;                 // decided by the server, always
        c.enabled = true;
        c.createdAt = Instant.now();
        return c;
    }

    public void changePasswordHash(String newHash) { this.passwordHash = newHash; }
    public void lock()   { this.locked = true; }
    public void unlock() { this.locked = false; }
}
```

There is no `setRole(...)` anywhere, so no code path can accidentally promote a user. The updated service is now short:

```java
@Transactional
public void register(RegisterRequest req) {        // already trimmed and lowercased by the record
    if (repository.existsByEmail(req.email()))       throw new DuplicateCredentialException("credentials.email.taken");
    if (repository.existsByUsername(req.username())) throw new DuplicateCredentialException("credentials.username.taken");

    String hash = passwordEncoder.encode(req.password());
    try {
        repository.save(UserCredentials.register(req.email(), req.username(), hash));
    } catch (DataIntegrityViolationException e) {
        throw new DuplicateCredentialException("credentials.duplicate");
    }
}

public AuthResponse login(LoginRequest req) {
    Authentication auth = authenticationManager.authenticate(
        UsernamePasswordAuthenticationToken.unauthenticated(req.identifier(), req.password()));
    return new AuthResponse(jwtService.generateToken((AppUserDetails) auth.getPrincipal()));
}
```

### Where a mapper does earn its place: outbound

Going out, the risk is the reverse: leaking a field you shouldn't. Here a mapper is safe and saves boilerplate. With MapStruct:

```java
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.ERROR)
public interface UserMapper {
    MeResponse toMe(UserCredentials credentials);     // record target: id, email, username, role
}
```

The `ERROR` policy is a production habit: if someone adds a field to `MeResponse` that the entity can't supply, the **build fails** instead of silently returning `null`. `passwordHash` can't leak because it is not a component of `MeResponse`.

For a project with only a couple of response types, a plain method is equally good and needs no library:

```java
public record MeResponse(UUID id, String email, String username, Role role) {
    public static MeResponse from(UserCredentials c) {
        return new MeResponse(c.getId(), c.getEmail(), c.getUsername(), c.getRole());
    }
}
```

Pick one style and use it everywhere, so a reader always knows where conversions live.

## Part 5: Validation rules and messages, designed for production

### Step 1: one place for the numbers and the normalizer

Your DTO annotation, your entity column length and your database script should never disagree. Put the facts in one class:

```java
public final class CredentialRules {
    private CredentialRules() {}

    public static final int EMAIL_MAX = 254;
    public static final int USERNAME_MIN = 3;
    public static final int USERNAME_MAX = 30;
    public static final int PASSWORD_MIN = 8;
    public static final int PASSWORD_MAX = 72;          // BCrypt only uses the first 72 bytes
    public static final int LOGIN_PASSWORD_MAX = 128;

    public static final String USERNAME_REGEX =
        "^[A-Za-z][A-Za-z0-9_]{" + (USERNAME_MIN - 1) + "," + (USERNAME_MAX - 1) + "}$";
    public static final String PASSWORD_REGEX = "^(?=.*[A-Za-z])(?=.*\\d).+$";

    public static String normalize(String value) {
        return value == null ? null : value.trim().toLowerCase(Locale.ROOT);
    }
}
```

Two details: the regex is built from the same constants, so it can never drift from the length rule. And `Locale.ROOT` matters: in a Turkish default locale, `"I".toLowerCase()` becomes `"ı"` (dotless i), which silently breaks logins. Always pass `Locale.ROOT` when normalizing identifiers.

You asked about keeping messages "inside the body" of the record. Records _can_ hold static constants in their body, but login and register share the same messages, so a separate class is better:

```java
public final class Msg {
    private Msg() {}
    public static final String EMAIL_REQUIRED    = "{credentials.email.required}";
    public static final String EMAIL_INVALID     = "{credentials.email.invalid}";
    public static final String EMAIL_SIZE        = "{credentials.email.size}";
    public static final String USERNAME_REQUIRED = "{credentials.username.required}";
    public static final String USERNAME_INVALID  = "{credentials.username.invalid}";
    public static final String PASSWORD_REQUIRED = "{credentials.password.required}";
    public static final String PASSWORD_SIZE     = "{credentials.password.size}";
    public static final String PASSWORD_WEAK     = "{credentials.password.weak}";
    public static final String IDENTIFIER_REQUIRED = "{login.identifier.required}";
    public static final String LOGIN_FIELD_TOO_LONG = "{login.field.size}";
}
```

Annotation values must be compile-time constants, which `static final String` fields are. The curly braces mean "look this key up in a message bundle". You get typo safety from the compiler (a wrong constant name won't compile) and the text lives elsewhere.

### Step 2: the message bundle (`src/main/resources/messages.properties`)

```properties
credentials.email.required=Email is required
credentials.email.invalid=Email address is not valid
credentials.email.size=Email must be at most {max} characters
credentials.username.required=Username is required
credentials.username.invalid=Username must be 3 to 30 characters, start with a letter, and contain only letters, digits or underscore
credentials.password.required=Password is required
credentials.password.size=Password must be between {min} and {max} characters
credentials.password.weak=Password must contain at least one letter and one digit
login.identifier.required=Email or username is required
login.field.size=Value is too long

credentials.email.taken=This email is already registered
credentials.username.taken=This username is already taken
credentials.duplicate=Email or username is already in use
```

`{min}` and `{max}` are filled in from the annotation's own attributes, so the text stays correct when you change a limit.

### Step 3: tell the validator to use your MessageSource

This is what makes the same file work for validation, for your exceptions, and for other languages (`messages_de.properties`, `messages_fr.properties`; the `Accept-Language` header picks the file):

```java
@Configuration
public class ValidationConfig {
    @Bean
    public LocalValidatorFactoryBean validator(MessageSource messageSource) {
        LocalValidatorFactoryBean bean = new LocalValidatorFactoryBean();
        bean.setValidationMessageSource(messageSource);
        return bean;
    }
}
```

The zero-config alternative is to put the same keys in a file named exactly `ValidationMessages.properties`, which Hibernate Validator reads on its own. That works fine for a single language, but then your exception messages need a second file. One `messages.properties` for everything is easier to maintain.

### Step 4: the final DTOs

```java
public record RegisterRequest(

    @NotBlank(message = Msg.EMAIL_REQUIRED)
    @Email(message = Msg.EMAIL_INVALID)
    @Size(max = CredentialRules.EMAIL_MAX, message = Msg.EMAIL_SIZE)
    String email,

    @NotBlank(message = Msg.USERNAME_REQUIRED)
    @ValidUsername
    String username,

    @NotBlank(message = Msg.PASSWORD_REQUIRED)
    @Size(min = CredentialRules.PASSWORD_MIN, max = CredentialRules.PASSWORD_MAX, message = Msg.PASSWORD_SIZE)
    @Pattern(regexp = CredentialRules.PASSWORD_REGEX, message = Msg.PASSWORD_WEAK)
    String password
) {
    public RegisterRequest {
        email    = CredentialRules.normalize(email);
        username = CredentialRules.normalize(username);
    }

    @Override
    public String toString() {
        return "RegisterRequest[email=" + email + ", username=" + username + ", password=***]";
    }
}
```

```java
public record LoginRequest(

    @NotBlank(message = Msg.IDENTIFIER_REQUIRED)
    @Size(max = CredentialRules.EMAIL_MAX, message = Msg.LOGIN_FIELD_TOO_LONG)
    String identifier,

    @NotBlank(message = Msg.PASSWORD_REQUIRED)
    @Size(max = CredentialRules.LOGIN_PASSWORD_MAX, message = Msg.LOGIN_FIELD_TOO_LONG)
    String password
) {
    public LoginRequest {
        identifier = CredentialRules.normalize(identifier);
    }

    @Override
    public String toString() { return "LoginRequest[identifier=" + identifier + ", password=***]"; }
}
```

Update the custom annotation from the earlier lesson to use the shared pieces: its default message becomes `{credentials.username.invalid}`, and `UsernameValidator` uses `CredentialRules.USERNAME_REGEX`.

A note on the login record: the messages are deliberately neutral ("too long", not "must be 3 to 30 characters"), so login never teaches an attacker your username rules.

## Part 6: Turning violations into the response

```java
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private final MessageSource messages;

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail onInvalidBody(MethodArgumentNotValidException ex) {
        Map<String, List<String>> errors = new TreeMap<>();
        ex.getBindingResult().getFieldErrors().forEach(e ->
            errors.computeIfAbsent(e.getField(), k -> new ArrayList<>()).add(e.getDefaultMessage()));

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        pd.setProperty("errors", errors);
        return pd;
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ProblemDetail onMalformedJson() {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Malformed request body");
    }

    @ExceptionHandler(DuplicateCredentialException.class)
    ProblemDetail onDuplicate(DuplicateCredentialException ex) {
        String text = messages.getMessage(ex.getCode(), null, LocaleContextHolder.getLocale());
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, text);
    }
}
```

An example 400 response:

```json
{
  "status": 400,
  "detail": "Validation failed",
  "errors": {
    "email": ["Email address is not valid"],
    "password": ["Password must be between 8 and 72 characters", "Password must contain at least one letter and one digit"]
  }
}
```

Design choices in that handler:

- **A list per field.** One bad value can break several rules (an empty password fails `@NotBlank`, `@Size` and `@Pattern`), and the order of violations is not guaranteed. Returning all of them is deterministic, and the frontend can show the first.
- **The rejected value is never copied into the response.** Echoing input is how passwords and injected text end up in browser consoles and logs.
- **Malformed JSON gets its own generic message**, so parser internals don't leak.
- `DuplicateCredentialException` now carries a _code_ (a message key), and the handler translates it for the caller's language.
- If you validate `@PathVariable` or `@RequestParam` directly, Spring 6.1+ throws `HandlerMethodValidationException`. The simplest way to cover it and many other MVC errors is to have the advice extend `ResponseEntityExceptionHandler`, or to set `spring.mvc.problemdetails.enabled=true`.

## Part 7: Test the rules and the messages

Rule tests are cheap and protect you from regressions:

```java
@SpringBootTest
class RegisterRequestValidationTest {

    @Autowired Validator validator;                       // the Spring-configured one, with your messages

    @Test
    void rejectsBadUsernameWithReadableMessage() {
        var req = new RegisterRequest("a@b.com", "ali!", "Passw0rdOK");
        var violations = validator.validate(req);

        assertThat(violations).hasSize(1);
        String message = violations.iterator().next().getMessage();
        assertThat(message).doesNotContain("{");           // fails if the bundle isn't wired
        assertThat(message).contains("letters, digits or underscore");
    }

    @Test
    void normalizesBeforeValidating() {
        var req = new RegisterRequest("  Ali@Mail.COM ", "Ali_99", "Passw0rdOK");
        assertThat(req.email()).isEqualTo("ali@mail.com");
        assertThat(validator.validate(req)).isEmpty();
    }
}
```

If you ever see a raw `{credentials.email.required}` in a response, the validator is not reading your `MessageSource`, and the `doesNotContain("{")` check above will catch that.

## Production checklist for this layer

|Area|Do this|
|---|---|
|Logging|Override `toString` on every DTO that carries a secret; never log request bodies on auth endpoints|
|Mass assignment|Records only, no entity as `@RequestBody`; optionally fail on unknown JSON properties|
|Single source of truth|Limits and regex in `CredentialRules`, used by DTO, entity and tests; mirror them in the SQL migration|
|Normalization|One method, `Locale.ROOT`, applied in the record constructor|
|Messages|Keys in `Msg`, text in `messages.properties`, one file per language|
|Responses|`ProblemDetail`, errors keyed by field, no rejected values, no stack traces|
|Login errors|Neutral wording; never explain which part was wrong|
|Mappers|Pure functions; outbound only; `unmappedTargetPolicy = ERROR`|
|Entity|No public setters on role, password hash or flags; use factory and intent methods|
|Password policy|Length matters more than symbols; consider a minimum of 12 and a check against a list of common or breached passwords|
|Tests|One test per rule, plus one that proves messages resolve|

## A related concept in brief: validation groups

Bean Validation has **groups**, which let one DTO apply different rules in different situations (`@NotNull(groups = Create.class)` versus `groups = Update.class`). It sounds like a fix for "login and register share a class", but groups make the rules harder to read, and one class still carries fields that don't apply to every use. Most production teams choose separate small records instead, which is the approach you now have.




[[Spring Security]]