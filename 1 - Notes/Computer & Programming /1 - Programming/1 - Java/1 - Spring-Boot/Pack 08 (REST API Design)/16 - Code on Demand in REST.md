


**Code on Demand** is REST's sixth constraint, and the only optional one. It says a server may send **executable code** to the client, and the client runs it. Normally a client knows in advance how to do its job and the server only sends data. Here the client is a generic runtime, and the server decides at the moment of the request what that runtime will do.

Your browser is the standard example. You request a page, the server replies with HTML plus a `<script>`, and the browser downloads and runs it. The browser never had that logic pre-installed; the server shipped it. Gmail, Google Maps, and your bank's web portal all work this way.

---

## The problem it solves

A client with all its logic baked in has a painful update cycle: to add a feature you publish a new client, users must download it, and old clients can't use new server features. With Code on Demand the client is generic, so the server ships new logic on the next load and everyone gets it instantly. This is why web apps iterate faster than native apps.

## Data vs. code (the line that matters)

|What the server sends|Example|Code on Demand?|
|---|---|---|
|Data|JSON from a REST API|No|
|Declarative instructions|HTML, CSS, config, feature flags|Not strictly|
|Executable code|JavaScript, WebAssembly|**Yes**|

Returning JSON the client _interprets_ is not Code on Demand. Returning JavaScript the client _executes_ is. Rules and feature flags sent by the server sit in between: they change client behavior, but safely, because the client only reads them.

## Why it's optional

Fielding made it optional because it works against two things REST values:

1. **Visibility.** Proxies, CDNs, and firewalls can inspect and cache JSON, but they can't tell what a blob of JavaScript will do. You trade visibility for flexibility.
2. **Security.** Running code from a server means trusting that server. Java applets, Flash, Silverlight, and ActiveX all died because arbitrary code from the internet was too dangerous. The web survived by converging on two sandboxed formats, JavaScript and WebAssembly.

It also sits in tension with other constraints: it blurs the client-server boundary, lets the client hold state, and is harder to cache than plain data. That's why a pure REST API (JSON in, JSON out) doesn't use it, and a web app that ships JavaScript is technically a **hybrid**: REST plus Code on Demand.

## The security model that makes it survivable

Code on Demand is only acceptable with a sandbox around it. The web provides:

- **Same-Origin Policy and CORS**: limit which sites a script can read from.
- **CSP (Content Security Policy)**: tells the browser which scripts may run and from where. This is your main defense, since without it an XSS attack can inject its own code.
- **SRI (Subresource Integrity)**: the browser checks a script's hash before running it.
- **Wasm and iframe sandboxes**: restrict what code can touch.

## In Spring Boot

Spring Boot is almost always on the **sending** side. It serves the page and its JS bundle (or `.wasm` files), and you set the CSP header to control what the browser may execute:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.headers(h -> h
        .contentSecurityPolicy(csp -> csp
            .policyDirectives("default-src 'self'; script-src 'self' https://trusted.cdn.com"))
        .httpStrictTransportSecurity(hsts -> hsts
            .includeSubDomains(true).maxAgeInSeconds(31536000)));
    return http.build();
}
```

For the lighter, declarative form, an endpoint can return client config or feature flags:

```java
@GetMapping("/api/config")
public ClientConfig config(@AuthenticationPrincipal User user) {
    return ClientConfig.builder()
        .featureEnabled("newCheckout", user.isBeta())
        .build();
}
```

## When to use it

Use it when the client is a trusted runtime like a browser, you want to change client behavior without shipping a new client, and you have a real sandbox. Avoid it for pure data APIs, for clients you don't control (CLI tools and IoT devices often can't run JavaScript), or when intermediaries need to inspect your responses.

## Pitfalls

- **Shipping code without a CSP.** One XSS hole becomes full account takeover.
- **Enforcing security on the client.** Client code can be modified, so authorization must always be checked on the server.
- **Embedding secrets in client code.** JavaScript is readable by anyone, so never put API keys in it.
- **Poor cache strategy for bundles.** Use content-hashed filenames and long `Cache-Control` on immutable assets.

## Recap

Code on Demand lets a server ship executable code that a client runs, which makes clients simple and updates instant. It costs you visibility and demands a strong sandbox, so REST keeps it optional. In Spring Boot you mostly serve the code and protect it with CSP.

That completes the six constraints: client-server, statelessness, cacheability, uniform interface, layered system, and code on demand (optional).




[[Spring Framework]]
[[Rest-API]]