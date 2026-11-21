
CSRF — Cross-Site Request Forgery — is an attack where a malicious site tricks your browser into sending a request to your app _using credentials your browser already has_, without you intending it. The attacker never sees your session or your cookie; they don't need to. They just need your browser to fire off a request, and because the browser automatically attaches cookies to any request going to the matching domain — regardless of which tab or site triggered that request — the forged request arrives looking perfectly legitimate to your server.

Spring Security enables CSRF protection by default for exactly this reason, and whether disabling it is "a good thing" depends entirely on _why_ your app is vulnerable to this in the first place — which comes down to how you authenticate.

![[bf22ecf6-d4d1-4a53-afa4-63d2150e8cc5.png]]
## Why CSRF exists at all — the actual mechanism

Say you're logged into `bank.com`, and it authenticates you with a session cookie (JSESSIONID, from your last lesson). You then visit `evil.com` in another tab. That page has:

```html
<form action="https://bank.com/transfer" method="POST">
  <input type="hidden" name="toAccount" value="attacker123">
  <input type="hidden" name="amount" value="5000">
</form>
<script>document.forms[0].submit();</script>
```

Your browser submits this form to `bank.com`. It doesn't care that the _page_ came from `evil.com` — cookies are scoped to the _target domain_, not the origin of the page making the request. So your browser dutifully attaches your `JSESSIONID` cookie for `bank.com`, the request looks exactly like a legitimate POST from your own logged-in session, and the server processes it. You never clicked anything on `bank.com`; `evil.com` acted _as you_, using your ambient credentials.

The key phrase is **"ambient credentials"**: any auth mechanism where the browser _automatically_ attaches proof of identity to every request — without your app's JavaScript having to explicitly add it — is vulnerable to this. Cookies are the classic example, because that automatic attachment is literally what cookies are for.

## Why Spring protects against it by default

Spring Security's default CSRF defense is the **synchronizer token pattern**. The server generates a random token, separate from the session cookie, and expects the client to send it back in a request parameter or custom header on every state-changing request (POST/PUT/DELETE/PATCH):

```java
// Spring Security auto-configures this when CSRF is enabled (the default)
http.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
);
```

The trick is: `evil.com` can make your browser send the cookie automatically, but it **cannot read** your CSRF token and attach it to the forged request, because:

- The token isn't stored where cookies are — the server expects it in a request _header_ or _body field_ that only your own app's JavaScript knows to set.
- Same-origin policy blocks `evil.com`'s JS from reading your app's page content or any response from `bank.com` to extract the token.

So the forged request arrives with the session cookie, but without the matching CSRF token, and Spring rejects it before it reaches your controller.

## So why do you see CSRF disabled so often?

Because most of what you've been building with me — JWT-based APIs — **aren't vulnerable to this in the first place**, and here's precisely why:

```java
http.csrf(csrf -> csrf.disable())
```

This is safe specifically when your auth token is a **JWT sent in an `Authorization: Bearer` header**, not a cookie. Go back to the attack: for it to work, the browser has to attach your credential _automatically_. A header is never attached automatically — your frontend's JavaScript has to explicitly read the JWT (from memory, or local storage) and set the header on each request:

```javascript
fetch('https://yourapp.com/api/transfer', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${jwt}` },
  body: JSON.stringify({ amount: 5000 })
});
```

`evil.com` can make your browser _send a request_, but it cannot make your browser attach a JWT it doesn't have and can't read. There's no ambient credential for it to ride on. This is the real rule, not "JWT = disable CSRF" as a cargo-culted default:

> **CSRF protection is irrelevant precisely when zero ambient credentials exist on the request** — no cookies, no HTTP Basic auth being auto-sent, nothing the browser attaches on its own. If _every_ piece of auth on a request has to be explicitly constructed by your JS, there's nothing for a forged cross-site request to exploit.

This is also exactly why your filter chain design from the Security Filter Chain lesson matters here: a **stateless**, `SessionCreationPolicy.STATELESS` chain backed purely by JWT headers is the configuration under which disabling CSRF is actually justified — not just convenient.

```java
http
    .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
    .csrf(csrf -> csrf.disable()); // justified ONLY because no session cookie exists to forge against
```

## Where disabling CSRF is a genuine mistake

The danger is when people copy that `.csrf(csrf -> csrf.disable())` line into an app that is **not** stateless — one that still:

- Uses `HttpSession` / JSESSIONID for login (form login, OAuth2 login with session-based `SecurityContext`),
- Or stores the JWT in a cookie instead of sending it via header (some apps do this for XSS-mitigation reasons, trading one risk for another),
- Or has _any_ endpoint relying on auto-attached credentials.

In that case, disabling CSRF removes your only defense against the forged-request attack, and it's a real, exploitable hole — not a theoretical one. This is the single most common production misconfiguration around this topic: disabling CSRF because "that's what the tutorial did" without checking whether the tutorial's auth model (often cookie-session) matches the app's actual auth model.

## How it's actually handled in production, properly

A production-grade decision tree looks like this:

**1. Pure stateless API, JWT-in-header, no browser session at all (your typical SPA + REST backend setup):**

```java
http
    .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
    .csrf(csrf -> csrf.disable())
    .authorizeHttpRequests(auth -> auth
        .requestMatchers("/api/public/**").permitAll()
        .anyRequest().authenticated()
    );
```

Disabling is correct here. No ambient credential, no attack surface for CSRF to exploit.

**2. Session-based or cookie-based auth of any kind (traditional server-rendered app, or a JWT deliberately stored in an `HttpOnly` cookie):**  
Keep CSRF enabled, and use a token delivery strategy that actually works for your frontend. The common production pattern is the **double-submit cookie**, via Spring's `CookieCsrfTokenRepository`:

```java
http.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
);
```

The server sets the CSRF token itself in a cookie _readable by JS_ (`HttpOnly=false`, unlike the session cookie). Your frontend JS reads that cookie value and echoes it back as a header (commonly `X-XSRF-TOKEN`) on every mutating request. Because `evil.com`'s JS can't read cookies belonging to `yourapp.com` (same-origin policy again), it can't construct a matching header — even though it _can_ trigger the cookie to be sent automatically. The mismatch is what Spring checks and rejects on.

**3. Mixed APIs (some endpoints session-based, some stateless, e.g. an admin console using form login alongside a public JWT API):**  
This is where `securityMatcher` from your filter chain design lesson earns its keep — you run two separate `SecurityFilterChain` beans, apply CSRF protection only to the chain matching the session-based paths, and disable it only on the chain matching the stateless JWT paths:

```java
@Bean
@Order(1)
SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    http.securityMatcher("/api/**")
        .csrf(csrf -> csrf.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
    return http.build();
}

@Bean
@Order(2)
SecurityFilterChain adminChain(HttpSecurity http) throws Exception {
    http.securityMatcher("/admin/**");
    // CSRF stays enabled (default) — this chain uses session-based form login
    return http.build();
}
```

The real production discipline isn't "CSRF on" or "CSRF off" as a blanket rule — it's auditing, endpoint by endpoint, whether an ambient credential exists on that path. Wherever one does, CSRF protection stays on; wherever it genuinely doesn't, disabling it isn't a shortcut, it's the correct configuration for that threat model.



[[Spring Security]]