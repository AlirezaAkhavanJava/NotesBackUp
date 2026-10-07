
 This is the next branch of the story: **wireless networking and cellular generations**. They solved a different problem from cloud/CDNs.

The central problem became:

> **How do we connect computers and phones to networks without physically plugging them into a cable?**

---

# 1. Wireless networking before Wi-Fi

Wireless communication is much older than the Internet.

The basic idea is:

```text
Digital data
    ↓
modulation
    ↓
radio waves
    ↓
air
    ↓
radio receiver
    ↓
digital data
```

Radio itself goes back to the late 19th/early 20th century, with foundational work by people such as Guglielmo Marconi.

But **wireless networking for computers** came much later.

---

# 2. Cellular networks came first

Mobile phones initially weren't Internet computers.

They were primarily:

```text
Phone
  ↓
Cellular network
  ↓
Telephone network
  ↓
Another phone
```

A geographic area was divided into **cells**.

```text
       Cell       Cell
     /─────\   /─────\
    /       \ /       \
   |   A     |   B     |
    \       / \       /
     \─────/   \─────/
```

Each cell had a **base station**.

As you moved, your phone could transfer its connection between cells. This is called **handover/handoff**.

---

# 3. 1G — first generation

**1G** appeared commercially in the 1980s.

The key feature:

> **Analog cellular voice.**

It was primarily for telephone calls.

```text
1G
 ↓
Analog
 ↓
Voice
```

No modern mobile Internet.

---

# 4. 2G — digital cellular

**2G** arrived in the 1990s.

The major transition:

```text
1G → analog voice

2G → digital voice
```

But 2G also introduced something extremely important:

## SMS

Short Message Service allowed phones to exchange short digital messages.

```text
Phone A
   ↓
SMS
   ↓
Cellular network
   ↓
Phone B
```

This was one of the first mass-market forms of digital mobile communication.

---

# 5. 2G also introduced mobile data

Technologies such as:

- GPRS
    
- EDGE
    

allowed phones to access packet-based data services.

Now:

```text
Phone
  ↓
Cellular network
  ↓
Internet
```

But speeds were extremely limited compared with modern broadband.

---

# 6. 3G — mobile Internet becomes practical

**3G** arrived around the turn of the millennium.

The goal was much more capable mobile data.

Now phones could increasingly support:

```text
Web browsing
Email
Multimedia
Mobile applications
Internet services
```

The important transition was:

```text
Mobile phone
     ↓
Mobile computer
```

---

# 7. Wi-Fi is a different thing

This distinction is extremely important:

> **Wi-Fi and cellular networks are not the same technology.**

Wi-Fi is primarily **local wireless networking**.

Cellular is designed for **wide-area mobile connectivity**.

### Wi-Fi

```text
Laptop ──┐
Phone ───┼──→ Wi-Fi Access Point ──→ Internet
Tablet ──┘
```

### Cellular

```text
Phone
  ↓
Cell tower
  ↓
Carrier network
  ↓
Internet
```

---

# 8. Where did Wi-Fi come from?

The technology behind modern Wi-Fi comes from the **IEEE 802.11** family of wireless LAN standards.

The first 802.11 standard was published in **1997**.

It defined wireless networking in the same broad family as Ethernet networking.

```text
Ethernet:

Computer ──cable──→ Switch

Wi-Fi:

Computer ──radio──→ Access Point
```

The original 802.11 was relatively slow.

---

# 9. Why was Wi-Fi needed?

Ethernet worked extremely well:

```text
PC ───── cable ───── Router
```

But imagine:

```text
Laptop
   │
   └────────────── 20-meter cable
```

Not convenient.

Wi-Fi allowed:

```text
Laptop
   )))))) radio ))))))
             ↓
        Access Point
             ↓
          Network
```

So the fundamental problem Wi-Fi solved was:

> **Local network connectivity without physical Ethernet cables.**

---

# 10. Why is it called Wi-Fi?

"Wi-Fi" is a **branding term**, not an acronym meaning "Wireless Fidelity."

The Wi-Fi Alliance popularized the term as a consumer-friendly brand for compatible IEEE 802.11 products.

Technically, when you say:

> "Wi-Fi"

you're generally talking about wireless LAN technology based on IEEE 802.11 standards.

---

# 11. Wi-Fi and Ethernet

The important relationship:

```text
                    LAN
                     │
          ┌──────────┴──────────┐
          ↓                     ↓
      Ethernet                Wi-Fi
          │                     │
       cable                  radio
          │                     │
          └──────────┬──────────┘
                     ↓
                 IP network
```

Both can ultimately carry IP packets.

For example:

