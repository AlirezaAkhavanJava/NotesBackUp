

A **switch** is a network device that connects multiple devices within a **local area network (LAN)** and forwards data only to the device that needs it, based on **MAC addresses**.

It is the central connecting device in most wired Ethernet networks.

---

## Where it fits in the models

| Model | Layer |
|---|---|
| OSI | **Layer 2 — Data Link** (traditional switch) |
| OSI | Layer 3 — Network (Layer 3 / multilayer switch) |
| TCP/IP | **Network Access / Link layer** |
| TCP/IP | Internet layer (Layer 3 switch) |

A standard switch is a **Layer 2 device**.  
A **Layer 3 switch** can also route packets using IP addresses.

---

## How a switch works

A switch keeps a **MAC address table** (also called a CAM table). It learns which device is on which port.

### Step by step

1. A frame arrives on a port.
2. The switch reads the **source MAC address** and records:  
   “This MAC is on this port.”
3. It reads the **destination MAC address**.
4. It looks up the destination MAC in its table.
5. It forwards the frame **only out the correct port**.
6. If the destination is unknown, it **floods** the frame to all ports except the one it came from.
7. Broadcast frames are also flooded.

---

## Simple diagram

```
        PC 1
         |
         |
PC 2 ----+---- SWITCH ---- Router ---- Internet
         |
         |
        PC 3

Switch MAC table:
  MAC AA:AA:AA:AA:AA:AA  -> Port 1  (PC 1)
  MAC BB:BB:BB:BB:BB:BB  -> Port 2  (PC 2)
  MAC CC:CC:CC:CC:CC:CC  -> Port 3  (PC 3)

Frame from PC 1 to PC 2:
  In:  Port 1
  Out: Port 2 only
```

PC 3 does **not** receive the frame. This is the key difference from a hub.

---

## Switch vs Hub vs Router

| Device | Layer | Forwarding based on | Sends data to |
|---|---|---|---|
| **Hub** | Layer 1 | Nothing — repeats electrically | All ports |
| **Switch** | Layer 2 | MAC address | Only the correct port |
| **Router** | Layer 3 | IP address | Next network toward destination |

- **Hub:** one device talks, everyone hears. Causes collisions.
- **Switch:** one device talks, only the target hears. Full-duplex, no collisions.
- **Router:** connects different networks, like your LAN to the internet.

---

## Key features of a switch

- **MAC address learning** — automatically builds its table.
- **Dedicated bandwidth per port** — each port gets full speed.
- **Full-duplex** — can send and receive at the same time.
- **Collision domains** — each port is its own collision domain.
- **VLAN support** — can logically separate networks on one physical switch.
- **Spanning Tree Protocol (STP)** — prevents loops.
- **Port mirroring** — copy traffic for monitoring.
- **QoS** — prioritize certain traffic.
- **PoE** — Power over Ethernet, powers devices like IP phones and cameras.

---

## Types of switches

| Type | Description |
|---|---|
| **Unmanaged** | Plug and play. No configuration. Home/small office. |
| **Managed** | Configurable: VLANs, STP, SNMP, QoS, port mirroring. Enterprise. |
| **Smart / Web-managed** | Limited management, cheaper than fully managed. |
| **Layer 3 / Multilayer** | Can route between VLANs and networks using IP. |
| **PoE** | Provides power over Ethernet cable. |
| **Stackable** | Multiple switches managed as one logical unit. |
| **Modular** | Chassis-based, expandable with cards. |
| **Fixed** | Fixed number of ports. |

---

## Why switches matter

Without switches, modern networks would be slow and chaotic:

- They **reduce unnecessary traffic** by forwarding only to the target.
- They **increase performance** with dedicated bandwidth per device.
- They **enable VLANs**, separating departments or guest networks.
- They **support full-duplex**, eliminating collisions.
- They are the **building blocks of LANs**, just as routers are the building blocks of the internet.

---

## In one sentence

> A **switch** is a Layer 2 network device that connects devices in a LAN and intelligently forwards frames to the correct port using MAC addresses, rather than broadcasting to everyone like a hub.


[[Networking]]