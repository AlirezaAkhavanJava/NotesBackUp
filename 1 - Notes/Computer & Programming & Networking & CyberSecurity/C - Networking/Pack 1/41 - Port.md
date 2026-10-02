

A **port** is a **16-bit number used to identify a specific network service or application on a device**.

In simple terms:

> **An IP address identifies the machine; a port identifies the service/application on that machine.**

### Example

Suppose your computer has:

```text
IP:   192.168.1.10
Port: 8080
```

A connection to:

```text
192.168.1.10:8080
```

means:

> "Connect to the service listening on port `8080` on this machine."

### Why do we need ports?

One computer can run many networked applications simultaneously:

```text
192.168.1.10
│
├── :22    SSH
├── :80    HTTP
├── :443   HTTPS
├── :5432  PostgreSQL
└── :8080  Spring Boot application
```

The **IP address** gets the packet to the computer.

The **port number** gets it to the appropriate network endpoint/process.

### Port range

A port is an unsigned 16-bit number:

```text
0 ─────────────────────────────── 65535
```

Common categories:

```text
0–1023       Well-known ports
1024–49151   Registered ports
49152–65535  Dynamic/ephemeral ports
```

Examples:

```text
22    → SSH
53    → DNS
80    → HTTP
443   → HTTPS
5432  → PostgreSQL
```

### Important distinction

A **port is not a physical socket or connector** on your computer.

This:

```text
192.168.1.10:8080
```

is a **logical network endpoint**.

In TCP/UDP networking, an endpoint is generally identified by:

```text
IP address + port + transport protocol
```

For example:

```text
TCP 192.168.1.10:8080
```

is different from:

```text
UDP 192.168.1.10:8080
```

Even though both use port `8080`.

[[Networking]]