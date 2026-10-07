
 now we can fill in the **prehistory of computer networking** without repeating the ARPANET/Internet/Web material.

The important story is:

> **Telecommunication → Telegraph → Telephone → Digital communication → Mainframes → Computer communication → Networking protocols**

The key realization is that **computer networking did not appear from nowhere**. It inherited a huge amount of engineering from telecommunications.

---

# 1. Telecommunication

**Telecommunication** literally means:

> Communicating information across a distance using technology.

Before electronic communication, information physically had to travel with a person or object:

```text
Person A
   ↓
letter / messenger
   ↓
Person B
```

The fundamental problem was:

> **How can we make information travel faster than the physical object carrying it?**

That question is much older than computers.

---

# 2. Before electricity: optical telegraph

One early solution was the **optical telegraph**.

A famous example was the semaphore network developed in France by **Claude Chappe** in the 1790s.

It used towers with movable mechanical arms:

```text
Tower A       Tower B       Tower C
   \             \             \
    \             \             \
   semaphore → semaphore → semaphore
```

An operator at Tower A would configure a symbol.

The next tower observed it and reproduced it.

Then the next tower did the same.

So information could travel over large distances much faster than a messenger.

But there was a problem:

**You needed line of sight.**

And it didn't work at night or in bad weather very well.

This was an important conceptual step:

> Information could be encoded into physical signals and transmitted through a communication network.

---

# 3. Electrical telegraph

Then electricity changed everything.

In the 1830s, inventors including **Samuel Morse** developed practical electrical telegraph systems.

Now:

```text
Station A
   │
   │ electrical signal
   ▼
═══════════════════════
      telegraph wire
═══════════════════════
   │
   ▼
Station B
```

Instead of physically moving a message, electrical signals travelled through a wire.

---

# 4. Morse code

The telegraph needed a way to represent characters using electrical signaling.

That's where **Morse code** became important.

For example:

```text
A = .-
B = -...
C = -.-.
```

So:

```text
LETTER
   ↓
MORSE CODE
   ↓
electrical pulses
   ↓
wire
   ↓
electrical pulses
   ↓
MORSE CODE
   ↓
LETTER
```

This is conceptually very similar to what computers eventually do.

The representation changed:

```text
human information
       ↓
encoded representation
       ↓
physical signal
       ↓
communication medium
       ↓
physical signal
       ↓
decoded representation
```

That pattern survives in modern networking.

---

# 5. The telegraph created the first large communication networks

Telegraph operators didn't simply connect two buildings.

They built networks.

```text
             Station B
             /
Station A ──┼── Station C
             \
             Station D
```

Now you have problems that look surprisingly familiar:

- addressing
    
- routing
    
- signal quality
    
- timing
    
- synchronization
    
- error detection
    
- retransmission
    
- switching
    
- network topology
    

These weren't yet Internet protocols, but the **engineering problems already existed**.

---

# 6. The next revolution: telephone

The telegraph primarily transmitted encoded symbols.

The telephone transmitted **voice**.

Alexander Graham Bell and others developed practical telephone systems in the 1870s.

Instead of:

```text
letters → code → electrical pulses
```

the system could represent:

```text
sound
 ↓
electrical signal
 ↓
wire
 ↓
electrical signal
 ↓
sound
```

This created enormous telephone networks.

And this becomes extremely important later.

Because early computer networking eventually used **telephone infrastructure**.

---

# 7. Telephone networks introduced switching

Imagine millions of telephones.

You can't have a dedicated physical wire between every possible pair:

```text
A ───────── B
A ───────── C
A ───────── D
B ───────── C
B ───────── D
C ───────── D
...
```

The number of connections would explode.

Instead, telephone networks introduced **switching**.

Conceptually:

```text
Phone A
   │
   ▼
[Switch]
 /   |   \
B    C    D
```

A switch establishes a communication path between endpoints.

This eventually developed into enormous telephone networks.

---

# 8. Circuit switching

Traditional telephone networks used **circuit switching**.

When you called someone:

```text
Phone A
  ↓
Switch
  ↓
Switch
  ↓
Switch
  ↓
Phone B
```

The network established a communication circuit for the call.

For the duration of the call, resources were associated with that connection.

This was excellent for continuous voice communication.

But computers have a different traffic pattern.

---

# 9. Computers behave differently from humans talking

