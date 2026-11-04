

## Mental model: a conversation by letter

HTTP is a **letter exchange**. The client writes one letter (the **request**), the server writes exactly one letter back (the **response**). The server never writes first, and each request gets one response.

```
CLIENT                                          SERVER
  │  ── REQUEST  (question / instruction) ──►    │
  │  ◄─ RESPONSE (result / answer) ───────────   │
```

## 1. What counts as a request

A **request** is everything the client sends. In raw form it's plain text:

```
POST /api/users/5/orders?notify=true HTTP/1.1      ← REQUEST LINE: method + path + query + version
Host: localhost:8080                               ┐
Content-Type: application/json                     │ HEADERS: metadata about the request
Accept: application/json                           │
Authorization: Bearer eyJhbGci...                  │
Idempotency-Key: 9f1c2a7e                          ┘
                                                   ← blank line = "headers end here"
{"items":[{"productId":7,"quantity":2}]}           ← BODY: the payload (optional)
```

|Part|What it says|Spring reads it with|
|---|---|---|
|Method|what action|`@GetMapping`, `@PostMapping`...|
|Path|which resource|`@PathVariable`|
|Query string|options / filters|`@RequestParam`|
|Headers|metadata, auth, formats|`@RequestHeader`, `consumes`, `produces`|
|Cookies (a header)|stored client state|`@CookieValue`|
|Body|the data itself|`@RequestBody`|

## 2. What counts as a response

A **response** is everything the server sends back:

```
HTTP/1.1 201 Created                               ← STATUS LINE: version + code + reason
Location: http://localhost:8080/api/users/5/orders/42   ┐ HEADERS
Content-Type: application/json                           ┘
                                                   ← blank line
{"id":42,"status":"PENDING"}                       ← BODY (optional)
```

|Part|What it says|Spring sets it with|
|---|---|---|
|Status code|how it went|`@ResponseStatus`, `ResponseEntity`|
|Headers|metadata (`Location`, cache, file name)|`ResponseEntity` `.header(...)`|
|Body|the result data|return value + `@ResponseBody` (automatic in `@RestController`)|

**The symmetry:** a request has _method + path + headers + body_; a response has _status + headers + body_. The status is the only part with no twin, which is why there is no "RequestStatus".

## 3. How Spring handles a request, end to end

```
 Browser/curl
     │ bytes over TCP
     ▼
 Tomcat (embedded)        parses raw text into HttpServletRequest / HttpServletResponse
     ▼
 Filters                  (security, CORS, logging): can reject early
     ▼
 DispatcherServlet        the front door: ONE entry point for all requests
     ▼
 HandlerMapping           "which controller method matches path + method + consumes + params?"
     ▼
 Interceptors (pre)
     ▼
 Argument resolvers       build each parameter:
                          @PathVariable → from path
                          @RequestParam → from query
                          @RequestBody  → HttpMessageConverter (JSON → object) → @Valid
     ▼
 YOUR CONTROLLER METHOD   runs only now → calls the service → returns a value
     ▼
 Return value handler     ResponseEntity? @ResponseBody? view name?
     ▼
 HttpMessageConverter     Java object → JSON bytes (chosen by Accept header)
     ▼
 Filters (on the way out)
     ▼
 Tomcat writes status + headers + body to the socket
```

