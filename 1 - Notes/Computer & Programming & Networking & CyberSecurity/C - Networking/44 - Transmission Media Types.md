

**Transmission media** is the **physical or wireless path through which data signals travel between network devices**.

> It is the medium that carries a signal from a sender to a receiver.

For example:

```text
Computer ───── Ethernet cable ───── Switch
Computer  ))))) Wi-Fi / Radio ))))) Router
```

Transmission media is primarily associated with the **Physical Layer (Layer 1)** of networking.

---

# 1. Two Main Types

```text
Transmission Media
│
├── Guided Media
│   └── Uses a physical cable
│
└── Unguided Media
    └── Uses electromagnetic waves through air/space
```

---

# 2. Guided Media

**Guided media** uses a physical transmission path to guide the signal.

Also called **wired media**.

```text
Device ───────────── Cable ───────────── Device
```

The three major types are:

### A. Twisted-Pair Cable

Two insulated copper wires are twisted together to reduce interference.

```text
~~~~\ /~~~~\ /~~~~
     X     X
~~~~/ \~~~~/ \~~~~
```

Common Ethernet cables:

```text
Cat5e
Cat6
Cat6a
Cat7
Cat8
```

Used extensively in:

```text
PC → Switch
Router → Switch
Server → Switch
```

Advantages:

- inexpensive
    
- easy to install
    
- flexible
    
- widely used
    

Disadvantages:

- limited distance
    
- susceptible to electromagnetic interference compared with fiber
    

Two major forms:

```text
UTP = Unshielded Twisted Pair
STP = Shielded Twisted Pair
```

---

### B. Coaxial Cable

Uses a central conductor surrounded by insulation and shielding.

```text
┌───────────────────────┐
│ Outer shield          │
│  ┌─────────────────┐  │
│  │ Insulation      │  │
│  │   ┌─────────┐   │  │
│  │   │Conductor│   │  │
│  │   └─────────┘   │  │
│  └─────────────────┘  │
└───────────────────────┘
```

Historically important in computer networking and still widely used for:

- cable television
    
- cable Internet
    
- RF systems
    
- antennas
    

---

### C. Fiber-Optic Cable

Uses **light** rather than electrical signals.

```text
Device ═════════════════════ Device
             LIGHT
```

There are two principal types:

```text
Single-mode fiber
Multi-mode fiber
```

Fiber provides:

- very high bandwidth
    
- long transmission distances
    
- low signal loss
    
- immunity to electromagnetic interference
    

It is heavily used in:

```text
Internet backbone
Data centers
Telecommunications
Long-distance links
```

---

# 3. Unguided Media

**Unguided media** transmits signals through air or space rather than through a physical cable.

Also called **wireless media**.

```text
Device  ))))))))))))))  Device
          Radio waves
```

Common types include:

### A. Radio Waves

Used by technologies such as:

```text
Wi-Fi
Bluetooth
Cellular networks
Radio communication
```

Radio waves can travel through the air and, depending on frequency and environment, can penetrate some obstacles.

---

### B. Microwaves

High-frequency electromagnetic waves commonly used for:

```text
Point-to-point wireless links
Cellular infrastructure
Satellite communication
```

For many terrestrial microwave links, antennas need a reasonably clear **line of sight**.

---

### C. Infrared

Uses infrared electromagnetic radiation.

Example:

```text
Remote controls
Short-range communication
```

Infrared generally has shorter range and more restrictive propagation characteristics than radio.

---

### D. Satellite

Communication signals travel between Earth stations and satellites.

```text
Earth Station
      ↑
      │
      ▼
   Satellite
      │
      ▼
Earth Station
```

Useful for:

- wide-area communication
    
- broadcasting
    
- remote connectivity
    
- navigation systems
    

---

# 4. Guided vs Unguided

|Property|Guided|Unguided|
|---|---|---|
|Physical cable|Yes|No|
|Signal travels through|Cable|Air/space|
|Examples|Ethernet, fiber|Wi-Fi, cellular, satellite|
|Mobility|Limited|High|
|Installation|Requires cabling|Usually easier to deploy|
|Interference|Depends on cable|Often more exposed to environmental interference|
|Security|Physical access is generally required|Signals propagate through the surrounding environment|

---

# 5. Electrical vs Optical vs Radio

Another useful way to classify transmission media is by **what carries the information**:

```text
Copper
  ↓
Electrical signals

Fiber
  ↓
Light

Wireless
  ↓
Electromagnetic waves
```

For example:

```text
Ethernet over twisted pair
        ↓
Electrical signal

Fiber Ethernet
        ↓
Optical signal

Wi-Fi
        ↓
Radio signal
```

---

# 6. Important Characteristics

When comparing transmission media, networking engineers care about several properties:

### Bandwidth

How much data the medium can carry.

```text
Higher bandwidth
        ↓
Potentially higher data rate
```

### Attenuation

Signal weakening as it travels.

```text
Distance ↑
   ↓
Signal strength ↓
```

### Noise / Interference

Unwanted signals that affect communication.

Examples:

```text
Electrical interference
Radio interference
Crosstalk
```

### Propagation Delay

How long the signal takes to physically travel through the medium.

### Distance

Maximum practical transmission distance before regeneration, amplification, or other techniques are required.

### Cost

Includes:

```text
Cable
Connectors
Transceivers
Installation
Maintenance
```

---

# 7. Example: Your Ethernet Connection

Suppose your Debian machine is connected through:

```text
enp3s0
   │
   ▼
Ethernet cable
   │
   ▼
Router
```

Your network stack might look conceptually like:

```text
Application
     ↓
TCP / UDP
     ↓
IP
     ↓
Ethernet
     ↓
Electrical signal
     ↓
Twisted-pair cable
     ↓
Router
```

The **twisted-pair cable is the transmission medium**.

With Wi-Fi:

```text
Application
     ↓
TCP / UDP
     ↓
IP
     ↓
802.11 Wi-Fi
     ↓
Radio waves
     ↓
Access Point
```

The **radio waves are the transmission medium**.

---

# Mental Model

Think of networking as:

```text
Protocol
   ↓
Rules for communication

Address
   ↓
Where / who

Transmission medium
   ↓
What physically carries the signal
```

So:

```text
IP       → logical network addressing
MAC      → local-link addressing
Port     → transport endpoint
Protocol → communication rules
Medium   → physical path carrying the signal
```

The key distinction is:

> **A transmission medium doesn't define how the data is structured; it provides the path that carries the signal.**


[[Networking]]