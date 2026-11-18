# Universal Basics: Networking and Tokens (Before Spring Security)

 Spring Security is just one implementation of ideas that exist everywhere: in Node, Python, Go, .NET, and mobile apps. If you learn the universal ideas first, Spring Security stops being a pile of annotations and becomes "oh, this is just that idea, with Spring's names on it."

## The problem these basics solve

Two computers that have never met need to:

1. **Find each other** and send data (networking).
2. **Prove who they are** across many separate messages, without repeating a password every time (tokens).

This lesson is the foundation under everything we covered. Sessions, cookies, CSRF, and JWT are all answers to these two problems.

## The map

```
Part 1: Networking                      Part 2: Tokens
 ┌──────────────────────┐               ┌──────────────────────┐
 │ Layers (the stack)   │               │ Identity vs proof    │
 │ IP, ports, DNS       │               │ Session vs token     │
 │ TCP, TLS             │               │ Opaque tokens        │
 │ HTTP (the language)  │               │ JWT (signed tokens)  │
 │ Cookies & headers    │               │ Access + refresh     │
 └──────────────────────┘               │ OAuth2 / OIDC        │
                                        └──────────────────────┘
```

---

# Part 1: Networking basics

## 1.1 The layers: why networking is a stack

Sending a message across the world is too big a job for one system. So it's split into **layers**, where each layer solves one problem and trusts the layer below it.

Think of mailing a letter:

|Letter analogy|Network layer|Real example|
|---|---|---|
|The words inside the letter|**Application**|HTTP, DNS, SMTP|
|A sealed, tamper-proof envelope|**Security**|TLS|
|Numbered pages, confirmed delivery|**Transport**|TCP, UDP|
|The street address|**Internet**|IP|
|The truck and the road|**Link**|Wi-Fi, Ethernet|

When your browser sends a request, it goes **down** the layers on your machine, travels as electrical or radio signals, and goes **back up** the layers on the server. Each layer wraps the one above it in its own header, like envelopes inside envelopes.

The practical benefit: when something breaks, you can ask "which layer?" A DNS error, a refused connection, a certificate error, and a 404 are four different layers failing.

## 1.2 IP addresses: "where is the machine?"

An **IP address** identifies a machine on a network, like a street address.

|Type|Example|Notes|
|---|---|---|
|IPv4|`93.184.216.34`|Four numbers from 0 to 255, running out|
|IPv6|`2606:2800:220:1:248:1893:25c8:1946`|Much bigger, the future|
|Private|`192.168.1.10`, `10.0.0.5`|Only works inside your home or company network|
|Loopback|`127.0.0.1` / `localhost`|"This machine itself"|

That last one is what you've been using when running Spring Boot: `localhost:8080` means "my own machine, port 8080."

Your home devices share one public IP. Your router uses **NAT** (Network Address Translation) to keep track of which private device asked for what. It's like an office receptionist forwarding calls to the right desk.

## 1.3 Ports: "which program on that machine?"

A machine runs many programs. The IP finds the building, and the **port** finds the room.

|Port|Used for|
|---|---|
|80|HTTP|
|443|HTTPS|
|22|SSH|
|5432|PostgreSQL|
|6379|Redis|
|8080|Common for dev servers (your Spring Boot default)|

So `https://example.com` secretly means `https://example.com:443`. When you set `server.port=9090` in Spring Boot, you're choosing which room your app waits in.

A full **address of a connection** is `IP + port`, for example `93.184.216.34:443`. That pair is called a **socket**.

## 1.4 DNS: "what is the IP of this name?"

People remember names, and machines need numbers. **DNS** is the internet's phone book.

```
Browser: "What is the IP of example.com?"
   │
   ├─ 1. Browser cache        → no
   ├─ 2. Operating system     → no
   ├─ 3. Your ISP's resolver  → asks the hierarchy:
   │       root servers → .com servers → example.com's own name server
   └─ 4. Answer: 93.184.216.34  (cached for a while, based on its TTL)
```

You can try it on Debian:

```bash
dig example.com
```

Look at the `ANSWER SECTION`. The number there is the IP, and the number before `IN A` is the TTL in seconds.

