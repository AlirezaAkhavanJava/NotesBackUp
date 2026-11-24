


Spring Security's ideas aren't really about Spring at all. They're answers to two problems every system connected to the internet has to deal with:
- **how do two computers find each other and send data back and forth** (that's networking),  
- **how does a server know who you are across many separate requests, without you typing your password every single time** (that's tokens). 

Sessions, cookies, CSRF, JWT — all of it is just different answers to those two problems. Let's take them one at a time, slowly.

## Part 1 — Networking

### The layers: who's responsible for what

Sending data across the internet isn't one big job — it's broken into layers, stacked on top of each other, where each layer only worries about one thing and just trusts the layer underneath it to have done its job:

| Layer       | Its one job                                    | Example         |
| ----------- | ---------------------------------------------- | --------------- |
| Application | The **actual message** you care about          | HTTP, DNS       |
| Security    | Seal the envelope so nobody can peek or tamper | TLS             |
| Transport   | Make sure data arrives, in order, without loss | TCP, UDP        |
| Internet    | Figure out _where_ to send it                  | IP              |
| Link        | Actually move bits through a wire or signal    | Wi-Fi, Ethernet |

Think of it like mailing a letter: you write the letter (Application), seal it in an envelope (Security), hand it to a reliable courier who guarantees delivery (Transport), the courier uses the street address to route it (Internet), and a truck physically drives it there (Link). Each layer does its one job and doesn't care how the layer below pulls it off.

![[a0c067d5-f3e1-4a90-a5cf-2a54647dfd1c.png]]

## Finding a machine, and a program on it

Every machine on the internet has an **IP address** — a unique number that identifies it, like `127.0.0.1` (which always means "this machine, right here"). But an IP address alone just finds the _computer_. A computer can run many programs at once — a database, a web server, your Spring Boot app — so there's a second number called a **port** that picks which program on that machine should receive the data. Port `443` usually means HTTPS, `5432` usually means Postgres, `8080` is Spring Boot's own default. An IP address plus a port together is called a **socket**, and that's the actual full "address" any connection is made to.

## DNS: turning names into addresses

Nobody types IP addresses into a browser — you type `example.com`. Something has to translate that name into the actual IP address, and that something is **DNS**. The lookup happens in stages: your browser checks its own cache first, then your OS, then your ISP's resolver, and if none of those know the answer, it works its way up through root servers and `.com` servers until it finds the one server that actually knows. You can watch this happen yourself with `dig example.com +short` in a terminal.

Here's why this matters for security: if someone can trick DNS into giving a _wrong_ IP address, they can silently redirect you to a fake server pretending to be the real one. This is exactly the problem TLS (next section) is designed to catch — even if DNS lies to you and sends you to the wrong machine, that attacker still can't produce a valid certificate for the real domain name, so your browser will refuse the connection.

### TCP: making delivery reliable

Raw IP packets aren't guaranteed to arrive, and they aren't guaranteed to arrive _in order_. **TCP** sits on top of IP and fixes both problems — it guarantees your data arrives complete and in the right sequence, starting every connection with a small "handshake" where both sides confirm they're ready: `SYN` → `SYN-ACK` → `ACK`. **UDP** is the alternative that skips all that reliability machinery for speed — used where losing a little data is fine but delay isn't, like video calls, games, DNS lookups, and the newer HTTP/3 (built on something called QUIC).

### TLS: making the connection private and genuine

**TLS** sits on top of TCP and solves three things at once: nobody eavesdropping can read your data, nobody can quietly modify it in transit, and you can be sure you're actually talking to the real server and not an impostor. It pulls this off by combining two different kinds of cryptography:

|Type|How it works|What it's used for|
|---|---|---|
|Asymmetric|A matched **pair** of keys — one public, one private|Letting two strangers safely agree on a secret, even over an insecure line|
|Symmetric|One single shared key both sides already have|Fast encryption of everything that follows, once the secret is agreed on|

The reason TLS uses both: asymmetric crypto is secure but slow, symmetric crypto is fast but needs both sides to already share a secret. So TLS uses the slow-but-safe asymmetric method just once, to safely hand over a shared secret, then switches to the fast symmetric method for the rest of the conversation. One detail worth remembering for later: **the public key signs or verifies, the private key is the one kept secret** — this exact idea comes back word-for-word when we get to JWT.

### HTTP: the actual conversation

**HTTP** is the language web requests and responses are written in, sitting on top of everything above:

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

Both messages follow the same shape: a start line, then some headers, then a blank line, then an optional body with the actual content. The common methods are `GET` (read something), `POST`/`PUT`/`PATCH`/`DELETE` (change something), and `OPTIONS` (a special preflight check browsers send before certain cross-origin requests).

### The one fact that explains everything after this

Here's the single most important thing to internalize: **HTTP has no memory.** The server treats every single request as if it's never seen you before — it doesn't remember that you logged in two seconds ago. This is called being **stateless**. Because of this, _every single request_ has to carry its own proof of who you are, since nothing is remembered between them. HTTP gives you two different ways to attach that proof:

|Carrier|Who sends it|Can an attacker trick the browser into sending it without you wanting to?|
|---|---|---|
|Cookie (`Set-Cookie`)|The browser sends it automatically, on every request to that site|Yes — this is the CSRF problem|
|`Authorization` header|Your own code has to attach it manually|No|

This one small difference — "sent automatically" vs. "sent on purpose" — is the root cause of basically the entire session-vs-token debate and the entire reason CSRF protection exists. Keep this distinction in your head; it explains a lot of what's coming.

## Part 2 — Tokens

### Two different questions

**Authentication** answers "who are you?" **Authorization** answers "what are you allowed to do?" These get confused a lot, but they're genuinely separate questions, asked and answered separately.

A **credential** — your password, your fingerprint — is something long-lived and precious. A **token** is short-lived proof you're handed _after_ you've already proven who you are once with a credential. The whole point of separating these: your password only needs to be sent once, rarely, while the token that gets passed around on every request afterward is something cheap to replace if it leaks — it can simply expire, or be revoked.

Every login flow, no matter how it's implemented, follows the exact same shape: you send your credentials once → the server hands you back a token → every request after that carries the token instead of your password → the server checks the token each time. The only thing that actually differs between systems is _what the token looks like_ and _how the server checks it_. That's the entire design space.

### Option 1: Opaque tokens (the "lookup" approach)

An **opaque token** is just a random string that means nothing by itself — like a coat check ticket. The server keeps a table somewhere (`token → {user, roles, expiry}`) and looks your token up in it every time you make a request. A traditional session ID works exactly this way.

- **Good**: you can revoke it instantly, just by deleting that row from the table. And if someone intercepts the token itself, it reveals nothing about you, since it's meaningless on its own.
- **Costly**: the server has to keep that table somewhere (often a shared store like Redis, so multiple server instances can all check it), and every single request means a lookup.

### Option 2: JWT — tokens that carry their own data

A **JWT** flips the approach completely: instead of the server looking anything up, the actual data lives _inside_ the token itself, protected by a cryptographic signature. The server just checks the signature's math instead of checking a database:

```
eyJhbGciOiJSUzI1NiJ9 . eyJzdWIiOiJhbGljZSJ9 . dBjftJeZ4CVP...
      HEADER                 PAYLOAD            SIGNATURE
```

Here's the part that surprises people: the header and payload are just plain Base64-encoded JSON — anyone who intercepts a JWT can decode and read them instantly. They are **not secret or encrypted**, only signed:

```json
{ "sub": "alice", "roles": ["USER"], "iss": "...", "iat": 1761200000, "exp": 1761200900 }
```

|Claim|What it means|
|---|---|
|`sub`|subject — who this token is about|
|`iss` / `aud`|who issued it / who it's meant for|
|`iat` / `exp`|when it was issued / when it expires|

The signature is computed as `Sign(header + "." + payload, key)`. To verify a JWT, the server recomputes that same signature from scratch and compares it to the one attached, then checks that `exp`, `iss`, and `aud` all look right — no database lookup required anywhere in that process. Because the payload is readable by anyone, **never put secrets in a JWT** — a password or an API key sitting in there is exposed the moment anyone decodes it.

|Signing style|Which key does what|Typical use|
|---|---|---|
|HS256 (symmetric)|One shared secret both signs and verifies|One single app handling both jobs itself|
|RS256/ES256 (asymmetric)|Private key signs, public key verifies|Many separate services — only the central auth server can actually create valid tokens|

### Comparing the two side by side

||Opaque token / session ID|JWT|
|---|---|---|
|Revoking it|Instant|Hard — you just have to wait for it to expire|
|Server-side storage needed|Yes|None|
|Best fit|A single backend serving a browser app|APIs, microservices, mobile apps|

### Where the browser keeps the token

|Storage location|Can malicious JavaScript (XSS) steal it?|Vulnerable to CSRF?|
|---|---|---|
|`HttpOnly` cookie|No — JavaScript can't even see it|Yes — needs separate CSRF defense|
|`localStorage`|Yes — any script on the page can read it|No|

Notice there's no free lunch here — each storage choice trades one vulnerability for the other.

### Access tokens and refresh tokens

In practice, systems usually issue _two_ tokens together: a short-lived **access token** (valid for maybe 5–15 minutes) that's used to actually call the API, and a long-lived **refresh token** (valid for days or weeks) that's sent _only_ to the authentication server, purely to get a fresh access token once the old one expires. A good extra safeguard: rotate the refresh token every time it's used — if an old, already-used refresh token ever shows up again, that's a strong signal someone stole a copy of it.

### OAuth2 and OIDC: "Sign in with Google"

This is the mechanism behind buttons like "Sign in with Google," where your app never actually sees your Google password. Four parties are involved: you (the resource owner), your app (the client), Google's login system (the authorization server), and Google's actual API (the resource server).

The flow, called the **authorization-code flow**, works like this: you log in directly at Google (your app never touches your password) → Google redirects you back to your app with a one-time code → your app's _server_ (not your browser) exchanges that code, along with its own secret, directly with Google for the actual tokens — a step that happens entirely out of reach of anything running in the browser. (**PKCE** is an extra layer added for apps that can't safely hold a secret at all, like single-page apps or mobile apps.)

**OIDC** builds one more thing on top of plain OAuth2: an **ID token**, which is itself a JWT whose whole purpose is proving _who just logged in_. Keep these conceptually separate: an access token is for calling APIs; an ID token is for proving identity to _your own app_.

---

### How this maps onto Spring Security later

Once you get into Spring Security itself, you'll recognize all of this under new names: a session is just an opaque token under the hood; `oauth2ResourceServer().jwt()` is literally the JWT signature-verification process described above; and `oauth2Login()` is exactly the authorization-code flow, just configured for you. Nothing new is being invented there — it's the same ideas wearing Spring's naming.


[[Spring Security]]