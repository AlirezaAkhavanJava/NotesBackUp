

A **Bearer header** is an HTTP header named `Authorization` whose value starts with the word `Bearer`, followed by a space and a token. It looks like this: `Authorization: Bearer eyJhbGciOi...`. The word "bearer" means "whoever holds this." It tells the server: "I am carrying a token. Treat me as the person this token was issued to."

So the two ideas fit together like an envelope and a letter. The **JWT is the letter**: it holds the data and the signature. The **Bearer header is the envelope**: it is the agreed way of delivering the letter to the server on every request. This is exactly the header your `JwtAuthFilter` reads when it calls `request.getHeader("Authorization")`.

## The whole thing in one picture

```
1. Login      POST /api/auth/login  {username, password}
              ◄── {"token": "eyJ...abc"}

2. Every      GET /api/me
   request    Authorization: Bearer eyJ...abc      ◄── the Bearer header
              │
              ▼
              JwtAuthFilter reads it, checks the JWT, sets the user
```

The token comes back **once**, in the body of the login response. After that, the client attaches it to every request as a Bearer header.

## Anatomy of the header

```
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhbGljZSJ9.x7A...
└─────┬──────┘ └─┬──┘ └────────────────────┬────────────────────┘
   header name  scheme                  credentials
```

|Part|Meaning|
|---|---|
|`Authorization`|The standard HTTP header for sending credentials|
|`Bearer`|The **scheme**: it names the kind of credentials that follow|
|one space|A single space separates the scheme from the credentials|
|the token|Your JWT, the three Base64URL parts joined by dots|

The Bearer scheme is defined by the OAuth 2.0 standard (RFC 6750). That is why you will see the same header in almost every modern API, not only in Spring.

## Bearer is not the same thing as JWT

Beginners often treat them as one idea. They are two separate decisions:

|Question|Answer|
|---|---|
|**What is the token?**|A JWT is one choice. It could also be a random string that the server looks up in a database.|
|**How is the token sent?**|The Bearer header is the usual choice. It could also be a cookie.|

A Bearer header can carry any token, and a JWT can travel in places other than a Bearer header. They are paired so often because the combination works well: the JWT is self-contained, and the header is explicit.

## Bearer compared with the other common scheme

||`Basic`|`Bearer`|
|---|---|---|
|Header|`Authorization: Basic YWxpY2U6c2VjcmV0MTIz`|`Authorization: Bearer eyJ...`|
|What is sent|`username:password` in Base64|A token|
|Sent when|On **every** request|On every request, but it's not the password|
|If intercepted|The attacker has the real password|The attacker has a token that will expire|
|Revocable|Only by changing the password|By expiry (and by a blocklist, if you build one)|

The Base64 in `Basic` is not encryption. `YWxpY2U6c2VjcmV0MTIz` decodes straight back to `alice:secret123`. With Bearer, the password is sent **once** at login, and after that only a short-lived token travels.

## How the server reads it: your filter, line by line

```java
String header = request.getHeader(HttpHeaders.AUTHORIZATION);   // 1

if (header == null || !header.startsWith("Bearer ")) {          // 2
    filterChain.doFilter(request, response);
    return;
}

String token = header.substring(7);                             // 3
```

1. `HttpHeaders.AUTHORIZATION` is Spring's constant for the string `"Authorization"`. It avoids typos.
2. `startsWith("Bearer ")` includes the trailing space on purpose. It makes sure the header really uses the Bearer scheme, and not `Basic` or something else. A missing header returns `null`, so that is checked first.
3. `"Bearer "` has 7 characters (6 letters and the space), so `substring(7)` leaves only the token. That string goes to `jwtService`.

## How a client sends it

**curl (Debian):**

```bash
curl http://localhost:8080/api/me \
  -H "Authorization: Bearer $TOKEN"
```

**PowerShell (Windows):**

```powershell
Invoke-RestMethod -Uri http://localhost:8080/api/me `
  -Headers @{ Authorization = "Bearer $token" }
