

The **Code on Demand** constraint is the sixth and final constraint of REST — and the only one that's **optional**. Fielding explicitly marked it as such, which is why most REST APIs today don't use it.

But it's conceptually fascinating, and understanding it explains a lot about why the web works the way it does.

## The core idea

> A server can send **executable code** to the client, which the client then runs.

Instead of the client knowing how to do everything in advance, the server ships logic to it at runtime. The client becomes a **general-purpose execution engine**, and the server decides what that engine should do.

This is the opposite of the other REST constraints, which are about **decoupling** and **transparency**. Code on Demand *couples* the client to the server's logic — temporarily, at runtime.

## The web browser: the canonical example

Your browser is the ultimate Code on Demand client.

When you visit a website:

1. Browser requests `index.html`
2. Server responds with HTML + `<script src="app.js">`
3. Browser downloads `app.js`
4. Browser executes it

The browser didn't know what `app.js` would do before it arrived. It didn't have the business logic pre-installed. The server **shipped the code**, and the browser ran it.

Every modern web app is Code on Demand:
- Gmail
- Google Maps
- Twitter/X
- Your bank's web portal

The browser is a generic HTML/CSS/JS runtime. The website decides what runs.

## The spectrum of code on demand

Code on Demand isn't binary — it exists on a spectrum:

| Level | Example | What's shipped |
|-------|---------|----------------|
| **No code** | REST API returning JSON | Data only |
| **Declarative** | HTML, CSS, SVG | Markup/instructions, not executable |
| **Scripted** | JavaScript in a browser | Full executable code |
| **Binary** | Java applets, Flash, WebAssembly | Compiled code |
| **Native** | App store updates | Native binaries |

The constraint is really about the **executable** end of this spectrum. JSON is data; JavaScript is code. The line matters.

## Historic examples

- **Java Applets** (1995–2017) — server sends a `.class` file, the browser's JVM runs it. Dead, killed by security issues and plugin deprecation.
- **Flash / ActionScript** — server sends a `.swf`, the Flash plugin runs it. Dead, killed by Steve Jobs's open letter and HTML5.
- **Silverlight** — Microsoft's Flash competitor. Dead.
- **ActiveX** — Microsoft's plugin system. Dead, security nightmare.

Every one of these died for the same reason: **arbitrary code from the internet is dangerous**. The browser vendors converged on JavaScript + WebAssembly as the only sanctioned execution formats.

## Modern examples

- **JavaScript in browsers** — the dominant case
- **WebAssembly (Wasm)** — compiled code that runs in a sandboxed VM in the browser. Used by Figma, AutoCAD Web, Google Earth.
- **Serverless edge functions** — Cloudflare Workers, Deno Deploy ship code to edge nodes
- **Mobile app updates** — some frameworks (React Native, Flutter, CodePush) push JS/bundle updates without app store review
- **Smart contracts** — code deployed to a blockchain, executed by every node
- **Jupyter notebooks** — data + executable code in one document

## Why it's optional

Fielding made Code on Demand optional because it **breaks two things REST values**:

### 1. Visibility

Intermediaries (proxies, CDNs, firewalls) can inspect JSON. They can cache it, validate it, log it, scan it.

They **cannot** inspect arbitrary executable code. They don't know what it will do. A firewall can't tell if a JavaScript payload will exfiltrate data or mine crypto.

Code on Demand trades **visibility for flexibility**.

### 2. Security

Executing code from a server means trusting that server. Every Code on Demand system has to answer:

- What can the code access? (sandboxing)
- What can it do to the user's machine? (permissions)
- Can it talk to other servers? (CORS, CSP)
- Can it persist? (storage, cookies)
- Can it escalate? (privilege boundaries)

JavaScript's answer: a strict sandbox with same-origin policy, CORS, CSP, and a permission model. WebAssembly's answer: an even tighter sandbox with no direct system access.

Without these, Code on Demand is a security disaster. That's why applets and Flash died.

## The benefit: client simplicity

The payoff is that the **client doesn't need to know everything in advance**.

Compare:

**Without Code on Demand:**
- Client ships with all logic baked in
- To add a feature, you update the client (app store review, user download)
- Old clients can't use new server features

**With Code on Demand:**
- Client is a generic runtime
- Server ships new logic on the next page load
- Users get new features instantly, no update required

This is why web apps iterate faster than native apps. The browser is a Code on Demand client; native apps (mostly) aren't.

## Code on Demand vs. the other constraints

Here's where it gets interesting. Code on Demand **conflicts** with the spirit of the other constraints:

| Constraint | Tension with Code on Demand |
|-----------|----------------------------|
| **Client-Server** | Code blurs the boundary — server logic runs on the client |
| **Statelessness** | Executable code can hold state on the client |
| **Cacheability** | Code is harder to cache safely than data |
| **Uniform Interface** | Code bypasses the uniform interface — it's a side channel |
| **Layered System** | Intermediaries can't inspect or transform code |
| **Code on Demand** | — |

This is exactly why Fielding made it optional. A pure REST API — JSON in, JSON out — is *more* RESTful in spirit than one that ships JavaScript. Code on Demand is a pragmatic exception, not a core principle.

## Is a REST API with JavaScript still REST?

Subtle question. Fielding's answer:

- A REST API that returns JSON is RESTful.
- A web app that returns HTML + JavaScript + JSON is **not purely RESTful** — it uses Code on Demand, which is an optional constraint.
- It's still "REST" in the loose sense people use today, but it's technically a **hybrid**: REST + Code on Demand.

