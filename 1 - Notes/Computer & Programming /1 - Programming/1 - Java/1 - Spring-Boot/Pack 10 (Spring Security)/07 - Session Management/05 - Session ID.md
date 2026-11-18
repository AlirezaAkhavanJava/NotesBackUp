

HTTP has no memory, so without a session ID you would have to log in again on every single click. The session ID is the small trick that lets a website recognize you from one request to the next. It sits underneath login, shopping carts, and everything we just covered about CSRF.

## The problem it solves

HTTP is **stateless**. Each request is independent, and the server treats it as if it had never seen you before. That was fine for the early web, where pages were just documents. It breaks the moment you want:

- "Stay logged in as Ahmed."
- "Remember the 3 items in my cart."
- "Show my own dashboard, not someone else's."

The server needs a way to link request #1, request #2, and request #3 to the same person. The session ID is that link.

## The core idea

The server gives you a **random ticket number** and keeps your real data on its own side.

- **Your data** (who you are, your cart, your roles) stays **on the server**, in a place called the **session store**.
- **The session ID** is just a random string, like `7F3A9C...`, that points to that data.
- Your browser sends the ID back on every request, and the server uses it to look up your data.

Think of a coat check. You hand over your coat and get a numbered ticket. The ticket is worthless by itself, but whoever holds it can claim the coat. The session ID works the same way, and that is also why you must protect it.

## A short history

**The early web (1991 to 1993).** Tim Berners-Lee's first HTTP had no concept of identity. Servers answered each request and forgot you instantly.

**Early workarounds.** Developers tried tricks to carry identity along:

- **Hidden form fields:** each page's form contained a secret value that was sent to the next page. This worked only while you kept clicking through forms.
- **URL rewriting:** the ID was placed in the address itself, like `shop.com/cart?sid=12345`. It worked, but it was ugly, and sharing or bookmarking a link also shared your session.

**Cookies (1994).** Lou Montulli at Netscape invented the **cookie**, reportedly to solve an online shopping cart problem. A cookie is a small piece of text that the server asks the browser to store and send back automatically with every request to that site. That made session IDs practical, because the ID could ride in a cookie without touching the page or URL.

**Standardization.** Cookies were specified in the late 1990s (RFC 2109), and later in a cleaner form (RFC 6265, 2011). Server platforms added built-in session support: Java's `HttpSession` appeared in the Servlet API in the late 1990s (you've seen `JSESSIONID`), and PHP got `PHPSESSID`.

**Learning from attacks (2000s onward).** Early implementations had real weaknesses:

- IDs that were **predictable** (sequential or guessable), so attackers could guess valid ones.
- **Session fixation:** the attacker plants a known ID on you and waits for you to log in with it.
- **Session hijacking:** stealing someone's ID through XSS or network sniffing.

These led to defenses that are now standard: long random IDs, the `HttpOnly` and `Secure` cookie flags, `SameSite`, and changing the ID at login. The modern web is the result of fixing those problems one by one.

## How it works, step by step

1. **First visit.** You open the site. The browser has no session ID yet.
2. **The server creates a session.** It generates a long random ID and creates an entry in its session store, for example `7F3A9C → { }` (empty for now).
3. **The server sends the ID back** in a response header:

```
Set-Cookie: JSESSIONID=7F3A9C...; Path=/; HttpOnly; Secure; SameSite=Lax
```

4. **The browser stores the cookie.** From now on, it automatically attaches this cookie to every request to that site:

```
Cookie: JSESSIONID=7F3A9C...
```

5. **You log in.** The server finds your session by the ID and saves your identity in it: `7F3A9C → { user: "ahmed", roles: [USER] }`.
6. **Later requests.** The browser sends the cookie, the server looks up `7F3A9C`, finds your data, and knows who you are.
7. **Logout or timeout.** The server deletes the entry. The ID you were holding now points to nothing, so it is useless.

Notice that the browser never stores your identity. It stores only the ticket. That is why `JSESSIONID` is meaningless to anyone who steals it _without_ a live session behind it, and dangerous to you if they steal it _while_ the session is alive.

## What makes a good session ID

- **Long and random.** OWASP recommends at least 128 bits of length with at least 64 bits of real randomness, produced by a **cryptographically secure** generator. An attacker should have no realistic way to guess one.
- **Meaningless.** It must not contain your username, email, or time. It is only a pointer.
- **Short-lived.** It expires after inactivity (for example 30 minutes) and, for sensitive apps, after an absolute limit too.
- **Replaced at login.** The ID you had _before_ logging in must not survive _after_ logging in. This blocks session fixation.

## How the cookie flags protect it

|Flag|What it does|
|---|---|
|`HttpOnly`|JavaScript can't read the cookie, so an XSS attack can't steal it|
|`Secure`|The browser sends it only over HTTPS, so it isn't exposed on the network|
|`SameSite`|The browser doesn't send it on most cross-site requests, which helps against CSRF|

## In your Java world

- Tomcat creates the session and the `JSESSIONID` cookie for you. In code, `HttpSession` is the object attached to that ID.
- Spring Security's **session fixation protection** is on by default. When you log in, it changes the session ID (`changeSessionId`) while keeping your data.
- The `SecurityContext` we talked about, holding your `Authentication`, is what gets saved _inside_ the session after login.
- With `SessionCreationPolicy.STATELESS`, Spring does not create sessions at all. That is the JWT style, where the token replaces the session ID.

## The limits of session IDs

Because the data lives **on the server**, sessions have a cost:

- **Memory:** every logged-in user takes up space on the server.
- **Scaling:** if you run 3 servers, user A's session may exist on server 1 only. A request that lands on server 2 would look logged out. There are two usual fixes. **Sticky sessions** make the load balancer always send you to the same server. A **shared session store** keeps sessions in one place that all servers can reach. **Spring Session** with a store like Redis is the common way to do the second one.

This is one big reason token-based approaches like JWT became popular: the server doesn't have to remember anything.

## Related concepts, in short

- **Cookie:** a small piece of text the browser stores for a site and sends back automatically. Sessions use a cookie as the carrier, but a cookie can hold other things too.
- **Session fixation:** an attack where the attacker gets you to use a session ID _they already know_, then waits for you to log in. Changing the ID at login defeats it.
- **Session hijacking:** stealing a valid session ID and using it as if you were the user. `HttpOnly`, `Secure`, and HTTPS are the main defenses.
- **JWT:** a signed token that carries your identity _inside itself_, so the server needs no session store. It trades server memory for harder revocation.

## Summary

HTTP forgets you after every request, so servers created the session ID: a long random ticket that points to your data on the server. Cookies, invented in 1994, made it automatic, and years of attacks taught us to make IDs unguessable, hidden from JavaScript, sent only over HTTPS, and replaced at login.





[[Spring Security]]