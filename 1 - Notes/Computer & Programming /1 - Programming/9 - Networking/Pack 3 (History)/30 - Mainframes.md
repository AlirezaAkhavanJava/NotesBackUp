
## Mainframes

**Definition:** A **mainframe computer** is a large, highly reliable computer system designed to provide **centralized computing and data processing for many users and applications simultaneously**.

It is not simply "a really big PC."

```text
                MAINFRAME
        ┌──────────────────────┐
        │   CPU / Processing   │
        │       Memory         │
        │       Storage        │
        │   I/O subsystems     │
        └──────────┬───────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
      User 1     User 2     User 3
     terminal    terminal   terminal
```

The important idea is **centralized computing**.

---

## Why did mainframes exist?

Early computers were enormously expensive.

Instead of:

```text
Person → own computer
```

an organization could have:

```text
             Mainframe
            /    |    \
           /     |     \
        User    User    User
```

Many people shared the same machine.

This was particularly useful for:

- governments
    
- universities
    
- banks
    
- airlines
    
- insurance companies
    
- scientific institutions
    
- large corporations
    

---

## Mainframe ≠ network

This distinction matters for the history we're following.

A mainframe is a **computer**.

A network is a **communication system connecting computers/devices**.

You could have:

```text
Terminal ─── cable ─── Mainframe
```

without having anything resembling the Internet.

---

## Terminals

A lot of early users didn't interact with the mainframe using a personal computer.

They used a **terminal**.

A terminal essentially provided:

```text
Keyboard → send input
Screen   ← receive output
```

The actual computation happened on the mainframe.

For example:

```text
You type:

$ calculate 123 × 456

        ↓

Terminal
        ↓
   communication
        ↓
Mainframe computes
        ↓
Terminal displays

56088
```

The terminal itself could be relatively "dumb."

That's why you will encounter the term:

**dumb terminal**

It means a terminal with little or no independent computing capability.

---

# Mainframe vs personal computer

This is the major architectural difference.

### Mainframe era

```text
              ┌──────────────┐
              │  MAINFRAME   │
              │              │
              │ CPU + Memory │
              │ Storage      │
              └──────┬───────┘
                     │
          ┌──────────┼──────────┐
          ↓          ↓          ↓
       Terminal   Terminal   Terminal
```

### PC era

```text
┌─────────┐       ┌─────────┐       ┌─────────┐
│ PC      │       │ PC      │       │ PC      │
│ CPU     │       │ CPU     │       │ CPU     │
│ Memory  │       │ Memory  │       │ Memory  │
└─────────┘       └─────────┘       └─────────┘
```

Each PC performs its own computation.

---

# Where this fits in our history

This is an important transition:

```text
1940s
│
│ Large early computers
│
▼
1950s–60s
│
│ Mainframes
│
│ Centralized computing
│
▼
Terminals connected to mainframes
│
▼
Computer networking
│
▼
Computers communicate with other computers
│
▼
Packet switching
│
▼
ARPANET
│
▼
TCP/IP
│
▼
Internet
│
▼
World Wide Web
```

There is an important conceptual shift here:

**Mainframe computing:**

> Many people → one powerful computer

**Computer networking:**

> Many computers → communicate with each other

**Internet:**

> Many networks → communicate with each other

**Web:**

> People → access linked information/services through that network

---

### One subtle point

Mainframes **still exist today**. They weren't replaced because they became useless.

Modern systems such as IBM Z mainframes are extremely good at workloads requiring:

- massive transaction processing
    
- reliability
    
- security
    
- huge I/O throughput
    
- backward compatibility
    
- centralized enterprise data processing
    

For example, a bank can process enormous numbers of transactions on a mainframe.

So **"mainframe" describes a class/architecture of computer system, not an obsolete historical machine.**


[[Networking]]