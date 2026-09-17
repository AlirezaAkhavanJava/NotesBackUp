

**Localhost** means **the computer you are currently using** when referring to network communication.

In networking, localhost is represented by the hostname:

```text
localhost
```

and normally resolves to the loopback IP address:

```text
127.0.0.1    → IPv4
::1          → IPv6
```

### The important idea

If your computer runs a server:

```text
Your computer
┌──────────────────────────────┐
│                              │
│  Spring Boot                 │
│  └── Server :8080            │
│                              │
└──────────────────────────────┘
```

You can access it using:

```text
http://localhost:8080
```

This means:

> "Connect to port 8080 on **this same computer**."

It does **not** mean your router, another PC, or the Internet.

### `localhost` vs `127.0.0.1`

These normally refer to the same loopback interface:

|Address|Meaning|
|---|---|
|`localhost`|Hostname for your own machine|
|`127.0.0.1`|IPv4 loopback address|
|`::1`|IPv6 loopback address|
|`localhost:8080`|Your machine, port `8080`|

For example:

```bash
curl http://localhost:8080
```

is essentially asking your own machine:

```text
"Connect to my machine on TCP port 8080."
```

### Why is it called "loopback"?

Because the network traffic **loops back into the same machine** instead of going out through Ethernet/Wi-Fi:

```text
Application
     │
     ▼
localhost / 127.0.0.1
     │
     ▼
Network stack
     │
     └──────────────┐
                    │
                    ▼
              Same computer
```

Compare this with:

```text
192.168.1.10
```

which could be your machine's **LAN address**, reachable by other devices on your local network.

So the key distinction is:

```text
localhost       → this machine
192.168.x.x     → machine on the local network
public IP       → machine reachable through the Internet (subject to routing/firewall)
```

For backend development, you'll constantly see things like:

```text
localhost:8080   → Spring Boot
localhost:5432   → PostgreSQL
localhost:3000   → frontend/dev server
localhost:8081   → another application
```

**Mental model:** `localhost` = **"me, from the network's point of view."**


[[Networking]]