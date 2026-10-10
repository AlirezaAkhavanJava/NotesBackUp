

## The one-sentence difference

- **`@PathVariable`** answers: **"WHICH thing?"** (identity)
- **`@RequestParam`** answers: **"HOW do you want it?"** (options)

## A simpler way to picture it

Imagine ordering from a **library**:

> "Give me **book #5**, **sorted by chapter**, **in large print**."

- **Book #5** is _which_ book. Without it you're asking for a different book, or no book at all. → **path**
- **Sorted by chapter, large print** are _options_. It's still book #5 either way, just presented differently. → **query params**

In a URL:

```
/books/5?sort=chapter&print=large
        │            │
   PathVariable   RequestParam
   (which book)   (how to show it)
```

## Side by side in code

```java
@GetMapping("/books/{id}")                 // PathVariable → identity
public Book one(@PathVariable Long id) { ... }

@GetMapping("/books")                      // RequestParam → filter/options
public List<Book> list(
        @RequestParam(required = false) String author,
        @RequestParam(defaultValue = "0") int page) { ... }
```

```bash
curl http://localhost:8080/books/5                      # one specific book
curl "http://localhost:8080/books?author=Tolkien&page=1"  # a filtered list
```

## The decision test

**"If I delete this value from the URL, does it point to a different thing, or the same thing shown differently?"**

|URL|Remove the value|Result|Use|
|---|---|---|---|
|`/books/5`|`/books/`|A different thing (the whole collection)|**Path**|
|`/books?author=Tolkien`|`/books`|Same collection, just unfiltered|**Query param**|
|`/books?page=2`|`/books`|Same collection, first page|**Query param**|

## How they behave differently (the mechanics)

||`@PathVariable`|`@RequestParam`|
|---|---|---|
|Position in URL|Inside the path: `/users/5`|After `?`: `/users?role=admin`|
|Declared in the mapping?|**Yes**, needs `{id}` placeholder|**No**, nothing in the mapping path|
|Can it be missing?|Not really: the URL would not match → **404**|Yes: `required=false` or `defaultValue`|
|Default value support|None|`defaultValue`|
|Missing when required|404 (no route matches)|400 Bad Request|
|Many optional values|Awkward|Natural (`?a=1&b=2&c=3`)|
|Order matters?|Yes (position in path)|No (`?a=1&b=2` = `?b=2&a=1`)|
|Can carry a list?|Not cleanly|Yes (`?ids=1,2,3`)|

The mapping difference is the key to why they feel different:

```java
@GetMapping("/users/{id}")       // {id} MUST appear in the path string
public User a(@PathVariable Long id) { ... }

@GetMapping("/users")            // no placeholder: params are not part of the route
public List<User> b(@RequestParam String role) { ... }
```

A `@PathVariable` is part of the **route itself**. A `@RequestParam` is extra information riding along **after** the route has already been matched.

## Why this convention exists (the "why")

**1. Routing and meaning.** A path is a _resource address_. `/users/5` is a stable name for user 5. Query strings describe a _view_ of a resource, so they're the right place for filters, sorting, and paging.

**2. Combinations explode in the path.** Imagine filtering with path variables: `/users/admin/active/page/2/size/10/sort/name`. Now the order matters, you can't skip anything, and every combination needs its own mapping. With query params, any subset works in any order: `/users?role=admin&page=2`.

**3. Optionality.** A path segment can't be "skipped" cleanly, but a query param can simply be left out.

**4. Caching and bookmarking.** Servers, proxies, and browsers treat `/users/5` as one clearly identified resource, which is why REST APIs use paths for identity.

## Using both together (the normal real-world case)

```java
@GetMapping("/users/{userId}/orders")
public List<Order> orders(
        @PathVariable Long userId,                       // WHICH user
        @RequestParam(required = false) String status,   // filter
        @RequestParam(defaultValue = "0") int page) {    // paging
    return service.findOrders(userId, status, page);
}
```

```bash
curl "http://localhost:8080/users/5/orders?status=paid&page=2"
```

Read it aloud: _"Orders of user 5, only paid ones, page 2."_ The identity is in the path, the options are in the query.

## Nuances and gotchas

**They can technically do the same job.** `/users?id=5` with `@RequestParam` works just as well as `/users/5`. Spring doesn't force you. The difference is **convention and design quality**, not capability. A REST API that fetches a single resource by query param works but looks unprofessional.

**Wrong choice symptoms:**

- Used a path variable for a filter (`/users/admin`): it clashes with other routes and can't be combined with other filters.
- Used a request param for identity (`/users?id=5`): the URL doesn't read as "a resource", and caching/linking suffers.

**Type errors look the same.** Both give **400** for a bad type (`/users/abc` or `?page=abc` for numbers).

**A missing path variable is a 404, not a 400.** That's a useful tell: path variables are part of _which route exists_, query params are part of _how a route is called_.

**A path variable cannot contain `/`.** `{name}` matches one segment only. Query param values can contain almost anything (once URL-encoded).

**Sensitive data goes in neither.** Both appear in logs and browser history.

## Quick cheat sheet

|You want to...|Use|
|---|---|
|Fetch/update/delete **one specific** item|`@PathVariable` → `/users/{id}`|
|**Filter** a list|`@RequestParam` → `?role=admin`|
|**Sort** a list|`@RequestParam` → `?sort=name`|
|**Paginate**|`@RequestParam` → `?page=2&size=10`|
|**Search** text|`@RequestParam` → `?q=spring`|
|Point to a **child** of something|`@PathVariable` → `/users/{id}/orders`|
|Send a **JSON object**|neither, use `@RequestBody`|




[[Spring Framework]]