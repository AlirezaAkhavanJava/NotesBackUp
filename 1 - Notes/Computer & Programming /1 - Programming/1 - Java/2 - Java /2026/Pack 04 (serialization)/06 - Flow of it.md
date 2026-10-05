
>We have some states like we have got a `@PostMapping` insertion that a user is trying to add something from the Front-end. That data is JSON, the JSON is sent to the Back-end and we catch it as a DTO, we use it in `@RequestBody` and a Mapper to create a new Object from that DTO and the Service adds some parts of it. This one is an Entity object, what was received was JSON but what we created after `@RequestBody` was **deserialized data** and what we send to a DB from the Back-end is **mapped Entity data**, which is converted into the database representation by JPA/Hibernate. What we receive from DB for `@GetMapping` is **database data mapped back into an Entity**, which is then **serialized into JSON** before being sent to the Front-end.

The key is to separate **JSON, Java objects, database data, serialization, and deserialization**. They are related, but they are not the same thing.

## 1. The big picture

Imagine your Spring Boot application has this flow:

```text
Frontend
   │
   │ JSON
   ▼
HTTP Request
   │
   ▼
@RequestBody
   │
   │ deserialization
   ▼
Java DTO
   │
   │ mapping
   ▼
Java Entity
   │
   │ JPA/Hibernate
   ▼
Database
```

And the reverse:

```text
Database
   │
   │ database row/data
   ▼
JPA/Hibernate
   │
   │ mapping
   ▼
Java Entity
   │
   │ serialization
   ▼
JSON
   │
   ▼
HTTP Response
   │
   ▼
Frontend
```

That's the mental model you want.

---

# 2. First: what is serialization?

**Serialization means converting an object's state into a representation that can be transmitted or stored.**

For example, suppose Java has:

```java
Task task = new Task();

task.setTitle("Learn Spring");
task.setCompleted(false);
```

The object's state is roughly:

```text
Task object
├── title = "Learn Spring"
└── completed = false
```

It can be serialized into JSON:

```json
{
    "title": "Learn Spring",
    "completed": false
}
```

The important point:

> **Serialization is not specifically "converting something into bytes."**

Bytes are one possible final representation, but JSON serialization produces a textual representation first.

For example:

```text
Java Object
     ↓
JSON representation
     ↓
UTF-8 bytes
     ↓
Network
```

---

# 3. Deserialization is the opposite

You receive:

```json
{
    "title": "Learn Spring",
    "completed": false
}
```

Spring/Jackson can convert that JSON into:

```java
CreateTaskRequest request
```

Conceptually:

```text
JSON
  ↓
deserialization
  ↓
Java object
```

So:

```text
Serialization:
Java Object → JSON

Deserialization:
JSON → Java Object
```

This is the first important distinction.

---

# 4. What `@RequestBody` actually does

Suppose you have:

```java
@PostMapping
public Task create(@RequestBody CreateTaskRequest request) {
    ...
}
```

The frontend sends:

```json
{
    "title": "Learn Spring"
}
```

Spring sees:

```java
@RequestBody CreateTaskRequest request
```

and essentially says:

> "Take the request body and convert its JSON representation into a `CreateTaskRequest` Java object."

Jackson performs the JSON ↔ Java conversion.

So:

```text
HTTP request body
       │
       │ JSON
       ▼
    Jackson
       │
       │ deserialization
       ▼
CreateTaskRequest
```

Therefore, your original statement:

> "what we created after `@RequestBody` was serialization"

was backwards.

It is:

> **What we get from `@RequestBody` is the result of deserialization.**

---

# 5. DTO → Entity is NOT serialization

This is another important distinction.

You might have:

```java
public record CreateTaskRequest(
    String title
) {}
```

and:

```java
@Entity
public class Task {

    @Id
    private Long id;

    private String title;

    private boolean completed;
}
```

Then your mapper does:

```java
Task task = mapper.toEntity(request);
```

