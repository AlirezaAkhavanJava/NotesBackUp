

The **first Web browser was created by Tim Berners-Lee at CERN around 1990**.

It was originally called **WorldWideWeb** — the same name as the Web itself. Later, it was renamed **Nexus** to avoid confusion.

But what's interesting isn't just _who made it_. It's **what problem a browser solved**.

---

# 1. The problem before the browser

The Internet already existed.

You could have:

```text
Computer A ───── Internet ───── Computer B
```

And protocols such as **TCP/IP** allowed computers to communicate.

But there wasn't yet a simple, graphical system for humans to navigate interconnected documents.

Imagine having thousands of documents:

```text
Document A
Document B
Document C
Document D
...
```

and wanting:

```text
Document A
    │
    │ link
    ▼
Document B
    │
    │ link
    ▼
Document C
```

The missing piece was software that could **retrieve documents, understand their markup, follow hyperlinks, and display them**.

That software was the **Web browser**.

---

# 2. What problem did the browser solve?

The browser provided a human-facing interface to the World Wide Web.

Without a browser, the underlying system was basically:

```text
URL
 ↓
HTTP
 ↓
server
 ↓
document
```

The user would have to understand the protocols and deal with the raw data.

The browser turned that into:

```text
User
 │
 ▼
Browser
 │
 ├── URL
 ├── HTTP
 ├── HTML parser
 └── hyperlink navigation
 │
 ▼
Web server
```

So the browser is essentially a **Web client**.

---

# 3. What was the first browser?

Tim Berners-Lee created the first browser/editor at CERN around **1990**.

It could:

- retrieve documents using HTTP
    
- display HTML
    
- follow hyperlinks
    
- edit HTML documents
    
- communicate with Web servers
    

This is important:

> The original browser wasn't just a viewer. It was also an **editor**.

Berners-Lee envisioned the Web as a system where people could both **read and create** interconnected documents.

---

# 4. How did it actually work?

The architecture was surprisingly close to what happens today.

Suppose the user wants:

```text
http://info.cern.ch/
```

The browser performs roughly:

```text
                 Browser
                    │
                    │ URL
                    ▼
             Parse the URL
                    │
                    ▼
            Find server address
                    │
                   DNS
                    │
                    ▼
               IP address
                    │
                    ▼
             Network connection
                    │
                    ▼
                  HTTP
                    │
             GET /index.html
                    │
                    ▼
              Web server
                    │
                    │ HTTP response
                    ▼
                 HTML
                    │
                    ▼
              HTML parser
                    │
                    ▼
              Display page
```

That basic architecture still exists.

Modern browsers are vastly more complicated, but the fundamental model remains.

---

# 5. HTML was critical

The browser needed a language describing the document.

That's where **HTML** came in.

For example:

```html
<h1>CERN</h1>

<p>Welcome to CERN.</p>

<a href="https://example.com">
    Another document
</a>
```

The browser reads the HTML and understands:

```text
<h1> → heading
<p>  → paragraph
<a>  → hyperlink
```

Then it renders the document.

The crucial innovation was that the document could contain **links to other documents**.

---

# 6. Hyperlinks were the killer feature

Consider:

```text
Document A
│
├── link → Document B
│
├── link → Document C
│
└── link → Document D
```

The browser lets the user click:

```text
Document A
     │
     │ click
     ▼
Document C
```

Then:

```text
Document C
     │
     │ click
     ▼
Document F
```

The user doesn't need to know where the documents physically reside.

They simply navigate the **information space**.

That's the fundamental idea behind the **World Wide Web**.

---

# 7. The first browser was primitive

It wasn't remotely like Chrome or Firefox.

The original browser had a very simple interface and was designed primarily for **NeXT computers**.

It didn't have:

```text
JavaScript
CSS
video
tabs
extensions
developer tools
WebGL
cookies
```

Those came much later.

The original Web was essentially:

```text
HTML
 +
HTTP
 +
URLs
 +
Hyperlinks
```

---

# 8. Then came graphical browsers

The Web became much more accessible when browsers such as **Mosaic** appeared in 1993.

Mosaic was developed at the **National Center for Supercomputing Applications (NCSA)** by a team including:

- Marc Andreessen
    
- Eric Bina
    
- others at NCSA
    

Mosaic became famous for making the Web much easier to use and for supporting images integrated into Web pages.

The evolution looked roughly like:

```text
1990
WorldWideWeb
     ↓
1993
Mosaic
     ↓
1994
Netscape Navigator
     ↓
1995+
Internet Explorer
     ↓
2000s+
Firefox / Safari / Chrome / ...
```

This is when the Web started moving from a research system toward a mass-market platform.

---

# 9. Browser vs Internet

This distinction is extremely important.

A browser **doesn't create the Internet**.

It uses Internet protocols.

Think:

```text
              Browser
                 │
        ┌────────┼────────┐
        │        │        │
       URL     HTML     HTTP
                 │
                TLS
                 │
                TCP
                 │
                 IP
                 │
              Internet
```

The Internet is the underlying network infrastructure.

The Web is an application system built on it.

The browser is a **client application that accesses the Web**.

---

# 10. The historical chain

Now everything you've been asking about fits together:

```text
Packet switching
       ↓
ARPANET
       ↓
TCP/IP
       ↓
Internet
       ↓
DNS
       ↓
Tim Berners-Lee
       ↓
World Wide Web
       │
       ├── URL
       ├── HTTP
       └── HTML
              ↓
        Web Browser
              ↓
      Human-friendly Web
```

And the fundamental problem solved by the browser was:

> **It turned the Web's underlying network protocols and hypertext documents into an interactive interface through which humans could navigate, retrieve, and eventually create interconnected information.**

The really interesting next step is **Mosaic**, because that's where the Web changed from a technical system used by researchers into something ordinary people could actually browse visually.


[[Networking]]