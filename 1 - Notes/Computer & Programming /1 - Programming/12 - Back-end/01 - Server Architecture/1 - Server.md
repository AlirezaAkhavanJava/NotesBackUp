


## 1. **What a server is**

- At the core, a **server = computer + software that listens for requests and responds**.
    
- Unlike your PC that waits for _you_ to open programs, a server is designed to sit there, 24/7, and answer other machines (clients) over a network.
    

Think: **a waiter in a restaurant**. Customers (clients) ask for stuff, waiter (server) brings it, maybe fetching from the kitchen (database).

---

## 2. **How a server works**

1. **Hardware layer** – Just like a normal computer but often more powerful: CPU, RAM, storage, NIC (network card). Can be physical (bare metal) or virtual (cloud VM, container).
    
2. **Operating system** – Usually Linux (Ubuntu, Debian, CentOS) because it’s stable. Handles processes, memory, networking.
    
3. **Networking stack** –
    
    - Listens on ports (e.g., port 80 for HTTP, 443 for HTTPS).
        
    - Uses TCP/IP to establish connections with clients.
        
    - Every request/response is just packets flying over the network.
        
4. **Server software** – Runs on top of the OS. This is what actually _responds_:
    
    - **Web servers**: Nginx, Apache, Caddy. They handle HTTP requests.
        
    - **App servers**: Tomcat, Jetty, Node.js runtime, etc. They run your backend code.
        
5. **Application code** – Your actual web app (Java Spring, Express.js, etc.). This is the logic that makes the server _useful_.
    
6. **Data layer** – Often tied to a database or cache. The server app queries this to provide dynamic responses.
    

---

## 3. **What a server contains**

Depending on what it’s running, a typical web server stack has:

- **OS tools** (Linux utilities, shells, system services).
    
- **Web server software** (Nginx/Apache) to handle HTTP.
    
- **Runtime environment** (Java, Node.js, Python, PHP) to run apps.
    
- **Application code** (your web app logic).
    
- **Databases** (PostgreSQL, MySQL, MongoDB, Redis).
    
- **Configuration files** (port numbers, domains, SSL certs, reverse proxy rules).
    
- **Logs** (error logs, access logs, app logs).
    

---

## 4. **How the cycle actually looks**

1. Client (browser) sends request → travels through internet → reaches server’s IP.
    
2. Server’s OS receives the packet → networking stack routes it to the correct port.
    
3. Web server software (like Nginx) grabs it → decides if it should serve a static file (HTML, image, CSS) or pass it to the app.
    
4. If app needed → web server forwards to **application server** (Tomcat/Spring Boot/Node).
    
5. Application server executes your code → possibly queries DB.
    
6. App builds a response (HTML/JSON).
    
7. Web server sends the response back over TCP/IP → browser receives it → renders it.
    

---

## 5. **Types of servers**

- **Web server** → serves websites and web apps.
    
- **Database server** → only stores/manages data.
    
- **File server** → stores files.
    
- **Mail server** → handles email.
    
- **Application server** → runs business logic.
    

---

## Brutal summary 🪓

A **server = machine that never sleeps, connected to the internet, listening on a port, running software that handles requests and gives back responses**. Everything else (web app, database, files, configs) is layered on top.

---



#### Tags : [[0 - Back-End]]