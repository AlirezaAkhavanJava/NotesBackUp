

## 1. Main Commands to Check IP Addresses

### `ip addr` (Modern, recommended)
```bash
ip addr show
# or shorter:
ip a
```

### `ip -4 addr` (IPv4 only)
```bash
ip -4 addr show
```

### `ip -6 addr` (IPv6 only)
```bash
ip -6 addr show
```

### `hostname -I` (Quick IPv4 list)
```bash
hostname -I
```

### `ifconfig` (Legacy, may need install)
```bash
ifconfig
# Install if missing:
sudo apt install net-tools      # Debian/Ubuntu
sudo dnf install net-tools      # Fedora/RHEL
```

---

## 2. How to Read the Output

Example `ip a` output:
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP
    link/ether 52:54:00:ab:cd:ef brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.42/24 brd 192.168.1.255 scope global dynamic eth0
       valid_lft 86390sec preferred_lft 86390sec
    inet6 fe80::5054:ff:feab:cdef/64 scope link
       valid_lft forever preferred_lft forever
```

**Key parts to read:**

| Field | Meaning |
|-------|---------|
| `1: lo`, `2: eth0` | Interface index and name |
| `<UP,LOWER_UP>` | Interface flags (UP = active) |
| `state UP` / `state DOWN` | Operational state |
| `mtu 1500` | Maximum transmission unit |
| `link/ether ...` | MAC address |
| `inet 192.168.1.42/24` | **IPv4 address** + prefix length |
| `brd 192.168.1.255` | Broadcast address |
| `scope global` | Public/routable address |
| `scope link` | Link-local (same subnet only) |
| `scope host` | Loopback only |
| `dynamic` | Assigned by DHCP |
| `inet6 fe80::...` | **IPv6 address** (fe80 = link-local) |
| `valid_lft` | Lifetime remaining |

**Understanding `192.168.1.42/24`:**
- `/24` = subnet mask `255.255.255.0` = 256 addresses (254 usable)
- Network: `192.168.1.0`, Broadcast: `192.168.1.255`

---

## 3. Get Just IPv4 and IPv6 Addresses

### IPv4 only
```bash
ip -4 addr show | grep inet
# Clean output:
ip -4 -o addr show | awk '{print $2, $4}'
```

### IPv6 only
```bash
ip -6 addr show | grep inet6
# Clean output:
ip -6 -o addr show | awk '{print $2, $4}'
```

### Default route / gateway
```bash
ip route
ip -6 route
# Just the gateway:
ip route | grep default
```

### Public IP (external)
```bash
curl -4 ifconfig.me        # IPv4
curl -6 ifconfig.co        # IPv6
curl ifconfig.me           # any
```

---

## 4. See the Network (Topology, Neighbors, Routes)

### Routing table
```bash
ip route show
# Output:
# default via 192.168.1.1 dev eth0 proto dhcp src 192.168.1.42 metric 100
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.42
```
- `default via 192.168.1.1` = your **gateway/router**
- `dev eth0` = interface used

### Neighbors (ARP table — who's on your LAN)
```bash
ip neigh
# or legacy:
arp -a
```

### Network interfaces summary
```bash
ip -br addr        # brief format
ip -br link        # link state
```

### Open ports / connections
```bash
ss -tuln           # listening TCP/UDP
ss -tup            # active connections with processes
netstat -tuln      # legacy
```

### DNS servers
```bash
resolvectl status
cat /etc/resolv.conf
```

### Scan the local network
```bash
# Install nmap
sudo apt install nmap
nmap -sn 192.168.1.0/24       # ping scan (no ports)
```

---

## 5. Quick Reference Cheat Sheet

| Task | Command |
|------|---------|
| All IPs | `ip a` |
| IPv4 only | `ip -4 a` |
| IPv6 only | `ip -6 a` |
| Quick IPv4 list | `hostname -I` |
| Gateway | `ip route \| grep default` |
| Public IP | `curl ifconfig.me` |
| LAN neighbors | `ip neigh` |
| Listening ports | `ss -tuln` |
| Brief summary | `ip -br a` |

**Tip:** `ip` replaces the old `ifconfig`, `route`, and `arp` tools. Use `ip` when possible — it's installed by default on nearly all modern Linux systems.


[[2 - Tags/Linux|Linux]]
[[Networking]]