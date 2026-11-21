

The `Location` header is an HTTP response header whose value is a URI pointing to a resource. It shows up in two very different situations, and people often confuse them because the header name is the same:

1. **201 Created** — "here's where to find the thing you just made."
2. **3xx Redirect** (301, 302, 303, 307, 308) — "go look here instead."

Both uses share the same header, but the _meaning_ and the _client behavior_ are completely different, so it's worth treating them as two separate concepts.

## `Location` on a 201 Created

When a client sends `POST /users` to create a new user, the server doesn't just say "success" — it tells the client exactly where the new resource now lives. That's the whole point: before the POST, the resource didn't have a URL. After it, it does, and the client has no way of knowing that URL unless the server tells it.

```
HTTP/1.1 201 Created
Location: https://api.example.com/users/42
Content-Type: application/json

{ "id": 42, "name": "..." }
```

The client can now do `GET /users/42` whenever it wants, without the server inventing that ID for it in some other side channel.

In Spring Boot, you build this with `URI` + `ResponseEntity.created(...)`, exactly as in the earlier controller example:

```java
@PostMapping
public ResponseEntity<UserDto> createUser(@RequestBody UserDto dto) {
    User saved = userService.save(dto);

    URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(saved.getId())
            .toUri();

    return ResponseEntity.created(location).body(toDto(saved));
}
```

`fromCurrentRequest()` grabs the URL of the current request (`.../users`) and `.path("/{id}")` appends the new ID onto it, so you don't have to hardcode the base path — if your app moves from `api.example.com` to a new domain, this code doesn't need to change.

`ResponseEntity.created(URI location)` is a shortcut for:

```java
ResponseEntity.status(HttpStatus.CREATED).location(location).body(dto)
```

Both do the same thing — set status 201 and set the `Location` header — `created()` is just less typing for the common case.

## `Location` on a redirect

The other use is telling the client "the resource you asked for isn't here, it's over there." The server responds with a 3xx status and a `Location` header pointing at the new place, and the browser (or HTTP client) follows it automatically.

```
HTTP/1.1 302 Found
Location: https://example.com/new-page
```

In Spring MVC, you don't usually build this `URI` by hand — the `redirect:` prefix in a view name, or `RedirectView`, handles it:

```java
@GetMapping("/old-page")
public String oldPage() {
    return "redirect:/new-page";
}
```

Spring sets the `Location` header and the 3xx status for you behind the scenes. You only drop down to manually building a `URI` for a redirect when you need to construct the target dynamically:

```java
@GetMapping("/go")
public ResponseEntity<Void> redirectDynamically(@RequestParam String target) {
    URI uri = UriComponentsBuilder.fromUriString(target).build().toUri();
    return ResponseEntity.status(HttpStatus.FOUND).location(uri).build();
}
```

## Why it has to be a full, absolute URI

The HTTP spec expects `Location` to be an absolute URI (`https://api.example.com/users/42`), not a bare path (`/users/42`) — although in practice most modern clients and browsers tolerate a relative path too. This is exactly why Spring's helpers (`ServletUriComponentsBuilder.fromCurrentRequest()`) exist: they build the full scheme + host + port + path for you, so you're not stuck concatenating `request.getScheme()`, `request.getServerName()`, and `request.getServerPort()` by hand.

## Related concept, briefly: `Content-Location`

There's a lesser-used cousin, `Content-Location`, which identifies the URI of the _specific representation_ returned in the response body (useful when content negotiation means the same URL can return different formats). It's rare in everyday REST APIs — `Location` is the one you'll actually reach for.


[[Spring Framework]]