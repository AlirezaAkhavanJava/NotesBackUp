
### Spring Security – UserDetails and UserDetailsService Explained (2025 Update)

In Spring Security, authentication is built around the **`UserDetails`** interface and the **`UserDetailsService`** interface. They are the cornerstone of how Spring Security represents a user and loads user data from anywhere (database, LDAP, JWT, etc.).

#### 1. The `UserDetails` interface

```java
public interface UserDetails extends Serializable {
    Collection<? extends GrantedAuthority> getAuthorities(); // roles/permissions
    String getPassword();
    String getUsername();
    boolean isAccountNonExpired();
    boolean isAccountNonLocked();
    boolean isCredentialsNonExpired();
    boolean isEnabled();
}
```

Spring Security provides a convenient implementation: **`org.springframework.security.core.userdetails.User`**

```java
UserDetails user = User.withUsername("john")
    .password(passwordEncoder.encode("secret"))
    .roles("USER", "ADMIN")           // becomes ROLE_USER, ROLE_ADMIN
    .authorities("READ", "WRITE")     // custom authorities
    .disabled(false)
    .accountExpired(false)
    .credentialsExpired(false)
    .accountLocked(false)
    .build();
```

#### 2. The `UserDetailsService` interface

```java
public interface UserDetailsService {
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

You usually implement this yourself when you store users in a database.

#### 3. Complete Modern Example (Spring Boot 3.x + Spring Security 6.x)

```java
// Entity
@Entity
@Table(name = "users")
public class AppUser {
    @Id @GeneratedValue
    private Long id;
    private String username;
    private String password;
    private String roles;           // e.g. "USER,ADMIN" or store in separate table
    private boolean enabled = true;
    // getters/setters
}

// Repository
@Repository
public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}

// Custom UserDetails implementation (optional but recommended)
public class AppUserDetails implements UserDetails {
    private final AppUser appUser;

    public AppUserDetails(AppUser appUser) {
        this.appUser = appUser;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Arrays.stream(appUser.getRoles().split(","))
                     .map(role -> new SimpleGrantedAuthority("ROLE_" + role.trim()))
                     .collect(Collectors.toList());
    }

    @Override public String getPassword() { return appUser.getPassword(); }
    @Override public String getUsername() { return appUser.getUsername(); }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return appUser.isEnabled(); }
}

// UserDetailsService implementation
@Service
@RequiredArgsConstructor
public class JpaUserDetailsService implements UserDetailsService {

    private final AppUserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser appUser = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        
        return new AppUserDetails(appUser);
    }
}
```

#### 4. Security Configuration (Spring Boot 3.x style – no WebSecurityConfigurerAdapter)

```java
@Configuration
@EnableMethodSecurity   // if you want @PreAuthorize etc.
@RequiredArgsConstructor
public class SecurityConfig {

    private final JpaUserDetailsService userDetailsService;
    private final PasswordEncoder passwordEncoder;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())  // adjust as needed
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .permitAll()
            )
            .logout(logout -> logout.permitAll());

        return http.build();
    }

    // Tell Spring to use our UserDetailsService
    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder);
        return provider;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

#### 5. Quick In-Memory Version (for testing)

```java
@Bean
public UserDetailsService inMemoryUserDetailsService(PasswordEncoder encoder) {
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

#### Key Points (2025)

- `WebSecurityConfigurerAdapter` is removed since Spring Security 5.7+. Use the new `SecurityFilterChain` bean approach.
- Prefer `UserDetailsService` + `DaoAuthenticationProvider` over the old `UserDetailsManager` for JPA scenarios.
- Always encode passwords with `PasswordEncoder` (never store plain text).
- Use `@EnableMethodSecurity` if you want method-level security (`@PreAuthorize("hasRole('ADMIN')")`).

That’s the complete, up-to-date way to work with `UserDetails` and `UserDetailsService` in modern Spring Security (Spring Boot 3.x / Spring Security 6.x). Let me know if you need JWT, OAuth2, or custom authentication provider examples next!

##### Tags : [[1 - Spring Security 🍌]]