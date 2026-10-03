
**TCP/IP** stands for **Transmission Control Protocol/Internet Protocol**. It is the fundamental set of communication rules—often called a **protocol suite**—that allows computers, phones, servers, and other devices to communicate over networks, including the internet.

It is not just two protocols. TCP and IP are the two core ones, but TCP/IP includes many protocols such as UDP, HTTP, DNS, SMTP, ICMP, and others.

### Core parts

- **IP (Internet Protocol)**  
  Handles **addressing and routing**. Every device on a network has an IP address. IP breaks data into packets and routes them across networks. It is “best effort”: it tries to deliver packets but does not guarantee they arrive, arrive in order, or arrive only once.

- **TCP (Transmission Control Protocol)**  
  Runs on top of IP and provides **reliable, ordered, error-checked delivery**. It establishes a connection, acknowledges received data, retransmits lost packets, and puts data back in order. It is used by web browsing, email, file transfers, etc.

- **UDP (User Datagram Protocol)**  
  Another transport protocol. It is faster but does **not** guarantee delivery or order. Used for streaming, online games, VoIP, DNS, etc.

### TCP/IP model layers

A common 4-layer view:

1. **Application layer** – HTTP/HTTPS, DNS, SMTP, SSH, FTP  
2. **Transport layer** – TCP, UDP  
3. **Internet layer** – IP, ICMP, routing  
4. **Network access / link layer** – Ethernet, Wi-Fi, ARP, network drivers  

This is similar to the OSI 7-layer model, but TCP/IP is the practical model the internet actually uses.

### How it works, simply

When you load a website:

1. DNS turns the domain name into an IP address.
2. TCP establishes a connection with the server.
3. HTTP sends the request.
4. IP routes packets across the internet.
5. TCP checks and reassembles the packets at the destination.
6. The browser displays the page.

### Analogy

- **IP** is like the postal system: it addresses and routes envelopes.
- **TCP** is like delivery confirmation: it makes sure all pages arrive, in order, and asks for missing ones.

In short: **TCP/IP is the language and rulebook of the internet.** It lets different devices and networks work together, regardless of who made them.


[[Networking]]