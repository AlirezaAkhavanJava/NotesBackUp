

This is the next major step in the same historical chain. The important thing is **why the architecture had to change**.

We went from:

```text
One website
   ↓
One server
```

to:

```text
Millions of users
   ↓
One server
   ↓
PROBLEM
```

and eventually to:

```text
Millions of users
       ↓
Load balancers
       ↓
Many application servers
       ↓
Caches / databases / storage / queues
       ↓
Multiple data centers
```

---

# 1. Before cloud computing: you owned the server

In the early Web, a company might have:

```text
Internet
   │
   ↓
[Company Server]
   │
   ↓
[Database]
```

If your website became popular:

```text
10 users
   ↓
server works

10,000 users
   ↓
server struggles

1,000,000 users
   ↓
server dies
```

You had to physically buy:

- servers
    
- CPUs
    
- RAM
    
- hard drives
    
- networking equipment
    
- racks
    
- cooling
    
- electricity
    
- backup systems
    

And someone had to operate all of it.

---

# 2. Scaling became the problem

Suppose you have one Spring Boot server:

```text
                    ┌──────────────┐
Users ─────────────→│ Spring Boot  │
                    │   Server     │
                    └──────────────┘
                           │
                           ↓
                       PostgreSQL
```

Now you have 100,000 concurrent users.

You can't simply keep making one machine infinitely powerful.

This leads to two forms of scaling.

### Vertical scaling

Make one machine bigger:

```text
4 CPU / 16 GB RAM
        ↓
16 CPU / 64 GB RAM
        ↓
64 CPU / 256 GB RAM
```

Also called **scale up**.

Problem:

> A single machine has physical limits and becomes expensive.

---

# 3. Horizontal scaling

Instead:

```text
             ┌── Server 1
Users ───────┼── Server 2
             ├── Server 3
             └── Server 4
```

This is **horizontal scaling** or **scale out**.

Now if traffic increases:

```text
4 servers
   ↓
10 servers
   ↓
100 servers
```

This became fundamental to large Internet services.

---

# 4. But now another problem appears

How does the user know which server to connect to?

You introduce a **load balancer**.

```text
                   ┌── Server 1
                   │
Users ──→ Load ────┼── Server 2
         Balancer  │
                   └── Server 3
```

The load balancer distributes requests.

For example:

```text
Request 1 → Server 1
Request 2 → Server 2
Request 3 → Server 3
Request 4 → Server 1
```

Now the application can scale horizontally.

---

# 5. But the Internet is global

Imagine you're in Iran and the server is in California.

```text
You
 │
 │ thousands of kilometers
 ↓
California server
```

Even if the server is extremely powerful, network distance creates:

- latency
    
- slower downloads
    
- expensive bandwidth
    
- congestion
    

And large files make this worse.

Suppose you upload a 500 MB video.

Every user downloading it from one server is expensive.

This leads to another technology:

# CDN

**CDN = Content Delivery Network**

A CDN places copies of content at geographically distributed **edge locations**.

Instead of:

```text
                  California
                     │
Users worldwide ─────┤
                     │
                  Server
```

you get:

```text
                 Origin Server
                     │
          ┌──────────┼──────────┐
          ↓          ↓          ↓
       CDN Edge   CDN Edge   CDN Edge
       New York   London     Tokyo
          ↑          ↑          ↑
        Users      Users      Users
```

A user gets content from a nearby edge.

---

# 6. What does a CDN actually cache?

Common examples:

```text
Images
CSS
JavaScript
Videos
Fonts
Downloads
Static HTML
```

For example:

```text
GET /images/avatar.jpg
```

Instead of reaching your Spring Boot server every time:

```text
User
 ↓
CDN
 ↓
cached image
```

Your backend doesn't need to process every request.

---

# 7. Why CDNs became extremely important

Consider YouTube.

You don't want:

```text
1 billion users
      ↓
one YouTube server
      ↓
video
```

Instead:

```text
                  YouTube Origin
                        │
                        ↓
                    CDN network
              ┌─────────┼─────────┐
              ↓         ↓         ↓
           America    Europe     Asia
              ↓         ↓         ↓
           users      users      users
```

This is how the Internet became capable of delivering enormous amounts of media.

---

# 8. Cloud computing

Now we reach **cloud computing**.

Cloud computing essentially changed:

> "I need to own physical computers."

into:

> "I need computing resources; someone else can provide them on demand."

Major cloud providers include:

- Amazon Web Services
    
- Microsoft Azure
    
- Google Cloud
    

Amazon Web Services  
Microsoft Azure  
Google Cloud

---

# 9. What does "cloud" actually mean?

The cloud isn't magic.

It's basically:

```text
Someone else's
massive collection of
physical computers
+
networking
+
storage
+
virtualization
+
automation
+
data centers
```

When you create a cloud VM:

```text
Your application
       ↓
Cloud API
       ↓
Physical infrastructure
       ↓
Virtual machine
       ↓
Your Linux server
```

You don't need to physically own the machine.

---

# 10. Virtualization

Virtualization was extremely important.

One physical machine:

```text
┌──────────────────────────────┐
│ Physical Server              │
│                              │
│ ┌────────┐ ┌────────┐       │
│ │ VM 1   │ │ VM 2   │ ...   │
│ │ Linux  │ │ Linux  │       │
│ └────────┘ └────────┘       │
└──────────────────────────────┘
```

A hypervisor manages the virtual machines.

This allows infrastructure providers to efficiently share physical hardware.

