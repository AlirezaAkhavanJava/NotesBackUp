
**Transmission media** are the physical pathways that carry data signals from one device to another in a network. They're broadly divided into **guided (wired)** and **unguided (wireless)** media.

---

## 1. Guided (Wired) Media

Signals travel along a solid physical path.

### Twisted Pair Cable
Two insulated copper wires twisted together to reduce electromagnetic interference (EMI). Multiple pairs are bundled in one jacket.

| Type | Shielding | Speed | Typical Use |
|------|-----------|-------|-------------|
| **UTP** (Unshielded) | None | Up to 10 Gbps (Cat6a/7) | Ethernet LANs, phones |
| **STP** (Shielded) | Foil/braid per pair | Up to 10 Gbps | Noisy industrial environments |

- **Pros:** Cheap, easy to install, flexible
- **Cons:** Limited distance (~100 m), susceptible to interference (UTP)
- **Connector:** RJ-45

### Coaxial Cable
A central copper conductor surrounded by insulation, a metallic shield, and an outer jacket.

- **Types:** Thinnet (10Base2), Thicknet (10Base5), RG-6 (TV/cable internet)
- **Pros:** Better shielding than UTP, higher bandwidth over distance
- **Cons:** Bulky, more expensive, largely replaced by twisted pair and fiber
- **Connector:** BNC, F-type

### Fiber Optic Cable
Carries data as **pulses of light** through a glass or plastic core.

| Type | Core | Light Path | Distance | Cost |
|------|------|------------|----------|------|
| **Single-mode** | Small (~9 µm) | One path | Up to 100+ km | Higher |
| **Multi-mode** | Larger (~50–62.5 µm) | Multiple paths | Up to ~2 km | Lower |

- **Pros:** Extremely high bandwidth, immune to EMI, very secure, long distance
- **Cons:** Expensive, fragile, requires skilled installation
- **Connectors:** LC, SC, ST

---

## 2. Unguided (Wireless) Media

Signals travel through air, vacuum, or water — no physical path.

### Radio Waves
- **Frequency:** 3 kHz – 1 GHz
- **Use:** Wi-Fi, Bluetooth, FM radio, cellular
- **Pros:** Penetrates walls, long range, omnidirectional
- **Cons:** Interference, limited bandwidth, security concerns

### Microwaves
- **Frequency:** 1 – 300 GHz
- **Use:** Satellite links, point-to-point links, Wi-Fi (2.4/5 GHz)
- **Pros:** High bandwidth, line-of-sight
- **Cons:** Requires clear line of sight, affected by rain/obstacles

### Infrared
- **Frequency:** 300 GHz – 400 THz
- **Use:** TV remotes, short-range device-to-device
- **Pros:** Cheap, secure (can't pass walls)
- **Cons:** Very short range, blocked by obstacles, line-of-sight only

---

## Comparison at a Glance

| Medium | Speed | Distance | Cost | EMI Immunity | Mobility |
|--------|-------|----------|------|--------------|----------|
| Twisted Pair | 10 Mbps–10 Gbps | ~100 m | Low | Low | None |
| Coaxial | 10 Mbps–1 Gbps | ~500 m | Medium | Medium | None |
| Fiber Optic | 1–100+ Gbps | 2–100+ km | High | Excellent | None |
| Radio | Varies | 10 m–100 km | Medium | N/A | High |
| Microwave | High | Line-of-sight | High | N/A | Limited |
| Infrared | Low–Medium | ~1–5 m | Low | N/A | Limited |

---

## Choosing the Right Medium

- **LAN, short distance, low cost** → UTP (Cat5e/Cat6)
- **High-speed backbone, long distance, EMI-heavy area** → Fiber optic
- **Legacy cable TV/internet** → Coaxial
- **Mobile devices, convenience** → Radio (Wi-Fi/Bluetooth)
- **Point-to-point between buildings** → Microwave or fiber

**Rule of thumb:** Wired media offer higher speed, reliability, and security; wireless media offer mobility and easier installation at the cost of speed and interference.


[[Networking]]