

## What is UserDetailsService?

Think of `UserDetailsService` as a **"bridge"** between your application's user data and Spring Security. It's like a translator that tells Spring Security:

- **WHERE** to find user information (database, file, external service)
- **HOW** to convert your user data into a format Spring Security understands

## Simple Analogy

Imagine a security guard (Spring Security) who needs to check IDs. The `UserDetailsService` is like the company's HR system that provides employee information to the security guard.

## Core Interface

```java
public interface UserDetailsService {
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

It has only **ONE method** - that's it!

---

## Example 1: In-Memory User (Simple Example)

### Configuration Class
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public UserDetailsService userDetailsService() {
        // Create users with username, password, and roles
        UserDetails user = User.builder()
            .username("john")
            .password("{noop}password123") // {noop} means no encoding
            .roles("USER")
            .build();

        UserDetails admin = User.builder()
            .username("admin")
            .password("{noop}admin123")
            .roles("ADMIN", "USER")
            .build();

        // Store users in memory
        return new InMemoryUserDetailsManager(user, admin);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }
}
```

### What's happening here?
- **`InMemoryUserDetailsManager`**: Stores users in application memory (good for testing)
- **`User.builder()`**: Creates user objects with username, password, roles
- **`{noop}`**: Temporary way to store passwords without encryption (NOT for production!)

---

## Example 2: Database Users (Production Ready)

### 1. User Entity (Your Database Table)
```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true, nullable = false)
    private String username;
    
    @Column(nullable = false)
    private String password;
    
    private boolean enabled;
    
    // Getters and setters
}
```

### 2. Role Entity
```java
@Entity
@Table(name = "roles")
public class Role {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    
    // Getters and setters
}
```

### 3. Custom UserDetailsService Implementation
```java
@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) 
		    throws UsernameNotFoundException {
        
        // 1. Find user in database
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        // 2. Convert our User to Spring Security's UserDetails
        return org.springframework.security.core.userdetails.User.builder()
            .username(user.getUsername())
            .password(user.getPassword())
            .disabled(!user.isEnabled())
            .accountExpired(false)
            .accountLocked(false)
            .credentialsExpired(false)
            .roles(getRolesAsArray(user.getRoles())) // Convert roles to array
            .build();
    }

    private String[] getRolesAsArray(Set<Role> roles) {
        return roles.stream()
            .map(Role::getName)
            .toArray(String[]::new);
    }
}
```

### 4. Repository Interface
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
}
```

### 5. Security Configuration
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/user/**").hasRole("USER")
                .requestMatchers("/", "/login", "/register").permitAll()
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .defaultSuccessUrl("/dashboard")
                .permitAll()
            )
            .logout(logout -> logout
                .logoutSuccessUrl("/login?logout")
                .permitAll()
            );

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(); // Secure password encoding
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }
}
```

---

## Example 3: Advanced Production Example with Additional Features

### Custom UserDetails Implementation
```java
public class CustomUserDetails implements UserDetails {
    private String username;
    private String password;
    private boolean enabled;
    private List<GrantedAuthority> authorities;
    private String email;
    private String firstName;
    private String lastName;

    // Constructor
    public CustomUserDetails(User user) {
        this.username = user.getUsername();
        this.password = user.getPassword();
        this.enabled = user.isEnabled();
        this.email = user.getEmail();
        this.firstName = user.getFirstName();
        this.lastName = user.getLastName();
        this.authorities = user.getRoles().stream()
            .map(role -> new SimpleGrantedAuthority("ROLE_" + role.getName()))
            .collect(Collectors.toList());
    }

    // Getters for custom fields
    public String getEmail() { return email; }
    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }

    // Required UserDetails methods
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() { return password; }

    @Override
    public String getUsername() { return username; }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return enabled; }
}
```

### Enhanced UserDetailsService
```java
@Service
@Transactional
public class EnhancedUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        
        // Log authentication attempts
        System.out.println("Authentication attempt for user: " + username);
        
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> {
                // Log failed attempts
                System.out.println("Failed authentication for user: " + username);
                return new UsernameNotFoundException("User not found: " + username);
            });

        // Check if account is locked, expired, etc.
        if (!user.isEnabled()) {
            throw new UsernameNotFoundException("User account is disabled: " + username);
        }

        return new CustomUserDetails(user);
    }
}
```

---

## Key Classes Explained

### 1. **UserDetailsService Interface**
- **Purpose**: Main contract for loading user-specific data
- **Key Method**: `loadUserByUsername(String username)`
- **Returns**: `UserDetails` object

### 2. **UserDetails Interface**
- **Purpose**: Represents user information that Spring Security needs
- **Contains**: username, password, roles, account status flags

### 3. **User (Spring Security's implementation)**
- **Purpose**: Ready-to-use implementation of UserDetails
- **Usage**: `User.builder().username().password().roles().build()`

### 4. **GrantedAuthority**
- **Purpose**: Represents roles/permissions (like "ROLE_ADMIN", "ROLE_USER")

### 5. **PasswordEncoder**
- **Purpose**: Encodes and verifies passwords securely
- **Common implementations**: BCryptPasswordEncoder, Pbkdf2PasswordEncoder

### 6. **AuthenticationProvider**
- **Purpose**: Processes authentication requests
- **Common implementation**: DaoAuthenticationProvider (uses UserDetailsService)

---

## Production Best Practices

### 1. **Always use proper password encoding**
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(); // Recommended for production
}
```

### 2. **Handle user not found gracefully**
```java
@Override
public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
    User user = userRepository.findByUsername(username)
        .orElseThrow(() -> new UsernameNotFoundException("Invalid username or password"));
    // Don't reveal that user doesn't exist
}
```

### 3. **Implement account status checks**
```java
if (!user.isEnabled()) {
    throw new DisabledException("Account is disabled");
}
if (user.isLocked()) {
    throw new LockedException("Account is locked");
}
```

### 4. **Use transactions in service layer**
```java
@Service
@Transactional
public class CustomUserDetailsService implements UserDetailsService {
    // Your implementation
}
```

## Common Use Cases

1. **Database authentication** - Most common
2. **LDAP authentication** - Corporate environments
3. **OAuth2/OpenID Connect** - Social login
4. **JWT authentication** - Microservices
5. **Multi-tenant applications** - Different user sources

This interface is the foundation of Spring Security's authentication mechanism and understanding it is crucial for implementing secure authentication in your applications.

##### Tags : [[1 - Spring Security 🍌]]