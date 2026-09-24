


First, a clarification: `toDto` and `fromDto` are methods of a **DTO/object mapper** — usually a MapStruct mapper or a hand-written mapper. They are not the methods of a MyBatis mapper, which instead has `selectById`, `insert`, `update`, etc.

## Core idea

A DTO mapper is a **bidirectional translator** between:

- **Entity / Domain model** — the object your persistence layer or business logic uses.
- **DTO** — the object your API/controller/messaging layer uses.

The two methods encode direction:

```java
public interface UserMapper {
    UserDto toDto(User user);   // Entity -> DTO
    User fromDto(UserDto dto);  // DTO -> Entity
}
```

Naming convention:

- `toX(...)` means **target is X**.
- `fromX(...)` means **source is X**.

So:

- `toDto(user)` → convert an entity/domain object **to a DTO**.
- `fromDto(dto)` → create an entity/domain object **from a DTO**.

## Architecture and where it sits

Typical layered flow:

```text
HTTP JSON
   ↓ / ↑
Controller
   ↓ / ↑  DTO
Service
   ↓ / ↑  Entity / Domain
Repository
   ↓ / ↑
Database
```

The DTO mapper is usually used by the **Service layer**, or sometimes by the Controller for simple cases. It sits at the boundary between the API model and the internal model.

Example flow for `POST /users`:

```text
Controller receives CreateUserRequest (DTO)
        ↓
Service calls mapper.fromDto(request)  -> User entity
        ↓
Repository saves User
        ↓
Service calls mapper.toDto(savedUser)  -> UserResponse (DTO)
        ↓
Controller returns JSON
```

Example flow for `GET /users/{id}`:

```text
Service calls repository.findById(id) -> User entity
        ↓
Service calls mapper.toDto(user) -> UserResponse (DTO)
        ↓
Controller returns JSON
```

So:

- **`fromDto`** is used for **inbound** data: API request → entity/domain.
- **`toDto`** is used for **outbound** data: entity/domain → API response.

## What they usually are

| Method | Source | Target | Typical use | Usually does |
|---|---|---|---|---|
| `toDto` | Entity / Domain | DTO | Returning data to controller/API | Hides sensitive fields, flattens nested objects, formats dates/enums, omits internal IDs |
| `fromDto` | DTO | Entity / Domain | Creating or updating from request | Ignores server-controlled fields like `id`, `createdAt`, `updatedAt`, `version`, roles, etc. |

They are normally:

- **Pure functions** — no database calls, no HTTP calls, no business decisions.
- **Stateless** — same input gives same output.
- **Simple** — field copying, renaming, type conversion, nested mapping.
- **Not responsible for validation** — validation belongs to the controller/service layer.
- **Not responsible for transactions** — `@Transactional` belongs on the service.

## Typical mapper interface

With MapStruct:

```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    UserDto toDto(User user);

    User fromDto(UserDto dto);

    List<UserDto> toDtoList(List<User> users);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    User fromCreateRequest(CreateUserRequest request);

    @Mapping(target = "id", ignore = true)
    void updateFromDto(UpdateUserRequest dto, @MappingTarget User user);
}
```

Common variants you will see:

- `toEntity(dto)` instead of `fromDto(dto)` — clearer target naming.
- `toResponse(entity)` instead of `toDto(entity)` — when DTOs are split into request/response types.
- `fromRequest(request)` and `toResponse(entity)` — very common in REST APIs.
- `toDtoList(entities)` / `fromDtoList(dtos)` — bulk conversions.
- `updateFromDto(dto, @MappingTarget entity)` — update an existing entity instead of creating a new one.

## Best practices

- Keep one mapper per aggregate/entity, e.g. `UserMapper`, `OrderMapper`.
- Prefer separate DTOs for request and response.
- Use `@Mapping` for fields with different names.
- Use `@MappingTarget` for updates.
- Ignore server-controlled fields on create/update.
- Do not expose JPA entities directly from controllers.
- Do not put business logic in the mapper.
- Test the mapper separately; MapStruct generates implementations at compile time, so mapping errors are caught early.

In short: **`toDto` is the outbound conversion from your internal model to an API DTO; `fromDto` is the inbound conversion from an API DTO to your internal model. Together they form the DTO mapper layer used mainly by the service layer.**

---

## End-to-end architecture diagram