Security link: if an attacker can lie to DNS, they can send you to a fake server. This is one reason HTTPS certificates exist. Even if you land on the wrong IP, the fake can't present a valid certificate for the real name.

## 1.5 TCP: reliable delivery

The internet underneath (IP) is unreliable: packets can arrive out of order, duplicated, or not at all. **TCP** fixes that by creating a dependable stream.

It starts with the **three-way handshake**:

```
Client  ──── SYN ────────▶  Server    "Can we talk?"
Client  ◀─── SYN-ACK ────   Server    "Yes, can you hear me?"
Client  ──── ACK ────────▶  Server    "Yes. Starting."
```

Then data flows in numbered pieces. The receiver confirms what it got, and the sender resends anything missing. You never see this. You just get a clean, ordered stream of bytes.

There is also **UDP**, the opposite trade-off: no handshake, no guarantees, but very fast. Video calls, games, and DNS often use it. (HTTP/3 uses a UDP-based protocol called QUIC.)

## 1.6 TLS: the sealed envelope

TCP delivers bytes, but anyone on the path can read them. **TLS** sits on top and adds the three guarantees from our earlier lesson: nobody can read it, nobody can change it, and you're talking to the right server.

The short version of how it works, which is worth understanding because **tokens depend on it**:

|Idea|Plain explanation|
|---|---|
|**Asymmetric crypto**|A key _pair_: a public key anyone may know and a private key only the owner has. Slow, but it lets strangers agree on a secret.|
|**Symmetric crypto**|One shared secret key used by both sides. Very fast, so it encrypts the real data.|
|**TLS combines both**|Use the slow method once to agree on a secret, then the fast method for everything else.|

Remember "public key and private key." You'll meet them again in JWT signatures.

## 1.7 HTTP: the language of the web

Everything above just moves bytes. **HTTP** is the agreed language those bytes speak. It is a simple **request, then response** protocol.

A request:

```http
POST /login HTTP/1.1
Host: example.com
Content-Type: application/json
Cookie: theme=dark

{"username": "alice", "password": "secret"}
```

A response:

```http
HTTP/1.1 200 OK
Content-Type: application/json
Set-Cookie: JSESSIONID=7F3A...; HttpOnly

{"message": "welcome"}
```

Both have the same four parts:

|Part|Request example|Response example|
|---|---|---|
|**Start line**|`POST /login HTTP/1.1` (method, path, version)|`HTTP/1.1 200 OK` (version, status code)|
|**Headers**|`Host`, `Content-Type`, `Cookie`|`Content-Type`, `Set-Cookie`|
|**Blank line**|separates headers from body|same|
|**Body**|The data you send (optional)|The data you receive (optional)|

### The methods

|Method|Meaning|Changes data?|
|---|---|---|
|`GET`|Read something|No|
|`POST`|Create something or submit an action|Yes|
|`PUT` / `PATCH`|Replace or partly update|Yes|
|`DELETE`|Remove|Yes|
|`OPTIONS`|"What am I allowed to do here?" (CORS preflight)|No|

### The most important property: HTTP is stateless

Each request stands completely alone. The server does not remember the previous one. This single fact is why sessions and tokens exist. It's worth reading twice.

> Because HTTP forgets you every time, **every request must carry its own proof of who you are.**

That sentence is the bridge to Part 2.

## 1.8 Headers and cookies: the carrying mechanism

Since every request must carry its proof, we need a place to put it. HTTP gives us two standard places:

|Carrier|How it works|Who adds it|
|---|---|---|
|**Cookie**|The server says `Set-Cookie`, and the browser **automatically** returns it on every request to that site|The browser, by itself|
|**`Authorization` header**|Your code puts `Authorization: Bearer <token>` on the request|Your code, **manually**|

This difference is the heart of the difference between sessions and tokens, and of why CSRF affects one and mostly not the other. **Cookies are automatic, so the browser can be tricked into sending them. Manually added headers can't be tricked that way.**

---

# Part 2: Token basics

## 2.1 Two different questions

People mix these up, so separate them first:

|Term|Question it answers|Example|
|---|---|---|
|**Authentication**|Who are you?|Checking a password|
|**Authorization**|What are you allowed to do?|"Admins only"|

