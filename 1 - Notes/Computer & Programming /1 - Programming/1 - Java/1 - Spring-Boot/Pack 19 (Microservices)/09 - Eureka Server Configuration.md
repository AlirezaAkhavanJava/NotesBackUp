

Eureka Server is the actual process that runs the service registry — the thing every microservice registers itself with and queries to find other services. "Configuring" it means two closely linked things: configuring the _server itself_ (how it runs, whether it talks to other Eureka servers, how aggressively it evicts dead instances) and configuring the _clients_ that register with it (because a lot of the server's behavior — like how long an instance is considered "alive" — is actually driven by properties the client sends). You already know _why_ a registry exists; this is about the actual knobs you turn to run one properly, from a single dev instance up to a real multi-zone production setup.

## 1. Standing up the server

You need the server dependency and one annotation.

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```

```java
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
```

`@EnableEurekaServer` activates the embedded registry endpoints (`/eureka/apps`, the dashboard at `/`, etc.) on this Spring Boot app. By itself it runs, but it runs in a mode that's wrong for anything but local dev, which brings us to the first real configuration decision.

## 2. Standalone vs. peer-aware mode

This is the single biggest fork in Eureka Server configuration, and it's controlled by whether the server registers itself as a _client_ of another Eureka server.

**Standalone (dev only):**

```yaml
server:
  port: 8761

eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
  server:
    enable-self-preservation: false   # see section 3
```

`register-with-eureka: false` and `fetch-registry: false` tell this instance "don't try to act like a client of some other Eureka server — you're alone." This is fine for local testing, but it means if this one process dies, every service loses its registry instantly. Not acceptable in production.

**Peer-aware (production):** you run two or more Eureka servers that register _with each other_. Each one is both a server and a client of the other.

```yaml
# eureka-server-1 (application-peer1.yml)
eureka:
  instance:
    hostname: peer1
  client:
    service-url:
      defaultZone: http://peer2:8762/eureka/
    register-with-eureka: true
    fetch-registry: true
```

```yaml
# eureka-server-2 (application-peer2.yml)
eureka:
  instance:
    hostname: peer2
  client:
    service-url:
      defaultZone: http://peer1:8761/eureka/
    register-with-eureka: true
    fetch-registry: true
```

Each server's `defaultZone` points at the _other_ server, not itself. They replicate their registries to each other, so if a client registers with peer1, peer2 learns about it too. If peer1 goes down, clients configured with both URLs just fail over to peer2 — no gap in the registry.

## 3. Self-preservation and eviction — the behavior most people misconfigure

This is the part of Eureka Server config that actually matters operationally, and it's the one setting people disable without understanding why it existed.

Eureka Server tracks, as a percentage, how many renewals ("heartbeats") it's receiving versus how many it _expects_ based on the number of registered instances. If that number drops sharply — say, below 85% — the server assumes something is wrong with the _network_, not with the instances, and stops evicting anything. The idea: a network partition shouldn't look identical to "half your fleet died," so instead of wiping the registry, it freezes evictions until renewals recover.

```yaml
eureka:
  server:
    enable-self-preservation: true      # default; keep true in prod
    renewal-percent-threshold: 0.85     # the 85% threshold above
    eviction-interval-timer-in-ms: 60000
```

In production, leave `enable-self-preservation: true`. Disabling it (as you'll see in almost every tutorial's "quick start") is only reasonable for a single-node dev setup where you _want_ stale instances evicted fast so your testing isn't confusing — in a real multi-instance cluster it protects you from a registry that panics during a transient network blip.

## 4. Client-side properties that drive server behavior

The server's eviction decisions are downstream of properties set on the _clients_, not the server. These live in every registering service's config, but you need to understand them to tune the server correctly.

```yaml
eureka:
  instance:
    lease-renewal-interval-in-seconds: 30   # how often this client sends a heartbeat
    lease-expiration-duration-in-seconds: 90 # server waits this long with no heartbeat before evicting
```

The server's expected renewal count (used in the self-preservation math from section 3) is calculated from how many clients are registered and how often they're _supposed_ to renew — which is exactly these two client properties. Shortening `lease-renewal-interval-in-seconds` makes the registry detect dead instances faster, at the cost of more network chatter; lengthening it does the opposite. Most production setups leave these at default and tune responsiveness elsewhere (e.g., client-side load balancer retry settings) instead.

## 5. Response caching — why new instances take a moment to show up

Eureka Server doesn't serve registry reads from a live data structure on every request; it serves them from a cache that's refreshed on an interval, because registry reads vastly outnumber registry writes in a real cluster and recomputing the full response every time would be wasteful.

```yaml
eureka:
  server:
    response-cache-update-interval-ms: 30000   # default
    use-read-only-response-cache: true          # default
```

This is why a freshly registered instance can take up to ~30 seconds to be visible to other clients — it's not a bug, it's this cache interval. If you're demoing something and instances seem to "not show up," this setting is why, not a misconfiguration elsewhere.

## 6. Security

The dashboard and the `/eureka/**` endpoints are unauthenticated by default, which is a real problem since anything that can reach the server can register itself as _any_ service name. If Spring Security is on the classpath, you secure it like any other endpoint, but Eureka's HTTP client needs the credentials baked into the registration URL itself:

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://eureka-user:eureka-pass@localhost:8761/eureka/
```

```java
@Configuration
public class EurekaServerSecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
            .httpBasic(Customizer.withDefaults())
            .csrf(csrf -> csrf.ignoringRequestMatchers("/eureka/**")); // Eureka's own HTTP client can't do CSRF tokens
        return http.build();
    }
}
```

The CSRF exclusion on `/eureka/**` is non-negotiable in practice — Eureka's registration client has no concept of CSRF tokens, so leaving CSRF protection on for that path means every client registration gets rejected.

## 7. Zones and availability zones

If you're running across multiple data centers or cloud AZs, Eureka supports zone awareness so clients prefer registering with and reading from a server in their own zone before falling back to others.

```yaml
eureka:
  client:
    region: us-east
    availability-zones:
      us-east: zone1,zone2
    service-url:
      zone1: http://peer1:8761/eureka/
      zone2: http://peer2:8762/eureka/
```

A client in `zone1` will prefer `peer1`; if that's unreachable, it falls back to `zone2`'s servers. This matters at real multi-region scale; for a typical single-region deployment you can ignore this entirely and stick with `defaultZone`.

## Putting it together: a realistic production baseline

```yaml
server:
  port: 8761

eureka:
  instance:
    hostname: ${EUREKA_HOSTNAME}
    lease-renewal-interval-in-seconds: 30
    lease-expiration-duration-in-seconds: 90
  client:
    register-with-eureka: true
    fetch-registry: true
    service-url:
      defaultZone: ${EUREKA_PEER_URL}
  server:
    enable-self-preservation: true
    renewal-percent-threshold: 0.85
    response-cache-update-interval-ms: 30000
```

Run at least two instances of this, each pointing at the other via `EUREKA_PEER_URL`, each behind Spring Security with basic auth, and you have a setup that survives a single node failure without the registry either freezing up permanently or panic-evicting your whole fleet on a network hiccup.


[[Spring Framework]]