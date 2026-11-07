

## 1. What is `.com`?

A domain such as:

```text
www.example.com
```

has a hierarchy:

```text
www     .    example    .    com
│             │              │
host        domain          TLD
```

`.com` is a **TLD** — the highest level of the domain name visible to normal users.

---

## 2. Why were these created?

Before DNS, ARPANET used a centrally maintained `HOSTS.TXT` file.

As the network grew, that became difficult to manage.

DNS introduced a **hierarchical naming system**:

```text
                         .
                         │
              ┌──────────┼──────────┐
             com        org        net
              │
           example
              │
             www
```

This allowed different organizations to manage different parts of the namespace.

---

# 3. Who created `.com`?

The original TLDs were introduced as part of the **DNS system in 1985**.

The initial generic TLDs included:

```text
.com   → commercial
.edu   → educational institutions
.gov   → U.S. government
.mil   → U.S. military
.net   → network-related organizations
.org   → organizations
.int   → international organizations
```

The DNS itself was designed primarily by **Paul Mockapetris** in 1983, but the creation and administration of the original top-level namespace involved the **Internet community and Internet naming authorities**, particularly the early **NIC (Network Information Center)** at SRI.

So don't think:

> "Mockapetris invented `.com`."

That's too simplistic.

More accurately:

> **DNS provided the hierarchical naming architecture, and the original TLD namespace was established through the Internet's early naming/registration administration.**

---

# 4. What did `.com` actually mean?

Originally:

**`.com` = commercial**

It was intended for commercial organizations.

For example:

```text
company.com
```

The idea was that the suffix itself gave you information about the organization.

Similarly:

```text
university.edu
government.gov
organization.org
network.net
```

---

# 5. `.net` is interesting

`.net` originally meant **network**.

It was intended primarily for organizations involved in networking infrastructure.

It wasn't originally intended to be:

> "A second `.com` for anyone who wants one."

That is effectively what happened later.

---

# 6. `.org`

`.org` meant **organization**.

It was intended for organizations that didn't fit the other categories.

For example:

```text
something.org
```

became strongly associated with nonprofits and public-interest organizations, although `.org` was never strictly limited to nonprofits.

---

# 7. `.edu`, `.gov`, `.mil`

These were much more restricted.

```text
.edu
 ↓
educational institutions

.gov
 ↓
U.S. government

.mil
 ↓
U.S. military
```

Notice something important:

**`.gov` and `.mil` are specifically associated with the United States.**

That comes from the historical structure of the original Internet.

---

# 8. Then came country-code TLDs

DNS also introduced **country-code TLDs (ccTLDs)**.

Examples:

```text
.ir → Iran
.uk → United Kingdom
.de → Germany
.fr → France
.jp → Japan
.us → United States
```

These use the **ISO 3166 country-code system** as their basis.

So:

```text
example.com
        ↑
      generic TLD

example.ir
        ↑
     country-code TLD
```

---

# 9. The important distinction

Don't confuse:

```text
DNS
```

with:

```text
.com
```

DNS is the **entire naming and resolution system**.

`.com` is merely **one branch of that hierarchy**.

For example:

```text
                       DNS
                        │
                        .
                        │
             ┌──────────┼───────────┐
             │          │           │
            com        org         ir
             │          │           │
          google      wikipedia   example
             │
           google
             │
            www
```

When you type:

```text
www.google.com
```

DNS can ultimately resolve that name to an IP address.

---

# 10. Why `.com` became so dominant

Originally:

```text
.com = commercial organization
```

But as the Web exploded in the 1990s:

```text
Internet
   ↓
World Wide Web
   ↓
Businesses create websites
   ↓
.com becomes extremely desirable
   ↓
.com becomes the default commercial domain
```

Eventually `.com` became so culturally associated with the Internet that many people started treating:

> **domain = `.com`**

even though there are hundreds of other TLDs today.

---

## Historical chain

This fits directly into what we've been studying:

```text
ARPANET
   ↓
TCP/IP
   ↓
DNS (1983)
   ↓
Original TLDs (1985)
   │
   ├── .com
   ├── .org
   ├── .net
   ├── .edu
   ├── .gov
   └── .mil
   ↓
World Wide Web (1990)
   ↓
Mosaic (1993)
   ↓
Netscape (1994)
   ↓
Internet Explorer (1995)
   ↓
Commercial Web explosion
   ↓
.com becomes dominant
```

So **`.com` wasn't created because the Web needed "website endings."** It existed **before the Web**, as part of the DNS naming architecture. The Web later made it enormously important.

[[Networking]]