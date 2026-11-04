

## The problem it solves

Two programs written by different people, in different languages, on different continents, need to talk. Without a shared language, every pair of programs would need its own custom agreement.

HTTP is that shared language. It has strict, simple rules for how to **ask** for something and how to **answer**. Your browser, `curl`, your Spring Boot app, and a mobile app all speak it, so they can all talk to each other.

> HTTP is a conversation made of **one request, then one response**, repeated. Each exchange stands alone.

You've seen pieces of it already. This lesson puts them into one picture, and it prepares you for JWT, which travels inside HTTP headers.

## The map

```
1. URL anatomy         → how you say WHERE
2. Request & response  → the message shape
3. Methods             → WHAT you want to do
4. Status codes        → HOW it went
5. Headers             → the extra instructions
6. Bodies              → the data (JSON, forms, files)
7. Caching             → avoiding repeat work
8. CORS preflight      → the browser's permission check
9. Versions            → HTTP/1.1, 2, 3
10. Spring Boot code   → all of it in practice
```

---

# Part 1: Anatomy of a URL

```
https://api.example.com:8443/users/42?active=true&sort=name#profile
└─┬──┘   └──────┬──────┘└─┬─┘└──┬───┘└──────────┬─────────┘└──┬──┘
scheme        host      port  path           query         fragment
```

|Piece|Meaning|Sent to the server?|
|---|---|---|
|**scheme**|The protocol (`http` or `https`)|Decides how to connect|
|**host**|Which machine (DNS turns it into an IP)|In the `Host` header|
|**port**|Which program (default 80 for http, 443 for https)|Used to connect|
|**path**|Which resource|Yes|
|**query**|Extra key=value options, after `?`, separated by `&`|Yes|
|**fragment**|A spot inside the page, after `#`|**No, the browser keeps it**|

The fragment never leaves your browser. That's why you should never rely on it for server logic, and it's also why a token placed in a fragment doesn't show up in server logs.

**Query vs path:** use the path to say _which_ thing (`/users/42`) and the query to say _how to view it_ (`?sort=name&page=2`).

**URL encoding:** special characters are written as `%` plus hex. A space becomes `%20`, and `&` inside a value becomes `%26`. Frameworks do this for you. Doing it by hand with string concatenation is a classic source of bugs and injection holes.

---

# Part 2: The shape of a request and a response

### A request

```http
POST /users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Accept: application/json
Authorization: Bearer eyJhbGciOi...
Content-Length: 38

{"name": "Alice", "email": "a@x.com"}
```

### A response

```http
HTTP/1.1 201 Created
Content-Type: application/json
Location: /users/42
Content-Length: 52

{"id": 42, "name": "Alice", "email": "a@x.com"}
```

|Part|Request|Response|
|---|---|---|
|**Start line**|Method, path, version|Version, status code, reason text|
|**Headers**|`Name: value` lines|Same style|
|**Blank line**|Ends the headers|Same|
|**Body**|Optional data|Optional data|

HTTP/1.1 is plain text, so you can read it directly. HTTP/2 and 3 are binary on the wire, but they carry **exactly the same ideas** (methods, headers, status codes), and tools like the browser's Network tab show them in the same form.

### The one rule that explains everything: HTTP is stateless

The server doesn't remember request #1 when request #2 arrives. Every request has to carry everything the server needs: who you are (cookie or `Authorization`), what you want, and in what format. That's why headers matter so much, and why sessions and tokens exist.

---

# Part 3: Methods, saying what you want to do

|Method|Meaning|Body?|Safe?|Idempotent?|
|---|---|---|---|---|
|`GET`|Read|No|Yes|Yes|
|`HEAD`|Like GET, but headers only|No|Yes|Yes|
|`POST`|Create, or trigger an action|Yes|No|**No**|
|`PUT`|Replace a whole resource|Yes|No|Yes|
|`PATCH`|Change part of a resource|Yes|No|Usually no|
|`DELETE`|Remove|Rarely|No|Yes|
|`OPTIONS`|"What may I do here?" (CORS)|No|Yes|Yes|

Two words in that table are worth defining:

- **Safe** means "doesn't change anything on the server." Browsers, caches, and crawlers assume `GET` is safe, so they'll call it freely. If `GET /deleteAccount` actually deletes, a search crawler or a prefetching browser can destroy data, and an attacker can trigger it from an `<img>` tag (that's the CSRF lesson).
- **Idempotent** means "doing it several times has the same effect as doing it once."

