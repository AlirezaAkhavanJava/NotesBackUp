![[Pasted image 20261007191610.png]]

A **switch** is a network device that connects multiple devices on the **same local network (LAN)** and forwards Ethernet frames to the correct device.

Think:

```text
PC A ──┐
PC B ──┤
PC C ──┼── [ SWITCH ] ── Router ── Internet
Server ─┤
Printer ─┘
```

### What does it actually do?

Suppose:

```text
PC A: 192.168.1.10
PC B: 192.168.1.20
```

PC A wants to send data to PC B.

The switch looks at the **destination MAC address** inside the Ethernet frame:

```text
Ethernet Frame
┌─────────────────────────────────────┐
│ Destination MAC │ Source MAC │ Data │
└─────────────────────────────────────┘
```

The switch maintains a **MAC address table**:

```text
MAC Address          Port
────────────────────────────
AA:AA:AA:AA:AA:AA    1
BB:BB:BB:BB:BB:BB    2
CC:CC:CC:CC:CC:CC    3
```

If PC B's MAC is on port 2, the switch sends the frame **only out port 2**.

That's the fundamental job of a switch:

> **Receive an Ethernet frame → examine its destination MAC → forward it through the appropriate port.**

### Why was a switch needed?

Older Ethernet networks commonly used **hubs**.

A hub essentially did:

```text
          ┌── PC A
          │
[ HUB ] ──┼── PC B
          │
          └── PC C
```

If A sent something to B, the hub repeated it to **everyone**.

A switch is smarter:

```text
A ──> [SWITCH] ──> B
                 X C
                 X D
```

Only the intended port receives the frame.

### Where does a switch operate?

Primarily at **OSI Layer 2 — Data Link**.

So:

```text
Application
Transport
Network       ← Router works here (IP)
Data Link     ← Switch works here (MAC/Ethernet)
Physical
```

A traditional Ethernet switch is therefore fundamentally a **Layer 2 device**.

Modern switches can also perform Layer 3 routing, but that's a more advanced type of switch.

### The important distinction

Don't confuse these:

```text
Switch  → MAC addresses → Ethernet frames → LAN
Router  → IP addresses  → IP packets      → between networks
```

For example:

```text
PC ── Switch ── Switch ── Router ── Internet
      LAN              │
                       └── moves traffic between networks
```

The **switch builds the local network**.  
The **router connects different networks**.


[[Networking]]