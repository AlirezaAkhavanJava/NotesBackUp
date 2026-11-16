

Everything we talked about — the HTTP text, the TCP segments — exists as actual binary data (1s and 0s) sitting in RAM at some point. But RAM holds data as electrical charge in capacitors; it doesn't "send" anything by itself. To get those bits from your server's RAM into another machine's RAM across a cable or through the air, something has to convert each bit into a physical, measurable signal — a voltage level, a pulse of light, or a radio wave — send that signal across a medium, and then have the receiving end convert it back into bits. That conversion step is the **physical layer**, and it's the lowest, most literal layer of networking: everything above it (HTTP, TCP, IP) is just an agreement about how to _interpret_ bits, but the physical layer is the only place where bits actually become something physics can carry.

### How a wire represents a bit

A copper Ethernet cable doesn't send "1" and "0" as abstract symbols — it sends **voltage over time**. The simplest scheme you could imagine is: high voltage = 1, low voltage (or zero) = 0. This is called **NRZ (Non-Return-to-Zero)** encoding. The problem with it is timing: if you send a long run of 1s, the voltage just sits high the whole time, and the receiver has no way to tell where one bit ends and the next begins — there's no "edge" to lock onto.

Real Ethernet solves this with line codes designed to guarantee frequent voltage transitions, so the receiver's clock can stay synchronized with the sender's clock purely by watching the signal itself (no separate "clock wire" exists). Two concrete examples:

- **Manchester encoding** (used in old 10BASE-T Ethernet): every bit is represented as a _transition_, not a level. A 1 is a low-to-high transition in the middle of the bit period; a 0 is high-to-low. This guarantees a transition every single bit, at the cost of needing twice the raw signaling rate for the same data rate.
- **4B5B / MLT-3** (used in 100BASE-TX Fast Ethernet): groups of 4 data bits get mapped to 5-bit symbols chosen specifically so no symbol has too many consecutive identical bits, then those symbols are sent using 3 voltage levels (-1, 0, +1) instead of 2, which reduces the signal's high-frequency energy and radiated interference.

Modern Gigabit Ethernet (1000BASE-T) goes further — it uses **PAM-5** (5 voltage levels per symbol) and actually sends and receives on all 4 wire pairs simultaneously, in both directions at once, using digital signal processing to cancel out the "echo" of its own transmission so it can hear the other side's signal on the same pair.

The twisting of the pairs inside the cable (twisted pair) isn't cosmetic — each pair is twisted at a different rate specifically so that electromagnetic interference hits both wires in a pair almost equally, and since the receiver reads the _difference_ between the two wires (differential signaling), that common interference cancels out.

### Fiber: the same idea, with light instead of voltage

Fiber-optic cable has no electrical signal at all — it sends pulses of light down a thin glass strand. A laser or LED turns on and off (or varies intensity/phase) to represent bits, and a photodetector on the other end converts light intensity back into an electrical signal the NIC's circuitry can process. Light is used over long distances because it doesn't suffer the same resistance-based attenuation and electromagnetic interference that copper does, so it can travel kilometers between repeaters instead of meters.

### Wireless: bits riding on a radio wave

With no physical medium at all, Wi-Fi has to encode bits onto a radio wave by modulating one of the wave's properties — its amplitude, frequency, or phase. Simple schemes shift between two states (e.g. two phases = 1 bit per symbol); modern Wi-Fi uses **QAM (Quadrature Amplitude Modulation)**, which varies both amplitude and phase together to pack multiple bits into a single symbol — Wi-Fi 6 uses 1024-QAM, meaning each symbol encodes 10 bits by distinguishing between 1024 combinations of amplitude and phase. On top of that, Wi-Fi uses **OFDM (Orthogonal Frequency-Division Multiplexing)**, splitting the channel into dozens of narrow sub-carriers sent in parallel, which is what makes it robust against interference on any single frequency.

