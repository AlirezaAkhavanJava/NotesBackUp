
These six concepts fit together very naturally. They are basically the next stage of the story we were building:

```text
Internet
   ↓
Wireless networking
   ↓
Smartphones
   ↓
Sensors + tiny computers
   ↓
IoT
   ↓
Bluetooth / Wi-Fi / cellular / NFC
   ↓
Cloud + edge computing
```

## 1. IoT — Internet of Things

**Definition:** IoT is the concept of connecting physical objects to networks so they can **sense, communicate, and/or act**.

An IoT device usually contains:

```text
┌─────────────────────┐
│     IoT DEVICE      │
│                     │
│  Sensor             │
│     ↓               │
│  Microcontroller    │
│     ↓               │
│  Network interface  │
│     ↓               │
│  Internet           │
└─────────────────────┘
```

For example, a smart temperature sensor:

```text
Temperature
    ↓
Sensor
    ↓
Microcontroller
    ↓
Wi-Fi
    ↓
Router
    ↓
Internet
    ↓
Cloud server
    ↓
Database
```

The important part is that **IoT isn't a particular protocol or technology**.

It's a category/architecture.

IoT devices can communicate using:

- Wi-Fi
    
- Bluetooth
    
- Ethernet
    
- cellular
    
- Zigbee
    
- LoRaWAN
    
- Thread
    
- MQTT
    
- HTTP
    
- CoAP
    
- etc.
    

### Example

A smart thermostat might do:

```text
Temperature = 28°C
        ↓
Device sends:
{
    "temperature": 28
}
        ↓
Server
        ↓
Database
```

Then your phone requests the temperature:

```text
Phone
  ↓ HTTPS
API
  ↓
Database
  ↓
28°C
```

---

# 2. Bluetooth

**Definition:** Bluetooth is a short-range wireless communication technology designed primarily for connecting nearby devices.

Think:

```text
Phone ←──── Bluetooth ────→ Headphones
```

Unlike Wi-Fi, Bluetooth generally isn't intended to provide your device with Internet access.

Its original problem was:

> "How do we connect nearby electronic devices without cables?"

Examples:

- headphones
    
- keyboards
    
- mice
    
- game controllers
    
- watches
    
- speakers
    
- sensors
    

### Bluetooth vs Wi-Fi

||Bluetooth|Wi-Fi|
|---|---|---|
|Main purpose|Device-to-device|Network/Internet access|
|Range|Usually shorter|Usually longer|
|Power consumption|Can be very low|Usually higher|
|Bandwidth|Lower|Higher|
|Example|Watch → phone|Laptop → router|

Bluetooth Low Energy (**BLE**) is particularly important for IoT.

A small sensor can run for months or years on a small battery because it doesn't need to continuously transmit large amounts of data.

---

# 3. GPS

**Definition:** GPS is a satellite-based positioning system that allows a receiver to determine its location using signals from satellites.

GPS itself is not an Internet technology.

This is important.

```text
Satellite
    ↓ radio signal
Phone
    ↓
GPS receiver
    ↓
calculate position
```

Your phone doesn't need Internet access to receive GPS signals.

The satellites continuously transmit information about:

- their identity
    
- their orbital position
    
- extremely precise timing
    

Your receiver measures how long signals from multiple satellites took to arrive.

With enough satellites, it can determine:

```text
latitude
longitude
altitude
time
```

Strictly speaking, people often say **"GPS"** when they mean satellite positioning generally. GPS is the U.S. system; there are also systems such as Galileo, GLONASS, and BeiDou.

---

# 4. NFC

**Definition:** NFC (Near Field Communication) is a very short-range wireless communication technology designed for communication when devices are extremely close together.

Usually:

```text
Phone
  │
  │ a few centimeters
  ▼
NFC terminal
```

Examples:

- contactless payments
    
- transit cards
    
- access cards
    
- NFC tags
    
- pairing devices
    

The range is intentionally tiny.

That's actually useful.

You can deliberately place your phone next to a payment terminal rather than having a connection that works from across the room.

