---

---
---
## 1. Legitimate IP-Related Tools

These are standard networking/security tools — used by admins, pentesters, and researchers:

| Tool | Purpose |
|------|---------|
| `nmap` | Network/port scanning, host discovery |
| `masscan` | Very fast port scanner |
| `arp-scan` | Discover devices on local LAN |
| `netdiscover` | ARP-based LAN discovery |
| `hping3` | Custom packet crafting (TCP/UDP/ICMP) |
| `tcpdump` / `wireshark` | Packet capture and analysis |
| `scapy` | Python packet manipulation |
| `whois` / `dig` | Domain/IP lookup |
| `curl` / `wget` | Fetch with custom headers/proxies |
| `proxychains` | Route traffic through proxy chains |
| `tor` | Anonymity network |
| `macchanger` | Change MAC address (not IP) |

**Legal use:** your own network, authorized pentests, CTFs, research. Using them on systems you don't own/aren't authorized to test is illegal in most countries (UK: Computer Misuse Act 1990; US: CFAA).

---

## 2. What "IP Hiding" Means

Hiding your IP = making services/servers see a different source IP than your real one. Common methods:

### a) VPN (Virtual Private Network)
- Encrypts traffic and routes it through a VPN server.
- Server sees the VPN's IP, not yours.
- Examples: Mullvad, ProtonVPN, WireGuard self-hosted.
- **Best for:** privacy, remote work, bypassing geo-blocks (where legal).

### b) Proxy
- Intermediary that forwards requests.
- **HTTP/SOCKS proxy:** app-level (browser, curl).
- **Transparent proxy:** network-level.
- Less secure than VPN (often no encryption).

### c) Tor
- Routes traffic through 3+ relays, encrypting in layers.
- Strong anonymity, but slow; exit nodes can be monitored.
- `.onion` services only reachable via Tor.

### d) Public Wi-Fi / mobile data
- Different IP but not anonymity — your ISP/tower still sees you.

### e) NAT / shared IP
- You already share a public IP with everyone on your home network.

---

## 3. What "IP Changing" Means

Changing your IP = getting a different address assigned.

| Method | How |
|--------|-----|
| Reconnect DHCP | `sudo dhclient -r eth0 && sudo dhclient eth0` |
| Restart router | ISP usually reassigns a new IP |
| Change MAC | `macchanger` then renew DHCP (some ISPs) |
| Static config | `ip addr add 192.168.1.50/24 dev eth0` |
| VPN/proxy | Your visible IP changes (real IP unchanged) |
| Mobile hotspot toggle | Carrier assigns new IP |
| Tor | Exit node IP changes per circuit |

**Note:** You cannot change your *real* public IP without ISP cooperation — you can only change what others *see*.

---

## 4. "Hacktool" Category — What It Actually Refers To

Antivirus/EDR software flags certain tools as "HackTool" or "Riskware" because they *can* be abused. These include:

### IP spoofing tools
- **`hping3`** — can forge source IPs in packets
- **`scapy`** — craft arbitrary IP headers
- **`yersinia`** — network protocol attacks (DHCP, STP, ARP)
- **`ettercap`** — MITM, ARP spoofing
- **`bettercap`** — modern MITM framework

### IP/identity obfuscation tools
- **`proxychains-ng`** — chain proxies
- **`tor` + `torsocks`** — anonymity
- **`anonsurf`** — routes all traffic through Tor
- **`macchanger`** — MAC spoofing
- **`kalitorify`** — Tor transparent proxy

### Reconnaissance tools
- **`whois`, `dnsrecon`, `fierce`, `dnsenum`** — DNS/IP recon
- **`theHarvester`** — OSINT gathering
- **`shodan` CLI** — internet-connected device search

### Attack-oriented (illegal without authorization)
- **ARP spoofing** → intercept LAN traffic
- **IP spoofing** → bypass IP-based auth, DoS reflection
- **DHCP starvation** → exhaust IP pool
- **DNS spoofing** → redirect victims

---

## 5. Critical Legal & Ethical Warnings

⚠️ **Using these to:**
- Access systems you don't own or lack written permission to test
- Hide your identity to commit fraud, harassment, or attacks
- Bypass paywalls, DRM, or geo-restrictions against ToS
- Intercept others' traffic (MITM on a network you don't control)

...is a **criminal offence** in the UK (Computer Misuse Act 1990), US (CFAA), EU (Directive 2013/40/EU), and most jurisdictions. Penalties include fines and prison.

**Safe/legal uses:**
- Testing your own home lab
- Authorized penetration testing (with a signed scope)
- CTF competitions
- Privacy from advertisers/ISPs (VPN/Tor for personal use)
- Accessing your own services remotely

---

## 6. Practical: Hide/Change Your IP Legally

```bash
# Check current public IP
curl ifconfig.me

# Renew DHCP lease (new local IP often)
sudo dhclient -r eth0 && sudo dhclient eth0

# Route a single command through Tor
sudo apt install tor torsocks
torsocks curl ifconfig.me

# Route everything through Tor (careful — may break things)
sudo apt install anonsurf
sudo anonsurf start
sudo anonsurf stop

# Proxy chain example
sudo apt install proxychains4
proxychains4 curl ifconfig.me
```

**For real privacy:** use a reputable no-logs VPN (Mullvad, IVPN, ProtonVPN) + HTTPS everywhere + a privacy-focused browser (Firefox + uBlock, or Tor Browser).

---

## 7. Summary Table

| Goal | Legit Method | "Hacktool" Method (⚠️ risky/illegal) |
|------|--------------|--------------------------------------|
| Hide IP | VPN, Tor | Anonsurf, proxy chains |
| Change IP | DHCP renew, router restart | MAC spoof + DHCP renew |
| Scan network | `nmap` (own net) | `masscan` (unauthorized) |
| Intercept traffic | Wireshark on own net | Ettercap/bettercap MITM |
| Spoof IP | Not really legit | `hping3`, Scapy, raw sockets |

---

[[Networking]]
[[2 - Tags/Linux|Linux]]