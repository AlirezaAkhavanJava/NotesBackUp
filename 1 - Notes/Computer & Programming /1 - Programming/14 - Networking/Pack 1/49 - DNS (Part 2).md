
![[Pasted image 20260921204917.png]]



# How DNS Actually Works — A Practical Walkthrough

The infographic gets the core flow right, but it simplifies a few things and skips some details that matter once you're actually working with DNS (which you will be, deploying Spring Boot apps). Let's go through it properly, and I'll flag corrections as we go.

## 1. Before DNS even starts: the hosts file

**Missing from the infographic:** before checking any cache, your OS checks a local file called `/etc/hosts` (on Debian, same on Linux/Mac). If there's a manual entry for `example.com` there, DNS is skipped entirely. This is how you can hijack local domain resolution for testing.

```bash
cat /etc/hosts
```

## 2. The cache chain (infographic steps 1–2)

The lookup order is actually:

1. Browser cache
2. OS resolver cache (`systemd-resolved` on Debian 13)
3. Router/local network cache (sometimes)
4. **Recursive resolver** cache

**Correction:** the infographic calls this "the ISP's recursive DNS server" — that's true by default, but most people (and most servers) configure a _different_ recursive resolver, like Google's `8.8.8.8`, Cloudflare's `1.1.1.1`, or Quad9's `9.9.9.9`. Your ISP is just the default if you haven't changed it. On Debian, check yours:

```bash
resolvectl status
```

## 3. Root → TLD → Authoritative (infographic steps 3–8)

This part is correct and is the real heart of DNS. It's a **hierarchical** system:

- **Root nameservers** (13 logical root server addresses, run via anycast by multiple operators worldwide) don't know `example.com` — they only know which server handles `.com`.
- **TLD nameservers** (for `.com`, `.io`, `.net`, etc.) don't know the IP either — they know which server is _authoritative_ for `example.com` specifically.
- **Authoritative nameserver** holds the actual DNS records and gives the final answer.

**One correction:** the infographic shows the recursive resolver querying each of these directly, which is accurate for a _recursive_ query — but technically the root and TLD servers give back _referrals_ ("ask this other server"), not final answers, until you reach the authoritative server. Only the authoritative server gives an actual answer.

You can watch this entire chain happen yourself:

```bash
dig +trace example.com
```

This traces root → TLD → authoritative live, which is a great way to see the diagram in action.

## 4. What's missing: DNS record types

The infographic only ever mentions "the IP address," but DNS returns different **record types** depending on what's asked:

|Record|Purpose|
|---|---|
|`A`|Domain → IPv4 address|
|`AAAA`|Domain → IPv6 address|
|`CNAME`|Domain → another domain name (alias)|
|`MX`|Mail server for the domain|
|`TXT`|Arbitrary text (SPF, domain verification, etc.)|
|`NS`|Which nameservers are authoritative|

Try it:

```bash
dig example.com A
dig example.com MX
dig example.com NS
```

## 5. What's missing: caching has an expiry (TTL)

The infographic says the ISP "caches this locally for future use" (step 8) but doesn't mention **TTL (Time To Live)** — every DNS record comes with a TTL in seconds, telling resolvers how long they're allowed to cache it before asking again. This is why DNS changes (e.g. pointing a domain to a new server) can take minutes to hours to propagate — everyone's cache has to expire first.

```bash
dig example.com | grep -A1 "ANSWER SECTION"
```

The number next to the record is its TTL.

## 6. What's missing: the protocol layer

- Queries typically use **UDP port 53** (fast, no handshake); DNS falls back to **TCP port 53** for large responses.
- Standard DNS is **unencrypted and unauthenticated** — anyone on the network path can see (and theoretically spoof) your queries. This is why **DNS over HTTPS (DoH)** and **DNS over TLS (DoT)** exist — increasingly the default in browsers like Firefox.

## 7. One conflation to fix: step 10

The infographic's final step ("browser loads the website content") glosses over a lot. Getting the IP address is only the end of DNS — after that, the browser still has to:

1. Open a TCP connection to that IP (three-way handshake)
2. Perform a TLS handshake (if HTTPS)
3. Send the actual HTTP request
4. Receive and render the response

DNS resolution is _step zero_ of loading a page, not the loading itself.

---

### Quick summary — corrected flow

```
Browser cache → OS cache → hosts file (skipped if empty)
    → Recursive resolver cache (ISP or 8.8.8.8/1.1.1.1/etc.)
        → Root nameserver (referral to TLD)
            → TLD nameserver (referral to authoritative)
                → Authoritative nameserver (final answer + TTL)
    ← cached by resolver until TTL expires
← IP returned to browser
→ TCP handshake → TLS handshake → HTTP request → page loads
```




[[Networking]]