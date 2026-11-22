
#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s nullglob

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

CREATED=0
SKIPPED=0

add_notes() {
    local folder="$1"
    shift

    local dir="$ROOT/$folder"
    local max_index=-1
    local file filename prefix concept index

    for file in "$dir"/*.md; do
        [[ -f "$file" ]] || continue
        filename="${file##*/}"

        if [[ "$filename" =~ ^([0-9]+)[[:space:]]*-[[:space:]] ]]; then
            prefix="${BASH_REMATCH[1]}"
            (( 10#$prefix > max_index )) && max_index=$((10#$prefix))
        fi
    done

    local next_index=$((max_index + 1))

    if [[ ! -d "$dir" ]]; then
        echo "[DIR] $folder"
        [[ "$DRY_RUN" == true ]] || mkdir -p -- "$dir"
    fi

    for concept in "$@"; do
        local exists=false

        for file in "$dir"/*.md; do
            [[ -f "$file" ]] || continue
            filename="${file##*/}"

            if [[ "$filename" == *" - $concept.md" ]]; then
                exists=true
                break
            fi
        done

        if [[ "$exists" == true ]]; then
            echo "[SKIP] $folder/$concept"
            ((SKIPPED += 1))
            continue
        fi

        printf -v index "%02d" "$next_index"

        local target="$dir/$index - $concept.md"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[PREVIEW] $folder/$index - $concept.md"
        else
            printf '%s\n' '[[Networking]]' > "$target"
            echo "[CREATED] $folder/$index - $concept.md"
        fi

        ((CREATED += 1))
        ((next_index += 1))
    done
}

echo "========================================"
echo " NETWORKING CURRICULUM GENERATOR"
echo "========================================"

# ==================================================
# PACK 0 - CONTENTS AND ROADMAP
# ==================================================

add_notes "Pack 0 (Contents and Roadmap)" \
    "Complete Networking Learning Roadmap" \
    "Networking Prerequisites and Learning Order" \
    "Practical Networking Labs" \
    "Networking Tools and References" \
    "Networking Knowledge Assessment"

# ==================================================
# PACK 1 - FUNDAMENTALS
# ==================================================

add_notes "Pack 1 (Fundamentals)" \
    "Network Topology" \
    "Bus Topology" \
    "Star Topology" \
    "Ring Topology" \
    "Mesh Topology" \
    "Hybrid Topology" \
    "Network Architecture Models" \
    "Network Segmentation" \
    "Broadcast Domains" \
    "Collision Domains" \
    "Unicast" \
    "Broadcast" \
    "Multicast" \
    "Anycast" \
    "Network Interface Card" \
    "Network Interface" \
    "Network Link" \
    "Network Hop" \
    "Network MTU" \
    "Jumbo Frames" \
    "Packet Switching Fundamentals" \
    "Store and Forward" \
    "Cut Through Switching" \
    "Full Duplex and Half Duplex" \
    "Flow Control in Networking" \
    "Network Congestion" \
    "Quality of Service" \
    "Jitter" \
    "Packet Loss" \
    "Network Availability" \
    "Network Reliability" \
    "Network Performance Metrics"

# ==================================================
# PACK 2 - OSI MODEL AND TCP/IP
# ==================================================

add_notes "Pack 2 (OSI Model - TCP.IP)" \
    "Encapsulation" \
    "Decapsulation" \
    "Protocol Data Units" \
    "Layer 1 - Physical Layer Details" \
    "Layer 2 - Data Link Layer Details" \
    "Layer 3 - Network Layer Details" \
    "Layer 4 - Transport Layer Details" \
    "Layer 5 - Session Layer Details" \
    "Layer 6 - Presentation Layer Details" \
    "Layer 7 - Application Layer Details" \
    "Ethernet and OSI Layers" \
    "TCP and OSI Layers" \
    "TCP IP Model Layers" \
    "OSI to TCP IP Layer Mapping" \
    "Protocols by OSI Layer" \
    "Headers and Trailers" \
    "Protocol Encapsulation Example" \
    "Network Troubleshooting with OSI Model"

# ==================================================
# PACK 4 - SWITCHING AND ROUTING DEVICES
# Keep existing Pack 4 and its original notes.
# ==================================================

