

## Mental model: a letter in an envelope, plus a wristband

You already know that a request or response is a "letter". Now zoom into its parts:

```
┌─ ENVELOPE ──────────────────────────────┐
│  Content-Type: application/json         │  ← HEADERS: instructions about the letter
│  Authorization: Bearer eyJ...           │
│  Cookie: sessionId=abc123               │
├─────────────────────────────────────────┤
│  {"name":"Alireza","email":"a@b.com"}   │  ← PAYLOAD: the letter's actual contents
└─────────────────────────────────────────┘
```

- **Header** = writing on the envelope (who, what format, how to handle it).
- **Payload** = the letter inside (the data you actually want to deliver).
- **Cookie** = a **wristband** the server gives you at the door. You show it on every later visit so the server recognizes you, because HTTP itself has no memory.

---

# 1. Header

## Definition

A header is a **`Name: value` metadata line** attached to a request or response. It describes the message or the sender rather than carrying the data itself. Headers sit after the first line and before the blank line:

```
GET /api/products/7 HTTP/1.1
Host: localhost:8080
Accept: application/json
Authorization: Bearer eyJhbGci...
```

## Why headers exist (the "why")

HTTP needs a place for information that is **about the exchange**, not part of the data. If metadata lived inside the body, every body format (JSON, XML, a PDF) would need its own convention, and proxies and servers couldn't read it without parsing the content. Headers give a **universal, format-independent** place that every server, proxy, cache, and browser understands.

## Categories (by purpose)

|Category|Examples|Question it answers|
|---|---|---|
|**Content description**|`Content-Type`, `Content-Length`, `Content-Encoding`|"What is the payload, and how big?"|
|**Negotiation**|`Accept`, `Accept-Language`, `Accept-Encoding`|"What format do I want back?" (this is what `produces` checks)|
|**Authentication**|`Authorization`, `WWW-Authenticate`|"Who am I / prove who you are"|
|**State**|`Cookie`, `Set-Cookie`|"Remember me"|
|**Caching**|`Cache-Control`, `ETag`, `If-None-Match`, `Last-Modified`|"Can I reuse an old copy?"|
|**Routing/identity of the target**|`Host`, `Origin`, `Referer`|"Where was this sent, and from where?"|
|**Redirect/creation**|`Location`|"Go/find it here" (the one you built with `URI`)|
|**CORS**|`Access-Control-Allow-Origin`, `Access-Control-Expose-Headers`|"Which browser origins may read this?"|
|**Proxy info**|`X-Forwarded-For`, `X-Forwarded-Proto`, `Forwarded`|"What did the original request look like?"|
|**Custom**|`X-Total-Count`, `Idempotency-Key`|Your own metadata|

## Request headers vs response headers

Some belong to only one direction: `Accept` and `Authorization` are request-only; `Set-Cookie`, `Location`, and `Retry-After` are response-only. Some, like `Content-Type`, appear in both and describe whichever payload that message carries. This is why `Content-Type` on a request chooses the converter for `@RequestBody`, while `Accept` on the same request chooses the one for the response.

## In Spring

```java
// READ request headers
@GetMapping("/me")
public String me(@RequestHeader("Authorization") String auth,
                 @RequestHeader(value = "Accept-Language", defaultValue = "en") String lang) { ... }

// Read ALL of them
public void all(@RequestHeader HttpHeaders headers) { ... }
public void map(@RequestHeader Map<String, String> headers) { ... }

// SET response headers
return ResponseEntity.ok()
        .header("X-Total-Count", "42")
        .contentType(MediaType.APPLICATION_JSON)
        .body(data);
```

```bash
curl -i -H "Authorization: Bearer abc" -H "X-Custom: hi" http://localhost:8080/me
```

## Rules and edge cases

- **Names are case-insensitive** (`content-type` = `Content-Type`). HTTP/2 and HTTP/3 force them to lowercase on the wire. Values are case-sensitive depending on the header.
- **Repeated headers are allowed** and are equivalent to a comma-joined list (`Accept: a, b`). The major exception is `Set-Cookie`, which must **not** be merged because cookie values may contain commas. Each cookie gets its own `Set-Cookie` line.
- **The `X-` prefix is deprecated** by RFC 6648 for new headers, but it's still everywhere. New custom headers can use a plain name like `Idempotency-Key`.
- **Size limits:** Tomcat caps the whole header block at **8 KB** by default (`server.max-http-request-header-size`). Oversized headers (often from huge cookies) produce **400 or 431**.
- **Headers are visible to proxies and logs.** They aren't secret; they're only protected in transit by HTTPS. Don't put secrets in custom headers that get logged.
- **Browsers hide response headers from cross-origin JavaScript** unless listed in `Access-Control-Expose-Headers`. This is the `X-Total-Count` problem from earlier.
- **Header injection:** if you put unvalidated user input into a response header, a newline (`\r\n`) in it could inject extra headers. Modern servers reject this, but never build header values from raw input.

