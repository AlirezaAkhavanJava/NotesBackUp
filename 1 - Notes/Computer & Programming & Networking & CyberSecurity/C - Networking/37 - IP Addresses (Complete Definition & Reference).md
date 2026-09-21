

---

## 1. What Is an IP Address?

An **IP address** (Internet Protocol address) is a **unique numerical label** assigned to every device on a network so it can be **identified and located** for sending/receiving data.

Think of it like a **postal address** for your device:
- **Street number** = host portion (which device)
- **Street/city** = network portion (which network)

### Two versions in use:

| Version | Format | Size | Example |
|---------|--------|------|---------|
| **IPv4** | Dotted decimal | 32-bit | `192.168.1.42` |
| **IPv6** | Hexadecimal, colon-separated | 128-bit | `2001:0db8::1428:57ab` |

### IPv4 structure
```
192  .  168  .   1   .   42
└──────network──────┘ └host┘
   (24 bits)          (8 bits)
```

Each octet = 0–255 (8 bits). Total = 4 × 8 = 32 bits ≈ **4.3 billion** addresses (exhausted in 2011 → hence IPv6).

---

## 2. Types of IP Addresses

### By scope/assignment:

| Type | Description | Example |
|------|-------------|---------|
| **Public** | Routable on the internet, globally unique | `8.8.8.8` |
| **Private** | Used inside LANs, not routable on internet | `192.168.1.10` |
| **Loopback** | Refers to the device itself | `127.0.0.1` |
| **Link-local** | Auto-assigned when DHCP fails | `169.254.x.x` |
| **Multicast** | One-to-many delivery | `224.0.0.0`–`239.255.255.255` |
| **Broadcast** | One-to-all on a subnet | `192.168.1.255` |
| **Anycast** | One-to-nearest (used in DNS/CDN) | `1.1.1.1` (Cloudflare) |
| **Unspecified** | "No address" placeholder | `0.0.0.0` |

### By assignment method:

| Method | Description |
|--------|-------------|
| **Static** | Manually configured, never changes |
| **Dynamic (DHCP)** | Assigned automatically by a server, has a lease |
| **APIPA** | Auto-assigned `169.254.x.x` when DHCP unavailable |

### By address class (legacy, but still referenced):

| Class | Range | Default Mask | Purpose |
|-------|-------|--------------|---------|
| A | `1.0.0.0` – `126.255.255.255` | /8 | Very large networks |
| B | `128.0.0.0` – `191.255.255.255` | /16 | Medium networks |
| C | `192.0.0.0` – `223.255.255.255` | /24 | Small networks |
| D | `224.0.0.0` – `239.255.255.255` | — | Multicast |
| E | `240.0.0.0` – `255.255.255.255` | — | Reserved/experimental |

> Modern networking uses **CIDR** (`192.168.1.0/24`) instead of classes.

---

## 3. Private vs Public IP

### Public IP
- **Globally unique** — assigned by your ISP
- **Routable** on the internet
- Registered with IANA/RIRs
- Your router has one; all your devices share it via **NAT**

