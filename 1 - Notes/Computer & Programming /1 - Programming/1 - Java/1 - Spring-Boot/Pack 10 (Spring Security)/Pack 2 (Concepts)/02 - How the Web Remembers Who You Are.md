

You log in, click a link, and the site still knows it's you. That feels normal, but it's surprising once you know how the web works underneath. Let's see how it's done, and what you need to keep it safe.

## The problem: HTTP forgets everything

HTTP is **stateless**. Each request arrives on its own, and the server treats it as if it's the first one it has ever seen from you.

Imagine a shop clerk with no memory. You walk up, say "I'm Alice, here's my password," and she lets you in. You take one step, and now she's forgotten you. You'd have to show your password again for every single page.

That would be unusable, so we need a way for each request to _carry proof_ of the earlier login. There are two common answers: **sessions with cookies**, and **tokens**. Both solve the same problem. They differ in _who does the remembering_.

## A quick tour of HTTP

Before we look at the two answers, you need a few HTTP basics, because both are built from them.

A request and a response each have a **start line**, **headers**, and an optional **body**:

```
GET /orders HTTP/1.1
Host: shop.example.com
Accept: application/json
Cookie: JSESSIONID=abc123
```

```
HTTP/1.1 200 OK
Content-Type: application/json

[{"id": 5, "total": 42.00}]
```

**Headers** are `Name: value` lines that carry information _about_ the message, not the message itself. A few you'll meet constantly:

|Header|Direction|What it does|
|---|---|---|
|`Cookie`|request|The browser sends back the cookies it has stored|
|`Set-Cookie`|response|The server asks the browser to store a cookie|
|`Authorization`|request|Carries credentials or a token|
|`WWW-Authenticate`|response|Says how to authenticate (sent with a 401)|
|`Content-Type`|both|Describes the body format, like `application/json`|

**Status codes** are the three-digit number in the response. They're grouped by their first digit:

- **2xx**: success (`200 OK`, `201 Created`)
- **3xx**: redirect (`302 Found`)
- **4xx**: _you_ made a mistake (`400`, `401`, `403`, `404`)
- **5xx**: the _server_ failed (`500`)

Now for the two answers.

## Answer 1: Sessions and cookies

In this approach, **the server remembers you**.

Here's the whole flow:

1. You send your username and password to `POST /login`.
2. The server checks them. They're good.
3. The server creates a **session**: a record in its memory (or a database or Redis) that says "session `abc123` belongs to alice."
4. The server sends back a response with a `Set-Cookie` header:

```
HTTP/1.1 200 OK
Set-Cookie: JSESSIONID=abc123; HttpOnly; Secure; SameSite=Lax
```

5. Your browser stores that cookie. From now on, it automatically attaches it to every request to that site:

```
GET /orders HTTP/1.1
Cookie: JSESSIONID=abc123
```

6. The server looks up `abc123`, finds "alice," and knows who you are.

Think of a coat check. You hand over your coat (log in) and get a numbered ticket (the cookie). The ticket means nothing by itself. The attendant keeps the real information behind the counter. Whoever holds ticket 123 gets coat 123.

The key point is that the cookie holds **only an ID**, not your identity. The real data lives on the server. In Spring Boot, that ID cookie is called `JSESSIONID` by default.

### Why people like sessions

- **Easy to cancel.** Delete the session on the server and the user is logged out instantly.
- **Secrets stay on the server.** The browser only holds a meaningless ID.
- **The browser does the work.** Cookies are sent automatically, so your frontend code doesn't have to.

### The catch

The server has to _store_ every session. If you run several servers behind a load balancer, they all need to find the same session. You'd use "sticky" routing, or a shared store like Redis. That's one reason Redis shows up so often next to Spring apps.

## Cookie flags: the safety switches

A cookie is a small piece of data, and cookies can be stolen or misused. Three flags, set on the `Set-Cookie` header, protect them. You should use all three on any login cookie.

### `HttpOnly`: hide it from JavaScript

Normally, any JavaScript running on your page can read cookies through `document.cookie`. If an attacker manages to inject a script into your page (an attack called **XSS**, cross-site scripting), they could read your session cookie and steal your login.

`HttpOnly` tells the browser: _only send this cookie in HTTP requests. Don't let JavaScript see it._ The script can no longer read it.

### `Secure`: HTTPS only

Without `Secure`, the browser might send your cookie over plain, unencrypted HTTP, where anyone on the same network could read it. `Secure` says: _only send this cookie over HTTPS._

### `SameSite`: don't send it from other sites

By default, a browser may attach your cookie even when the request was triggered by a _different_ website. That enables **CSRF** (cross-site request forgery). A malicious page could quietly make your browser submit a "transfer money" request to your bank, and your cookie would go along for the ride.

`SameSite` controls this. It has three values:

|Value|Behavior|
|---|---|
|`Strict`|Cookie is sent only for requests that start on your own site. Safest, but clicking a link to your site from elsewhere arrives logged out.|
|`Lax`|Cookie is sent on your own site's requests _and_ on simple top-level navigations, like clicking a link. Blocked for cross-site form posts and background requests. A good default.|
|`None`|Cookie is sent everywhere. This _requires_ the `Secure` flag.|

Modern browsers treat a cookie with no `SameSite` as `Lax`, but it's better to say so explicitly.

A few other attributes control lifetime and scope, and you'll see them too. `Max-Age` or `Expires` say when the cookie dies, and `Path` and `Domain` say which URLs receive it. If you set none of the lifetime ones, you get a **session cookie** that disappears when the browser closes.

