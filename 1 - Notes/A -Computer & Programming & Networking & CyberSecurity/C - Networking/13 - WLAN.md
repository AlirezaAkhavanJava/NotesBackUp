
# WLAN (Wireless Local Area Network)

## Definition

A **WLAN** (Wireless Local Area Network) is a **LAN that uses wireless communication** (radio waves, Wi-Fi) instead of physical cables to connect devices. It gives devices network access within a limited area — like a home, office, school, or campus — without needing Ethernet cables.

**Wi-Fi is the most common technology used to build a WLAN.**

![[Pasted image 20260911194601.png]]

---

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Geographic scope** | Same as LAN — building, home, campus (up to ~100 m per access point) |
| **Medium** | Radio waves (2.4 GHz, 5 GHz, 6 GHz bands) |
| **Speed** | High — 54 Mbps (802.11g) up to several Gbps (Wi-Fi 6/7) |
| **Ownership** | Private (you own the router/AP) |
| **Cost** | Low — no cabling needed |
| **Mobility** | Devices can move freely within coverage |
| **Security** | WPA2 / WPA3 encryption, SSID, MAC filtering |
| **Standard** | IEEE 802.11 family (a, b, g, n, ac, ax, be) |

---

## Difference: LAN vs WLAN

| Aspect | **LAN (wired)** | **WLAN (wireless)** |
|--------|-----------------|---------------------|
| **Medium** | Ethernet cables (twisted pair, fiber) | Radio waves (Wi-Fi) |
| **Mobility** | Fixed — device must be plugged in | Free movement within range |
| **Speed** | Very high & stable (1–100 Gbps) | High but varies (54 Mbps – several Gbps) |
| **Reliability** | Very stable, low interference | Affected by walls, interference, distance |
| **Security** | Physically secure (cable access needed) | Needs encryption (WPA2/WPA3) |
| **Setup** | Requires cabling | No cables — quick setup |
| **Cost** | Cabling cost can be high | Lower (no cabling) |
| **Latency** | Very low | Slightly higher |
| **Range** | Limited by cable length | ~30–100 m per access point |
| **Example** | Office Ethernet network | Home Wi-Fi, café Wi-Fi |

---

## WLAN vs WWAN vs WPAN

| Type | Full form | Scope | Technology | Example |
|------|-----------|-------|------------|---------|
| **WPAN** | Wireless Personal Area Network | ~1–10 m | Bluetooth, Zigbee | Wireless earbuds |
| **WLAN** | Wireless Local Area Network | ~10–100 m | Wi-Fi (802.11) | Home/office Wi-Fi |
| **WMAN** | Wireless Metropolitan Area Network | City (~5–50 km) | WiMAX | City broadband |
| **WWAN** | Wireless Wide Area Network | Country/global | 4G/5G, satellite | Mobile data |

---

## What Problem Does WLAN Solve?

Wired LANs need cables everywhere — expensive, messy, and restrictive.

**WLAN solves:**
1. **Mobility** — users move freely with laptops, phones, tablets
2. **No cabling cost** — no need to run Ethernet through walls
3. **Easy expansion** — add devices without new wiring
4. **Flexible placement** — devices where cables can't reach (warehouses, historic buildings)
5. **Guest access** — visitors get internet without plugging in
6. **Scalability** — add access points to extend coverage

**Example problems solved:**
- A café wants customers to use the internet → **WLAN**
- A warehouse needs handheld scanners to roam freely → **WLAN**
- A home has phones, laptops, TVs, and smart devices → **WLAN**

---

## Illustrations

### 1. Wired LAN vs WLAN

```
   WIRED LAN                          WLAN
   ┌──────────────┐                  ┌──────────────┐
   │ PC ──cable──┐│                  │ PC ~~~       │
   │ PC ──cable──┼┤                  │ Phone ~~~    │
   │ PC ──cable──┘│                  │ TV ~~~       │
   │    Switch    │                  │   Router/AP  │
   └──────┬───────┘                  └──────┬───────┘
          │                                 │
       Internet                          Internet
   (all devices plugged in)         (all devices wireless)
```

---

### 2. WLAN Inside a Building

```
   ┌──────────────────── Building (WLAN) ────────────────────┐
   │                                                         │
   │     💻 PC          📱 Phone         📺 Smart TV          │
   │       ~~~            ~~~               ~~~              │
   │          \            |               /                 │
   │           \           |              /                  │
   │            ▼          ▼             ▼                   │
   │           ┌───────────────────────────┐                 │
   │           │   Wireless Access Point   │                 │
   │           │        (Router)           │                 │
   │           └─────────────┬─────────────┘                 │
   │                         │                               │
   └─────────────────────────┼───────────────────────────────┘
                             │
                        Internet (WAN)
```

---

### 3. WLAN with Multiple Access Points (Campus)

```
   ┌────────────────────── Campus WLAN ──────────────────────┐
   │                                                         │
   │   ┌── AP 1 ──┐      ┌── AP 2 ──┐      ┌── AP 3 ──┐      │
   │   │  Floor 1 │      │  Floor 2 │      │  Floor 3 │      │
   │   └────┬─────┘      └────┬─────┘      └────┬─────┘      │
   │        │                 │                 │            │
   │        └────────── Wired Backbone ────────┘             │
   │                         │                               │
   │                    Core Switch                          │
   │                         │                               │
   └─────────────────────────┼───────────────────────────────┘
                             │
                       Internet (WAN)
```

---

### 4. Network Type Hierarchy (Including WLAN)

```
   PAN          LAN / WLAN        MAN / WMAN         WAN / WWAN
  (1–10 m)     (10 m–1 km)       (5–100 km)       (100 km – global)

   📱🔵          🏠🏢📶             🏙️📡               🌍🛰️
 Bluetooth    Home/Office       City              Internet
              (wired/wireless)  (wired/wireless)  (wired/wireless)
```

---

### 5. Wi-Fi Standards Timeline

```
   1997      1999      2003      2009      2014      2019      2024
   802.11    802.11b   802.11g   802.11n   802.11ac  802.11ax  802.11be
   2 Mbps    11 Mbps   54 Mbps   600 Mbps  6.9 Gbps  9.6 Gbps  46 Gbps
   ─────────────────────────────────────────────────────────────────►
                        Wi-Fi 1 → Wi-Fi 4 → Wi-Fi 5 → Wi-Fi 6 → Wi-Fi 7
```

---

## Summary

- **WLAN** = a LAN built with **wireless (Wi-Fi)** technology instead of cables.
- **Same scope as LAN** but adds **mobility** and removes cabling.
- **Technology** = IEEE 802.11 (Wi-Fi 1 through Wi-Fi 7).
- **Purpose** = flexible, cable-free network access for homes, offices, campuses, and public spaces.
- **Trade-off** = more convenient, but slightly less stable and secure than wired LAN (needs WPA2/WPA3).



[[Networking]]