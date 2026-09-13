# MAN (Metropolitan Area Network)

## Definition

![[Pasted image 20260911194408.png]]

A **MAN** (Metropolitan Area Network) is a network that spans a **city or a large metropolitan area** — larger than a LAN but smaller than a WAN. It typically covers a range of **5 km to 100 km** and connects multiple LANs within the same city or region.

A common example is a **city-wide cable TV network** or a **campus network spanning multiple buildings across a city**.

---

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Geographic scope** | City or metropolitan area (5–100 km) |
| **Speed** | High — faster than WAN, slower than LAN (typically 10 Mbps – 10 Gbps) |
| **Ownership** | Usually a single entity (city, ISP, large organization) or consortium |
| **Cost** | Moderate — between LAN and WAN |
| **Hardware** | Routers, switches, fiber optic cables, microwave links |
| **Technologies** | Fiber (Metro Ethernet), WiMAX, DSL, Cable, MPLS |
| **Purpose** | Connect multiple LANs across a city |

---

## Difference: LAN vs MAN vs WAN

| Aspect | **LAN** | **MAN** | **WAN** |
|--------|---------|---------|---------|
| **Full form** | Local Area Network | Metropolitan Area Network | Wide Area Network |
| **Coverage** | Building / campus (up to ~1 km) | City / metro (5–100 km) | Country / global (100+ km) |
| **Speed** | Very high (1–100 Gbps) | High (10 Mbps – 10 Gbps) | Lower (1 Mbps – 10 Gbps) |
| **Latency** | Very low (<1 ms) | Low (1–10 ms) | High (10–500+ ms) |
| **Ownership** | Private (single person/org) | Single org or consortium | Multiple carriers / public |
| **Cost** | Low | Moderate | High |
| **Setup** | Easy | Moderate | Complex |
| **Error rate** | Very low | Low | Higher |
| **Example** | Home Wi-Fi, office LAN | City cable TV, metro Ethernet, campus across city | The Internet, bank ATM network |

---

## What Problem Does MAN Solve?

LANs can connect devices in one building, but a city has many buildings that need to communicate.

**MAN solves:**
1. **City-wide connectivity** — connects offices, schools, and government buildings across a city
2. **High-speed backbone** — provides fast links between LANs within the metro area
3. **Shared public services** — city Wi-Fi, traffic cameras, emergency services
4. **ISP infrastructure** — connects subscribers across a city to the internet backbone
5. **Cost-effective middle ground** — cheaper than building a WAN, faster than routing over the public internet

**Example problems solved:**
- A university with 5 campuses across a city → **MAN**
- A city government connecting all its departments → **MAN**
- A cable ISP delivering TV/internet to homes in one city → **MAN**

---

## Illustrations

### 1. LAN vs MAN vs WAN Scope

```
   PAN          LAN              MAN                WAN
  (1–10 m)   (10 m–1 km)      (5–100 km)        (100 km – global)

   📱🔵        🏠🏢              🏙️                  🌍
 Bluetooth   Home/Office       City              Internet
```

---

### 2. MAN Connecting Multiple LANs in a City

```
   ┌──────────────────────── CITY (MAN) ────────────────────────┐
   │                                                            │
   │   ┌─────────┐      ┌─────────┐      ┌─────────┐            │
   │   │ LAN –   │      │ LAN –   │      │ LAN –   │            │
   │   │ Bank HQ │      │ Univ    │      │ Hospital│            │
   │   └────┬────┘      └────┬────┘      └────┬────┘            │
   │        │                │                │                 │
   │        └────── Metro Ethernet / Fiber ───┘                 │
   │                       │                                    │
   │                 ┌─────┴─────┐                              │
   │                 │  MAN Core │─────► Internet (WAN)         │
   │                 └───────────┘                              │
   └────────────────────────────────────────────────────────────┘
```

---

### 3. Hierarchy: LAN → MAN → WAN

```
        ┌──────────────────────── WAN (Global) ────────────────────────┐
        │                                                               │
        │   ┌──────────── MAN (City A) ───────────┐                     │
        │   │  ┌── LAN ──┐   ┌── LAN ──┐          │                     │
        │   │  │ Office  │   │ School  │          │                     │
        │   │  └─────────┘   └─────────┘          │                     │
        │   └──────────────────────────────────────┘                    │
        │                                                               │
        │   ┌──────────── MAN (City B) ───────────┐                     │
        │   │  ┌── LAN ──┐   ┌── LAN ──┐          │                     │
        │   │  │ Office  │   │ Data Ctr│          │                     │
        │   │  └─────────┘   └─────────┘          │                     │
        │   └──────────────────────────────────────┘                    │
        └───────────────────────────────────────────────────────────────┘
```

---

### 4. Real-World Example: City Cable Network (MAN)

```
        Homes (LANs)              City MAN                Internet
        ┌────────┐
        │ Home 1 │──┐
        └────────┘  │
        ┌────────┐  │    ┌──────────────┐      ┌──────────┐
        │ Home 2 │──┼───►│  Cable ISP   │─────►│ Internet │
        └────────┘  │    │  Head-End    │      │  (WAN)   │
        ┌────────┐  │    │  (MAN Core)  │      └──────────┘
        │ Home 3 │──┘    └──────────────┘
        └────────┘
```

---

## Summary

- **MAN** = city-sized network connecting many LANs.
- **Sits between LAN and WAN** in scope, speed, and cost.
- **Purpose** = provide high-speed connectivity across a city for organizations, ISPs, and public services.
- **Common tech** = Metro Ethernet, fiber optics, WiMAX, cable.
- **Examples** = city cable TV/internet, university campus across a city, government metro network.


[[Networking]]