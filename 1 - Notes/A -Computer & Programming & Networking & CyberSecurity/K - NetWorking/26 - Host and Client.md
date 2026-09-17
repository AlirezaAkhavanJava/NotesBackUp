


## **HOST**

**Definition:** A host is any computer or device connected to a network that can send, receive, or process data. It can be a server, client, or both.

### Types of Hosts:

**1. Server Host**

- Provides services/resources to other computers
- Listens on specific ports for connections
- Stays running 24/7
- Examples: Web server, database server, mail server

**2. Client Host**

- Requests services from servers
- Initiates connections
- Can be turned off without affecting others
- Examples: Desktop computer, laptop, mobile phone

**3. Peer Host**

- Acts as both server and client simultaneously
- In peer-to-peer (P2P) networks
- Example: Torrent client, Skype

### Host Characteristics:

- Has a **unique IP address** on the network
- Has a **hostname** (friendly name)
- Connected to network via ethernet or WiFi
- Can run multiple services simultaneously

**Examples of Hosts:**

```
192.168.1.1        - Router (gateway host)
192.168.1.100      - Desktop computer (client host)
192.168.1.50       - Web server (server host)
8.8.8.8            - Google DNS server (server host)
10.0.0.5           - Laptop (client host)
```

---

## **CLIENT**

**Definition:** A client is a computer program or device that requests services or resources from a server. It initiates communication.

### Client Characteristics:

- **Initiates requests** - Starts the conversation
- **Sends queries** - Asks for data/services
- **Receives responses** - Gets results back
- **Dependent** - Relies on server's availability
- **Temporary connection** - Connects when needed, disconnects when done

### Types of Clients:

**1. Web Browser (HTTP Client)**

```
- Chrome, Firefox, Safari
- Requests web pages from web servers
- Displays HTML content
```

**2. Email Client (SMTP/POP3 Client)**

```
- Outlook, Thunderbird, Gmail client
- Sends emails to SMTP server
- Retrieves emails from POP3/IMAP server
```

**3. SSH Client**

```
- PuTTY, OpenSSH, Termius
- Connects to SSH server for remote access
```

**4. Database Client**

```
- MySQL Workbench, pgAdmin
- Connects to database server
- Sends SQL queries
```

**5. FTP Client**

```
- FileZilla, WinSCP
- Connects to FTP server
- Uploads/downloads files
```

---

## **HOST vs CLIENT - Key Differences**

|Aspect|Host|Client|
|---|---|---|
|**Definition**|Any device on network|Program/device requesting service|
|**Role**|Can be server or client|Always requests services|
|**Initiates**|Can receive or initiate|Always initiates|
|**Runs Services**|May run services|Uses services|
|**Connection**|Can receive connections|Initiates connections|
|**Dependency**|Can work independently|Depends on server|

---

## **CLIENT-SERVER MODEL**

### How They Interact:

```
┌─────────────────────────────────────────────────────┐
│                    NETWORK                          │
│                                                     │
│  ┌─────────────┐              ┌─────────────────┐   │
│  │   CLIENT    │              │      HOST       │   │
│  │  (Requester)│              │   (Responder)   │   │
│  │             │              │                 │   │
│  │ • Initiates │ ──Request──> │ • Receives      │   │
│  │ • Sends data│              │ • Processes     │   │
│  │ • Waits for │              │ • Sends back    │   │
│  │   response  │ <─Response─  │                 │   │
│  └─────────────┘              └─────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Example: Web Browsing

```
CLIENT (Your Browser)          NETWORK           HOST (Web Server)
─────────────────────          ───────           ──────────────────

1. User types URL
   ↓
2. DNS lookup: example.com → 93.184.216.34
   ↓
3. Browser sends HTTP request ──────────────────> Server receives request
   GET / HTTP/1.1                                 
   Host: example.com                              Processes request
   User-Agent: Chrome                             
   ↓                                              ↓
                                                  Looks up page
                                                  Generates HTML
                                                  Prepares response
   ↓                                              ↓
4. Browser receives response <────────────────── Server sends response
   HTTP/1.1 200 OK                               HTTP/1.1 200 OK
   Content-Type: text/html                       Content-Type: text/html
   Content-Length: 1234                          <HTML content>
   ↓
5. Browser renders HTML
   Displays webpage to user
```

---

## **PRACTICAL EXAMPLES**

### Example 1: Email

```
EMAIL CLIENT (Thunderbird)         EMAIL SERVERS (Hosts)
──────────────────────             ─────────────────────

