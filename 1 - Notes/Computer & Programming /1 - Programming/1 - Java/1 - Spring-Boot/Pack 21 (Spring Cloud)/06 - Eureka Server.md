
Eureka Server is the concrete implementation of the registry role you just learned about in the abstract — this is what actually running one looks like: the annotation, the config knobs that matter in production, and the dashboard it gives you for free.

## Standing one up

```java
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
```

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```

```yaml
server:
  port: 8761

eureka:
  client:
    register-with-eureka: false   # this server shouldn't register itself as a client
    fetch-registry: false         # and shouldn't try to pull a registry from itself
  server:
    enable-self-preservation: true
```

That `register-with-eureka: false` / `fetch-registry: false` pair matters: by default, every app with the Eureka starter on its classpath — including the server itself — tries to act as a _client_ too (register and fetch). A standalone Eureka Server needs those switched off, or it spends its time talking to itself.

Run it, visit `http://localhost:8761`, and you get Eureka's built-in dashboard: a live table of every registered application, how many instances each has, and their status (UP, DOWN, OUT_OF_SERVICE). This is the first place to look when a client "can't find" another service — if the target isn't listed here at all, the problem is on the registration side, not the calling side.

## The client side, with the options that actually matter

You've seen the minimal client config already. Here's what each piece of a realistic one is doing:

```yaml
spring:
  application:
    name: order-service   # THIS is the name other services discover you by

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka
  instance:
    prefer-ip-address: true          # register IP, not hostname
    lease-renewal-interval-in-seconds: 10    # heartbeat frequency
    lease-expiration-duration-in-seconds: 30 # how long before a missed heartbeat = eviction
```

`spring.application.name` isn't cosmetic — it's the literal key other services use (the `name = "order-service"` you wrote in a `@FeignClient` earlier _is_ this value). `prefer-ip-address: true` matters specifically in containerized environments, where a container's hostname is often a meaningless auto-generated string that no other container can resolve, but its IP is directly reachable — without this flag, Eureka registers the hostname and other services fail to connect to something DNS can't look up.

The heartbeat pair controls how fast Eureka notices a dead instance: with the values above, an instance missing its 10-second heartbeat for 30 seconds total gets evicted. Tightening these makes dead instances disappear from discovery faster, at the cost of more network chatter and a higher risk of evicting an instance that's just briefly slow rather than actually dead.

## Self-preservation mode

You met this conceptually in the fundamentals lesson — here's what configuring it actually looks like. Eureka Server tracks the overall rate of renewals it's receiving across _all_ registered instances. If that rate drops sharply all at once (the classic sign of a network partition rather than mass instance death), it refuses to start evicting instances, favoring a possibly-stale registry over wrongly wiping out a healthy fleet:

```yaml
eureka:
  server:
    enable-self-preservation: true   # production default — leave this on
    renewal-percent-threshold: 0.85  # if renewals drop below 85% of expected, suspect a network issue, not dead instances
```

In local development, this becomes an annoyance rather than a safety net: you restart services constantly, Eureka sees "a lot of instances just stopped renewing," assumes network trouble, and keeps showing dead instances as UP for far longer than you want to wait while debugging. That's why local/dev profiles commonly disable it:

```yaml
# application-dev.yml, Eureka Server
eureka:
  server:
    enable-self-preservation: false
```

Never ship that to production — it removes the exact protection that keeps a network blip from looking like a mass outage.

## Peer awareness: running more than one Eureka Server

A single Eureka Server is a single point of failure for the whole discovery mechanism — if it goes down, no service can look up any other service (existing clients still have their last-known registry cached locally, which cushions this somewhat, but new instances can't register and callers can't discover new ones). Production Eureka runs as a small cluster of peers that replicate their registries to each other:

```yaml
# Eureka Server instance 1
server:
  port: 8761
eureka:
  instance:
    hostname: eureka-peer1
  client:
    service-url:
      defaultZone: http://eureka-peer2:8762/eureka
    register-with-eureka: true    # peers DO register with each other
    fetch-registry: true
```

```yaml
# Eureka Server instance 2
server:
  port: 8762
eureka:
  instance:
    hostname: eureka-peer2
  client:
    service-url:
      defaultZone: http://eureka-peer1:8761/eureka
    register-with-eureka: true
    fetch-registry: true
```

Each server here points at the _other_ as its `defaultZone` — that's what makes them peers rather than two unrelated standalone servers. Each one registers itself with the other, and each replicates its registry across. Clients then list _both_ peers in their own `defaultZone`, comma-separated:

```yaml
# a client, pointed at the cluster, not one instance
eureka:
  client:
    service-url:
      defaultZone: http://eureka-peer1:8761/eureka,http://eureka-peer2:8762/eureka
```

The client tries the list in order and fails over automatically if one peer is unreachable — this is what actually removes the single point of failure, not the peer replication by itself.

## Securing the dashboard and registration endpoint

By default, Eureka Server's dashboard and its registration API are wide open — anyone who can reach port 8761 can see every registered service and its addresses, which is an internal map of your whole architecture handed out for free. Basic auth is the common minimum:

```yaml
spring:
  security:
    user:
      name: eureka-admin
      password: ${EUREKA_PASSWORD}
```

```yaml
# clients must now include credentials in the URL
eureka:
  client:
    service-url:
      defaultZone: http://eureka-admin:${EUREKA_PASSWORD}@localhost:8761/eureka
```

Adding Spring Security to the server's classpath secures _all_ its endpoints by default, including the registration/discovery API that clients use — which is why the client's `defaultZone` URL needs those same credentials embedded, not just a browser visiting the dashboard.

[[Spring Framework]]
