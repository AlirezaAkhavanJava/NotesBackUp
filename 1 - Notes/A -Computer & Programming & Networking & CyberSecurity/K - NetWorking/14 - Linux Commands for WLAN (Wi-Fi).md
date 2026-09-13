
# Linux Commands for WLAN (Wi-Fi)

Here are the Linux commands specifically for **WLAN / Wi-Fi** management and troubleshooting.

---

## 1. View Wi-Fi Interfaces

| Command | Definition | Example |
|---------|-----------|---------|
| `iw dev` | List all wireless devices/interfaces | `iw dev` |
| `iwconfig` | Legacy tool to show wireless interfaces | `iwconfig` |
| `ip link` | Show all network interfaces (including Wi-Fi) | `ip link show` |
| `lspci` | List PCI devices (find Wi-Fi card) | `lspci \| grep -i network` |
| `lsusb` | List USB devices (find USB Wi-Fi adapter) | `lsusb` |
| `lsmod` | Show loaded kernel modules (Wi-Fi driver) | `lsmod \| grep -i wifi` |

---

## 2. Scan for Wi-Fi Networks

| Command | Definition | Example |
|---------|-----------|---------|
| `iw dev wlan0 scan` | Scan for nearby Wi-Fi networks | `sudo iw dev wlan0 scan` |
| `iw dev wlan0 scan \| grep SSID` | List only SSID names | `sudo iw dev wlan0 scan \| grep SSID` |
| `nmcli dev wifi` | List Wi-Fi networks (NetworkManager) | `nmcli dev wifi list` |
| `nmcli dev wifi rescan` | Force rescan for networks | `sudo nmcli dev wifi rescan` |
| `iwlist wlan0 scan` | Legacy scan for networks | `sudo iwlist wlan0 scan` |

---

## 3. Connect to a Wi-Fi Network

| Command | Definition | Example |
|---------|-----------|---------|
| `nmcli dev wifi connect` | Connect to Wi-Fi via NetworkManager | `nmcli dev wifi connect "MyWiFi" password "pass123"` |
| `nmtui` | Text UI to connect to Wi-Fi | `nmtui` |
| `iw dev wlan0 connect` | Connect using `iw` (open network) | `sudo iw dev wlan0 connect "MyWiFi"` |
| `wpa_supplicant` | Connect to WPA/WPA2 network | `sudo wpa_supplicant -i wlan0 -c /etc/wpa_supplicant.conf` |
| `dhclient` | Get IP after connecting | `sudo dhclient wlan0` |

---

## 4. Disconnect / Disable Wi-Fi

| Command | Definition | Example |
|---------|-----------|---------|
| `nmcli dev disconnect` | Disconnect Wi-Fi interface | `nmcli dev disconnect wlan0` |
| `ip link set down` | Turn off Wi-Fi interface | `sudo ip link set wlan0 down` |
| `ip link set up` | Turn on Wi-Fi interface | `sudo ip link set wlan0 up` |
| `rfkill block wifi` | Software-block Wi-Fi | `sudo rfkill block wifi` |
| `rfkill unblock wifi` | Unblock Wi-Fi | `sudo rfkill unblock wifi` |
| `nmcli radio wifi off` | Turn off Wi-Fi radio | `nmcli radio wifi off` |
| `nmcli radio wifi on` | Turn on Wi-Fi radio | `nmcli radio wifi on` |

---

## 5. Wi-Fi Connection Info

| Command | Definition | Example |
|---------|-----------|---------|
| `iw dev wlan0 link` | Show current Wi-Fi connection details | `iw dev wlan0 link` |
| `iwconfig wlan0` | Show signal quality, SSID, rate | `iwconfig wlan0` |
| `nmcli dev show wlan0` | Detailed Wi-Fi device info | `nmcli dev show wlan0` |
| `nmcli connection show` | Show saved Wi-Fi connections | `nmcli connection show` |
| `nmcli -f all dev wifi` | Full Wi-Fi details (BSSID, channel, etc.) | `nmcli -f all dev wifi` |

---

## 6. Signal Strength & Speed

| Command | Definition | Example |
|---------|-----------|---------|
| `iw dev wlan0 station dump` | Show signal strength, bitrate, etc. | `iw dev wlan0 station dump` |
| `cat /proc/net/wireless` | Show signal quality | `cat /proc/net/wireless` |
| `watch -n 1 cat /proc/net/wireless` | Live signal monitoring | `watch -n 1 cat /proc/net/wireless` |
| `iwconfig wlan0 \| grep Quality` | Quick signal quality check | `iwconfig wlan0 \| grep Quality` |

---

## 7. Wi-Fi Interface Configuration