---

# 2. Payload

## Definition

The **payload** is the **actual data being carried** by a message, as opposed to the metadata describing it. In an HTTP request or response, it's the **body**:

```
POST /api/users HTTP/1.1
Content-Type: application/json      ← header (about the payload)
Content-Length: 38                  ← header (size of the payload)
                                    ← blank line
{"name":"Alireza","email":"a@b.com"}   ← PAYLOAD
```

The word comes from shipping: the **payload** of a truck is the cargo, as distinct from the truck, the fuel, and the paperwork. Headers are the truck and paperwork; the payload is the cargo.

## Payload vs body: are they the same?

In everyday HTTP talk, yes. Precisely, the HTTP specification (RFC 9110) calls the bytes on the wire the **message body**, and calls the _meaningful content_ after decoding the **content**/representation. The difference matters when the body is **transformed**:

```
Content-Encoding: gzip      ← body on the wire is compressed
Transfer-Encoding: chunked  ← body is sent in pieces
```

The _payload_ you care about is the decoded data; Spring/Tomcat undo gzip and chunking before your `@RequestBody` sees it.

## Payload formats

The header `Content-Type` tells the receiver how to interpret the bytes:

|Content-Type|Payload looks like|Spring reads it with|
|---|---|---|
|`application/json`|`{"a":1}`|`@RequestBody` (Jackson)|
|`application/x-www-form-urlencoded`|`name=Ali&age=30`|`@RequestParam` / `@ModelAttribute`|
|`multipart/form-data`|parts with files|`@RequestParam MultipartFile`|
|`text/plain`|raw text|`@RequestBody String`|
|`application/octet-stream`|raw bytes|`byte[]` / `Resource`|
|`application/pdf`, `image/png`|file bytes|`Resource` response|

**The pairing rule:** the payload is just bytes. **Without `Content-Type`, those bytes are meaningless**, which is exactly why a missing header gives you the 415 you learned about.

## Which messages have payloads?

|Message|Payload?|
|---|---|
|Request: POST, PUT, PATCH|yes, normally|
|Request: GET, DELETE|technically allowed but **semantically undefined**; avoid|
|Request: HEAD|no|
|Response: 200 with data|yes|
|Response: **204, 304, 1xx**|**must not** have one|
|Response to HEAD|no (headers only, with the size it _would_ have had)|

## How the receiver knows where the payload ends

Two mechanisms, both declared by headers:

- `Content-Length: 38`: "exactly 38 bytes follow".
- `Transfer-Encoding: chunked`: size unknown in advance (streaming); data arrives in sized chunks, ending with a zero-length chunk.

If these lie (length too short), the receiver gets a truncated body or the next request is misread. This is the basis of an attack class called **request smuggling**, one reason servers are strict about these headers.

## The word "payload" has other meanings

You'll meet this ambiguity constantly:

|Context|"Payload" means|
|---|---|
|HTTP / REST|the request or response body|
|**JWT** (JSON Web Token)|the **middle part** of the token containing the claims (`sub`, `exp`, ...). A JWT is `header.payload.signature`, so it has its own header and payload|
|Webhooks|the JSON the other service POSTs to you|
|Messaging (Kafka, RabbitMQ)|the message's content|
|Networking|the data inside a packet, after the packet's own headers|

The same idea everywhere: **payload = the cargo, header = the label on it**. Even a JWT follows it: its header says "algorithm: HS256", its payload carries the user claims.

## Rules and edge cases

- **The body can be read once** (a stream), hence one `@RequestBody` per method.
- **Payload size limits.** Spring Boot's multipart default is 1 MB per file (`spring.servlet.multipart.max-file-size`). Tomcat limits form POST bodies and, for JSON, relies on you and your gateway to cap it. Without a limit, a huge payload is a denial-of-service vector.
- **Encoding.** JSON is UTF-8 by spec. Declare it in `Content-Type: application/json; charset=utf-8` if there's any doubt about text types.
- **A JWT payload is encoded, not encrypted.** Base64 is trivially reversible (like decoding `_ga` earlier), so never put secrets in it.
- **Never trust the payload**: validate with `@Valid`, bind to DTOs, and cap sizes.

---

# 3. Cookie

## Definition

