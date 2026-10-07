


These are actually **two separate stories** that eventually came together.

### 1. The `@` symbol existed long before email

`@` was **not invented for email**.

It was used centuries earlier, particularly as a shorthand meaning **"at"**.

For example:

```text
10 apples @ $2
```

means:

```text
10 apples at $2 each
```

By the time computers existed, `@` was already a character available on keyboards.

---

## 2. Ray Tomlinson and email

![[Pasted image 20261007180418.png]]

In **1971**, **Ray Tomlinson** was working on ARPANET.

He wanted to send a message from one computer/user to another computer/user.

The problem was:

```text
user + computer
```

needed to be represented as one address.

He chose:

```text
user@computer
```

The `@` symbol was ideal because it naturally meant:

> **user "at" computer**

For example:

```text
tomlinson@host
```

means roughly:

```text
user Tomlinson
      ↓
   located at
      ↓
   host computer
```

This became the fundamental structure of email addresses.

---

# 3. What did Tomlinson actually invent?

Tomlinson is generally credited with creating the first **networked email system** that could send messages between different computers over ARPANET.

Before that, computers could have programs that stored messages for users **on the same machine**.

The major breakthrough was:

```text
Computer A                         Computer B
┌──────────────┐                  ┌──────────────┐
│ User A       │                  │ User B       │
└──────┬───────┘                  └──────▲───────┘
       │                                 │
       └────── message ────────────────► │
                 ARPANET
```

And the address could identify both:

```text
user@host
```

---

## 4. Why `@` specifically?

Tomlinson needed a character that:

- wasn't normally part of a person's name
    
- clearly separated the **user** from the **computer**
    
- already existed on the keyboard
    

He chose `@`.

So:

```text
alice@computerA
```

can conceptually be read as:

```text
USER       LOCATION/HOST
 │               │
 ▼               ▼
alice     @    computerA
```

This is the ancestor of today's:

```text
alice@example.com
```

---

## 5. One important distinction

**Email ≠ SMTP.**

Email evolved through multiple technologies.

Very roughly:

```text
1971
Ray Tomlinson
    ↓
network email
    ↓
ARPANET
    ↓
standardized mail protocols
    ↓
SMTP
    ↓
modern Internet email
```

Today, when you send:

```text
alice@example.com
```

the `@` is still performing essentially the same conceptual job:

```text
alice      @      example.com
 user            mail domain
```

And that's why the history connects beautifully:

```text
Packet switching
      ↓
    ARPANET
      ↓
Networked computers
      ↓
   Email (1971)
      ↓
 user@host
      ↓
Internet
      ↓
user@example.com
```

**Ray Tomlinson didn't invent the `@` symbol. He chose an existing symbol and gave it its famous role in network email addressing.**


[[Networking]]