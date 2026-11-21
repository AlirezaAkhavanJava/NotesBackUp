

A URI (Uniform Resource Identifier) is just a string that identifies a resource — it could be a web address, a file path, a URN, anything that points at "a thing" using a standard syntax. Java's `java.net.URI` class takes that string and turns it into a structured, validated object: instead of you manually slicing a string with `substring()` and `indexOf()` to pull out the host or the query parameters, the URI class parses the string once according to the official URI grammar (RFC 3986) and gives you typed accessors for every piece — scheme, host, port, path, query, fragment.

In Spring Boot, you run into `URI` constantly: building REST client calls, constructing redirect responses, generating `Location` headers after a POST, and configuring resource paths. It's a small class, but it removes a huge class of bugs that come from treating URLs as plain strings (forgetting to encode a space, concatenating `?` and `&` wrong, mismatching a trailing slash).

## Why not just use a `String`?

If you store a URI as a raw `String`, Java has no idea it's supposed to follow URI rules. You could write `"htt p://exa mple .com"` and nothing stops you until something downstream chokes on it. Two other string-based problems show up constantly:

1. **Encoding.** URIs can only contain a restricted set of characters. A space, an `&` inside a query value, or non-ASCII characters like `é` all have to be "percent-encoded" (`%20`, `%26`, etc.). Doing this by hand with string concatenation is how you get subtle bugs where a URL works for "John" but breaks for "O'Brien & Sons".
2. **Structure.** A URI isn't just text — it has defined parts in a fixed order:

```
scheme://userInfo@host:port/path?query#fragment
```

The `URI` class understands this structure. Give it a full string, or build it piece by piece, and it knows which part is which, validates the result, and encodes anything that needs encoding.

## Creating a URI

There are two main ways:

**1. Parse an existing string:**

```java
URI uri = new URI("https://api.example.com:8443/users/42?active=true#top");
```

This throws a checked `URISyntaxException` if the string is malformed — so the compiler forces you to handle bad input instead of discovering it at runtime.

**2. Build it from parts**, which is the safer option when any part comes from user input or a variable, because the constructor handles encoding for you:

```java
URI uri = new URI(
    "https",            // scheme
    "api.example.com",  // host
    "/users/42",         // path
    "active=true",       // query
    "top"                 // fragment
);
```

If you pass a name with a space or special character into one of these fields, this constructor percent-encodes it automatically. The single-string constructor does **not** — it expects the string to already be valid.

## Pulling pieces back out

Once you have a `URI` object, each component is a method call away:

```java
uri.getScheme();    // "https"
uri.getHost();      // "api.example.com"
uri.getPort();      // 8443
uri.getPath();      // "/users/42"
uri.getQuery();     // "active=true"
uri.getFragment();  // "top"
```

This is the real payoff: no manual string parsing, no off-by-one errors chopping at `?` or `#`.

## Where this shows up in Spring Boot

**1. Calling another service with `RestClient` or `RestTemplate`.** Rather than hand-building a query string, Spring gives you `UriComponentsBuilder`, which is `URI`'s friend for exactly this job:

```java
URI uri = UriComponentsBuilder.fromUriString("https://api.example.com/users")
        .queryParam("active", true)
        .queryParam("name", "O'Brien & Sons")  // encoded automatically
        .build()
        .toUri();

restClient.get().uri(uri).retrieve().body(UserDto.class);
```

Notice the `&` and `'` in the name — `UriComponentsBuilder` handles the percent-encoding for you, so you never concatenate raw strings into a URL.

**2. Returning a `Location` header after creating a resource.** This is the classic REST pattern: after a `POST /users` succeeds, the response should include a `Location` header pointing at the new resource. `ServletUriComponentsBuilder` builds this `URI` relative to the current request:

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

`ResponseEntity.created(URI location)` specifically requires a `URI` object, not a `String` — Spring enforces correctness at the type level here.

**3. Redirects.** A `RedirectView` or a manually built redirect response also takes a `URI`/`String` representing where to send the client, built the same safe way.

## A quick related concept: `URL` vs `URI`

You'll also see `java.net.URL` in older code. The short version: a `URI` is purely about _identifying_ a resource (syntax and structure only — it doesn't know how to fetch anything). A `URL` is a `URI` that also knows how to _locate and open a connection_ to the resource (it has protocol handlers behind it, like `http`). Modern Java and Spring code favors doing all your parsing/building with `URI`, then converting to `URL` only at the last moment (`uri.toURL()`) when you actually need to open a connection. This avoids some validation gaps that `URL` historically had.


[[Spring Framework]]