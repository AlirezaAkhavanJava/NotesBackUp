
Eureka's configuration surface splits into three logical groups: **server-side settings** (how the registry itself behaves), **client-side settings** (how an instance talks to the registry), and **instance-level settings** (how an instance describes itself to the registry). Knowing which group a property belongs to is half the battle — the prefixes tell you: `eureka.server.*`, `eureka.client.*`, `eureka.instance.*`.

### Server-side configuration (`eureka.server.*`)

These live on the Eureka Server app and control registry behavior itself.

```properties
eureka.server.enable-self-preservation=true
eureka.server.renewal-percent-threshold=0.85
eureka.server.eviction-interval-timer-in-ms=60000
```

- **`enable-self-preservation`** — you already touched this conceptually: if the percentage of instances renewing their lease drops below the threshold, the server assumes a network issue and stops evicting instances, rather than wiping the registry. In local dev, this is almost always turned `false`, because with just one or two instances, normal restarts will trip the threshold and flood your logs with self-preservation warnings.
- **`renewal-percent-threshold`** — the cutoff percentage used above (default 0.85 = 85%).
- **`eviction-interval-timer-in-ms`** — how often the server runs its cleanup task to evict expired instances.

```properties
# typical local/dev override
eureka.server.enable-self-preservation=false
```

### Client-side configuration (`eureka.client.*`)

These control how an instance _behaves as a client of the registry_ — registering, fetching, and talking to peers.

```properties
eureka.client.register-with-eureka=true
eureka.client.fetch-registry=true
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
eureka.client.registry-fetch-interval-seconds=30
```

- **`register-with-eureka`** — should this app register itself? The Eureka Server sets this to `false` for itself (a registry doesn't need to register with itself), while every normal microservice leaves it `true`.
- **`fetch-registry`** — should this app pull down the full registry to cache locally? A plain client needs `true` so it can resolve other services' addresses; the server itself sets this `false` too (unless you're running multiple peer servers — more below).
- **`service-url.defaultZone`** — the registry's own address. The name `defaultZone` exists because Eureka supports **zones** (think regions/availability zones); if you don't configure zones explicitly, everything falls into `defaultZone`.
- **`registry-fetch-interval-seconds`** — how often a client refreshes its local cached copy of the registry (default 30s). Lower this for faster discovery of new instances at the cost of more network chatter.

### Instance-level configuration (`eureka.instance.*`)

This is how a given instance describes _itself_ in the registry — its identity, host info, and lease timing.

```properties
eureka.instance.hostname=${HOSTNAME}
eureka.instance.prefer-ip-address=true
eureka.instance.lease-renewal-interval-in-seconds=30
eureka.instance.lease-expiration-duration-in-seconds=90
eureka.instance.instance-id=${spring.application.name}:${random.value}
```

- **`prefer-ip-address`** — register using the instance's IP instead of hostname. In containerized environments (Docker, Kubernetes), hostnames are often unresolvable outside the container's own network, so this is set `true` almost everywhere in practice.
- **`lease-renewal-interval-in-seconds`** — the heartbeat interval you already learned about conceptually (default 30s) — how often this instance tells the server "I'm alive."
- **`lease-expiration-duration-in-seconds`** — how long the server waits without a heartbeat before evicting the instance (default 90s = 3 missed heartbeats). This is the actual timeout knob; the heartbeat interval alone doesn't determine eviction speed, this does.
- **`instance-id`** — the unique identifier for _this specific instance_, distinct from `spring.application.name` (which is the _service's_ name, shared by all its instances). Without a unique `instance-id`, running two instances of the same service on one machine can cause the registry to treat them as one entry and overwrite each other.

### Peer-aware Eureka servers (high availability)

A single Eureka Server is a single point of failure, so production setups usually run Eureka servers as peers that replicate to each other:

```properties
# server 1 (peer1)
eureka.client.service-url.defaultZone=http://peer2:8762/eureka/

# server 2 (peer2)
eureka.client.service-url.defaultZone=http://peer1:8761/eureka/
```

Notice each server points to the _other_ as its "registry URL" — meaning each server also acts as a client of its peer, which is why `register-with-eureka` and `fetch-registry` are both `true` in this setup (unlike the single-server case where they're `false`).

### Properties you'll see but rarely need to touch

- `eureka.instance.lease-renewal-interval-in-seconds` vs `lease-expiration-duration-in-seconds` — the only pair most people tighten (e.g. 5s/15s) when they want faster failure detection for demos, at the cost of more network load in real production traffic.
- `eureka.client.healthcheck.enabled=true` — makes Eureka ask Spring Boot Actuator's actual health status instead of just "the process is up," so an instance that's alive but, say, lost its DB connection gets correctly reported as `DOWN` rather than `UP`.



[[Spring Framework]]