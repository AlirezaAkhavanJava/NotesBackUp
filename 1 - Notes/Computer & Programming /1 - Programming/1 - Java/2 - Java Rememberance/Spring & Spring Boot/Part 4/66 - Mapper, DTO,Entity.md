
 The **Entity, DTO, and Mapper aren't each owned by one layer**.

A better model is:

```text
HTTP
 │
 ▼
Controller
 │
 │ Request DTO
 ▼
Service
 │
 │ Entity
 ▼
Repository
 │
 ▼
Database
```

And **Mapper sits between DTOs and Entities**, usually used by the Service.

```text
              Controller
             /          \
            ▼            ▲
     Request DTO      Response DTO
            │            ▲
            │            │
            ▼            │
          Mapper ─────────┘
            │
            ▼
          Entity
            │
            ▼
       Repository
            │
            ▼
         Database
```

### Responsibilities

|Concept|Main responsibility|
|---|---|
|**Entity**|Persistence/domain state; mapped by JPA|
|**Repository**|Database access|
|**Request DTO**|Data entering your application|
|**Response DTO**|Data leaving your application|
|**Mapper**|Converts DTO ↔ Entity|
|**Service**|Business logic + orchestration|
|**Controller**|HTTP boundary|

### Example

Request:

```java
public record CreateTaskRequest(
        String title,
        String description
) {}
```

Entity:

```java
@Entity
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String title;
    private String description;
}
```

Mapper:

```java
@Component
public class TaskMapper {

    public Task toEntity(CreateTaskRequest request) {
        return new Task(
                null,
                request.title(),
                request.description()
        );
    }

    public TaskResponse toResponse(Task task) {
        return new TaskResponse(
                task.getId(),
                task.getTitle(),
                task.getDescription()
        );
    }
}
```

Service:

```java
@Service
public class TaskService {

    private final TaskRepository repository;
    private final TaskMapper mapper;

    public TaskResponse create(CreateTaskRequest request) {

        Task task = mapper.toEntity(request);

        Task saved = repository.save(task);

        return mapper.toResponse(saved);
    }
}
```

Controller:

```java
@PostMapping
public TaskResponse create(
        @Valid @RequestBody CreateTaskRequest request
) {
    return taskService.create(request);
}
```

So the flow is:

```text
Client
  │
  │ JSON
  ▼
Controller
  │
  │ Request DTO
  ▼
Service
  │
  │ Mapper
  ▼
Entity
  │
  ▼
Repository
  │
  ▼
Database
  │
  │ Entity
  ▼
Mapper
  │
  │ Response DTO
  ▼
Controller
  │
  │ JSON
  ▼
Client
```

### One correction to your statement

Instead of:

> Entity belongs to Repository layer

I'd say:

> **Entity belongs to the domain/persistence model, and Repository operates on Entities.**

Instead of:

> DTO for Service

I'd say:

> **DTO belongs to an application/API boundary; the Service consumes and produces DTOs when appropriate.**

And:

> **Mapper is a translation component between representations; it isn't specifically a Controller component.**

That's the cleaner architecture to carry forward.


[[Java]]
[[0 - Spring Framework]]