Here's why idempotency matters in real life. Your phone sends a payment request, and the network drops before the reply arrives. Should the app retry?

|Method|Retry result|
|---|---|
|`PUT /users/42 {name: "Bob"}`|Fine. The name is "Bob" either way.|
|`DELETE /users/42`|Fine. It's gone either way.|
|`POST /payments {amount: 100}`|**Danger.** You might charge twice.|

Real payment systems solve this by letting the client send an **idempotency key** (a unique ID in a header), so the server can recognize a retry and ignore the duplicate.

**PUT vs PATCH:** `PUT` sends the _complete_ new version (missing fields get wiped or reset), while `PATCH` sends only the changes.

---

# Part 4: Status codes, how it went

Every response has a three-digit code. The first digit tells you the category:

|Range|Meaning|Who's at fault|
|---|---|---|
|**1xx**|Informational|Nobody|
|**2xx**|Success|Nobody|
|**3xx**|Redirect, look elsewhere|Nobody|
|**4xx**|Client error|**The request**|
|**5xx**|Server error|**The server**|

### The ones you'll meet constantly

|Code|Name|When to use it|
|---|---|---|
|**200**|OK|Success with a body|
|**201**|Created|A `POST` made something. Include a `Location` header.|
|**204**|No Content|Success, nothing to return (common for `DELETE`)|
|**301**|Moved Permanently|The URL changed forever (browsers and search engines cache this)|
|**302**|Found|Temporary redirect|
|**304**|Not Modified|"Your cached copy is still good" (see caching)|
|**307 / 308**|Temporary / Permanent Redirect|Like 302 / 301, but the method is **preserved**|
|**400**|Bad Request|Malformed or invalid input|
|**401**|Unauthorized|You aren't authenticated (the name is misleading)|
|**403**|Forbidden|You're authenticated but not allowed|
|**404**|Not Found|No such resource|
|**405**|Method Not Allowed|Wrong method (`DELETE` on a read-only URL)|
|**409**|Conflict|Clashes with current state (duplicate email, version clash)|
|**415**|Unsupported Media Type|You sent a `Content-Type` the server can't read|
|**422**|Unprocessable Content|Well-formed, but fails validation rules|
|**429**|Too Many Requests|Rate limit hit|
|**500**|Internal Server Error|A bug on the server|
|**502 / 503 / 504**|Bad Gateway / Unavailable / Gateway Timeout|A proxy or upstream service is down or slow|

### Details that trip people up

**401 vs 403.** Despite its name, `401` means _not authenticated_: "I don't know who you are." It should come with a `WWW-Authenticate` header saying how to log in. `403` means _authenticated but not permitted_: "I know who you are, and the answer is no." In Spring Security terms, `401` comes from the `AuthenticationEntryPoint` and `403` from the `AccessDeniedHandler`, which you met earlier.

**302 vs 307 on a POST.** Historically, browsers turn a redirected `POST` into a `GET` on `302` and `301`. `307` and `308` **keep the method and body**. After a form `POST`, the standard trick is to answer `303 See Other`, which tells the browser to `GET` the result page. That way a refresh doesn't resubmit the form (the "Post/Redirect/Get" pattern).

**404 can be a security tool.** Some systems return `404` instead of `403` for resources you shouldn't even know exist, so attackers can't tell "exists but forbidden" from "doesn't exist."

---

# Part 5: Headers, the instructions around the data

Headers are `Name: value` lines. Think of them as the **labels on a parcel**: they say what's inside, who it's for, and how to handle it. Here are the ones that matter.

### Describing the body

|Header|Direction|Meaning|
|---|---|---|
|`Content-Type`|Both|Format of the body: `application/json`, `text/html`, `multipart/form-data`|
|`Content-Length`|Both|Body size in bytes|
|`Content-Encoding`|Response|Compression used (`gzip`, `br`)|

### Asking for a format (content negotiation)

|Header|Meaning|
|---|---|
|`Accept`|"I can read these types" (`application/json`)|
|`Accept-Encoding`|"I can decompress these" (`gzip, br`)|
|`Accept-Language`|"My preferred languages" (`en-GB, en;q=0.8`)|

The `q=0.8` is a **quality weight** from 0 to 1, meaning "second choice, at 80% preference." The server picks the best match it can supply. In Spring, this is why one method can return JSON or XML based on `Accept`.

### Identity and security

