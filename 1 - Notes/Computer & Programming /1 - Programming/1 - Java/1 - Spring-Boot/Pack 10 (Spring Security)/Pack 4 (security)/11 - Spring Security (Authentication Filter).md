![[6a951148-8a50-4482-9587-fa937ff85752.png]]


# Understanding Spring Security Authentication Flow

## First, what is "authentication"?

**Authentication** is the process of verifying _who_ a request comes from. Given a username and password, the system checks whether they are correct and, if so, establishes an identity for the rest of the request.

It is different from **authorization**, which asks _what_ that identity is allowed to do. This diagram covers authentication only. Authorization comes later in the chain.

Without a framework, every web app would have to write this logic itself: parse credentials, look up users, compare hashed passwords, and remember who is logged in. Spring Security packages all of that into a pipeline of cooperating components. The diagram shows that pipeline.

## The big picture

Spring Security works by placing a **chain of filters** in front of your controllers. Every incoming HTTP request passes through these filters before reaching your code. One of them is the **authentication filter**, which tries to log the user in. If it fails, the request never reaches your controller.

Your controller stays clean. It only runs when the request is already known to be authenticated.

## The cast of characters

Each box in the diagram is a Java interface or class with a single responsibility. Here they are one at a time.

### 1. Filter Chain

**Definition:** An ordered list of servlet filters that every HTTP request passes through.

**Why it exists:** Servlet filters are the standard Java EE mechanism for intercepting requests before they reach a servlet. Spring Security uses this to guard the entire application at the edge, not inside each controller.

**Problem it solves:** Without a central gate, you would have to remember to check authentication in every endpoint. Forgetting one would leave a hole.

**How it works:** The filters run in order. Each one either passes the request along or stops it. In the diagram, Filter 1, Filter 2, and so on are security concerns such as CSRF protection, session handling, and headers. The Authentication Filter is one of them.

**How you'll use it:** You rarely write filters yourself. You configure which requests need authentication, and Spring builds the chain.

### 2. Authentication Filter

**Definition:** A filter that extracts credentials from the request and triggers authentication. For form logins, this is `UsernamePasswordAuthenticationFilter`.

**Why it exists:** Credentials can arrive in different forms, such as a form POST, an HTTP Basic header, or a JWT. The filter's job is to read them from the request and hand them off.

**How it works:** It reads the username and password from the request, wraps them in an `Authentication` object with `authenticated = false`, and passes that object to the Authentication Manager.

### 3. Authentication Manager

**Definition:** An interface with one method, `authenticate(Authentication)`. The default implementation is `ProviderManager`.

**Why it exists:** Your application might authenticate users in several ways: passwords in a database, LDAP, OAuth, or a one-time code. The manager doesn't know how to check any of them. It only knows how to ask the right provider.

**How it works:** `ProviderManager` holds a list of `AuthenticationProvider` objects and asks each one, in turn, whether it supports this type of `Authentication`. The first one that supports it attempts the check.

**Why this design matters:** The entry point stays the same no matter how many authentication methods you add. The filter always calls `authenticate()`, and the manager routes the request.

### 4. Authentication Provider

**Definition:** A component that performs one kind of authentication. The most common is `DaoAuthenticationProvider`, which checks a username and password against a user store.

**Why it exists:** Separating "how to authenticate" from "who calls authentication" lets you swap or combine strategies without rewriting the filter.

**How it works:** `DaoAuthenticationProvider` does three things. It asks the `UserDetailsService` for the user (step 6). It asks the `PasswordEncoder` to compare passwords (step 5). If both succeed, it returns a fully authenticated `Authentication` object containing the user's roles.

### 5. Password Encoder

**Definition:** An interface with `encode(raw)` and `matches(raw, encoded)`. The standard implementation is `BCryptPasswordEncoder`.

**Why it exists:** You must never store passwords in plain text. If your database leaks, plain passwords expose every user. A password encoder stores a one-way hash instead.

**Problem it solves:** Hashes can't be reversed, but you can still verify a password. When a user logs in, the encoder hashes what they typed and compares it with the stored hash.

**Why BCrypt specifically:** BCrypt is deliberately slow and includes a random salt. This makes brute-force attacks expensive. Fast hashes like MD5 or SHA-256 are the wrong choice for passwords.

### 6. UserDetailsService

**Definition:** An interface with one method, `loadUserByUsername(String username)`, which returns a `UserDetails` object.

**Why it exists:** Spring Security doesn't know where your users live. They might be in PostgreSQL, MongoDB, or a text file. This interface is the bridge: you implement it, and Spring calls it.

**How it works:** Given a username, it returns the stored user's password hash, roles, and account status (enabled, locked, expired). It does not check the password. That is the provider's job.