And a third idea that connects them:

|Term|Meaning|
|---|---|
|**Credential**|The _long-term_ secret you prove yourself with (password, fingerprint, passkey)|
|**Token**|A _short-term_ proof you receive **after** you've shown the credential|

The problem tokens solve: **you don't want to send your password with every request.** Sending it once, getting a token back, and using the token afterward means your password is exposed far less often, and a stolen token is less harmful than a stolen password, because tokens can expire and be limited.

## 2.2 The universal login flow

Nearly every system you'll ever build follows this same shape:

```
1. Client → Server:   "Here are my credentials"   (password, once)
2. Server:            checks them, creates a TOKEN
3. Server → Client:   "Here is your token"
4. Client → Server:   every later request carries the token
5. Server:            checks the token, then serves or rejects
```

The only differences between the approaches are **what the token looks like** and **how the server checks it** in step 5. That gives two big families.

## 2.3 Family 1: Opaque tokens (reference tokens)

An **opaque** token is a random string with **no meaning inside it**. The server keeps a table remembering what it points to.

```
Token:  "9f2c71e0b4a8..."   ← looks like nothing
Server's table:
   "9f2c71e0b4a8..."  →  { user: alice, roles: [USER], expires: 10:30 }
```

**Verification** = a lookup. You can see this is exactly what a **session ID** is. A session ID _is_ an opaque token. The coat-check ticket from before is the perfect picture.

|Strength|Weakness|
|---|---|
|Easy to revoke instantly: delete the row|Server must store and look up every token|
|Token reveals nothing if intercepted|Many servers need a shared store (Redis)|
|Simple to understand|Every check costs a lookup|

## 2.4 Family 2: Self-contained tokens (JWT)

A **self-contained** token carries the data **inside itself**, protected by a **signature** so nobody can alter it. The server doesn't need to store anything. It just checks the signature.

The common format is **JWT** (JSON Web Token, pronounced "jot"). It has three parts separated by dots:

```
eyJhbGciOiJSUzI1NiJ9 . eyJzdWIiOiJhbGljZSIsInJvbGVzIjpbIlVTRVIiXX0 . dBjftJeZ4CVP...
      HEADER                         PAYLOAD                          SIGNATURE
```

Each of the first two parts is just **Base64URL-encoded JSON**. You can decode them. Here they are decoded:

**Header** (how it was signed):

```json
{ "alg": "RS256", "typ": "JWT" }
```

**Payload** (the claims, meaning statements about the user):

```json
{
  "sub": "alice",
  "roles": ["USER"],
  "iss": "https://auth.example.com",
  "iat": 1761200000,
  "exp": 1761200900
}
```

|Claim|Meaning|
|---|---|
|`sub`|**Subject**: who the token is about|
|`iss`|**Issuer**: who created it|
|`aud`|**Audience**: who it is meant for (an API)|
|`iat`|**Issued at**: creation time|
|`exp`|**Expiration**: when it stops being valid (Unix seconds)|
|custom claims|`roles`, `email`, and so on|

**Signature** is the clever part. The issuer takes `header + "." + payload` and signs it:

```
signature = Sign( header.payload , secret_or_private_key )
```

### A crucial point: a JWT is signed, NOT encrypted

Anyone holding the token can **read** the payload, because Base64 is not secrecy. The signature only guarantees **nobody changed it**. So:

> Never put passwords, secrets, or private data in a normal JWT payload.

### How the server verifies a JWT

```
1. Split the token into header, payload, signature
2. Recompute the signature from header + payload with the key
3. Compare with the signature on the token   → mismatch = REJECT (tampered)
4. Check exp   → expired = REJECT
5. Check iss and aud   → wrong issuer or audience = REJECT
6. All good → trust the claims inside
```

Notice: **no database, no lookup.** Any server with the key can verify it. That is why JWTs scale so naturally across many servers and many services.

### Two signing styles

This is where the public and private keys from the TLS section come back:

|Style|How|Typical use|
|---|---|---|
|**HS256** (symmetric)|One shared secret signs and verifies|One app that both issues and checks tokens|
|**RS256 / ES256** (asymmetric)|**Private key signs**, **public key verifies**|Many services: only the auth server holds the private key, and everyone else can verify with the public key but can't forge anything|

