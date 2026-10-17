
## Why PasswordEncoder is Important

PasswordEncoder is crucial for securely storing passwords by:
- **Hashing passwords** instead of storing them in plain text
- **Adding salt** to prevent rainbow table attacks
- **Using adaptive functions** that are computationally expensive to slow down brute-force attacks

## Default PasswordEncoder in Spring Security 5+

Since Spring Security 5, the default PasswordEncoder is `DelegatingPasswordEncoder`, which supports multiple encoding algorithms.

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // Default uses bcrypt with strength 10
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }
}
```

## Available PasswordEncoder Implementations

### 1. BCryptPasswordEncoder (Recommended)
```java
@Bean
public PasswordEncoder passwordEncoder() {
    // Strength ranges from 4 to 31 (default: 10)
    return new BCryptPasswordEncoder(12);
}

// Usage example
public class UserService {
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    public void createUser(String username, String rawPassword) {
        String encodedPassword = passwordEncoder.encode(rawPassword);
        // Store encodedPassword in database
        
        // Verify password during login
        boolean matches = passwordEncoder.matches(rawPassword, encodedPassword);
    }
}
```

### 2. Argon2PasswordEncoder
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
}
```

### 3. PBKDF2PasswordEncoder
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return PBKDF2PasswordEncoder.defaultsForSpringSecurity_v5_8();
}
```

### 4. SCryptPasswordEncoder
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return SCryptPasswordEncoder.defaultsForSpringSecurity_v5_8();
}
```

## DelegatingPasswordEncoder (Most Common)

```java
@Bean
public PasswordEncoder passwordEncoder() {
    String defaultEncodingId = "bcrypt";
    Map<String, PasswordEncoder> encoders = new HashMap<>();
    encoders.put("bcrypt", new BCryptPasswordEncoder());
    encoders.put("pbkdf2", new Pbkdf2PasswordEncoder());
    encoders.put("scrypt", new SCryptPasswordEncoder());
    encoders.put("argon2", new Argon2PasswordEncoder());
    
    DelegatingPasswordEncoder delegatingPasswordEncoder = 
        new DelegatingPasswordEncoder(defaultEncodingId, encoders);
    
    // For backward compatibility with plain text (not recommended for production)
    delegatingPasswordEncoder.setDefaultPasswordEncoderForMatches(
        new PlainTextPasswordEncoder()
    );
    
    return delegatingPasswordEncoder;
}
```

## Complete Security Configuration Example

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

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
            .logout(logout -> logout
                .permitAll()
            );
        
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService(PasswordEncoder passwordEncoder) {
        UserDetails user = User.builder()
            .username("user")
            .password(passwordEncoder.encode("password"))
            .roles("USER")
            .build();
            
        UserDetails admin = User.builder()
            .username("admin")
            .password(passwordEncoder.encode("admin"))
            .roles("ADMIN")
            .build();
            
        return new InMemoryUserDetailsManager(user, admin);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }
}
```

## Custom UserDetailsService with Password Encoding

```java
@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Override
    public UserDetails loadUserByUsername(String username) 
            throws UsernameNotFoundException {
        
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));
            
        return org.springframework.security.core.userdetails.User.builder()
            .username(user.getUsername())
            .password(user.getPassword()) // Already encoded
            .roles(user.getRoles().toArray(new String[0]))
            .build();
    }
    
    public User registerNewUser(String username, String rawPassword) {
        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(rawPassword));
        return userRepository.save(user);
    }
}
```

## Password Validation and Strength Checking

```java
@Component
public class PasswordStrengthValidator {
    
    private final PasswordEncoder passwordEncoder;
    
    public PasswordStrengthValidator(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }
    
    public boolean isPasswordStrong(String password) {
        // Minimum 8 characters, at least one letter and one number
        String pattern = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{8,}$";
        return password.matches(pattern);
    }
    
    public String encodePassword(String rawPassword) {
        if (!isPasswordStrong(rawPassword)) {
            throw new IllegalArgumentException("Password does not meet strength requirements");
        }
        return passwordEncoder.encode(rawPassword);
    }
}
```

## Migration Strategy for Legacy Systems

```java
@Bean
public PasswordEncoder passwordEncoder() {
    Map<String, PasswordEncoder> encoders = new HashMap<>();
    encoders.put("bcrypt", new BCryptPasswordEncoder());
    encoders.put("md5", new MessageDigestPasswordEncoder("MD5"));
    encoders.put("sha256", new MessageDigestPasswordEncoder("SHA-256"));
    encoders.put("noop", NoOpPasswordEncoder.getInstance());
    
    DelegatingPasswordEncoder delegatingPasswordEncoder = 
        new DelegatingPasswordEncoder("bcrypt", encoders);
    
    return delegatingPasswordEncoder;
}
```

## Testing PasswordEncoder

```java
@SpringBootTest
class PasswordEncoderTest {

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Test
    void testPasswordEncoding() {
        String rawPassword = "mySecurePassword123";
        String encodedPassword = passwordEncoder.encode(rawPassword);
        
        assertThat(encodedPassword).isNotEqualTo(rawPassword);
        assertThat(passwordEncoder.matches(rawPassword, encodedPassword)).isTrue();
        assertThat(passwordEncoder.matches("wrongPassword", encodedPassword)).isFalse();
    }
    
    @Test
    void testDifferentSaltsProduceDifferentHashes() {
        String rawPassword = "samePassword";
        String encoded1 = passwordEncoder.encode(rawPassword);
        String encoded2 = passwordEncoder.encode(rawPassword);
        
        assertThat(encoded1).isNotEqualTo(encoded2);
        assertThat(passwordEncoder.matches(rawPassword, encoded1)).isTrue();
        assertThat(passwordEncoder.matches(rawPassword, encoded2)).isTrue();
    }
}
```

## Best Practices

1. **Always use adaptive one-way functions** like bcrypt, Argon2, or PBKDF2
2. **Use a strength factor** appropriate for your security requirements
3. **Never store passwords in plain text**
4. **Use DelegatingPasswordEncoder** for migration flexibility
5. **Validate password strength** before encoding
6. **Consider using pepper** (external secret) for additional security
7. **Keep dependencies updated** to benefit from security improvements

## Migration Example

```java
@Service
public class PasswordMigrationService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Transactional
    public void migrateUserPassword(String username, String rawPassword) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));
            
        // If password is not already using modern encoding
        if (!user.getPassword().startsWith("{bcrypt}")) {
            String newEncodedPassword = passwordEncoder.encode(rawPassword);
            user.setPassword(newEncodedPassword);
            userRepository.save(user);
        }
    }
}
```

This comprehensive guide covers the essential aspects of PasswordEncoder in Spring Security, helping you implement secure password handling in your applications.


###### Tags : [[1 - Spring Security 🍌]]