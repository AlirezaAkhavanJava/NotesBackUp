---

---
---
A **socket** is a **software abstraction that represents one endpoint of network communication**.

At a practical level, a socket gives a program a way to **send and receive data over a network**.

A useful mental model is:

> **IP identifies the host, port identifies the service endpoint, and a socket is the program's communication interface to that endpoint.**

---

# 1. Socket as a communication endpoint

Suppose your Spring Boot application is running on:

```text
IP:   192.168.1.10
Port: 8080
```

A network endpoint can be represented as:

```text
192.168.1.10:8080
```

A socket is the software mechanism through which your application communicates using that endpoint.

Conceptually:

```text
Application
    │
    │ reads / writes data
    ▼
  Socket
    │
    │
    ▼
TCP / UDP
    │
    ▼
Network
```

So the socket sits between your **application** and the **networking stack provided by the OS**.

---

# 2. Socket is not the same thing as a port

These are related, but they are not the same.

### Port

A **port** is a number:

```text
8080
```

It identifies a logical network service endpoint.

### Socket

A **socket** is an OS-managed communication abstraction used by a program.

For example:

```text
IP address: 192.168.1.10
Port:       8080
Protocol:   TCP
```

A program can create a TCP socket and bind it to:

```text
192.168.1.10:8080
```

The port is just part of the addressing information associated with the socket.

---

# 3. A socket has an address

For Internet networking, a socket is commonly associated with:

```text
IP address + Port
```

For example:

```text
192.168.1.10:8080
```

But the complete identity of a communication endpoint also depends on the transport protocol:

```text
TCP + 192.168.1.10 + 8080
```

and

```text
UDP + 192.168.1.10 + 8080
```

are different transport endpoints.

---

# 4. TCP socket vs UDP socket

This distinction is extremely important.

## TCP socket

A TCP socket represents communication over **TCP**, which is connection-oriented.

Typical lifecycle:

```text
socket()
   ↓
bind()
   ↓
listen()
   ↓
accept()
   ↓
read/write
   ↓
close()
```

For a client:

```text
socket()
   ↓
connect()
   ↓
read/write
   ↓
close()
```

TCP provides mechanisms such as:

- reliable delivery
    
- ordered data
    
- retransmission
    
- flow control
    
- congestion control
    
- connection establishment
    

---

## UDP socket

UDP is connectionless at the protocol level.

Typical usage is closer to:

```text
socket()
   ↓
bind()
   ↓
sendto() / recvfrom()
   ↓
close()
```

UDP does not inherently provide:

- reliable delivery
    
- ordering
    
- retransmission
    
- congestion control like TCP
    

The application can implement some of these mechanisms itself when necessary.

---

# 5. Server socket and client socket

With TCP, it helps to distinguish **listening sockets** from **connected sockets**.

## Server listening socket

A server creates a socket and listens on a port.

For example:

```text
0.0.0.0:8080
```

Conceptually:

```text
Server
  │
  └── Listening Socket
          │
          └── Port 8080
```

Its job is essentially:

> "Wait for incoming TCP connection attempts."

---

## Connected socket

When a client connects:

```text
Client                     Server

10.0.0.5:53142  ───────→  192.168.1.10:8080
```

The server's `accept()` operation produces a **new connected socket** for that particular client connection.

Now you have:

```text
Listening socket
      │
      ├── Connection A → Client A
      ├── Connection B → Client B
      └── Connection C → Client C
```

This is a very important concept.

The server does **not** use one single connected socket to communicate with every client.

It normally has:

```text
1 listening socket
+
1 connected socket per active TCP connection
```

---

# 6. The TCP connection is identified by a 4-tuple

For TCP, a connection is commonly identified using:

```text
Source IP
Source Port
Destination IP
Destination Port
```

For example:

```text
Client:
10.0.0.5:53142

Server:
192.168.1.10:8080
```

The TCP connection can be represented as:

```text
(10.0.0.5, 53142, 192.168.1.10, 8080)
```

The client's port `53142` is usually an **ephemeral port**.

This is why many clients can simultaneously connect to the same server port:

```text
Client A: 10.0.0.5:53142 ──┐
Client B: 10.0.0.6:49221 ──┼──→ Server: 192.168.1.10:8080
Client C: 10.0.0.7:61433 ──┘
```

All use server port `8080`, but their complete TCP connections are different.

---

# 7. What happens when a TCP server starts?

Let's use a simplified server.

### Step 1 — Create socket

The application asks the OS:

```text
Create a TCP socket.
```

The OS creates and manages the socket.

---

### Step 2 — Bind

The application associates the socket with an address:

```text
192.168.1.10:8080
```

This is:

```text
bind()
```

Now the OS knows that this socket is associated with port `8080`.

---

### Step 3 — Listen

The application tells the OS:

