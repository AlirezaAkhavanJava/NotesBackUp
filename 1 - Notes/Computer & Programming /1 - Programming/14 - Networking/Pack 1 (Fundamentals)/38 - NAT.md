
# NAT (Network Address Translation) — Complete Definition

---

## 1. What Is NAT?

**NAT (Network Address Translation)** is the process of **rewriting the source and/or destination IP addresses** (and often ports) in IP packet headers **as they pass through a router or firewall**.

In plain terms: NAT lets **many devices share one public IP address** by translating private addresses to public ones (and back) on the fly.

It was created because:
- IPv4 addresses ran out (~4.3 billion isn't enough for ~30+ billion devices)
- Private networks need to talk to the internet without each device having a public IP
- It adds a layer of isolation/security (external hosts can't directly reach internal devices)

Defined primarily in **RFC 3022** (traditional NAT) and **RFC 2663** (NAT terminology).

---

## 2. The Core Problem NAT Solves

Without NAT:
```
Every device needs its own globally unique public IP.
→ 4.3 billion IPv4 addresses exhausted (happened in 2011).
→ New devices couldn't get online.
```

With NAT:
```
One public IP  ──  shared by hundreds of devices
via translation at the router.
```

---

## 3. How NAT Works (Step by Step)

### Setup
- Home network: `192.168.1.0/24`
- Your laptop: `192.168.1.42`
- Router's LAN IP: `192.168.1.1`
- Router's public IP: `86.24.10.5`
- You visit `93.184.216.34` (example.com) on port 80

### Outbound (your request leaving)

| Step | Source IP:Port | Destination IP:Port |
|------|---------------|---------------------|
| Laptop sends | `192.168.1.42:51000` | `93.184.216.34:80` |
| Router rewrites (NAT) | `86.24.10.5:40001` | `93.184.216.34:80` |
| Server sees | `86.24.10.5:40001` | — |

The router **remembers** in its NAT table:
```
192.168.1.42:51000  ←→  86.24.10.5:40001
```

### Inbound (server's reply returning)

| Step | Source IP:Port | Destination IP:Port |
|------|---------------|---------------------|
| Server replies | `93.184.216.34:80` | `86.24.10.5:40001` |
| Router looks up table | — | finds `192.168.1.42:51000` |
| Router rewrites & forwards | `93.184.216.34:80` | `192.168.1.42:51000` |

Your laptop receives the reply as if it came directly.

**Key point:** The router rewrites addresses **transparently** — neither your laptop nor the server knows NAT happened.

---

## 4. Types of NAT

### a) Static NAT (1-to-1)
- One private IP permanently mapped to one public IP.
- Used for servers that must be reachable from outside.
- Example: `192.168.1.10` ⇄ `86.24.10.5` (always)

### b) Dynamic NAT (many-to-many pool)
- A pool of public IPs; each private IP gets one temporarily.
- Limited by pool size — if pool exhausted, no more connections.

### c) PAT / NAT Overload (many-to-one) ⭐ most common
- **Port Address Translation** — many private IPs share **one** public IP.
- Distinguishes connections by **source port number**.
- This is what your home router does.
- Also called **NAT overload** or **IP masquerading** (Linux term).

```
192.168.1.42:51000  ──┐
192.168.1.43:51001  ──┼──► 86.24.10.5 (one public IP)
192.168.1.44:51002  ──┘    differentiated by port
```

### d) NAT64 / NAT46 / NAT66
- Translates between IPv6 and IPv4 networks.
- Used during IPv6 transition.

### e) CGNAT (Carrier-Grade NAT)
- ISP-level NAT using `100.64.0.0/10` (RFC 6598).
- Many customers share one public IP.
- Common on mobile networks and some ISPs.
- Downside: you can't easily host services or get a "real" public IP.

### f) Hairpin NAT (NAT loopback)
- Lets internal devices reach other internal devices via the **public** IP.
- Common issue: can't access your own server via public IP without this.

---

## 5. NAT vs PAT — The Difference

| Feature | NAT (basic) | PAT (NAT overload) |
|---------|-------------|---------------------|
| Translates | IP only | IP + port |
| Mapping | 1-to-1 | Many-to-1 |
| Public IPs needed | One per device | One total |
| Used by home routers | Rarely | Almost always |
| Also called | Basic NAT | NAT overload, masquerade |

**In everyday speech, "NAT" usually means PAT.**

---

## 6. The NAT Table (Translation Table)

The router maintains a table like:

| Inside Local | Inside Global | Outside Global | Protocol | Timeout |
|--------------|---------------|----------------|----------|---------|
| 192.168.1.42:51000 | 86.24.10.5:40001 | 93.184.216.34:80 | TCP | 300s |
| 192.168.1.43:52000 | 86.24.10.5:40002 | 142.250.185.78:443 | TCP | 280s |
| 192.168.1.44:53000 | 86.24.10.5:40003 | 8.8.8.8:53 | UDP | 30s |

**Cisco terminology:**
- **Inside local** = private IP of internal device
- **Inside global** = public IP as seen by outside
- **Outside global** = public IP of external destination

---

## 7. Port Forwarding (Static NAT for inbound)

NAT **blocks unsolicited inbound** connections by default — that's why you can't host a web server without configuration.

**Port forwarding** creates a permanent rule:
```
Incoming to 86.24.10.5:8080  →  forward to  192.168.1.100:80
```

| External Port | Internal IP | Internal Port | Protocol |
|---------------|-------------|---------------|----------|
| 8080 | 192.168.1.100 | 80 | TCP |
| 2222 | 192.168.1.50 | 22 | TCP |
| 25565 | 192.168.1.60 | 25565 | TCP/UDP |

Also called: **static NAT**, **virtual server**, **DNAT** (Linux).

---

## 8. Advantages and Disadvantages

### ✅ Advantages
- **Conserves IPv4 addresses** — biggest reason
- **Hides internal topology** — external hosts only see the router
- **Basic firewall effect** — unsolicited inbound blocked
- **Easy internal renumbering** — change private range without ISP involvement
- **Flexible** — can route multiple internal subnets through one public IP

### ❌ Disadvantages
- **Breaks end-to-end connectivity** — the internet's original design principle
- **Complicates peer-to-peer** — VoIP, gaming, BitTorrent struggle
- **Breaks some protocols** — FTP, SIP, H.323 embed IPs in payloads (need ALG)
- **Hairpin/loopback issues** — internal devices can't always reach public IP
- **Hides attackers** — harder to trace abuse back to a specific device
- **Stateful overhead** — router must track every connection
- **CGNAT problems** — no real public IP, can't port forward, some services break
- **Slows IPv6 adoption** — people rely on NAT as a "security" crutch

---

## 9. NAT and Security — Common Misconception

> "NAT is a firewall / makes me secure."

**Not exactly true.** NAT:
- ✅ **Incidentally** blocks unsolicited inbound connections (side effect, not design)
- ❌ Does **not** inspect packet contents
- ❌ Does **not** filter outbound traffic
- ❌ Does **not** stop malware from phoning home
- ❌ Can be bypassed by **UPnP** (apps open their own ports)
- ❌ **NAT slipstreaming** / **NAT traversal** techniques punch holes

**A real firewall** does stateful inspection, filtering, logging, and policy enforcement. NAT is not a substitute.

---

## 10. NAT Traversal (How P2P Bypasses NAT)

Since NAT blocks inbound, protocols use tricks to establish connections:

| Technique | How it works |
|-----------|--------------|
| **STUN** | Client asks a public server "what's my public IP:port?" |
| **TURN** | Relay server forwards traffic when direct fails |
| **ICE** | Combines STUN + TURN, tries all paths |
| **UPnP / NAT-PMP** | App asks router to open a port automatically |
| **Hole punching** | Both peers send outbound simultaneously; NAT tables align |
| **Reverse connections** | Internal host connects out; external replies on same socket |

Used by: WebRTC, Zoom, Discord, games, BitTorrent, Tailscale, WireGuard.

---

## 11. NAT on Linux (Practical)

```bash
# View NAT table (conntrack)
sudo conntrack -L
sudo cat /proc/net/nf_conntrack

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Set up PAT (masquerade) on eth0
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Port forwarding: external 8080 → 192.168.1.100:80
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 \
  -j DNAT --to-destination 192.168.1.100:80

# Check your NAT type (gaming)
# Strict / Moderate / Open — determined by STUN test
```

On your home router, NAT is configured via the web UI (usually `192.168.1.1`) under "Port Forwarding", "Virtual Server", or "NAT".

---

## 12. Quick Reference Summary

| Term | Meaning |
|------|---------|
| **NAT** | Rewriting IP addresses in packet headers |
| **PAT / NAT overload** | Many-to-one using ports (home routers) |
| **Static NAT** | Permanent 1-to-1 mapping |
| **Dynamic NAT** | Temporary mapping from a pool |
| **CGNAT** | ISP-level NAT (`100.64.0.0/10`) |
| **Port forwarding / DNAT** | Inbound rule to reach internal host |
| **SNAT** | Source NAT (outbound, masquerade) |
| **DNAT** | Destination NAT (inbound, port forward) |
| **NAT table** | Router's record of active translations |
| **NAT traversal** | Techniques to bypass NAT for P2P |
| **Hairpin NAT** | Internal access via public IP |
| **ALG** | Application Layer Gateway — fixes FTP/SIP through NAT |

---

## 13. The One-Sentence Definition

> **NAT is a router function that rewrites the source/destination IP (and often port) in packet headers so that multiple private-network devices can share one public IP address — translating outbound requests to the public IP and matching inbound replies back to the correct internal device using a stateful translation table.**

**Analogy:** NAT is like a company's receptionist. All external calls go to one main number (public IP). The receptionist (router) knows which extension (private IP) each call is for, transfers it, and remembers the mapping so return calls reach the right person — without the outside caller ever knowing the internal extension numbers.



[[Networking]]