add_notes "Pack 4" \
    "Layer 1 Network Devices" \
    "Layer 2 Network Devices" \
    "Layer 3 Network Devices" \
    "Network Hub" \
    "Repeater" \
    "Bridge" \
    "Ethernet Switch Architecture" \
    "Managed and Unmanaged Switches" \
    "Layer 2 and Layer 3 Switches" \
    "Switch MAC Address Table" \
    "MAC Address Learning" \
    "MAC Address Aging" \
    "Switching and Frame Forwarding" \
    "Unknown Unicast Flooding" \
    "Broadcast Forwarding" \
    "Router Architecture" \
    "Routing and Packet Forwarding" \
    "Default Gateway" \
    "Routing Table Fundamentals" \
    "Static and Dynamic Routing" \
    "Firewall and Router Differences" \
    "Modem and Router Differences" \
    "Access Point Architecture" \
    "Gateway Devices"

# ==================================================
# PACK 5 - ETHERNET AND DATA LINK LAYER
# ==================================================

add_notes "Pack 5 (Ethernet and Data Link Layer)" \
    "Ethernet Fundamentals" \
    "IEEE 802.3 Standard" \
    "Ethernet Frame Structure" \
    "Ethernet Frame Header" \
    "Ethernet Frame Fields" \
    "EtherType" \
    "Frame Check Sequence" \
    "Ethernet MAC Addressing" \
    "MAC Address Structure" \
    "Unicast MAC Addresses" \
    "Multicast MAC Addresses" \
    "Broadcast MAC Address" \
    "MAC Address Resolution" \
    "Ethernet Physical Standards" \
    "Fast Ethernet" \
    "Gigabit Ethernet" \
    "10 Gigabit Ethernet" \
    "Fiber Optic Ethernet" \
    "Copper Ethernet" \
    "Fiber Optic Cables" \
    "Twisted Pair Cables" \
    "RJ45 Connector" \
    "Auto Negotiation" \
    "VLAN Fundamentals" \
    "IEEE 802.1Q" \
    "VLAN Tagging" \
    "Access Ports and Trunk Ports" \
    "Inter VLAN Routing" \
    "Spanning Tree Protocol" \
    "Rapid Spanning Tree Protocol" \
    "Link Aggregation" \
    "LACP" \
    "Ethernet Flow Control"

# ==================================================
# PACK 6 - IP ADDRESSING AND SUBNETTING
# ==================================================

add_notes "Pack 6 (IP Addressing and Subnetting)" \
    "IPv4 Address Structure" \
    "Network ID and Host ID" \
    "Subnet Masks" \
    "CIDR Notation" \
    "Classful Addressing" \
    "Classless Addressing" \
    "Public IP Address Ranges" \
    "Private IP Address Ranges" \
    "Loopback Address Range" \
    "Link Local Addressing" \
    "APIPA" \
    "Network Address" \
    "Broadcast Address" \
    "Usable Host Addresses" \
    "Subnetting Fundamentals" \
    "Subnetting Calculations" \
    "Subnetting with Binary Arithmetic" \
    "Variable Length Subnet Masking" \
    "Fixed Length Subnet Masking" \
    "Supernetting" \
    "Route Aggregation" \
    "Subnet Planning" \
    "IPv4 Address Allocation" \
    "IP Address Conflicts" \
    "IP Address Planning Exercises"

# ==================================================
# PACK 7 - IPv4 AND IPv6
# ==================================================

add_notes "Pack 7 (IPv4 and IPv6)" \
    "IPv4 Protocol Architecture" \
    "IPv4 Packet Header" \
    "IPv4 Header Fields" \
    "IPv4 Fragmentation" \
    "IPv4 Reassembly" \
    "Time To Live" \
    "IPv4 Options" \
    "IPv4 Routing Behavior" \
    "IPv4 Address Exhaustion" \
    "IPv6 Fundamentals" \
    "IPv6 Address Structure" \
    "IPv6 Address Types" \
    "IPv6 Global Unicast" \
    "IPv6 Link Local" \
    "IPv6 Unique Local Addresses" \
    "IPv6 Multicast" \
    "IPv6 Anycast" \
    "IPv6 Address Compression" \
    "IPv6 Prefixes" \
    "IPv6 Packet Header" \
    "IPv6 Extension Headers" \
    "IPv6 Neighbor Discovery Protocol" \
    "IPv6 Router Advertisement" \
    "IPv6 SLAAC" \
    "IPv6 DHCPv6" \
    "IPv6 Fragmentation" \
    "IPv6 Path MTU Discovery" \
    "IPv4 vs IPv6" \
    "Dual Stack Networking" \
    "NAT64 and DNS64" \
    "Transition from IPv4 to IPv6"

