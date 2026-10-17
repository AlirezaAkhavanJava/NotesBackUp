
### What is `DaoAuthenticationProvider` in Spring Security?

`DaoAuthenticationProvider` is the **most commonly used** `AuthenticationProvider` in Spring Security.  
"DAO" stands for **Data Access Object** — it authenticates users by loading user details from a **UserDetailsService** (your "DAO") and comparing the presented password against the stored (encoded) one using a `PasswordEncoder`.

It’s perfect for classic username/password authentication where users are stored in a database, in-memory, LDAP (via a custom service), etc.

### How DaoAuthenticationProvider Works (Flow)

1. User submits username + password → creates a `UsernamePasswordAuthenticationToken` (unauthenticated).
2. `ProviderManager` asks all registered providers → `DaoAuthenticationProvider.supports(...)` returns `true` for `UsernamePasswordAuthenticationToken`.
3. `DaoAuthenticationProvider.authenticate(...)` is called:
   - Calls `UserDetailsService.loadUserByUsername(username)`
   - Checks if user exists and is enabled/credentials non-expired, etc.
   - Uses `PasswordEncoder.matches(rawPassword, storedEncodedPassword)`
   - If everything matches → returns a new fully authenticated `UsernamePasswordAuthenticationToken` with authorities.
   - Else → throws `BadCredentialsException`, `DisabledException`, etc.

### Minimal Working Configuration (Spring Security 6+, Spring Boot 3+)

#### 1. UserDetailsService (e.g., JPA-based)

```java
@Service
public class JpaUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public JpaUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        return new org.springframework.security.core.userdetails.User(
                user.getUsername(),
                user.getPassword(),                     // must be BCrypt-encoded
                user.isEnabled(),
                true, true, true,                       // account non-expired, credentials non-expired, account non-locked
                AuthorityUtils.createAuthorityList("ROLE_USER")  // or map from user.getRoles()
        );
    }
}
```

#### 2. PasswordEncoder Bean

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();  // or Argon2, SCrypt, etc.
}
```

#### 3. DaoAuthenticationProvider Bean (Optional but recommended for extra options)

```java
@Bean
public DaoAuthenticationProvider daoAuthenticationProvider(
        UserDetailsService userDetailsService,
        PasswordEncoder passwordEncoder) {

    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(userDetailsService);
    provider.setPasswordEncoder(passwordEncoder);

    // Optional but useful
    provider.setHideUserNotFoundException(false); // helps debugging (default is true)
    // provider.setPreAuthenticationChecks(...);   // custom checks
    // provider.setPostAuthenticationChecks(...);

    return provider;
}
```

#### 4. SecurityFilterChain (Spring Security 6+)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final DaoAuthenticationProvider daoAuthenticationProvider;

    public SecurityConfig(DaoAuthenticationProvider daoAuthenticationProvider) {
        this.daoAuthenticationProvider = daoAuthenticationProvider;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .permitAll()
            )
            .logout(logout -> logout.logoutSuccessUrl("/"))
            .authenticationProvider(daoAuthenticationProvider); // important!

        return http.build();
    }
}
```

**Note:** In modern Spring Boot, if you have exactly one `AuthenticationProvider` bean and one `UserDetailsService` bean, Spring Boot will auto-configure a `DaoAuthenticationProvider` for you — you often don’t even need to create it manually.

### Quick In-Memory Example (for testing)

```java
@Bean
public UserDetailsService inMemoryUsers(PasswordEncoder encoder) {
    UserDetails user = User.withUsername("user")
            .password(encoder.encode("password"))
            .roles("USER")
            .build();

    UserDetails admin = User.withUsername("admin")
            .password(encoder.encode("admin"))
            .roles("ADMIN")
            .build();

    return new InMemoryUserDetailsManager(user, admin);
}
```

That’s it — Spring Boot auto-creates the `DaoAuthenticationProvider` behind the scenes.

### When to Create Your Own DaoAuthenticationProvider Bean?

You usually do it when you want to:
- Hide `UserNotFoundException` (default behavior for security)
- Add extra checks (e.g., OTP validation)
- Use a custom `UserDetailsPasswordService` for automatic password rehashing
- Set a custom `UserCache` (e.g., Caffeine cache)

### Common Pitfalls

| Issue                                 | Fix                                                                 |
|---------------------------------------|---------------------------------------------------------------------|
| `BadCredentialsException` always     | Make sure stored password is encoded with the same `PasswordEncoder` |
| `UserNotFoundException` thrown        | By default hidden → becomes `BadCredentialsException`. Set `setHideUserNotFoundException(false)` for debugging |
| No authorities loaded                 | Return proper `GrantedAuthority` list in `UserDetails`              |
| Multiple providers cause ambiguity    | Register them in the order you want them tried                     |

### TL;DR

- Use `DaoAuthenticationProvider` 99% of the time for username/password auth.
- Just provide a `UserDetailsService` + `PasswordEncoder` → Spring Boot wires it automatically.
- Create the provider bean manually only if you need custom behavior.


##### Tags : [[1 - Spring Security 🍌]]