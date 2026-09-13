
# WAN (Wide Area Network)

## Definition

A **WAN** (Wide Area Network) is a telecommunications network that spans a **large geographic area** — such as a city, country, continent, or the entire globe. It connects multiple LANs together so devices can communicate across long distances.

The **internet itself is the largest WAN** in existence.

---

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Geographic scope** | Very large — cities, countries, continents, global |
| **Speed** | Generally slower than LAN (latency & bandwidth limited by distance) |
| **Ownership** | Usually owned by telecom carriers/ISPs (leased lines, fiber, satellites) |
| **Cost** | Expensive to build and maintain |
| **Hardware** | Routers, modems, MPLS switches, satellites, undersea cables |
| **Technologies** | MPLS, Leased Lines, DSL, Fiber, 4G/5G, Satellite, VPN |

---

## Difference Between LAN and WAN

| Aspect | **LAN** | **WAN** |
|--------|---------|---------|
| **Full form** | Local Area Network | Wide Area Network |
| **Coverage** | Single room/building/campus | City → Country → Global |
| **Speed** | Very high (1–100 Gbps) | Lower (1 Mbps – 10 Gbps, high latency) |
| **Latency** | Very low (sub-millisecond) | Higher (10 ms – 500+ ms) |
| **Ownership** | Private (you own it) | Usually public/leased from ISP |
| **Cost** | Low (cheap hardware) | High (leased lines, infrastructure) |
| **Setup** | Easy, do-it-yourself | Complex, requires ISP/carrier |
| **Error rate** | Low | Higher (long distance, many hops) |
| **Example** | Home Wi-Fi, office network | The Internet, bank ATM network, corporate WAN |
| **Media** | Ethernet, Wi-Fi | Fiber optics, satellites, MPLS, undersea cables |

---

## What Problem Does WAN Solve?

LANs only work **locally** — they can't connect a branch in London to a branch in Tokyo.

**WAN solves:**
1. **Long-distance communication** — connect offices in different cities/countries
2. **Resource sharing across locations** — central servers, databases, cloud apps
3. **Global connectivity** — email, websites, video calls across the world
4. **Centralized management** — one company, many locations, single network
5. **Access to the internet** — links your LAN to the global network

**Example problems solved:**
- A bank with branches across a country needs shared customer data → **WAN**
- Employees working from home need to reach office servers → **WAN (VPN over internet)**
- Two company offices 500 km apart need to share files → **WAN**

---

## Illustrations

### 1. Simple LAN vs WAN

```
        LAN (one building)                    WAN (many buildings/cities)
   ┌────────────────────┐              ┌──────────────┐   ┌──────────────┐
   │  PC ──┐            │              │  LAN London  │   │  LAN Tokyo   │
   │  PC ──┼── Switch    │              └──────┬───────┘   └──────┬───────┘
   │  PC ──┘            │                     │                  │
   │      Router        │                     └────── WAN ───────┘
   └────────┬───────────┘                   (fiber / satellite / MPLS)
            │
        Internet
```

---

### 2. LAN Inside a Company, WAN Connecting Branches

```
   ┌─────────────────────────── COMPANY WAN ───────────────────────────┐
   │                                                                    │
   │   ┌─────────────┐        ┌─────────────┐        ┌─────────────┐    │
   │   │  LAN – NY   │        │  LAN – LDN  │        │  LAN – TOK  │    │
   │   │  PCs + SW   │        │  PCs + SW   │        │  PCs + SW   │    │
   │   │   Router    │        │   Router    │        │   Router    │    │
   │   └──────┬──────┘        └──────┬──────┘        └──────┬──────┘    │
   │          │                      │                      │           │
   │          └──────── WAN links (MPLS / VPN) ────────────┘           │
   │                                                                    │
   └────────────────────────────────────────────────────────────────────┘
```

---

### 3. The Internet = The Biggest WAN

```
        Your Home LAN
        ┌──────────┐
        │ PC  Phone│
        │   Router │
        └────┬─────┘
             │  (ISP)
             ▼
   ┌─────────────────────────────────────────────────┐
   │              THE INTERNET (WAN)                 │
   │   ┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐         │
   │   │ ISP │───│ ISP │───│ ISP │───│ ISP │  ...    │
   │   └──┬──┘   └──┬──┘   └──┬──┘   └──┬──┘         │
   │      │         │         │         │            │
   │   undersea fiber, satellites, backbone routers  │
   └──────┬─────────┬─────────┬─────────┬────────────┘
          │         │         │         │
      Office LAN  Bank LAN  School LAN  Cloud LAN
```

---

### 4. Scope Comparison Diagram

```
   PAN          LAN              MAN               WAN
  (1–10 m)   (10 m–1 km)      (1–100 km)       (100 km – global)

   📱🔵        🏠🏢              🏙️                 🌍
 Bluetooth   Home/Office       City             Internet
```

---

## Summary

- **LAN** = small, fast, cheap, private — your home or office.
- **WAN** = huge, slower, expensive, usually leased — connects LANs across the world.
- **WAN's purpose** = break the distance barrier so distant networks and users can communicate and share resources.
- **The Internet** = the world's largest WAN, made of millions of interconnected LANs and WANs.

[[Networking]]