In practice, almost every real system is a hybrid. Pure REST is rare.

## Spring Boot and Code on Demand

Spring Boot is primarily a **server-side** framework, so it's usually on the **sending** side of Code on Demand. Here's how it shows up:

### 1. Serving JavaScript to browsers

```java
@Controller
public class WebController {

    @GetMapping("/")
    public String index() {
        return "index";   // renders src/main/resources/templates/index.html
    }
}
```

The HTML references a JS bundle. The browser downloads and executes it. That's Code on Demand.

### 2. Serving WebAssembly

```java
@GetMapping("/wasm/{file}")
public ResponseEntity<Resource> getWasm(@PathVariable String file) {
    Resource resource = new ClassPathResource("static/wasm/" + file);
    return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType("application/wasm"))
            .body(resource);
}
```

Same pattern — ship compiled code, browser runs it.

### 3. Serving dynamic client logic

A more interesting case: an API that returns **configuration or rules** the client interprets.

```java
@GetMapping("/api/rules")
public RuleSet getRules() {
    return RuleSet.builder()
            .add("discount", "if cart.total > 100 then 10% off")
            .add("shipping", "if country == 'US' then free")
            .build();
}
```

This is a lightweight form of Code on Demand: the server ships **rules**, the client interprets them. It's not arbitrary code, but it's logic the client didn't have pre-installed.

### 4. Feature flags and remote config

```java
@GetMapping("/api/config")
public ClientConfig getConfig(@AuthenticationPrincipal User user) {
    return ClientConfig.builder()
            .featureEnabled("newCheckout", user.isBeta())
            .theme(user.getPreferredTheme())
            .build();
}
```

The client changes behavior based on server-sent config. This is **declarative Code on Demand** — safer than executable code, still powerful.

### 5. Serverless / edge functions

Spring Boot isn't typically used here, but the pattern exists: ship a function to a runtime (AWS Lambda, Cloudflare Workers), the runtime executes it. Same idea.

## The security model

If you're going to use Code on Demand, you need a security model. The web's model:

- **Same-Origin Policy** — JS from `a.com` can't read data from `b.com`
- **CORS** — servers opt in to cross-origin requests
- **Content Security Policy (CSP)** — restricts what scripts can run and where they load from
- **Sandboxing** — iframes, Web Workers, Wasm VMs
- **Subresource Integrity (SRI)** — verify a script's hash before running
- **Permissions API** — camera, mic, location require explicit user consent

In Spring Boot, you'd configure:

```java
@Configuration
public class WebSecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .headers(headers -> headers
                .contentSecurityPolicy(csp -> csp
                    .policyDirectives("default-src 'self'; script-src 'self' https://trusted.cdn.com")
                )
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31536000)
                )
            );
        return http.build();
    }
}
```

CSP is your primary defense: it tells the browser which scripts it's allowed to run. Without it, an XSS attack can inject arbitrary Code on Demand.

## When to use Code on Demand

**Use it when:**
- You need client-side interactivity (web apps)
- You want to update client logic without shipping a new client
- The client is a trusted runtime (browser, Wasm VM)
- You have a strong sandbox and security model
- The benefit (flexibility) outweighs the cost (visibility, security)

**Avoid it when:**
- You're building a pure data API (return JSON)
- The client is a third-party you don't control
- Intermediaries need to inspect or transform your responses
- You can't guarantee a sandbox
- You care about cacheability and transparency

## Common pitfalls

1. **Serving executable code without CSP.** An XSS hole becomes a full account takeover.

2. **Assuming the client will run your code.** Not all clients can — CLI tools, IoT devices, and many API consumers can't execute JavaScript.

3. **Confusing data with code.** Returning JSON that the client *interprets* is not Code on Demand in the strict sense. Returning JavaScript that the client *executes* is.

4. **Breaking cacheability silently.** Code is harder to cache than data. Version your bundles, use content hashes, set long `Cache-Control` on immutable assets.

5. **Trusting client-executed code for security.** Never enforce authorization on the client. The client can be modified. Always enforce on the server.

6. **Shipping secrets in client code.** JavaScript is readable. Anyone can inspect it. Never embed API keys or secrets.

7. **Ignoring the optional nature.** If you call your API "REST" but it ships JavaScript, you're using an optional constraint. That's fine — just know it's not pure REST.

## TL;DR

- **Code on Demand** = server sends executable code to the client, client runs it.
- It's the **only optional** REST constraint. Fielding marked it optional because it conflicts with visibility and security.
- **Canonical example:** JavaScript in a browser.
- **Historic examples:** Java applets, Flash, Silverlight, ActiveX — all dead.
- **Modern examples:** JavaScript, WebAssembly, edge functions, smart contracts.
- **Benefit:** client doesn't need to know logic in advance; server can update behavior on the fly.
- **Cost:** intermediaries can't inspect code; security requires a strong sandbox.
- **Spring Boot relevance:** mostly on the sending side — serving JS, Wasm, config, feature flags. Use CSP, SRI, and a proper security model.
- **Pure REST APIs don't use it.** They return data (JSON), not code. A system that uses Code on Demand is technically a hybrid.

You've now covered all six REST constraints. The full set:

1. **Client-Server** — separation of concerns
2. **Statelessness** — every request is self-contained
3. **Cacheability** — responses declare if they can be reused
4. **Uniform Interface** — resources, methods, representations, hypermedia
5. **Layered System** — intermediaries are transparent
6. **Code on Demand** — *optional*: ship executable code to clients




[[Spring Framework]]