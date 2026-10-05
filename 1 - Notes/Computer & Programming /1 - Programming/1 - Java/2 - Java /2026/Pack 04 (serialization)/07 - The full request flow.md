


## 1. Mental model first

The data a user types is the same information the whole way through, but it changes form at each boundary, like a message passing through translators. Each form exists because the next stage understands only that form:

|Stage|Form|Who understands it|
|---|---|---|
|Browser|JS object|JavaScript|
|Network|JSON text (bytes)|Anyone: it's a shared format|
|Controller|Java DTO object|Your Java code|
|Service|Java Entity object|Your domain and persistence code|
|Database|Rows and columns|SQL|

The only places where state becomes bytes or text are the two JSON boundaries. Everything else is object-to-object copying or ORM mapping.

## 2. The POST flow (creating something)

1. The user fills a form. The front-end holds a JS object and calls `JSON.stringify`, which gives the text `{"name":"Alice","age":25}`.
2. It is sent as the body of `POST /persons` with the header `Content-Type: application/json`.
3. Spring sees `@RequestBody`, and Jackson **deserializes** the JSON into a `CreatePersonRequest` DTO.
4. If you wrote `@Valid`, validation rules (`@NotBlank`, `@Min`) run now. Bad input is rejected here with a 400, before any of your logic runs.
5. The service maps the DTO to a new `PersonEntity` and adds fields the client must not control (`createdAt`, `status`, owner).
6. The repository saves the entity. Hibernate generates `INSERT INTO person (...) VALUES (?, ?, ?)`, the DB stores the row, and the entity receives its generated `id`.
7. The service maps the saved entity to a `PersonResponse` DTO.
8. Jackson **serializes** that DTO to JSON, and the response goes back as `201 Created`.

## 3. The GET flow (reading)

1. The request arrives, usually with no body: `GET /persons/5`.
2. The service asks the repository, and Hibernate runs `SELECT ... WHERE id = 5`.
3. The DB returns a row, and Hibernate builds a `PersonEntity` from it.
4. The service maps the entity to `PersonResponse`.
5. Jackson serializes it to JSON, and the browser parses it back into a JS object.

Notice that **GET has no deserialization step on the server**, because there is no JSON body to read. Only the response is serialized.

## 4. The code, end to end

```java
// Wire contract IN: only what the client may send
public record CreatePersonRequest(
        @NotBlank String name,
        @Min(0) int age) {}

// Wire contract OUT: only what the client may see
public record PersonResponse(Long id, String name, int age) {}

// Persistence shape: matches the table
@Entity
class PersonEntity {
    @Id @GeneratedValue Long id;
    String name;
    int age;
    Instant createdAt;
    protected PersonEntity() {}          // Hibernate needs a no-arg constructor
    PersonEntity(String name, int age) { this.name = name; this.age = age; }
}

@RestController
@RequestMapping("/persons")
class PersonController {
    private final PersonService service;
    PersonController(PersonService service) { this.service = service; }

    @PostMapping
    ResponseEntity<PersonResponse> create(@Valid @RequestBody CreatePersonRequest req) {
        PersonResponse created = service.create(req);
        return ResponseEntity.created(URI.create("/persons/" + created.id())).body(created);
    }

    @GetMapping("/{id}")
    PersonResponse get(@PathVariable Long id) { return service.get(id); }
}

@Service
class PersonService {
    private final PersonRepository repo;
    PersonService(PersonRepository repo) { this.repo = repo; }

    @Transactional
    PersonResponse create(CreatePersonRequest req) {
        var entity = new PersonEntity(req.name(), req.age());   // DTO -> Entity
        entity.createdAt = Instant.now();                       // server-owned field
        var saved = repo.save(entity);                          // Entity -> row
        return new PersonResponse(saved.id, saved.name, saved.age);  // Entity -> DTO
    }

    PersonResponse get(Long id) {
        var e = repo.findById(id).orElseThrow(() -> new NoSuchElementException("Not found"));
        return new PersonResponse(e.id, e.name, e.age);
    }
}
```

## 5. Why the separate classes exist

- **Request DTO vs Response DTO:** they differ. The client sends no `id`, and the server returns one. Using one class for both lets a client send an `id` or other fields they should never control.
- **DTO vs Entity:** the DTO follows the JSON contract and the Entity follows the DB schema. Each can change without breaking the other.
- **Security:** if you bind JSON straight onto an entity, a client can add `"role":"ADMIN"` to the body and your code may save it. This is called **mass assignment** (over-posting). A DTO with only the allowed fields blocks it.

## 6. What's good to know

**Validation and errors**

- Validate at the edge (`@Valid` on the DTO) and keep business rules in the service.
- Use a `@RestControllerAdvice` to turn exceptions into consistent JSON errors (400 for bad input, 404 for missing, 409 for conflicts) instead of leaking stack traces.

**Jackson behavior**

- By default Spring Boot ignores unknown JSON fields instead of failing.
- A missing field becomes `null` (or `0` for a primitive), so use `@NotNull` or validation if it is required. Records and constructors work with Jackson, but the field names must match the JSON keys.
- Dates: use `Instant` or `LocalDate`, which serialize to ISO-8601 text. Avoid the old `java.util.Date`.

**Mapping**

- Hand-written mapping like the code above is fine for small projects. For many fields, **MapStruct** generates the mapping code at compile time, so it is as fast as handwritten.
- Keep entities off the wire: returning one directly risks `LazyInitializationException`, infinite recursion on bidirectional relations, and leaked fields like `passwordHash`.

**Persistence**

- `@Transactional` makes the service method one unit: if anything throws, the DB changes roll back.
- Hibernate **tracks** loaded entities. Inside a transaction, changing a field on a loaded entity is saved automatically at commit, even without calling `save()`.
- **N+1 problem:** loading a list of entities and then touching a lazy relation on each one fires one extra query per row. Watch your SQL logs (`spring.jpa.show-sql=true`) while learning.
- IDs are generated by the DB (or by a sequence), so they exist only after `save()`.

**HTTP semantics**

- POST returns `201 Created` with a `Location` header, GET returns `200`, and a missing resource returns `404`.
- Retries happen. If a client resends a POST after a timeout, you may create a duplicate, so important operations use an idempotency key or a unique constraint.

## 7. Compact summary

```
JSON ──Jackson (deserialize)──▶ Request DTO ──map──▶ Entity ──Hibernate──▶ SQL row
JSON ◀──Jackson (serialize)──── Response DTO ◀──map── Entity ◀──Hibernate── SQL row
```

Each arrow is a different technique with the same purpose: state moving between a place that holds it in one shape and a place that needs it in another.





[[Serialization]]