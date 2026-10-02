



We've touched this in the REST overview and URL formatting tutorials. Let's now go deeper — this pairing (nouns + verbs) is the actual foundation of REST, so it's worth mastering properly rather than treating as a quick recap.

---

## 1. The Core Mental Model

REST flips how most beginners think about APIs. Coming from procedural code, your instinct is to think in **actions**: "create a book," "get a book," "delete a book." REST asks you to separate that into two independent pieces:

```
NOUN (resource)  +  VERB (HTTP method)  =  the action
     /books       +       POST          =  "create a book"
     /books/{id}  +       DELETE        =  "delete a book"
```

The noun never changes based on what you're doing to it. Only the verb changes. This is the single biggest mindset shift when learning REST.

---

## 2. Resources (Nouns) — Identifying Them Correctly

### What makes something a resource?

Go back to our Domain Overview glossary — **anything with identity and independent existence in your domain is a candidate resource.** From our Library example:

|Domain concept|Resource?|URL|
|---|---|---|
|Book|Yes — has identity, lifecycle|`/books`|
|Loan|Yes — has identity, its own lifecycle|`/loans`|
|Member|Yes|`/members`|
|"borrow"|**No** — this is an action, not a noun|Becomes `POST /loans`, not `/borrow`|
|dueDate|**No** — just an attribute of Loan|Not its own resource|

This is exactly the entity-vs-attribute distinction from our Domain Model tutorial — resources map almost 1:1 to your domain entities, not to every noun you can think of.

### Collection resources vs. singleton resources

Most resources are **collections** with individual **members**:

```
/books           → collection resource (all books)
/books/{id}      → singleton member of that collection (one book)
```

Occasionally you have a true **singleton resource** — something where there's only ever one, no collection makes sense:

```
GET /members/{id}/profile      → a member has exactly one profile, not many
GET /system/health             → there's only one system health status
```

You don't pluralize these because "multiple" doesn't conceptually exist.

### The "verb in the noun" trap

This is the #1 beginner mistake, and you'll see it constantly in real (badly-designed) codebases:

```
❌ /getBooks
❌ /createBook
❌ /deleteBookById
❌ /books/delete/{id}
❌ /updateBookTitle
```

Every one of these smuggles a verb into the URL — meaning the HTTP method becomes redundant or actively contradicts the URL (`POST /books/delete/{id}` — is it creating or deleting?). Once you fix the URL to be a pure noun, the HTTP method carries all the "verb" meaning on its own:

```
✅ GET    /books           (list)
✅ POST   /books           (create)
✅ DELETE /books/{id}      (delete)
✅ PATCH  /books/{id}      (update title, among other fields)
```

---

## 3. HTTP Verbs — Full Semantics (Not Just "What They Do")

This is where most tutorials stay shallow. Each verb carries two important _properties_ beyond "what action it performs": **safety** and **idempotency**. Understanding these changes how you design your service layer.

|Verb|Safe?|Idempotent?|Meaning|
|---|---|---|---|
|`GET`|✅ Yes|✅ Yes|Read-only, no side effects, repeatable forever|
|`HEAD`|✅ Yes|✅ Yes|Like GET, but headers only, no body|
|`OPTIONS`|✅ Yes|✅ Yes|"What methods does this endpoint support?"|
|`POST`|❌ No|❌ No|Create / trigger an action — **not** safe to repeat blindly|
|`PUT`|❌ No|✅ Yes|Replace entirely — repeating it has the same end result|
|`PATCH`|❌ No|⚠️ Usually not|Partial update — repeating _can_ differ depending on what changed|
|`DELETE`|❌ No|✅ Yes|Remove — deleting an already-deleted resource is still "gone"|

### What "safe" means

A **safe** method causes no state change on the server — you could call it a million times and nothing changes except reads happening. This is why browsers, proxies, and search engine crawlers are allowed to call `GET` freely without asking permission — and why you should _never_ implement a `GET` endpoint that secretly deletes data or has side effects. That breaks a fundamental contract every HTTP client relies on.

### What "idempotent" means

An **idempotent** method produces the same end state no matter how many times you call it with the same input.

```
PUT /books/{id}  { "title": "Effective Java", "author": "Bloch" }
```

Call this once, or five times in a row — the book ends up in the exact same state. This matters practically: if a client's network request times out and it's unsure whether the server received it, it can safely **retry** a `PUT` or `DELETE` without fear of corrupting data (e.g., accidentally creating five books, or double-decrementing a copy count).

`POST` is _not_ idempotent — calling `POST /loans` twice creates **two** loans, not one. This is exactly why retry logic must be handled carefully for `POST` (often via an idempotency key, a more advanced topic) but can be automatic and safe for `PUT`/`DELETE`.

---

## 4. `PUT` vs `PATCH` — The Distinction People Get Wrong

This deserves its own section because it's commonly misused even in production codebases.

### `PUT` — full replacement

The request body must contain **every** field. Any field you omit is treated as if you intend to remove/reset it.

