
# VPN (Virtual Private Network)

## Definition

A **VPN** (Virtual Private Network) is a technology that creates a **secure, encrypted tunnel** between your device and another network (or server) over the public internet. It makes your traffic **private** and makes it appear as if you're connecting from a different location.

**Simple version:** A VPN hides and protects your internet traffic by routing it through a secure tunnel.

---

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Encryption** | Scrambles your data so nobody can read it |
| **Tunneling** | Wraps your data in a protected "tunnel" over the internet |
| **IP masking** | Hides your real IP, shows the VPN server's IP |
| **Authentication** | Verifies both ends of the connection |
| **Protocols** | OpenVPN, WireGuard, IPSec, L2TP, PPTP |
| **Scope** | Works over any network (LAN, WAN, internet) |

---

## How a VPN Works (Simple Diagram)

```
   WITHOUT VPN                          WITH VPN
   ─────────────                        ──────────

   💻 You                               💻 You
    |                                    |
    | (plain data, visible)              | (encrypted tunnel)
    ▼                                    ▼
   🌐 Internet                          🔒 VPN Server
    |                                    |
    | (hackers/ISP can see)              | (decrypted here)
    ▼                                    ▼
   🖥️ Website                           🌐 Internet
                                         |
                                         ▼
                                        🖥️ Website
                                        (sees VPN's IP, not yours)
```

---

## What Problem Does VPN Solve?

| Problem | How VPN Solves It |
|---------|-------------------|
| ISP/others spying on your traffic | Encrypts everything |
| Public Wi-Fi is unsafe | Protects data on open networks |
| Your real IP is exposed | Masks IP with VPN server's IP |
| Geo-blocked content | Appear from another country |
| Remote workers need office access | Secure tunnel into company LAN |
| Censorship in some countries | Bypasses blocks |
| Site-to-site connectivity | Links two LANs securely over internet |

---

## Types of VPN

| Type | Description | Example |
|------|-------------|---------|
| **Remote Access VPN** | Single user connects to a private network | Working from home → office |
| **Site-to-Site VPN** | Connects two entire networks | Office in London ↔ Office in Tokyo |
| **Client-based VPN** | Software on your device | NordVPN, OpenVPN app |
| **SSL/TLS VPN** | Browser-based access | Corporate web portal |
| **Personal/Commercial VPN** | For privacy/streaming | ExpressVPN, ProtonVPN |

---

## VPN vs Related Concepts

| Aspect | **VPN** | **Proxy** | **Tor** |
|--------|---------|-----------|---------|
| Encryption | Yes (strong) | Usually no | Yes (multi-layer) |
| Speed | Fast | Fast | Slow |
| Anonymity | Medium | Low | High |
| Scope | Whole device | App/browser only | Browser/app |
| Use case | Privacy, remote work | Bypass blocks | Strong anonymity |

---

## Common VPN Protocols

| Protocol | Speed | Security | Notes |
|----------|-------|----------|-------|
| **OpenVPN** | Good | Excellent | Open-source, widely used |
| **WireGuard** | Excellent | Excellent | Modern, lightweight |
| **IPSec/IKEv2** | Good | Excellent | Great for mobile |
| **L2TP/IPSec** | Medium | Good | Often blocked |
| **PPTP** | Fast | Weak | Obsolete, avoid |

---

## Real-Life Analogy

| Real world | VPN |
|------------|-----|
| 🚗 Driving on a public road (everyone sees you) | Normal internet |
| 🚇 Driving through a private tunnel (nobody sees you) | VPN |
| 🎭 Wearing a mask so nobody knows you | IP masking |
| 🏢 Entering a building through a secret back door | Remote access VPN |

---

## Summary

- **VPN** = encrypted tunnel over the internet for privacy and security.
- **Hides your IP** and **protects your data** from snoopers.
- **Used for:** privacy, public Wi-Fi safety, remote work, bypassing geo-blocks, site-to-site links.
- **Key tech:** OpenVPN, WireGuard, IPSec.
- **Not the same as:** proxy (no encryption) or Tor (different design).


[[Networking]]