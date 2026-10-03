

## Mental model first: sending a package

Imagine you want to send a gift to a friend in another country. You don't personally drive it there. You hand it to a chain of specialists, each doing one job and trusting the next:

1. You decide what to say and write the letter. _(Application)_
2. You translate it into a language your friend reads and seal it in a locked box. _(Presentation)_
3. You arrange the "conversation": it's a reply to an ongoing exchange. _(Session)_
4. The shipping company splits it into numbered parcels and tracks delivery. _(Transport)_
5. A router picks the route across countries using addresses. _(Network)_
6. A local courier moves it across one street or one hop. _(Data Link)_
7. The truck, plane, and road physically carry it. _(Physical)_

**Why layers exist:** each layer solves one problem and hides its complexity from the layer above. A web developer doesn't care whether the data travels over Wi-Fi or fiber. You can swap Wi-Fi for Ethernet without touching your Spring Boot app. This is separation of concerns, the same principle you use when you split a Spring app into controller, service, and repository.

**Encapsulation:** when you send data, it travels _down_ the layers, and each layer wraps it with its own header (like putting an envelope inside a bigger envelope). The receiver unwraps it going _up_.

```
Sender                                   Receiver
7 Application   [ DATA ]                 7
6 Presentation  [ DATA ]                 6
5 Session       [ DATA ]                 5
4 Transport     [TCP hdr][ DATA ]        4   → "segment"
3 Network       [IP hdr][TCP][ DATA ]    3   → "packet"
2 Data Link     [Eth hdr][IP][TCP][DATA][trailer]  2 → "frame"
1 Physical      0101101010101...         1   → "bits"
```

The unit of data at each layer has a name: data → segment → packet → frame → bits.

---

## Layer 7: Application

**What it does:** provides the network services that programs directly use. It's the layer where _meaningful messages_ are defined, such as "GET me this page" or "send this email".

**Why it exists:** programs need an agreed vocabulary. Without a shared protocol, a browser and a server couldn't understand each other.

**Protocols:** HTTP/HTTPS, DNS, SMTP, FTP, SSH.

**Example:** your browser sends:

```
GET /api/users HTTP/1.1
Host: localhost:8080
```

**Your world:** a Spring Boot `@RestController` lives here:

```java
@RestController
public class UserController {
    @GetMapping("/api/users")
    public List<String> users() {
        return List.of("Ali", "Sara");
    }
}
```

**Gotcha:** "Application layer" does _not_ mean the application (Chrome, your Java app). It means the _protocol_ the app speaks.

---

## Layer 6: Presentation

**What it does:** translates data between the app's format and a network-ready format. Three jobs: **encoding/serialization**, **compression**, **encryption**.

**Why it exists:** different machines represent data differently (character sets, byte order). This layer makes sure both sides interpret the bytes the same way.

**Examples:** UTF-8 vs ASCII, JSON/XML serialization, gzip compression, TLS encryption.

**Your world:** when Spring returns a `List<String>`, **Jackson** converts the Java object to JSON text `["Ali","Sara"]`. That's presentation-layer work.

**Gotcha:** TLS is usually _placed_ here conceptually, but it really straddles layers 5-6 (and sometimes is seen as sitting just above Transport). This is the first sign that real life doesn't fit OSI perfectly.

---

## Layer 5: Session

**What it does:** opens, manages, and closes _conversations_ between two applications. It handles things like checkpoints and resuming an interrupted exchange.

**Why it exists:** a single request isn't always enough. A video call or file transfer is an ongoing dialogue that needs to be kept organized, and recovered if it breaks.

**Examples:** NetBIOS, RPC, SQL sessions, the "login session" idea.

**Your world:** a login session with a session ID or JWT token, or a database connection kept open by HikariCP.

**Gotcha:** in the real internet (TCP/IP model), layers 5, 6, and 7 are merged into one "Application" layer. Session handling is mostly done by the application itself (cookies, tokens). That's why many engineers consider this the "fuzziest" layer.

---

## Layer 4: Transport

**What it does:** provides **end-to-end communication between processes**. It does this by:

- **Ports:** identify _which program_ on a machine gets the data (80 for HTTP, 8080 for your Spring app).
- **Segmentation:** splits large data into chunks.
- **Reliability (TCP):** acknowledgments, retransmission of lost chunks, ordering.
- **Flow/congestion control:** prevents flooding a slow receiver.

