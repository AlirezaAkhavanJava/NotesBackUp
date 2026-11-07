

> **URL identifies a resource → DNS finds the server → HTTP transfers the resource → HTML describes a web page → WWW is the overall system that ties these ideas together.**

Let's build the history and the roles.

---

# 1. WWW — World Wide Web

The **World Wide Web** is a system for accessing and linking documents/resources over the Internet.

It was invented by **Tim Berners-Lee** at CERN around **1989–1990**.

The Web was built from several technologies:

```text
             WORLD WIDE WEB
                    │
       ┌────────────┼────────────┐
       │            │            │
      URL          HTTP         HTML
       │            │            │
 identifies      transfers    describes
 resources       resources    documents
```

The important distinction:

> **The Internet is the network. The Web is a service/system that runs on top of that network.**

For example:

```text
Internet
│
├── Email
├── SSH
├── DNS
├── BitTorrent
└── World Wide Web
       │
       ├── HTTP
       ├── HTML
       └── URLs
```

So the Web is **not the Internet itself**.

---

# 2. HTML

**HTML = HyperText Markup Language.**

HTML describes the **structure and meaning of a web document**.

For example:

```html
<h1>Hello</h1>

<p>This is my website.</p>

<a href="https://example.com">Visit</a>
```

The browser interprets this and creates a document:

```text
Hello

This is my website.

Visit
```

HTML gives the browser information such as:

```text
<h1>       heading
<p>        paragraph
<a>        hyperlink
<img>      image
<form>     form
```

### Why was HTML needed?

Before the Web, documents existed, but Berners-Lee wanted a system where documents could contain **links to other documents**.

That's the **hypertext** part.

For example:

```text
Document A
    │
    │ hyperlink
    ▼
Document B
    │
    │ hyperlink
    ▼
Document C
```

This creates the interconnected Web.

---

# 3. HTTP

**HTTP = Hypertext Transfer Protocol.**

HTTP defines how a client and server communicate to transfer Web resources.

For example, your browser might send:

```http
GET /index.html HTTP/1.1
Host: example.com
```

The server responds:

```http
HTTP/1.1 200 OK
Content-Type: text/html

<html>
    ...
</html>
```

So:

```text
Browser
   │
   │ HTTP request
   ▼
Web server
   │
   │ HTTP response
   ▼
Browser
```

HTTP doesn't define HTML.

It defines **the communication protocol used to request and transfer resources**.

That distinction matters.

```text
HTML
  = What is the document?

HTTP
  = How do we transfer the document?
```

---

# 4. URL

**URL = Uniform Resource Locator.**

A URL tells you **where/how to access a resource**.

Example:

```text
https://example.com/articles/networking.html
```

Break it apart:

```text
https://
   │
   └── scheme

example.com
   │
   └── host

/articles/networking.html
   │
   └── path
```

A more complete URL can look like:

```text
https://example.com:443/articles?id=42#networking
```

```text
https://
   │
   └── scheme

example.com
   │
   └── host

:443
   │
   └── port

/articles
   │
   └── path

?id=42
   │
   └── query

#networking
   │
   └── fragment
```

The URL gives the client enough information to identify/access the resource.

---

# 5. How they work together

Suppose you type:

```text
https://example.com/index.html
```

into your browser.

### Step 1 — URL

The browser parses:

```text
scheme = https
host   = example.com
path   = /index.html
```

### Step 2 — DNS

The browser needs the server's IP address:

```text
example.com
      ↓
     DNS
      ↓
93.184.216.34
```

### Step 3 — connection

The browser establishes the appropriate network connection to the server.

For HTTPS, this involves:

```text
TCP
 ↓
TLS
```

### Step 4 — HTTP

The browser sends an HTTP request:

```http
GET /index.html HTTP/1.1
Host: example.com
```

### Step 5 — server responds

The server returns:

```http
HTTP/1.1 200 OK
Content-Type: text/html

<html>
...
</html>
```

### Step 6 — HTML

The browser parses the HTML:

```html
<h1>Hello</h1>
<p>Welcome.</p>
```

and constructs the page you see.

So the complete flow is:

```text
                  URL
                   │
                   ▼
            https://example.com
                   │
                   ▼
                  DNS
                   │
                   ▼
              IP address
                   │
                   ▼
              TCP + TLS
                   │
                   ▼
                 HTTP
                   │
             GET /index.html
                   │
                   ▼
              Web Server
                   │
             HTTP response
                   │
                   ▼
                 HTML
                   │
                   ▼
                Browser
                   │
                   ▼
              Rendered page
```

---

# 6. Who invented what?

|Technology|Creator|Approx. date|
|---|---|--:|
|**WWW**|Tim Berners-Lee|1989–1990|
|**HTML**|Tim Berners-Lee|1990|
|**HTTP**|Tim Berners-Lee + early Web contributors|1990|
|**URL**|Tim Berners-Lee + early Web contributors|1990|
|**DNS**|Paul Mockapetris|1983|
|**TCP/IP**|Vint Cerf & Robert Kahn|1970s|

The first Web server and browser were also created by Berners-Lee at CERN.

The first website was hosted at:

```text
info.cern.ch
```

---

# 7. The most important distinction

Don't memorize these as four random acronyms.

Think of them as different responsibilities:

```text
URL
│
└── "Which resource do I want?"

HTTP
│
└── "How do I request/transfer it?"

HTML
│
└── "What is the structure of this document?"

WWW
│
└── "The overall hyperlinked information system
    built using these technologies."
```

And underneath all of them:

```text
             WEB
              │
            HTTP
              │
             TCP
              │
              IP
              │
      Ethernet / Wi-Fi
              │
           Internet
```

One final correction to a common misconception:

**A URL is not necessarily an "address of a website."** It identifies a **resource**. A URL can identify an HTML document, image, video, API endpoint, PDF, etc.

For example:

```text
https://example.com/index.html   → HTML resource
https://example.com/logo.png     → image resource
https://example.com/api/users    → API resource
```

That distinction becomes very important once you start learning **REST APIs and Spring Boot**.


[[Networking]]