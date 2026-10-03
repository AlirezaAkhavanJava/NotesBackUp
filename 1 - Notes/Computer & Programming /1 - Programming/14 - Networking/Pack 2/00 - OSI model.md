
The **OSI model** (Open Systems Interconnection model) is a **conceptual model for understanding how computers communicate over a network**.

It divides network communication into **7 layers**, where each layer has a specific responsibility.

### The 7 layers

```text
┌─────────────────────────┐
│ 7. Application          │ ← HTTP, DNS, SSH
├─────────────────────────┤
│ 6. Presentation         │ ← Encoding, encryption, formatting
├─────────────────────────┤
│ 5. Session              │ ← Communication sessions
├─────────────────────────┤
│ 4. Transport            │ ← TCP, UDP, ports
├─────────────────────────┤
│ 3. Network              │ ← IP, routing
├─────────────────────────┤
│ 2. Data Link            │ ← Ethernet, MAC addresses
├─────────────────────────┤
│ 1. Physical             │ ← Cables, radio, electrical signals
└─────────────────────────┘
```

### The important idea

Imagine your Spring Boot application sends:

```http
GET /api/users
```

That is **Layer 7 — Application**.

As the data travels down the networking stack, each layer provides its own functionality:

```text
Your Java application
        ↓
      HTTP       Layer 7
        ↓
      TCP        Layer 4
        ↓
       IP        Layer 3
        ↓
    Ethernet     Layer 2
        ↓
   Electrical    Layer 1
```

At the receiving computer, the process happens in reverse:

```text
Physical
   ↓
Data Link
   ↓
Network
   ↓
Transport
   ↓
Session
   ↓
Presentation
   ↓
Application
```

### Why does the OSI model exist?

It gives engineers a **common way to reason about networking**.

For example:

> "The application can communicate, but we're getting a TCP connection failure."

You immediately know you're dealing primarily with **Layer 4**, rather than HTTP itself.

Or:

> "The machine can't reach `192.168.1.50`."

You start thinking about **Layer 3 — IP/routing**.

Or:

> "The network interface isn't detecting the cable."

That's down at **Layer 1/2**.

### One thing to remember

Don't think:

> "Real computers literally have seven OSI layers."

They don't necessarily. OSI is primarily a **reference model** used to understand and discuss networking.

The Internet's practical architecture is more commonly represented by the **TCP/IP model**.

For your backend path, I'd especially master:

**Layer 7 → HTTP**  
**Layer 4 → TCP/UDP + ports**  
**Layer 3 → IP + routing**  
**Layer 2 → Ethernet + MAC**

Those four will become extremely relevant when you start debugging Spring Boot services, Docker networking, PostgreSQL connections, reverse proxies, and distributed systems.

---



> **OSI is not a program. It is a model for describing how networking is organized.**



### Application side

Suppose you have:

```java
public static void main(String[] args) {
    System.out.println("Hello");
}
```

Your **program code actually executes** and controls the application's behavior.

There is an execution engine underneath it:

```text
Your Java code
      ↓
JVM
      ↓
Operating System
      ↓
CPU
```

### Networking side

The OSI model doesn't execute anything:

```text
OSI model
    ↓
[just a conceptual model]
```

Instead, **actual software and hardware implement networking protocols**.

For example:

```text
Your Spring Boot application
          ↓
        HTTP
          ↓
   Operating System
          ↓
      TCP/IP stack
          ↓
    Network interface
          ↓
    Ethernet / Wi-Fi
          ↓
       Physical medium
```

The **TCP/IP stack** is the important part here.

For example, when your Java application does:

```java
HttpClient client = HttpClient.newHttpClient();
```

and sends a request, your application isn't manually implementing TCP.

It asks the operating system's networking facilities to communicate.

The OS contains networking functionality such as:

```text
TCP implementation
IP implementation
routing
socket subsystem
network interface handling
```

And the network hardware has its own firmware/electronics for things like Ethernet or Wi-Fi.

### So what does OSI actually do?

Think of OSI as a **blueprint for describing responsibilities**:

```text
                 OSI model
                     │
       ┌─────────────┼─────────────┐
       ↓             ↓             ↓
   Application    Transport     Network
       │             │             │
      HTTP           TCP           IP
```

The OSI model says:

> "These are the different responsibilities involved in network communication."

It doesn't say:

> "Run this OSI program."

There is **no `osi` process running on your Debian machine**.

### A useful analogy

Think about a **car manufacturing/engineering diagram**.

A diagram might divide a car into:

```text
Engine
Transmission
Brakes
Steering
Electrical
Body
```

The diagram itself doesn't operate the car.

The **actual components** do.

Similarly:

```text
OSI model
   ↓
describes networking responsibilities

Actual protocols/software/hardware
   ↓
perform networking
```

For your backend work, the important distinction is:

**OSI = model**

**TCP/IP = actual networking protocol suite/architecture**

**Linux kernel = implements much of the networking stack**

**Network hardware = performs the physical/link-level work**

**Your application = uses the networking stack through APIs such as sockets**

That last relationship is particularly important for understanding how **Java → sockets → TCP → IP → Ethernet → network** actually works.

[[Networking]]