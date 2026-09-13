
## 1. What is an IP Address?

An **IP address** (Internet Protocol address) is a **logical, numerical label** assigned to every device participating in a network that uses the Internet Protocol for communication. It operates primarily at the **Network Layer (Layer 3)** of the OSI model.

### Key Characteristics:
- **Logical, not physical**: Unlike MAC addresses, IP addresses are assigned by software/network configuration, not burned into hardware.
- **Can change**: A device can have different IPs over time (e.g., via DHCP) or multiple IPs simultaneously.
- **Two main versions**: IPv4 (32-bit) and IPv6 (128-bit).
- **Hierarchical**: Structured to allow routing across networks (unlike flat MAC addressing).
- **Two parts**: **Network portion** + **Host portion** (determined by subnet mask).

### Format Examples:
| Version | Format | Example |
|---------|--------|---------|
| IPv4 | 4 octets, dotted decimal | `192.168.1.10` |
| IPv6 | 8 groups of hex, colon-separated | `2001:0db8:85a3::8a2e:0370:7334` |

---

## 2. What Problems Do IP Addresses Solve?

### 1. **Global Addressing Across Networks**
- **Problem**: MAC addresses are flat and only work within a local segment. They cannot scale to route data across the global internet.
- **Solution**: IP addresses are **hierarchical**, allowing routers to summarize and forward traffic across billions of devices worldwide.

### 2. **Routing Between Different Networks**
- **Problem**: Data needs to travel from one network to another through intermediate routers.
- **Solution**: IP addresses contain network information that routers use to determine the best path (via routing tables).

### 3. **Logical Grouping of Devices (Subnetting)**
- **Problem**: Networks need to be divided into manageable, secure segments.
- **Solution**: IP addressing with subnet masks allows logical division into subnets for organization, security, and performance.

### 4. **Decoupling Identity from Hardware**
- **Problem**: When hardware fails or is replaced, communication shouldn't break permanently.
- **Solution**: IP addresses can be reassigned to new hardware, preserving network identity.

### 5. **Communication Across Heterogeneous Networks**
- **Problem**: Different physical networks (Ethernet, Wi-Fi, fiber) need a common addressing scheme.
- **Solution**: IP provides a **universal addressing layer** independent of underlying physical technology.

### 6. **NAT and Address Conservation**
- **Problem**: IPv4 has only ~4.3 billion addresses — not enough for all devices.
- **Solution**: Private IP ranges + NAT (Network Address Translation) allow many devices to share one public IP.

### 7. **Service Identification & Reachability**
- **Problem**: Clients need to locate servers (web, email, DNS) on the internet.
- **Solution**: IP addresses (often via DNS resolution) provide reachable endpoints for services.

---

## 3. How Do IP Addresses Work?

### 3.1 Structure (IPv4)
An IPv4 address is **32 bits**, divided into 4 octets:

```
192  .  168  .   1   .   10
11000000.10101000.00000001.00001010
```

### 3.2 Network vs Host Portion
Determined by the **subnet mask**:

```
IP:      192.168.1.10    → 11000000.10101000.00000001.00001010
Mask:    255.255.255.0   → 11111111.11111111.11111111.00000000
         ─────────────     ────────────────────────── ────────
         Network portion   Network bits (24)          Host bits (8)
```

- **Network portion**: Identifies the network (same for all devices on the subnet).
- **Host portion**: Identifies the specific device within that network.

### 3.3 CIDR Notation
Instead of writing full subnet masks, CIDR (Classless Inter-Domain Routing) uses a prefix:

| Subnet Mask | CIDR | Usable Hosts |
|-------------|------|--------------|
| 255.0.0.0 | /8 | 16,777,214 |
| 255.255.0.0 | /16 | 65,534 |
| 255.255.255.0 | /24 | 254 |
| 255.255.255.192 | /26 | 62 |
| 255.255.255.252 | /30 | 2 |

### 3.4 How Data Travels (Simplified)
1. **Source** creates a packet with source & destination IP.
2. **Local routing decision**: Is destination on same subnet?
   - **Yes** → Send directly via ARP (MAC resolution).
   - **No** → Send to **default gateway** (router).
3. **Routers** forward the packet hop-by-hop based on routing tables.
4. **Destination** receives packet, responds using the source IP.

### 3.5 Special Addresses
| Address | Purpose |
|---------|---------|
| `0.0.0.0` | "This host" / default route |
| `127.0.0.1` | Loopback (localhost) |
| `255.255.255.255` | Limited broadcast |
| `169.254.x.x` | Link-local (APIPA) when DHCP fails |
| `224.0.0.0 – 239.255.255.255` | Multicast |

---

## 4. Types of IP Addresses

### 4.1 By Version
| Type | Size | Format | Example |
|------|------|--------|---------|
| **IPv4** | 32-bit | Dotted decimal | `192.168.1.1` |
| **IPv6** | 128-bit | Colon hex | `2001:db8::1` |

