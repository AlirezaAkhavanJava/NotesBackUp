
Service discovery fundamentals sit one level below the Eureka mechanics you already know — this is about the general _pattern_ that Eureka (and its alternatives) implement, the architectural choices that pattern forces you to make, and why those choices matter even if you only ever use Eureka. Knowing the pattern is what lets you read about Consul, Zookeeper, or Kubernetes-native discovery later and immediately know where each piece fits, instead of learning each one from scratch as if it were unrelated.

## The problem, stripped down

In a monolith, calling another part of your system is a method call — the address is "wherever the JVM loaded that class." In microservices, calling another service means knowing an actual network address: host and port. The naive answer — hardcode `http://192.168.1.14:8081` in `order-service`'s config — breaks the moment any of these happen: that instance crashes and gets rescheduled somewhere else, you scale `order-service` from one instance to five, or you deploy a new version to a new address and retire the old one. Service discovery exists so that calling another service means asking "where is `order-service` _right now_" instead of knowing a fixed address in advance.

## The three moving parts every discovery system has

Any service discovery solution — Eureka, Consul, Zookeeper, Kubernetes DNS, all of them — is built from the same three pieces:

1. **A registry** — a store of "service name → list of live addresses," kept somewhere all services can reach.
2. **Registration** — the mechanism by which an instance's address gets _into_ that registry when it starts (and comes out when it stops or dies).
3. **Discovery** — the mechanism by which a caller turns a service name into an actual address to call.

Eureka happens to bundle a registry, client-side registration, and client-side discovery into one project. But those are three independently-variable decisions, and different systems make different choices on each — which is exactly where the interesting architecture is.

## Registration: who tells the registry an instance exists?

**Self-registration** — the instance registers itself on startup, and de-registers (or lets a heartbeat lapse) on shutdown:

```java
@SpringBootApplication
@EnableDiscoveryClient   // triggers self-registration with whatever registry is on the classpath
public class OrderServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }
}
```

This is the pattern Eureka uses. It's simple, but it couples every service to the registry's client library — every service needs to know _how_ to register with whichever registry you picked.

**Third-party registration** — the service itself knows nothing about the registry; a separate component watches the deployment platform and registers/deregisters instances on its behalf. This is how Kubernetes-native discovery works: your pod never calls any "register me" API — Kubernetes itself updates its internal registry (backing Service DNS entries) the moment a pod becomes healthy, because Kubernetes is already the thing that created and is tracking that pod. Nothing in your application code needs a discovery client at all.

The trade-off: self-registration gives you fine control (you decide exactly when an instance considers itself ready) but adds a library dependency to every service. Third-party registration removes that dependency but ties you to whatever platform is doing the watching — you lose that capability for free if you're not on that platform.

## Discovery: who decides which address to actually call?

**Client-side discovery** — the calling service queries the registry directly, gets back a list of live addresses, and picks one itself (this is exactly LoadBalancer's job, which you've already seen sitting on top of Eureka). The caller does the work; the registry just answers "here's who's available."

**Server-side discovery** — the caller doesn't talk to the registry at all. It sends every request to one fixed, stable address — a load balancer — and _that_ load balancer is the thing that queries the registry and routes the request onward. This is the AWS ELB / Kubernetes Service model: your code calls `http://order-service` (a stable DNS name), and the platform transparently resolves which actual pod gets it.

```
Client-side (Eureka + Feign + LoadBalancer):
  checkout-service --[query]--> Eureka --[list of addresses]--> checkout-service picks one --> order-service instance

Server-side (Kubernetes Service / cloud LB):
  checkout-service --[fixed address]--> Load Balancer --[looks up + routes]--> order-service instance
```

Client-side discovery pushes the load-balancing logic and the registry-awareness into every single service. Server-side discovery centralizes it — services stay simpler, but now there's a load balancer hop (and a load-balancing component to operate) on every call.

## Health checks: how dead instances actually get removed

A registry that only removes entries when a service politely says "I'm shutting down" is wrong the moment a process is killed abruptly — which is the common case in real failures. Every discovery system solves this with some form of heartbeat/TTL:

- **Eureka**: each client sends a heartbeat every 30 seconds by default; miss enough heartbeats and the server evicts the instance from the registry, on the assumption it's dead.
- **Consul / Kubernetes**: an active health check — the registry (or platform) itself periodically _calls_ the instance (an HTTP endpoint, a TCP probe) rather than waiting to be heartbeated. An instance that stops responding gets marked unhealthy and pulled from discovery results, typically faster than a heartbeat-timeout approach.

This distinction matters in practice: heartbeat-based systems are vulnerable to a specific failure mode called a **self-preservation** trade-off — if network partitions make many instances miss heartbeats at once, is that "everyone actually died" or "the network broke"? Eureka's default behavior, when too many instances miss heartbeats simultaneously, is to stop evicting anything and keep serving the stale registry rather than risk wrongly wiping out a healthy fleet during a network blip — favoring availability of (possibly stale) data over strict correctness.

## DNS-based discovery: the simplest possible version

Not every system needs Eureka-level machinery. DNS-based discovery is the oldest and crudest form: the registry _is_ DNS, "discovery" is just a DNS lookup, and a load balancer (or round-robin DNS with multiple A records) sits behind the name. Kubernetes' default Service discovery works exactly this way — `order-service` resolves via cluster DNS to a stable virtual IP, and kube-proxy (not your app) handles routing to a real pod behind it.

The appeal is that literally every language and tool already knows how to do a DNS lookup — zero client libraries needed. The limitation is that DNS wasn't designed for frequent, rapid membership changes or rich health-check semantics; it works well when something else (a platform load balancer) is doing the real health-aware routing behind that stable name, and less well as a _direct_ client-side discovery mechanism for fast-changing instance sets.

## Where this leaves Eureka, and what else is out there

Eureka is: self-registration + client-side discovery + heartbeat-based health checks. That's one specific, coherent set of choices — not the only correct one. Two names worth recognizing, not learning in depth yet:

- **Consul** — a registry with built-in active health checking and, unlike Eureka, doubles as a general key-value store and can do DNS-based discovery as an alternative to its HTTP API.
- **Zookeeper** — older, strongly-consistent coordination service that can back service discovery but is a lower-level building block (distributed locks, leader election) that discovery is just one use of, not a discovery tool purpose-built the way Eureka is.

The reason to know these exist isn't to pick between them right now — it's so that when a production system description says "we use Consul for discovery" or "we rely on Kubernetes Service discovery," you can immediately place it on the same three-part framework (registry / registration / discovery) you just learned, instead of treating it as an unrelated new topic.

[[Spring Framework]]
