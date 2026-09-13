
A **LAN** (Local Area Network) is a network that connects computers and devices within a limited geographic area, such as a home, office, school, or single building.

![[Pasted image 20260911194033.png]]

**Key characteristics:**
- **Small geographic scope** — typically within a single building or campus (up to a few kilometers)
- **High speed** — usually much faster than wide-area networks (WANs), often 100 Mbps to 10 Gbps
- **Privately owned** — usually managed by a single person or organization
- **Low cost** — relatively inexpensive to set up and maintain

**Common examples:**
- Your home Wi-Fi network
- An office Ethernet network
- A school computer lab

**Typical hardware:**
- Switches, routers, access points, network interface cards (NICs), and cabling (Ethernet) or wireless (Wi-Fi)

**Contrast with other network types:**
- **WAN** (Wide Area Network) — covers large areas, e.g., the internet or connections between cities
- **MAN** (Metropolitan Area Network) — covers a city
- **PAN** (Personal Area Network) — very small, e.g., Bluetooth connections

In short, a LAN is a fast, local network for sharing files, printers, and internet access among nearby devices.

# Linux Commands Related to LAN

| Command | Definition | Common Usage Example |
|---------|------------|----------------------|
| `ip` | Modern tool to show/manage IP addresses, routes, and network interfaces | `ip addr show` |
| `ifconfig` | Legacy tool to configure network interfaces (deprecated, replaced by `ip`) | `ifconfig eth0` |
| `ping` | Tests connectivity to another host on the LAN using ICMP | `ping 192.168.1.1` |
| `arp` | Displays/manipulates the ARP cache (IP ↔ MAC mapping) | `arp -a` |
| `ip neigh` | Modern replacement for `arp`, shows neighbor (ARP) table | `ip neigh show` |
| `netstat` | Shows network connections, routing tables, and interface stats | `netstat -rn` |
| `ss` | Modern replacement for `netstat`, shows socket statistics | `ss -tuln` |
| `route` | Displays/manipulates the kernel routing table (legacy) | `route -n` |
| `ip route` | Modern tool to view/manage routing table | `ip route show` |
| `traceroute` | Traces the path packets take to a destination host | `traceroute 8.8.8.8` |
| `tracepath` | Similar to traceroute, no root privileges required | `tracepath google.com` |
| `nmap` | Scans the LAN to discover hosts, open ports, and services | `nmap -sn 192.168.1.0/24` |
| `arp-scan` | Scans the local network to discover devices via ARP | `arp-scan --localnet` |
| `hostname` | Shows or sets the system's hostname | `hostname -I` |
| `hostnamectl` | Views/sets hostname and related system info | `hostnamectl status` |
| `nmcli` | Command-line tool for NetworkManager (manage connections) | `nmcli device status` |
| `nmtui` | Text-based UI for NetworkManager | `nmtui` |
| `ethtool` | Displays/configures Ethernet adapter settings (speed, duplex) | `ethtool eth0` |
| `iwconfig` | Configures wireless interfaces (legacy) | `iwconfig wlan0` |
| `iw` | Modern tool for wireless interface configuration | `iw dev wlan0 link` |
| `dhclient` | Requests/renews a DHCP lease from a LAN DHCP server | `sudo dhclient eth0` |
| `dig` | Queries DNS servers for name resolution | `dig google.com` |
| `nslookup` | Queries DNS to resolve names to IPs | `nslookup google.com` |
| `getent hosts` | Resolves hostnames using system databases | `getent hosts router` |
| `resolvectl` | Manages DNS resolution (systemd-resolved) | `resolvectl status` |
| `nc` (netcat) | Reads/writes data across network connections (TCP/UDP) | `nc -zv 192.168.1.1 80` |
| `tcpdump` | Captures and analyzes packets on the LAN | `sudo tcpdump -i eth0` |
| `wireshark` | GUI packet analyzer (LAN traffic inspection) | `sudo wireshark` |
| `iperf3` | Measures network bandwidth/throughput between hosts | `iperf3 -c 192.168.1.10` |
| `nload` | Real-time network traffic/bandwidth monitor | `nload eth0` |
| `iftop` | Displays bandwidth usage per connection | `sudo iftop -i eth0` |
| `vnstat` | Monitors network traffic statistics over time | `vnstat -i eth0` |
| `brctl` | Manages Linux Ethernet bridges | `brctl show` |
| `bridge` | Modern tool for bridge management | `bridge link` |
| `iptables` | Configures firewall rules (packet filtering/NAT) | `sudo iptables -L` |
| `nft` | Modern replacement for iptables (nftables) | `sudo nft list ruleset` |
| `ufw` | Simplified firewall management frontend | `sudo ufw status` |
| `firewalld` | Dynamic firewall manager (RHEL/Fedora) | `firewall-cmd --list-all` |
| `ssh` | Securely connects to remote hosts on the LAN | `ssh user@192.168.1.5` |
| `scp` | Securely copies files between LAN hosts | `scp file.txt user@192.168.1.5:/home/` |
| `rsync` | Efficiently syncs files between hosts | `rsync -av folder/ user@host:/backup/` |
| `smbclient` | Accesses SMB/CIFS shares (Windows file sharing) | `smbclient -L //192.168.1.5` |
| `mount.cifs` | Mounts a Windows/Samba share on the LAN | `mount -t cifs //server/share /mnt` |
| `avahi-browse` | Discovers services on the LAN via mDNS (Bonjour) | `avahi-browse -a` |
| `hostapd` | Turns a Linux machine into a Wi-Fi access point | `sudo hostapd /etc/hostapd.conf` |
| `dnsmasq` | Lightweight DNS/DHCP server for small LANs | `sudo systemctl start dnsmasq` |
| `isc-dhcp-server` | Full DHCP server for the LAN | `sudo systemctl start isc-dhcp-server` |

**Notes:**
- Commands like `ifconfig`, `route`, `arp`, and `netstat` are legacy but still found on older systems.
- Modern replacements: `ip`, `ss`, `ip neigh`, `ip route`.
- Most diagnostic/scanning tools (`nmap`, `tcpdump`, `arp-scan`) require **root/sudo** privileges.


[[Networking]]