```

**JavaScript in a browser:**

```javascript
const res = await fetch("http://localhost:8080/api/me", {
  headers: { Authorization: `Bearer ${token}` }
});
```

**Java, calling another API with Spring's `RestClient`:**

```java
String body = RestClient.create()
        .get()
        .uri("http://localhost:8080/api/me")
        .headers(h -> h.setBearerAuth(token))   // builds "Bearer <token>" for you
        .retrieve()
        .body(String.class);
```

`setBearerAuth(token)` adds the word `Bearer` and the space itself, so you pass only the token. It prevents the classic mistake of writing `Bearer Bearer xyz`.

In Postman, open the **Authorization** tab, choose the type **Bearer Token**, and paste the token without the word "Bearer."

## Why a header, and not the URL, the body or a cookie?

|Place|Problem|
|---|---|
|URL (`/api/me?token=...`)|URLs end up in server logs, browser history and the `Referer` header, so the token leaks|
|Request body|GET requests have no body, and it mixes authentication with business data|
|Cookie|The browser attaches cookies **automatically**, which opens the door to CSRF attacks|
|`Authorization` header|Not logged by default, and the code must add it deliberately|

That last point is the reason `csrf.disable()` is acceptable in a Bearer-header API. A malicious website can make your browser send a cookie, but it cannot make your browser add an `Authorization` header it doesn't know about.

## The security idea behind "bearer"

A bearer token works like cash or a concert ticket. The server never asks "who is carrying this?" It only asks "is this token valid?" Anyone who holds a valid token gets in. Three things follow from that:

- **Always use HTTPS.** On plain HTTP, anyone on the network can read the header and copy the token.
- **Keep tokens short-lived.** A stolen token works until `exp`, so 5 to 15 minutes limits the damage.
- **Never log the header.** Request logging that prints all headers will write your tokens into log files.

Where the client stores the token is a real trade-off. In `localStorage`, JavaScript can read it, so an XSS bug can steal it. In an `HttpOnly` cookie, JavaScript can't read it, but then CSRF protection matters again. There is no perfect answer, only a choice of which risk you manage.

## What the server should answer when it's missing

The standard says a `401` response should include a `WWW-Authenticate` header that names the scheme. You can add it to the entry point from your `SecurityConfig`:

```java
.authenticationEntryPoint((req, res, e) -> {
    res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    res.setHeader("WWW-Authenticate", "Bearer");
    res.setContentType("application/json");
    res.getWriter().write("{\"error\":\"Unauthorized\"}");
})
```

This tells the client "authenticate using the Bearer scheme." Many clients ignore it, but it is the correct behavior.

## Common mistakes

- **Missing the space.** `Bearer<token>` or `Bearer token` with two spaces fails the `startsWith("Bearer ")` check or leaves a leading space in the token.
- **Doubling the word.** Writing `Bearer Bearer xyz`, usually because the library already adds the prefix.
- **Sending the quotes.** Copying `"token":"eyJ..."` from the JSON response with the quote marks included. The token itself has no quotes.
- **A line break inside the token.** Pasting from a wrapped terminal can add a hidden newline. A strange `MalformedJwtException` is the usual sign.
- **Using the wrong header name.** `Authentication` instead of `Authorization` is a very common typo.
- **Forgetting CORS in a browser app.** If your front end runs on a different origin from the API, the `Authorization` header triggers a preflight `OPTIONS` request. Your Spring CORS config must allow that header, or the browser blocks the call before it reaches your filter.
- **Testing without the header and expecting 403.** A missing token now gives `401` with your entry point. `403` appears only when the user is known but not allowed.

## A related concept: opaque tokens

A Bearer header doesn't have to carry a JWT. An **opaque token** is a random string like `9f8a2c...` with no meaning on its own. The server stores it in a database or cache (Redis is a common choice) and looks it up on each request. This is slower, because it needs a lookup, but you can revoke a token instantly by deleting it. A JWT is the opposite: it needs no lookup, but you can't take it back before it expires. Both travel in the same `Authorization: Bearer` header, which shows again that the header and the token type are separate choices.




[[Spring Security]]