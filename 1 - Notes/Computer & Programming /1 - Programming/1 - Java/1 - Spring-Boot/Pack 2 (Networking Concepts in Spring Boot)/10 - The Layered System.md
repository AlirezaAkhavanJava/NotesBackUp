

The **layered system** is one of REST's six constraints, and it says something simple: a client must not be able to tell whether it's connected directly to the server that owns the data (the _origin server_) or to an intermediary along the way. The client sends an HTTP request and gets an HTTP response. Whether a CDN, a load balancer, an API gateway, a reverse proxy, or five of them handled it in between is invisible.

This matters because it lets you grow a system by **inserting components rather than rewriting clients**. You can add a cache, a firewall, rate limiting, or ten more servers, and the mobile app that's already in people's pockets keeps working untouched. This tutorial covers the problem layering solves, what a well-behaved layer must do, the headers that keep layers honest, how Spring Boot fits in, and the ways layers go wrong.

---

## The problem: success makes a single server inadequate

Imagine your Spring Boot API starts life as one server, and the client talks to it directly:

```text
Client ──► Spring Boot app ──► Database
```

Then the real world arrives:

- Traffic grows, so one server isn't enough. You need several, and something must spread requests across them.
- Attackers show up. You want something filtering malicious traffic _before_ it reaches your code.
- Users in Asia complain about latency. You want responses served from nearby.
- You need authentication and rate limiting in one place instead of copy-pasted into every service.
- HTTPS certificates are a chore. You'd rather handle TLS once, at the edge.

You _could_ put every one of these into the app and teach every client about it. But then every change breaks clients, and your app becomes a giant knot of unrelated responsibilities. The layered constraint offers another route: **let each concern live in its own component, positioned between client and server, and keep the client's view of the world unchanged.**

```text
Client ─► CDN ─► WAF ─► Load balancer ─► Gateway ─► App instances ─► Database
```

The client still just says `GET https://api.example.com/users/42`. Everything else is your business.

## The analogy: a restaurant that grew

A tiny café has one person who seats you, cooks, serves, and takes payment. As it grows, it hires a host, a waiter, a runner, a sommelier, and a cashier. You, the customer, still just "go to the restaurant." Hire a new runner and you won't notice. Replace the sommelier with a wine dispenser and you still won't notice.

Each person is a layer with one job, and the customer's experience stays the same. That "stays the same" part is the entire constraint, and it's where the rules in the next section come from. If the new cashier started charging you for things you didn't order, you'd notice immediately, because the layer stopped being transparent.

## What counts as a layer

Anything that sits between the client and the origin and speaks HTTP can be a layer:

|Layer|Its job|
|---|---|
|Load balancer|Spread requests across servers|
|Reverse proxy (Nginx, HAProxy)|Route, terminate TLS, compress|
|API gateway (Spring Cloud Gateway, Kong)|Authentication, rate limiting, routing|
|CDN (Cloudflare, CloudFront)|Cache and serve content near the user|
|Caching proxy (Varnish)|Store responses so the origin isn't hit|
|WAF|Block malicious traffic|
|Service mesh sidecar (Istio, Linkerd)|mTLS, retries, observability between services|
|BFF (Backend for Frontend)|Combine several services' data for one kind of client|

Two side notes. First, Netflix Zuul, which sometimes appears in older lists like this, is a legacy gateway, and Spring Cloud Gateway is what you'd choose today in the Spring world. Second, layers aren't only separate machines. Servlet filters inside your own app form layers too (more on that below).

## Why this is such a big deal

**Scalability.** Add a load balancer or a CDN and no client changes. Layering is the reason horizontal scaling feels invisible to callers.

**Separation of concerns.** The gateway handles auth, the CDN handles caching, the load balancer handles distribution, and the origin handles business logic. No single component has to be good at everything.

**Security.** You can put a WAF or authentication in front of the origin without modifying it, terminate TLS at the edge, and rate-limit at the gateway. The origin can be tucked away on a private network.

**Replaceability.** Swap Nginx for HAProxy, or Varnish for CloudFront, or move from a monolith to microservices behind a gateway, and clients never know.

