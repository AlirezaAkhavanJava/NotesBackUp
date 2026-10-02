
**ARP (Address Resolution Protocol)** is a network protocol used to map an IP address to a physical MAC address on a local network (LAN).

## The Problem It Solves

On a local network, devices communicate using **MAC addresses** (hardware addresses burned into network cards), but applications and users work with **IP addresses**. When a device wants to send data to another device on the same network, it knows the destination IP but needs the destination MAC address to actually deliver the frame. ARP bridges that gap.

## How It Works

1. **ARP Request (broadcast):** Device A wants to send data to IP `192.168.1.5`. It broadcasts a message to the whole local network asking: *"Who has 192.168.1.5? Tell me your MAC address."*

2. **ARP Reply (unicast):** The device that owns that IP responds directly: *"I have 192.168.1.5, and my MAC address is AA:BB:CC:DD:EE:FF."*

3. **Caching:** Device A stores this IP-to-MAC mapping in its **ARP cache** for a period of time (typically minutes), so it doesn't have to ask again for every packet.

## Key Points

- **Layer:** ARP operates between Layer 2 (Data Link) and Layer 3 (Network) of the OSI model.
- **Scope:** It only works within a single local network (broadcast domain). To reach a device on another network, the sender ARPs for the **default gateway's** MAC address instead.
- **Related protocols:**
  - **RARP** – reverse ARP (MAC → IP), largely obsolete
  - **NDP** – Neighbor Discovery Protocol, used in IPv6 instead of ARP
  - **Gratuitous ARP** – an unsolicited ARP used to detect conflicts or update caches

## Security Concern: ARP Spoofing

ARP has **no authentication**, so a malicious device can send fake ARP replies claiming "I have that IP" — this is called **ARP spoofing/poisoning**. It enables man-in-the-middle attacks, where traffic is intercepted or redirected. Defenses include **Dynamic ARP Inspection (DAI)** and **static ARP entries**.

## Quick Analogy

Think of ARP like asking in a crowded room: *"Who's named John?"* — everyone hears it, but only John answers and tells you where he's standing so you can hand him the package directly.


[[Networking]]