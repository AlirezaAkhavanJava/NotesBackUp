
 This is the exact chain you should learn next, because these technologies are not random inventions—they evolved as the Web moved from **documents → dynamic websites → applications**.

# 1. The big picture

The evolution is roughly:

```text
HTML
  ↓
Dynamic HTML
  ↓
JavaScript
  ↓
XMLHttpRequest
  ↓
AJAX
  ↓
JSON
  ↓
REST APIs
  ↓
SPAs
  ↓
Frontend / Backend separation
  ↓
Modern Web applications
```

But there are some technologies in between, especially **XML, XHTML, DOM, CSS, HTTP, and JavaScript**.

Let's build the history properly.

---

# 2. HTML — the foundation

**HTML = HyperText Markup Language**

Tim Berners-Lee created HTML as part of the original Web around 1990.

Its job is:

> **Describe the structure of a Web document.**

Example:

```html
<h1>My Tasks</h1>

<p>Learn Spring Boot</p>

<a href="/tasks">View tasks</a>
```

HTML describes:

```text
heading
paragraph
link
```

It does **not** primarily describe application logic.

Think:

```text
HTML
 ↓
"What is this content?"
```

---

# 3. HTTP — communication

HTML is the document.

HTTP is how the browser communicates with the server.

```text
Browser
   │
   │ HTTP GET /tasks
   ↓
Server
   │
   │ HTTP response
   ↓
Browser
```

Example:

```http
GET /tasks HTTP/1.1
Host: example.com
```

Server:

```http
HTTP/1.1 200 OK
Content-Type: text/html

<html>
    ...
</html>
```

So:

```text
HTML = representation/content
HTTP = transport/application protocol for requesting/transferring it
```

---

# 4. CSS — presentation

HTML says:

```html
<h1>Hello</h1>
```

CSS says:

```css
h1 {
    font-size: 32px;
}
```

So:

```text
HTML → structure
CSS  → presentation
```

This separation became fundamental to Web development.

---

# 5. JavaScript — behavior

JavaScript was introduced by Netscape in 1995.

HTML:

```html
<button>Click me</button>
```

JavaScript:

```javascript
button.addEventListener("click", () => {
    console.log("clicked");
});
```

Now the browser can execute logic.

The browser effectively became:

```text
HTML
 ↓
DOM
 ↓
JavaScript
 ↓
change page
```

---

# 6. DOM

**DOM = Document Object Model**

The browser takes HTML and constructs an in-memory tree.

HTML:

```html
<html>
  <body>
    <h1>Hello</h1>
    <p>World</p>
  </body>
</html>
```

becomes conceptually:

```text
Document
└── html
    └── body
        ├── h1
        │   └── "Hello"
        └── p
            └── "World"
```

JavaScript can manipulate this tree.

```javascript
document.querySelector("h1").textContent = "Hello Alireza";
```

This was extremely important for Web 2.0.

---

# 7. XML

**XML = Extensible Markup Language**

XML became a W3C recommendation in 1998.

Its purpose was to represent **structured data**.

Example:

```xml
<user>
    <id>42</id>
    <name>Alireza</name>
    <role>developer</role>
</user>
```

Notice the difference:

### HTML

```html
<h1>Alireza</h1>
```

is primarily about presenting/structuring a document.

### XML

```xml
<user>
    <name>Alireza</name>
</user>
```

is primarily about representing structured data.

XML became heavily used for:

- data exchange
    
- configuration
    
- SOAP Web Services
    
- enterprise systems
    
- RSS
    
- early AJAX responses
    

---

# 8. XHTML

**XHTML = Extensible HyperText Markup Language**

XHTML was essentially HTML reformulated using XML's stricter syntax rules.

For example, XML requires properly nested elements:

```xml
<p>
    <strong>Hello</strong>
</p>
```

XHTML aimed to make HTML conform to XML rules.

The important historical point:

> XHTML was intended to make the Web's markup more rigorously structured, but it did not become the dominant direction of Web development.

HTML eventually continued evolving as **HTML5**.

So don't think:

```text
HTML → XHTML → HTML5
```

