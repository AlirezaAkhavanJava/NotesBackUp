
POJO, Entity, and DTO are three labels for the same basic shape — a class with fields and getters/setters — distinguished only by what role that class plays. The confusion usually isn't the code, it's forgetting that these are _roles_, not different syntaxes.

**POJO** is the broadest term: any plain Java object with no required inheritance, no required interface, nothing framework-specific attached to it. `Entity` and `DTO` are both POJOs; they just carry an extra job description.

**Entity** is a POJO whose job is to represent a row in a database table, via JPA/Hibernate:

```java
@Entity
public class User {
    @Id
    private Long id;
    private String name;
    private String passwordHash;   // sensitive — never leaves the app as-is
}
```

The `@Entity` annotation and the persistence context are what separate it from a plain POJO: the ORM tracks this object's lifecycle, flushes changes to the DB, and may lazy-load related data behind the scenes.

**DTO** is a POJO whose job is to move data across a boundary — typically between your service layer and the outside world (an HTTP request/response body):

```java
public class UserDTO {
    private String name;
    // no id, no passwordHash — only what the client needs
}
```

It has no persistence annotations and, ideally, no business logic — just the subset of fields that's safe and relevant to expose.

**Why not just send the Entity directly?** Three concrete reasons: it leaks internal-only fields (password hashes, audit columns), it can trigger lazy-loading exceptions or accidental infinite JSON recursion on bidirectional relationships, and it couples your public API shape to your database schema — so a column rename becomes a breaking API change instead of an internal refactor.

The standard flow in a Spring Boot REST app, mapping request/response through both:

```
Client → Controller(DTO in/out) → Service(maps DTO↔Entity) → Repository → DB
```

The controller only ever sees DTOs. The service is where the conversion happens — by hand, or with a mapper like MapStruct, which you've already [[entity-dto-mapper|looked at]].


[[Spring Framework]]