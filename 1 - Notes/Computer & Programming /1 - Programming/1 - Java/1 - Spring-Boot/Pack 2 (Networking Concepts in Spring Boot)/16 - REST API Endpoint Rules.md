

A REST endpoint is a URL plus an HTTP method. The URL says **which resource** you mean (a task, a user, an order), and the method says **what to do** with it (read, create, replace, delete). If you design every endpoint around that split, your API stays small, predictable and easy for other developers to guess.

This note is the hands-on companion to Part 1 of your REST API design note. That note explained the ideas. This one gives you the rules for naming and structuring endpoints, with your `DoItLater` tasks API as the running example. The 20 rules in the original are grouped here into nine, so you can learn them in order without drowning.

---

## The one idea behind every rule

```text
HTTP method  =  what you want to do
URL          =  what you want to do it to
```

`DELETE /tasks/42` already reads as "delete task 42." You don't need `POST /deleteTask/42`, because the verb is in the method. Keep this sentence in mind and most of the rules below follow from it.

---

## 1. Name resources with plural nouns

```http
GET    /tasks            ✔
GET    /getTasks         ✘  (a verb in the URL)
POST   /createTask       ✘
```

Use **plural**, **lowercase** nouns, with hyphens for multiple words: `/tasks`, `/user-profiles`, `/order-items`. Don't mix styles (`/userProfiles` next to `/order_items`). Consistency matters more than which style you pick.

Plural gives you a clean pattern:

```text
/tasks        the collection of tasks
/tasks/42     one task, whose ID is 42
```

The Java method name is an implementation detail. A controller method called `completeTask()` doesn't mean the URL should be `/completeTask`.

---

## 2. Choose the verb by what you want to do

|Method|Meaning|Example|
|---|---|---|
|`GET`|Read|`GET /tasks/42`|
|`POST`|Create inside a collection|`POST /tasks`|
|`PUT`|**Replace** the whole resource|`PUT /tasks/42`|
|`PATCH`|Change **part** of it|`PATCH /tasks/42`|
|`DELETE`|Remove|`DELETE /tasks/42`|

**PUT versus PATCH** is the one that confuses people:

- `PUT /tasks/42` sends the **complete** task. Any field you leave out is replaced with nothing or a default.
- `PATCH /tasks/42` sends **only what changes**, such as `{ "status": "COMPLETED" }`.

For "mark a task done," PATCH is usually the better fit.

---

## 3. Path says _which one_; query says _which ones, and how_

```http
GET /tasks/42                         ← this exact task (path)
GET /tasks?status=COMPLETED           ← tasks matching a condition (query)
```

The path **identifies** a resource. The query string **narrows or shapes** a list. So `/tasks?id=42` is the wrong way to fetch one task.

Use the query string for all three of these:

```http
GET /tasks?status=COMPLETED&priority=HIGH      filtering
GET /tasks?page=0&size=20                      pagination
GET /tasks?sort=dueDate,desc                   sorting
```

Two practical notes:

- **Don't put a state in the path.** `/tasks/completed` and `/tasks/pending` are filters, so write `?status=COMPLETED`.
- **Match Spring's conventions.** Spring Data reads `page`, `size` and `sort=field,direction` automatically (see the pagination part of your REST API note). Inventing `sort=-dueDate` means writing the parsing yourself.

---

## 4. Show relationships by nesting, but keep it shallow

```http
GET /users/42/tasks        tasks that belong to user 42
GET /users/42/tasks/7      task 7 of user 42
GET /orders/123/items
GET /posts/55/comments
```

Nest when the child belongs to the parent. But deep chains such as `/users/42/orders/123/items/7/reviews/2` are painful to use. A good rule is **one or two levels of nesting**. If a resource has its own unique ID, give it a top-level URL as well, so `GET /reviews/2` is enough.

---

## 5. For actions that aren't plain CRUD

Say you want to complete a task. The cleanest approach is usually to change the resource:

```http
PATCH /tasks/42
{ "status": "COMPLETED" }
```

But some operations are truly _actions_ with side effects (sending emails, moving things around), and they don't fit "change a field." For those, an **action endpoint** is acceptable:

```http
POST /tasks/42/archive
POST /orders/123/cancel
```

Don't force everything into CRUD, but don't reach for action endpoints first. Try PATCH, and pick one style and stay consistent.

---

## 6. Let the status code say what happened

Don't return `200 OK` for everything.

|Situation|Code|
|---|---|
|Read worked|`200 OK`|
|Created (add a `Location` header)|`201 Created`|
|Deleted|`204 No Content`|
|Bad input|`400 Bad Request`|
|Not logged in|`401 Unauthorized`|
|Logged in but not allowed|`403 Forbidden`|
|It doesn't exist|`404 Not Found`|