A cookie is a **small piece of data (name=value) that a server asks the browser to store, and that the browser automatically sends back with later requests to the same site**. It exists because of one design fact:

> **HTTP is stateless.** Each request is independent. The server has no built-in memory of who you are between requests.

Cookies bolt memory on: the server hands you a token (the wristband), and your browser shows it every time.

## The mechanism: two headers

```
1. LOGIN
   Client ──► POST /login  {"user":"ali","pass":"..."}

   Server ◄── 200 OK
              Set-Cookie: sessionId=abc123; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=3600

2. EVERY LATER REQUEST (browser does this automatically)
   Client ──► GET /api/orders
              Cookie: sessionId=abc123
   Server    looks up abc123 → "this is Ali" → returns Ali's orders
```

- **`Set-Cookie`** is a **response** header: "store this".
- **`Cookie`** is a **request** header: "here's what you stored for this site". Several cookies are joined in one line: `Cookie: a=1; b=2` (separated by `;` , not commas).

The key difference from a header you set yourself: **the browser attaches cookies automatically**, with no code in your front-end. That convenience is also the source of most cookie security issues.

## The attributes (this is where the depth is)

```
Set-Cookie: sessionId=abc123; Path=/; Domain=example.com; Max-Age=3600;
            Secure; HttpOnly; SameSite=Lax
```

|Attribute|What it does|Why it exists|
|---|---|---|
|**`Max-Age`** / **`Expires`**|Lifetime. Without either, it's a **session cookie**, deleted when the browser closes (roughly; browsers may restore sessions). `Max-Age=0` deletes it|Control how long login lasts|
|**`Path`**|Cookie is sent only for URLs under this path|Scoping; it's why a context path changes cookie behavior (mentioned earlier)|
|**`Domain`**|Which hosts receive it. Omit it and it's sent only to the **exact host** that set it. Set `example.com` and subdomains get it too|Share across subdomains, but it widens exposure|
|**`Secure`**|Only sent over **HTTPS**|Prevents leaking over plain HTTP|
|**`HttpOnly`**|**JavaScript cannot read it** (`document.cookie` hides it); the browser still sends it|Defends against **XSS** stealing the session|
|**`SameSite`**|Whether the cookie is sent on **cross-site** requests: `Strict`, `Lax`, `None`|Defends against **CSRF**|
|**`Partitioned`** (CHIPS)|Separates third-party cookies per top-level site|Modern privacy mechanism|

### SameSite in detail

"Site" means the registrable domain (`example.com`), ignoring subdomains and ports.

|Value|Sent when...|Use|
|---|---|---|
|`Strict`|only when the request originates from the **same site**|highest protection; but following a link from email to your site arrives logged-out|
|`Lax`|same-site, plus **top-level navigations with safe methods** (clicking a link, GET)|the browser default today; good balance|
|`None`|always, including cross-site; **requires `Secure`**|third-party embeds, cross-site APIs|

**Why it matters:** imagine you're logged into your bank. A malicious page contains a hidden form that POSTs to `bank.com/transfer`. Your browser, being helpful, attaches your bank cookie automatically. The bank sees a valid session and moves money. This is **CSRF** (Cross-Site Request Forgery). `SameSite=Lax` blocks the cross-site POST from carrying the cookie.

### Cookie prefixes

`__Host-` and `__Secure-` name prefixes make the browser **enforce** attribute rules: a `__Host-session` cookie is accepted only if it's `Secure`, has `Path=/`, and has **no** `Domain`, which locks it to exactly one host. Use them for session cookies when you can.

## First-party vs third-party cookies

- **First-party:** set by the site you're visiting (`sdbullion.com` sets its own cookie).
- **Third-party:** set by _another_ domain embedded in the page (an ad network, analytics). Browsers are increasingly restricting these (Safari and Firefox block them by default; Chrome has its own evolving controls), which is **why `_gl` exists**: it carries identity in the URL when a cookie can't cross domains. This connects directly to your previous question; `_ga` was a first-party cookie, and `_gl` is the URL-borne copy of it.

## In Spring

**Reading:**

```java
@GetMapping("/me")
public String me(@CookieValue(name = "sessionId", required = false) String session) { ... }
```

**Setting (the right way):**

```java
@PostMapping("/login")
public ResponseEntity<Void> login(@RequestBody LoginRequest req) {
    String token = authService.login(req);

    ResponseCookie cookie = ResponseCookie.from("sessionId", token)
            .httpOnly(true)
            .secure(true)
            .sameSite("Lax")
            .path("/")
            .maxAge(Duration.ofHours(1))
            .build();

    return ResponseEntity.noContent()
            .header(HttpHeaders.SET_COOKIE, cookie.toString())
            .build();
}
```

