

## Simpler mental model

Think of a mapping annotation as a **door with a security checklist**. A request only gets into your method if it passes _every_ check you wrote:

|Check|Parameter|The question the door asks|
|---|---|---|
|Address|`path` / `value`|"Is this the right URL?"|
|Verb|`method`|"Is this GET, POST, etc.?"|
|ID card|`headers`|"Does the request carry this header?"|
|Ticket|`params`|"Does the URL contain this query parameter?"|
|Language in|`consumes`|"Is the body in a format I accept?"|
|Language out|`produces`|"Can I reply in a format the client wants?"|
|Label|`name`|(Just a nickname for the door, not a check)|

If **any** check fails, the door stays closed and Spring tries other methods. If none match, you get an error (the error codes are listed below).

---

## 1. `path` / `value`: the URL

`value` and `path` are **aliases**: they mean exactly the same thing. `value` is the default, so you can omit the name.

```java
@GetMapping("/users")                    // shorthand for value = "/users"
@GetMapping(path = "/users")             // same thing
@GetMapping({"/users", "/people"})       // multiple URLs → same method
```

**Placeholders and patterns:**

```java
@GetMapping("/users/{id}")               // matches /users/5, /users/abc
@GetMapping("/users/{id:[0-9]+}")        // regex: only digits, /users/abc → 404
@GetMapping("/files/*")                  // * = exactly one path segment
@GetMapping("/files/**")                 // ** = any number of segments (/files/a/b/c)
```

**Class + method combine** by concatenation:

```java
@RequestMapping("/api/users")            // class
@GetMapping("/{id}")                     // method → final URL: /api/users/{id}
```

---

## 2. `method`: the HTTP verb

Only exists on `@RequestMapping`. The shortcuts (`@GetMapping` etc.) already have it filled in, which is why they don't offer this parameter.

```java
@RequestMapping(path = "/users", method = RequestMethod.GET)
@RequestMapping(path = "/users", method = {RequestMethod.PUT, RequestMethod.PATCH})  // either
```

Right URL but wrong verb → **405 Method Not Allowed**.

---

## 3. `params`: required query parameters (or values)

The request URL must satisfy the condition, otherwise this method is skipped (and if nothing else matches, **400 Bad Request**).

```java
@GetMapping(path = "/users", params = "role")           // must have ?role=anything
@GetMapping(path = "/users", params = "role=admin")     // must be exactly ?role=admin
@GetMapping(path = "/users", params = "role!=admin")    // role present but not admin
@GetMapping(path = "/users", params = "!debug")         // must NOT contain ?debug
@GetMapping(path = "/users", params = {"role=admin", "active=true"})  // ALL must hold
```

**Why this is useful:** the _same URL_ can go to _different methods_ depending on the query string:

```java
@GetMapping(path = "/search", params = "q")
public List<User> byText(@RequestParam String q) { ... }

@GetMapping(path = "/search", params = "email")
public User byEmail(@RequestParam String email) { ... }
```

`/search?q=ali` → first method. `/search?email=a@b.com` → second.

> Don't confuse this with `@RequestParam`. `params` is a **gate** (decides whether the method is chosen). `@RequestParam` is a **reader** (pulls the value into a Java variable). They are often used together.

---

## 4. `headers`: required HTTP headers

Same syntax as `params`, but checks headers.

```java
@GetMapping(path = "/users", headers = "X-API-VERSION=2")
public List<UserV2> listV2() { ... }

@GetMapping(path = "/users", headers = "X-API-VERSION=1")
public List<UserV1> listV1() { ... }
```

Same URL, and the client chooses the version via a header. This is **header-based API versioning**.

```java
headers = "X-Admin"          // header must exist
headers = "!X-Debug"         // header must NOT exist
headers = "X-Env!=prod"      // header present, value not "prod"
```

> `Content-Type` and `Accept` headers are better handled with `consumes`/`produces` (below), which gives proper status codes.

---

## 5. `consumes`: what the **request body** must be

"I only accept bodies of this `Content-Type`." Checked against the request's `Content-Type` header. Mainly relevant for POST/PUT/PATCH.

```java
@PostMapping(path = "/users", consumes = "application/json")
public User createFromJson(@RequestBody UserDto dto) { ... }

@PostMapping(path = "/users", consumes = "application/xml")
public User createFromXml(@RequestBody UserDto dto) { ... }
```

Better: use constants to avoid typos:

```java
consumes = MediaType.APPLICATION_JSON_VALUE
consumes = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE}  // either
consumes = "!text/plain"                                                         // anything except
```

Wrong content type → **415 Unsupported Media Type**.

Typical file-upload example:

```java
@PostMapping(path = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public String upload(@RequestParam("file") MultipartFile file) { ... }
```

---

## 6. `produces`: what the **response** will be

"I can answer in this format." Checked against the client's `Accept` header. It also sets the response `Content-Type`.

```java
@GetMapping(path = "/users/{id}", produces = "application/json")
public User json(@PathVariable Long id) { ... }

@GetMapping(path = "/users/{id}", produces = "application/xml")
public User xml(@PathVariable Long id) { ... }
```

Same URL: the client sends `Accept: application/json` and gets JSON, or `Accept: application/xml` and gets XML. This is called **content negotiation**.

Client wants something you can't produce → **406 Not Acceptable**.

---

## 7. `name`: a label for the mapping

Just a human-readable name for the mapping. It performs no check and has no effect on routing. It's used mainly by tooling (e.g. building links in views):

```java
@GetMapping(path = "/users/{id}", name = "getUser")
```

You'll rarely write this as a beginner. Safe to ignore.

---

## Putting it all together

```java
@PostMapping(
    path = "/api/users",
    consumes = MediaType.APPLICATION_JSON_VALUE,   // body must be JSON
    produces = MediaType.APPLICATION_JSON_VALUE,   // reply is JSON
    headers = "X-API-VERSION=2",                   // client must send this header
    params = "notify=true"                         // URL must be /api/users?notify=true
)
public User create(@RequestBody UserDto dto) { ... }
```

This method is reached **only** if the request is `POST /api/users?notify=true` with `Content-Type: application/json`, `Accept` compatible with JSON, **and** header `X-API-VERSION: 2`.

---

## Nuances and gotchas

**Which error means which check failed:**

|Failure|Status|
|---|---|
|URL doesn't match any `path`|404|
|URL matches but verb doesn't|405|
|`consumes` mismatch|415|
|`produces` mismatch|406|
|`params` / `headers` condition fails|400|

**Class-level vs method-level combining rules:**

- `path`: **concatenated** (`/api/users` + `/{id}`)
- `method`, `params`, `headers`: **combined** (both levels apply)
- `consumes`, `produces`: the **method-level overrides** the class-level one (not merged)

**Most specific mapping wins.** If two methods could match, Spring prefers the more specific one (e.g. `/users/me` beats `/users/{id}`, and a mapping with `params`/`consumes` beats one without). Truly identical mappings crash the app at startup with an "Ambiguous mapping" error.

**Shortcut annotations don't have `method`.** `@GetMapping(method = ...)` won't compile. That's by design.

**Arrays:** every parameter above that accepts one value also accepts several using `{ "a", "b" }`, meaning "any of these" for `path`, `method`, `consumes`, `produces`, but "**all** of these" for `params` and `headers`.





[[Spring Framework]]