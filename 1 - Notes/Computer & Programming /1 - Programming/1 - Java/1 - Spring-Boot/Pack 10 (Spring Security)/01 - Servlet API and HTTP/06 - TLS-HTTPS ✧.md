

Every time you see the padlock in your browser, TLS is protecting you. This lesson shows what it does, how it sets up a secure connection in a few milliseconds, and how to turn it on in your own Spring Boot app.

You already know the building blocks (hashing, symmetric and asymmetric encryption, signatures). TLS is where they all work together.

## The problem: plain HTTP is a postcard

When you send a request over plain HTTP, it travels through your Wi-Fi router, your ISP, and many other machines before it reaches the server. Each one can read it, and each one can change it.

That means a person on the same café Wi-Fi could:

- **Read** your session cookie, your password, and your messages.
- **Change** the page on its way to you, for example injecting a script.
- **Pretend** to be the server, and you'd never know.

Everything we've learned so far (cookies, tokens, hashed passwords) falls apart if the connection itself is open to snooping. Sending a perfectly hashed password over plain HTTP still exposes the password in transit.

## The terms

- **TLS (Transport Layer Security)** is the protocol that protects a connection. It sits between HTTP and the network.
- **HTTPS** is simply **HTTP running inside a TLS connection**. Same requests, same headers, same status codes. They're just wrapped in a protective tunnel.
- **SSL** is TLS's old, broken ancestor. People still say "SSL certificate," but they almost always mean TLS. Today you should use **TLS 1.3**, or at least TLS 1.2. TLS 1.0 and 1.1 are deprecated.

## What TLS gives you: three promises

|Promise|What it means|Which tool provides it|
|---|---|---|
|**Confidentiality**|Nobody in the middle can read the data|Symmetric encryption (AES)|
|**Integrity**|Nobody can change the data without being caught|Authenticated encryption (AES-GCM)|
|**Authentication**|You're really talking to the real server|Certificates and signatures|

The third one is easy to forget, and it matters a lot. Encryption without authentication is nearly worthless. If you encrypt a message perfectly but send it to an attacker pretending to be your bank, you've only protected it on the way to the wrong person.

## Certificates: how you know the server is real

When you visit `shop.example.com`, the server must prove it's the real one. It does this with a **certificate**.

A certificate is a small signed document that says:

> "The public key `ABC...` belongs to `shop.example.com`. Valid from this date to that date. Signed, a Certificate Authority."

A **certificate authority (CA)** is an organization your device already trusts, such as Let's Encrypt, DigiCert, or Sectigo. Your operating system and browser ship with a built-in list of trusted CAs, called the **trust store**.

Here's why you can trust it. The CA verified that whoever asked for the certificate really controls that domain, then **signed** the certificate with the CA's private key. Your browser checks that signature using the CA's public key, which it already has.

Think of a certificate as a passport. A government you trust (the CA) checked who you are and stamped it. A border officer (your browser) doesn't need to know you personally. They trust the stamp.

### The chain of trust

CAs rarely sign server certificates directly. There's usually a chain:

```
Root CA  (in your browser's trust store)
   └── signs → Intermediate CA
                  └── signs → shop.example.com  (the server's certificate)
```

Your browser follows the chain upward until it reaches a root it already trusts. If any link is missing, expired, or has a bad signature, the connection fails with a warning.

### What your browser checks

- The **signature chain** leads to a trusted root.
- The certificate is **not expired**.
- The **hostname matches**. The certificate lists the domains it covers in a field called **SAN (Subject Alternative Name)**. If you visit `shop.example.com` and the certificate says `other.com`, you get a warning.
- The certificate hasn't been **revoked**.

## The handshake: building the secure tunnel

Before any HTTP data flows, the client and server do a short exchange called the **TLS handshake**. Its goal is to agree on a **shared secret key** that only the two of them know, even though they're talking over an open network.

Here's the TLS 1.3 version in plain steps:

