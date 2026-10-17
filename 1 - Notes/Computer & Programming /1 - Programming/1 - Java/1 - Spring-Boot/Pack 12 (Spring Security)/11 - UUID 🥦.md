
# UUID (Universally Unique Identifier) - Complete Guide

## What is a UUID?

A **UUID (Universally Unique Identifier)** is a 128-bit number used to identify information in computer systems. The key characteristic is that each UUID is **virtually guaranteed to be unique** across space and time.

### UUID Format
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
Example: `f47ac10b-58cc-4372-a567-0e02b2c3d479`

## Why Use UUIDs?

### Traditional Auto-Increment IDs vs UUIDs

```java
// Traditional auto-increment IDs
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;  // 1, 2, 3, 4... (sequential)
}

// UUID approach
@Entity
public class User {
    @Id
    private UUID id;  // Unique across all systems
}
```

### Advantages of UUIDs:
1. **Global Uniqueness**: Can generate IDs across multiple systems without coordination
2. **Security**: Hard to guess (unlike sequential IDs 1, 2, 3...)
3. **Offline Generation**: Can create IDs without database connection
4. **No Database Bottleneck**: No need to wait for database to generate next ID
5. **Distributed Systems**: Perfect for microservices and distributed databases

## UUID Versions

There are 5 main versions of UUIDs:

| Version | Method | Use Case |
|---------|--------|----------|
| v1 | Timestamp + MAC address | Time-based ordering |
| v2 | DCE Security | Security principals |
| **v3** | **MD5 Hash** | **Name-based (deterministic)** |
| **v4** | **Random** | **Most common - completely random** |
| **v5** | **SHA-1 Hash** | **Name-based (better security)** |
| v6+ | Newer standards | Future implementations |

## Java UUID Implementation

### 1. Basic UUID Operations

```java
import java.util.UUID;

public class UUIDBasicDemo {
    public static void main(String[] args) {
        // Generate a random UUID (version 4)
        UUID uuid1 = UUID.randomUUID();
        System.out.println("Random UUID: " + uuid1);
        System.out.println("Version: " + uuid1.version()); // 4
        System.out.println("Variant: " + uuid1.variant()); // 2
        
        // Create UUID from string
        String uuidString = "f47ac10b-58cc-4372-a567-0e02b2c3d479";
        UUID uuid2 = UUID.fromString(uuidString);
        System.out.println("From string: " + uuid2);
        
        // Compare UUIDs
        System.out.println("Equal: " + uuid1.equals(uuid2));
        
        // Get string representations
        System.out.println("ToString: " + uuid1.toString());
        System.out.println("Hex: " + Long.toHexString(uuid1.getMostSignificantBits()));
    }
}
```

### 2. Different UUID Versions in Java

