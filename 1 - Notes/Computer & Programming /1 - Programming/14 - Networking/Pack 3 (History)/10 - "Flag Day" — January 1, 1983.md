

In Internet history, **Flag Day** refers to the day **ARPANET officially switched from NCP to TCP/IP**.

```text
Before January 1, 1983

ARPANET
   │
   └── NCP
```

After the transition:

```text
January 1, 1983

ARPANET
   │
   └── TCP/IP
          │
          ├── IP
          └── TCP
```

### Why was this necessary?

The old **NCP (Network Control Protocol)** was designed primarily for communication within the ARPANET environment.

But the goal had become much larger:

> **Connect multiple independent networks into one "network of networks."**

TCP/IP was designed for that.

```text
             INTERNET
                 │
       ┌─────────┼─────────┐
       │         │         │
    ARPANET   Satellite   Radio
       │         │         │
       └─────────┼─────────┘
                 │
                IP
```

The different underlying networks could remain different while **IP provided a common internetworking layer**.

### What happened on Flag Day?

Network operators had to transition their machines and network equipment from:

```text
NCP → TCP/IP
```

The transition was deliberately coordinated. Systems that remained on NCP would no longer be able to participate normally in the TCP/IP-based ARPANET.

That's why it was called a **"flag day"**: essentially, there was a specific date when everyone had to switch.

### Why is it historically important?

Because this is the chain you've been building:

```text
Packet switching
      ↓
ARPANET
      ↓
Problem: connect different networks
      ↓
TCP/IP
      ↓
January 1, 1983
      ↓
ARPANET switches NCP → TCP/IP
      ↓
Internet architecture
```

**Flag Day wasn't the invention of the Internet.** It was a crucial transition that made TCP/IP the standard protocol architecture of ARPANET and helped establish the foundation for today's Internet.



[[Networking]]