Consider a telephone conversation:

```text
Person A ←────────────→ Person B

continuous communication
```

But a computer might do:

```text
send request
      ↓
wait
      ↓
receive response
      ↓
wait
      ↓
send another request
```

Computer traffic is **bursty**.

For example:

```text
████
        █
                 █████████
```

A dedicated circuit could sit unused much of the time.

This helped motivate the development of **packet switching**.

And that is one of the critical transitions:

```text
Telephone thinking
       ↓
continuous circuit
       ↓
Computer networking
       ↓
bursty packet communication
```

---

# 10. Meanwhile: computers become practical

Now move into the 1940s–1960s.

Computers became increasingly capable, but they were enormous and expensive.

Examples include systems such as:

- ENIAC
    
- UNIVAC
    
- IBM mainframes
    

The architecture was fundamentally different from today's PC.

```text
              MAINFRAME
       ┌────────────────────┐
       │ CPU                │
       │ Memory             │
       │ Storage            │
       │ I/O                │
       └─────────┬──────────┘
                 │
        multiple users
                 │
       ┌─────────┼─────────┐
       ↓         ↓         ↓
    Terminal   Terminal   Terminal
```

---

# 11. The interesting convergence

Now we have two separate technological worlds:

### Telecommunications

```text
Telegraph
   ↓
Telephone
   ↓
Switching
   ↓
Huge communication networks
```

### Computing

```text
Early computers
   ↓
Mainframes
   ↓
Multiple users
   ↓
Remote terminals
```

Eventually they meet:

```text
             COMPUTER
                 │
              terminal
                 │
                 ▼
        TELECOMMUNICATION
             NETWORK
                 │
                 ▼
             MAINFRAME
```

Now a computer could communicate with another computer **through telecommunications infrastructure**.

This is a major step toward networking.

---

# 12. Modems

Here's where the two worlds literally meet.

A telephone network was designed for **analog voice**, while computers produced **digital data**.

So you needed a device that translated between them.

**Modem = modulator-demodulator**

```text
Computer
   │
 digital bits
   │
   ▼
[ MODEM ]
   │
 analog signal
   │
   ▼
Telephone network
   │
   ▼
[ MODEM ]
   │
 digital bits
   │
   ▼
Computer
```

This technology became extremely important for computer communications.

So the chain is:

```text
Computer
   ↓
digital data
   ↓
modem
   ↓
telephone network
   ↓
modem
   ↓
computer
```

That is literally computer networking built on top of telecommunications infrastructure.

---

# 13. And then protocols become unavoidable

Now imagine two computers connected over a telephone network.

Computer A says:

```text
010101...
```

Computer B receives something.

But they need to agree:

- When does a message start?
    
- When does it end?
    
- What does each byte mean?
    
- How fast should data be sent?
    
- What happens if something is corrupted?
    
- How do we know it arrived?
    
- How do we establish a connection?
    
- How do we terminate it?
    

Therefore:

```text
Physical communication
        ↓
Need rules
        ↓
Communication protocols
```

And as networks become more complex:

```text
one connection
     ↓
network
     ↓
multiple networks
     ↓
internetwork
```

the protocols become more sophisticated.

---

# 14. The full historical chain

This is the timeline I recommend keeping in your head:

```text
                    TELECOMMUNICATION
                           │
            ┌──────────────┴──────────────┐
            ↓                             ↓
     Optical telegraph              Electrical telegraph
            │                             │
            │                        Morse code
            │                             │
            └──────────────┬──────────────┘
                           ↓
                       Telephone
                           ↓
                    Switching networks
                           ↓
                  Circuit switching
                           │
                           │
                           │      COMPUTING
                           │          │
                           │      Mainframes
                           │          ↓
                           │      Terminals
                           │          ↓
                           └──────→ Modems
                                      ↓
                              Computer communication
                                      ↓
                               Packet switching
                                      ↓
                                   ARPANET
                                      ↓
                                   TCP/IP
                                      ↓
                                  Internet
                                      ↓
                                     Web
```

The really important conceptual transition is:

> **Telecommunications taught us how to move information across distance. Computing gave us machines that needed to exchange digital information. Computer networking emerged when those two worlds converged.**

And then **protocols** became the formal language that allowed increasingly different machines and networks to understand one another.


[[Networking]]