---

# 11. Infrastructure became programmable

This is one of the biggest changes.

Old world:

```text
Buy server
 ↓
Install OS
 ↓
Configure manually
 ↓
Deploy application
```

Cloud:

```text
API
 ↓
Create server
 ↓
Configure network
 ↓
Attach storage
 ↓
Deploy application
```

Infrastructure became something software could control.

This eventually led to:

**Infrastructure as Code**

and technologies such as:

- Terraform
    
- Kubernetes
    
- Docker
    
- Ansible
    

---

# 12. Databases became a distributed-systems problem

Now suppose your Spring Boot application has:

```text
Server 1 ──┐
Server 2 ──┤
Server 3 ──┤──→ PostgreSQL
Server 4 ──┘
```

Suddenly you need to think about:

- concurrent requests
    
- transactions
    
- connection pools
    
- replication
    
- backups
    
- consistency
    
- failover
    
- locking
    

And when one database isn't enough:

```text
Primary
   │
   ├── Replica 1
   ├── Replica 2
   └── Replica 3
```

Now you're entering **distributed systems**.

---

# 13. Caching

Another problem:

Suppose 1 million users request:

```http
GET /api/products/42
```

Why query PostgreSQL one million times if the result rarely changes?

Introduce a cache:

```text
Browser
   ↓
Backend
   ↓
Redis
   │
   ├── HIT → return data
   │
   └── MISS
          ↓
       PostgreSQL
```

This is why technologies such as Redis became important.

---

# 14. Message queues

Now imagine a user uploads a video.

You don't necessarily want the HTTP request to sit there waiting while your backend:

```text
upload
 ↓
convert video
 ↓
generate thumbnails
 ↓
analyze video
 ↓
notify users
```

Instead:

```text
User
 ↓
Backend
 ↓
Message Queue
 ↓
Worker
 ↓
process video
```

The request can finish quickly.

Technologies such as Kafka and RabbitMQ became important for these kinds of architectures.

---

# 15. Microservices

As companies became extremely large, one giant application could become difficult to manage.

Instead:

```text
                 API Gateway
                     │
       ┌─────────────┼─────────────┐
       ↓             ↓             ↓
   User Service  Order Service Payment Service
       │             │             │
       ↓             ↓             ↓
    Database      Database      Database
```

Each service can potentially:

- deploy independently
    
- scale independently
    
- fail independently
    
- have its own data/storage
    

This is the **microservices architecture**.

Important:

> Microservices did not appear simply because they were "better."

They emerged partly because organizations were dealing with enormous systems and teams.

They also introduce significant complexity.

---

# 16. Containers

Then came **Docker** and containerization.

Instead of:

```text
Server
 ├── manually configured Java
 ├── manually configured dependencies
 └── manually configured application
```

you can package the application and its environment:

```text
┌─────────────────────────┐
│ Docker Container        │
│                         │
│ Spring Boot application │
│ Java runtime            │
│ dependencies            │
└─────────────────────────┘
```

Then run it consistently across environments.

---

# 17. Kubernetes

Once you have:

```text
100 containers
```

you don't want to manually manage them.

Kubernetes automates things such as:

```text
deploy
restart
scale
schedule
network
service discovery
```

Conceptually:

```text
Kubernetes Cluster

        ┌───────────────┐
        │ Control Plane │
        └───────┬───────┘
                │
       ┌────────┼────────┐
       ↓        ↓        ↓
     Node     Node      Node
      │         │        │
   Pod Pod    Pod Pod   Pod Pod
```

---

# 18. The architecture today

A large modern application might look like:

```text
                         USERS
                           │
                           ↓
                      DNS / CDN
                           │
                           ↓
                    Load Balancer
                           │
                           ↓
                    API Gateway
                           │
             ┌─────────────┼─────────────┐
             ↓             ↓             ↓
        User Service   Task Service   Auth Service
             │             │             │
             ↓             ↓             ↓
          Database      Database      Database
             │
             └──────────┬──────────────┘
                        ↓
                     Cache
                        │
                        ↓
                    Message Bus
                        │
             ┌──────────┼──────────┐
             ↓          ↓          ↓
          Worker     Worker     Worker
```

And surrounding all of this:

```text
Monitoring
Logging
Metrics
Tracing
Security
Backups
CI/CD
```

---

# 19. Why did all this happen?

This is the most important part.

Every architectural layer appeared because something became a bottleneck:

```text
Static Web
    ↓
Need interaction
    ↓
JavaScript / AJAX
    ↓
Need structured data
    ↓
JSON / APIs
    ↓
Need scalable applications
    ↓
Backend services
    ↓
Need millions of users
    ↓
Load balancing
    ↓
Need global delivery
    ↓
CDNs
    ↓
Need flexible infrastructure
    ↓
Cloud
    ↓
Need independent scaling
    ↓
Distributed systems
    ↓
Need manageable deployment
    ↓
Containers
    ↓
Need orchestration
    ↓
Kubernetes
```

So **modern backend engineering is basically the result of decades of problems accumulating and being solved one layer at a time.**

And that brings us to where your Java/Spring work sits:

```text
Internet
   ↓
HTTP
   ↓
DNS
   ↓
CDN / Load Balancer
   ↓
Spring Boot
   ↓
REST API
   ↓
Service Layer
   ↓
Repository / JPA
   ↓
PostgreSQL
```

You are learning the **application layer of a system whose architecture evolved from all of those historical problems**.

[[Networking]]