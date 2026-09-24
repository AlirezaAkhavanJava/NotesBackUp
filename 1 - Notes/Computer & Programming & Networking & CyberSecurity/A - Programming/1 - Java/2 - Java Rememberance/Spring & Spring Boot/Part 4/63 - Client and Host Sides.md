 **DTOs aren't necessarily only what the user provides.**

A better mental model is:

```text
              API boundary
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
 Request DTO           Response DTO
 user → server         server → user
        │                   ▲
        ▼                   │
      Service               │
        │                   │
        ▼                   │
      Entity ───────────────┘
        │
        ▼
     Database
```

### 1. Request DTO

This represents **what the client is allowed to send**.

```java
public record CreateUserRequest(
    String email,
    String password
) {}
```

The client sends:

```json
{
  "email": "alice@example.com",
  "password": "secret"
}
```

The client **doesn't construct a `User` entity**.

The service receives the DTO and decides what to do with it:

```java
User user = new User();

user.setEmail(request.email());
user.setPassword(hash(request.password()));
```

Notice the important boundary:

```text
CreateUserRequest
       │
       │ application logic
       ▼
     User
   Entity
```

The entity contains **application/domain state**, not simply a copy of user input.

---

### 2. Response DTO

This is the other direction.

Suppose your Entity contains:

```java
@Entity
public class User {

    private UUID id;
    private String email;
    private String passwordHash;
    private Instant createdAt;
    private boolean enabled;
}
```

You probably don't want to expose all of that.

So:

```java
public record UserResponse(
    UUID id,
    String email
) {}
```

Then:

```text
Entity
  │
  │ select what is safe/public
  ▼
UserResponse
  │
  ▼
JSON
  │
  ▼
Client
```

The client receives:

```json
{
  "id": "...",
  "email": "alice@example.com"
}
```

not:

```json
{
  "id": "...",
  "email": "alice@example.com",
  "passwordHash": "...",
  "createdAt": "...",
  "enabled": true
}
```

---

## 3. So your security intuition is correct

This part of what you said is important:

> "they both make sure user doesn't see something he should not"

**Yes, that's one major reason DTOs are used.**

But the deeper idea is **boundary control**, not merely security.

DTOs let you explicitly control:

- what clients may **send**
    
- what clients may **receive**
    
- what fields are exposed
    
- what fields are writable
    
- how your API contract differs from your persistence model
    

So:

```text
                 CLIENT
                    │
             ┌──────┴──────┐
             │             │
             ▼             ▲
      Request DTO      Response DTO
             │             ▲
             ▼             │
          Service ─────────┘
             │
             ▼
           Entity
             │
             ▼
          Database
```

### The key distinction

**DTO = communication model**

**Entity = persistence/domain model**

And the Service is where you typically translate between them:

```java
CreateUserRequest → User → UserResponse
```

That's a much stronger mental model than simply thinking:

> "DTO = user input, Entity = logic."

Because you'll soon encounter **request DTOs, response DTOs, command DTOs, query DTOs, projections, domain objects, and persistence entities**, and this boundary-based model will continue to work.


[[Java]]
[[0 - Spring Framework]]