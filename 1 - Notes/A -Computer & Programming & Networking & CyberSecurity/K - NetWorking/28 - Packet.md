

## Packet
A **packet** is a small unit of data transmitted over a network. When data is sent, it is divided into packets, which travel independently from source to destination and are reassembled at the destination.

A packet typically has:

- **Header** – control information such as:
  - Source and destination IP addresses
  - Protocol type
  - Sequence number
  - Time-to-live (TTL)
- **Payload** – the actual data being sent
- **Trailer** (sometimes) – error-checking information such as a CRC

Example: When you load a webpage, your request and the webpage data are broken into packets and routed across the internet.

## If you literally mean “package”
In networking, **package** is not a standard data-unit term. It can mean:

- A **software package** used for networking, e.g. a network driver or `apt`/`npm` package.
- A **bundle of network services or protocols** offered together.
- In some programming contexts, a namespace/library for network operations, e.g. Java’s `java.net` package.

So: in data communication, the correct term is **packet**, not package.

---


## Anatomy of a Packet

A network packet is a small, formatted unit of data. It usually has three main parts:

### 1. Header
Control information used to deliver the packet:
- **Source address** – where it came from
- **Destination address** – where it is going
- **Protocol** – e.g., TCP, UDP, ICMP
- **Length** – size of the packet
- **TTL / Hop Limit** – limits how many routers it can pass through
- **Sequence / Identification info** – helps with ordering and reassembly
- **Checksum** – detects header corruption
- **Flags / Fragment offset** – used if the packet is fragmented

Example IPv4 header fields: Version, IHL, DSCP, Total Length, Identification, Flags, Fragment Offset, TTL, Protocol, Header Checksum, Source IP, Destination IP, Options.

### 2. Payload
The actual data being carried. This is often:
- a **TCP segment**
- a **UDP datagram**
- an **ICMP message**
- part of a file, webpage, video, etc.

### 3. Trailer
Not all packets have a trailer. At the link layer, an **Ethernet frame** ends with an **FCS/CRC** used for error detection.

Important distinction:
- **Layer 4:** TCP = segment, UDP = datagram
- **Layer 3:** IP = packet
- **Layer 2:** Ethernet = frame

So a packet is usually encapsulated inside a frame.

## How a Packet Works

1. **Segmentation**  
   The sender breaks data into smaller packets.

2. **Encapsulation**  
   Each layer adds its own header:  
   `Data → TCP/UDP header → IP header → Ethernet header/trailer → bits on wire`

3. **Routing**  
   Switches forward frames using MAC addresses inside a LAN.  
   Routers forward packets using IP addresses between networks.

4. **Forwarding**  
   Each router looks at the destination IP, checks its routing table, and sends the packet to the next hop.

5. **TTL decrement**  
   Every router reduces the TTL by 1. If TTL reaches 0, the packet is dropped. This prevents infinite loops.

6. **Fragmentation and MTU**  
   If a packet is too large for a link’s MTU, IPv4 can fragment it. IPv6 usually uses path MTU discovery instead. Fragments are reassembled at the destination.

7. **Independent travel**  
   Packets can take different paths and arrive out of order.

8. **Reassembly**  
   The destination uses sequence numbers — especially with TCP — to reorder packets and rebuild the original data.

9. **Error handling**  
   Checksums and frame checks detect corruption. Bad packets are usually dropped.  
   - TCP retransmits lost/corrupted packets.  
   - UDP does not guarantee delivery or order.

10. **Delivery**  
    Headers are stripped layer by layer, and the payload is passed to the application.

Simple analogy: a packet is like an envelope. The header is the address and delivery instructions, the payload is the letter inside, and routers are like postal sorting offices that pass it toward the destination.


[[Networking]]