|Header|Meaning|
|---|---|
|`Authorization`|Credentials: `Bearer <token>` or `Basic <base64>`|
|`Cookie` / `Set-Cookie`|The cookie system from last lesson|
|`WWW-Authenticate`|Server's "log in like this" hint, sent with 401|
|`Origin`|Which site started this request (important for CORS and CSRF)|

Notice `Basic` is just `base64(username:password)`, which is **encoding, not encryption**. Anyone who sees it can read it. That's why Basic auth is only acceptable over HTTPS.

### Routing and context

|Header|Meaning|
|---|---|
|`Host`|Which site you want. One server (one IP) can host many sites, and this header says which one.|
|`User-Agent`|Which client is calling (browser, `curl/8.x`). Easily faked, so never trust it for security.|
|`Referer`|The page you came from (yes, it's spelled wrong in the spec)|
|`X-Forwarded-For` / `X-Forwarded-Proto`|Added by proxies to say the original client IP and scheme|

### The security headers you already know

`Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options`, and `Referrer-Policy` all ride in **response** headers. The server sends them, and the browser enforces them.

A note on naming: headers starting with `X-` were an old convention for custom headers. It's been deprecated, but you'll still see it in lots of existing code.

---

# Part 6: Bodies, the data itself

The `Content-Type` header tells the receiver how to read the bytes.

|Content-Type|Looks like|Used for|
|---|---|---|
|`application/json`|`{"name":"Alice"}`|APIs|
|`application/x-www-form-urlencoded`|`name=Alice&age=30`|Classic HTML forms|
|`multipart/form-data`|Several parts separated by a boundary|**File uploads**|
|`text/html`|A web page|Pages|
|`text/plain`|Plain text|Simple text|
|`application/octet-stream`|Raw bytes|Downloads|

Why does JSON matter for security? If the server demands `Content-Type: application/json`, a plain HTML form on `evil.com` can't send it without triggering a CORS preflight. That makes JSON APIs a bit harder to attack with CSRF, though it is not a substitute for a real defense.

**Large and streaming bodies:** when the size isn't known in advance, HTTP/1.1 uses `Transfer-Encoding: chunked`, sending the body in pieces. That's how streaming responses and Server-Sent Events work.

---

# Part 7: Caching, avoiding repeat work

## The problem it solves

Most of the web is the same files fetched again and again: logos, scripts, stylesheets. Downloading them every time wastes time and bandwidth. HTTP has a built-in system for reusing copies.

### Level 1: "Don't even ask me" (freshness)

```http
Cache-Control: max-age=86400
```

"Treat this as fresh for 86,400 seconds (one day). Don't contact me during that time." The browser serves it from its own cache, and you'll see `(disk cache)` in the Network tab with no network time at all.

### Level 2: "Ask me, but I'll say if it's unchanged" (validation)

When the copy is stale, the browser doesn't blindly download again. It asks politely:

```
1st request:
   GET /logo.png
   ← 200 OK
     ETag: "v7-abc"
     (body: 40 KB)

Later:
   GET /logo.png
   If-None-Match: "v7-abc"       ← "I have version v7-abc. Still current?"
   ← 304 Not Modified            ← "Yes." (no body, just a few bytes)
```

|Header|Role|
|---|---|
|`ETag`|A fingerprint of the content (like a version label)|
|`If-None-Match`|The browser echoes the fingerprint it holds|
|`Last-Modified` / `If-Modified-Since`|The date-based version of the same idea|
|**304**|"Use your copy," and no body is sent|

### The `Cache-Control` values you'll use

|Value|Meaning|
|---|---|
|`max-age=N`|Fresh for N seconds|
|`no-cache`|**Misleading name.** You _may_ store it, but must **revalidate** before reuse|
|`no-store`|**Never store it at all.** For sensitive data.|
|`private`|Only the user's browser may cache it, not shared caches such as CDNs|
|`public`|Any cache may store it|
|`immutable`|Never changes. Skip even revalidation.|

Remember: **`no-cache` ≠ "don't cache"**. `no-store` is the one that forbids storing.

### Practical strategy

|Content|Strategy|
|---|---|
|Versioned files (`app.3f9a1c.js`)|`max-age=31536000, immutable` (the filename changes when the content does)|
|HTML pages|`no-cache` (always check, but benefit from 304)|
|Private account data|`no-store`|

Spring Security applies `Cache-Control: no-cache, no-store, max-age=0, must-revalidate` to secured responses **by default**, so that after logout, pressing the Back button won't show someone's private page from cache. That's the "cache control" header from the Spring Security features list.

---

# Part 8: CORS and the preflight request

## The problem it solves

Recall the **same-origin policy**: a script on `https://a.com` can't read responses from `https://b.com`. But legitimate cases exist, like your front end on `app.example.com` calling your API on `api.example.com`. **CORS** (Cross-Origin Resource Sharing) is how the _server_ says "this other origin is allowed."

### Simple requests vs preflighted requests

A **simple** request (a plain `GET`, or a form-style `POST`) is sent right away, and the browser checks the response headers afterward.

For anything "unusual," the browser first sends a **preflight**, a harmless `OPTIONS` request, to ask permission. A request is unusual if it uses:

- `PUT`, `PATCH`, or `DELETE`, or
- `Content-Type: application/json`, or
- a custom header like **`Authorization`**.

So **almost every real API call with a token triggers a preflight.**

```
Browser (page on https://app.example.com) wants to do:
   PUT https://api.example.com/users/42   with Authorization: Bearer ...

Step 1, PREFLIGHT (sent by the browser, automatically):
   OPTIONS /users/42
   Origin: https://app.example.com
   Access-Control-Request-Method: PUT
   Access-Control-Request-Headers: authorization, content-type

Step 2, server replies:
   204 No Content
   Access-Control-Allow-Origin: https://app.example.com
   Access-Control-Allow-Methods: GET, PUT, DELETE
   Access-Control-Allow-Headers: authorization, content-type
   Access-Control-Max-Age: 3600

Step 3, browser compares, and if everything is allowed:
   PUT /users/42    (the real request)
```

|Response header|Meaning|
|---|---|
|`Access-Control-Allow-Origin`|Which origin may read the response|
|`Access-Control-Allow-Methods`|Which methods are allowed|
|`Access-Control-Allow-Headers`|Which request headers are allowed|
|`Access-Control-Allow-Credentials: true`|Cookies and auth may be included (then `*` is **not** allowed as the origin)|
|`Access-Control-Max-Age`|How long the browser may remember this answer, so it skips repeat preflights|

### Important truths about CORS

1. **CORS is enforced by the browser, not the server.** `curl` ignores it entirely. If your API works in `curl` but fails in the browser, CORS is a likely cause.
2. **The server still receives and processes many blocked requests.** CORS stops the page from _reading_ the response, not necessarily the request from being _sent_. That's why it isn't a CSRF defense.
3. **The preflight carries no `Authorization` header or cookies.** So if your security layer rejects every unauthenticated `OPTIONS` with `401`, the real request never happens. That's why Spring Security needs `http.cors(...)` to run **before** authentication.

---

# Part 9: Connections and versions

### How connections are reused

Opening a TCP + TLS connection takes several round trips. Doing that for every request would be slow. So:

- **HTTP/1.0** opened a new connection for every request.
- **HTTP/1.1 (1997)** introduced **keep-alive** (on by default): one connection serves many requests, one after another. A weakness remains: a slow response blocks everything behind it on that connection (**head-of-line blocking**). Browsers work around it by opening about 6 connections per host.
- **HTTP/2 (2015)** is binary and adds **multiplexing**: many requests and responses interleave on **one** connection. It also compresses headers (HPACK), which helps because cookies and tokens repeat on every request.
- **HTTP/3 (2022)** runs over **QUIC**, which is built on UDP. It removes head-of-line blocking at the transport level too, and connects faster. It handles network switches better (Wi-Fi to mobile data).

||HTTP/1.1|HTTP/2|HTTP/3|
|---|---|---|---|
|Format|Text|Binary|Binary|
|Parallel requests per connection|One at a time|Many (multiplexed)|Many (multiplexed)|
|Runs on|TCP|TCP|QUIC (UDP)|
|Browsers need TLS|No|Yes (in practice)|Yes|
|Your code changes?||**No**|**No**|

Your controllers don't change between versions. It's a transport upgrade, handled by the server (Tomcat) and the browser. That is why `server.http2.enabled=true` is a single property.

### HTTPS is HTTP inside TLS

`https://` means the same HTTP messages, wrapped in a TLS tunnel. The headers, URL path, query, cookies, and body are all encrypted in transit. What's still visible to a network observer: the destination IP, and usually the domain name (through the TLS handshake's SNI field). That's worth knowing, because "HTTPS hides everything" is not quite true.

