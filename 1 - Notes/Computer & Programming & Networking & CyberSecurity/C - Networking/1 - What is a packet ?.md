
Think of a packet as a **piece of information being sent over a network**.

Imagine you want to send a message:

> `HELLO`

Your computer needs to send those bits through a cable or Wi-Fi.

For a larger message, the data can be broken into smaller pieces:

```text
"I LOVE LINUX AND JAVA"

Packet 1 → "I LOVE"
Packet 2 → "LINUX"
Packet 3 → "AND"
Packet 4 → "JAVA"
```

Those pieces are **packets**.

A packet is not only the actual data, though. It also contains information needed to handle and deliver that data.

```text
┌──────────────────────────┐
│ Where am I going?        │ ← destination
│ Where did I come from?   │ ← source
│ Other information        │
│                          │
│        HELLO             │ ← actual data
└──────────────────────────┘
```

For example, an IP packet might contain:

```text
FROM:      192.168.1.20
TO:        142.250.74.14

DATA:
"HELLO"
```

A router looks at the destination information, decides where to send the packet next, and forwards it.

You can think of packets like **boxes sent through the postal system**. If you want to send a huge book, you could split it into several boxes:

```text
Book
 │
 ├── Box 1
 ├── Box 2
 ├── Box 3
 └── Box 4
```

Each box has information such as:

```text
FROM
TO
CONTENTS
```

Networking works similarly:

```text
Large amount of data
        │
        ▼
 ┌──────┼──────┐
 ▼      ▼      ▼
Packet Packet Packet
  │      │      │
  └──────┼──────┘
         ▼
      Network
         │
         ▼
     Destination
```

So the simplest definition is:

> **A packet is a chunk of data prepared to travel through a network.**


[[Networking]]