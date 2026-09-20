

## Definition

A **server** is a software application or hardware device that provides resources, data, or services to other computers (called **clients**) over a network. The server-client architecture follows a request-response model: clients send requests, and servers process and return responses.

---

## Problems That Led to Server Architecture

Before centralized servers existed, computing faced several challenges:

### 1. **Data Redundancy & Inconsistency**

- Each computer stored its own data independently
- Multiple copies led to conflicts and inconsistent information
- **Solution**: Centralized data storage on a single server

### 2. **Resource Inefficiency**

- Every machine needed expensive hardware (storage, processing power)
- Poor utilization of resources across the organization
- **Solution**: Servers consolidated resources, allowing clients to be "thin" (low-spec)

### 3. **Scalability Issues**

- Peer-to-peer systems couldn't handle growing user bases
- No clear way to manage many users connecting simultaneously
- **Solution**: Dedicated servers handle multiple clients efficiently

### 4. **Security & Access Control**

- No centralized way to manage user permissions
- Data stored locally was vulnerable
- **Solution**: Servers enable centralized authentication and authorization

### 5. **Maintenance & Updates**

- Updates had to be deployed to every machine individually
- **Solution**: Update the server once, all clients benefit immediately

---

## How Servers Work

### Basic Server Architecture

```
┌─────────────────────────────────────────┐
│         SERVER                          │
│  ┌──────────────────────────────────┐   │
│  │  Listen on Port (e.g., 80, 443)  │   │
│  └──────────────────────────────────┘   │
│           ↓ ↓ ↓                         │
│  ┌──────────────────────────────────┐   │
│  │  Accept Client Connections       │   │
│  └──────────────────────────────────┘   │
│           ↓ ↓ ↓                         │
│  ┌──────────────────────────────────┐   │
│  │  Process Requests                │   │
│  │  (Query data, execute logic)     │   │
│  └──────────────────────────────────┘   │
│           ↓ ↓ ↓                         │
│  ┌──────────────────────────────────┐   │
│  │  Send Response Back to Client    │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
       ↑         ↑         ↑
    Client 1  Client 2  Client 3
```

### Key Concepts

**1. Listening on Ports**

- Servers "listen" on specific network ports (0-65535)
- Common ports: 80 (HTTP), 443 (HTTPS), 22 (SSH), 3306 (MySQL)

**2. Multithreading/Concurrency**

- Servers handle multiple client connections simultaneously
- Uses threads, processes, or async I/O

**3. Request-Response Cycle**

- Client sends a formatted request (HTTP, FTP, SSH, etc.)
- Server parses it, processes it, and sends back a response

**4. Persistence**

- Servers run continuously (24/7)
- Maintain state and data across requests

---

## Essential Linux Commands for Servers

### Network & Port Management

```bash
# Check listening ports and connections
netstat -tuln                    # Show all listening sockets
ss -tuln                         # Modern alternative to netstat
ss -tunlp                        # Show process info too

# Show established connections
netstat -an | grep ESTABLISHED
ss -an | grep ESTABLISHED

# Check specific port
lsof -i :8080                    # Show process using port 8080
netstat -tuln | grep :3306       # Check if MySQL is listening
```

### Process Management

```bash
# Start a server
./myserver &                     # Run in background
nohup ./myserver &               # Run, immune to hangups

# View running processes
ps aux | grep server             # Find server processes
top -p [PID]                     # Monitor specific process

# Control servers
systemctl start nginx            # Start service (systemd)
systemctl status apache2         # Check status
systemctl stop mongodb           # Stop service
systemctl restart postgresql     # Restart service

# View system services
systemctl list-units --type=service
```

### Log Monitoring

```bash
# View server logs
tail -f /var/log/apache2/access.log        # Real-time Apache logs
tail -n 50 /var/log/nginx/error.log        # Last 50 lines
journalctl -u nginx -f                     # systemd logs, follow mode
journalctl -u mysql -n 100                 # Last 100 MySQL log entries
```

### Connection Testing

```bash
# Test if server is responding
curl http://localhost:8080                 # Make HTTP request
curl -I http://example.com                 # Headers only
nc -zv localhost 3306                      # Check if port is open
telnet localhost 22                        # Test SSH connection

# DNS lookups
nslookup example.com
dig example.com
host example.com
```

### Server Performance & Resources

```bash
# CPU, Memory, Disk usage
top                              # Real-time system monitor
htop                             # Enhanced top
free -h                          # Memory usage (human-readable)
df -h                            # Disk space usage
du -sh /var/www                  # Directory size

# Network stats
iftop                            # Network bandwidth usage
vnstat                           # Network traffic statistics
ss -s                            # Socket statistics
```

### Starting/Stopping Common Servers

```bash
# Web Servers
sudo systemctl start nginx
sudo systemctl start apache2

# Databases
sudo systemctl start mysql
sudo systemctl start postgresql
sudo systemctl start mongodb

# Other common services
sudo systemctl start ssh
sudo systemctl start redis-server
sudo systemctl start node-app     # Custom Node.js app
```

### Creating Custom Systemd Services

```bash
# Create service file
sudo nano /etc/systemd/system/myapp.service

# Content:
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=myuser
ExecStart=/usr/local/bin/myapp
Restart=always

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
```

### Firewall & Security

```bash
# UFW (Uncomplicated Firewall)
sudo ufw allow 22/tcp            # Allow SSH
sudo ufw allow 80/tcp            # Allow HTTP
sudo ufw allow 443/tcp           # Allow HTTPS
sudo ufw status                  # Check firewall status

# iptables (advanced)
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

---

## Common Server Types & Ports

|Server Type|Port|Purpose|
|---|---|---|
|HTTP (Web)|80|Serve web pages|
|HTTPS (Secure Web)|443|Encrypted web traffic|
|SSH|22|Remote shell access|
|MySQL|3306|Database|
|PostgreSQL|5432|Database|
|MongoDB|27017|NoSQL Database|
|Redis|6379|In-memory cache|
|FTP|21|File transfer|
|SMTP|25, 587|Email sending|
|POP3|110|Email receiving|

---

## Example: Simple Python Server

```bash
# Start a basic HTTP server on port 8000
python3 -m http.server 8000

# In another terminal, test it
curl http://localhost:8000

# Check what's listening
ss -tuln | grep 8000
```

This covers the fundamentals! Would you like me to dive deeper into any specific server type (web, database, etc.) or explore more advanced Linux server management?


[[Networking]]