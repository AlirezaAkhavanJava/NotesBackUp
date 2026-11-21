
An `AuthenticationProvider` is the part of Spring Security that actually decides "is this person who they claim to be?" It receives an unverified login attempt (for example, a username and a password someone typed) and either returns a fully verified `Authentication` object or rejects the attempt with an exception. It's the judge. Everything else in the login flow is there to deliver the case to the judge or to remember the verdict.

You've already met one without knowing it: the `DaoAuthenticationProvider` from the `UserDetailsService` lesson. It was the one calling your service and checking the password. In this lesson you'll see how it fits into the bigger picture, how to write your own, and when you'd want to.

## 1. The interface

It has exactly two methods:

```java
public interface AuthenticationProvider {
    Authentication authenticate(Authentication authentication) throws AuthenticationException;
    boolean supports(Class<?> authentication);
}
```

|Method|The question it answers|
|---|---|
|`supports(Class<?>)`|"Is this the kind of login attempt I know how to handle?"|
|`authenticate(Authentication)`|"Is this attempt valid? If yes, give me the verified result."|

The `Authentication` object is the thing being passed around. Before verification it's a "claim" (username + raw password). After verification it's a "proof" (user details + authorities). Same type, two stages of life.

## 2. Who calls the provider: the `ProviderManager`

You never call a provider yourself. A manager, `ProviderManager` (the standard `AuthenticationManager`), holds a list of providers and loops through them:

```
Login attempt arrives at ProviderManager
   │
   ▼
Provider 1 ── supports() this token type?
   │              no ──► skip to next provider
   │              yes ──► authenticate()
   │                         │
   │            returns Authentication ──► DONE, login succeeds
   │            throws exception ────────► remember it, try next provider
   │            returns null ────────────► "not for me," try next provider
   ▼
Provider 2 ... and so on
   │
   ▼
Nobody succeeded ──► throws the last exception ──► login fails
```

Think of a panel of examiners. The manager shows the candidate to each examiner in turn. An examiner who doesn't handle that kind of exam skips it. The first one who says "verified" ends the process.

This design is why you can mix login methods in one app: a form login with password, an API key for scripts, and a token for mobile apps, each with its own provider.

## 3. Providers that come built in

|Provider|Verifies|Typical use|
|---|---|---|
|`DaoAuthenticationProvider`|Username + password using a `UserDetailsService` and `PasswordEncoder`|Standard database login|
|`JwtAuthenticationProvider`|A JWT bearer token (resource server)|Token-protected APIs|
|`LdapAuthenticationProvider`|Credentials against an LDAP directory|Company directory login|
|`RememberMeAuthenticationProvider`|A "remember me" cookie|Staying logged in|

For most database-backed apps, `DaoAuthenticationProvider` is all you need and you never write a provider.

## 4. Writing your own: username and password with extra control

Here's a provider that does what `DaoAuthenticationProvider` does, but written out so you can see every step.

