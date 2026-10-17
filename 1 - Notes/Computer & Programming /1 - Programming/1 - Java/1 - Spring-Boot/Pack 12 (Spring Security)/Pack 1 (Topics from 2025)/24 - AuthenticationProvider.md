
### What is `AuthenticationProvider` in Spring Security?

The `AuthenticationProvider` interface is a core component of Spring Security's authentication architecture. It is responsible for performing a **specific type** of authentication (e.g., username/password against a database, LDAP, external API, OTP, etc.).

- The main `AuthenticationManager` (usually a `ProviderManager`) delegates incoming `Authentication` requests (typically a `UsernamePasswordAuthenticationToken`) to a list of registered `AuthenticationProvider` instances.
- Each provider checks if it **supports** the incoming authentication type.
- If it does, it attempts to authenticate. On success, it returns a fully populated `Authentication` object (authenticated = true). On failure, it throws an `AuthenticationException` or returns `null` (to let the next provider try).
- This design allows multiple authentication mechanisms in the same application (e.g., form login + API key + LDAP).

Common built-in providers:
- `DaoAuthenticationProvider` → Username/password with a `UserDetailsService` and `PasswordEncoder`.
- `LdapAuthenticationProvider` → LDAP servers.
- `RememberMeAuthenticationProvider` → "Remember me" cookie.

### The `AuthenticationProvider` Interface

```java
public interface AuthenticationProvider {
    Authentication authenticate(Authentication authentication)
            throws AuthenticationException;

    boolean supports(Class<?> authentication);
}
```

- `authenticate(...)`: Contains your custom logic. Extract credentials, validate them, load authorities, and return a new authenticated `Authentication` (usually `UsernamePasswordAuthenticationToken`).
- `supports(...)`: Return `true` if this provider can handle the given `Authentication` subclass (e.g., `UsernamePasswordAuthenticationToken.class`).

### When to Use a Custom `AuthenticationProvider`?

Use it when the default `DaoAuthenticationProvider` + `UserDetailsService` is not enough, such as:
- Authenticating against an external/third-party service (e.g., Crowd, OAuth2 resource server, custom API).
- Adding extra checks (e.g., OTP, CAPTCHA, account status from another source).
- Non-standard credential formats.

### Example: Simple Custom AuthenticationProvider (Spring Security 6+)

```java
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class CustomAuthenticationProvider implements AuthenticationProvider {

    @Override
    public Authentication authenticate(Authentication auth) throws AuthenticationException {
        String username = auth.getName();
        String password = auth.getCredentials().toString();

        // Your custom logic here (e.g., call external API, check DB, etc.)
        if ("admin".equals(username) && "secret".equals(password)) {
            List<GrantedAuthority> authorities = List.of(new SimpleGrantedAuthority("ROLE_ADMIN"));

            // Return authenticated token (credentials can be nulled for security)
            return new UsernamePasswordAuthenticationToken(username, null, authorities);
        }

        // Fail → throw exception or return null to try next provider
        throw new AuthenticationCredentialsNotFoundException("Invalid credentials");
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

### Registering the Provider in Spring Security 6+ (Lambda DSL)

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    private final CustomAuthenticationProvider customAuthProvider;

    public SecurityConfig(CustomAuthenticationProvider customAuthProvider) {
        this.customAuthProvider = customAuthProvider;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .anyRequest().authenticated()
            )
            .formLogin(Customizer.withDefaults())  // or httpBasic, etc.
            .authenticationProvider(customAuthProvider);  // <-- Register here

        return http.build();
    }
}
```

- If you have **exactly one** `AuthenticationProvider` bean, Spring Security may auto-configure it (but it's safer to register explicitly with `.authenticationProvider()`).
- You can register multiple providers; they will be tried in order.

### More Realistic Example: Delegating to a Third-Party Service

```java
@Override
public Authentication authenticate(Authentication auth) throws AuthenticationException {
    String username = auth.getName();
    String password = auth.getCredentials().toString();

    // Example: Call external REST API
    boolean valid = externalService.validate(username, password);

    if (valid) {
        List<GrantedAuthority> authorities = externalService.getRoles(username);
        return new UsernamePasswordAuthenticationToken(username, null, authorities);
    }
    throw new BadCredentialsException("External system authentication failed");
}
```

### Key Tips for Spring Security 6+

- Use the new lambda-based DSL (no `WebSecurityConfigurerAdapter` – deprecated since 5.7, removed in 6+).
- Always encode passwords with `PasswordEncoder` if you handle them yourself.
- After successful authentication, erase credentials (`new UsernamePasswordAuthenticationToken(principal, null, authorities)`).
- For DAO-style auth, it's often simpler to just customize `UserDetailsService` + use `DaoAuthenticationProvider` instead of a full custom provider.



##### Tags : [[1 - Spring Security 🍌]]