The point that matters for your question: wired and wireless are solving the _exact same problem_ — "how do I represent a stream of bits as a physical phenomenon, and recover those bits reliably on the other end" — they just use different physical phenomena (voltage, light, radio) and different encoding tricks suited to each medium's weaknesses (interference, attenuation, multipath reflection for wireless).

### How the receiver knows where one message starts and another begins

A raw electrical or radio signal is continuous — there's no gap between bits to tell you "this is where a new message starts." This is solved one layer up, by **framing**, which belongs to the Data Link layer (Ethernet). An Ethernet frame has a fixed, known structure:

```
Preamble (7 bytes) | SFD (1 byte) | Dest MAC (6) | Src MAC (6) | EtherType (2) | Payload (46–1500) | FCS/CRC (4)
```

- The **Preamble** is a repeating `10101010...` pattern whose only job is to let the receiver's clock-recovery circuitry lock onto the sender's exact bit timing before any real data arrives.
- The **SFD (Start Frame Delimiter)** is one specific byte pattern (`10101011`) that breaks the repeating preamble — the instant the receiver sees that exact pattern, it knows "the next bit is the real start of the frame," and everything from there is counted according to the fixed field layout above.
- The **FCS (Frame Check Sequence)** at the end is a CRC checksum computed over the frame's contents; the receiver recomputes it from the bits it received and compares — if they don't match, the frame was corrupted in transit (interference, a bad cable) and gets silently discarded, relying on TCP further up the stack to notice the missing data and retransmit.

So "knowing where the message is" isn't magic pattern recognition — it's a strict, pre-agreed byte layout, with specific marker bytes whose whole purpose is to be unambiguous boundaries.

### How it climbs back up to something your server understands

This is where everything connects to what we covered with the HTTP/TCP/IP diagram — it's a strict encapsulation chain, and the receiving side just peels it apart one layer at a time:

1. The **NIC (Network Interface Card)** is the piece of hardware that actually does the physical-layer conversion — it has the circuitry (PHY chip) that demodulates voltage/light/radio back into raw bits, and the framing logic (MAC chip) that recognizes the preamble/SFD and assembles those bits into a complete Ethernet frame.
2. Once it has a full frame, the NIC uses **DMA (Direct Memory Access)** to write that frame's bytes directly into a reserved region of your server's RAM — without needing the CPU to shuttle each byte over, which would be far too slow.
3. The NIC then raises a **hardware interrupt**, which tells the CPU "stop what you're doing, there's a frame waiting in RAM for you."
4. The CPU runs the OS's **network driver**, which reads the Ethernet header, checks the FCS, and strips the Ethernet framing off — leaving just the IP packet that was inside the payload.
5. The OS kernel's **TCP/IP stack** takes over from there: it reads the IP header (checking the destination IP matches this machine), strips it, and passes what's left — a TCP segment — to the TCP layer. TCP reads the **port number** in its header, which is exactly how the kernel decides _which process_ on the machine this data belongs to (port 8080 → your Spring Boot process, port 5432 → PostgreSQL, etc.).
6. TCP hands the remaining bytes to that process's **socket buffer** — and this is the exact point where your earlier question connects: Tomcat's internal accept/read loop is sitting there blocked on that socket, reading bytes out of that buffer. Those bytes are the raw HTTP text — `GET /users/5 HTTP/1.1\r\nHost: ...` — and only _now_, after all of that, does Tomcat begin parsing it into an `HttpServletRequest` object.

So the short version of "how does the server realize what it is": it doesn't figure it out by inspecting the signal — it trusts a strict chain of headers, each one written by a specific layer and read by the matching layer on the other end, each layer stripping its own header before handing the rest upward. The NIC and OS never need to understand HTTP at all; they just keep passing payload upward until it lands in the one process that's listening on the right port, and _that_ process is the first one that actually parses the text as HTTP.




[[Networking]]
[[Spring Framework]]