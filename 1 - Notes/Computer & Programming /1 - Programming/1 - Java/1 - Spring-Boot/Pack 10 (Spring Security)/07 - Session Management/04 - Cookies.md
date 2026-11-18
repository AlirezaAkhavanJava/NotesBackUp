

Cookies let a website remember you. Without them, every page you load would feel like your first visit. You'd log in again on every click, and your shopping cart would empty itself.

## The problem cookies solve

HTTP is **stateless**. That means the server treats every request as brand new and keeps no memory of the previous one. You send a request, you get a response, and the server forgets you.

That's a problem. After you log in, the server needs to know that your next request is still _you_. Cookies fix this.

## What a cookie is

A cookie is a small piece of text that a server asks your browser to store. The browser then sends it back automatically on later requests to that same site.

Think of a coat check. You hand over your coat and get a numbered ticket. You don't carry the coat around. You just show the ticket, and they know which coat is yours. The cookie is the ticket.

## How it works, step by step

**1. You visit or log in.** The server answers with a `Set-Cookie` header:

```
HTTP/1.1 200 OK
Set-Cookie: JSESSIONID=A1B2C3D4; Path=/; HttpOnly; Secure; SameSite=Lax
```

**2. Your browser stores it.** It saves the cookie and remembers which site it belongs to.

**3. Every later request carries it.** The browser adds a `Cookie` header on its own. You write no code for this:

```
GET /profile HTTP/1.1
Cookie: JSESSIONID=A1B2C3D4
```

**4. The server recognizes you.** It looks up `A1B2C3D4`, finds your session, and knows who you are.

Notice that the cookie usually holds only an ID, not your actual data. The data stays on the server.

## The settings on a cookie

A cookie is more than a name and a value. These attributes control how it behaves, and several of them matter a lot for security.

|Attribute|What it does|
|---|---|
|`Expires` / `Max-Age`|When the cookie dies. Without either, it disappears when you close the browser.|
|`Domain`|Which domains receive the cookie.|
|`Path`|Which URL paths receive it, such as `/` for the whole site.|
|`Secure`|Only send it over HTTPS. This stops it from leaking on plain HTTP.|
|`HttpOnly`|JavaScript can't read it. This protects it if an attacker injects a script (XSS).|
|`SameSite`|Controls whether it's sent on requests that start from other sites. This helps against CSRF.|

If you remember only one thing from this table, make it this: **a login cookie should almost always be `HttpOnly` and `Secure`.**

## Kinds of cookies

- **Session cookies** have no expiry date. They vanish when the browser closes. Logins often use these.
- **Persistent cookies** have an expiry date, so they survive restarts. "Remember me" uses these.
- **First-party cookies** come from the site you're visiting.
- **Third-party cookies** come from a different domain, such as an ad network embedded in the page. Browsers are limiting these because they enable cross-site tracking.

## Limits to know

- A cookie is small, roughly 4 KB each.
- Browsers cap how many cookies one site can set.
- The browser sends cookies on _every_ matching request, so big cookies slow everything down.
- The user can view, edit, and delete their own cookies. **Never trust a cookie's contents without checking them on the server.**

## Where you'll meet cookies in Spring Security

Cookies show up right away in the servlet world from your last question:

- **`JSESSIONID`** is the session cookie. After you log in, Spring Security stores your `Authentication` in the server-side `HttpSession`, and this cookie is the ticket that points to it.
- **`XSRF-TOKEN`** is the cookie that carries a CSRF token when you configure `CookieCsrfTokenRepository`.
- **`remember-me`** is the persistent cookie that keeps you logged in across browser restarts.

You can tighten the session cookie in `application.properties`:

```properties
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.same-site=lax
```

## A quick related concept: sessions

A **session** is the server-side memory that goes with a cookie. The cookie holds a small ID. The session holds the real data, such as who you are and what's in your cart. The two work as a pair: the cookie is the ticket, and the session is the coat. This is why a stolen session cookie is dangerous. Whoever holds the ticket can claim the coat.




[[Spring Security]]