NFC is related to **RFID**, but they're not identical concepts.

---

# 5. Smart devices

A **smart device** is basically a physical device that has computing and often networking capabilities, allowing it to sense information, process it, communicate, or make decisions.

For example:

```text
Traditional light bulb:

Electricity → Light


Smart light:

Phone
  ↓
Wi-Fi
  ↓
Smart bulb
  ↓
Microcontroller
  ↓
LED
```

Now the bulb can:

- receive commands
    
- report status
    
- change brightness
    
- change color
    
- run schedules
    
- communicate with other systems
    

This is where IoT becomes visible in everyday life.

---

# 6. Edge computing

This one is particularly important for understanding modern distributed systems.

**Definition:** Edge computing means processing data **closer to where that data is generated or where it is needed**, rather than sending everything to a distant centralized cloud server.

Imagine a security camera.

### Cloud-only approach

```text
Camera
   ↓
Internet
   ↓
Cloud
   ↓
AI processing
   ↓
"Person detected"
   ↓
Internet
   ↓
Camera/phone
```

That's potentially inefficient.

Instead:

### Edge computing

```text
Camera
   ↓
Edge computer
   ↓
AI processing
   ↓
"Person detected"
   ↓
Only important information sent to cloud
```

The computation happens near the **edge of the network**.

---

# 7. Why does edge computing exist?

Three major reasons:

### Latency

If something must react immediately:

```text
Sensor → distant cloud → response
```

is slower than:

```text
Sensor → nearby computer → response
```

### Bandwidth

Imagine 10,000 cameras continuously uploading raw video.

That's enormous data.

Instead:

```text
Camera
 ↓
Edge processing
 ↓
"Nothing interesting happened"
```

You don't necessarily need to send every frame to the cloud.

### Reliability

If the Internet connection disappears:

```text
Cloud unavailable
        ↓
Edge device can still operate
```

This matters for industrial systems, vehicles, robotics, cameras, etc.

---

# 8. Cloud vs Edge

This is the important mental model:

```text
             CLOUD
        ┌───────────────┐
        │ Data centers  │
        │ Databases     │
        │ Large compute │
        │ AI models     │
        └───────┬───────┘
                │
             Internet
                │
        ┌───────┴───────┐
        │               │
      EDGE            EDGE
   computer         computer
      │               │
   devices          devices
```

Cloud:

> Massive centralized computing resources.

Edge:

> Computing resources placed closer to the devices/users producing the data.

They are **not competitors**.

A real system frequently uses both.

---

# 9. Now connect all six

Imagine a smart fitness watch.

```text
              GPS satellites
                    ↓
                  GPS
                    ↓
Heart/motion sensors
        ↓
   Watch computer
        ↓
     Bluetooth
        ↓
      Phone
        ↓
       Wi-Fi
        ↓
      Router
        ↓
      Internet
        ↓
   Cloud backend
        ↓
    PostgreSQL
```

And perhaps:

```text
Phone
  ↓
NFC
  ↓
Payment terminal
```

while the backend might use:

```text
IoT devices
      ↓
   MQTT/API
      ↓
Edge processing
      ↓
Cloud
      ↓
Spring Boot
      ↓
PostgreSQL
```

Now you're seeing why these technologies emerged together.

---

## The bigger evolution

You can think of the history like this:

```text
Computers
   ↓
Computer networks
   ↓
Internet
   ↓
World Wide Web
   ↓
Web 2.0
   ↓
Social networks
   ↓
Smartphones
   ↓
Wireless everywhere
   ↓
Sensors + microcontrollers
   ↓
IoT
   ↓
Cloud computing
   ↓
Edge computing
   ↓
Distributed physical computing
```

The fundamental shift is huge:

> **The Internet stopped being something that computers used and became something that physical objects participate in.**

Your laptop is an Internet-connected computer.

An IoT system says:

> What if the **thermostat, car, camera, factory machine, watch, refrigerator, light bulb, medical sensor, and industrial robot** also become networked computers?

That's essentially the conceptual bridge from **the Internet of computers → the Internet of Things**.


[[Networking]]