If an exception happens anywhere before the response is committed, it goes to the **exception resolvers** (`@ExceptionHandler` first, then `@ResponseStatus`, then Spring's defaults, then 500).

**Why this matters:** your method is only _one step_ in the middle. Everything before it (routing, parsing, validation) is Spring's job and can reject the request before your code runs. Everything after it (serializing, status, headers) is also Spring's job. Your method only has to turn _input objects into an output object_.

## 4. How data should be RECEIVED (which channel for which data)

Pick the channel by the **kind** of data:

|Data|Channel|Annotation|Example|
|---|---|---|---|
|**Which** resource|Path|`@PathVariable`|`/users/5`|
|Filter, sort, page, search|Query string|`@RequestParam`|`?role=admin&page=2`|
|The **object** being created or updated|Body (JSON)|`@RequestBody`|`{"name":"Ali"}`|
|Info about the request itself (auth, version, idempotency, language)|Header|`@RequestHeader`|`Authorization: Bearer ...`|
|Small client-side state|Cookie|`@CookieValue`|`sessionId=abc`|
|Files|Multipart body|`@RequestParam MultipartFile`|`-F file=@a.jpg`|
|Classic HTML form fields|Form body|`@RequestParam` / `@ModelAttribute`|`name=Ali&age=30`|

**Rules that follow from this:**

1. **Identity in the path, options in the query, data in the body.**
2. **Never put secrets in the path or query.** URLs are logged everywhere. Use headers or the body.
3. **GET and DELETE should not rely on a body.** Many proxies drop it.
4. **Bind to a request DTO, not an entity** (prevents mass assignment).
5. **Validate at the door** with `@Valid`, and never trust client data.
6. **Declare what you accept** with `consumes`, and expect a clean 415 otherwise.

```java
@PostMapping(path = "/{userId}/orders", consumes = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<OrderResponse> create(
        @PathVariable Long userId,                        // which user
        @RequestHeader("Idempotency-Key") String key,     // about the request
        @Valid @RequestBody OrderRequest req) { ... }     // the data
```

## 5. How data should be SENT (what a good response looks like)

**1. Use the right status**, so clients can react without parsing the body:

|Outcome|Status|
|---|---|
|Read or update OK|200|
|Created|201 + `Location`|
|Accepted, not done yet|202|
|Success, nothing to return|204|
|Client's fault|400 / 404 / 409 / 415|
|Server's fault|500 / 502 / 503 / 504|

**2. Return a response DTO, not an entity**, so you don't leak fields or hit lazy-loading and recursion problems.

**3. Put metadata in headers, data in the body.** A total count is `X-Total-Count`; the body stays a clean array.

**4. Set `Content-Type` correctly** (done for you by `produces` and the converter).

**5. Errors must have the same shape everywhere.** Use `ProblemDetail` via `@RestControllerAdvice`. Don't return a 200 with `{"error": ...}`.

**6. Be consistent.** The same kind of data should come back in the same structure from every endpoint.

```java
return ResponseEntity.created(location).body(response);   // 201 + header + DTO body
```

## 6. Request to response, traced once

`POST /api/users/5/orders` with a JSON body:

|Step|Who|What|
|---|---|---|
|1|Tomcat|parses the raw text|
|2|Filters|CORS and auth checks (could return 401/403 here)|
|3|`DispatcherServlet` + `HandlerMapping`|match path, `POST`, `consumes` (else 404/405/415)|
|4|Resolvers|`userId=5` from path, key from header, JSON → `OrderRequest`|
|5|`@Valid`|constraints checked (else 400, controller never runs)|
|6|Controller|calls the service, receives the saved order|
|7|Return handler|sees `ResponseEntity` → status 201 + `Location`|
|8|Converter|`OrderResponse` → JSON bytes|
|9|Tomcat|writes the response|

## Nuances and gotchas

**1. "Request" and "response" are objects too.** You can ask for the raw `HttpServletRequest request` or `HttpServletResponse response` as method parameters, but you rarely should. The annotations give you typed, validated, testable data. Writing directly to `HttpServletResponse` **bypasses** converters, `@ResponseBody`, and `ResponseEntity`.

**2. One response per request, and once committed it can't change.** After Spring starts writing the body, status and headers are fixed. A later exception can't turn it into a 500.

**3. The body can be read only once.** That's why there's one `@RequestBody` per method.

**4. HTTP is stateless.** Each request must carry everything the server needs (token, IDs). The server doesn't "remember" the previous request unless you add sessions or tokens, so authentication travels in a header on _every_ request.

**5. Not everything is a request/response pair.** WebSockets, Server-Sent Events, and streaming keep a connection open and send many messages. Those are later topics.

**6. Content negotiation links both directions.** `Content-Type` says _what I'm sending you_; `Accept` says _what I want back_. Mismatch gives 415 (request side) or 406 (response side).

## Quick reference

```
REQUEST  (client → server)                RESPONSE (server → client)
─────────────────────────                 ──────────────────────────
method     → @GetMapping...               status   → @ResponseStatus / ResponseEntity
path       → @PathVariable                headers  → ResponseEntity.header(...)
query      → @RequestParam                body     → return value (@ResponseBody)
headers    → @RequestHeader
cookies    → @CookieValue
body       → @RequestBody (+ @Valid)
```




[[Spring Framework]]