


Spring Security locks down your app by default once it's on the classpath. Making it _usable_ means giving it three things: 
- a way to represent a user it understands, 
- a way to fetch that user
- a config that wires an `AuthenticationProvider` and a `SecurityFilterChain` together.  Everything below builds toward that.

![[f084035a-a191-41d4-95a7-0566a6e049de.png]]

**1. Add the dependency**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

As soon as this is on the classpath, every endpoint is locked and a default login page appears — that's your signal it's active.

**2. The entity your users are stored as**

```java
@Entity
@Table(name = "users")
public class AppUser {
    @Id @GeneratedValue
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(nullable = false)
    private String password; // always stored encoded, never raw

    private boolean enabled = true;

    private String roles; // e.g. "ROLE_USER,ROLE_ADMIN"

    // getters/setters
}
```

Just a plain JPA entity — nothing Spring-Security-specific yet.

**3. The repository to fetch it**

```java
public interface UserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}
```

**4. `AppUserDetails` — the adapter Spring Security actually needs**  
Spring Security only knows how to work with the `UserDetails` interface, not your `AppUser`. This class makes `AppUser` look like a `UserDetails` without changing `AppUser` itself:

```java
public class AppUserDetails implements UserDetails {
    private final AppUser user;

    public AppUserDetails(AppUser user) {
        this.user = user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Arrays.stream(user.getRoles().split(","))
            .map(String::trim)
            .filter(s -> !s.isEmpty())
            .map(SimpleGrantedAuthority::new)
            .toList();
    }

    @Override public String getPassword() { return user.getPassword(); }
    @Override public String getUsername() { return user.getUsername(); }
    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return user.isEnabled(); }
}
```

The five boolean methods are account-state flags Spring Security checks before allowing login — expired account, locked account, expired credentials, disabled account. Return `true` for all of them unless your app actually implements that kind of restriction. `getAuthorities()` is the one real piece of logic: it turns your comma-separated `roles` string into the `GrantedAuthority` objects `hasRole()`/`hasAuthority()` will check later.

**5. The service that loads a user by username**

```java
@Service
public class CustomUserDetailsService implements UserDetailsService {
    private final UserRepository repo;
    public CustomUserDetailsService(UserRepository repo) { this.repo = repo; }

    @Override
    public UserDetails loadUserByUsername(String username) {
        return repo.findByUsername(username)
            .map(AppUserDetails::new)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }
}
```

This is the glue: repository fetches the raw `AppUser`, `AppUserDetails` wraps it, and this method hands the wrapped object back to Spring Security.

**6. The config beans**

```java
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider authProvider(
	    UserDetailsService uds, 
	    PasswordEncoder pe
	    ) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(uds);
        provider.setPasswordEncoder(pe);
        return provider;
    }

    @Bean
    public SecurityFilterChain filterChain(
		    HttpSecurity http, 
		    DaoAuthenticationProvider provider
	    ) throws Exception {
        http.authenticationProvider(provider)
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/auth/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .formLogin(Customizer.withDefaults());
        return http.build();
    }
}
```

`DaoAuthenticationProvider` is where everything meets: it calls `CustomUserDetailsService` to get the `AppUserDetails`, then uses `PasswordEncoder` to check the submitted password against the stored hash.

**7. Save a user with an encoded password**

```java
AppUser user = new AppUser();
user.setUsername("alice");
user.setPassword(passwordEncoder.encode("rawPassword"));
user.setRoles("ROLE_USER");
repo.save(user);
```

Never store or compare raw passwords — always through `PasswordEncoder`.

**End state**: unauthenticated requests to protected paths get redirected to a login form, successful login runs through `AppUserDetails` and `DaoAuthenticationProvider`, and `SecurityContextHolder` ends up holding an authenticated principal that `.hasRole("ADMIN")` or `@PreAuthorize` can check. JWT, custom providers, and multiple filter chains are all additions layered on top of this same base, not replacements for it.



[[Spring Security]]