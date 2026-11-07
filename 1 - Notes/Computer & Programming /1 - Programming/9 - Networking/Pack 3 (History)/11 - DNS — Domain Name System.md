

**DNS is the distributed naming system that translates human-readable domain names into network addresses, primarily IP addresses.**

For example:

```text
www.example.com
       ↓
     DNS
       ↓
93.184.216.34
```

But to understand DNS, you need to understand the problem that existed **before DNS**.

---

# 1. The problem: humans don't want to remember IP addresses

IP networking works with addresses such as:

```text
142.250.72.14
```

A computer can work with that.

Humans would rather type:

```text
google.com
```

So we need a mapping:

```text
google.com ─────────→ 142.250.72.14
```

That is the basic problem DNS solves.

But there was a much bigger problem behind it.

---

# 2. Before DNS: HOSTS.TXT

Early ARPANET used a central file called **HOSTS.TXT**.

Conceptually:

```text
HOSTS.TXT

UCLA       → 10.0.0.1
SRI        → 10.0.0.2
MIT        → 10.0.0.3
...
```

Every participating computer could obtain a copy of this file.

If you wanted to find another host:

```text
hostname
   ↓
look in HOSTS.TXT
   ↓
find IP address
```

This worked when the network was small.

---

# 3. Why HOSTS.TXT stopped scaling

Imagine the network has:

```text
10 computers
```

Easy.

Then:

```text
1,000 computers
```

Still manageable.

But eventually:

```text
10,000
100,000
1,000,000+
```

Now a single centrally maintained file becomes a serious problem.

You have:

```text
              Central host
                   │
             HOSTS.TXT
                   │
       ┌───────────┼───────────┐
       ↓           ↓           ↓
    Computer    Computer    Computer
```

Every time a machine is added or its address changes:

```text
HOSTS.TXT
    ↓
update central file
    ↓
distribute new copy
    ↓
everyone downloads it
```

This creates several problems:

### Scalability

The file keeps getting larger.

### Central administration

One authority has to maintain it.

### Update traffic

Every change has to propagate to everyone.

### Name collisions

There needs to be a way to ensure that names are unique.

### Administrative boundaries

Different organizations should be able to manage their own names.

---

# 4. The DNS solution

DNS changed the architecture from:

```text
ONE giant file
```

to:

```text
DISTRIBUTED DATABASE
```

That's the really important idea.

Instead of:

```text
               HOSTS.TXT
                   │
        ┌──────────┼──────────┐
        ↓          ↓          ↓
       ALL        ALL        ALL
```

DNS uses a hierarchy:

```text
                     .
                     │
              ┌──────┴──────┐
              │             │
             com           org
              │
          example.com
              │
        ┌─────┴─────┐
        │           │
       www         mail
```

Different organizations can control different parts of the namespace.

For example:

```text
example.com
     │
     ├── www
     ├── mail
     └── api
```

The owner of `example.com` can manage its own DNS records without modifying one giant global file.

---

# 5. Who invented DNS?

The person most strongly associated with the invention of DNS is:

![[Pasted image 20261007180948.png]]

**Paul Mockapetris.**

In **1983**, while working at USC's Information Sciences Institute, Mockapetris designed the Domain Name System.

He published the foundational RFCs:

- **RFC 882**
    
- **RFC 883**
    

These were published in **1983**.

The system was subsequently refined and standardized through later RFCs.

So:

```text
1983

Paul Mockapetris
       ↓
Domain Name System
       ↓
distributed hierarchical naming
```

---

# 6. Why the hierarchy?

This is one of the cleverest parts.

Take:

```text
www.example.com
```

DNS can be understood from right to left:

```text
www . example . com
 │       │       │
 │       │       └── Top-level domain
 │       └────────── Domain
 └────────────────── Host/subdomain
```

And above `com` is the root:

```text
www.example.com.
               ↑
             root
```

The complete conceptual hierarchy is:

```text
                    .
                    │
                  com
                    │
                 example
                    │
                   www
```

The root is represented by:

```text
.
```

That's why a fully qualified domain name technically ends with a dot:

```text
www.example.com.
```

You normally don't type the final dot because DNS software treats it as implicit.

---

# 7. How does DNS actually find the IP?

Suppose you type:

```text
https://www.example.com
```

Your computer needs the IP.

Conceptually:

```text
Browser
   │
   │ "What's the IP for www.example.com?"
   ▼
DNS resolver
   │
   ▼
Root DNS server
   │
   │ "Ask .com"
   ▼
.com DNS server
   │
   │ "Ask example.com"
   ▼
example.com authoritative DNS server
   │
   │ "www.example.com = 93.184.x.x"
   ▼
Resolver
   │
   ▼
Your computer
```

Then your browser can connect to the IP address.

---

# 8. DNS isn't just "domain → IP"

This is an important professional distinction.

DNS is a **general naming system**, and it stores different types of **resource records**.

For example:

```text
A       → IPv4 address
AAAA    → IPv6 address
MX      → mail server
CNAME   → canonical name / alias
NS      → authoritative name server
TXT     → arbitrary text data
```

For example:

```text
example.com

A       → 93.184.216.34
MX      → mail.example.com
NS      → ns1.example.com
```

So don't think:

> DNS = website-to-IP lookup.

Think:

> **DNS = distributed hierarchical database for Internet naming.**

IP address lookup is just one of its most common uses.

---

# 9. The problem DNS solved, precisely

Before DNS:

```text
Name
 ↓
central HOSTS.TXT
 ↓
IP
```

After DNS:

```text
Name
 ↓
distributed hierarchical namespace
 ↓
DNS resolution
 ↓
IP
```

The major problems it solved were:

**1. Scalability**

The namespace could grow enormously.

**2. Distributed administration**

Organizations could manage their own domains.

**3. Decentralization**

There was no need for one giant host file containing every machine.

**4. Dynamic updates**

Names and addresses could change without distributing an entire global file.

**5. Human-friendly naming**

Humans could use:

```text
google.com
github.com
openai.com
```

instead of remembering IP addresses.

---

## The historical chain

You're now building a very useful timeline:

```text
Packet switching
      ↓
ARPANET
      ↓
Email
      ↓
TCP/IP
      ↓
1983 — Flag Day
      ↓
Internet becomes a network of networks
      ↓
1983 — DNS
      ↓
Human-readable hierarchical names
      ↓
World Wide Web
      ↓
Modern Internet
```

And one subtle but important point:

**DNS and the Web are not the same thing.**

DNS existed **before the Web**.

DNS answers:

```text
"What network address/name information corresponds
to this domain?"
```

HTTP answers:

```text
"How do I request and transfer web resources?"
```

That's why when you eventually dissect:

```bash
curl https://example.com
```

you'll be able to see the chain:

```text
example.com
     ↓
DNS
     ↓
IP address
     ↓
TCP
     ↓
TLS
     ↓
HTTP
     ↓
response
```

That is the actual stack you're learning.


[[Networking]]