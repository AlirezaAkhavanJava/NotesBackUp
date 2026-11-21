![[Pasted image 20251210105139.png]]
# 1. What DTO Pattern Is

**DTO (Data Transfer Object)** is a simple object used to **carry data between layers** (usually Controller ↔ Service ↔ Client).

A DTO has:

- No business logic
    
- No JPA annotations (usually)
    
- Only fields needed for input/output
    

DTO = "Clean data box that travels around your application."

---

# 2. Why We Use DTOs (Real Reasons That Matter)

### 1. Protect Your Entities

Entities contain:

- Database mappings
    
- Sensitive fields
    
- Relationships
    
- Internal logic
    

You should generally never expose them directly in REST responses.

DTOs prevent:

- Leaking passwords
    
- Exposing internal IDs
    
- Infinite JSON recursion
    
- Unintentionally modifying database objects
    

### 2. Better API Structure

Clients shouldn't see:

- Foreign key internals
    
- Lazy-loaded entities
    
- JPA annotations
    
- Unwanted fields
    

DTOs give your API a clean structure.

### 3. Avoid JPA Lazy Loading Problems

Returning entities directly can cause:

- N+1 queries
    
- Infinite recursion
    
- Serialization errors
    
- Performance issues
    

DTOs allow you to control which data is fetched and returned.

**Important:** DTOs alone do not eliminate N+1 queries or guarantee fewer database hits. Query design, projections, fetch strategies, and mapping timing also matter.

### 4. Decouple Your Domain

Your database structure should NOT dictate your API structure.

DTOs allow:

- Different shapes for inputs and outputs
    
- Renaming fields
    
- Flattening nested objects
    
- Hiding internal structure changes
    

---

# 3. DTO Types (VERY IMPORTANT)

### Type A: Request DTO

Used for POST/PUT/PATCH input.

```
public record CreateUserRequest(
    String username,
    String email,
    String password
) {}
```

### Type B: Response DTO

Used for API output.

```
public record UserResponse(
    Long id,
    String username,
    String email
) {}
```

### Type C: Update DTO

Contains only fields allowed to be updated.

```
public record UpdateUserRequest(
    String email,
    String bio
) {}
```

### Type D: Nested DTO

Used for representing sub-objects.

```
public record PostSummary(
    Long id,
    String title
) {}
```

---

# 4. Entity vs DTO (Side-by-side)

### ENTITY (Business + Database)

```
@Entity
public class User {

    @Id
    private Long id;

    private String email;
    private String password;

    @OneToMany(mappedBy = "user")
    private List<Post> posts;
}
```

### DTO (API Only)

```
public record UserResponse(
    Long id,
    String email
) {}
```

Notice:

- Password removed
    
- Posts removed
    
- Simple and clean structure
    

---

# 5. Mapping: How Entities ↔ DTOs Are Converted

There are three common approaches.

## A. Manual Mapping (Best Control)

Example:

```
public UserResponse toDto(User user) {
    return new UserResponse(
        user.getId(),
        user.getEmail()
    );
}
```

Reverse mapping:

```
public User toEntity(CreateUserRequest dto) {
    User user = new User();
    user.setEmail(dto.email());
    user.setPassword(dto.password());
    return user;
}
```

Advantages:

- Maximum control
    
- Clear and predictable
    
- Easy to debug
    
- Safe when explicitly handling fields
    

Disadvantage:

- More code
    

## B. Using ModelMapper (Automatic)

```
modelMapper.map(user, UserResponse.class);
```

Disadvantages:

- Can be unpredictable with complex object graphs
    
- Mapping configuration can become difficult
    
- Some errors may only appear at runtime
    

## C. Using MapStruct (Compile-time Mapping)

```
@Mapper(componentModel = "spring")
public interface UserMapper {

    UserResponse toDto(User user);

    User toEntity(CreateUserRequest request);
}
```

Advantages:

- Fast (uses annotation processing)
    
- Type-safe
    
- Generates mapping code at compile time
    
- Integrates with Spring
    

A strong choice for larger applications.

---

# 6. How DTO Fits in Spring Boot Layered Architecture

```
Client
   |
   v
Controller
   |
   v
Request DTO
   |
   v
Service
   |
   v
Entity
   |
   v
Repository
   |
   v
Database
```

### Request Flow

Client → Request DTO → Controller → Service → Entity → Repository → Database

### Response Flow

Database → Repository → Entity → Service → Response DTO → Controller → Client

Each layer has its own responsibility.

---

# 7. Example of Full Workflow

### Step 1: Request DTO

```
public record CreatePostRequest(
    String title,
    String content
) {}
```

### Step 2: Response DTO

```
public record PostResponse(
    Long id,
    String title,
    String content
) {}
```

### Step 3: Mapping

Entity mapping:

```
public Post toEntity(CreatePostRequest dto) {

    return Post.builder()
        .title(dto.title())
        .content(dto.content())
        .build();
}
```

Response mapping:

```
public PostResponse toDto(Post post) {

    return new PostResponse(
        post.getId(),
        post.getTitle(),
        post.getContent()
    );
}
```

### Step 4: Controller

```
@PostMapping
public PostResponse createPost(
    @RequestBody CreatePostRequest request
) {
    return postService.createPost(request);
}
```

### Step 5: Service

```
public PostResponse createPost(CreatePostRequest request) {

    Post post = postMapper.toEntity(request);

    Post savedPost = repository.save(post);

    return postMapper.toDto(savedPost);
}
```

The service coordinates the operation, while the mapper handles object conversion.

---

# 8. When DTO Pattern Is Important

Use DTOs when:

- You have bidirectional relationships
    
- You want to avoid infinite JSON recursion
    
- Your entities contain sensitive data
    
- You want clean API responses
    
- You want versioned REST APIs
    
- You want API stability when your database schema changes
    

DTOs are an important part of professional API design.

---

# 9. Mistakes You MUST Avoid

- Exposing entities directly in REST responses
    
- Using entities as request payloads
    
- Returning entire entity graphs through REST
    
- Blindly using automatic mapping on complex projects
    
- Putting business logic inside DTOs
    

DTOs should generally be:

- Lightweight
    
- Simple
    
- Free of JPA annotations
    

---

# Half-Brain Summary

If you were half-asleep:

**Entities = Database and domain model.**

**DTOs = Data exchanged through your API.**

Use DTOs to protect entities, control API responses, and separate your database structure from your API contract.

###### Tags: [[Spring Framework]]