1. **ClientHello.** Your browser says: "Hi. Here are the TLS versions and encryption methods I support. Here's my half of a key exchange."
2. **ServerHello.** The server replies: "Let's use this method. Here's my half of the key exchange."
3. **Both sides calculate the same secret.** Using the two halves, each side independently computes an identical shared key. An eavesdropper who saw both halves cannot compute it. This trick is called **Diffie-Hellman key exchange**.
4. **Server proves its identity.** It sends its **certificate**, plus a **signature** made with its private key over the handshake so far. This proves it owns the key in the certificate and isn't replaying an old one.
5. **Both sides say "Finished."** Each sends a check value, confirming nobody tampered with the handshake.
6. **Encrypted data flows.** From here on, every HTTP message is encrypted with the shared key, using fast symmetric encryption (AES-GCM or ChaCha20).

```
Browser                                   Server
   │ ── ClientHello + key share ────────────▶ │
   │ ◀── ServerHello + key share ──────────── │
   │ ◀── Certificate + signature ──────────── │   (server proves who it is)
   │ ◀── Finished ───────────────────────────  │
   │ ── Finished ───────────────────────────▶ │
   │ ══════ encrypted HTTP traffic ═════════  │
```

TLS 1.3 completes this in **one round trip**, which is why HTTPS today is barely slower than HTTP.

### Why this design is clever

You can see all three tools from the last lesson here:

- **Signatures** and certificates prove who the server is.
- **Asymmetric math** (the key exchange) creates a shared secret without ever sending it.
- **Symmetric encryption** protects the real data, because it's fast.

That's hybrid encryption in action.

### Forward secrecy

The key exchange uses **fresh, temporary keys for every connection**. So even if an attacker records your encrypted traffic today and steals the server's private key next year, they still can't decrypt the old recordings. Each session's key is gone for good. This property is called **forward secrecy**, and TLS 1.3 requires it.

## HTTPS and the cookie flag

Remember the `Secure` cookie flag? Now it makes complete sense. `Secure` tells the browser _only send this cookie over HTTPS_. Without TLS underneath, a session cookie crossing the network could be copied by anyone watching, no matter how well you hash passwords or sign tokens.

Two more related protections:

- **HSTS** (`Strict-Transport-Security` header): tells the browser "always use HTTPS for this site, for the next N seconds." It blocks attackers who try to downgrade a visitor to plain HTTP.
- **Mixed content:** if an HTTPS page loads a script or image over plain HTTP, that weak link can be attacked. Browsers block or warn about it. Load everything over HTTPS.

## What HTTPS does not do

It's easy to over-trust the padlock, so keep these limits in mind.

- **It doesn't make a site trustworthy.** A phishing site can have a perfectly valid certificate for its own scam domain. The padlock means "this connection is private and goes to the domain shown," not "this site is honest."
- **It doesn't protect the data once it arrives.** TLS protects data _in transit_. Once the server decrypts it, your app is responsible. You still need hashed passwords, authorization checks, and input validation.
- **It doesn't hide everything.** An observer can still see _which server_ you connected to (its IP address, and usually the domain name) and roughly how much data moved. They can't see the page, the headers, or the contents.
- **It doesn't replace authentication.** TLS proves _the server's_ identity to you. You still need logins to prove _the user's_ identity to the server.

## Turning on HTTPS in Spring Boot

There are two common setups.

### Option 1: Let Spring Boot handle TLS directly

You need a **keystore**, a file holding your private key and certificate. For local development, you can generate a self-signed one with the `keytool` that comes with the JDK:

```bash
keytool -genkeypair -alias myapp -keyalg RSA -keysize 2048 \
  -storetype PKCS12 -keystore keystore.p12 -validity 365 \
  -dname "CN=localhost" -ext "san=dns:localhost"
```

Then configure it in `application.properties`:

```properties
server.port=8443
server.ssl.enabled=true
server.ssl.key-store=classpath:keystore.p12
server.ssl.key-store-type=PKCS12
server.ssl.key-store-password=${KEYSTORE_PASSWORD}
server.ssl.key-alias=myapp
```

Notice the password comes from an environment variable. Never commit it to Git.

