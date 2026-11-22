
Registration and discovery are the client's two separate jobs — telling Eureka Server it exists, and asking Eureka Server where everyone else is. You've seen the config flags for both already; this is what's actually happening underneath those flags: the lifecycle a registration goes through, why discovery isn't as instant as it looks, and how to query the registry from code instead of letting Feign do it invisibly.

## The registration lifecycle: more than "registered or not"

An instance isn't just present-or-absent in the registry — it carries a **status**, and that status changes over its lifetime:

```
STARTING → UP → (heartbeats every lease-renewal-interval-in-seconds) → DOWN / OUT_OF_SERVICE
```

When a Spring Boot app with the Eureka client starts, it registers itself with status `STARTING` _before_ the application context is fully ready — this exists specifically so other services don't get routed to an instance that's still initializing. It flips to `UP` once the app is actually ready to serve traffic. By default, Spring Boot ties this flip to Actuator's health indicator rather than just "the JVM finished booting":

```yaml
eureka:
  client:
    healthcheck:
      enabled: true   # instance status in Eureka follows Actuator's /actuator/health, not just "process is running"
```

With this on, if `/actuator/health` reports `DOWN` — say, the database connection pool can't reach Postgres — Eureka reflects that as `DOWN` too, and LoadBalancer stops routing new calls to it, even though the JVM process itself is still alive. Without it, Eureka only knows "the process sent a heartbeat," which says nothing about whether the app can actually do its job.

## Discovery isn't a live query — it's a cached snapshot

This is the gotcha people hit without realizing it: a Eureka **client** does not call the server fresh on every single lookup. On startup it pulls the full registry once, then refreshes that local cache on a timer:

```yaml
eureka:
  client:
    registry-fetch-interval-seconds: 30   # default — how often the client re-pulls the registry
```

Every discovery call your app makes — every Feign call, every `LoadBalancer`-resolved request — reads from that **local in-memory cache**, not a live network call to Eureka Server. This is a deliberate trade-off: it means Eureka Server being briefly unreachable doesn't break service-to-service calls at all (clients keep working off their last-known cache), but it also means a newly registered instance can take up to `registry-fetch-interval-seconds` (30 seconds by default) before _other_ services' local caches even know it exists — "I just registered, why isn't anyone sending me traffic yet" is almost always this cache delay, not a registration failure.

```
Instance C starts → registers with Eureka Server (now UP in the server's registry)
   ↓ (up to 30s later)
Instance A's local cache refreshes → now Instance A's Feign calls can route to C
```

This is also why a slow rolling deployment (new instances staggered with delay) is often intentional — it gives caches across the fleet time to catch up before traffic ramps onto a new instance.

## Querying the registry directly: the DiscoveryClient API

Feign and LoadBalancer use this underneath, but you can call it yourself when you need to reason about instances explicitly — picking a specific one, checking how many are live, reading instance metadata:

```java
@Service
public class InstanceInspector {

    private final DiscoveryClient discoveryClient;

    public InstanceInspector(DiscoveryClient discoveryClient) {
        this.discoveryClient = discoveryClient;
    }

    public void inspect() {
        List<ServiceInstance> instances = discoveryClient.getInstances("order-service");

        for (ServiceInstance instance : instances) {
            String url = instance.getUri().toString();      // e.g. http://10.0.1.14:8081
            Map<String, String> metadata = instance.getMetadata(); // custom key-value tags
            System.out.println(url + " " + metadata);
        }

        List<String> allKnownServices = discoveryClient.getServices(); // every application name in the registry
    }
}
```

`Spring Cloud`'s `DiscoveryClient` is a vendor-neutral interface — the same code works unchanged if the registry behind it were Consul instead of Eureka, because it's an abstraction over "some registry," not Eureka-specific. This is the escape hatch for anything Feign's declarative style can't express — for example, deliberately calling a _specific_ instance rather than letting the load balancer choose one, which comes up in things like cache-warming or targeted debugging calls.

## Attaching metadata to a registration

An instance can carry arbitrary key-value tags alongside its address, set at registration time:

```yaml
eureka:
  instance:
    metadata-map:
      zone: us-east-1a
      version: 2.3.0
      team: payments
```

That metadata shows up in `instance.getMetadata()` on any caller using `DiscoveryClient`, and in the Eureka dashboard. The most common real use is **zone-aware routing** — tagging instances with their availability zone so LoadBalancer can be configured to prefer same-zone instances over cross-zone ones, cutting network latency and often cross-zone data transfer cost:

```yaml
eureka:
  client:
    prefer-same-zone-eureka: true
```

## Deregistration: the orderly shutdown path

A clean shutdown (not a crash) should actively tell Eureka "I'm gone" rather than waiting for a heartbeat timeout to evict it — the gap between "process stopped" and "heartbeat-based eviction notices" is exactly the window where other services might still route traffic to a dead instance. Spring Boot wires this up for you automatically through the `DiscoveryClient`'s shutdown hook when the application context closes normally (`Ctrl+C`, a graceful container stop), sending an explicit deregistration call rather than just disappearing. This is also the reason graceful shutdown handling matters in containerized deployments — if the platform sends `SIGKILL` instead of giving the app time to run its shutdown hooks, that deregistration call never fires, and you're back to depending on the heartbeat-timeout eviction you saw on the server side.


[[Spring Framework]]