```java
import java.util.UUID;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;

public class UUIDVersionsDemo {
    
    // Version 4: Random UUID (Most Common)
    public static UUID generateRandomUUID() {
        return UUID.randomUUID(); // This is always version 4
    }
    
    // Version 3: Name-based using MD5
    public static UUID generateNameBasedUUIDv3(String namespace, String name) {
        String source = namespace + name;
        try {
            byte[] bytes = source.getBytes(StandardCharsets.UTF_8);
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(bytes);
            
            // Set version to 3
            digest[6] &= 0x0f;  // Clear version
            digest[6] |= 0x30;  // Set to version 3
            // Set variant to 2 (RFC 4122)
            digest[8] &= 0x3f;  // Clear variant
            digest[8] |= 0x80;  // Set to RFC 4122
            
            long msb = 0;
            long lsb = 0;
            for (int i = 0; i < 8; i++)
                msb = (msb << 8) | (digest[i] & 0xff);
            for (int i = 8; i < 16; i++)
                lsb = (lsb << 8) | (digest[i] & 0xff);
                
            return new UUID(msb, lsb);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
    
    // Version 5: Name-based using SHA-1 (Recommended over v3)
    public static UUID generateNameBasedUUIDv5(String namespace, String name) {
        String source = namespace + name;
        try {
            byte[] bytes = source.getBytes(StandardCharsets.UTF_8);
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            byte[] digest = md.digest(bytes);
            
            // Set version to 5
            digest[6] &= 0x0f;  // Clear version
            digest[6] |= 0x50;  // Set to version 5
            // Set variant to 2 (RFC 4122)
            digest[8] &= 0x3f;  // Clear variant
            digest[8] |= 0x80;  // Set to RFC 4122
            
            long msb = 0;
            long lsb = 0;
            for (int i = 0; i < 8; i++)
                msb = (msb << 8) | (digest[i] & 0xff);
            for (int i = 8; i < 16; i++)
                lsb = (lsb << 8) | (digest[i] & 0xff);
                
            return new UUID(msb, lsb);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
    
    public static void main(String[] args) {
        System.out.println("=== UUID Versions Demo ===");
        
        // Version 4 - Random
        UUID v4 = generateRandomUUID();
        System.out.println("V4 (Random): " + v4);
        System.out.println("  Version: " + v4.version());
        
        // Version 3 - Name-based MD5
        UUID v3 = generateNameBasedUUIDv3("my-namespace", "john.doe");
        System.out.println("V3 (Name-based MD5): " + v3);
        System.out.println("  Version: " + v3.version());
        
        // Version 5 - Name-based SHA-1
        UUID v5 = generateNameBasedUUIDv5("my-namespace", "john.doe");
        System.out.println("V5 (Name-based SHA-1): " + v5);
        System.out.println("  Version: " + v5.version());
        
        // Same input always produces same output for v3/v5
        UUID v5_same = generateNameBasedUUIDv5("my-namespace", "john.doe");
        System.out.println("V5 Same input: " + v5_same);
        System.out.println("  Equal: " + v5.equals(v5_same));
    }
}
```

## UUID in Spring Boot Applications

### 1. Entity with UUID as Primary Key

```java
@Entity
@Table(name = "users")
public class User {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(
        name = "UUID",
        strategy = "org.hibernate.id.UUIDGenerator"
    )
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;
    
    @Column(nullable = false)
    private String username;
    
    @Column(nullable = false)
    private String email;
    
    // Constructors
    public User() {
        // Hibernate requires no-args constructor
    }
    
    public User(String username, String email) {
        this.username = username;
        this.email = email;
    }
    
    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
```

### 2. Repository

```java
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    
    // Custom query methods work the same as with Long IDs
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    List<User> findByUsernameContainingIgnoreCase(String username);
}
```

### 3. Service Layer

```java
@Service
@Transactional
public class UserService {
    
    private final UserRepository userRepository;
    
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    public User createUser(String username, String email) {
        // Check if user already exists
        if (userRepository.findByUsername(username).isPresent()) {
            throw new IllegalArgumentException("Username already exists: " + username);
        }
        
        if (userRepository.findByEmail(email).isPresent()) {
            throw new IllegalArgumentException("Email already exists: " + email);
        }
        
        // Create new user - ID will be auto-generated by Hibernate
        User user = new User(username, email);
        return userRepository.save(user);
    }
    
    public User getUserById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));
    }
    
    public User getUserById(String idString) {
        try {
            UUID id = UUID.fromString(idString);
            return getUserById(id);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid UUID format: " + idString);
        }
    }
    
    public List<User> searchUsers(String searchTerm) {
        return userRepository.findByUsernameContainingIgnoreCase(searchTerm);
    }
    
    public void deleteUser(UUID id) {
        if (!userRepository.existsById(id)) {
            throw new UserNotFoundException("User not found with id: " + id);
        }
        userRepository.deleteById(id);
    }
}
```