# ==================================================
# PACK 8 - ROUTING AND ROUTING PROTOCOLS
# ==================================================

add_notes "Pack 8 (Routing and Routing Protocols)" \
    "Routing Fundamentals" \
    "Routing Decisions" \
    "Longest Prefix Match" \
    "Routing Metrics" \
    "Administrative Distance" \
    "Static Routing" \
    "Default Routing" \
    "Dynamic Routing" \
    "Routing Information Base" \
    "Forwarding Information Base" \
    "Control Plane and Data Plane" \
    "Distance Vector Routing" \
    "Link State Routing" \
    "Path Vector Routing" \
    "RIP Routing Protocol" \
    "OSPF Fundamentals" \
    "OSPF Areas" \
    "BGP Fundamentals" \
    "BGP Autonomous Systems" \
    "BGP Path Selection" \
    "Inter Domain Routing" \
    "Intra Domain Routing" \
    "Policy Based Routing" \
    "ECMP Routing" \
    "Multipath Routing" \
    "Routing Loops" \
    "Route Convergence" \
    "Route Redistribution" \
    "Traceroute and Routing Paths"

# ==================================================
# PACK 9 - TRANSPORT LAYER
# ==================================================

add_notes "Pack 9 (Transport Layer - TCP and UDP)" \
    "Transport Layer Fundamentals" \
    "TCP Segment Structure" \
    "TCP Header Fields" \
    "TCP Flags" \
    "SYN Flag" \
    "ACK Flag" \
    "FIN Flag" \
    "RST Flag" \
    "PSH and URG Flags" \
    "TCP Three Way Handshake" \
    "TCP Connection Termination" \
    "TCP State Machine" \
    "TCP Sequence Numbers" \
    "TCP Acknowledgments" \
    "TCP Retransmission" \
    "TCP Retransmission Timeout" \
    "TCP Sliding Window" \
    "TCP Flow Control" \
    "TCP Congestion Control" \
    "TCP Slow Start" \
    "TCP Congestion Avoidance" \
    "TCP Fast Retransmit" \
    "TCP Fast Recovery" \
    "TCP Selective Acknowledgment" \
    "TCP Delayed Acknowledgment" \
    "TCP Keepalive" \
    "TCP TIME WAIT State" \
    "TCP Connection Reset" \
    "TCP Head of Line Blocking" \
    "UDP Datagram Structure" \
    "UDP Header Fields" \
    "UDP Checksum" \
    "UDP Connectionless Communication" \
    "TCP vs UDP" \
    "QUIC Protocol" \
    "QUIC and HTTP 3" \
    "Ephemeral Ports" \
    "Well Known Ports" \
    "IANA Port Assignments" \
    "Port Ranges"

# ==================================================
# PACK 10 - DNS AND NAME RESOLUTION
# ==================================================

add_notes "Pack 10 (DNS and Name Resolution)" \
    "DNS Architecture" \
    "DNS Namespace" \
    "DNS Hierarchy" \
    "DNS Root Servers" \
    "Top Level Domains" \
    "Authoritative DNS Servers" \
    "Recursive DNS Resolvers" \
    "DNS Resolution Process" \
    "Iterative and Recursive Queries" \
    "DNS Resolver Caching" \
    "DNS TTL" \
    "DNS Resource Records" \
    "A Record" \
    "AAAA Record" \
    "CNAME Record" \
    "MX Record" \
    "NS Record" \
    "SOA Record" \
    "TXT Record" \
    "PTR Record" \
    "SRV Record" \
    "CAA Record" \
    "Reverse DNS Lookup" \
    "DNS Zone Files" \
    "DNS Zone Transfers" \
    "DNSSEC" \
    "DNS over HTTPS" \
    "DNS over TLS" \
    "Split Horizon DNS" \
    "DNS Load Balancing" \
    "DNS Troubleshooting"

# ==================================================
# PACK 11 - DHCP AND NETWORK CONFIGURATION
# ==================================================

