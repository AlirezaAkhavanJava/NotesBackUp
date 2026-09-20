## What is a MAC Address?

A **MAC address** (Media Access Control address) is a **unique, permanent identifier** assigned to every network interface card (NIC) or network-capable device at the hardware level. It operates at the **Data Link Layer (Layer 2)** of the OSI model.

### Key Characteristics:
- **Format**: 48 bits (6 bytes), written as 12 hexadecimal digits
  - Example: `00:1A:2B:3C:4D:5E` or `00-1A-2B-3C-4D-5E`
- **Structure**:
  - First 3 bytes = **OUI** (Organizationally Unique Identifier) – identifies the manufacturer
  - Last 3 bytes = **NIC-specific** – unique serial number assigned by the manufacturer
- **Uniqueness**: Intended to be globally unique (though spoofing is possible)
- **Permanence**: Burned into the hardware (though software can override it)

---

## What Problems Does a MAC Address Solve?

### 1. **Physical Device Identification on a Local Network**
- Problem: On a LAN, devices need a way to be uniquely identified regardless of what software or IP they use.
- Solution: MAC addresses provide a **hardware-level identity** that doesn't change when a device moves or reboots.

### 2. **Frame Delivery Within a LAN (Layer 2 Communication)**
- Problem: Ethernet/Wi-Fi frames need source and destination addresses to reach the correct device on the same local network.
- Solution: MAC addresses are used in the **frame header** so switches can forward data to the exact physical port/device.

### 3. **Switching and Forwarding Decisions**
- Problem: A switch needs to know which port a device is connected to without manual configuration.
- Solution: Switches build a **MAC address table** by learning source MACs, enabling intelligent forwarding instead of broadcasting everything.

### 4. **Avoiding IP Address Conflicts at Layer 2**
- Problem: Two devices could accidentally have the same IP, causing confusion at Layer 3.
- Solution: Even with duplicate IPs, MAC addresses allow the network to distinguish physical devices.

### 5. **DHCP Address Assignment**
- Problem: A DHCP server needs a way to consistently assign the same IP to a specific device.
- Solution: MAC addresses can be used for **DHCP reservations**, ensuring a device always gets the same IP.

### 6. **Access Control and Security (Filtering)**
- Problem: Network administrators may want to allow only specific devices onto a network.
- Solution: **MAC filtering** (allow/deny lists) can restrict network access based on hardware address.

### 7. **Wake-on-LAN (WoL)**
- Problem: How do you remotely power on a shut-down computer?
- Solution: A special "magic packet" containing the target's MAC address is broadcast on the LAN to wake it.

---

## Summary Table

| Problem | How MAC Address Solves It |
|---------|---------------------------|
| Device identification on LAN | Unique hardware-level ID |
| Frame delivery at Layer 2 | Source/destination in frame header |
| Switch forwarding | MAC address table learning |
| IP conflict confusion | Distinguishes physical devices |
| DHCP consistency | MAC-based reservations |
| Network access control | MAC filtering |
| Remote wake-up | Wake-on-LAN magic packet |

---

**In short**: A MAC address solves the fundamental problem of **uniquely identifying and delivering data to specific physical devices on a local network**, independent of logical (IP) addressing.


[[Networking]]