**Observability.** Every boundary between layers is a place to measure, log, replay, or inject faults for testing.

## The rules a layer must follow to stay invisible

A layer can't do whatever it likes. For the constraint to hold, a layer must:

1. **Speak the same protocol.** HTTP in, HTTP out.
2. **Preserve semantics.** A `GET` stays safe, a `PUT` stays idempotent, and so on. A proxy that turns a `GET` into something with side effects is broken.
3. **Respect caching headers.** If a response says `no-store`, the layer must not store it.
4. **Forward or regenerate the right headers.** Details in the next section.
5. **Not change the API's meaning.** A layer may add value (caching, auth, compression) but must not alter what the API _means_.

A layer that violates these is no longer transparent, and that's a bug rather than a design choice.

## Headers: how layers leave breadcrumbs

When a request passes through proxies, the origin sees a problem: the TCP connection comes from the _proxy_, so the apparent client IP, scheme, and host are the proxy's, not the real client's. A few headers solve this.

**`Via`** records which intermediaries handled the request, each appending itself:

```text
Via: 1.1 varnish, 1.1 nginx
```

**`X-Forwarded-*`** (the de facto convention) and the newer standard **`Forwarded`** describe the original request:

```text
X-Forwarded-For: 203.0.113.7, 198.51.100.4
X-Forwarded-Proto: https
X-Forwarded-Host: api.example.com
X-Forwarded-Port: 443
```

`X-Forwarded-For` is a chain: the leftmost is the original client, and each proxy appends the address it received the request from.

This isn't only about logging IPs. Without these headers, your app may think requests are plain `http` on an internal hostname, so redirects, generated links, and OAuth redirect URIs come out wrong (`http://internal-host:8080/...` instead of `https://api.example.com/...`).

In Spring Boot you tell the app to honor them:

```properties
server.forward-headers-strategy=framework
```

The two main values:

