

## Simple mental model

A URI is a **name tag for a resource**. It answers: _"how do I point at that thing?"_

You've already used URIs all along: `/api/users/7` is one. In the last topic, `ResponseEntity.created(location)` needed a `URI` for the `Location` header, which tells the client: _"I created your new user, and you can find it here."_

## URI vs URL vs URN

- **URI** (Uniform Resource **Identifier**) is the umbrella term: anything that identifies a resource.
- **URL** (Locator) is a URI that also says _where/how to get it_: `https://example.com/users/7`.
- **URN** (Name) is a URI that only _names_ something, without a location: `urn:isbn:9780134685991`.

Every URL is a URI, but not every URI is a URL. In everyday web work they are used almost interchangeably, and REST APIs mostly deal with URLs. Think of it like a person: a URI is "identifies a person", a URL is "identifies a person _by their home address_", a URN is "identifies a person _by their passport number_".

## Anatomy

```
https://alireza:secret@example.com:8080/api/users/7?role=admin&page=2#details
└─┬──┘   └────┬──────┘ └────┬─────┘└┬─┘└────┬─────┘ └─────┬───────┘ └──┬──┘
scheme    userinfo        host    port   path           query       fragment
```

|Part|Example|Notes|
|---|---|---|
|scheme|`https`|the protocol/type|
|userinfo|`alireza:secret`|rarely used, and insecure|
|host|`example.com`||
|port|`8080`|omitted = default (80/443)|
|path|`/api/users/7`|what `@PathVariable` reads|
|query|`role=admin&page=2`|what `@RequestParam` reads|
|fragment|`details`|**never sent to the server**, browser-only|

This is also why you learned `@PathVariable` and `@RequestParam` as different things: they read different parts of the URI.

## `java.net.URI` in Java

`URI` is an **immutable** class from the standard library that parses and holds those parts.

```java
URI uri = URI.create("https://example.com:8080/api/users/7?role=admin#top");

uri.getScheme();     // "https"
uri.getHost();       // "example.com"
uri.getPort();       // 8080
uri.getPath();       // "/api/users/7"
uri.getQuery();      // "role=admin"
uri.getFragment();   // "top"
```

### Two ways to create one

```java
URI a = URI.create("/api/users/7");                 // throws unchecked IllegalArgumentException if invalid
URI b = new URI("https", "example.com", "/api/users/7", null);  // throws checked URISyntaxException
```

`URI.create(...)` is the convenient one. The multi-argument constructors **encode illegal characters for you** (spaces, non-ASCII), whereas the single-string forms expect an already valid string.

### Resolving relative URIs

```java
URI base = URI.create("http://localhost:8080/api/users/");
URI full = base.resolve("7");        // http://localhost:8080/api/users/7
```

Note the trailing slash on `base`. Without it, `resolve("7")` _replaces_ the last segment (`users`) and you get `/api/7`. This is the same rule as browser relative links.

## How it appears in Spring: the `Location` header

After a successful POST, REST convention is **201 Created + a `Location` header pointing at the new resource**.

```java
@PostMapping
public ResponseEntity<User> create(@Valid @RequestBody UserDto dto) {
    User saved = service.create(dto);
    URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(saved.getId())
            .toUri();
    return ResponseEntity.created(location).body(saved);
}
```

Step by step, for `POST http://localhost:8080/api/users`:

1. `fromCurrentRequest()` starts from the current request URL: `http://localhost:8080/api/users`
2. `.path("/{id}")` appends a template: `.../api/users/{id}`
3. `.buildAndExpand(7)` fills the placeholder: `.../api/users/7`
4. `.toUri()` turns it into a `URI`

Result: `Location: http://localhost:8080/api/users/7`

**Why this builder instead of string concatenation?** It automatically uses the right host, port, and scheme (even behind a proxy with `X-Forwarded-*` headers, when configured), and it **encodes values safely**. Hardcoding `"http://localhost:8080/..."` breaks the moment you deploy.

### The builder family

```java
// Based on the current request (only works inside a request thread)
ServletUriComponentsBuilder.fromCurrentRequest()          // includes the query string!
ServletUriComponentsBuilder.fromCurrentRequestUri()       // without the query string
ServletUriComponentsBuilder.fromCurrentContextPath()      // just scheme://host:port/contextPath

// From scratch (works anywhere, e.g. building a link to an external API)
UriComponentsBuilder.fromUriString("https://api.example.com/users/{id}")
        .queryParam("expand", "orders")
        .buildAndExpand(7)
        .toUri();
// https://api.example.com/users/7?expand=orders
```

### Encoding in practice

```java
UriComponentsBuilder.fromUriString("https://example.com/search")
        .queryParam("q", "spring boot")
        .encode()
        .build()
        .toUri();
// https://example.com/search?q=spring%20boot
```

A space becomes `%20`. This is called **percent-encoding**, and it's why you should never concatenate user input into URLs by hand.

## Nuances and gotchas

**1. `fromCurrentRequest()` keeps the query string.** If the client posts to `/api/users?notify=true`, your `Location` becomes `/api/users/7?notify=true`, which is usually wrong. Prefer `fromCurrentRequestUri()` for `Location` headers.

**2. `URI` vs `URL` in Java are different classes.**

- `java.net.URI` only _parses and holds text_. It never touches the network.
- `java.net.URL` can _open connections_ (`openStream()`), and its old `equals`/`hashCode` can do **DNS lookups**, which is a notorious pitfall.
- Convert with `uri.toURL()`. Since Java 20, `new URL(String)` is deprecated, so the modern idiom is `URI.create(s).toURL()`.

**3. `URI.create` throws on invalid input.** `URI.create("http://bad url")` (a space) → `IllegalArgumentException`. Never feed it raw user input without validation.

**4. Relative vs absolute `Location`.** HTTP allows a relative `Location` (`/api/users/7`), but absolute is the safest and most common. Using the builder gives you absolute for free.

**5. Fragments never reach your server.** `/page#section` sends only `/page`. So you cannot read the fragment in a controller; it's browser-side only.

**6. Path variables and encoded slashes.** A `%2F` inside a value is usually rejected (as mentioned in `@PathVariable`), so don't put slashes inside identifiers.

**7. `URI` is immutable.** Methods like `resolve` return a _new_ URI. You never modify one in place.

**8. Comparison.** `URI.equals` compares components case-sensitively in parts (scheme and host are case-insensitive, path is case-sensitive), so `HTTP://Example.com/a` equals `http://example.com/a`, but `/A` does not equal `/a`.

## Quick reference

|You want|Code|
|---|---|
|Parse a string|`URI.create("...")`|
|Read parts|`getScheme()`, `getHost()`, `getPort()`, `getPath()`, `getQuery()`|
|Combine base + relative|`base.resolve("7")`|
|Location of new resource|`ServletUriComponentsBuilder.fromCurrentRequestUri().path("/{id}").buildAndExpand(id).toUri()`|
|Build with query params|`UriComponentsBuilder.fromUriString(...).queryParam(k, v).build().toUri()`|
|To `URL`|`uri.toURL()`|

## How it fits

```
POST /api/users  ──►  create user  ──►  201 Created
                                         Location: http://localhost:8080/api/users/7
                                                   └──────── a URI ────────┘
```

The client can now `GET` that exact URI to fetch the new user. This is the REST idea of **hypermedia in miniature**: the server tells you where things live instead of the client guessing.




[[Spring Framework]]