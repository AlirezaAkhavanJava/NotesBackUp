




## Side-by-side comparison

| Aspect | OSI | TCP/IP |
|---|---|---|
| Full name | Open Systems Interconnection | Transmission Control Protocol / Internet Protocol |
| Created by | ISO | DARPA / ARPANET community |
| Time | Late 1970s–1980s | 1970s, deployed earlier |
| Design approach | Model first, then protocols | Protocols first, then model |
| Layers | 7 | 4 (or 5 in teaching models) |
| Governance | ISO committees, formal standards | IETF, “rough consensus and running code” |
| Complexity | Complex, many options | Simpler, pragmatic |
| Connection style | Supports connection-oriented and connectionless at multiple layers | IP is connectionless; TCP is connection-oriented; UDP is connectionless |
| Example protocols | X.25, X.400, X.500, FTAM, CMIP, TP4, CLNP | IP, TCP, UDP, HTTP, DNS, SMTP, SSH |
| Adoption | Limited, mostly government/telecom attempts | Global, runs the internet |
| Fate | Protocols largely faded; model survives | Protocols and model dominate |

---

## Layer mapping diagram

```
OSI 7-Layer                     TCP/IP 4-Layer              TCP/IP 5-Layer
+---------------------+         +---------------------+     +---------------------+
| 7 Application       |         |                     |     | Application         |
| 6 Presentation      |  ---->  | Application         |     |                     |
| 5 Session           |         |                     |     |                     |
+---------------------+         +---------------------+     +---------------------+
| 4 Transport         |  ---->  | Transport           |     | Transport           |
+---------------------+         +---------------------+     +---------------------+
| 3 Network           |  ---->  | Internet            |     | Network             |
+---------------------+         +---------------------+     +---------------------+
| 2 Data Link         |         |                     |     | Data Link           |
| 1 Physical          |  ---->  | Network Access      |     | Physical            |
+---------------------+         +---------------------+     +---------------------+
```

Key mapping:

- **OSI Application + Presentation + Session** → **TCP/IP Application**
- **OSI Transport** → **TCP/IP Transport**
- **OSI Network** → **TCP/IP Internet**
- **OSI Data Link + Physical** → **TCP/IP Network Access**
- The **5-layer TCP/IP model** is just the 4-layer model with Network Access split into Data Link and Physical.

---

## Why TCP/IP won

1. **It was already working.**  
   TCP/IP was deployed on ARPANET and Unix systems before OSI was fully standardized.

2. **It was simpler and more practical.**  
   OSI was designed by committee and tried to cover everything. TCP/IP focused on solving real internetworking problems.

3. **It was free and open.**  
   TCP/IP implementations spread freely, especially with Unix. OSI protocols were often complex, expensive, and tied to telecom/government procurement.

4. **Bottom-up vs top-down.**  
   TCP/IP grew from working code. OSI was designed as a grand model first, then protocols were specified.

5. **The Internet exploded.**  
   Once the web and global internet took off, TCP/IP was already the default. OSI never caught up.

6. **IETF culture.**  
   “Rough consensus and running code” beat slow formal committee processes.

---

## Why OSI still matters

Even though OSI protocols lost, the OSI model is still useful:

- It gives a **common vocabulary**: Layer 1, Layer 2, Layer 3, Layer 7.
- It helps with **troubleshooting**: “Is this a Layer 2 problem or a Layer 3 problem?”
- It separates concerns: physical, data link, network, transport, session, presentation, application.
- It is used in **certifications and teaching**.
- Some OSI ideas influenced later protocols: X.500 influenced LDAP, and IS-IS is an OSI-derived routing protocol still used in some networks.

---

## Who won?

| Category | Winner |
|---|---|
| Protocol suite that runs the internet | **TCP/IP** |
| Actual deployed global networking | **TCP/IP** |
| Layered reference model in textbooks | **OSI** |
| Common network terminology | **OSI** |
| Practical implementation and vendor support | **TCP/IP** |

**Final verdict:**  
**TCP/IP won the war. OSI won the peace.**  
TCP/IP runs the internet, but OSI still provides the map we use to talk about it.


[[Networking]]