---

# Part 10: Spring Boot, all of it in code

A small REST controller that uses methods, status codes, headers, and caching properly:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserRepository repo;

    public UserController(UserRepository repo) {
        this.repo = repo;
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> get(@PathVariable long id) {
        return repo.findById(id)
                .map(user -> ResponseEntity.ok()
                        .cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePrivate())
                        .eTag("\"v" + user.getVersion() + "\"")
                        .body(user))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<User> create(@Valid @RequestBody User input) {
        User saved = repo.save(input);
        URI location = URI.create("/users/" + saved.getId());
        return ResponseEntity.created(location).body(saved);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable long id) {
        repo.deleteById(id);
    }
}
```

Line by line:

- `@RestController` marks a class whose methods return data (JSON) instead of page names.
- `@RequestMapping("/users")` is the common path prefix.
- `@GetMapping("/{id}")` handles `GET /users/42`. `@PathVariable long id` pulls `42` from the path.
- `repo.findById(id)` returns an `Optional<User>`. The `.map(...)` branch runs when a user exists, and builds a `200 OK`.
- `.cacheControl(CacheControl.maxAge(5 min).cachePrivate())` sets `Cache-Control: max-age=300, private`.
- `.eTag(...)` sets the `ETag` header. Spring then automatically handles `If-None-Match` checks on `GET`, answering **304** when the ETag matches.
- `.orElse(ResponseEntity.notFound().build())` returns **404** when no user exists.
- `@PostMapping` handles creation. `@Valid @RequestBody User input` reads the JSON body into a `User` and runs validation rules. A failed validation produces **400** automatically.
- `ResponseEntity.created(location)` gives **201** and a `Location: /users/42` header, the proper response to a creation.
- `@DeleteMapping` with `@ResponseStatus(NO_CONTENT)` returns **204** with no body.

### Letting Spring compute ETags for you

If you don't want to manage versions by hand, a built-in filter hashes each response body and creates the `ETag` itself:

```java
@Bean
FilterRegistrationBean<ShallowEtagHeaderFilter> etagFilter() {
    FilterRegistrationBean<ShallowEtagHeaderFilter> bean =
            new FilterRegistrationBean<>(new ShallowEtagHeaderFilter());
    bean.addUrlPatterns("/api/*");
    return bean;
}
```

- `ShallowEtagHeaderFilter` hashes the response body, then adds the `ETag`.
- If the browser sent a matching `If-None-Match`, the filter turns the response into **304** and drops the body.
- It saves **bandwidth** but not **work**, since your controller still runs fully. "Shallow" means exactly that.

### Choosing the response format from the `Accept` header

```java
@GetMapping(value = "/{id}", produces = { "application/json", "application/xml" })
```

- `produces` lists the formats this method can supply. Spring compares it with the request's `Accept` header and picks one, or answers **406 Not Acceptable** if none fits.
- The related `consumes = "application/json"` limits what bodies this method accepts. A different type gets **415**.

### Mapping your own errors to status codes

```java
@RestControllerAdvice
public class ApiErrors {