(The full table, with 409, 412 and 422, is in your REST API note.)

### Idempotency, in one idea

An operation is **idempotent** if doing it ten times leaves the same _state_ as doing it once.

- `GET`, `PUT` and `DELETE` are idempotent. `PUT /users/42` with `{"name":"Alireza"}` ten times still leaves the name as Alireza. Even a second `DELETE` leaves the task deleted. The _response_ may differ (404 instead of 204), but the resulting state is the same.
- `PATCH` depends on what it does. Setting a status is idempotent, and "add 1 to a counter" isn't.
- `POST /orders` is not idempotent, because each call can create another order. That is why the REST API note introduced the `Idempotency-Key` header.

---

## 7. Keep your API independent of your internals

Your API is an **interface**, not a mirror of your database or your Java code.

```text
Database tables:   tbl_usr, tbl_usr_addr, usr_task_rel
API resources:     /users, /users/42, /users/42/tasks
```

If your table names change, the API doesn't have to. This is exactly why Spring Boot apps return DTOs instead of entities, as your Entity/DTO/mapper note explained.

---

## 8. Version on breaking changes only

```http
/api/v1/tasks      →   /api/v2/tasks   (only when you must break clients)
```

Adding an optional field to a response is **not** a breaking change, so it doesn't need a `v2`. Renaming or removing a field, or changing its meaning, is.

---

## 9. Think about who is asking (a rule the original missed)

This one matters for your `DoItLater` app, where every task belongs to a user.

If you expose `GET /users/{userId}/tasks`, then any logged-in user could change the number in the URL and read someone else's tasks. This flaw is common, and it has a name: _broken access control_. Two safe designs:

- **Use the logged-in user.** Expose `GET /tasks`, and have the service return only the current user's tasks. The user comes from the token, through the `Authentication` object (your Authentication and JWT notes cover how it gets into the `SecurityContext`), not from the URL.
- **If an ID stays in the URL,** check that it matches the authenticated user and return 403 or 404 otherwise.

Some APIs also add a shortcut such as `GET /users/me`. It reads naturally and never takes a user ID from the client.

---

## Putting it together: the `DoItLater` tasks API

```http
GET    /api/v1/tasks                         list (current user's tasks)
GET    /api/v1/tasks/{id}                    one task
POST   /api/v1/tasks                         create  → 201 + Location
PUT    /api/v1/tasks/{id}                    replace
PATCH  /api/v1/tasks/{id}                    change part, e.g. {"status":"COMPLETED"}
DELETE /api/v1/tasks/{id}                    delete  → 204

GET    /api/v1/tasks?status=TODO&priority=HIGH      filter
GET    /api/v1/tasks?page=0&size=20&sort=dueDate,asc   paginate and sort
POST   /api/v1/tasks/{id}/archive                   action, when it's truly an action
```

And the Spring controller skeleton that matches it:

```java
@RestController
@RequestMapping("/api/v1/tasks")
public class TaskController {

    @GetMapping                         // GET /api/v1/tasks?status=...&page=...
    public Page<TaskResponse> list(@RequestParam(required = false) TaskStatus status,
                                   Pageable pageable) { ... }

    @GetMapping("/{id}")                // GET /api/v1/tasks/42
    public TaskResponse get(@PathVariable Long id) { ... }

    @PostMapping                        // POST /api/v1/tasks
    public ResponseEntity<TaskResponse> create(@Valid @RequestBody CreateTaskRequest request) { ... }

    @PatchMapping("/{id}")              // PATCH /api/v1/tasks/42
    public TaskResponse update(@PathVariable Long id, @RequestBody UpdateTaskRequest request) { ... }

    @DeleteMapping("/{id}")             // DELETE /api/v1/tasks/42
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) { ... }
}
```

Each annotation maps one row of the table above to one method. That is the whole connection between the design rules and your Spring Web controllers.

---

## A way to design any endpoint: ask in order

```text
1. What is the RESOURCE?               → the noun (tasks)
2. One item or the collection?         → /tasks or /tasks/{id}
3. What do I want to do?               → the HTTP method
4. Am I narrowing, sorting or paging?  → query parameters
5. Is it a relationship?               → nest it (1–2 levels)
6. Is it a real action, not CRUD?      → try PATCH first, then an action endpoint
7. Whose data is this?                 → derive the user from the token
```

Try it: "Get all completed tasks" gives resource = tasks, collection, read, filter by status, so `GET /tasks?status=COMPLETED`. "Mark task 42 completed" gives resource = tasks, item 42, modify, so `PATCH /tasks/42` with `{"status":"COMPLETED"}`.




[[Spring Framework]]