add_notes "Pack 11 (DHCP and Network Configuration)" \
    "DHCP Fundamentals" \
    "DHCP Client Server Architecture" \
    "DHCP DORA Process" \
    "DHCP Discover" \
    "DHCP Offer" \
    "DHCP Request" \
    "DHCP Acknowledgment" \
    "DHCP Lease" \
    "DHCP Lease Renewal" \
    "DHCP Reservation" \
    "DHCP Options" \
    "DHCP Relay Agent" \
    "DHCPv6" \
    "Static IP Configuration" \
    "Dynamic IP Configuration" \
    "Network Configuration Management" \
    "IP Address Assignment" \
    "Default Gateway Configuration" \
    "DNS Server Configuration"

# ==================================================
# PACK 12 - APPLICATION LAYER PROTOCOLS
# ==================================================

add_notes "Pack 12 (Application Layer Protocols)" \
    "Application Layer Fundamentals" \
    "HTTP Protocol" \
    "HTTPS Protocol" \
    "FTP" \
    "FTPS" \
    "SFTP" \
    "SSH Protocol" \
    "Telnet" \
    "SMTP" \
    "POP3" \
    "IMAP" \
    "SNMP" \
    "NTP" \
    "LDAP" \
    "Kerberos" \
    "SMB Protocol" \
    "NFS Protocol" \
    "MQTT" \
    "AMQP" \
    "WebSocket" \
    "Server Sent Events" \
    "DNS Protocol" \
    "DHCP Protocol" \
    "RDP" \
    "Syslog Protocol" \
    "Protocol Port Reference"

# ==================================================
# PACK 13 - HTTP AND WEB NETWORKING
# ==================================================

add_notes "Pack 13 (HTTP and Web Networking)" \
    "HTTP Architecture" \
    "HTTP Request Lifecycle" \
    "HTTP Request Line" \
    "HTTP Response Line" \
    "HTTP Headers" \
    "HTTP Methods and Semantics" \
    "HTTP Safe Methods" \
    "HTTP Idempotency" \
    "HTTP Status Code Reference" \
    "HTTP Content Negotiation" \
    "MIME Types" \
    "Content Type and Content Length" \
    "HTTP Cookies and Sessions" \
    "HTTP Authentication Schemes" \
    "Basic Authentication" \
    "Bearer Authentication" \
    "HTTP Caching" \
    "Cache Control Directives" \
    "ETag and Conditional Requests" \
    "HTTP Redirects" \
    "HTTP Persistent Connections" \
    "HTTP Pipelining" \
    "HTTP 2 Multiplexing" \
    "HTTP 2 Server Push" \
    "HTTP 3 Architecture" \
    "HTTP Proxies" \
    "Reverse Proxy Architecture" \
    "CDN Architecture" \
    "Content Delivery Networks" \
    "WebSockets Handshake" \
    "CORS Protocol Mechanics" \
    "Browser Same Origin Policy" \
    "Cross Origin Requests" \
    "HTTP Compression" \
    "HTTP Request Body Streaming"

# ==================================================
# PACK 14 - TLS AND NETWORK SECURITY
# ==================================================

add_notes "Pack 14 (TLS and Network Security)" \
    "Network Security Fundamentals" \
    "Threats to Network Communication" \
    "Confidentiality Integrity and Availability" \
    "Symmetric Cryptography" \
    "Asymmetric Cryptography" \
    "Cryptographic Hash Functions" \
    "Digital Signatures" \
    "Public Key Infrastructure" \
    "Digital Certificates" \
    "Certificate Authorities" \
    "X.509 Certificates" \
    "Certificate Chain of Trust" \
    "Certificate Validation" \
    "TLS Fundamentals" \
    "TLS Handshake" \
    "TLS 1.2" \
    "TLS 1.3" \
    "TLS Cipher Suites" \
    "Perfect Forward Secrecy" \
    "SNI Server Name Indication" \
    "ALPN Application Layer Protocol Negotiation" \
    "Mutual TLS" \
    "Certificate Revocation" \
    "OCSP and OCSP Stapling" \
    "HSTS" \
    "IPsec Fundamentals" \
    "VPN Architecture" \
    "WireGuard" \
    "OpenVPN" \
    "Network Firewalls" \
    "Packet Filtering" \
    "Stateful Firewalls" \
    "DDoS Fundamentals" \
    "Network Intrusion Detection" \
    "Network Intrusion Prevention" \
    "ARP Spoofing" \
    "DNS Spoofing" \
    "Man in the Middle Attacks"