**Why it exists:** the layers below only get data to the _machine_. Something has to deliver it to the _right program_ and guarantee it arrived intact.

**TCP vs UDP:**

||TCP|UDP|
|---|---|---|
|Analogy|Registered mail with signature|Dropping postcards in a mailbox|
|Reliable|Yes|No|
|Ordered|Yes|No|
|Speed|Slower|Faster|
|Used for|Web, email, files|Video calls, gaming, DNS|

**Your world (Java code at this layer):**

```java
try (ServerSocket server = new ServerSocket(9000)) {   // listens on TCP port 9000
    Socket client = server.accept();                    // TCP handshake completed
    BufferedReader in = new BufferedReader(
        new InputStreamReader(client.getInputStream()));
    System.out.println(in.readLine());
}
```

Spring Boot's embedded Tomcat does exactly this under the hood, listening on TCP port 8080.

**Try it on Debian:**

```bash
ss -tuln          # shows listening TCP/UDP ports
```

---

## Layer 3: Network

**What it does:** **logical addressing and routing**. It gives every device an IP address and decides the path packets take across many networks.

**Why it exists:** the internet is a network of networks. You need a global address scheme and something that forwards packets hop by hop toward the destination.

**Protocols/devices:** IP (IPv4/IPv6), ICMP (used by `ping`), **routers**.

**Analogy:** a postal sorting center reading the destination country and city, then deciding which truck to put it on.

**Gotcha:** IP is **best-effort**. It doesn't guarantee delivery, order, or no duplicates. That's exactly why TCP exists above it.

**Try it:**

```bash
ip addr                 # your IP addresses
ping 8.8.8.8            # ICMP, layer 3
traceroute 8.8.8.8      # shows each router hop (install with: sudo apt install traceroute)
```

---

## Layer 2: Data Link

**What it does:** moves frames between **two directly connected devices** on the same local network. It uses **MAC addresses** (hardware addresses) and detects transmission errors.

**Why it exists:** layer 3 says _which network_ to reach, but within one network (your home Wi-Fi) someone has to deliver to the exact device. IP addresses change; MAC addresses identify the physical network card.

**Protocols/devices:** Ethernet, Wi-Fi (802.11), ARP (which maps IP to MAC), **switches**.

**Key distinction:**

- IP address = where you _are_ (changes with network, like a mailing address).
- MAC address = _who you are_ (burned into the card, like a national ID).

At each router hop, the MAC addresses change, while the IP addresses stay the same end-to-end.

**Try it:**

```bash
ip link           # shows your interfaces and MAC addresses
ip neigh          # ARP table: IP to MAC mappings
```

---

## Layer 1: Physical

**What it does:** transmits raw **bits** (0s and 1s) as electrical, light, or radio signals.

**Why it exists:** at the end of the day, data must physically move. This layer defines cables, connectors, voltages, frequencies, and timing.

**Examples:** Ethernet cable, fiber optic, Wi-Fi radio waves, hubs, repeaters, network cards.

**Gotcha:** this layer knows nothing about "data" or meaning, only signals. When your internet is down, always check here first (cable unplugged? Wi-Fi off?). A huge share of "network bugs" are layer 1.

---

## Putting it together: what happens when you open `http://localhost:8080/api/users`

1. **L7:** the browser builds an HTTP GET request.
2. **L6:** text is encoded as UTF-8 (and encrypted if HTTPS).
3. **L5:** the connection/session is established.
4. **L4:** TCP handshake, destination port 8080, data segmented.
5. **L3:** IP header added (source and destination IP).
6. **L2:** Ethernet frame with MAC addresses.
7. **L1:** bits become electrical/radio signals.

The server reverses the process upward and Tomcat hands the request to your Spring controller.

You can _see_ all these layers in a real capture:

```bash
sudo apt install wireshark     # or tcpdump
```

Wireshark literally displays each layer's header as an expandable tree.

---

## Nuances worth knowing

- **OSI is a reference model**, not what the internet actually runs. The real internet uses the **TCP/IP model** (4 layers: Link, Internet, Transport, Application). OSI is still used as the common _vocabulary_. When someone says "layer 7 load balancer" or "layer 3 firewall", they mean OSI numbering.
- **Layers leak:** ARP sits between 2 and 3, TLS between 4 and 7. Real protocols don't respect the boundaries neatly.
- **Memory trick (top to bottom):** _All People Seem To Need Data Processing._ (Bottom to top: _Please Do Not Throw Sausage Pizza Away._)

---



[[Networking]]