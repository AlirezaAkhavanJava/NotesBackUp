

## 1. **Definition**

A **web server** is software (sometimes bundled with hardware) that:

- **Listens** for HTTP/HTTPS requests from clients (browsers, apps).
    
- **Processes** or **forwards** those requests.
    
- **Responds** with the right content (HTML, CSS, JS, images, JSON, etc.).
    

In short: **It’s the doorman of the web** — every request knocks on the server first.

---

## 2. **How it works**

1. A browser sends `GET /index.html HTTP/1.1` to `example.com`.
    
2. DNS resolves `example.com` to the server’s IP.
    
3. TCP/IP delivers the request packet to the server on **port 80 (HTTP)** or **443 (HTTPS)**.
    
4. The **web server software** (like Apache, Nginx, Caddy) catches the request.
    
5. It decides:
    
    - Serve a **static file** (HTML, CSS, image).
        
    - Or forward the request to an **application server** (e.g., Tomcat/Spring Boot, Node.js) that generates a dynamic response.
        
6. Response (HTML/JSON/etc.) is sent back through the same TCP connection → browser renders it.
    

---

## 3. **What a web server contains**

- **Core engine** → handles HTTP requests/responses.
    
- **Configuration files** → define routes, domains, ports, SSL certificates.
    
- **Modules/plugins** → for compression, logging, reverse proxy, security.
    
- **Static file handler** → serves CSS, JS, images directly.
    
- **Reverse proxy** capability → passes requests to a backend app.
    
- **Logging system** → keeps access/error logs.
    

---

## 4. **Examples of web servers**

- **Apache HTTP Server** (classic, modular).
    
- **Nginx** (lightweight, high-performance, often used as reverse proxy).
    
- **Caddy** (auto HTTPS, modern config).
    
- **Microsoft IIS** (Windows environments).
    

---

## 5. **Web server vs application server**

- **Web server:** Handles HTTP + static content efficiently.
    
- **Application server:** Runs your backend code (Java, Python, Node).
    

Example setup:

- Nginx (web server) receives request.
    
- For `/static/logo.png` → Nginx serves it directly.
    
- For `/api/users` → Nginx forwards it to Spring Boot (application server).
    

---

👉 Brutal summary:  
A **web server is the traffic cop** of the internet. It sits on a machine, listens to HTTP requests, and either serves files or passes the request to deeper app logic.

---


#### Tags : [[0 - Back-End]]