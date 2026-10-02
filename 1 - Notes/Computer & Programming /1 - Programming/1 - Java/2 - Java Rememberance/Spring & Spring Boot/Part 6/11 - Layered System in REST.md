


The **Layered System** is one of the six architectural constraints of REST. It's the one people nod at and then never think about again — but it's quietly responsible for a huge portion of why REST APIs scale.

## The core idea

> A client should not be able to tell whether it's connected directly to the origin server, or to an intermediary in between.

That's it. The client talks to *something* that speaks HTTP and returns the right response. Whether that something is:

- the actual server,
- a load balancer,
- a CDN edge node,
- an API gateway,
- a reverse proxy,
- a caching layer,
- a security filter,

…is **invisible** to the client. And that's the whole point.

## The restaurant analogy (extended)

In the earlier API analogy, the waiter was the interface. Now imagine the restaurant has grown:

- A **host** seats you.
- A **waiter** takes your order.
- A **runner** brings the food.
- A **sommelier** handles wine.
- A **cashier** takes payment.

You, the customer, just interact with "the restaurant." You don't know or care that five different people touched your meal. Each is a **layer**, and each has one job.

If the restaurant hires a new runner, you don't notice. If they replace the sommelier with an automated wine dispenser, you still don't notice. That's layering.

## What counts as a layer?

Any component that sits between the client and the origin server and speaks HTTP can be a layer:

| Layer | Job |
|-------|-----|
| **Load balancer** | Distributes requests across servers |
| **Reverse proxy** (Nginx, HAProxy) | Routes, terminates TLS, compresses |
| **API gateway** (Spring Cloud Gateway, Kong, Zuul) | Auth, rate limiting, routing |
| **CDN** (Cloudflare, CloudFront) | Caches and serves content near the user |
| **Caching proxy** (Varnish, Squid) | Stores responses to avoid hitting origin |
| **WAF** (Web Application Firewall) | Blocks malicious traffic |
| **Service mesh sidecar** (Istio, Linkerd) | Handles mTLS, retries, observability |
| **BFF** (Backend for Frontend) | Aggregates microservices for one client type |

Each is transparent to the client. The client sends the same request regardless.

## Why this matters

### 1. Scalability

You can add layers without changing clients. Need more capacity? Add a load balancer. Need faster global response times? Add a CDN. The client code never changes.

### 2. Separation of concerns

Each layer does one thing:
- Gateway handles auth.
- CDN handles caching.
- Load balancer handles distribution.
- Origin server handles business logic.

No single component has to be good at everything.

### 3. Security

You can insert a WAF or auth layer without touching the origin. You can terminate TLS at the edge. You can rate-limit at the gateway. The origin server trusts traffic that has passed through the layers.

### 4. Flexibility

Swap out any layer. Replace Nginx with HAProxy. Replace Varnish with CloudFront. Migrate from a monolith to microservices behind a gateway. Clients don't know.

### 5. Testability

You can insert a mock layer or a chaos layer during testing. You can replay traffic through a proxy. Layering makes the system observable at each boundary.

## The rules a layer must follow

A layer is **not** free to do whatever it wants. To be a transparent REST layer, it must:

1. **Speak the same protocol** — HTTP in, HTTP out.
2. **Preserve semantics** — a `GET` must remain safe; a `DELETE` must remain unsafe.
3. **Respect caching headers** — if a response says `no-store`, the layer must not store it.
4. **Forward or regenerate the right headers** — `Via`, `X-Forwarded-For`, `Forwarded`, etc.
5. **Not break the contract** — it can add value (caching, auth) but not change the API's meaning.

If a layer changes the semantics, it's no longer transparent. That's a bug.

## The `Via` header

HTTP has a header specifically for layering:

```
Via: 1.1 varnish, 1.1 nginx
```

Each proxy that handles the request appends itself. This lets you debug the chain: "which layers did this request pass through?" It's optional but useful for observability.

## `X-Forwarded-*` headers

When a request passes through proxies, the origin server sees the **proxy's** IP, not the client's. Headers fix that:

```
X-Forwarded-For: 203.0.113.7, 198.51.100.4
X-Forwarded-Proto: https
X-Forwarded-Host: api.example.com
X-Forwarded-Port: 443
```

The origin server reads these to know the real client. In Spring Boot:

```java
server.forward-headers-strategy=framework
```

or, for older setups:

```java
server.use-forward-headers=true
```

This makes `request.getRemoteAddr()` and `request.getScheme()` return the original client's values instead of the proxy's.

**Security warning:** only trust `X-Forwarded-*` from proxies you control. Otherwise a client can spoof their IP.

## Layering in Spring Boot

Spring Boot doesn't have a "layered system" feature — layering is an architectural concern. But Spring gives you tools to build layers:

### 1. Spring Cloud Gateway (API gateway layer)

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

