

An **AuthenticationProvider** is the specialist that actually checks one kind of proof. The `AuthenticationManager` is the receptionist: it takes the login attempt and asks its providers, "can any of you handle this?" The provider that says yes does the real work and either returns a trusted `Authentication` or throws an exception. For username and password, that specialist is `DaoAuthenticationProvider`. It is the piece that calls your `UserDetailsService` and your `PasswordEncoder`.

The second half of this lesson is about the data that arrives _before_ any of this happens. You will learn how to design validation so only a "normal" username gets through. You will also learn one thing that surprises many people: validation is **not** what stops SQL injection. Parameterized queries are. Validation is a second wall, and you need both.

## Part 1: Who calls whom

The five helpers, in one picture (validation happens first, outside the manager):

```
Request JSON
   │
   ▼
[1] Bean Validation          ← checks shape, at the controller (@Valid)
   │
   ▼
AuthService.login()
   │
   ▼
[2] AuthenticationManager    ← receptionist: loops over providers
   │
   ▼
[3] AuthenticationProvider   ← specialist (DaoAuthenticationProvider)
   │        ├── [4] UserDetailsService   ← "find me this user"
   │        └── [5] PasswordEncoder      ← "does this password match the hash?"
   ▼
Authenticated Authentication, or an exception
```

And here is which helper is used on which path. Notice that **registration never touches the manager or the provider**:

|Helper|Register|Login|
|---|---|---|
|Bean Validation|Strict rules on `RegisterRequest`|Light rules on `LoginRequest`|
|PasswordEncoder|`encode()` once|`matches()` inside the provider|
|UserDetailsService|Not used (you use `existsBy...` instead)|Loads the user inside the provider|
|AuthenticationProvider|Not used|Does the whole check|
|AuthenticationManager|Not used|Entry point, picks the provider|

## Part 2: Inside DaoAuthenticationProvider, step by step

The interface has just two methods:

```java
public interface AuthenticationProvider {
    Authentication authenticate(Authentication authentication) throws AuthenticationException;
    boolean supports(Class<?> authentication);
}
```

- `supports(...)` answers "do I understand this kind of token?" The Dao provider says yes to `UsernamePasswordAuthenticationToken` only.
- `authenticate(...)` does the work. It has three possible outcomes: return an authenticated `Authentication` (success), throw an `AuthenticationException` (failure), or return `null` (rare: "I can't decide, ask someone else").

When your login calls `authenticationManager.authenticate(token)`, the Dao provider walks through these steps:

|Step|What happens|Helper used|If it fails|
|---|---|---|---|
|1. Load|Calls `loadUserByUsername(identifier)`|UserDetailsService|`UsernameNotFoundException`, turned into `BadCredentialsException`|
|2. Pre-checks|`isAccountNonLocked()`, `isEnabled()`, `isAccountNonExpired()`|The `UserDetails` object|`LockedException`, `DisabledException`, `AccountExpiredException`|
|3. Password|`passwordEncoder.matches(raw, userDetails.getPassword())`|PasswordEncoder|`BadCredentialsException`|
|4. Post-check|`isCredentialsNonExpired()`|The `UserDetails` object|`CredentialsExpiredException`|
|5. Build result|Creates a new authenticated token: principal = `UserDetails`, authorities filled in, password erased|None|None|

Two clever details worth knowing:

1. **It hides "user not found".** By default it converts `UsernameNotFoundException` into `BadCredentialsException`, so the caller can't tell "no such user" from "wrong password."
2. **It resists timing attacks.** If the user doesn't exist, it still runs a dummy password comparison, so a missing user doesn't answer noticeably faster than a wrong password. This is one strong reason to prefer the built-in provider over writing your own.

## Part 3: Writing your own provider (to see how it works)

You rarely need to write one for username and password, but doing it once makes the Dao provider obvious. Here is the same logic by hand:

