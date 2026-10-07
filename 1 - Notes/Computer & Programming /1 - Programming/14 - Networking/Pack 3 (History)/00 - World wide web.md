

The **World Wide Web (WWW or simply "the Web")** is a system that lets you access and link **documents and resources over the Internet** using technologies such as:

- **HTTP/HTTPS** — communication protocol
    
- **URLs** — addresses of resources
    
- **HTML** — structure of web pages
    
- **Web browsers** — software that retrieves and displays those resources
    
- **Web servers** — computers that provide those resources
    

The important distinction is:

> **The Internet is the network. The Web is a service that runs on top of that network.**

For example:

```text
Your browser
     │
     │ HTTPS
     ▼
Web server
     │
     ▼
HTML / CSS / JavaScript
```

The Internet itself provides the underlying connectivity:

```text
Internet
 ├── Web (HTTP/HTTPS)
 ├── Email (SMTP/IMAP)
 ├── SSH
 ├── DNS
 ├── FTP
 └── many other services
```

### When was it created?

The Web was invented by **Tim Berners-Lee** while working at **CERN** in Switzerland.

A simplified timeline:

|Year|Event|
|---|---|
|**1989**|Berners-Lee proposed a system for sharing information using hypertext over the Internet.|
|**1990**|He created the fundamental Web technologies: **HTML, HTTP, and URL concepts**, along with the first web server and browser.|
|**1991**|The first website became publicly available.|
|**1993**|CERN made the Web technology freely available, helping it spread rapidly.|

The original proposal was titled **"Information Management: A Proposal"**.

The first web server was:

```text
http://info.cern.ch/
```

And the first web browser was also a **web editor**, originally called **WorldWideWeb**.

### The key idea

Before the Web, the Internet already existed.

Berners-Lee essentially combined:

```text
Internet
   +
Hypertext
   +
URLs
   +
HTTP
   +
HTML
   =
World Wide Web
```

So when you type:

```text
https://example.com/index.html
```

you're **using the Web**, while the underlying packets travel through the **Internet**.

This distinction is extremely important for networking: **HTTP belongs to the Application Layer**, while the Internet underneath it involves protocols such as **TCP/IP**.


> [WWW](https://www.youtube.com/watch?v=J8hzJxb0rpc)

> [WWW 2](https://www.youtube.com/watch?v=guvsH5OFizE)

[[Networking]]