Your browser will warn you about a self-signed certificate, because no trusted CA signed it. That's fine for development, and it's a good way to see the "chain of trust" idea in action. Never use self-signed certificates in production.

In Spring Boot 3.1 and later, you can also use **SSL bundles**, which are a tidier way to group keystore settings and even reload certificates without restarting. They're worth a look once the basics are clear.

### Option 2: Terminate TLS at a reverse proxy (most common in production)

Most real deployments put **nginx**, **Caddy**, a load balancer, or a cloud service in front of the app. The proxy handles HTTPS and certificates, and passes plain HTTP to your app on a private network. On Debian, you can get free, auto-renewing certificates from **Let's Encrypt** using `certbot`, or use Caddy, which obtains them automatically.

There's one catch. Your app now sees plain HTTP requests, so it might think the connection is insecure, build `http://` redirect links, or refuse to mark cookies `Secure`. The proxy sends headers like `X-Forwarded-Proto: https` to tell your app the truth, and you tell Spring Boot to trust them:

```properties
server.forward-headers-strategy=framework
```

Only enable this when your app really sits behind a proxy you control. Otherwise a client could fake those headers.

### Spring Security settings

Spring Security can force HTTPS and send the HSTS header:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .requiresChannel(channel -> channel.anyRequest().requiresSecure())
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

- `requiresSecure()` redirects any plain-HTTP request to HTTPS.
- Spring Security adds the **HSTS** header by default, but only on requests that arrive over HTTPS.

## Common errors and what they mean

|Error|Usual cause|
|---|---|
|`PKIX path building failed` (Java)|Java doesn't trust the server's certificate chain: a self-signed cert, or a missing intermediate.|
|`certificate has expired`|The certificate's validity ended. Automate renewal so this never surprises you.|
|Hostname mismatch / `No subject alternative names matching`|You connected to a name that isn't in the certificate's SAN list.|
|`unable to find valid certification path`|Same family as PKIX: the trust store doesn't include the issuer.|
|Redirect loop behind a proxy|The app doesn't know the original request was HTTPS. Check `X-Forwarded-Proto` and `forward-headers-strategy`.|

When you hit the PKIX error in development, the tempting fix is to disable certificate checking. Don't. That removes the _authentication_ promise entirely and leaves you open to impersonation. Instead, add the certificate to your trust store, or use a properly signed one.

## A bonus: mutual TLS (mTLS)

In normal HTTPS, only the **server** shows a certificate. In **mutual TLS**, the **client** shows one too, so both sides prove who they are. It's common between internal services ("service A must prove it's really service A"). Spring Boot supports it with `server.ssl.client-auth=need` and a truststore for client certificates. Keep it in mind for later, when you work on service-to-service security.

## Mistakes to avoid

- **Running a login page over plain HTTP.** Credentials and cookies are exposed. Use HTTPS everywhere, not just on the login page.
- **Disabling certificate validation** to "make the error go away."
- **Letting certificates expire.** Automate renewal.
- **Committing keystores or passwords to Git.**
- **Using self-signed certificates in production.**
- **Allowing old protocols.** Disable SSL, TLS 1.0, and TLS 1.1. Modern JDKs already do this by default.
- **Forgetting `Secure` on cookies, or HSTS on the site.**
- **Trusting `X-Forwarded-*` headers** when your app is directly exposed to the internet.

## Summary

- **HTTPS is HTTP inside TLS.** TLS gives you confidentiality, integrity, and authentication.
- **Certificates** prove a server's identity. A trusted **CA** signs them, and browsers verify the chain up to a root they already trust.
- The **handshake** uses asymmetric key exchange to agree on a secret, then **symmetric encryption** (AES) protects the actual traffic. **Forward secrecy** means old recordings stay unreadable.
- HTTPS protects data **in transit** only. It doesn't prove a site is honest, and it doesn't replace login or authorization.
- It pairs with the **`Secure` cookie flag** and **HSTS**.
- In Spring Boot, either set `server.ssl.*` with a keystore, or terminate TLS at a **reverse proxy** and set `server.forward-headers-strategy`.





[[Spring Security]]