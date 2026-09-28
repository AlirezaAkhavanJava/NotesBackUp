

**Node.js is a runtime that lets you execute JavaScript outside of a web browser.**

Normally:

```text
JavaScript → Chrome/Firefox → Browser
```

With Node.js:

```text
JavaScript → Node.js → Your Linux machine
```

### Why does Node.js exist?

JavaScript originally lived mainly inside browsers and manipulated web pages:

```javascript
document.querySelector("button")
```

Node.js lets JavaScript interact with things outside the browser:

```javascript
// Read a file
const fs = require("fs");

const data = fs.readFileSync("hello.txt", "utf8");
console.log(data);
```

So Node.js provides APIs for things like:

- Filesystem
    
- Networking
    
- HTTP servers
    
- Processes
    
- Environment variables
    
- Streams
    
- TCP/UDP
    
- etc.
    

### Node.js ≠ JavaScript

This distinction is important:

```text
JavaScript
   ↓
Programming language

Node.js
   ↓
Runtime for executing JavaScript
```

Node.js is built around the **V8 JavaScript engine**, the same engine used by Chromium/Chrome.

### Why are you installing Node.js?

Since you're creating an **Angular** frontend:

```text
Angular application
       ↓
Node.js
       ↓
npm
       ↓
Angular CLI
```

For example:

```bash
npx @angular/cli@latest new DoItLater-Angular
```

`npx` and `npm` come with Node.js.

Your architecture is therefore roughly:

```text
┌─────────────────────┐
│ Angular Frontend    │
│ TypeScript          │
└──────────┬──────────┘
           │ HTTP/JSON
           ↓
┌─────────────────────┐
│ Spring Boot Backend │
│ Java                │
└──────────┬──────────┘
           │ JDBC
           ↓
┌─────────────────────┐
│ PostgreSQL          │
└─────────────────────┘
```

**Node.js is primarily supporting your Angular development/build tooling here.** Your Angular application itself ultimately runs JavaScript in the user's browser; Node.js is not required for the browser to execute the finished Angular app.