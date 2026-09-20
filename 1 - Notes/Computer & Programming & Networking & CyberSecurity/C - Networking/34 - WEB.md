### What is the Web?

The World Wide Web (often just called "the Web") is a system of interlinked hypertext documents and multimedia content accessed via the Internet. It was invented by Tim Berners-Lee in 1989 while working at CERN. Think of the Web as a vast collection of websites, pages, images, videos, and applications that you can navigate using hyperlinks. It's built on three core technologies:
- **HTML (HyperText Markup Language)**: Structures the content of web pages.
- **HTTP/HTTPS (HyperText Transfer Protocol/Secure)**: The protocol for transferring data between your browser and web servers.
- **URLs (Uniform Resource Locators)**: Addresses that point to specific resources on the Web.

The Web is not the same as the Internet—it's a service that runs on top of the Internet, much like email or file sharing.

---
### How the Internet Works

The Internet is a global network of interconnected computers and devices that communicate using standardized protocols. It's often described as a "network of networks." Here's a high-level overview of how it functions:

1. **Basic Architecture**:
   - Devices (like your computer, phone, or server) connect to the Internet via Internet Service Providers (ISPs) using wired (e.g., fiber optic cables) or wireless (e.g., Wi-Fi, cellular) connections.
   - These devices are organized into smaller networks (e.g., home LANs, corporate intranets) that link to larger backbone networks operated by major telecom companies.

2. **Data Transmission**:
   - Data is broken into small packets (chunks of information) for efficient transmission. Each packet includes the sender's address, receiver's address, and the data itself.
   - Packets travel across the Internet via routers, which are like traffic directors. Routers forward packets hop-by-hop through the most efficient paths, even if that means packets from the same message take different routes.
   - At the destination, packets are reassembled into the original data.

1. **Key Protocols (TCP/IP Suite)**:
   - The Internet relies on the TCP/IP (Transmission Control Protocol/Internet Protocol) model, which has layers for handling different aspects of communication:
     - **Application Layer**: Handles high-level protocols like HTTP for web browsing or SMTP for email.
     - **Transport Layer**: TCP ensures reliable, ordered delivery of data (e.g., it retransmits lost packets). UDP (User Datagram Protocol) is faster but less reliable, used for things like video streaming.
     - **Internet Layer**: IP assigns unique addresses (IPv4 like 192.168.1.1 or IPv6 like 2001:db8::1) to devices and routes packets between networks.
     - **Link Layer**: Deals with physical connections, like Ethernet for wired networks.

4. **DNS (Domain Name System)**:
   - Humans use domain names (e.g., example.com), but computers use IP addresses. DNS acts like a phonebook, translating domain names to IP addresses. When you type a URL, your device queries DNS servers to find the corresponding IP.

The Internet is decentralized—no single entity controls it entirely—and it's resilient because data can reroute around failures.

### How Browsers Work

A web browser (e.g., Chrome, Firefox, Safari) is software that retrieves, renders, and displays web content. Here's the step-by-step process:

1. **User Input**: You enter a URL (e.g., https://www.example.com) or click a link.

2. **DNS Resolution**: The browser queries DNS to convert the domain name to an IP address.

3. **Connection Establishment**: Using TCP, the browser initiates a "handshake" to connect to the server at that IP address (usually on port 80 for HTTP or 443 for HTTPS).

4. **Request Sending**: The browser sends an HTTP request to the server, specifying what it wants (e.g., GET /page.html).

5. **Server Response**: The server processes the request and sends back an HTTP response, including status codes (e.g., 200 OK, 404 Not Found) and the content (HTML, CSS, JavaScript, images).

6. **Rendering**:
   - The browser parses the HTML to build the Document Object Model (DOM), a tree-like structure representing the page.
   - It applies CSS for styling and executes JavaScript for interactivity.
   - Additional resources (like images or scripts) are fetched via more HTTP requests.
   - The rendering engine (e.g., Blink in Chrome) paints the page on your screen.

7. **Interactivity and Updates**: Browsers handle events like clicks, maintain cookies for session data, and use caching to speed up future visits.

Browsers also enforce security features, like sandboxing tabs to prevent malicious code from affecting your system.

### How HTTP and URLs Work

#### URLs
A URL is a standardized way to locate resources on the Web. It breaks down like this:
- **Scheme**: Indicates the protocol (e.g., https:// for secure web, ftp:// for file transfer).
- **Host**: The domain name or IP (e.g., www.example.com).
- **Port**: Optional; defaults to 80 for HTTP (e.g., :8080).
- **Path**: The specific resource on the server (e.g., /blog/post1).
- **Query String**: Optional parameters after ? (e.g., ?search=query&sort=asc).
- **Fragment**: Optional anchor after # (e.g., #section2), which jumps to a part of the page.

Example: https://www.example.com:443/blog/post1?search=query#section2

#### HTTP
HTTP is the protocol for requesting and delivering web content. It's stateless (each request is independent) and works in a request-response model:

1. **Request Methods**: Common ones include:
   - GET: Retrieve data (e.g., load a page).
   - POST: Send data (e.g., submit a form).
   - PUT/DELETE: Update or remove resources.

2. **Headers**: Metadata like User-Agent (browser info), Content-Type (e.g., text/html), or Authorization.

3. **Status Codes**: Responses include codes like 200 (success), 301 (redirect), 404 (not found), 500 (server error).

4. **HTTPS**: An encrypted version using SSL/TLS to secure data in transit, preventing eavesdropping.

HTTP/2 and HTTP/3 improve efficiency with multiplexing (multiple requests over one connection) and faster protocols like QUIC.

### Fundamental Networking Stuff

Here's a quick rundown of other key concepts:

- **IP Addresses**: Unique identifiers for devices. IPv4 is running out, so IPv6 is expanding the pool.
- **Ports**: Virtual endpoints on a device (0-65535) to direct traffic (e.g., web servers use 80/443).
- **Packets and Routing**: Data packets include headers with source/destination IPs. Routers use protocols like BGP (Border Gateway Protocol) for global routing.
- **Firewalls and NAT**: Firewalls block unwanted traffic; NAT (Network Address Translation) allows multiple devices to share one public IP.
- **OSI Model**: A conceptual framework with 7 layers (Physical, Data Link, Network, Transport, Session, Presentation, Application) that influenced TCP/IP.
- **Bandwidth and Latency**: Bandwidth is data transfer speed (e.g., Mbps); latency is delay (e.g., ping time in ms).
- **Wireless vs. Wired**: Wi-Fi uses radio waves; wired uses cables. Both can involve protocols like Ethernet.

[[Networking]]