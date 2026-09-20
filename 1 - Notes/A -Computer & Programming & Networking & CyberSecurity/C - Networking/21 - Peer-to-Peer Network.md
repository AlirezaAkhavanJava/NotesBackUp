
# Peer-to-Peer (P2P) Network

## Definition

A **Peer-to-Peer (P2P) Network** is a network model where **every device (peer) is equal** — each computer can act as both a **client** and a **server**. There is no central server; peers share resources (files, bandwidth, processing power) directly with each other.

**Simple version:** Everyone is equal. No boss. Every device both asks and answers.

---

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Decentralized** | No central server |
| **Equal peers** | Every node is both client and server |
| **Direct sharing** | Peers connect to each other directly |
| **Scalable** | More peers = more resources |
| **Fault-tolerant** | No single point of failure |
| **Self-organizing** | Peers find each other automatically |
| **Cheap** | No expensive server needed |

---

## How It Works (Simple Diagram)

```
        PEER-TO-PEER MODEL
        ──────────────────

        ┌──────────┐
        │  Peer A  │◄──────────┐
        │ (client  │           │
        │ + server)│           │
        └────┬─────┘           │
             │                 │
             │  direct         │
             │  connection     │
             ▼                 │
        ┌──────────┐      ┌────┴─────┐
        │  Peer B  │◄────►│  Peer C  │
        │ (client  │      │ (client  │
        │ + server)│      │ + server)│
        └────┬─────┘      └────┬─────┘
             │                 │
             └────────┬────────┘
                      ▼
                 ┌──────────┐
                 │  Peer D  │
                 │ (client  │
                 │ + server)│
                 └──────────┘

        No central server. Everyone talks to everyone.
```

---

## Types of P2P Networks

| Type | Description | Example |
|------|-------------|---------|
| **Pure P2P** | No central server at all | Early Gnutella, Freenet |
| **Hybrid P2P** | Central index server + direct transfers | Napster, BitTorrent trackers |
| **Structured P2P** | Organized using DHT (hash table) | Kademlia, BitTorrent DHT |
| **Unstructured P2P** | Peers randomly connect | Gnutella, Freenet |
| **Centralized P2P** | Central server for discovery only | Early Napster |

---

## P2P vs Client-Server

| Aspect | **Client-Server** | **Peer-to-Peer** |
|--------|-------------------|------------------|
| **Structure** | Centralized | Decentralized |
| **Roles** | Dedicated client & server | Every node is both |
| **Cost** | High (need servers) | Low (use existing PCs) |
| **Scalability** | Limited by server | Grows with peers |
| **Security** | Central control | Harder to secure |
| **Management** | Easy | Complex |
| **Single point of failure** | Yes | No |
| **Performance** | Fast, consistent | Varies by peers |
| **Data location** | One server | Spread across peers |
| **Example** | Web, email | BitTorrent, blockchain |

---

## What Problem Does P2P Solve?

| Problem | How P2P Solves It |
|---------|-------------------|
| Server too expensive | No server needed |
| Server overloaded | Load spread across peers |
| Server goes down | No single point of failure |
| Censorship | No central point to block |
| Large file distribution | Many peers share pieces |
| Central data control | Data spread across users |
| Privacy | Direct peer connections |

---

## Real-Life Analogy

| Real world | P2P |
|------------|-----|
| 🍲 Potluck dinner | Everyone brings a dish, everyone eats |
| 📚 Study group sharing notes | Everyone shares, everyone learns |
| 🤝 Friends lending tools | Direct sharing, no store |
| 🏘️ Neighborhood tool shed | No central warehouse |
| 🍕 Pizza party where everyone brings a slice | P2P file sharing |

**Compare:** Restaurant (client-server) vs Potluck (P2P).

---

## Real-World Examples

| Service | How It Uses P2P |
|---------|-----------------|
| **BitTorrent** | File sharing across peers |
| **Blockchain / Bitcoin** | Decentralized ledger |
| **Tor** | Anonymity network |
| **IPFS** | Decentralized file storage |
| **Skype (originally)** | P2P voice calls |
| **Resilio Sync** | P2P file sync |
| **WebRTC** | Browser-to-browser communication |
| **LimeWire / Napster** | Early file sharing |
| **Ethereum** | Decentralized apps |
| **Freenet** | Censorship-resistant network |

---

## Advantages & Disadvantages

| ✅ Advantages | ❌ Disadvantages |
|--------------|-----------------|
| No expensive server | Harder to manage |
| No single point of failure | Security risks |
| Scales with users | Slower if peers are slow |
| Cheap to set up | Hard to find files |
| Censorship-resistant | Legal issues (piracy) |
| Direct sharing | Peers must be online |
| Fault-tolerant | Data consistency issues |

---

## P2P Architecture Types (Visual)

```
   PURE P2P                    HYBRID P2P                STRUCTURED P2P
   ────────                    ──────────                ──────────────

   A ── B                      ┌─────────┐               A ── B
   │ ╲  │                      │ Index   │               │    │
   │  ╲ │                      │ Server  │               C ── D
   C ── D                      └────┬────┘               │    │
                                    │                    E ── F
   No server.                  A ── B ── C               (DHT ring)
   Everyone equal.             Direct transfers.         Organized lookup.
```

---

## Linux Commands Related to P2P

| Command | Definition | Example |
|---------|-----------|---------|
| `transmission-cli` | BitTorrent client | `transmission-cli file.torrent` |
| `aria2c` | Multi-protocol downloader (incl. torrent) | `aria2c file.torrent` |
| `ctorrent` | Console BitTorrent client | `ctorrent file.torrent` |
| `rtorrent` | Powerful CLI torrent client | `rtorrent file.torrent` |
| `ipfs` | InterPlanetary File System | `ipfs add file.txt` |
| `syncthing` | P2P file sync | `syncthing` |
| `resilio-sync` | P2P sync tool | `rslsync` |
| `ss` / `netstat` | Show P2P connections | `ss -tun` |
| `tcpdump` | Capture P2P traffic | `sudo tcpdump -i eth0 port 6881` |
| `nmap` | Scan P2P ports | `nmap -p 6881-6889 host` |
| `ufw` | Firewall P2P ports | `sudo ufw allow 6881` |

---

## Summary

- **P2P** = decentralized network where every peer is both client and server.
- **No central server** — peers connect directly.
- **Types:** pure, hybrid, structured, unstructured.
- **Key benefits:** cheap, scalable, fault-tolerant, censorship-resistant.
- **Key weaknesses:** hard to manage, security risks, inconsistent.
- **Examples:** BitTorrent, blockchain, IPFS, Tor, Syncthing.
- **Contrast:** Client-Server = one boss; P2P = everyone equal.


[[Networking]]