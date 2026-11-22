

Nginx (pronounced "engine-x") is a high-performance **web server** that also commonly works as a **reverse proxy**, **load balancer**, and **HTTP cache**. At its core, Nginx listens for incoming HTTP/HTTPS requests and decides what to do with them — serve a static file directly, or forward the request to another server (like your Spring Boot app) and relay the response back. It was built specifically to handle a huge number of simultaneous connections with very little memory and CPU, which is why it's one of the most widely deployed pieces of infrastructure software in existence.

The reason Nginx exists alongside something like embedded Tomcat (which already serves HTTP) comes down to architecture: Tomcat is good at running your Java application logic, but it's not the best tool for everything a production-facing server needs to do — TLS termination, serving static assets efficiently, compressing responses, rate-limiting, or distributing traffic across multiple app instances. Nginx sits in front of your app and handles that layer, so your Spring Boot process can focus purely on business logic.

## How Nginx processes a request

Nginx is built around an **event-driven, asynchronous** architecture rather than the thread-per-connection model many servers use. A small number of **worker processes** each handle thousands of connections concurrently using non-blocking I/O, instead of spinning up a new OS thread per request. This is the architectural reason Nginx can handle massive concurrent load on modest hardware — it's not doing more work per request, it's doing it with far less overhead per connection.

## The reverse proxy role (most relevant to your Spring app)

A **reverse proxy** sits between the client and your backend, forwarding client requests to the backend and returning the backend's response as if it came from the proxy itself. The client never talks to Tomcat/Spring directly — it only ever sees Nginx.

```nginx
server {
    listen 80;
    server_name myapp.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

`proxy_pass` is the directive that actually forwards the request to your Spring Boot app running on port 8080. The `proxy_set_header` lines matter because, without them, your Spring app would see every request as coming from `127.0.0.1` (Nginx itself) instead of the real client IP — Spring Security's `request.getRemoteAddr()`, audit logging, and rate-limiting logic all depend on these headers being passed through correctly.

## Why you'd put Nginx in front of Spring Boot specifically

- **TLS/SSL termination** — Nginx handles the HTTPS handshake and certificate management once, so your Spring app only ever deals with plain HTTP internally. Simpler certs, simpler app config.
- **Serving static files** — if your app serves any static assets (JS, CSS, images), Nginx can serve them directly from disk without ever touching your JVM, which is far faster and frees Tomcat's threads for actual application work.
- **Load balancing** — if you run multiple instances of your Spring Boot app (for scaling or zero-downtime deploys), Nginx can distribute incoming requests across them:

```nginx
upstream spring_app {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
}

server {
    listen 80;
    location / {
        proxy_pass http://spring_app;
    }
}
```

- **Buffering and protecting slow clients** — Nginx can fully receive a slow client's request before handing it to your app, so a slow network connection doesn't tie up a Tomcat worker thread for the whole duration.
- **Rate limiting and basic security filtering** — things like `limit_req` can block abusive traffic before it ever reaches your JVM.

## A related concept, briefly

**Load balancer** is a term that comes up constantly alongside Nginx: it just means a component that spreads incoming traffic across multiple backend instances so no single instance is overwhelmed. Nginx can act as one (as shown above), but dedicated load balancers (hardware or cloud-based, like an AWS ELB) exist too — the `upstream` block is Nginx's built-in way of doing the same job in software.


[[Java]]
[[System Design]]