    @ExceptionHandler(UserNotFound.class)
    public ResponseEntity<Map<String, String>> notFound(UserNotFound e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", e.getMessage()));
    }

    @ExceptionHandler(DuplicateEmail.class)
    public ResponseEntity<Map<String, String>> conflict(DuplicateEmail e) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Map.of("error", e.getMessage()));
    }
}
```

- `@RestControllerAdvice` is a global handler for exceptions thrown from any controller.
- Each `@ExceptionHandler` method turns one exception type into one status code. This keeps controllers clean: they throw meaningful exceptions, and one place decides the HTTP answer.
- Don't leak internals in error bodies. Never return stack traces, SQL text, or file paths.

### Reading headers in a controller

```java
@GetMapping("/whoami")
public String whoami(@RequestHeader("User-Agent") String agent,
                     @RequestHeader(value = "X-Request-Id", required = false) String reqId) {
    return "Client: " + agent + ", request id: " + reqId;
}
```

- `@RequestHeader("User-Agent")` pulls that header into a variable.
- `required = false` stops Spring from returning **400** when the header is missing.

---

# Part 11: See all of it with `curl` on Debian

Start your Spring Boot app, then try these. Each one shows a different part of this lesson.

**1. See the whole conversation:**

```bash
curl -v http://localhost:8080/users/1
```

Lines starting with `>` are your request, and `<` are the response. You'll see the start line, headers, and body.

**2. Headers only, with a different method:**

```bash
curl -i -X DELETE http://localhost:8080/users/1
```

`-i` includes response headers, and `-X` picks the method. Expect `204`. Run it twice and see that `DELETE` is idempotent in effect.

**3. Send JSON:**

```bash
curl -i -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"a@x.com"}'
```

Look for `201 Created` and `Location:`. Now remove the `Content-Type` header and watch for `415`.

**4. Test caching and 304:**

```bash
curl -i http://localhost:8080/users/1
curl -i -H 'If-None-Match: "v1"' http://localhost:8080/users/1
```

The first shows the `ETag`. The second sends it back, and you should get `304 Not Modified` with no body.

**5. Test content negotiation:**

```bash
curl -i -H "Accept: application/xml" http://localhost:8080/users/1
```

You'll get XML, or `406` if you've offered only JSON.

**6. Pretend to be a browser doing a CORS preflight:**

```bash
curl -i -X OPTIONS http://localhost:8080/users/1 \
  -H "Origin: https://app.example.com" \
  -H "Access-Control-Request-Method: PUT" \
  -H "Access-Control-Request-Headers: authorization"