```java
@Component
public class AppAuthenticationProvider implements AuthenticationProvider {

    private final UserDetailsService userDetailsService;
    private final PasswordEncoder passwordEncoder;

    public AppAuthenticationProvider(UserDetailsService userDetailsService,
                                     PasswordEncoder passwordEncoder) {
        this.userDetailsService = userDetailsService;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public Authentication authenticate(Authentication authentication) {
        String username = authentication.getName();
        String rawPassword = authentication.getCredentials().toString();

        UserDetails user;
        try {
            user = userDetailsService.loadUserByUsername(username);
        } catch (UsernameNotFoundException e) {
            throw new BadCredentialsException("Bad credentials");
        }

        if (!passwordEncoder.matches(rawPassword, user.getPassword())) {
            throw new BadCredentialsException("Bad credentials");
        }
        if (!user.isEnabled()) {
            throw new DisabledException("Account is disabled");
        }

        return UsernamePasswordAuthenticationToken.authenticated(
                user, null, user.getAuthorities());
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

Line by line:

- The two constructor arguments are the tools it needs: one to find the user, one to check the password. Spring injects both.
- `authentication.getName()` returns the username the person typed.
- `authentication.getCredentials()` returns the raw password they typed. Credentials is Spring Security's general word for "the secret part."
- The `try/catch` converts "no such user" into the same `BadCredentialsException` as "wrong password." This keeps the error message identical, so an attacker can't tell which usernames exist.
- `passwordEncoder.matches(raw, hash)` hashes the typed password and compares it to the stored hash. This is the safe way to check a password.
- The `isEnabled()` check blocks disabled accounts even when the password is right.
- `UsernamePasswordAuthenticationToken.authenticated(user, null, authorities)` builds the _verified_ result. The principal is the user, the credentials are set to `null` (you don't keep the raw password around after checking), and the authorities come from your `getAuthorities()` method.
- `supports(...)` says "I only handle username-and-password tokens." The `isAssignableFrom` check also accepts subclasses.

## 5. Why `supports()` matters

`supports()` is the examiner's "is this my exam?" check. Without it, a password provider would try to verify an API-key attempt and crash on a missing password.

|Login attempt type|Password provider's `supports()`|API-key provider's `supports()`|
|---|---|---|
|`UsernamePasswordAuthenticationToken`|true|false|
|`ApiKeyAuthenticationToken`|false|true|

The manager asks `supports()` first and only calls `authenticate()` on a "yes."

## 6. What to return and what to throw

|Situation|What your `authenticate()` does|
|---|---|
|Credentials valid|Return a fully authenticated `Authentication`|
|Credentials invalid|Throw an `AuthenticationException` subclass (`BadCredentialsException`, `DisabledException`, `LockedException`...)|
|You can't decide, "not mine"|Return `null`, and the manager tries the next provider|

Two rules of thumb: never return an `Authentication` you haven't verified, and prefer throwing a specific exception for a clear failure.

## 7. Registering it

If your provider is a Spring bean (`@Component`, as above), Spring Boot picks it up. You can also be explicit in the filter chain configuration:

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http,
                                       AppAuthenticationProvider provider) throws Exception {
    http
        .authenticationProvider(provider)
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

A word of caution: once you define your own provider, it usually _replaces_ the automatic `DaoAuthenticationProvider` that Boot would have built from your `UserDetailsService`. Your provider becomes responsible for the whole check.

## 8. A second example: an API key provider

This shows why custom providers exist at all. Imagine scripts calling your API with a header `X-API-KEY`. There's no username or password, so `DaoAuthenticationProvider` can't help.

First, a token class for this kind of attempt:

```java
public class ApiKeyAuthenticationToken extends AbstractAuthenticationToken {

    private final String apiKey;
    private final Object principal;

    // unverified: only the key is known
    public ApiKeyAuthenticationToken(String apiKey) {
        super(null);
        this.apiKey = apiKey;
        this.principal = null;
        setAuthenticated(false);
    }

    // verified: key checked, we know who it belongs to
    public ApiKeyAuthenticationToken(Object principal, Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.apiKey = null;
        this.principal = principal;
        setAuthenticated(true);
    }

    @Override public Object getCredentials() { return apiKey; }
    @Override public Object getPrincipal()   { return principal; }
}
```

Then its provider:

```java
@Component
public class ApiKeyAuthenticationProvider implements AuthenticationProvider {

    private final ApiKeyRepository keys;

    public ApiKeyAuthenticationProvider(ApiKeyRepository keys) { this.keys = keys; }

    @Override
    public Authentication authenticate(Authentication authentication) {
        String key = (String) authentication.getCredentials();
        ApiClient client = keys.findByKeyHash(hash(key))
                .orElseThrow(() -> new BadCredentialsException("Invalid API key"));
        return new ApiKeyAuthenticationToken(client.getName(),
                List.of(new SimpleGrantedAuthority("ROLE_SERVICE")));
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return ApiKeyAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

Walkthrough:

- The token class has two constructors on purpose: one for "unverified claim," one for "verified proof." The `setAuthenticated` flag tells the two stages apart.
- The provider looks up the key by its hash. You store hashes of API keys, never the raw keys, for the same reason you store password hashes.
- `supports()` only accepts `ApiKeyAuthenticationToken`, so password logins never reach this provider.
- A small filter (not shown) reads the `X-API-KEY` header, creates the unverified token, and hands it to the `AuthenticationManager`. That filter is the "delivery" part of the flow.

## 9. Do you need a custom provider?

|Your situation|What to write|
|---|---|
|Users in your database, normal password login|Just a `UserDetailsService`|
|Same, but with extra rules (IP check, tenant check, two-factor code)|A custom `AuthenticationProvider`|
|Non-password credentials (API key, one-time code, external system)|A custom `AuthenticationProvider` plus its own token class|
|JWT-protected API|The built-in JWT support, often no custom provider|

## 10. Related concepts, in short

- **`AuthenticationManager`**: the one-method interface (`authenticate`) that the rest of the app calls. `ProviderManager` is its standard implementation, and it's the one holding the list of providers.
- **`Authentication`**: the object that carries "who" through the system. Before checking it holds the claim, after checking it holds the proof (principal, credentials, authorities, and an `authenticated` flag).
- **`UserDetailsService`**: a helper that _loads_ a user. A provider uses it, but the provider is the one that decides yes or no.
- **Authentication filter**: the entry point that grabs the raw request (form fields, header, token) and builds the first unverified `Authentication` to send to the manager.





[[Spring Security]]