```text
        +-----------------------------+
        |            User             |
        |   (Browser / Mobile / API)  |
        +--------------+--------------+
                       |
                       | HTTP request / response
                       | JSON over REST
                       v
+---------------------------------------------------------------+
|                     Server (Spring Boot)                      |
|                                                               |
|  +----------------+        +----------------+                 |
|  |  Controller    |        |    Service     |                 |
|  | @RestController| <----> |   @Service     |                 |
|  +----------------+        +-------+--------+                 |
|          ^                         |                          |
|          |                         |                          |
|          | DTO                     | Entity / Domain          |
|          |                         v                          |
|  +----------------+        +----------------+                 |
|  |   DTO Mapper   | <----> |  Entity/Domain |                 |
|  | toDto/fromDto  |        |  User, Order   |                 |
|  +----------------+        +-------+--------+                 |
|                                    |                          |
|                                    v                          |
|                            +----------------+                 |
|                            |  MyBatis Mapper|                 |
|                            | select/insert  |                 |
|                            +-------+--------+                 |
|                                    |                          |
+------------------------------------|--------------------------+
                                     v
                              +--------------+
                              |   Database   |
                              |  users table |
                              +--------------+
```

## Request flow: creating a user

```text
User/Browser                          Server (Spring Boot)
    |                                        |
    | 1. HTTP POST /users                    |
    |    JSON: { "name": "Ana", ... }        |
    |--------------------------------------->|
    |                                        | 2. Controller receives JSON
    |                                        |    Jackson -> CreateUserRequest DTO
    |                                        |
    |                                        | 3. Controller calls Service.create(request)
    |                                        |
    |                                        | 4. DTO Mapper: fromDto(request)
    |                                        |    CreateUserRequest DTO -> User Entity
    |                                        |
    |                                        | 5. MyBatis Mapper: insert(user)
    |                                        |        |
    |                                        |        v
    |                                        |    Database stores row
    |                                        |        |
    |                                        |        v
    |                                        | 6. MyBatis Mapper returns User Entity
    |                                        |    (with generated id)
    |                                        |
    |                                        | 7. DTO Mapper: toDto(user)
    |                                        |    User Entity -> UserResponse DTO
    |                                        |
    | 8. HTTP 201 Created                    |
    |    JSON: { "id": 42, "name": "Ana" }   |
    |<---------------------------------------|
```

## Request flow: reading a user

```text
User/Browser                          Server (Spring Boot)
    |                                        |
    | 1. HTTP GET /users/42                  |
    |--------------------------------------->|
    |                                        | 2. Controller calls Service.findById(42)
    |                                        |
    |                                        | 3. MyBatis Mapper: findById(42)
    |                                        |        |
    |                                        |        v
    |                                        |    Database returns row
    |                                        |        |
    |                                        |        v
    |                                        | 4. MyBatis Mapper maps row -> User Entity
    |                                        |
    |                                        | 5. DTO Mapper: toDto(user)
    |                                        |    User Entity -> UserResponse DTO
    |                                        |
    | 6. HTTP 200 OK                         |
    |    JSON: { "id": 42, "name": "Ana" }   |
    |<---------------------------------------|
```

## What is happening

| Step | Component | What it does |
|---|---|---|
| 1 | User | Sends an HTTP request with JSON to the Spring Boot server. |
| 2 | Controller | Receives the request. Jackson converts JSON into a DTO such as `CreateUserRequest`. |
| 3 | Service | Contains business logic and transaction boundaries. Calls mappers and repository/mapper methods. |
| 4 | DTO Mapper `fromDto` | Converts an inbound DTO into an Entity/Domain object. Example: `CreateUserRequest -> User`. |
| 5 | MyBatis Mapper | Executes SQL such as `insert`, `selectById`, `update`. It talks to the database. |
| 6 | Database | Stores or retrieves rows from tables such as `users`. |
| 7 | DTO Mapper `toDto` | Converts an Entity/Domain object into an outbound DTO. Example: `User -> UserResponse`. |
| 8 | Controller | Serializes the DTO back to JSON using Jackson and returns it to the user. |

## The two mappers are different

```text
DTO Mapper
  DTO  <-------->  Entity / Domain
  toDto:   Entity -> DTO
  fromDto: DTO    -> Entity

MyBatis Mapper
  Entity / Domain  <-------->  Database rows
  findById, insert, update, delete
```

## Key rule

- `fromDto` is used for **incoming data**: API request -> Entity/Domain.
- `toDto` is used for **outgoing data**: Entity/Domain -> API response.
- MyBatis Mapper handles **Entity/Domain <-> Database**.
- DTO Mapper handles **DTO <-> Entity/Domain**.
- The Service layer usually owns and coordinates both mappers.
- The Controller should not talk directly to the MyBatis Mapper.
- The DTO Mapper should not contain business logic or database calls.

[[Java]]
[[0 - Spring Framework]]
[[9 - Mapper]]
[[65 - Mapper]]