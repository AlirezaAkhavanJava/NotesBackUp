
In networking, **throughput** is the actual rate at which data is successfully transmitted from one point to another over a network connection, typically measured in bits per second (bps), kilobits per second (Kbps), megabits per second (Mbps), or gigabits per second (Gbps).

## Key Points

**Definition:**
Throughput = the amount of data that actually moves through a network in a given amount of time.

**Throughput vs. Bandwidth:**
- **Bandwidth** = the *maximum* theoretical capacity of a link (e.g., a 1 Gbps Ethernet cable)
- **Throughput** = the *actual* data transferred, which is often lower than bandwidth due to real-world factors

**What reduces throughput below bandwidth:**
- Network congestion
- Protocol overhead (headers, acknowledgments)
- Latency and packet loss (causing retransmissions)
- Hardware limitations (CPU, NIC, routers)
- Interference (in wireless networks)

## Example
If you have a 100 Mbps connection but only download a file at 70 Mbps, your **bandwidth** is 100 Mbps and your **throughput** is 70 Mbps.

## Related Metrics
- **Goodput** – throughput excluding protocol overhead (only useful application data)
- **Latency** – delay in data transmission
- **Jitter** – variation in latency

In short, throughput measures how much data *actually* gets through, not how much *could* get through.


[[Networking]]