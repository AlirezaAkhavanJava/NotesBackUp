

Cross-Site Request Forgery is an attack where a malicious site tricks a logged-in user's browser into sending a request to your app that the user never intended to send. The browser does this automatically because it attaches cookies (like a session cookie) to every request to your domain, no matter which page triggered that request. The attacker never sees your user's cookie and never needs to — they just need the browser to fire the request _with_ it.

Classic example: your user is logged into `bank.com` with a session cookie. They visit `evil.com`, which contains:

```html
<form action="https://bank.com/transfer" method="POST">
  <input type="hidden" name="to" value="attacker-account">
  <input type="hidden" name="amount" value="5000">
</form>
<script>document.forms[0].submit()</script>
```

The browser submits this to `bank.com`, attaches the session cookie automatically, and `bank.com`'s server sees a perfectly valid, authenticated POST request. Same-origin policy stops the attacker from _reading_ the response, but it does nothing to stop them from _sending_ the request in the first place. That's the gap CSRF protection closes.

## The defense: synchronizer token pattern

The fix is to require a second piece of proof on every state-changing request — a token that isn't a cookie, so the browser won't attach it automatically. The server generates an unpredictable token, the legitimate page embeds it in the form or sends it as a header on AJAX calls, and the server checks it matches before processing the request. `evil.com` has no way to read that token (same-origin policy blocks it from reading your page's content), so it can't forge a valid request even though the cookie still gets attached.

Note what's _not_ protected automatically: GET, HEAD, TRACE, and OPTIONS are treated as "safe" methods with no side effects, so Spring Security doesn't require a token for them. The check only kicks in on POST, PUT, PATCH, DELETE.

## How Spring Security models this

A few pieces work together:

- **`CsrfToken`** — the interface representing the token itself: a value, a header name it can arrive in, and a parameter name it can arrive in.
- **`CsrfTokenRepository`** — where the token is stored and compared against. The two you'll actually use are `HttpSessionCsrfTokenRepository` (token lives in the session — the historic default for server-rendered apps) and `CookieCsrfTokenRepository` (token lives in a cookie the browser holds, readable by JavaScript so an SPA can grab it and echo it back in a header).
- **`CsrfTokenRequestHandler`** — resolves the token for the current request and makes it available to the view/response. As of Spring Security 5.8+, this replaced the older `CsrfTokenRequestResolver` approach. There are two implementations: `XorCsrfTokenRequestAttributeHandler` (the default — masks the token with a per-request XOR pad before exposing it, specifically to defeat BREACH, a compression-based side-channel attack that could otherwise let an attacker guess the token byte-by-byte from response size) and the plain `CsrfTokenRequestAttributeHandler` (no masking, simpler, fine if you've disabled response compression).
- **`CsrfFilter`** — the filter in the chain that actually does the check: loads the token, compares it against what the request supplied, rejects with 403 on mismatch.

One detail worth knowing: the token is loaded _deferred_. Calling `request.getAttribute("_csrf")` (or rendering it in a form) is what actually triggers generation/lookup — a request that never touches the token doesn't force a session to be created or a cookie to be written just because CSRF protection is enabled. This matters for scalability; it's why you'll see `requestHandler.setCsrfRequestAttributeName(null)` in cookie-based setups — it tells the handler to defer resolution rather than eagerly resolving on every request.

## Scenario 1: server-rendered app (session-based)

This is the default behavior — you don't need to configure anything beyond enabling it, since Spring Security protects CSRF by default when sessions are in play.

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf(Customizer.withDefaults()); // HttpSessionCsrfTokenRepository + Xor handler
    return http.build();
}
```

In a Thymeleaf form, `th:action` automatically adds the hidden CSRF input for you. If you're building the form by hand:

```html
<input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}" />
```

`_csrf` here is the request attribute the handler exposed — `parameterName` and `token` are the two fields you need off the `CsrfToken` object.

## Scenario 2: SPA talking to the backend via cookies

If your frontend is a separate JS app making `fetch`/`axios` calls and you're using cookie-based session auth (not JWT), the token needs to live somewhere JS can read it and echo back.

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    CsrfTokenRequestAttributeHandler handler = new XorCsrfTokenRequestAttributeHandler();
    handler.setCsrfRequestAttributeName(null);

    http.csrf(csrf -> csrf
        .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
        .csrfTokenRequestHandler(handler)
    );
    return http.build();
}
```

`withHttpOnlyFalse()` is the key line — a normal cookie would be `HttpOnly` so JS can't touch it, but here JS _needs_ to read it, so that protection is deliberately traded off (the token still isn't the auth credential, just the proof-of-origin, so this is fine). The cookie is named `XSRF-TOKEN` by convention; the client reads it and sends it back as the `X-XSRF-TOKEN` header on every mutating request — that header name is what `CookieCsrfTokenRepository` checks against by default.

## Scenario 3: stateless JWT API (your current setup)

This is the one that actually matters for your stack. CSRF exploits the browser's automatic, no-questions-asked attachment of _cookies_. If your auth is a JWT sent in an `Authorization: Bearer <token>` header — which is how your `JwtAuthFilter` works — there's no cookie for the browser to auto-attach, and browsers don't auto-attach arbitrary headers across origins either. `evil.com` has no mechanism to make the victim's browser send your JWT, because the JWT was never stored somewhere the browser sends automatically. That's why CSRF protection is conventionally disabled for pure stateless, header-based APIs:

```java
http.csrf(AbstractHttpConfigurer::disable);
```

The important thing isn't the one-liner, it's the reasoning: you disable it _because_ the attack it defends against doesn't apply to your auth model, not because it's an annoying checkbox. The moment any part of your app starts relying on a cookie for auth (even a `HttpOnly` refresh-token cookie), that endpoint is back in CSRF's blast radius and needs the token.

## Testing it

MockMvc requests to CSRF-protected endpoints need the token injected, or they get a 403 before your controller is ever reached:

```java
mockMvc.perform(post("/api/orders").with(csrf()))
```

That `with(csrf())` post-processor comes from `spring-security-test` and stands in for the real token exchange.



[[Spring Security]]