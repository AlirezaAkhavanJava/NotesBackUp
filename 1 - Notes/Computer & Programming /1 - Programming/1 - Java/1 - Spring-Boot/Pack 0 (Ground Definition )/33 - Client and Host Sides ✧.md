
DTOs split into two directions across the API boundary — that's the core upgrade over "DTO = user input."

![[ce0eb718-57ac-4751-ae67-c060a880262d.png]]

**Request DTO** — what the client is _allowed to send_. The client never touches your Entity directly; it sends a plain record, and your service decides how that maps into domain state:

```java
public record CreateUserRequest(String email, String password) {}
```

```java
User user = new User();
user.setEmail(request.email());
user.setPassword(hash(request.password()));
```

**Response DTO** — what the client is _allowed to receive_. Your Entity usually holds more than you want to expose (password hash, audit fields, internal flags):

```java
public record UserResponse(UUID id, String email) {}
```

So the client gets `{id, email}` — never `passwordHash` or `createdAt`.

**The real distinction:**

```
DTO    = communication model (contract with the outside world)
Entity = persistence/domain model (what you store and operate on)
```

The service is the translator between them:

```
CreateUserRequest → User → UserResponse
```

Once you have this boundary clearly, it generalizes cleanly to things you'll meet later — command DTOs, query DTOs, projections — all of them are just "shapes of data crossing a boundary," distinct from the Entity that lives inside it.


[[Spring Framework]]