
## Latency (Networking)

**Latency** is the **time delay** between the moment data is sent and the moment it is received at its destination. In networking, it is usually measured in **milliseconds (ms)**.

More precisely, latency is the **end-to-end delay** a packet experiences as it travels from source to destination. It is not the same as bandwidth or speed of the connection.

---

## Main Components of Latency

Total latency along a path is the sum of several delays:

**Latency = Processing + Queuing + Transmission + Propagation**

| Component | Definition | Typical Cause |
|---|---|---|
| **Processing delay** | Time a router, switch, or NIC takes to examine the packet header and decide where to forward it. | Device CPU, lookup tables, firewall inspection. |
| **Queuing delay** | Time a packet waits in a buffer before it can be transmitted. | Network congestion; more traffic than link capacity. |
| **Transmission delay** | Time to push all the packet’s bits onto the link. | Packet size ÷ link bandwidth. Larger packets or slower links increase it. |
| **Propagation delay** | Time for the signal to physically travel through the medium. | Distance ÷ speed of signal in the medium. Fiber/copper ≈ 2×10⁸ m/s. |

Formula examples:
- **Transmission delay** = packet size (bits) / link rate (bits per second)
- **Propagation delay** = distance / propagation speed

Queuing delay is usually the most variable and is often the largest cause of unpredictable latency.

---

## Round-Trip Time (RTT)

**RTT** is the time for a packet to go from source to destination **and back again**.

RTT ≈ one-way latency × 2 + processing delays

Tools like `ping` measure RTT. When people say “ping is 20 ms,” they usually mean the round-trip time is 20 ms.

---

## Latency vs Bandwidth / Throughput

These are different:

- **Latency** = how long it takes one bit or packet to arrive.
- **Bandwidth** = how much data can be sent per second.
- **Throughput** = actual achieved data rate.

A link can have **high bandwidth** but still **high latency**. For example, a satellite link may have high bandwidth but 500+ ms latency due to distance.

Analogy:  
- Bandwidth is the width of a pipe.  
- Latency is how long water takes to travel through the pipe.

---

## Jitter

**Jitter** is the **variation in latency** between packets. If packets arrive with 10 ms, 12 ms, 11 ms delays, jitter is low. If they arrive with 10 ms, 80 ms, 30 ms delays, jitter is high.

High jitter hurts real-time applications like:
- VoIP calls
- Video conferencing
- Online gaming
- Live streaming

---

## Common Causes of High Latency

- Long physical distance
- Many router hops
- Network congestion
- Slow or overloaded devices
- Wireless interference
- Satellite links
- Bufferbloat
- Retransmissions from packet loss
- Protocol overhead, e.g., TCP handshakes, DNS lookups

---

## How Latency Is Measured

- **ping** – measures RTT to a host.
- **traceroute / mtr** – shows latency per hop along a path.
- **One-way latency** – requires synchronized clocks at both ends, so it is harder to measure accurately.

---

## Why Latency Matters

Low latency is critical for:
- Real-time voice and video
- Online gaming
- Financial trading
- Remote control systems
- Web page loading speed

High latency makes applications feel slow and can break real-time communication.

**In short:** latency is the delay data experiences traveling across a network. It is made up of processing, queuing, transmission, and propagation delays, and it is different from bandwidth.


[[Networking]]