as a simple replacement chain.

It's more accurate to think:

```text
HTML
 │
 ├── XHTML effort
 │
 └── HTML continued evolving
          ↓
        HTML5
```

---

# 9. The problem: full-page reloads

Now we reach the Web 2.0 problem.

Suppose you have:

```text
/tasks
```

and click:

```text
Complete task
```

Old architecture:

```text
Browser
   │
   │ POST /tasks/42/complete
   ↓
Server
   │
   │ generate entire HTML page
   ↓
Browser
   │
   ↓
RENDER ENTIRE PAGE
```

Even though only this changed:

```text
☐ Learn Spring Boot

        ↓

☑ Learn Spring Boot
```

the entire page might be downloaded again.

That was inefficient and produced a less application-like experience.

---

# 10. XMLHttpRequest

Browsers gained the ability to make HTTP requests from JavaScript without navigating away from the current page.

The important technology was:

**XMLHttpRequest (XHR)**

Microsoft introduced an early implementation in Internet Explorer in the late 1990s; it later became standardized and widely adopted.

Conceptually:

```text
JavaScript
    │
    │ HTTP request
    ↓
Server
    │
    │ data
    ↓
JavaScript
```

The page doesn't necessarily reload.

Example:

```javascript
const xhr = new XMLHttpRequest();

xhr.open("GET", "/api/tasks");

xhr.onload = () => {
    console.log(xhr.responseText);
};

xhr.send();
```

This was a major building block for Web 2.0.

---

# 11. AJAX

**AJAX = Asynchronous JavaScript and XML**

The term was coined/popularized in 2005 by Jesse James Garrett.

Important:

> AJAX is **not a protocol**.

It is a technique/pattern involving:

```text
JavaScript
+
HTTP requests
+
asynchronous communication
+
updating the page dynamically
```

Originally XML was commonly used for the response, hence:

```text
Asynchronous
JavaScript
and
XML
```

But eventually JSON became much more common.

---

# 12. AJAX changed the interaction model

Before:

```text
CLICK
 ↓
HTTP request
 ↓
FULL HTML RESPONSE
 ↓
FULL PAGE RELOAD
```

AJAX:

```text
CLICK
 ↓
JavaScript
 ↓
HTTP request
 ↓
small data response
 ↓
JavaScript
 ↓
DOM update
```

This is a massive conceptual change.

The browser wasn't merely displaying documents anymore.

It was **executing an application**.

---

# 13. JSON

**JSON = JavaScript Object Notation**

Example:

```json
{
  "id": 42,
  "name": "Learn Spring Boot",
  "completed": false
}
```

JSON became popular because it is:

- compact
    
- easy for JavaScript to process
    
- human-readable
    
- language-independent
    
- simpler than XML for many API use cases
    

Compare XML:

```xml
<task>
    <id>42</id>
    <name>Learn Spring Boot</name>
    <completed>false</completed>
</task>
```

JSON:

```json
{
  "id": 42,
  "name": "Learn Spring Boot",
  "completed": false
}
```

JSON is not inherently a Web protocol.

It's a **data interchange format**.

---

# 14. AJAX + JSON

Now you get the modern pattern:

```text
Browser
   │
   │ JavaScript
   │
   │ GET /api/tasks
   ↓
Backend
   │
   ↓
Database
   │
   ↑
Backend
   │
   │ JSON
   ↑
Browser
   │
   ↓
JavaScript
   │
   ↓
DOM
```

For example:

```http
GET /api/tasks/42
```

Response:

```json
{
  "id": 42,
  "title": "Learn Spring Boot",
  "completed": false
}
```

The frontend can then render that data.

---

# 15. REST APIs

Now we need to distinguish **AJAX** from **REST**.

AJAX answers:

> "How can JavaScript communicate with a server without reloading the page?"

REST answers a different question:

> "How should network resources be represented and interacted with over HTTP?"

REST = **Representational State Transfer**.

It was described by Roy Fielding in his 2000 doctoral dissertation.

A REST-style API might have:

