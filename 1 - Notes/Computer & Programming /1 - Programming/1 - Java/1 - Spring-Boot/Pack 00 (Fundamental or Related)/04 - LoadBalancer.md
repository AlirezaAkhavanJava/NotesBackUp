
A **load balancer** is the piece of infrastructure that sits in front of a group of servers and decides, for each incoming request, which one of those servers should actually handle it. From the client's point of view, there's just one address to talk to — the load balancer's — and it never sees or cares which of the backend servers responded. This is exactly the piece that made the "load-balancing cluster" from before actually work: the cluster is the group of interchangeable nodes, and the load balancer is the component that spreads traffic across them and hides individual node failures from the outside world.

### The problem it exists to solve

If every client talked directly to one specific server, you'd be back to a single point of failure and a single capacity ceiling — exactly what clustering was meant to avoid. You need something standing between the clients and the pool of servers that can (a) spread requests out so no one server gets overwhelmed, and (b) notice when a server is down and simply stop sending it traffic. That "something" is the load balancer.

```
                 requests
Client ──────────────────────► Load Balancer
                                     │
                     ┌───────────────┼───────────────┐
                     ▼               ▼               ▼
                 Server A        Server B        Server C
```

### How it decides where to send a request

A load balancer needs an algorithm to pick a target. Some common ones:

- **Round robin** — requests go to servers in rotating order: A, then B, then C, then back to A. Simple, works well when servers are roughly equal in power and requests are roughly equal in cost.
- **Least connections** — send the next request to whichever server currently has the fewest active connections. Better when some requests take much longer than others, since round robin can pile slow requests onto one unlucky server.
- **IP hash** — the client's IP address is hashed to consistently map it to the same backend server. Useful when you need a given client to keep landing on the same server (this is one way to handle **session affinity**, also called **sticky sessions**).
- **Weighted variants** of the above — if Server A is twice as powerful as Server B, you give it double the weight so it receives roughly twice the traffic.

### How it knows a server is down

A load balancer continuously runs **health checks** — small periodic requests (e.g. hitting a `/health` or `/actuator/health` endpoint in a Spring Boot app) to each backend server. If a server stops responding correctly, the load balancer marks it as unhealthy and stops routing traffic to it, without any manual intervention. Once the server starts responding normally again, it gets added back into rotation. This is the mechanism that actually delivers on the "cluster survives node failure" promise — the load balancer is what notices the failure and routes around it in real time.

### Layer 4 vs. Layer 7 load balancing

This distinction trips a lot of people up, so it's worth being precise:

- **Layer 4 (transport layer)** — the load balancer only looks at IP addresses and TCP/UDP ports. It forwards raw packets without understanding what's inside them (no idea if it's HTTP, a database protocol, etc.). Fast and simple, but can't make decisions based on request content.
- **Layer 7 (application layer)** — the load balancer actually understands HTTP. It can read the request path, headers, or cookies, and route based on that — for example, sending `/api/*` requests to one group of servers and `/static/*` requests to another, or routing based on a session cookie for sticky sessions. Slower than Layer 4 since it has to parse the request, but far more flexible.

Nginx and HAProxy are common software load balancers that can operate at either layer depending on configuration; cloud providers also offer managed versions (AWS has both an Application Load Balancer for Layer 7 and a Network Load Balancer for Layer 4).

### Where it sits relative to the rest of the stack

Put next to the cluster picture from before: the load balancer is the thing a client talks to; it decides which node in the cluster actually handles that one request. It doesn't replicate data, doesn't elect leaders, doesn't manage consensus — that's the job of the clustering layer underneath it (for stateless app servers there's nothing to coordinate; for a database cluster, the load balancer is usually only in front of read replicas, while writes still route specifically to the primary node, since that's a decision the load balancer itself doesn't understand).


[[Spring Framework]]