| Command | Definition | Example |
|---------|-----------|---------|
| `iw dev wlan0 set type managed` | Set interface to client mode | `sudo iw dev wlan0 set type managed` |
| `iw dev wlan0 set type monitor` | Set to monitor mode (packet sniffing) | `sudo iw dev wlan0 set type monitor` |
| `iw dev wlan0 set channel 6` | Set Wi-Fi channel | `sudo iw dev wlan0 set channel 6` |
| `iw dev wlan0 set txpower fixed 20dBm` | Set transmit power | `sudo iw dev wlan0 set txpower fixed 20dBm` |
| `ip addr add 192.168.1.10/24 dev wlan0` | Assign static IP | `sudo ip addr add 192.168.1.10/24 dev wlan0` |

---

## 8. Create a Wi-Fi Hotspot (AP Mode)

| Command | Definition | Example |
|---------|-----------|---------|
| `nmcli dev wifi hotspot` | Quick hotspot via NetworkManager | `nmcli dev wifi hotspot ssid MyHotspot password 12345678` |
| `hostapd` | Full-featured access point daemon | `sudo hostapd /etc/hostapd/hostapd.conf` |
| `dnsmasq` | DHCP/DNS for hotspot clients | `sudo dnsmasq -C /etc/dnsmasq.conf` |
| `create_ap` | Script to create AP easily | `sudo create_ap wlan0 eth0 MyAP pass123` |

---

## 9. Monitor Mode & Packet Capture

| Command | Definition | Example |
|---------|-----------|---------|
| `airmon-ng start wlan0` | Enable monitor mode (Aircrack-ng) | `sudo airmon-ng start wlan0` |
| `airmon-ng stop wlan0mon` | Disable monitor mode | `sudo airmon-ng stop wlan0mon` |
| `airodump-ng wlan0mon` | Capture Wi-Fi packets | `sudo airodump-ng wlan0mon` |
| `tcpdump -i wlan0` | Capture packets on Wi-Fi | `sudo tcpdump -i wlan0` |
| `wireshark` | GUI packet analyzer | `sudo wireshark` |

---

## 10. Troubleshooting WLAN

| Command | Definition | Example |
|---------|-----------|---------|
| `dmesg \| grep -i wifi` | Check Wi-Fi driver messages | `dmesg \| grep -i wifi` |
| `journalctl -u NetworkManager` | NetworkManager logs | `journalctl -u NetworkManager -f` |
| `systemctl restart NetworkManager` | Restart network service | `sudo systemctl restart NetworkManager` |
| `systemctl restart wpa_supplicant` | Restart WPA supplicant | `sudo systemctl restart wpa_supplicant` |
| `ping -I wlan0 8.8.8.8` | Ping through Wi-Fi interface | `ping -I wlan0 8.8.8.8` |
| `modprobe -r iwlwifi && modprobe iwlwifi` | Reload Wi-Fi driver | `sudo modprobe -r iwlwifi && sudo modprobe iwlwifi` |
| `rfkill list` | Check if Wi-Fi is blocked | `rfkill list` |

---

## 11. Wi-Fi Security / Cracking (for testing only)

| Command | Definition | Example |
|---------|-----------|---------|
| `aircrack-ng` | Crack WEP/WPA handshakes | `aircrack-ng capture.cap` |
| `aireplay-ng` | Inject packets | `sudo aireplay-ng --deauth 10 -a AP_MAC wlan0mon` |
| `wash` | Scan for WPS-enabled APs | `sudo wash -i wlan0mon` |
| `reaver` | WPS attack tool | `sudo reaver -i wlan0mon -b AP_MAC` |

⚠️ **Only use on networks you own or have permission to test.**

---

## 12. Quick Cheat Sheet (Top 10 Wi-Fi Commands)

| # | Command | What it does |
|---|---------|-------------|
| 1 | `iw dev` | List Wi-Fi interfaces |
| 2 | `nmcli dev wifi list` | Scan Wi-Fi networks |
| 3 | `nmcli dev wifi connect "SSID" password "pass"` | Connect to Wi-Fi |
| 4 | `iw dev wlan0 link` | Show current connection |
| 5 | `iwconfig wlan0` | Signal quality + SSID |
| 6 | `nmcli dev disconnect wlan0` | Disconnect |
| 7 | `rfkill list` | Check if Wi-Fi is blocked |
| 8 | `nmcli radio wifi on/off` | Turn Wi-Fi on/off |
| 9 | `iw dev wlan0 scan` | Detailed scan |
| 10 | `nmcli dev wifi hotspot` | Create hotspot |

---

## Common Wi-Fi Interface Names

| Name | Meaning |
|------|---------|
| `wlan0` | Classic Wi-Fi interface |
| `wlp3s0` | Predictable name (PCI bus 3, slot 0) |
| `wlx...` | USB Wi-Fi adapter (MAC-based name) |
| `wlan0mon` | Monitor mode interface |

---

**Note:** Most Wi-Fi commands need `sudo`. Use `iw` (modern) over `iwconfig`/`iwlist` (legacy), and `nmcli` if you use NetworkManager (most desktops).


[[Networking]]