### 7 and 8. DB and User Details

Steps 7 and 8 are the database query and the result. Your `UserDetailsService` queries the database by username (step 7) and returns the user record (step 8). This record includes the stored password hash. Spring then compares that hash with the submitted password.

### 9. Authentication Result

**Definition:** The outcome of the authentication attempt, returned back up the chain as an `Authentication` object.

**How it works:** On success, the returned `Authentication` has `authenticated = true`, the principal (the user), and the granted authorities (roles). On failure, Spring throws an exception such as `BadCredentialsException`, which becomes a 401 or a redirect to the login page.

### 10. Response

If authentication succeeded, the request continues down the chain to your controller. If it failed, the chain stops and the client receives an error response.

### Security Context

**Definition:** A holder, stored per thread or per request, that contains the currently authenticated `Authentication` object.

**Why it exists:** After authentication, every later part of the request needs to know who the user is: controllers, service methods, and authorization checks. Passing the user through every method signature would be tedious and error-prone.

**How it works:** Step 2 in the diagram stores the successful result here. Later code calls `SecurityContextHolder.getContext().getAuthentication()` to read it.

**How you'll use it:** Controllers can receive the current user directly:

```java
@GetMapping("/me")
public String whoAmI(Authentication authentication) {
    return authentication.getName();
}
```

## The journey of one login, step by step

Imagine a `POST /login` request with `username=alice` and `password=secret123`.

1. The request enters the filter chain.
2. `UsernamePasswordAuthenticationFilter` reads `alice` and `secret123` from the form and creates an unauthenticated `Authentication` object.
3. The filter calls `authenticationManager.authenticate(...)`.
4. `ProviderManager` finds `DaoAuthenticationProvider`, which supports username and password, and delegates to it.
5. The provider asks the `PasswordEncoder` to check `secret123` against the stored hash.
6. The provider asks `UserDetailsService.loadUserByUsername("alice")` for the user.
7. The service runs a database query for `alice`.
8. The database returns Alice's record, including her hash and roles.
9. The provider confirms the password matches and returns an authenticated `Authentication` object. If the password didn't match, it would throw an exception and the flow would stop here.
10. The filter stores the authentication in the Security Context and lets the request continue to your controller, which returns the response.

## Configuring it in Spring Boot

Here is a minimal, working setup that shows where each diagram component comes from. This uses Spring Boot 3 and Spring Security 6 style, where the chain is configured with a `SecurityFilterChain` bean.

### The password encoder

```java
@Configuration
public class PasswordConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

Spring registers this bean. `DaoAuthenticationProvider` finds it and uses it automatically in step 5.

### The user loader

Suppose you have a JPA entity `AppUser` and a repository for it:

```java
@Service
public class AppUserDetailsService implements UserDetailsService {

    private final AppUserRepository repository;

    public AppUserDetailsService(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser user = repository.findByUsername(username)           // step 7: DB query
                .orElseThrow(() -> new UsernameNotFoundException("No user: " + username));

        return User.withUsername(user.getUsername())                 // step 8: returned details
                .password(user.getPasswordHash())                    // stored hash, not plain text
                .roles(user.getRole())                               // e.g. "USER" or "ADMIN"
                .build();
    }
}
```

What this does: Spring calls `loadUserByUsername`. Your code fetches the user from the database and converts it into a `UserDetails` object. Notice that you return the stored hash. You never compare passwords yourself.

### The filter chain

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/login", "/register").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .formLogin(Customizer.withDefaults());

        return http.build();
    }
}
```

What this does: `formLogin` installs `UsernamePasswordAuthenticationFilter` into the chain (step 2). `authorizeHttpRequests` decides which URLs need authentication. Spring wires the rest automatically: the manager, the provider, the encoder, and your user service.

Notice that you never mention the Authentication Manager or the Provider explicitly. Spring Boot creates them from the beans you registered. That is why understanding the diagram matters: when something breaks, you need to know which bean to inspect.

## Things that commonly go wrong

**Storing plain-text passwords.** If you save `"secret123"` directly, `BCryptPasswordEncoder.matches()` will always fail. Always hash with `passwordEncoder.encode(...)` when you create or update a user.

**Forgetting the `{bcrypt}` prefix when using `User.withDefaultPasswordEncoder()`.** That helper is deprecated and only for demos. In real code, use a proper `PasswordEncoder` bean.

**Expecting `UserDetailsService` to check the password.** It doesn't. It only loads the user. The provider performs the comparison.

**Calling the Authentication Manager from a controller without understanding the flow.** You can do this for custom login APIs, but for most apps the filter does it for you.




[[Spring Security]]