```

You'll see the `Access-Control-Allow-*` headers, or their absence. Without them, a real browser would block the actual call.

**7. Follow a redirect:**

```bash
curl -i http://example.com
curl -iL http://github.com
```

`-L` follows redirects. Without it you see the `301` or `302` and the `Location` header. With it you see the chain.

**8. Check HTTP version and timing:**

```bash
curl -sI --http2 https://example.com | head -1
curl -o /dev/null -s -w "dns:%{time_namelookup} connect:%{time_connect} tls:%{time_appconnect} first-byte:%{time_starttransfer} total:%{time_total}\n" https://example.com
```

The first line shows `HTTP/2 200`. The second prints how long each phase took: DNS, TCP, TLS, and the first byte. It's the Network tab's **Timing** panel in your terminal.

**9. Basic auth is just Base64:**

```bash
echo -n 'alice:secret' | base64
curl -i -H "Authorization: Basic YWxpY2U6c2VjcmV0" http://localhost:8080/me
```

Decode it back with `base64 -d` to see for yourself that it isn't encryption.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Using `GET` to change data|Crawlers, prefetchers, and CSRF can trigger it|Use `POST`, `PUT`, `DELETE`|
|Returning `200` with `{"error": ...}` for failures|Clients, caches, and monitoring tools can't tell it failed|Use the right 4xx or 5xx|
|`401` and `403` swapped|Clients don't know whether to log in again or give up|`401` = not logged in, `403` = not allowed|
|Retrying a non-idempotent `POST` blindly|Duplicate orders or charges|Idempotency keys|
|Putting secrets in the URL query|They land in logs, history, and `Referer`|Use headers or the body|
|Thinking `no-cache` means "don't store"|Private data may remain in caches|Use `no-store` for sensitive data|
|Ignoring timeouts on outgoing calls|Threads pile up when a service hangs|Set connect and read timeouts|
|Relying on CORS to protect your API|`curl` and attackers don't obey it|Real authentication and authorization|
|Trusting `User-Agent`, `Referer`, or `X-Forwarded-For`|The client controls them|Validate on the server, trust proxy headers only from your own proxy|

---

## Related concept, briefly

**REST:** a style of designing APIs on top of HTTP. The core ideas: treat things as **resources** with URLs (`/users/42`), use the HTTP **methods** for actions instead of putting verbs in the path (`DELETE /users/42`, not `/deleteUser?id=42`), use **status codes** honestly, and stay **stateless**, so each request carries its own credentials. That last point is exactly why REST APIs pair so naturally with **tokens in the `Authorization` header**, which is where we're headed next.

---

## The whole picture

|Question|Answer|
|---|---|
|What is HTTP?|A request-then-response language, stateless|
|Message shape?|Start line, headers, blank line, optional body|
|What does a method say?|What you want to do (`GET` reads, `POST` creates...)|
|Safe vs idempotent?|Safe changes nothing. Idempotent means repeating is harmless.|
|What does a status code say?|How it went: 2xx ok, 3xx go elsewhere, 4xx your fault, 5xx server's fault|
|Where do identity and tokens travel?|In headers (`Cookie`, `Authorization`)|
|How does caching work?|`Cache-Control` for freshness, `ETag` + `If-None-Match` + `304` for validation|
|What is a preflight?|An `OPTIONS` request the browser sends before unusual cross-origin calls|
|Who enforces CORS?|The browser, not the server and not `curl`|
|HTTP/2 and 3?|Faster transport, with the same methods, headers, and codes|




[[Spring Security]]
[[Spring Framework]]