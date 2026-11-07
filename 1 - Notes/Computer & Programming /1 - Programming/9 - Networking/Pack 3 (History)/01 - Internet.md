
## What is the Internet?


[Birth of the Internet](https://www.youtube.com/watch?v=VPToE8vwKew&t=98s)

The **Internet is a global network of interconnected computer networks** that communicate using a common family of protocols, primarily **TCP/IP**.

The simplest mental model is:

```text
Your computer
     │
     ▼
Your local network
     │
     ▼
ISP
     │
     ▼
Other networks
     │
     ▼
Destination network
     │
     ▼
Server
```

The Internet is **not one giant network owned by one organization**. It is a **network of networks** operated by many different organizations, ISPs, companies, governments, universities, data centers, etc.

### What does "Internet" actually mean?

The word comes from **internetworking**:

```text
Network A ───┐
             │
Network B ───┼── Internet
             │
Network C ───┘
```

Different networks are connected together so that a computer on one network can communicate with a computer on another.

### Is the Internet hardware or software?

**Both**, but the Internet itself isn't a single piece of software.

It is a combination of:

**Physical infrastructure**

```text
Ethernet cables
Fiber-optic cables
Undersea cables
Routers
Switches
Wireless links
Data centers
```

and **protocols** that define how devices communicate:

```text
Ethernet
IP
TCP
UDP
DNS
BGP
HTTP
TLS
...
```

For example, when your browser requests:

```text
https://example.com
```

many things happen:

```text
Application
    │
   HTTP
    │
   TLS
    │
   TCP
    │
    IP
    │
Ethernet / Wi-Fi
    │
    ▼
   Internet
```

This connects directly to what you're learning about the **OSI model**.

### Internet vs Web

This distinction is fundamental:

```text
                    INTERNET
                       │
        ┌──────────────┼──────────────┐
        │              │              │
       Web           Email           SSH
    HTTP/HTTPS     SMTP/IMAP          │
        │              │              │
        └──────────────┴──────────────┘
                       │
                Internet protocols
                  and networks
```

**Internet:** the global networking infrastructure and system of interconnected networks.

**World Wide Web:** one service built on top of the Internet.

So:

> **The Web uses the Internet, but the Internet is much bigger than the Web.**

And historically, **the Internet existed before the World Wide Web**. The Web appeared around **1989–1991**, while the Internet's development goes back much further, particularly to **ARPANET in the late 1960s**.


[[Networking]]