```java
@PutMapping("/{id}")
public BookDto replace(@PathVariable UUID id, @RequestBody BookDto fullBook) {
    return bookService.replace(id, fullBook); // expects title, author, isbn — all of it
}
```

```
PUT /books/9b1deb4d-...
{ "title": "Effective Java", "author": "Joshua Bloch", "isbn": "978-0134685991" }
```

If you sent only `{ "title": "..." }` via `PUT`, a strict implementation should treat `author` and `isbn` as now-null — which is almost never what a client actually wants. This is exactly why `PUT` is used far less often in practice than `PATCH`.

### `PATCH` — partial update

Only the fields you send get changed; everything else stays as-is.

```java
@PatchMapping("/{id}")
public BookDto updatePartial(@PathVariable UUID id, @RequestBody Map<String, Object> updates) {
    return bookService.applyPatch(id, updates);
}
```

```
PATCH /books/9b1deb4d-...
{ "title": "Effective Java, 3rd Edition" }
```

Only `title` changes. `author` and `isbn` are untouched.

**Practical guidance:** in most Spring Boot apps, you'll reach for `PATCH` far more often than `PUT` — clients almost always want to update one or two fields, not resend the entire object. Many real-world APIs (including well-known ones) skip `PUT` entirely and just use `PATCH` for all updates. That's a completely reasonable simplification for a learning project.

---

## 5. When an Action Doesn't Fit CRUD — Handling "Non-Noun" Operations

Real domains have actions that don't map cleanly to create/read/update/delete. Our Library app has a great example: **returning** a book isn't quite "updating a Loan" in the user's mental model, even though technically it is.

Three accepted patterns, in order of REST-purity:

### Pattern A — Model it as a state change (most RESTful)

Treat "return" as an update to the Loan's status — stays fully within CRUD:

```
PATCH /loans/{id}
{ "status": "RETURNED" }
```

### Pattern B — Sub-resource representing the action

Treat the action itself as a resource you're "creating":

```
POST /loans/{id}/return
```

Here, `/return` isn't really a verb-in-URL violation — it's shorthand for "the event of this loan being returned," which many teams treat as an acceptable pragmatic exception, especially for actions that don't map to a clean field update (e.g., `POST /orders/{id}/cancel`, `POST /accounts/{id}/activate`).

### Pattern C — A dedicated action resource (most formal)

Model the action itself as a first-class resource with its own history:

```
POST /returns
{ "loanId": "..." }
```

This creates a `Return` record — useful if "returns" themselves need to be tracked, audited, or queried independently (e.g., "show me all returns processed today").

**Practical guidance:** Pattern A is cleanest when the action truly is just a status change. Pattern B is the most common pragmatic choice in real APIs when the action has meaningful side effects (like our Loan return decrementing a due-date check, incrementing available copies, etc.) beyond a single field flip.

```java
@PostMapping("/{id}/return")
public LoanDto returnBook(@PathVariable UUID id) {
    return loanService.returnBook(id);
}
```

---

## 6. Full Verb Reference, Applied to the Library Domain

|Verb|URL|Meaning|Idempotent?|
|---|---|---|---|
|`GET`|`/books`|List all books|✅|
|`GET`|`/books/{id}`|Get one book|✅|
|`GET`|`/books?author=Bloch`|Filter books|✅|
|`POST`|`/books`|Create a new book|❌|
|`PATCH`|`/books/{id}`|Update part of a book|⚠️ depends|
|`PUT`|`/books/{id}`|Replace a book entirely|✅|
|`DELETE`|`/books/{id}`|Remove a book|✅|
|`POST`|`/loans`|Borrow a book (create a Loan)|❌|
|`POST`|`/loans/{id}/return`|Return a book (action pattern)|⚠️ arguably ✅ if truly idempotent|
|`GET`|`/members/{id}/loans`|List a member's loans|✅|

---

## 7. Quick Decision Checklist

When designing a new endpoint, ask in order:

1. **What's the noun?** → this becomes your URL path (`/loans`)
2. **Am I reading, creating, replacing, partially updating, or deleting?** → pick `GET`/`POST`/`PUT`/`PATCH`/`DELETE` accordingly
3. **Does this action not cleanly fit CRUD?** → use the sub-resource action pattern (`POST /loans/{id}/return`) rather than inventing a verb in the main noun path
4. **Could a client safely retry this request if the network dropped?** → if not, and it should be safe to retry, reconsider whether it should be `PUT`/`DELETE` instead of `POST`

---

## Quick Summary

1. **URLs are nouns** (resources), **HTTP methods are verbs** — never mix a verb into the path
2. `GET` is safe and idempotent — never give it side effects
3. `PUT` = idempotent full replacement; `PATCH` = usually-partial update — prefer `PATCH` in practice
4. `POST` is neither safe nor idempotent — this is exactly why it's used for "create" and "actions"
5. For actions that don't fit CRUD (like "return a book"), use a sub-resource action endpoint: `POST /resource/{id}/action-name`

---




[[Java]]
[[0 - Spring Framework]]