# ==================================================
# PACK 15 - LINUX NETWORKING / DEBIAN 13
# ==================================================

add_notes "Pack 15 (Linux Networking - Debian 13)" \
    "Linux Network Stack Architecture" \
    "Linux Network Interfaces" \
    "iproute2 Architecture" \
    "ip address" \
    "ip link" \
    "ip route" \
    "ip neigh" \
    "ip rule" \
    "ip netns" \
    "ss Command" \
    "Linux Socket API" \
    "Linux TCP Socket States" \
    "Linux Network Buffering" \
    "Linux Network Namespaces" \
    "Virtual Ethernet Pairs" \
    "Linux Bridge Networking" \
    "Linux Routing and Forwarding" \
    "IP Forwarding" \
    "Linux NAT with nftables" \
    "nftables Fundamentals" \
    "Netfilter Hooks" \
    "Connection Tracking" \
    "NetworkManager on Debian" \
    "systemd-networkd on Debian" \
    "Debian Network Configuration" \
    "Debian DNS Configuration" \
    "systemd-resolved on Debian" \
    "resolvectl" \
    "DHCP Client on Debian" \
    "Network Configuration with systemd" \
    "Linux TCP Tuning" \
    "Linux UDP Networking" \
    "Linux Firewall Configuration" \
    "Linux Network Services" \
    "OpenSSH Networking" \
    "Network Configuration with nmcli" \
    "Network Configuration with nmtui" \
    "Linux Network Troubleshooting"

# ==================================================
# PACK 16 - TROUBLESHOOTING AND ANALYSIS
# ==================================================

add_notes "Pack 16 (Network Troubleshooting and Analysis)" \
    "Network Troubleshooting Methodology" \
    "Troubleshooting with OSI Model" \
    "ping" \
    "traceroute" \
    "tracepath" \
    "mtr" \
    "ip route get" \
    "ss and Socket Inspection" \
    "netstat" \
    "lsof Network Inspection" \
    "nc and Netcat" \
    "ncat" \
    "telnet for Connectivity Testing" \
    "curl Network Diagnostics" \
    "wget Network Diagnostics" \
    "dig" \
    "nslookup" \
    "host Command" \
    "tcpdump Fundamentals" \
    "Wireshark Fundamentals" \
    "Packet Capture" \
    "Packet Filtering" \
    "BPF and Berkeley Packet Filter" \
    "Network Interface Statistics" \
    "ethtool" \
    "iperf3" \
    "Network Latency Testing" \
    "Packet Loss Diagnosis" \
    "MTU Troubleshooting" \
    "Path MTU Discovery" \
    "TCP Connection Troubleshooting" \
    "DNS Troubleshooting Methodology" \
    "Port Connectivity Troubleshooting" \
    "Firewall Troubleshooting" \
    "TLS Connection Troubleshooting" \
    "Network Performance Analysis"

# ==================================================
# PACK 17 - WIRELESS NETWORKING
# ==================================================

add_notes "Pack 17 (Wireless Networking)" \
    "Wireless Networking Fundamentals" \
    "IEEE 802.11 Standards" \
    "WiFi Architecture" \
    "Wireless Access Points" \
    "Wireless Stations" \
    "Infrastructure Mode" \
    "Ad Hoc Mode" \
    "SSID and BSSID" \
    "WiFi Frequency Bands" \
    "2.4 GHz WiFi" \
    "5 GHz WiFi" \
    "6 GHz WiFi" \
    "WiFi Channels" \
    "Channel Width" \
    "WiFi Signal Strength" \
    "RSSI and SNR" \
    "WiFi Authentication" \
    "WPA2" \
    "WPA3" \
    "WiFi Encryption" \
    "Wireless Roaming" \
    "Wireless Interference" \
    "WiFi Security" \
    "Linux Wireless Tools" \
    "iw Command" \
    "iwconfig" \
    "iwlist" \
    "rfkill" \
    "wpa_supplicant" \
    "NetworkManager WiFi Management"

# ==================================================
# PACK 18 - NETWORK ARCHITECTURE
# ==================================================