```text
Laptop
  ↓
Wi-Fi
  ↓
Access Point
  ↓
Ethernet
  ↓
Router
  ↓
ISP
  ↓
Internet
```

This is why your browser doesn't fundamentally care whether you connected through Wi-Fi or Ethernet.

It eventually sees an IP network.

---

# 12. 4G — mobile broadband

Then came **4G**.

This was a major transition.

Mobile networks increasingly became **IP-based packet networks**.

Instead of thinking primarily:

```text
phone → telephone network
```

the architecture increasingly looked like:

```text
phone
  ↓
radio
  ↓
cellular network
  ↓
IP network
  ↓
Internet
```

4G made things like these much more practical:

- streaming
    
- video calls
    
- mobile apps
    
- social media
    
- mobile gaming
    
- cloud services
    

And this happened at almost exactly the same time smartphones were exploding.

---

# 13. The iPhone + 3G/4G combination

This is an important historical convergence.

You had:

```text
Web 2.0
   +
Social media
   +
Smartphones
   +
Mobile broadband
   +
App stores
```

Together:

```text
        Smartphone
             │
       ┌─────┴─────┐
       ↓           ↓
     Wi-Fi       Cellular
       │           │
       └─────┬─────┘
             ↓
          Internet
             ↓
       Cloud services
             ↓
      Social applications
```

The Internet stopped being primarily something you accessed from a **desk**.

It became something you carried.

---

# 14. 5G

**5G** is the fifth generation of cellular technology.

It began commercial deployment around **2019**, although deployments and standards evolved over several years.

The goals include:

```text
higher throughput
lower latency
greater capacity
more connected devices
more flexible network architecture
```

It isn't simply:

> "4G but faster."

5G also targets different classes of applications.

For example:

```text
5G
├── enhanced mobile broadband
├── massive IoT connectivity
└── low-latency/high-reliability use cases
```

---

# 15. The "G" does NOT mean GHz

This is a common misunderstanding.

```text
1G
2G
3G
4G
5G
```

The **G means Generation**.

It doesn't mean gigahertz.

For example:

```text
5G = fifth generation cellular technology
```

Frequency bands are a separate concept.

---

# 16. Cellular generations at a glance

|Generation|Approx. era|Main transition|
|---|---|---|
|**1G**|1980s|Analog mobile voice|
|**2G**|1990s|Digital voice + SMS|
|**3G**|2000s|Practical mobile data|
|**4G**|2010s|High-speed IP mobile broadband|
|**5G**|2020s|Higher capacity, speed, lower latency, massive device connectivity|

Don't treat these dates as exact worldwide boundaries; deployment happened at different times in different countries.

---

# 17. Wi-Fi generations

Wi-Fi has its own evolution, separate from 1G/2G/3G/4G/5G:

```text
802.11
  ↓
802.11b
  ↓
802.11a/g
  ↓
802.11n
  ↓
802.11ac
  ↓
802.11ax
  ↓
802.11be
```

These later generations are commonly branded:

```text
Wi-Fi 4  → 802.11n
Wi-Fi 5  → 802.11ac
Wi-Fi 6  → 802.11ax
Wi-Fi 7  → 802.11be
```

Again:

```text
Wi-Fi 6 ≠ 6G
```

They are completely different numbering systems.

---

# 18. What actually happens when your phone uses Wi-Fi?

Suppose you open:

```text
https://google.com
```

Your phone might do:

```text
Application
    ↓
HTTPS
    ↓
TCP / QUIC
    ↓
IP
    ↓
Wi-Fi
    ↓
Access Point
    ↓
Router
    ↓
ISP
    ↓
Internet
    ↓
Google
```

Notice something important:

**Wi-Fi is not replacing IP.**

It is one part of the lower networking stack used to move the packets over the local wireless link.

Similarly, cellular radio is another access technology.

---

# 19. The complete historical progression

Now our timeline becomes:

```text
1960s
Packet switching
      ↓
1969
ARPANET
      ↓
1970s
TCP/IP
      ↓
1983
DNS
      ↓
1989–90
World Wide Web
      ↓
1990s
Commercial Web
      ↓
Late 1990s
Search engines
      ↓
2000s
Web 2.0
      ↓
Social networks
      ↓
2007
Smartphone revolution
      ↓
3G / mobile Internet
      ↓
2010s
4G
      ↓
Cloud + mobile + social
      ↓
2020s
5G + cloud + IoT + distributed systems
```

And there's a beautiful underlying pattern:

```text
First:
Connect computers.

Then:
Connect documents.

Then:
Connect people.

Then:
Connect mobile devices.

Then:
Connect almost everything.
```

That last stage leads directly into **IoT, Bluetooth, GPS, NFC, smart devices, edge computing, and eventually today's Internet of Things**.



[[Networking]]