### Private IP
- **Reusable** in every private network (that's why your neighbor also has `192.168.1.1`)
- **Not routable** on the internet
- Defined in **RFC 1918**

**RFC 1918 private ranges:**

| Class | Range | CIDR | # Addresses |
|-------|-------|------|-------------|
| A | `10.0.0.0` – `10.255.255.255` | `10.0.0.0/8` | ~16.7 million |
| B | `172.16.0.0` – `172.31.255.255` | `172.16.0.0/12` | ~1 million |
| C | `192.168.0.0` – `192.168.255.255` | `192.168.0.0/16` | ~65,000 |

### Why this matters — NAT
Your router translates:
```
Your device:  192.168.1.42  ──┐
Your phone:   192.168.1.43  ──┼──► Router ──► Public IP: 86.24.x.x ──► Internet
Your laptop:  192.168.1.44  ──┘
```
Outsiders only see the public IP. Internal IPs are invisible.

---

## 4. Why Can Everyone Use `192.168.1.1`?

This is the key insight. **Private IPs are only meaningful inside their own network.**

### Analogy: Apartment numbers
- Building A: Flat 1, Flat 2, Flat 3
- Building B: Flat 1, Flat 2, Flat 3

Both buildings have "Flat 1" — **no conflict** because they're in different buildings (different networks).

### Technical reason
1. **Private IPs are never routed on the internet.** ISPs drop packets with private source/destination addresses at their boundary.
2. **Each network is isolated.** Your `192.168.1.1` and your neighbor's `192.168.1.1` exist in separate LANs.
3. **NAT translates** your private IP → your public IP before traffic leaves.
4. **Routers only care about their own LAN.** Your router sees `192.168.1.x` and knows which device to send to — it doesn't know or care about other networks using the same range.

### So why is `192.168.1.1` so common as a gateway?
- It's the **first usable address** in the default `/24` subnet (`192.168.1.0` = network, `.1` = router, `.255` = broadcast).
- Router manufacturers default to `192.168.1.1` or `192.168.0.1` for familiarity.
- It's a convention, not a requirement — you can change it to `192.168.1.254` or `10.0.0.1` and nothing breaks.

**Conflict only happens if:**
- You connect two networks with the same range (e.g., VPN into a network using `192.168.1.0/24` while your home also uses it) → routing ambiguity.

---

## 5. Complete List of Reserved / Special IP Ranges

### IPv4 Reserved Ranges (RFC-defined)

| Range | CIDR | RFC | Purpose |
|-------|------|-----|---------|
| `0.0.0.0/8` | — | RFC 1122 | "This network" / unspecified |
| `0.0.0.0` | /32 | — | Default route / "any address" |
| `10.0.0.0` – `10.255.255.255` | `10.0.0.0/8` | RFC 1918 | Private (Class A) |
| `100.64.0.0` – `100.127.255.255` | `100.64.0.0/10` | RFC 6598 | Carrier-grade NAT (CGNAT) |
| `127.0.0.0` – `127.255.255.255` | `127.0.0.0/8` | RFC 1122 | Loopback (`127.0.0.1` = localhost) |
| `169.254.0.0` – `169.254.255.255` | `169.254.0.0/16` | RFC 3927 | Link-local / APIPA |
| `172.16.0.0` – `172.31.255.255` | `172.16.0.0/12` | RFC 1918 | Private (Class B) |
| `192.0.0.0` – `192.0.0.255` | `192.0.0.0/24` | RFC 6890 | IETF protocol assignments |
| `192.0.2.0` – `192.0.2.255` | `192.0.2.0/24` | RFC 5737 | TEST-NET-1 (documentation) |
| `192.88.99.0` – `192.88.99.255` | `192.88.99.0/24` | RFC 7526 | 6to4 relay anycast (deprecated) |
| `192.168.0.0` – `192.168.255.255` | `192.168.0.0/16` | RFC 1918 | Private (Class C) |
| `198.18.0.0` – `198.19.255.255` | `198.18.0.0/15` | RFC 2544 | Benchmark testing |
| `198.51.100.0` – `198.51.100.255` | `198.51.100.0/24` | RFC 5737 | TEST-NET-2 (documentation) |
| `203.0.113.0` – `203.0.113.255` | `203.0.113.0/24` | RFC 5737 | TEST-NET-3 (documentation) |
| `224.0.0.0` – `239.255.255.255` | `224.0.0.0/4` | RFC 5771 | Multicast |
| `240.0.0.0` – `255.255.255.254` | `240.0.0.0/4` | RFC 1112 | Reserved (future use) |
| `255.255.255.255` | `/32` | RFC 919 | Limited broadcast |

### Common Multicast Addresses (within `224.0.0.0/4`)

| Address | Purpose |
|---------|---------|
| `224.0.0.1` | All hosts on subnet |
| `224.0.0.2` | All routers on subnet |
| `224.0.0.5` | OSPF all routers |
| `224.0.0.9` | RIPv2 routers |
| `224.0.1.1` | NTP |
| `239.255.255.250` | SSDP (UPnP) |

### IPv6 Reserved Ranges

| Range | CIDR | Purpose |
|-------|------|---------|
| `::/128` | — | Unspecified address |
| `::1/128` | — | Loopback (localhost) |
| `::ffff:0:0/96` | — | IPv4-mapped IPv6 |
| `64:ff9b::/96` | — | IPv4/IPv6 translation (NAT64) |
| `100::/64` | — | Discard-only |
| `2001::/32` | — | Teredo tunneling |
| `2001:db8::/32` | — | Documentation (RFC 3849) |
| `fc00::/7` | — | Unique local (private) — `fd00::/8` in practice |
| `fe80::/10` | — | Link-local |
| `ff00::/8` | — | Multicast |

### Private IPv6 (`fc00::/7`)
Equivalent to RFC 1918 for IPv6:
- `fd00::/8` — locally assigned (most common)
- Not routable on the public internet

---

## 6. Quick Reference Summary

| Concept | Key Point |
|---------|-----------|
| **IP address** | Unique label identifying a device on a network |
| **IPv4** | 32-bit, ~4.3B addresses, dotted decimal |
| **IPv6** | 128-bit, virtually unlimited, hex colon format |
| **Public IP** | Globally unique, internet-routable, from ISP |
| **Private IP** | Reusable per network, not internet-routable (RFC 1918) |
| **Why 192.168.1.1 repeats** | Private ranges are isolated per network + NAT translation |
| **Loopback** | `127.0.0.1` (IPv4), `::1` (IPv6) — always yourself |
| **APIPA** | `169.254.x.x` — DHCP failed, self-assigned |
| **CGNAT** | `100.64.0.0/10` — ISP-level NAT (common on mobile) |
| **Broadcast** | Last address in subnet (e.g., `192.168.1.255/24`) |
| **Default gateway** | Router's LAN IP — usually `.1` or `.254` |

---

## 7. Verify on Your Own System

```bash
# Your private IP
ip -4 addr show

# Your public IP (what the internet sees)
curl ifconfig.me

# Your gateway
ip route | grep default

# Check if an IP is private
# 10.x.x.x, 172.16-31.x.x, 192.168.x.x = private
```

**Key takeaway:** Private IPs work like apartment numbers inside a building — every building can have a "Flat 1" without conflict, because the postal system (internet routing) only cares about the building's street address (public IP). NAT is the mailroom that translates between them.


[[Networking]]