### 4. REST Controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    private final UserService userService;
    
    public UserController(UserService userService) {
        this.userService = userService;
    }
    
    @PostMapping
    public ResponseEntity<UserDTO> createUser(@RequestBody @Valid CreateUserRequest request) {
        User user = userService.createUser(request.getUsername(), request.getEmail());
        UserDTO userDTO = mapToDTO(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(userDTO);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUser(@PathVariable String id) {
        User user = userService.getUserById(id);
        UserDTO userDTO = mapToDTO(user);
        return ResponseEntity.ok(userDTO);
    }
    
    @GetMapping
    public ResponseEntity<List<UserDTO>> searchUsers(@RequestParam(required = false) String search) {
        List<User> users;
        if (search != null && !search.trim().isEmpty()) {
            users = userService.searchUsers(search);
        } else {
            users = userService.getAllUsers();
        }
        List<UserDTO> userDTOs = users.stream().map(this::mapToDTO).collect(Collectors.toList());
        return ResponseEntity.ok(userDTOs);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable String id) {
        userService.deleteUser(UUID.fromString(id));
        return ResponseEntity.noContent().build();
    }
    
    // DTO mapping method
    private UserDTO mapToDTO(User user) {
        return new UserDTO(
            user.getId().toString(),
            user.getUsername(),
            user.getEmail()
        );
    }
    
    // DTO Classes
    public static class CreateUserRequest {
        @NotBlank private String username;
        @Email @NotBlank private String email;
        
        // getters and setters
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }
    
    public static class UserDTO {
        private final String id;
        private final String username;
        private final String email;
        
        public UserDTO(String id, String username, String email) {
            this.id = id;
            this.username = username;
            this.email = email;
        }
        
        // getters
        public String getId() { return id; }
        public String getUsername() { return username; }
        public String getEmail() { return email; }
    }
}
```

## Database Configuration

### 1. PostgreSQL Configuration

```sql
-- Create table with UUID type (PostgreSQL)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert with auto-generated UUID
INSERT INTO users (username, email) VALUES ('john_doe', 'john@example.com');
```

### 2. Hibernate Configuration

```properties
# application.properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.id.uuid_generator_strategy=org.hibernate.id.uuid.CustomVersionOneStrategy

# For better UUID performance
spring.jpa.properties.hibernate.jdbc.batch_size=25
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
```

## Performance Considerations

### 1. UUID Storage Size

```java
public class UUIDStorageDemo {
    public static void main(String[] args) {
        // Storage requirements
        System.out.println("=== Storage Requirements ===");
        System.out.println("Long (8 bytes): " + Long.BYTES + " bytes");
        System.out.println("Integer (4 bytes): " + Integer.BYTES + " bytes");
        System.out.println("UUID (16 bytes): " + 16 + " bytes");
        
        // Memory impact
        UUID uuid = UUID.randomUUID();
        String uuidString = uuid.toString();
        
        System.out.println("UUID as object: ~40 bytes (with object overhead)");
        System.out.println("UUID as string: 36 characters = 72+ bytes (UTF-16)");
        System.out.println("UUID as binary: 16 bytes (most efficient)");
    }
}
```

### 2. Indexing Performance

```java
@Entity
@Table(name = "users")
public class User {
    
    @Id
    private UUID id;
    
    // For better query performance, also index frequently searched fields
    @Column(nullable = false)
    private String username;
    
    @Column(nullable = false)
    private String email;
    
    // Consider adding created_at for time-based queries
    @CreationTimestamp
    private LocalDateTime createdAt;
}
```

## Best Practices

### 1. When to Use UUIDs

**✅ Use UUIDs when:**
- Building distributed systems
- Need offline ID generation
- Security through obscurity is desired
- Merging data from multiple sources
- Microservices architecture

**❌ Avoid UUIDs when:**
- Storage size is critical
- Maximum read performance needed
- Simple single-database applications
- Human-readable IDs are important

### 2. UUID Format in APIs

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverter(new StringToUUIDConverter());
    }
    
    public static class StringToUUIDConverter implements Converter<String, UUID> {
        @Override
        public UUID convert(String source) {
            try {
                return UUID.fromString(source);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid UUID format: " + source);
            }
        }
    }
}
```

### 3. Custom UUID Generator

```java
@Component
public class CustomUUIDGenerator {
    
    // For time-ordered UUIDs (better for database indexing)
    public UUID generateTimeOrderedUUID() {
        return UUID.randomUUID(); // In real implementation, use time-based algorithm
    }
    
    // For predictable testing
    public UUID generateTestUUID(String testName) {
        return generateNameBasedUUIDv5("test-namespace", testName);
    }
    
    private UUID generateNameBasedUUIDv5(String namespace, String name) {
        // Implementation from earlier
        String source = namespace + name;
        try {
            byte[] bytes = source.getBytes(StandardCharsets.UTF_8);
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            byte[] digest = md.digest(bytes);
            
            digest[6] &= 0x0f;
            digest[6] |= 0x50;
            digest[8] &= 0x3f;
            digest[8] |= 0x80;
            
            long msb = 0;
            long lsb = 0;
            for (int i = 0; i < 8; i++)
                msb = (msb << 8) | (digest[i] & 0xff);
            for (int i = 8; i < 16; i++)
                lsb = (lsb << 8) | (digest[i] & 0xff);
                
            return new UUID(msb, lsb);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
```

## Testing with UUIDs

```java
@SpringBootTest
class UserServiceTest {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private UserRepository userRepository;
    
    @Test
    void testCreateUserWithUUID() {
        // Given
        String username = "testuser";
        String email = "test@example.com";
        
        // When
        User user = userService.createUser(username, email);
        
        // Then
        assertNotNull(user.getId());
        assertEquals(36, user.getId().toString().length()); // UUID string length
        assertEquals(username, user.getUsername());
        assertEquals(email, user.getEmail());
        
        // Verify can retrieve by UUID
        User foundUser = userService.getUserById(user.getId());
        assertEquals(user.getId(), foundUser.getId());
    }
    
    @Test
    void testInvalidUUIDHandling() {
        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            userService.getUserById("invalid-uuid-string");
        });
    }
}
```

## Common UUID Patterns

### 1. Base64 Encoding for Compact Representation

```java
import java.util.Base64;

public class UUIDCompression {
    
    public static String toBase64(UUID uuid) {
        byte[] bytes = new byte[16];
        long msb = uuid.getMostSignificantBits();
        long lsb = uuid.getLeastSignificantBits();
        
        for (int i = 0; i < 8; i++) {
            bytes[i] = (byte) (msb >>> 8 * (7 - i));
        }
        for (int i = 8; i < 16; i++) {
            bytes[i] = (byte) (lsb >>> 8 * (15 - i));
        }
        
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
    
    public static UUID fromBase64(String base64) {
        byte[] bytes = Base64.getUrlDecoder().decode(base64);
        long msb = 0;
        long lsb = 0;
        
        for (int i = 0; i < 8; i++) {
            msb = (msb << 8) | (bytes[i] & 0xff);
        }
        for (int i = 8; i < 16; i++) {
            lsb = (lsb << 8) | (bytes[i] & 0xff);
        }
        
        return new UUID(msb, lsb);
    }
    
    public static void main(String[] args) {
        UUID original = UUID.randomUUID();
        String base64 = toBase64(original);
        UUID restored = fromBase64(base64);
        
        System.out.println("Original: " + original);
        System.out.println("Base64:   " + base64);
        System.out.println("Restored: " + restored);
        System.out.println("Equal:    " + original.equals(restored));
        System.out.println("Length:   " + original.toString().length() + " vs " + base64.length());
    }
}
```

## Summary

**UUID Key Points:**
- **128-bit unique identifiers** - extremely low collision probability
- **Multiple versions** - v4 (random) is most common
- **Database friendly** - but consider storage and indexing impact
- **Perfect for distributed systems** - generate IDs anywhere
- **Secure** - hard to guess compared to sequential IDs

UUIDs are essential for modern distributed applications, providing global uniqueness without centralized coordination.


###### Tags : [[1 - Spring Security 🍌]]