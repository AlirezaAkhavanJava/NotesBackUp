You've already implemented client-side load balancing concretely with Spring Cloud LoadBalancer, and you named the client-side/server-side split briefly back in Service Discovery Fundamentals. This lesson is the piece in between those two: the general architectural pattern itself — the actual algorithms a load balancer can run, independent of any one framework, and the trade-off that makes "client-side" a real design decision rather than just "the way Spring happens to do it."

## The core architectural claim, restated precisely

Client-side load balancing means: the calling service holds the list of candidate addresses and decides which one to hit, with no intermediary network hop in between. The alternative — server-side — means every call goes to one fixed address first (a proxy, an ELB, a Kubernetes Service), and _that_ component holds the list and does the picking. The distinction is about **where the decision-making logic physically runs**, not about which service initiates the call (both are "the client calling the server" in the everyday sense).

```
Client-side:
  caller → [picks instance itself from a list it holds] → target instance
  (one network hop)

Server-side:
  caller → fixed load balancer address → [LB picks instance] → target instance
  (two network hops — caller to LB, LB to target)
```

That one-hop-vs-two-hop difference is the single biggest practical consequence: client-side avoids a network round trip through an intermediary, at the cost of every caller needing its own up-to-date view of who's available.

## The algorithms, independent of any framework

Spring Cloud LoadBalancer ships round-robin and random, which you've already used. The broader algorithm space a client-side balancer can implement:

**Round robin** — cycle through the list in fixed order: instance 1, 2, 3, 1, 2, 3... Simple, and fair in the specific sense of "equal call count per instance," but blind to whether instances are actually equally capable of handling load right now.

**Weighted round robin** — same cycling, but instances get proportionally more turns based on an assigned weight (a bigger VM gets weight 3, a smaller one gets weight 1). Fixes the "equal count is wrong when instances aren't equal" problem, but the weights are usually set once, manually, not computed from live conditions.

**Least connections** — route to whichever instance currently has the fewest in-flight requests from this caller. This adapts to the fact that not all requests take the same time to process — an instance stuck on three slow requests looks busier than one that just finished two fast ones, and this algorithm actually notices that, where round robin doesn't.

**Least response time** — go further than counting connections: track each instance's recent average latency and prefer the fastest-responding one. More adaptive than least-connections, at the cost of needing to actually measure and maintain that latency data per instance.

**Consistent hashing** — derive the target instance from a hash of something about the request (a user ID, a session key) rather than load conditions at all, so the _same_ key reliably lands on the _same_ instance call after call. This isn't about balancing load evenly — it's for when you need request affinity (routing a given user consistently to one instance, useful for in-memory caching per instance) despite the instance list changing over time.

**Power of two random choices** — pick two instances at random, then route to whichever of those two currently has less load. This sounds like an odd compromise, but it's a well-known result in load-balancing theory: checking just two candidates instead of all of them gets you most of the benefit of "always pick the least-loaded instance" with a fraction of the coordination overhead that a true global least-connections view requires across many callers.

Spring Cloud's `ServiceInstanceListSupplier`/algorithm split you've already seen is exactly built so any of these can be plugged in as a custom bean — the framework gives you round-robin and random out of the box, and the architecture openly expects you to supply something smarter for cases that need it.

## Why "client-side" is a genuine trade-off, not a free upgrade

**The case for it**: one fewer network hop means lower latency on every call, and it removes a potential single point of failure — there's no central load balancer that, if it goes down, takes every service's traffic with it. The decision-making also has richer information available (the caller can know about its own recent failures against a specific instance, for instance) than a generic proxy sitting in front of everything would.

**The cost**: every single service needs the load-balancing logic — and the discovery-client logic feeding it — built into it. In a single-language shop (everything's Java/Spring) this is one shared library dependency, which is exactly why Spring Cloud LoadBalancer feels "free" to you. In a polyglot shop (some services in Java, some in Go, some in Python), each language needs its own equivalent library, independently kept correct and in sync — the logic isn't shared, it's _duplicated_ across language ecosystems. Server-side load balancing sidesteps this entirely: the proxy doesn't care what language called it, so the balancing logic exists exactly once, regardless of how many languages are in play.

## The resolution the industry landed on: sidecar proxies / service mesh

This is worth knowing about even briefly, because it's the direct answer to the polyglot problem above, and it's where a lot of real production systems have moved. Instead of baking load-balancing logic into each application (client-side, the Spring Cloud way) or routing every call through one shared, central proxy (server-side, the classic way), a **service mesh** gives every instance its own _local_ proxy — a sidecar, typically Envoy — running alongside it. The application still only knows "call `order-service`"; the sidecar next to it does the actual discovery lookup and instance-picking, in a separate process, in whatever language the mesh is written in, not the application's.

```
Without mesh (client-side, your Spring stack):
  checkout-service [app code: DiscoveryClient + LoadBalancer] → order-service instance

With service mesh (e.g. Istio/Envoy):
  checkout-service [app code: just "call order-service"]
        → checkout-service's own sidecar [does discovery + balancing]
              → order-service instance's sidecar → order-service instance
```

This gets you the client-side benefit (still no detour through one shared central proxy for the whole system; each call's balancing decision happens right next to the caller) without the polyglot duplication cost, because the sidecar is the same binary regardless of what language the application next to it is written in. The cost moves elsewhere — you're now running and operating an extra process per instance, and the architecture gets a new moving part (the mesh's control plane) that configures all those sidecars consistently. Names worth recognizing if this comes up again: **Istio** and **Linkerd** are the common service mesh control planes, almost always built on **Envoy** as the actual sidecar proxy.

[[Spring Framework]]
