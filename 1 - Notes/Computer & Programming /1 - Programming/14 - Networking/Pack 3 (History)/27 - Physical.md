

## 1. The basic definition

A network needs a physical way to move information from A → B.

There are two broad categories:

```text
                  DATA TRANSMISSION
                         │
              ┌──────────┴──────────┐
              │                     │
           WIRED                  WIRELESS
              │                     │
        physical medium          electromagnetic
            /cable                 waves
              │                     │
      ┌───────┼────────┐       ┌────┴────┐
      │       │        │       │         │
   Copper   Fiber    etc.    Wi-Fi    Cellular
      │       │                │         │
  electrical  light          radio     radio
   signals   pulses          waves     waves
```

So **yes**:

- Copper cables → electrical signals
    
- Fiber-optic cables → light
    
- Wi-Fi → radio waves
    
- Cellular → radio waves
    

But there's an important distinction:

> **Data is not inherently electricity or radio waves. Data is represented by physical signals.**

---

# 2. Wired connections

A **wired network** uses a physical cable between devices.

For example:

```text
PC ─────── Ethernet cable ─────── Router
```

The cable physically carries the signal.

There are several important types.

---

## 3. Copper cable

This is probably what you're imagining when you think "electrical wire."

Example:

**Ethernet**

```text
PC
 │
 │ electrical signal
 ▼
══════════════════════
      copper cable
══════════════════════
             │
             ▼
          Router
```

Inside an Ethernet cable are copper conductors.

The network hardware changes the electrical characteristics of the conductors according to the bits being transmitted.

Very simplified:

```text
voltage
  │
  │     ┌───┐       ┌───┐
  │     │   │       │   │
  │─────┘   └───────┘   └────
  │
  └──────────────────────────── time
```

The receiver measures the signal and reconstructs the transmitted bits.

### Common copper network cables

**Twisted pair**

Examples:

- Cat5e
    
- Cat6
    
- Cat6a
    
- Cat8
    

You'll commonly see:

```text
RJ45 connector
      │
      ▼
[ Cat6 Ethernet cable ]
```

These contain twisted copper pairs.

The twisting helps reduce electromagnetic interference and crosstalk.

---

# 4. Fiber optic cable

This is very different.

Fiber doesn't send the information as electrical current through the cable.

It sends **light**.

```text
Computer
   │
electrical data
   │
   ▼
Optical transceiver
   │
   │ light pulses
   ▼
════════════════════════════
       optical fiber
════════════════════════════
   │
   │ light
   ▼
Optical transceiver
   │
   │ electrical data
   ▼
Computer
```

Inside the fiber is extremely thin glass or plastic.

A transmitter converts electrical signals into optical signals.

The light travels through the fiber.

At the other end:

```text
light → electrical signal → network device
```

So:

> **Copper = electrical signaling**  
> **Fiber = optical signaling**

Fiber is extremely important for the Internet because it can carry enormous amounts of data over very long distances.

---

# 5. Wireless

Wireless doesn't require a physical conductor between the two endpoints.

Instead, information is encoded into **electromagnetic radiation**.

For Wi-Fi:

```text
Laptop
   │
   │ radio waves
   │ ))))))))))))))
   ▼
Wi-Fi Access Point
```

Those radio waves are electromagnetic waves.

They're the same broad physical phenomenon as:

- radio
    
- microwave
    
- infrared
    
- visible light
    
- ultraviolet
    
- X-rays
    

They simply occupy different frequency ranges.

Wi-Fi and cellular use particular radio-frequency bands.

---

# 6. So are radio waves "the Internet"?

No.

This distinction is extremely important.

Consider your phone:

```text
Phone
  │
  │ radio
  ▼
Cell tower
  │
  │ fiber/copper
  ▼
ISP network
  │
  │ fiber
  ▼
Internet
  │
  │ fiber
  ▼
Google server
```

Only part of the journey is wireless.

The Internet itself is a huge combination of technologies.

A request might travel:

```text
Phone
 ↓
Wi-Fi radio
 ↓
Router
 ↓
Fiber
 ↓
ISP
 ↓
Fiber
 ↓
Data center
 ↓
Ethernet/fiber
 ↓
Server
```

The **Internet is the interconnected network**, not a particular physical medium.

---

# 7. And yes — the oceans really have cables

This is one of the coolest things about the Internet.

There are **submarine fiber-optic cables running across oceans**.

For example:

```text
New York
   │
   │
   │  submarine fiber cable
   │
   └──────────────────────────┐
                              │
                         Atlantic
                           Ocean
                              │
                              │
                              ▼
                           Europe
```

They aren't science-fiction cables floating in the ocean.

They're physical fiber-optic cables laid across the seabed.