add_notes "Pack 18 (Network Architecture and Infrastructure)" \
    "Enterprise Network Architecture" \
    "Three Tier Network Architecture" \
    "Two Tier Network Architecture" \
    "Spine Leaf Architecture" \
    "Data Center Networking" \
    "Network Segmentation Architecture" \
    "VLAN Architecture" \
    "Subnet Design" \
    "DMZ Architecture" \
    "High Availability Networking" \
    "Network Redundancy" \
    "Link Aggregation Architecture" \
    "Load Balancer Architecture" \
    "Layer 4 Load Balancing" \
    "Layer 7 Load Balancing" \
    "Reverse Proxy vs Load Balancer" \
    "Content Delivery Network Architecture" \
    "Anycast Routing" \
    "Software Defined Networking" \
    "SDN Control Plane" \
    "Overlay Networks" \
    "VXLAN" \
    "MPLS Fundamentals" \
    "Network Automation" \
    "Infrastructure as Code for Networking" \
    "Network Documentation"

# ==================================================
# PACK 19 - BACKEND NETWORKING
# ==================================================

add_notes "Pack 19 (Backend Networking and Distributed Systems)" \
    "Backend Network Communication" \
    "Client Server Request Lifecycle" \
    "DNS Resolution in Backend Applications" \
    "TCP Connections in Java" \
    "Java Socket Programming" \
    "Java ServerSocket" \
    "Java NIO Networking" \
    "Blocking and Non Blocking IO" \
    "Java Network Channels" \
    "HTTP Client Networking" \
    "HTTP Connection Pooling" \
    "HTTP Keep Alive in Java" \
    "Spring Boot Embedded Server Networking" \
    "Tomcat Connector Configuration" \
    "Spring Boot Request Processing" \
    "Servlet Request Lifecycle" \
    "Backend Network Timeouts" \
    "Connection Timeout" \
    "Read Timeout" \
    "Write Timeout" \
    "Connection Pool Timeout" \
    "Retry and Backoff Strategies" \
    "Idempotent Network Requests" \
    "Network Failure Handling" \
    "Backend DNS Caching" \
    "Database Connection Networking" \
    "PostgreSQL Wire Protocol" \
    "PostgreSQL Client Server Communication" \
    "JDBC Network Communication" \
    "Connection Pooling with HikariCP" \
    "Database Network Latency" \
    "Redis Network Protocol" \
    "Message Broker Networking" \
    "RabbitMQ Network Communication" \
    "Kafka Network Communication" \
    "Microservices Network Communication" \
    "Service Discovery" \
    "API Gateway Networking" \
    "Service Mesh Networking" \
    "Distributed Tracing Across Services" \
    "Network Resilience Patterns"

# ==================================================
# PACK 20 - ADVANCED NETWORKING
# ==================================================

add_notes "Pack 20 (Advanced Networking)" \
    "Advanced TCP Internals" \
    "TCP Congestion Control Algorithms" \
    "TCP Cubic" \
    "BBR Congestion Control" \
    "TCP Window Scaling" \
    "TCP Timestamps" \
    "TCP Fast Open" \
    "TCP Keepalive Tuning" \
    "Socket Buffer Tuning" \
    "Network Kernel Tuning" \
    "Linux Network Queuing" \
    "Traffic Control tc" \
    "Quality of Service Classes" \
    "Traffic Shaping" \
    "Traffic Policing" \
    "Fair Queuing" \
    "Network Congestion Management" \
    "Advanced Routing Policy" \
    "Policy Routing with ip rule" \
    "Multipath TCP" \
    "QUIC Internals" \
    "eBPF Networking" \
    "XDP Fundamentals" \
    "DPDK Fundamentals" \
    "Network Virtualization" \
    "SR-IOV" \
    "RDMA Fundamentals" \
    "Network Time Synchronization" \
    "Precision Time Protocol" \
    "Network Protocol Analysis" \
    "Network Performance Engineering" \
    "High Performance Networking"

echo
echo "========================================"
echo " GENERATION SUMMARY"
echo "========================================"
echo "Root:    $ROOT"
echo "Created: $CREATED"
echo "Skipped: $SKIPPED"
echo "Dry run: $DRY_RUN"
echo "========================================"

if [[ "$DRY_RUN" == false ]]; then
    echo
    echo "Final package structure:"
    tree "$ROOT"
fi
