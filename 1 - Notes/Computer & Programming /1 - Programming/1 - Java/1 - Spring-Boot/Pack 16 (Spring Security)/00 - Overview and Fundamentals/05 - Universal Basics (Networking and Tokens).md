

Spring Security's ideas aren't Spring-specific — they're universal: two problems every networked system has to solve. **Find each other and move data** (networking), and **prove identity across many separate requests without resending a password each time** (tokens). Everything else — sessions, cookies, CSRF, JWT — is an answer to one of these two problems.

## Part 1 — Networking

Sending data across the internet is split into layers, each solving one problem and trusting the layer below it:

|Layer|Job|Example|
|---|---|---|
|Application|The actual message|HTTP, DNS|
|Security|Seal the envelope|TLS|
|Transport|Reliable, ordered delivery|TCP, UDP|
|Internet|Addressing|IP|
|Link|Physical transmission|Wi-Fi, Ethernet|

**IP + port**: an IP address finds the machine (`127.0.0.1` = "this machine"); a port finds the program on it (`443` HTTPS, `5432` Postgres, `8080` your Spring Boot default). IP + port together is a **socket**.

**DNS** resolves a name to an IP (browser cache → OS → ISP resolver → root → `.com` servers → the domain's own server). Check it with `dig example.com +short`. If DNS can be lied to, you can be sent to a fake server — which is exactly why TLS certificates exist: even landing on the wrong IP, an attacker can't present a valid cert for the real name.

**TCP** turns IP's unreliable packets into a dependable stream, starting with a handshake (`SYN` → `SYN-ACK` → `ACK`). UDP skips all that for speed (video, games, DNS, and HTTP/3's QUIC).

**TLS** sits on top of TCP and adds: nobody can read it, nobody can change it, you're talking to the right server. It works by combining two kinds of crypto:

|Type|How|Use|
|---|---|---|
|Asymmetric|public/private **key pair**|strangers agree on a secret|
|Symmetric|one shared key|fast — encrypts everything after|

Remember "public key signs/verifies vs. private key" — it comes back for JWT.

**HTTP** is the request/response language on top of all that:

```http
POST /login HTTP/1.1
Host: example.com
Cookie: theme=dark

{"username": "alice", "password": "secret"}
```

```http
HTTP/1.1 200 OK
Set-Cookie: JSESSIONID=7F3A...; HttpOnly

{"message": "welcome"}
```

Both have a start line, headers, a blank line, then an optional body. Methods: `GET` (read), `POST`/`PUT`/`PATCH`/`DELETE` (write), `OPTIONS` (CORS preflight).

The one fact that matters most: **HTTP is stateless** — the server remembers nothing between requests. So every request must carry its own proof of identity. HTTP gives two carriers for that proof:

|Carrier|Sent by|Can be tricked (CSRF)?|
|---|---|---|
|Cookie (`Set-Cookie`)|the browser, automatically|yes|
|`Authorization` header|your code, manually|no|

That one distinction is the root of the session-vs-token and CSRF story.

## Part 2 — Tokens

**Authentication** = who are you. **Authorization** = what can you do. A **credential** (password, fingerprint) is long-term; a **token** is short-term proof you get _after_ presenting a credential — so your password is exposed rarely, and a stolen token can expire or be revoked.

Every login flow has the same shape: send credentials once → server issues a token → every later request carries the token → server checks it. The only variable is what the token looks like and how it's checked:

**Opaque tokens** — a random string with no meaning; the server looks it up in a table (`token → {user, roles, expiry}`). A session ID is exactly this.

-  instant revocation (delete the row), reveals nothing if intercepted
-  needs server-side storage (often shared via Redis), every check is a lookup

**JWT (self-contained tokens)** — the data lives inside the token, protected by a signature, so the server verifies instead of looking anything up:

```
eyJhbGciOiJSUzI1NiJ9 . eyJzdWIiOiJhbGljZSJ9 . dBjftJeZ4CVP...
      HEADER                 PAYLOAD            SIGNATURE
```

Header and payload are just Base64URL JSON — readable by anyone, **not secret**:

```json
{ "sub": "alice", "roles": ["USER"], "iss": "...", "iat": 1761200000, "exp": 1761200900 }
```

|Claim|Meaning|
|---|---|
|`sub`|subject (who)|
|`iss` / `aud`|issuer / intended audience|
|`iat` / `exp`|issued-at / expiration|

Signature = `Sign(header + "." + payload, key)`. Verification is: recompute the signature, compare, check `exp`/`iss`/`aud` — no database involved. **Never put secrets in a JWT payload** — it's signed, not encrypted.

|Style|Key used|Typical use|
|---|---|---|
|HS256 (symmetric)|one shared secret signs _and_ verifies|one app doing both jobs|
|RS256/ES256 (asymmetric)|private key signs, public key verifies|many services — only the auth server can forge tokens|

||Opaque / session ID|JWT|
|---|---|---|
|Revocation|instant|hard — wait for `exp`|
|Server state|required|none|
|Best for|one backend, browser app|APIs, microservices, mobile|

**Storage on the client:**

|Storage|XSS can steal?|CSRF risk?|
|---|---|---|
|`HttpOnly` cookie|no|yes — needs CSRF defense|
|`localStorage`|yes|no|

**Access + refresh tokens**: a short-lived access token (5–15 min) calls the API; a long-lived refresh token (days/weeks) is sent _only_ to the auth server to get a new access token when the old one expires. Rotating the refresh token each use lets the server detect theft (a reused old one is a red flag).

**OAuth2 / OIDC** — how "Sign in with Google" works without your app ever seeing the Google password. Four roles: you (resource owner), your app (client), Google's login (authorization server), Google's API (resource server). The authorization-code flow: you log in at Google → Google redirects back with a one-time code → your app's _server_ swaps that code (+ its own secret) for tokens directly with Google, out of the browser's reach. (**PKCE** adds extra protection for apps that can't hold a secret, like SPAs/mobile.) OIDC adds an **ID token** (a JWT proving who logged in) on top of OAuth2's access token — keep the two separate: access tokens call APIs, ID tokens prove identity to _your_ app.

---

When you move into Spring Security proper: a session is an opaque token, `oauth2ResourceServer().jwt()` is signature verification, and `oauth2Login()` is the authorization-code flow — same ideas, Spring's names on them.



[[Spring Security]]