
A **cluster** is a group of separate machines (or processes) that are connected together and coordinated so that, from the outside, they behave like a single, more capable system. **Clustering** is the practice — and the set of techniques — used to make that group work together: distributing load across the members, keeping them in sync, detecting when one fails, and recovering without the whole system going down. The core motivation is always one (or both) of two things: you need more capacity than a single machine can give you (scaling), or you need the system to keep running even if one machine dies (availability).

### Why a single machine isn't enough

A single server has a ceiling: a fixed amount of CPU, memory, and disk I/O. Once your workload exceeds that, you have two choices — make the machine bigger (**vertical scaling**, i.e. buy a beefier server), or add more machines and split the work between them (**horizontal scaling**, i.e. clustering). Vertical scaling hits physical and cost limits fast; horizontal scaling, in principle, lets you keep adding machines indefinitely. Clustering is the mechanism that makes horizontal scaling actually usable — it's what turns "five separate computers" into "one logical service."

A single machine also has a failure mode: if it crashes, the service is down until someone fixes it. A cluster solves this by having multiple nodes capable of doing the same job, so if one goes down, the others pick up the slack — this is **high availability**.

### The two main flavors of clustering

**1. Load-balancing / stateless clustering** — Multiple nodes run the same application, and requests are spread across them (usually by a load balancer sitting in front). Each node can handle any request independently, so if one node dies, the load balancer just stops sending traffic to it. This is the simplest form of clustering and is how most web application servers scale — e.g. running five identical instances of a Spring Boot app behind an Nginx or cloud load balancer. There's no real "state" to coordinate between nodes here; each one is interchangeable.

**2. Data / stateful clustering** — This is harder, because the nodes hold _data_, and that data has to stay consistent across all of them. Databases and caches use this kind of clustering:

```
          ┌─────────────┐
          │   Client     │
          └──────┬───────┘
                 │
         ┌───────▼────────┐
         │  Load Balancer  │
         └───┬────────┬────┘
             │        │
      ┌──────▼──┐  ┌──▼───────┐
      │ Node A  │  │ Node B   │
      │(Primary)│◄─┤(Replica) │
      └─────────┘  └──────────┘
```

Here, writes typically go to one node (the **primary**/**leader**), and that node replicates the data to the others (**replicas**/**followers**). If the primary fails, one of the replicas is promoted to take over — this process is called **failover**. PostgreSQL, Redis, and most production databases support this kind of clustering, usually called **replication** when it's about copying data, and **sharding** when it's about splitting data across nodes instead of copying it (each node holds a different slice of the total dataset, which is how you scale storage and write throughput beyond what one machine could hold).

### The hard part: keeping nodes in agreement

The moment you have more than one node holding state, you run into a genuinely hard problem: how do the nodes agree on what the "true" current state is, especially when nodes can crash or network connections between them can drop? This is the domain of **distributed consensus**. A cluster needs to agree on things like "who is the current leader" — this is usually solved with algorithms like **Raft** or **Paxos**, or tools built on them like **ZooKeeper** or **etcd**. You'll see this under the hood in things like Kafka (which elects partition leaders) or Kubernetes (which uses etcd to keep the whole cluster's state consistent).

### Clustering shows up at different layers

- **Application cluster** — multiple instances of your app (e.g. several Spring Boot JARs) behind a load balancer.
- **Database cluster** — multiple database nodes replicating or sharding data (e.g. a PostgreSQL primary-replica setup).
- **Cache cluster** — e.g. Redis Cluster, which shards keys across nodes using hash slots so no single node has to hold the entire cache.
- **Orchestration cluster** — Kubernetes itself is a cluster of machines (nodes) that cooperatively run and schedule containers across themselves.

### A quick related concept: cluster vs. "pool"

It's worth distinguishing a cluster from a **connection pool**, since the terms get used near each other and can blur together. A connection pool (like HikariCP) is a set of _reusable connections to one target_ held by a single application instance — it's about efficiency, not failover or distribution. A cluster is a set of _independent nodes_, each capable of doing real work on their own, coordinated for scale or resilience. You can absolutely have a connection pool _inside_ an app that is itself one node of a cluster — they operate at different layers entirely and solve different problems.



[[Spring Framework]]