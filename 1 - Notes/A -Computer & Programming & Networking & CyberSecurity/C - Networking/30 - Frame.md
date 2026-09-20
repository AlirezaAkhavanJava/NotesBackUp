
## Frame (Networking)

A **frame** is a **Layer 2 (Data Link Layer) Protocol Data Unit (PDU)**. It encapsulates a Layer 3 packet so it can be transmitted across a specific local network link, such as Ethernet, Wi-Fi, PPP, or HDLC.

Simple distinction:
- **Layer 4:** TCP = segment, UDP = datagram
- **Layer 3:** IP = packet
- **Layer 2:** Ethernet = frame

So a **packet is carried inside a frame** on a local link.

---

## What a Frame Does

A frame provides the structure needed to move data across a local network link. It:

1. **Framing / delimiting**  
   Marks where a transmission unit starts and ends, so the receiver knows what bits belong together.

2. **Local addressing**  
   Uses MAC addresses to identify the source and destination network interfaces on the same link.

3. **Encapsulation**  
   Carries a network-layer packet inside its payload.

4. **Protocol identification**  
   Tells the receiver what upper-layer protocol is inside, e.g. IPv4, IPv6, ARP.

5. **Error detection**  
   Uses a checksum / CRC to detect corrupted frames. Bad frames are usually dropped.

6. **Media access control**  
   Helps control how devices share a physical medium, e.g. CSMA/CD in old Ethernet, CSMA/CA in Wi-Fi, or full-duplex switching in modern Ethernet.

7. **Optional VLAN and QoS tagging**  
   Supports VLANs and priority handling with 802.1Q tags.

---

## What Problem a Frame Solves

At the physical layer, a network only sends raw bits: `101011000...`. That raw bit stream has several problems:

- There are **no boundaries** — the receiver does not know where one message ends and the next begins.
- There is **no local addressing** — the receiver does not know which device on the link should get the data.
- There is **no error detection** — corrupted bits may go unnoticed.
- There is **no protocol multiplexing** — the receiver does not know whether the payload is IPv4, IPv6, ARP, etc.
- Multiple devices on a shared medium need a way to **coordinate access**.

A frame solves these problems by adding a header and trailer around the packet, giving the link layer a well-defined format for local delivery.

---

## Internal Structure of an Ethernet Frame

The most common example is an **Ethernet II frame**. On the wire, it looks roughly like this:

```
[ Preamble | SFD | Dest MAC | Src MAC | Type/Length | Payload | FCS ]
```

With optional VLAN tagging:

```
[ Preamble | SFD | Dest MAC | Src MAC | 802.1Q Tag | Type/Length | Payload | FCS ]
```

### Field Definitions

| Field | Typical Size | Definition / Purpose |
|---|---:|---|
| **Preamble** | 7 bytes | Alternating 1s and 0s used by the receiver to synchronize its clock with the incoming signal. |
| **SFD** (Start Frame Delimiter) | 1 byte | Usually `10101011`; marks the actual start of the frame. |
| **Destination MAC** | 6 bytes | 48-bit MAC address of the intended receiver on the local link. Can be unicast, multicast, or broadcast (`FF:FF:FF:FF:FF:FF`). |
| **Source MAC** | 6 bytes | 48-bit MAC address of the sending network interface. |
| **802.1Q VLAN Tag** (optional) | 4 bytes | Adds VLAN ID, priority, and discard eligibility. TPID is usually `0x8100`. |
| **EtherType / Length** | 2 bytes | If value ≥ `0x0600`, it identifies the upper-layer protocol: `0x0800` = IPv4, `0x86DD` = IPv6, `0x0806` = ARP. If ≤ 1500, it indicates payload length in older 802.3 framing. |
| **Payload / Data** | 46–1500 bytes | The encapsulated Layer 3 packet, such as an IP packet. Minimum 46 bytes; maximum 1500 bytes by default (MTU). |
| **Pad** | 0–46 bytes | Zeros added if the payload is too small to meet the minimum frame size. |
| **FCS** (Frame Check Sequence) | 4 bytes | 32-bit CRC used for error detection. If the receiver’s calculation does not match, the frame is discarded. |
| **Interframe Gap** (not part of frame) | 12 bytes / 96 bit times | Idle time between frames so receivers can prepare for the next frame. |

Typical Ethernet frame size:
- **Minimum:** 64 bytes from Destination MAC to FCS.
- **Maximum:** 1518 bytes without VLAN tagging; 1522 bytes with an 802.1Q tag.
- Preamble and SFD are additional on the wire.

---

## How a Frame Works

1. **A Layer 3 packet is created** — for example, an IP packet.
2. **Layer 2 encapsulates it** — the packet becomes the payload of a frame.
3. **MAC addresses are added** — source and destination addresses for the local link.
4. **FCS is calculated** — for error detection.
5. **The frame is transmitted** — bits go out over the physical medium.
6. **A switch receives the frame** — it reads the destination MAC address and forwards the frame out the correct port.
7. **The receiver checks the FCS** — if valid, it strips the Layer 2 header and passes the packet to Layer 3.
8. **At each router hop, the frame changes** — the old Layer 2 frame is removed, and a new frame is built for the next link. The IP packet inside usually stays the same.

---

## Frame vs Packet

| Feature | Frame | Packet |
|---|---|---|
| Layer | Layer 2, Data Link | Layer 3, Network |
| Addressing | MAC addresses | IP addresses |
| Scope | Local link / same network segment | End-to-end across networks |
| Example | Ethernet frame, Wi-Fi frame | IPv4 packet, IPv6 packet |
| Device that forwards | Switch | Router |
| Error detection | FCS / CRC | Header checksum in IPv4; no checksum in IPv6 |

In short: a **frame** is the Layer 2 envelope that carries a packet across a local link. It gives data boundaries, local addressing, protocol identification, error detection, and media access control.


[[Networking]]