```text
Start accepting incoming TCP connections.
```

Conceptually:

```text
listen()
```

The socket becomes a **listening socket**.

---

### Step 4 — Accept

A client sends a TCP connection request.

The server calls:

```text
accept()
```

The OS creates/returns a new connected socket representing that client connection.

Conceptually:

```text
                  Listening Socket
                       :8080
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
        Socket A      Socket B      Socket C
        Client A      Client B      Client C
```

---

# 8. Socket is an OS resource

This is another important point.

A socket is not just some abstract networking concept.

The **operating system maintains socket state and resources**.

When a process creates a socket, the OS tracks information such as:

```text
Protocol
Local IP
Local Port
Remote IP
Remote Port
Connection state
Send buffer
Receive buffer
Socket options
```

The application interacts with the socket through a programming interface provided by the OS.

On Linux, this happens through the **socket API**.

---

# 9. Socket file descriptor on Linux

This is especially useful for you because you use Linux.

On Linux, a socket is represented to a process using a **file descriptor**.

For example:

```c
int sockfd = socket(AF_INET, SOCK_STREAM, 0);
```

The returned:

```text
sockfd
```

is an integer file descriptor.

For example:

```text
3
```

So you might have:

```text
stdin  → FD 0
stdout → FD 1
stderr → FD 2
socket → FD 3
```

This is one reason Unix/Linux has the philosophy:

> **"Everything is a file"**

A socket isn't literally a normal disk file, but it can be accessed through the Unix file-descriptor interface.

For example:

```c
read(sockfd, buffer, size);
write(sockfd, buffer, size);
close(sockfd);
```

---

# 10. Java's view of sockets

Since you're working with Java, this becomes more concrete.

Java provides classes such as:

```java
java.net.Socket
java.net.ServerSocket
java.net.DatagramSocket
```

For TCP:

### Server

```java
ServerSocket server = new ServerSocket(8080);

Socket client = server.accept();
```

Conceptually:

```text
ServerSocket
     │
     │ accepts
     ▼
  Socket
```

`ServerSocket` is primarily used for **listening for incoming TCP connections**.

`Socket` represents an established TCP communication endpoint.

You can then obtain streams:

```java
InputStream in = client.getInputStream();
OutputStream out = client.getOutputStream();
```

So:

```text
Java application
       │
       ▼
java.net.Socket
       │
       ▼
JVM
       │
       ▼
Linux socket API
       │
       ▼
Linux kernel networking stack
       │
       ▼
Network interface
       │
       ▼
Network
```

That stack is extremely useful to understand as a backend developer.

---

# 11. Socket and HTTP

HTTP itself does not generally replace sockets.

For traditional HTTP/1.1 over TCP:

```text
Application
    ↓
HTTP
    ↓
TCP socket
    ↓
TCP
    ↓
IP
    ↓
Ethernet/Wi-Fi
```

For HTTPS:

```text
Application
    ↓
HTTP
    ↓
TLS
    ↓
TCP socket
    ↓
TCP
    ↓
IP
    ↓
Network
```

So when your Spring Boot application receives:

```text
GET /users HTTP/1.1
```

the HTTP data ultimately arrives through a network connection backed by sockets.

---

# 12. Socket vs endpoint vs connection

These three concepts are often confused.

### Endpoint

An endpoint describes one side of communication:

```text
192.168.1.10:8080
```

### Socket

A socket is the **OS/application abstraction used to communicate through that endpoint**.

### Connection

A TCP connection is the **communication relationship between two TCP endpoints**.

For example:

```text
Client Socket                         Server Socket
10.0.0.5:53142  ←── TCP connection ─→  192.168.1.10:8080
```

---

# 13. A good mental model

Think about a building:

```text
IP address = Building address
Port       = Apartment/office number
Socket     = Communication interface/phone line inside that office
Connection = The active conversation between two endpoints
```

So:

```text
        HOST
192.168.1.10
      │
      ├── :22    → SSH socket
      ├── :5432  → PostgreSQL socket
      └── :8080  → Spring Boot socket
```

And when a client connects:

```text
Client                                  Server

Socket ───────── TCP connection ─────── Socket
```

---

# 14. The most important distinction

Keep this hierarchy in your head:

```text
IP address
    ↓
Identifies a host/interface

Port
    ↓
Identifies a transport-layer endpoint

Socket
    ↓
OS/programming abstraction for network communication

Connection
    ↓
Active communication between endpoints
```

And for TCP specifically:

```text
Server
 ├── Listening socket :8080
 │
 ├── Connected socket ← Client A
 ├── Connected socket ← Client B
 └── Connected socket ← Client C
```

That model will make **TCP, HTTP servers, Spring Boot/Tomcat, WebSockets, and Linux networking** much easier to understand.

[[Networking]]