The gateway handles routing, auth, and rate limiting. The user-service never sees raw internet traffic.

### 2. Spring Security (auth layer)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));
        return http.build();
    }
}
```

This is a **filter layer** inside the app. It sits in front of your controllers.

### 3. Filters and interceptors (in-app layers)

```java
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws IOException, ServletException {
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(request, response);   // pass to the next layer
        } finally {
            long elapsed = System.currentTimeMillis() - start;
            log.info("{} {} -> {} ({} ms)",
                    request.getMethod(), request.getRequestURI(),
                    response.getStatus(), elapsed);
        }
    }
}
```

Each filter is a layer. They stack:

```
Client
  → TLS termination (Nginx)
    → API Gateway (Spring Cloud Gateway)
      → Auth filter (Spring Security)
        → Logging filter
          → Rate-limit filter
            → Controller
              → Service
                → Repository
                  → Database
```

The client only sees the outermost boundary. Every layer in between is invisible.

### 4. Service-to-service layering

In microservices, services call each other through HTTP:

```
Client → API Gateway → Order Service → Payment Service → Bank API
```

Each hop is a layer. The client doesn't know the Order Service calls Payment, which calls a bank. That's the layered system in action.

## A concrete request walkthrough

A mobile app calls `GET https://api.example.com/users/42`.

```
1. DNS resolves api.example.com → Cloudflare edge IP
2. Cloudflare (CDN layer)
   - checks cache: miss
   - forwards to origin
3. Load balancer
   - picks server #3
   - forwards
4. Nginx reverse proxy
   - terminates TLS
   - adds X-Forwarded-For
   - forwards to Spring Cloud Gateway
5. Spring Cloud Gateway (API gateway layer)
   - validates JWT
   - checks rate limit
   - routes to user-service
6. Spring Security filter (in-app layer)
   - re-validates JWT (defense in depth)
   - sets SecurityContext
7. Logging filter
   - starts timer
8. Controller
   - calls service, returns user 42 as JSON
9. Response travels back through every layer
   - Gateway adds Cache-Control
   - Cloudflare caches it for 60s
10. Client receives 200 OK
```

The client sent one request and got one response. It has no idea that **eight layers** touched it. That's the layered system.

## What layering costs you

Layering isn't free. Each layer adds:

- **Latency** — every hop costs milliseconds
- **Complexity** — more moving parts to configure, deploy, monitor
- **Debugging difficulty** — "where did this header get stripped?"
- **Failure modes** — a broken CDN breaks everything behind it
- **Cost** — gateways, CDNs, and meshes aren't free

The REST constraint says layering *should be possible*, not that you should add layers greedily. Add a layer when it earns its keep.

## Common pitfalls

1. **Assuming the client IP is the real IP.** Behind a proxy, it's the proxy's IP. Read `X-Forwarded-For` — but only from trusted proxies.

2. **Trusting `X-Forwarded-*` from the internet.** Attackers can forge these. Only strip and re-add them at your edge.

3. **Caching in the wrong layer.** If a CDN caches user-specific data without `Cache-Control: private`, you leak data between users.

4. **Breaking statelessness across layers.** If the gateway stores session state and the origin expects it, you've broken statelessness. Keep each layer stateless.

5. **Forgetting `Vary`.** A CDN caching a response that varies on `Accept-Language` without `Vary` serves the wrong language.

6. **Double authentication.** Gateway validates JWT, then Spring Security validates again. That's fine — but make sure both use the same key/issuer, or requests fail mysteriously.

7. **Losing headers through layers.** Some proxies strip unknown headers. Use standard ones (`Authorization`, `Forwarded`) or configure your proxies.

8. **Timeouts stacking.** If each of 5 layers has a 30s timeout, a slow request can hang for 150s. Set timeouts deliberately and consistently.

## Layering vs. statelessness

These two constraints work together:

- **Statelessness** means any layer can handle any request — no sticky sessions required.
- **Layering** means you can add as many layers as you want, because each request carries everything needed.

Together, they're why REST APIs scale horizontally. Remove either, and the whole thing falls apart.

## TL;DR

- **Layered System** = a client can't tell if it's talking to the origin server or to an intermediary.
- Layers include: load balancers, CDNs, API gateways, reverse proxies, WAFs, service meshes, and in-app filters.
- Each layer must **preserve HTTP semantics** and respect caching headers to stay transparent.
- Layering gives you **scalability, security, separation of concerns, and replaceability**.
- Spring Boot tools: Spring Cloud Gateway (gateway layer), Spring Security (auth layer), filters/interceptors (in-app layers), `server.forward-headers-strategy` (header handling).
- Costs: latency, complexity, more failure points. Add layers deliberately.
- It pairs with **statelessness** to enable horizontal scaling.




[[Spring Framework]]