### 4.2 By Scope / Reachability
| Type | Description | Range |
|------|-------------|-------|
| **Public** | Globally routable on the internet | Assigned by ISPs |
| **Private** | Used within LANs, not internet-routable | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` |
| **Loopback** | Refers to the device itself | `127.0.0.0/8`, `::1` |
| **Link-Local** | Auto-assigned when no DHCP | `169.254.0.0/16`, `fe80::/10` |
| **Multicast** | One-to-many delivery | `224.0.0.0/4`, `ff00::/8` |
| **Broadcast** | One-to-all on subnet (IPv4 only) | Subnet's highest address |
| **Anycast** | One-to-nearest (IPv6 mainly) | — |

### 4.3 By Assignment Method
| Type | Description |
|------|-------------|
| **Static** | Manually configured, doesn't change |
| **Dynamic** | Assigned automatically via DHCP, can change |
| **APIPA** | Auto-assigned when DHCP unavailable (`169.254.x.x`) |

### 4.4 By Role (IPv4 Historical Classes)
| Class | Range | Default Mask | Purpose |
|-------|-------|--------------|---------|
| A | 1–126 | /8 | Large networks |
| B | 128–191 | /16 | Medium networks |
| C | 192–223 | /24 | Small networks |
| D | 224–239 | — | Multicast |
| E | 240–255 | — | Experimental |

*(Modern networks use CIDR instead of classes.)*

---

## 5. Linux Commands to Interact with IP Addresses

### 5.1 Viewing IP Configuration

| Command | Purpose | Example |
|---------|---------|---------|
| `ip addr` / `ip a` | Show all interfaces and IPs (modern) | `ip addr show eth0` |
| `ip -4 addr` | Show only IPv4 addresses | `ip -4 addr` |
| `ip -6 addr` | Show only IPv6 addresses | `ip -6 addr` |
| `ifconfig` | Legacy tool (deprecated, net-tools) | `ifconfig eth0` |
| `hostname -I` | Quick list of all IPs | `hostname -I` |
| `ip link show` | Show interface status (up/down) | `ip link show` |

### 5.2 Assigning / Modifying IP Addresses

| Command | Purpose |
|---------|---------|
| `sudo ip addr add 192.168.1.50/24 dev eth0` | Add an IP to an interface |
| `sudo ip addr del 192.168.1.50/24 dev eth0` | Remove an IP |
| `sudo ip link set eth0 up` | Bring interface up |
| `sudo ip link set eth0 down` | Bring interface down |
| `sudo dhclient eth0` | Request IP via DHCP |
| `sudo dhclient -r eth0` | Release DHCP lease |

### 5.3 Routing

| Command | Purpose |
|---------|---------|
| `ip route show` | Display routing table |
| `ip route add 10.0.0.0/8 via 192.168.1.1` | Add a static route |
| `ip route del 10.0.0.0/8` | Delete a route |
| `ip route add default via 192.168.1.1` | Set default gateway |
| `route -n` | Legacy routing table view |

### 5.4 ARP (IP ↔ MAC Mapping)

| Command | Purpose |
|---------|---------|
| `ip neigh` | Show ARP table (modern) |
| `arp -a` | Show ARP table (legacy) |
| `sudo ip neigh flush all` | Clear ARP cache |
| `arping 192.168.1.1` | Send ARP request to an IP |

### 5.5 Connectivity Testing

| Command | Purpose |
|---------|---------|
| `ping 8.8.8.8` | Test reachability |
| `ping -6 2001:4860:4860::8888` | Test IPv6 |
| `traceroute 8.8.8.8` | Trace path to destination |
| `tracepath 8.8.8.8` | Trace path (no root needed) |
| `mtr 8.8.8.8` | Live traceroute + ping combo |

### 5.6 DNS & Name Resolution

| Command | Purpose |
|---------|---------|
| `dig google.com` | Query DNS records |
| `dig +short google.com` | Short answer only |
| `nslookup google.com` | Interactive DNS lookup |
| `host google.com` | Simple DNS lookup |
| `cat /etc/resolv.conf` | Show DNS servers |
| `cat /etc/hosts` | Show local host mappings |

### 5.7 Monitoring & Analysis

| Command | Purpose |
|---------|---------|
| `ss -tuln` | Show listening TCP/UDP ports (modern) |
| `netstat -tuln` | Same, legacy |
| `ss -tp` | Show established connections with processes |
| `tcpdump -i eth0` | Capture packets (requires root) |
| `nmap 192.168.1.0/24` | Scan network for hosts |

### 5.8 Quick Practical Examples

```bash
# Show my IP addresses
ip -4 addr show

# Assign a static IP
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up

# Check the default gateway
ip route | grep default

# Test connectivity and DNS
ping -c 4 8.8.8.8
dig +short example.com

# See who's on my subnet (ARP)
ip neigh

# Check listening services
sudo ss -tulnp
```

---

## 6. Summary Comparison: MAC vs IP

| Feature | MAC Address | IP Address |
|---------|-------------|------------|
| OSI Layer | Layer 2 (Data Link) | Layer 3 (Network) |
| Nature | Physical, burned-in | Logical, assigned |
| Format | 48-bit hex | 32-bit (v4) / 128-bit (v6) |
| Scope | Local segment | Global (with routing) |
| Changes? | Normally fixed | Can change |
| Used by | Switches | Routers |
| Hierarchy | Flat | Hierarchical |

---

## Final Takeaway

- **MAC addresses** identify *who* a device is physically on a local network.
- **IP addresses** identify *where* a device is logically on a network and enable **end-to-end routing** across the internet.
- Together, they form the foundation of modern networking: **IP for routing, MAC for local delivery**, glued together by **ARP** (IPv4) or **NDP** (IPv6).


[[Networking]]