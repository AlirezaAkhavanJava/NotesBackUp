
**Layer 1 of the OSI model**, known as the **Physical Layer**, is the lowest layer in the Open Systems Interconnection reference model. It is responsible for the actual physical connection between devices and the transmission of raw, unstructured data bits across a communication medium.

Unlike upper layers that deal with logical data structures (frames, packets, segments), the Physical Layer deals exclusively with the electrical, mechanical, procedural, and functional aspects of activating, maintaining, and deactivating physical links.

### Key Responsibilities

*   **Bit Transmission:** Converts digital bits (0s and 1s) from the Data Link Layer (Layer 2) into signals appropriate for the transmission medium (e.g., electrical voltage changes, light pulses, or radio waves).
*   **Physical Medium & Connectors:** Defines the specifications for cables (copper, fiber optic), wireless frequencies, connectors (RJ45, USB-C, SFP), pin layouts, and voltage levels.
*   **Encoding & Modulation:** Determines how bits are represented on the wire (e.g., NRZ, Manchester encoding, QAM modulation).
*   **Transmission Mode:** Defines the direction of data flow: Simplex (one-way), Half-Duplex (two-way, not simultaneous), or Full-Duplex (two-way, simultaneous).
*   **Topology:** Defines the physical layout of the network (Bus, Star, Ring, Mesh).
*   **Synchronization:** Ensures the sender and receiver are synchronized at the bit level so the receiver knows when a bit starts and ends.

### Common Protocols and Standards
The Physical Layer encompasses hardware standards rather than software protocols. Examples include:
*   **Ethernet PHY standards:** 1000BASE-T, 10GBASE-SR, etc.
*   **Wireless standards:** IEEE 802.11 (Wi-Fi) RF specifications, Bluetooth radio layer, 5G NR physical layer.
*   **Serial/Interface standards:** RS-232, V.35, SONET/SDH, OTN.
*   **Cabling standards:** TIA/EIA-568 (twisted pair), ITU-T G.652 (single-mode fiber).

### Key Distinction
> ⚠️ **Important:** The Physical Layer does **not** understand frames, MAC addresses, or IP addresses. It has no concept of "data" beyond a stream of raw bits. Error detection/correction and framing are handled by Layer 2 (Data Link Layer). If a cable is unplugged or a signal is too weak, it is a Layer 1 issue.

### Troubleshooting Context
In network diagnostics, Layer 1 problems manifest as:
*   No link lights on NICs/switches
*   CRC errors or excessive collisions
*   Intermittent connectivity due to damaged cabling
*   Signal attenuation or electromagnetic interference (EMI)


[[Networking]]