```text
GET    /api/tasks
GET    /api/tasks/42
POST   /api/tasks
PUT    /api/tasks/42
DELETE /api/tasks/42
```

Conceptually:

```text
/tasks
   │
   ├── GET     → retrieve
   ├── POST    → create
   │
   └── /42
        ├── GET    → retrieve task 42
        ├── PUT    → update task 42
        └── DELETE → delete task 42
```

---

# 16. REST + JSON + AJAX

Now combine everything:

```text
                 INTERNET
                    │
        ┌───────────┴───────────┐
        │                       │
    FRONTEND                 BACKEND
        │                       │
    JavaScript                Spring
        │                       │
        │ HTTP + JSON           │
        └───────────────────────┘
                    │
                PostgreSQL
```

Example:

```text
Angular
   │
   │ GET /api/tasks
   ↓
Spring Boot
   │
   ↓
TaskRepository
   │
   ↓
PostgreSQL
```

Then:

```text
PostgreSQL
   ↓
Spring Boot
   ↓
JSON
   ↓
Angular
```

This is basically the architecture you're working with in your own projects.

---

# 17. SPA

**SPA = Single-Page Application**

A traditional website might work like:

```text
GET /
GET /about
GET /tasks
GET /profile
```

Each navigation can involve loading another HTML document.

A SPA instead initially loads an application:

```text
GET /
   ↓
HTML
CSS
JavaScript
   ↓
Application starts
```

Then JavaScript handles navigation and communicates with APIs.

```text
Browser
   │
   ├── /tasks
   ├── /profile
   ├── /settings
   │
   └── API requests
          ↓
       Backend
```

The browser doesn't necessarily download a new HTML document for every route.

---

# 18. Angular is an example

Your Angular frontend is essentially:

```text
Angular
   │
   ├── Components
   ├── Services
   ├── Routing
   ├── State
   └── HTTP client
          │
          ↓
       REST API
          │
          ↓
     Spring Boot
          │
          ↓
      PostgreSQL
```

That's the modern frontend/backend separation.

---

# 19. The major architectural separation

Older Web application:

```text
Browser
    ↓
Server
    ↓
HTML
```

Modern application:

```text
                 HTTP
                  │
       ┌──────────┴──────────┐
       ↓                     ↓
   FRONTEND              BACKEND
   Angular                Spring Boot
       │                     │
       │      JSON           │
       └─────────────────────┘
                              │
                              ↓
                         PostgreSQL
```

The backend doesn't necessarily return HTML anymore.

It can return **data**.

For example:

```json
{
  "id": 42,
  "title": "Learn REST",
  "completed": true
}
```

The frontend decides how that data should appear.

---

# 20. This is the crucial historical transition

The Web started as:

```text
DOCUMENT WEB
```

Then became:

```text
INTERACTIVE WEB
```

Then:

```text
APPLICATION WEB
```

The progression:

```text
1990
HTML + HTTP + URL
        ↓
1995
JavaScript + CSS
        ↓
1998
XML + DOM
        ↓
late 1990s
XMLHttpRequest
        ↓
2000s
AJAX
        ↓
2000s
JSON
        ↓
2000s
REST APIs
        ↓
2010s
SPAs
        ↓
today
Frontend ↔ API ↔ Backend ↔ Database
```

### The key mental model

```text
HTML
"What is the document?"

CSS
"How does it look?"

JavaScript
"What does it do?"

DOM
"What does the browser currently have?"

HTTP
"How do systems communicate?"

XML / JSON
"How do we represent structured data?"

AJAX / Fetch
"How does JavaScript communicate with the server?"

REST
"How should resources be exposed/interacted with over HTTP?"

SPA
"How can the browser behave like an application?"

Frontend
"User interface + client-side behavior"

Backend
"Business logic + data + security"

Database
"Persistent state"
```

One final correction that's worth keeping in your head: **REST, AJAX, JSON, XML, XHTML, JavaScript, HTML, and SPAs are not successive versions of one technology.** They solve **different problems**, and many coexist. The history is about them gradually fitting together into the architecture we now call a modern Web application.

[[Networking]]