Here's what a well-protected login cookie looks like:

```
Set-Cookie: JSESSIONID=abc123; Path=/; Max-Age=3600; HttpOnly; Secure; SameSite=Lax
```

## Answer 2: Tokens

In this approach, **the server doesn't need to remember you.** Instead, you carry your own proof.

1. You send your username and password to `POST /login`.
2. The server checks them, then builds a small piece of data about you, like "this is alice, role ADMIN, expires in 15 minutes."
3. It **signs** that data with a secret key and hands the result to you. That signed data is the **token**.
4. On every request, you send the token back in the `Authorization` header:

```
GET /orders HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbGljZSJ9.x7Kf...
```

5. The server checks the signature. If it's valid, the server trusts what's inside. It doesn't look anything up.

"Bearer" simply means _whoever bears (holds) this token is treated as the user._ That's also why you must guard tokens carefully.

A signed token is like a concert wristband with a hologram. The staff doesn't check a list. They just check that the hologram is genuine.

### What's inside a JWT

The most common token format is the **JWT** (JSON Web Token, pronounced "jot"). It has three parts separated by dots:

```
header . payload . signature
```

- The **header** says which signing algorithm was used.
- The **payload** holds the claims, like `sub` (the user), `roles`, and `exp` (expiry time).
- The **signature** proves nobody changed the first two parts.

The most important thing to understand is that **a JWT is signed, not encrypted**. Anyone can decode the payload and read it. The signature only stops people from _changing_ it. So never put secrets, like passwords, inside a token.

### Why people like tokens

- **Stateless servers.** Nothing to store, so scaling across many servers is easy.
- **Works across services.** One token can be accepted by several different APIs.
- **Fits non-browser clients.** Mobile apps and API consumers handle a header more naturally than cookies.

### The catch

- **Hard to cancel.** The server doesn't track tokens, so it can't just delete one. A stolen token works until it expires. The usual fix is short-lived tokens, plus a separate **refresh token** to get new ones.
- **Where do you keep it?** If you store it in the browser's `localStorage`, JavaScript can read it, so an XSS attack can steal it. If you store it in an `HttpOnly` cookie, you get cookie protection back, but you need to think about CSRF again.

## Sessions or tokens?

||**Sessions + cookies**|**Tokens (JWT)**|
|---|---|---|
|Who remembers you?|The server|You (the client)|
|What you send|A random ID|A signed data blob|
|Carried in|`Cookie` header|`Authorization` header|
|Logging someone out|Easy: delete the session|Hard: wait for expiry|
|Scaling|Needs shared session storage|Simple|
|Best fit|Traditional websites|APIs, mobile apps, many services|

Neither one is "better." A server-rendered website with a login page is usually happiest with sessions. A separate frontend, a mobile app, or an API used by many clients often prefers tokens.

## Back to 401 vs. 403

Now you can see where these two status codes come from. They describe what went wrong _after_ the server looks at your cookie or token.

**401 Unauthorized** means _not logged in_. The request had no cookie or token, or it was invalid or expired. The server says "I don't know who you are." The fix is to authenticate. A 401 response often includes a `WWW-Authenticate` header that says how.

**403 Forbidden** means _logged in, but not allowed_. The server knows exactly who you are, and the answer is still no. Logging in again won't help. You need different permissions.

```
No cookie / bad token            →  401  "Who are you?"
Valid login, but a USER visits
/admin                           →  403  "I know you, and no."
```

The name "Unauthorized" for 401 is a historical mistake. It really means "unauthenticated." If you remember that, you'll debug faster.

Some other codes you'll run into while building login flows:

- **400 Bad Request**: the request itself was malformed.
- **404 Not Found**: the resource doesn't exist. Some apps deliberately return 404 instead of 403 to avoid revealing that a secret page exists.
- **302 Found**: a redirect. A website often redirects you to `/login` instead of returning a 401.

## How this looks in Spring Security

Since you work with Spring Boot, here's where these ideas live:

- **Sessions** are the default. After a successful form login, Spring creates a session and sends `JSESSIONID`. It also changes the session ID at login, which blocks an attack called _session fixation_.
- **Tokens** are supported through the OAuth2 resource server, which checks a `Bearer` JWT on each request.
- **Cookie flags** can be set in `application.properties`:

```properties
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
```

- **401 and 403** are produced by two pieces: an `AuthenticationEntryPoint` handles unauthenticated requests (401), and an `AccessDeniedHandler` handles authenticated-but-denied requests (403).

## Mistakes to avoid

- **Leaving off `HttpOnly`, `Secure`, or `SameSite`** on a login cookie.
- **Putting secrets in a JWT.** Remember that anyone can read the payload.
- **Making tokens that never expire.** A stolen one would work forever.
- **Returning 403 when you mean 401** (or the reverse). Clients use these codes to decide whether to show a login screen.
- **Trusting the client's claims.** Always verify the session or signature on the server.

## Summary

- HTTP is **stateless**, so every request needs to carry proof of who you are.
- **Sessions + cookies:** the server remembers you and gives your browser an ID. The browser sends it back automatically.
- **Tokens:** the server gives you signed data. You send it in the `Authorization` header, and the server remembers nothing.
- Protect cookies with **`HttpOnly`** (hidden from JavaScript), **`Secure`** (HTTPS only), and **`SameSite`** (blocks cross-site misuse).
- **401** means "not logged in." **403** means "logged in, but not allowed."



[[Spring Security]]