User writes email
         ↓
Client connects to SMTP server
(smtp.gmail.com:587)
         ↓
SMTP Server receives email
         ↓
Server stores in recipient's mailbox
         ↓
Recipient's email client connects
to POP3/IMAP server
         ↓
Client retrieves email
         ↓
User reads email
```

### Example 2: Database Access

```
DATABASE CLIENT              DATABASE HOST
(MySQL Workbench)            (MySQL Server)
──────────────────           ──────────────

1. User clicks "Run Query"
   ↓
2. Client sends SQL query ───────────> Server receives SQL
   "SELECT * FROM users"              
                                       Executes query
                                       ↓
                                       Returns result set
3. Client receives results <────────── Server sends data
   ↓                                   
4. Displays results to user
```

### Example 3: SSH Access

```
SSH CLIENT              SSH HOST (Server)
(Your Laptop)           (Remote Server)
──────────────          ─────────────────

User runs:
ssh user@192.168.1.50
         ↓
Client connects to port 22
         ↓
Server receives connection ──────────>
         ↓
Server sends SSH banner
         ↓
Client receives <───────────
         ↓
User enters password
         ↓
Client sends credentials ──────────>
         ↓
Server authenticates
         ↓
Server grants access <───────────
         ↓
User gets remote shell prompt
```

---

## **SPECIAL CASES**

### 1. **Peer-to-Peer (P2P)**

- Every participant is both client AND host
- No central server
- Example: BitTorrent, Skype

```
Peer A ←──────────→ Peer B
(Client & Server)  (Client & Server)
  ↓                  ↓
Acts as client when requesting data
Acts as server when sharing data
```

### 2. **Localhost**

- A host that refers to itself
- IP address: `127.0.0.1`
- Used for development/testing

```
Client program        Server program
    ↓                       ↓
  (both on same machine)
  
Example: Your browser connects to
http://localhost:8000
→ The computer acts as both client AND server
```

### 3. **Multiple Connections**

```
One Server Host        Multiple Client Hosts
(Example: Web Server)  ─────────────────────

Client 1 ──┐
Client 2 ──┼──> Server
Client 3 ──┤
Client 4 ──┘

Server handles multiple simultaneous client connections
```

---

## **REAL-WORLD ANALOGY**

Think of a restaurant:

```
RESTAURANT (HOST/SERVER)
├─ Listens for customers (listens on port)
├─ Processes orders (processes requests)
├─ Prepares food (generates response)
└─ Serves customers (sends response)

CUSTOMER (CLIENT)
├─ Comes to restaurant (connects)
├─ Places order (sends request)
├─ Waits for food (waits for response)
└─ Eats food (receives and uses response)

MULTIPLE CUSTOMERS = MULTIPLE CLIENTS
Restaurant serves all customers = Server handling multiple clients
```

---

## **KEY NETWORKING CONCEPTS**

### Host Identification:

```
Every host has:

1. IP Address (like home address)
   └─ IPv4: 192.168.1.100
   └─ IPv6: 2001:0db8::1

2. Hostname (like person's name)
   └─ webserver.example.com
   └─ desktop-pc
   └─ localhost

3. MAC Address (physical address)
   └─ 00:1A:2B:3C:4D:5E
```

### Client Connection Process:

```
1. CLIENT SENDS REQUEST
   - Opens socket
   - Specifies server host IP + port
   - Sends data to server
   
2. HOST RECEIVES REQUEST
   - Listens on port
   - Accepts connection
   - Reads client data
   
3. HOST SENDS RESPONSE
   - Processes request
   - Sends response back
   - Closes or keeps connection
   
4. CLIENT RECEIVES RESPONSE
   - Reads server data
   - Processes response
   - Displays to user
   - Closes connection
```

---

## **SUMMARY**

|Concept|Meaning|
|---|---|
|**Host**|Any device on network; can be server, client, or both|
|**Client**|Program/device that requests services from a host|
|**Server**|Host that provides services to clients|
|**Request**|Message from client asking for service|
|**Response**|Message from host providing service|
|**Port**|Virtual "door" where host listens for clients|
|**Connection**|Communication link between client and host|

The client-server model is fundamental to how the internet works. Every time you:

- Browse the web
- Send an email
- Access a database
- Stream a video
- Play an online game

...you're using a client connecting to a host to request services!

[[Networking]]