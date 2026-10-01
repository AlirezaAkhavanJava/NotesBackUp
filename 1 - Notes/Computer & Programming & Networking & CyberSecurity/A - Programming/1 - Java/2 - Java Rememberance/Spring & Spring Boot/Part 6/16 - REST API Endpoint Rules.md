
REST endpoint design becomes much easier if you treat the URL as **a description of resources**, not as a description of actions.

## REST API Endpoint Rules

### 1. Use nouns, not verbs

The endpoint identifies **what resource you're dealing with**.

```http
GET    /users
GET    /users/42
POST   /users
PUT    /users/42
DELETE /users/42
```

Avoid:

```http
GET  /getUsers
POST /createUser
POST /deleteUser
POST /updateUser
```

The HTTP method already describes the operation.

---

### 2. Use HTTP methods correctly

|Method|Meaning|Example|
|---|---|---|
|`GET`|Retrieve|`GET /tasks/42`|
|`POST`|Create|`POST /tasks`|
|`PUT`|Replace|`PUT /tasks/42`|
|`PATCH`|Partially modify|`PATCH /tasks/42`|
|`DELETE`|Delete|`DELETE /tasks/42`|

Mental model:

```text
HTTP method = what you want to do
URL          = what you want to do it to
```

So:

```http
DELETE /tasks/42
```

means:

> Delete task 42.

You don't need:

```http
POST /deleteTask/42
```

---

# 3. Use plural resource names

Prefer:

```http
/users
/tasks
/orders
/products
/comments
```

rather than:

```http
/user
/task
/order
/product
/comment
```

This gives you a consistent collection/resource model:

```text
/tasks       → collection of tasks
/tasks/42    → one particular task
```

---

# 4. Use IDs to identify individual resources

```http
GET /tasks/42
GET /users/17
GET /orders/923
```

The structure is:

```text
/collection/{resource-id}
```

For example:

```http
GET /tasks/42
```

means:

```text
tasks
  └── task whose ID = 42
```

---

# 5. Collections and individual resources

This distinction is extremely important.

### Collection

```http
GET /tasks
```

Means:

> Give me the collection of tasks.

### Individual resource

```http
GET /tasks/42
```

Means:

> Give me task 42.

Likewise:

```http
POST /tasks
```

creates a new task **inside the collection**.

```http
DELETE /tasks/42
```

deletes one resource.

---

# 6. Use path parameters for resource identity

Good:

```http
GET /users/42
GET /tasks/123
GET /products/987
```

Bad:

```http
GET /users?id=42
GET /tasks?id=123
```

Query parameters are generally for **filtering, searching, sorting, pagination, etc.**

Path:

```text
/tasks/42
```

means:

> This exact resource.

Query:

```text
/tasks?status=COMPLETED
```

means:

> Tasks matching this condition.

---

# 7. Use query parameters for filtering

```http
GET /tasks?status=COMPLETED
```

```http
GET /tasks?priority=HIGH
```

Multiple filters:

```http
GET /tasks?status=COMPLETED&priority=HIGH
```

Search:

```http
GET /users?search=alireza
```

---

# 8. Use query parameters for pagination

For example:

```http
GET /tasks?page=0&size=20
```

or:

```http
GET /tasks?limit=20&offset=40
```

Don't create endpoints like:

```http
GET /tasks/page/2
```

unless you have a specific reason for path-based pagination.

---

# 9. Use query parameters for sorting

```http
GET /tasks?sort=dueDate
```

Descending:

```http
GET /tasks?sort=-dueDate
```

Or explicitly:

```http
GET /tasks?sort=dueDate&direction=desc
```

The exact convention is yours; **consistency** matters.

---

# 10. Nested resources represent relationships

Suppose a user owns tasks.

You can represent:

```http
GET /users/42/tasks
```

Meaning:

> Give me the tasks belonging to user 42.

And:

```http
GET /users/42/tasks/7
```

Meaning:

> Give me task 7 belonging to user 42.

Other examples:

```http
GET /orders/123/items
GET /posts/55/comments
GET /courses/10/students
```

---

# 11. Don't nest unnecessarily deeply

Avoid monsters like:

```http
/users/42/orders/123/items/7/reviews/2
```

Deep nesting makes APIs harder to use.

Often this is enough:

```http
GET /reviews/2
```

The resource itself can contain its relationships.

A practical rule:

```text
1–2 levels of nesting → usually fine
3+ levels             → reconsider the design
```

---

# 12. Actions that aren't CRUD need special treatment

This is where people get confused.

Suppose you want to complete a task.

You could do:

```http
PATCH /tasks/42
```

with:

```json
{
  "status": "COMPLETED"
}
```

This is usually a clean REST-style design because you're modifying the resource.

But some operations genuinely represent an action:

```text
POST /tasks/42/archive
POST /users/42/activate
POST /orders/123/cancel
```

These are sometimes called **action endpoints**.

Don't blindly force everything into CRUD.

---

# 13. Don't put the HTTP method into the URL

Bad:

```http
GET  /getTasks
POST /createTask
POST /updateTask
POST /deleteTask
```

Good:

```http
GET    /tasks
POST   /tasks
PUT    /tasks/42
PATCH  /tasks/42
DELETE /tasks/42
```

---

# 14. Use consistent naming

Pick a convention and stick to it.

Good:

