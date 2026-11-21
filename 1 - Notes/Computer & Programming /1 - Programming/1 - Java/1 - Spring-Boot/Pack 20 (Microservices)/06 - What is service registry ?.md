
A **service registry** is the component in a microservices system that keeps track of which service instances exist and where they currently live (host + port). You already just saw a concrete implementation of this — **Eureka** — so think of this as zooming out one level: this is the _concept_ Eureka implements.

### Why it exists

In a monolith, if one part of your code wants to call another part, it just calls a method — everything's in the same process, same address. In microservices, `order-service` and `payment-service` are separate processes, often on separate machines/containers, and their network locations aren't fixed:

- Instances scale up and down (2 instances now, 5 at peak load)
- Containers restart with new IPs
- Deployments move services to different hosts

So you can't hardcode `http://192.168.1.5:8082/payments`. You need something that always knows the _current_ truth of "where is `payment-service` right now, across all its running instances."

### The two core operations

A service registry supports exactly two things:

1. **Registration** — a service instance announces itself on startup: _"I am `payment-service`, I'm at `10.0.0.12:8082`, here's a health-check endpoint to verify I'm alive."_
2. **Discovery** — another service asks: _"Give me the current list of instances for `payment-service`."_

```
payment-service instance A  ──register──▶  Service Registry
payment-service instance B  ──register──▶        │
                                                   │
order-service  ──"where is payment-service?"──▶  Service Registry
                                                   │
                                          ◀── [A: 10.0.0.12:8082,
                                               B: 10.0.0.13:8082]
```

### Keeping the registry honest

A registry is only useful if its data is current, so instances send periodic **heartbeats**. If an instance stops heartbeating, the registry eventually removes it — otherwise you'd discover a dead instance and your request would fail. This is exactly the mechanism Eureka's 30-second heartbeat and eviction logic implements.

### Client-side vs server-side discovery

This is a design distinction worth having explicitly:

- **Client-side discovery**: the calling service itself queries the registry and picks an instance (this is what Eureka + `@LoadBalanced` does — the client does the lookup and load-balancing).
- **Server-side discovery**: a separate component (like a load balancer or your API gateway) queries the registry on the caller's behalf, so the caller just hits one fixed address and the routing/lookup happens behind it.

Eureka is the classic example of the first style; something like AWS's ALB with ECS service discovery, or Kubernetes' own built-in DNS-based discovery, leans toward the second.

### Why Kubernetes users sometimes skip Eureka entirely

Worth knowing: if you deploy on Kubernetes, Kubernetes already has its own built-in service registry (via `kube-dns`/CoreDNS and Services), so Eureka becomes redundant there — Eureka mainly earns its keep when you're _not_ on an orchestrator that already solves this for you.


[[Spring Framework]]