```java
@Component
@RequiredArgsConstructor
public class CredentialsAuthenticationProvider implements AuthenticationProvider {

    private final AppUserDetailsService userDetailsService;
    private final PasswordEncoder passwordEncoder;

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String identifier  = authentication.getName();
        String rawPassword = (String) authentication.getCredentials();

        UserDetails user;
        try {
            user = userDetailsService.loadUserByUsername(identifier);                // helper 4
        } catch (UsernameNotFoundException e) {
            throw new BadCredentialsException("Invalid credentials");
        }

        if (!user.isEnabled())          throw new DisabledException("Account disabled");
        if (!user.isAccountNonLocked()) throw new LockedException("Account locked");

        if (!passwordEncoder.matches(rawPassword, user.getPassword())) {              // helper 5
            throw new BadCredentialsException("Invalid credentials");
        }

        return UsernamePasswordAuthenticationToken.authenticated(user, null, user.getAuthorities());
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

Line by line:

- `authentication.getName()` is the identifier the person typed. `getCredentials()` is the raw password.
- The `try/catch` is the "hide user not found" behavior, written by hand.
- The flag checks come before the password check, the same order as the built-in provider.
- `UsernamePasswordAuthenticationToken.authenticated(...)` builds the **authenticated** version. The second argument is `null` on purpose: we don't keep the raw password.
- `supports(...)` tells the manager "send me username/password tokens, nothing else."

Weakness of this hand-written version: an unknown user returns faster than a wrong password. The built-in provider avoids that, so for real apps use `DaoAuthenticationProvider` (from last lesson) and write a custom provider only for something genuinely different, like an API key, a one-time code, or a login through an outside service.

## Part 4: How the manager chooses a provider

`ProviderManager` holds a list and loops over it. In plain words:

```java
@Bean
public AuthenticationManager authenticationManager(DaoAuthenticationProvider dao,
                                                   ApiKeyAuthenticationProvider apiKey) {
    return new ProviderManager(List.of(dao, apiKey));
}
```

For each provider, in order:

1. If `supports(token.getClass())` is false, **skip** it.
2. Otherwise call `authenticate(token)`.
3. If it returns a result, **stop and return** it (the manager also erases the credentials from the result).
4. If it throws a normal `AuthenticationException` such as `BadCredentialsException`, remember the error and **try the next provider**.
5. If it throws an account-status error (`DisabledException`, `LockedException`), **stop immediately**. The person is known but not allowed, so asking more providers makes no sense.
6. If nobody handled it, throw the last error (or `ProviderNotFoundException` if no provider supported the token at all).

That is why one manager can support password login and API keys side by side: each provider only reacts to its own token type.

## Part 5: Designing input validation

### Decide your policy first

You said you want to block special characters and numbers. The tool for this is an **allow-list**: describe exactly what _is_ allowed, and reject everything else. Never try the reverse (a block-list of "bad characters" or stripping them), because attackers are better at finding what you forgot than you are at listing it.

One honest note: **numbers are not dangerous.** `ali2000` is harmless. Blocking digits only forces people into awkward names and more collisions. Your choice, but here are the common policies:

|Policy|Regex|Allows|Good for|
|---|---|---|---|
|Letters only|`^[A-Za-z]{3,30}$`|`Ali`, `sara`|Display-name style, very strict|
|Letters, digits, underscore (recommended)|`^[A-Za-z][A-Za-z0-9_]{2,29}$`|`ali_2000` (must start with a letter)|Most apps|
|Plus dot and hyphen|`^[A-Za-z][A-Za-z0-9._-]{2,29}$`|`ali.k-2`|Email-like handles|

Why ASCII only (`A-Za-z`)? Unicode lets people register lookalike letters (a Cyrillic "а" looks like a Latin "a"), which enables impersonation. Keep usernames ASCII, even if display names are not.

### One reusable rule: a custom annotation

Put the rule in one place so every DTO uses the same one:

```java
@Documented
@Constraint(validatedBy = UsernameValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidUsername {
    String message() default "Username must be 3-30 characters: letters, digits or underscore, starting with a letter";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

```java
public class UsernameValidator implements ConstraintValidator<ValidUsername, String> {

    private static final Pattern PATTERN  = Pattern.compile("^[A-Za-z][A-Za-z0-9_]{2,29}$");
    private static final Set<String> RESERVED = Set.of("admin", "root", "support", "system");

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null) return true;                 // @NotBlank reports null, not this
        return PATTERN.matcher(value).matches()
            && !RESERVED.contains(value.toLowerCase());
    }
}
```

Walkthrough:

- The annotation is just a label; the validator class holds the logic.
- `matches()` requires the **whole** string to fit the pattern, so `ali\n` or `ali; DROP` fails.
- The reserved list stops people registering as `admin`. This is a business rule, not security filtering.
- Returning `true` for `null` is a convention: each annotation checks one thing, and `@NotBlank` handles "missing."

Use it:

```java
public record RegisterRequest(
    @NotBlank @Email @Size(max = 254)  String email,
    @NotBlank @ValidUsername           String username,
    @NotBlank @Size(min = 8, max = 72) String password
) {}
```

Regex safety tip: a plain character class with a fixed length, like the one above, is safe. Avoid nested repeats such as `(a+)+`, which can freeze your server on crafted input (this attack is called ReDoS).

### Different fields need different rules

"Validate every string like a username" is a trap. Each field has its own allow-list:

|Field|Rule|Why|
|---|---|---|
|Username|Strict allow-list (above)|It becomes an identifier|
|Email|`@Email` plus `@Size(max=254)`|Real proof is the verification email|
|Password|Length only, **any characters allowed**|It is hashed, never shown or put into SQL. Banning symbols makes passwords weaker|
|Login identifier|`@NotBlank` plus `@Size(max=254)`|Don't leak your username rules to attackers|
|Free text (bio, title)|`@Size(max=...)`, no control characters|Special characters are normal here|
|IDs in the URL|Use `Long` or `UUID` types|A type mismatch is rejected automatically|

### Validate at every door

Validation must run on the **server**; browser checks are only for convenience. Also remember that JSON bodies are not the only input. URL parts and query parameters need rules too:

```java
@GetMapping("/api/users/{username}")
public UserDto get(@PathVariable @ValidUsername String username) { ... }
```

With current Spring Boot (Spring 6.1 and newer) the constraint on a parameter is enforced automatically. On older versions, add `@Validated` on the controller class.

Finally, **reject, don't repair.** If the username is `ali!`, return an error. Don't silently strip the `!`, because then the person doesn't know what name they actually got. Do normalize safe things (lowercase) in the service after validation.

## Part 6: What actually stops SQL injection

SQL injection happens when user text becomes part of the SQL _command_ instead of staying as _data_. Here is the classic case:

|Input typed as username|Code|Resulting SQL|
|---|---|---|
|`ali`|`"... WHERE username = '" + input + "'"`|`... WHERE username = 'ali'` (fine)|
|`' OR '1'='1`|same code|`... WHERE username = '' OR '1'='1'` (returns **everyone**)|

Your username allow-list would block `'` in this one field. But if you rely on that, the very next field you forget to validate becomes a hole. The real fix is to never build SQL by gluing strings. Use **parameters**, where the database receives the command and the data separately. It is the same idea as a JDBC `PreparedStatement`.

**Safe (do these):**

```java
// 1. Derived query: Spring Data generates a parameterized query
Optional<UserCredentials> findByUsername(String username);

// 2. @Query with a named parameter
@Query("select c from UserCredentials c where c.email = :email or c.username = :username")
Optional<UserCredentials> lookup(@Param("email") String email, @Param("username") String username);

// 3. JdbcTemplate with ? placeholders
jdbcTemplate.queryForObject("select count(*) from user_credentials where username = ?", Integer.class, username);
```

**Unsafe (never do these):**

```java
// String concatenation in JPQL or native SQL
em.createQuery("select c from UserCredentials c where c.username = '" + username + "'");
jdbcTemplate.query("select * from user_credentials where username = '" + username + "'", ...);
@Query(value = "select * from user_credentials where username = '" + ... , nativeQuery = true) // same idea
```

Parameters cannot cover two cases, and both need an allow-list:

- **Dynamic column names or sort direction** (e.g. `ORDER BY` from a request parameter). Parameters only replace _values_. Map the input to a fixed list: `Set.of("createdAt", "username").contains(sortField)`.
- **`LIKE` searches.** The input can contain `%` and `_`, which act as wildcards. Escape them if you don't want users matching everything.

Extra walls that cost little:

- Give the application's PostgreSQL user only the permissions it needs, not superuser.
- Never return raw database errors to the client. Use your generic error JSON.
- Keep the length caps. They stop huge payloads and cheap denial-of-service attempts.

## Putting it together on the login path

1. `LoginRequest` passes light validation (not blank, length caps).
2. `AuthService` trims and lowercases, then calls `authenticationManager.authenticate(...)`.
3. The manager finds `DaoAuthenticationProvider`, which calls your `UserDetailsService`.
4. The `UserDetailsService` calls the repository, a **parameterized** query, so even a hostile string stays data.
5. The provider compares with `passwordEncoder.matches(...)` and builds the authenticated result.

## A related concept in brief: XSS

SQL injection attacks the **database** boundary, and parameters fix it. **XSS** (cross-site scripting) attacks the **display** boundary: someone stores `<script>...</script>` in a bio, and it runs in another user's browser when shown. You fix it by _encoding on output_ (React, Thymeleaf and similar escape text by default), not by banning `<` and `>` at input. Two boundaries, two different fixes.





[[Spring Security]]