This is:

```text
DTO
 ↓
mapping
 ↓
Entity
```

**This is not serialization.**

You're simply transforming one Java object into another Java object.

Think:

```text
CreateTaskRequest ──────► Task
       Java object       Java object
```

No JSON is required.

---

# 6. Then the Service does its work

For example:

```java
Task task = mapper.toEntity(request);

task.setCompleted(false);
task.setCreatedAt(LocalDateTime.now());

taskRepository.save(task);
```

Now you have:

```text
JSON
  ↓ deserialization
DTO
  ↓ mapping
Entity
  ↓ business logic
modified Entity
```

The entity is now ready to be persisted.

---

# 7. What happens when you call `save()`?

You might think:

```java
taskRepository.save(task);
```

means:

```text
Entity → serialized data → database
```

But that's not the best mental model.

JPA/Hibernate takes the **state of the Java entity** and translates it into SQL/database operations.

For example:

```java
Task
id = 10
title = "Learn Spring"
completed = false
```

Hibernate might generate something conceptually like:

```sql
INSERT INTO task (id, title, completed)
VALUES (10, 'Learn Spring', false);
```

So:

```text
Java Entity
    ↓
Hibernate/JPA mapping
    ↓
SQL
    ↓
Database row
```

This is **ORM mapping**, not simply serialization.

---

# 8. Database → Entity

Now imagine you make:

```http
GET /api/tasks/10
```

The database contains:

```text
id | title        | completed
---+--------------+----------
10 | Learn Spring | false
```

Hibernate retrieves that database data and constructs/populates a Java entity:

```java
Task task
```

Conceptually:

```text
Database row
     ↓
Hibernate/JPA
     ↓
Task entity
```

Again, this is **mapping**, not JSON deserialization.

---

# 9. Then something interesting happens

Your controller returns:

```java
@GetMapping("/{id}")
public Task getTask(@PathVariable Long id) {
    return taskService.findById(id);
}
```

The controller returns:

```java
Task
```

Spring needs to put that object into the HTTP response.

The client expects JSON.

So Jackson performs **serialization**:

```text
Task Java object
      ↓
   Jackson
      ↓ serialization
     JSON
```

Result:

```json
{
    "id": 10,
    "title": "Learn Spring",
    "completed": false
}
```

Then that JSON is sent over HTTP.

---

# 10. The complete cycle

Now put everything together:

### POST

```text
Frontend
   │
   │ JSON
   ▼
HTTP Request
   │
   ▼
Jackson
   │
   │ deserialization
   ▼
DTO
   │
   │ mapping
   ▼
Entity
   │
   │ business logic
   ▼
Entity
   │
   │ JPA/Hibernate
   ▼
SQL
   │
   ▼
Database
```

### GET

```text
Database
   │
   │ database row
   ▼
JPA/Hibernate
   │
   │ ORM mapping
   ▼
Entity
   │
   ▼
Controller
   │
   │ Jackson serialization
   ▼
JSON
   │
   ▼
HTTP Response
   │
   ▼
Frontend
```

---

# 11. The four concepts you should keep separate

This is where people commonly mix things up.

|Operation|What happens|
|---|---|
|JSON → DTO|**Deserialization**|
|DTO → Entity|**Mapping**|
|Entity → Database|**ORM/JPA persistence**|
|Database → Entity|**ORM/JPA mapping**|
|Entity → JSON|**Serialization**|

So your mental model should be:

```text
JSON
 ↕
Serialization / Deserialization
 ↕
Java Objects

Java Object
 ↕
Mapping
 ↕
Other Java Object

Java Entity
 ↕
ORM
 ↕
Database
```

### The most important distinction

**Serialization is about representation.**

**Mapping is about transformation between models.**

**ORM is about translating object state ↔ relational database state.**

That's why `DTO → Entity` isn't serialization, and `Entity → database` isn't simply serialization.

[[Serialization]]