- `framework` uses Spring's `ForwardedHeaderFilter`, working regardless of the embedded server.
- `native` lets the server itself (such as Tomcat's remote IP handling) process them. This pairs with settings like `server.tomcat.remoteip.internal-proxies` to define which proxies you trust.

One correction to a common older snippet: `server.use-forward-headers=true` was the pre-Boot-2.2 property. It has since been replaced by `server.forward-headers-strategy`, so use that.

**Security warning:** these headers are just text, and anyone can send them. If the origin trusts `X-Forwarded-For` from arbitrary clients, an attacker can claim any IP they like and dodge IP-based rules. The fix is architectural: your outermost layer should _strip or overwrite_ incoming forwarded headers from the internet, and the origin should only accept them from known proxies.

## Layers inside a Spring Boot app

Spring Boot doesn't have a "layered system" feature, because layering is an architectural idea. But it gives you the building blocks at several levels.

**1. The gateway layer: Spring Cloud Gateway.**

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: users
          uri: http://user-service:8080
          predicates:
            - Path=/api/users/**
          filters:
            - StripPrefix=1
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 10
                redis-rate-limiter.burstCapacity: 20
```

The gateway routes, authenticates, and rate-limits. The user service never sees raw internet traffic.

**2. The auth layer: Spring Security.** It's a chain of servlet filters sitting in front of your controllers:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/public/**").permitAll()
            .anyRequest().authenticated())
        .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
    return http.build();
}
```

**3. Your own filters.** Any `OncePerRequestFilter` is a layer you control, and the `chain.doFilter(...)` call is literally "pass this to the next layer":

```java
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws IOException, ServletException {
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(request, response);
        } finally {
            log.info("{} {} -> {} ({} ms)", request.getMethod(),
                     request.getRequestURI(), response.getStatus(),
                     System.currentTimeMillis() - start);
        }
    }
}
```

**4. Service-to-service.** In microservices, `Client → Gateway → Order Service → Payment Service → Bank API` is layering too. The client has no idea the Order Service calls Payment, which calls a bank.

A nuance worth knowing: _inside_ your app you also have the controller → service → repository structure, often called "layered architecture." That's a different idea (code organization), even though the word is the same. REST's layered system is about **components between client and server**, not about how you arrange packages in your codebase. It's easy to mix the two up.

## One request, start to finish

A mobile app calls `GET https://api.example.com/users/42`:

```text
1. DNS resolves api.example.com to a CDN edge
2. CDN: cache miss, forwards to origin
3. Load balancer: picks server #3
4. Nginx: terminates TLS, sets X-Forwarded-* headers, forwards on
5. Spring Cloud Gateway: validates the JWT, checks rate limit, routes to user-service
6. Spring Security filter: re-validates the JWT (defense in depth)
7. Logging filter: starts a timer
8. Controller: loads user 42, returns JSON
9. The response travels back through every layer;
   the CDN caches it for 60s based on Cache-Control
10. The client receives 200 OK
```

One request, one response, and around eight components touched it without the client knowing. That invisibility is the whole point.

## What layers cost you

Nothing here is free:

- **Latency**: every hop adds milliseconds.
- **Complexity**: more to configure, deploy, and monitor.
- **Debugging pain**: "which layer stripped that header?" can eat an afternoon.
- **More failure points**: a broken CDN or gateway breaks everything behind it.
- **Money**: gateways, CDNs, and meshes aren't free.

REST says layering _should be possible_, not that you should stack layers greedily. A tiny internal API may need nothing beyond a load balancer. Add a layer when it earns its keep.

## Where things go wrong

1. **Trusting the apparent client IP.** Behind a proxy it's the proxy's address. Read forwarded headers, but only from trusted proxies.
2. **Trusting forwarded headers from the internet.** They're forgeable. Strip and re-add them at the edge.
3. **Caching user-specific data in a shared cache.** A CDN caching `/me` without `Cache-Control: private` can serve one user's data to another. This is a classic data leak.
4. **Forgetting `Vary`.** If a response differs by `Accept-Language` or `Accept-Encoding` and you don't say so with `Vary`, a cache may serve the wrong variant.
5. **Stateful layers.** If a gateway keeps session state the origin depends on, you've broken statelessness and lost free horizontal scaling. Keep every layer stateless (or push state to a shared store).
6. **Mismatched auth config.** If the gateway and the app both validate JWTs, they must agree on issuer, keys, and audience, or requests fail in confusing ways.
7. **Headers disappearing.** Some proxies drop unknown headers. Prefer standard ones, and check proxy configuration.
8. **Muddled timeouts.** Each layer has its own timeout, and when they're inconsistent you get odd failures, like a gateway giving up while the origin keeps working on a request nobody is waiting for. A good rule of thumb is that **inner timeouts should be shorter than outer ones**, so the layer closest to the work fails first and reports a meaningful error.

## Related ideas worth knowing

- **Statelessness.** The partner constraint. Statelessness means any layer can handle any request, since each one is self-contained, and layering means you can add as many layers as you like. Together they're why REST scales horizontally, and removing either weakens the other.
- **Cacheability.** Layers like CDNs can only cache safely because responses declare their own cache rules. Layering and caching reinforce each other.
- **Uniform interface.** Intermediaries can act intelligently (caching GETs, retrying idempotent requests) _because_ HTTP methods have standard meanings.
- **Defense in depth.** Validating auth at both gateway and app is a deliberate redundancy, so one misconfigured layer doesn't expose everything.
- **The "hairy" side of the pattern**: service meshes and sidecars push layering _between_ internal services, giving you retries, mTLS, and tracing without changing application code.

## Recap

The layered system constraint says a client can't tell whether it's talking to the origin or to an intermediary. That's what lets you insert load balancers, CDNs, gateways, firewalls, and proxies as your system grows, all without touching clients. To remain transparent, each layer must preserve HTTP semantics, honor caching headers, and pass along context through `Via` and `X-Forwarded-*`/`Forwarded` (trusted only from proxies you control). In Spring Boot you build layers with Spring Cloud Gateway, Spring Security, and servlet filters, and you use `server.forward-headers-strategy` so the app sees the real client scheme, host, and IP. The price is extra latency, complexity, and failure points, so add layers on purpose, keep each one stateless, and keep your timeouts coordinated.




[[Spring Framework]]
[[Rest-API]]