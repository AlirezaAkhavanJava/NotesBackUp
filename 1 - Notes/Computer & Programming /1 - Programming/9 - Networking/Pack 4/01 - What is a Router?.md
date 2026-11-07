


A **router** is a network device that **connects different IP networks and forwards packets between them**.

The key idea is:

> **A switch connects devices within a network. A router connects networks to other networks.**

For example:

```text
                 Network 1
        192.168.1.0/24
              │
        ┌─────┴─────┐
        │   Switch  │
        └─────┬─────┘
          PC  │
             │
        ┌────▼─────┐
        │  Router  │
        └────┬─────┘
             │
             │  Network 2
             │  203.x.x.x
             ▼
          Internet
```

### What does it actually do?

Suppose your PC wants to communicate with a server on another network:

```text
PC
192.168.1.10
    │
    │ IP packet
    ▼
Router
192.168.1.1
    │
    │ forwards packet
    ▼
Internet
    │
    ▼
Server
```

The router examines the packet's **destination IP address**:

```text
┌──────────────────────────────────────┐
│ Source IP      192.168.1.10          │
│ Destination IP 142.250.x.x            │
│ Data                                  │
└──────────────────────────────────────┘
```

It then asks:

> **"Which network should I send this packet toward?"**

It uses its **routing table** to make that decision.

For example:

```text
Destination       Next Hop        Interface
------------------------------------------------
192.168.1.0/24    directly        eth0
10.0.0.0/8        10.0.0.1        eth1
0.0.0.0/0         ISP router      eth2
```

The last entry is particularly important:

```text
0.0.0.0/0
```

means essentially:

> **If I don't have a more specific route, send it to this gateway.**

That's the **default route**.

---

## Router vs Switch

This distinction is fundamental:

||Switch|Router|
|---|---|---|
|Main job|Connect devices|Connect networks|
|Main address|MAC address|IP address|
|Data|Ethernet frame|IP packet|
|OSI layer|Layer 2|Layer 3|
|Typical scope|LAN|Between networks|
|Decision|Which port?|Which route?|

So:

```text
          Ethernet / LAN
               
PC ────── Switch ────── Router ────── Internet
          │                │
       MAC-based        IP-based
       forwarding       forwarding
```

### One important detail

Your **home Wi-Fi router** is usually several devices/functions combined into one box:

```text
             Home Router
┌──────────────────────────────────┐
│                                  │
│  Switch      Wi-Fi Access Point │
│  Router      DHCP Server         │
│  NAT         Firewall            │
│                                  │
└──────────────────────────────────┘
```

So when people say _"my router"_, they often mean an entire **networking appliance**, not just the routing function.

The core concept, however, is simple:

> **A router receives an IP packet, examines its destination IP, consults its routing table, and forwards the packet toward the appropriate network.**


[[Networking]]