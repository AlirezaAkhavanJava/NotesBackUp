

`@RequestHeader` is a Spring MVC annotation that binds the value of an HTTP request header directly to a controller method parameter, the same way `@PathVariable` binds a URL segment and `@RequestParam` binds a query parameter. Instead of manually pulling headers out of `HttpServletRequest`, you declare the header you want as a parameter, and Spring extracts it before your method body even runs.

### The problem it solves

Without it, reading a header means reaching into the raw servlet API:

```java
@GetMapping("/orders")
public List<Order> getOrders(HttpServletRequest request) {
    String token = request.getHeader("Authorization");
    String acceptLang = request.getHeader("Accept-Language");
    // ...
}
```

This works, but it's low-level: no type conversion, no built-in validation that the header exists, and it clutters the method signature with a generic `HttpServletRequest` instead of expressing what the method actually needs. `@RequestHeader` replaces this with a declarative parameter:

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader("Authorization") String token) {
    // token already extracted, ready to use
}
```

Spring reads the header named `Authorization` from the incoming request and passes its value straight into `token`.

### Basic usage and naming

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader("X-Client-Version") String clientVersion) {
    ...
}
```

If the parameter name already matches the header name (ignoring case), you can omit the explicit name:

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader String Authorization) {
    ...
}
```

In practice almost everyone still writes the explicit name, because HTTP header names use hyphens (`X-Client-Version`) which aren't valid in Java identifiers, and because the explicit form is clearer at a glance.

### Required vs optional, and defaults

By default, `@RequestHeader` requires the header to be present — if it's missing, Spring responds with `400 Bad Request` before your method runs at all:

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader("Authorization") String token) {
    // 400 automatically if Authorization header is absent
}
```

To make it optional, set `required = false`, and the parameter becomes `null` if the header is missing:

```java
@GetMapping("/orders")
public List<Order> getOrders(
        @RequestHeader(value = "X-Client-Version", required = false) String clientVersion) {
    if (clientVersion == null) {
        clientVersion = "unknown";
    }
    ...
}
```

Or skip the null check entirely with `defaultValue`, which also implicitly makes the header optional:

```java
@GetMapping("/orders")
public List<Order> getOrders(
        @RequestHeader(value = "X-Client-Version", defaultValue = "unknown") String clientVersion) {
    ...
}
```

### Type conversion

Spring converts the header's string value to the parameter's declared type using the same conversion machinery it uses for `@RequestParam` and `@PathVariable`:

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader("X-Page-Size") int pageSize) {
    ...
}
```

If `X-Page-Size: 25` is sent, `pageSize` becomes the `int` `25` automatically. If the header can't convert (e.g. it's not a valid integer), Spring throws `MethodArgumentTypeMismatchException`, which by default becomes a `400`.

### Binding multiple headers at once

Two parameter types let you grab everything instead of one header at a time:

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader Map<String, String> headers) {
    headers.forEach((name, value) -> log.debug("{}: {}", name, value));
}
```

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader HttpHeaders headers) {
    MediaType accept = headers.getAccept().get(0);
    List<String> authHeaders = headers.get("Authorization");
}
```

`HttpHeaders` is the richer option — it understands structured headers like `Accept` and `Content-Type` as their proper types (`MediaType`, lists, etc.) rather than raw strings, and it correctly handles headers that can legally repeat (a single header name with multiple values).

### Multi-value headers as a `List`

Some headers (like `Accept` or a custom header sent multiple times) can appear more than once in a single request. Binding directly to a `List` captures all of them:

```java
@GetMapping("/orders")
public List<Order> getOrders(@RequestHeader("Accept") List<MediaType> acceptTypes) {
    ...
}
```

### Where it fits alongside `@RequestParam` and `@PathVariable`

All three work the same way mechanically — they declare "extract this value from the request and hand it to me as a typed parameter" — they just differ in _where_ in the request they look: `@PathVariable` reads from the URL path, `@RequestParam` reads from the query string (or form body), and `@RequestHeader` reads from the HTTP headers. Headers are typically used for things that describe the _request itself_ rather than the resource being addressed — authentication tokens (`Authorization`), content negotiation (`Accept`, `Accept-Language`), caching (`If-None-Match`, `If-Modified-Since`), and custom metadata like API versioning (`X-Client-Version`) — rather than for identifying or filtering data, which is what path variables and query parameters are for.


[[Spring Framework]]