![Image](https://images.openai.com/static-rsc-4/7BE1sB4N9FwPyZZ6HnIv6xZWkrAHeDShXyQ3eYzaDCG4jxfd-CpTNemkYeF_zhiVgAPYTBNCU_JQUmGJbW7NTkECV4aH50Y3msieHgGE_At8Jpzvqat5A3OrCnwGc4HYwfGjfvxwDVT8el_57o3r0uCyTBiK3TB4JrC0ZVNA4b8Zhdu8oJd6_UJxfGOuHAmD?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/DQo6N5wot3cW2muJfS3zFDSt69VmuNBeb18Jq8b_RdxwGz8r_FVQFQXaw0Wf5SYgYyFU61EMard-p_680C1-NuC7w_678NrZSDvNSs813etJWEAlzcALOqesiLWISl6kTugBsUe5AdX-meEorCw3oCc2HVkmpOuoyoi719tpGXcEy0tP8Xik6EtbB2Q-sS1R?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/LXa9P0Ldre5E2_4Qz9Cmmgp_pLX_WPSMmqxtjr1IWORgg-vH6ON6ufmpFiT95Swi3e_QPc_6qt47709IfXQ61c2AlRfyTp8S00YmYphPjB3Bn5ymp3rLe9U1ljLAv4P0uoWNDmdNvjCyfsGbKFORGdLNNoQcF0rkAdN7-0BnMPxJ_RqPRKrD8PtNH3rsllaT?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/xHUoKkHlqwNwsIglXqrSsmgPfVmPHdUT5Tl8Bu633_HXIMTZj40ERGHXFFKVf6kBPH3Rtf451vwxgwXv06fRiox1c1OCESH5Gd1FD_TcKznHcvT_65QHj35GB6KYWVzBPn-tHCf8gbT0B0byMBmYbkLMrLGBLYwGxZkMQvDw3OIP7zohtjJjTiLq4UzQQrxE?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/KEGMyw5PXvgDcJjf438rljFooNdyWB8HoVsMfJzmfB8FbvcCgsRMbHeqlWiZ3f7d-p4V1dLQ7tPda-B5X1APb2vyriefIJ1BtCzoo5zg8drRW49K3mC5fsq0gK7uvvauBxpb_Kxjq4B7QdeEZEOIJivLJ0pZzPViaMt36ozdVV_OdQkv0Iv7OkjJMQOjuUDF?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/tc6vbOSJFJesEau38OApfjShSpNgmwG8CH3N2DKDv9cQERZbEwGlsttk7-Iez3AjB6y39TlrbHXsmncMDsnuy6KBfV_Ma57VAjcZkxVavgZrv0fOC-5ANKmPH57iSKKdBZv-L3RoRxUusYcLUVUuRBMTcGEv7fQKm10fmshROdULGWGGF7x-e5FefLV_BB2v?purpose=fullsize)

And they carry a huge amount of international Internet traffic.

---

# 8. What does a submarine cable actually look like?

It's not simply a giant glass fiber exposed to seawater.

A simplified cross-section looks something like:

```text
        ┌───────────────────────┐
        │ protective outer layer│
        │   ┌───────────────┐   │
        │   │ steel/wires   │   │
        │   │ ┌───────────┐ │   │
        │   │ │ insulation│ │   │
        │   │ │ ┌───────┐ │ │   │
        │   │ │ │ fiber │ │ │   │
        │   │ │ └───────┘ │ │   │
        │   │ └───────────┘ │   │
        │   └───────────────┘   │
        └───────────────────────┘
```

The actual construction varies depending on where the cable is deployed.

Near shore, cables need substantial protection because anchors, fishing equipment, and other hazards can damage them.

In deep ocean, the cable can be much lighter because it mainly needs to survive installation and the environment.

---

# 9. But how can light travel thousands of kilometers?

It doesn't travel through one uninterrupted piece of fiber forever.

Submarine cables contain **optical amplifiers/repeaters** at intervals.

Conceptually:

```text
Europe
  │
  │ fiber
  ▼
[Repeater]
  │
  │ fiber
  ▼
[Repeater]
  │
  │ fiber
  ▼
[Repeater]
  │
  │ fiber
  ▼
[Repeater]
  │
  ▼
USA
```

The optical signal becomes weaker as it travels.

Repeaters/amplifiers compensate for that loss.

Modern submarine systems can contain many fiber pairs and sophisticated optical transmission systems.

---

# 10. What about satellites?

That's another wireless path.

For example:

```text
Laptop
   ↓
Wi-Fi
   ↓
Router
   ↓
Satellite terminal
   ↓
📡 radio
   ↓
Satellite
   ↓
📡 radio
   ↓
Ground station
   ↓
Fiber
   ↓
Internet
```

So the Internet can use:

- copper
    
- fiber
    
- radio
    
- satellite links
    
- cellular
    
- Wi-Fi
    

depending on the particular section of the path.

---

# 11. The really important distinction

Don't think:

> "Wired = Internet"

or:

> "Wireless = Internet"

Instead think:

```text
                    NETWORK
                       │
          ┌────────────┴────────────┐
          │                         │
       WIRED                    WIRELESS
          │                         │
     ┌────┴────┐              ┌─────┴─────┐
     │         │              │           │
   Copper    Fiber          Wi-Fi      Cellular
     │         │              │           │
 electrical   light          radio       radio
  signals    signals         waves       waves
```

And above all of that is the **network protocol stack**:

```text
Application
    ↑
HTTP
    ↑
TCP / QUIC
    ↑
IP
    ↑
Ethernet / Wi-Fi / Cellular
    ↑
Physical medium
    ↑
copper / fiber / radio
```

That's why when you learned **TCP/IP**, **HTTP**, **Wi-Fi**, etc., you were learning different layers of the same system.

### Your physical Internet connection might literally be:

```text
Your laptop
   │
   │ Wi-Fi radio waves
   ▼
Home router
   │
   │ electrical Ethernet
   ▼
ISP equipment
   │
   │ optical fiber
   ▼
City network
   │
   │ fiber
   ▼
Submarine cable
   │
   │ fiber under Atlantic Ocean
   ▼
Europe
   │
   │ fiber
   ▼
Data center
   │
   │ Ethernet/fiber
   ▼
Server
```

**So yes: when you use the Internet, your data may physically travel through radio waves, electrical signals, and pulses of light during the same request.**

That is the mental model worth keeping.



[[Networking]]