**Deleting:** send the same name, same `Path`/`Domain`, with `maxAge(0)`. If `Path` or `Domain` differ from the original, the browser treats it as a **different cookie** and won't delete the old one.

`ResponseCookie` is preferred over the servlet `jakarta.servlet.http.Cookie` because the servlet class has **no `SameSite` support** and a clumsier API.

**Spring's own session cookie** (when you use `HttpSession` or Spring Security): the server creates a cookie named `JSESSIONID`. Configure it:

```properties
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
server.servlet.session.timeout=30m
```

**Testing from Debian:**

```bash
curl -i -c jar.txt -X POST http://localhost:8080/login ...   # -c saves cookies to a file
curl -b jar.txt http://localhost:8080/api/orders             # -b sends them back
```

Also, in the browser: DevTools, Application tab, Cookies, shows every attribute.

## Where cookies sit between header and payload

A cookie is **not a separate thing from headers**. It's carried _by_ two headers (`Set-Cookie` and `Cookie`). So:

```
HTTP message
├── Headers   ← includes Cookie / Set-Cookie
└── Payload   ← the data
```

## Rules and edge cases

- **Size and count limits:** roughly **4 KB per cookie** and about 50 cookies per domain (browser-dependent). All matching cookies ride on **every request**, so bloated cookies slow every call and can trigger 431.
- **Never store sensitive data in the cookie itself.** Store an **opaque session ID** and keep the data on the server (the classic **session** model), or use a **signed** token. The browser user can edit any cookie.
- **Cookies and CORS:** for cross-origin Angular calls (`localhost:4200` to `localhost:8080`), cookies are **not sent by default**. You need `withCredentials: true` in Angular **and** `allowCredentials(true)` in Spring's CORS config, and then `allowedOrigins("*")` becomes illegal (you must list exact origins). Another reason the CORS example listed an explicit origin.
- **`localhost` quirks:** ports are _not_ part of cookie scope, so `localhost:4200` and `localhost:8080` **share** cookies, but they are different **origins** for CORS. Easy to confuse.
- **Cookie vs `Authorization` header for auth:** cookies are sent automatically (convenient, but need CSRF protection); an `Authorization: Bearer` header is added by your code (immune to CSRF, but JavaScript must hold the token, so XSS can steal it). Neither is universally best; with an Angular front-end, a common secure choice is an `HttpOnly` cookie plus CSRF defenses.
- **Cookies are not "sessions".** A session is _server-side state_; the cookie merely carries the session's ID. Deleting the cookie doesn't delete the server's session data.
- **Legal angle:** in the EU (you're in Zürich, so Swiss law applies similarly) non-essential cookies, such as analytics and advertising, usually require consent. Strictly necessary ones, like a login session, generally don't. That's why websites show cookie banners.

---

# Comparison

||**Header**|**Payload**|**Cookie**|
|---|---|---|---|
|What it is|metadata line `Name: value`|the actual data|a stored `name=value` the server asks the browser to keep|
|Purpose|describe/control the exchange|deliver the content|remember state across stateless requests|
|Direction|request and response|request and response|set by response, returned by request|
|Lives in|between first line and blank line|after the blank line|**inside** headers (`Set-Cookie`, `Cookie`)|
|Who controls it|both sides|both sides|server sets, **browser** stores and sends automatically|
|Spring (read)|`@RequestHeader`|`@RequestBody`|`@CookieValue`|
|Spring (write)|`ResponseEntity.header(...)`|return value|`ResponseCookie` + `Set-Cookie`|
|Size limit|~8 KB total|large (configurable)|~4 KB each|
|Typical content|`Content-Type`, `Authorization`|JSON, files|session ID, preferences|

## Where each goes: a decision guide

|Data|Place|Why|
|---|---|---|
|The object being created or updated|**payload**|structured, can be large, validated|
|Format, language, version, idempotency key, auth token|**header**|about the request, not the entity|
|"Remember this browser/login"|**cookie** (`HttpOnly`, `Secure`, `SameSite`)|the browser attaches it for you|
|Which item / filters|path / query|see URL design|

## The whole picture, connected

```
Request:   POST /api/users  HTTP/1.1                  ← request line  (URL design lesson)
           Content-Type: application/json             ┐
           Cookie: sessionId=abc123                   ├ HEADERS (incl. cookie)
           Idempotency-Key: 9f1c                      ┘
                                                      ← blank line
           {"name":"Ali"}                             ← PAYLOAD
```





[[Spring Framework]]
[[Networking]]