```text
/task-items
/user-profiles
/order-items
```

Avoid mixing:

```text
/userProfiles
/task-items
/order_items
```

For REST APIs, lowercase paths with hyphens are a common convention:

```http
/api/v1/user-profiles
/api/v1/order-items
```

---

# 15. Version your API deliberately

A common approach:

```http
/api/v1/tasks
/api/v1/users
```

Then a breaking version:

```http
/api/v2/tasks
```

Don't version every tiny change.

For example, adding an optional response field normally shouldn't require:

```text
v2
```

Breaking changes are where versioning becomes important.

---

# 16. HTTP status codes are part of endpoint design

Don't return `200 OK` for everything.

### Successful retrieval

```http
GET /tasks/42
→ 200 OK
```

### Successful creation

```http
POST /tasks
→ 201 Created
```

### Successful deletion

```http
DELETE /tasks/42
→ 204 No Content
```

### Invalid request

```http
POST /tasks
→ 400 Bad Request
```

### Unauthenticated

```http
GET /tasks
→ 401 Unauthorized
```

### Authenticated but forbidden

```http
GET /admin/users
→ 403 Forbidden
```

### Resource doesn't exist

```http
GET /tasks/999999
→ 404 Not Found
```

---

# 17. Don't encode state in the URL

Avoid:

```http
GET /tasks/completed
GET /tasks/pending
GET /tasks/high-priority
```

Prefer:

```http
GET /tasks?status=COMPLETED
GET /tasks?status=PENDING
GET /tasks?priority=HIGH
```

Because `completed`, `pending`, and `high-priority` are **properties/filters**, not necessarily separate resource types.

---

# 18. Think about idempotency

This is an important professional-level rule.

An operation is **idempotent** if performing it multiple times has the same intended result as performing it once.

Generally:

```text
GET     → idempotent
PUT     → idempotent
DELETE  → idempotent
PATCH   → depends on operation
POST    → generally not idempotent
```

For example:

```http
PUT /users/42
```

with:

```json
{
  "name": "Alireza"
}
```

Calling it once:

```text
name = Alireza
```

Calling it 10 times:

```text
name = Alireza
```

Same resulting state.

But:

```http
POST /orders
```

could create:

```text
Order #1
Order #2
Order #3
...
```

---

# 19. Don't expose your database structure blindly

Your REST API is an **interface**, not necessarily a mirror of your database.

Database:

```text
tbl_usr
tbl_usr_addr
usr_task_rel
```

API:

```http
/users
/users/42
/users/42/tasks
```

Your database schema can change without necessarily breaking API consumers.

This is one reason DTOs are useful in Spring Boot.

---

# 20. Don't make endpoints represent Java methods

This is a common beginner mistake.

Your controller might contain:

```java
createTask()
getTask()
deleteTask()
completeTask()
```

But that does **not** mean your API should become:

```http
POST /createTask
GET  /getTask
DELETE /deleteTask
POST /completeTask
```

The Java method is an implementation detail.

The HTTP interface should represent resources.

---

# A Complete Example

Suppose you're designing your `DoItLater` API.

A clean structure could be:

```http
GET    /api/v1/tasks
GET    /api/v1/tasks/{id}

POST   /api/v1/tasks

PUT    /api/v1/tasks/{id}
PATCH  /api/v1/tasks/{id}

DELETE /api/v1/tasks/{id}
```

Filtering:

```http
GET /api/v1/tasks?status=TODO
GET /api/v1/tasks?priority=HIGH
GET /api/v1/tasks?dueDate=2026-10-01
```

Pagination:

```http
GET /api/v1/tasks?page=0&size=20
```

Sorting:

```http
GET /api/v1/tasks?sort=dueDate&direction=asc
```

User-specific:

```http
GET /api/v1/users/{userId}/tasks
```

Action when appropriate:

```http
POST /api/v1/tasks/{id}/archive
```

---

# The Mental Model

When designing an endpoint, ask these questions **in order**:

```text
1. What is the RESOURCE?
        ↓
2. Is it a collection or one resource?
        ↓
3. What HTTP METHOD describes the operation?
        ↓
4. Does the resource need an ID?
        ↓
5. Are these conditions/filtering?
        → query parameters
        ↓
6. Is this a relationship?
        → nested resource
        ↓
7. Is this genuinely an action that isn't ordinary CRUD?
        → action endpoint
```

So:

```text
"Get all completed tasks"

RESOURCE = tasks
COLLECTION = yes
OPERATION = read
FILTER = status=COMPLETED

                ↓

GET /tasks?status=COMPLETED
```

While:

```text
"Delete task 42"

RESOURCE = tasks
RESOURCE ID = 42
OPERATION = delete

                ↓

DELETE /tasks/42
```

And:

```text
"Change task 42's status to COMPLETED"

RESOURCE = tasks
RESOURCE ID = 42
OPERATION = modify

                ↓

PATCH /tasks/42
```

with:

```json
{
  "status": "COMPLETED"
}
```

## The short rulebook

```text
URL       → resource
HTTP verb → operation
Path ID   → identity
Query     → filtering / searching / sorting / pagination
Nesting   → relationship
Body      → resource representation / modification data
Status    → result of the operation
```

If you remember only one sentence:

> **Design the URL around nouns/resources, and let HTTP methods describe the action.**

[[0 - Spring Framework]]