The second style is the heart of modern systems. An API can verify tokens without ever being able to create them.

### The trade-offs of JWT

|Strength|Weakness|
|---|---|
|No server storage, scales easily|**Hard to revoke**: valid until `exp`|
|Any service can verify it independently|Bigger than a session ID (sent on every request)|
|Carries user info and roles|Info inside can go stale until the token expires|
|Works across different domains and apps|Easy to implement insecurely if you skip the checks|

A classic JWT bug: accepting a token whose header says `"alg": "none"` (no signature). Good libraries refuse this, so **always use a maintained library and fix the algorithm you expect**.

## 2.5 Opaque vs JWT, side by side

||Opaque token / session ID|JWT|
|---|---|---|
|Looks like|Random string|Three Base64 parts with dots|
|Data lives|On the server|Inside the token|
|Verified by|Looking it up|Checking the signature|
|Revocation|Instant|Hard, you wait for expiry|
|Server state|Required|None|
|Best for|Browser apps with one backend|APIs, microservices, mobile apps|

Neither is better in general. Many real systems use both.

## 2.6 Where does the client keep the token?

This question matters for security, and it ties directly back to XSS and CSRF.

|Storage|XSS can steal it?|CSRF can abuse it?|Notes|
|---|---|---|---|
|**`HttpOnly` cookie**|No (JavaScript can't read it)|**Yes**, since the browser sends it automatically, so you need CSRF defenses|Best for browser apps|
|**`localStorage`**|**Yes**, any injected script reads it|No (not sent automatically)|Easy, but risky if XSS exists|
|**Memory (JS variable)**|Harder, but still reachable by XSS|No|Lost on page refresh|

There's no perfect option, only trade-offs. For classic browser apps, an `HttpOnly` cookie plus CSRF protection is a strong default. For mobile apps, the platform's secure storage (Keychain on iOS, Keystore on Android) is the right place.

## 2.7 Access tokens and refresh tokens

Short-lived tokens are safer, but nobody wants to log in every 10 minutes. The solution is **two tokens with different jobs**:

||Access token|Refresh token|
|---|---|---|
|Purpose|Calls the API|Gets a new access token|
|Lifetime|Short (5 to 15 minutes)|Long (days or weeks)|
|Sent to|The API on every request|**Only** the auth server|
|If stolen|Damage limited by short life|Serious, so protect and rotate it|

The flow:

```
1. Login → server gives ACCESS (15 min) + REFRESH (7 days)
2. Client uses ACCESS on every API call
3. ACCESS expires → API replies 401
4. Client sends REFRESH to the auth server → gets a new ACCESS
5. REFRESH expires → user must log in again
```

This is the same idea as the remember-me mechanism from our session lesson: a short-lived thing that does the work, and a long-lived thing that only renews it. **Refresh token rotation** (issuing a new refresh token each time and invalidating the old one) lets the server detect theft, since a reused old token signals a problem.

## 2.8 OAuth2 and OIDC: tokens between companies

So far, one app issues and checks its own tokens. But what about "Sign in with Google"? Your app is not allowed to see Google passwords, yet it needs to know who the user is.

**OAuth2** is a standard for **letting an app act for you without learning your password**, using tokens.

The four roles:

|Role|Example|
|---|---|
|**Resource owner**|You, the user|
|**Client**|The app that wants access (your app)|
|**Authorization server**|Issues tokens (Google's login system)|
|**Resource server**|The API that accepts tokens (Google's API)|

The common flow, the **Authorization Code flow**, in plain words:

```
1. Your app sends you to Google's login page      (you type your password at Google, not at the app)
2. Google asks: "Allow this app to see your email?"  → you click Allow
3. Google redirects you back to the app with a short one-time CODE
4. The app's server swaps CODE (+ its own secret) for TOKENS, directly with Google
5. The app uses the tokens
```

The one-time code travels through the browser, which is risky territory. The real tokens are swapped **server to server**, where nobody can see them. For apps that can't keep a secret (browser-only apps, mobile apps), **PKCE** adds a per-login proof so a stolen code is useless.

**OIDC (OpenID Connect)** is a thin layer on top that adds an **ID token** (a JWT that says _who the user is_). OAuth2 alone is about _access_, and OIDC adds _identity_.

|Token|Purpose|Who reads it|
|---|---|---|
|**Access token**|Permission to call an API|The API|
|**ID token** (OIDC)|Proof of who logged in|Your app|
|**Refresh token**|Get new access tokens|The auth server only|

A common mistake is using an ID token to call an API. Keep the roles separate.

---

# Part 3: Seeing it with tools

All of this can be observed on your Debian machine.

**1. DNS:**

```bash
dig example.com +short
```

**2. TCP and TLS:**

```bash
curl -v https://example.com 2>&1 | head -40
```

`-v` is verbose. You'll see DNS resolving, the TCP connection, the TLS handshake, and then the HTTP request and response lines, in that order. It's the layers from Part 1 in action.

**3. Headers only:**

```bash
curl -I https://example.com
```

**4. Send a token manually:**

```bash
curl -H "Authorization: Bearer eyJhbGciOi..." http://localhost:8080/api/me
```

`-H` adds a header. This is the "manual carrier" from section 1.8.

**5. Decode a JWT yourself:**

```bash
echo 'eyJzdWIiOiJhbGljZSIsInJvbGVzIjpbIlVTRVIiXX0' | base64 -d
```

You'll see the JSON. (If `base64` complains about padding, add `=` characters at the end.) This proves the payload is readable, not secret. The website jwt.io also decodes tokens, but never paste real production tokens into online tools.

**6. In the browser:** open the Network tab, log in to any site, and look at the login response. Is it a `Set-Cookie` (session style) or a JSON body with `access_token` (token style)? Then see how later requests carry it: a `Cookie` header or an `Authorization` header.

---

# The whole picture in one table

|Concept|One-line meaning|Where you'll meet it in Spring Security|
|---|---|---|
|IP + port|Which machine, which program|`server.address`, `server.port`|
|DNS|Name to IP|Not directly, but certificates depend on names|
|TCP|Reliable stream|Handled by Tomcat|
|TLS|Encryption and identity|`server.ssl.*`, HTTPS, HSTS|
|HTTP statelessness|Each request stands alone|The reason sessions or tokens exist|
|Cookie|Automatic carrier|Session login, CSRF concerns|
|`Authorization` header|Manual carrier|JWT resource server|
|Opaque token|Random key to server data|`HttpSession`|
|JWT|Signed self-contained token|`oauth2ResourceServer().jwt()`|
|Access + refresh|Short-lived plus renewer|OAuth2 client and authorization server|
|OAuth2 / OIDC|Delegated login between companies|`oauth2Login()`|

# A small decision guide

|Your situation|Typical choice|
|---|---|
|Classic website, one backend|Server session in an `HttpOnly` cookie, plus CSRF protection|
|REST API for a mobile app or a single-page app|Access token (JWT) in the `Authorization` header, plus a refresh token|
|Many microservices|JWT signed with asymmetric keys, verified by each service|
|"Sign in with Google"|OAuth2 / OIDC authorization code flow with PKCE|

# Two related concepts, briefly

**Hashing vs encryption vs signing:** three tools that people confuse. _Hashing_ is a one-way scramble (passwords). _Encryption_ is a two-way scramble that hides data from people without the key (TLS). _Signing_ doesn't hide anything, but it proves who made the data and that it wasn't changed (JWT). Each solves a different problem, and tokens use signing.

**Stateless vs stateful:** a **stateful** server remembers you between requests (sessions), and a **stateless** server remembers nothing, and each request carries everything needed (JWT). Stateless servers are easier to copy and scale, and stateful ones are easier to control and revoke.

---

When you start the Spring Security deep dive, you'll recognize every piece. Sessions are opaque tokens, JWT support is signature verification, and `oauth2Login` is the authorization code flow, all running on top of HTTP and TLS. If you'd like to go next, a good order is **HTTP in more depth** (methods, status codes, caching, CORS preflight), then **JWT hands-on** (create and verify one yourself with a small Java program), and then the Spring Security filter chain.




[[Spring Security]]