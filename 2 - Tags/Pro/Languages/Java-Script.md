**JavaScript (JS)** is a programming language that runs in the web browser and makes web pages interactive. It is also used outside the browser, including on servers.

**Analogy:** A web page is a house. **HTML** is the structure (walls, rooms), **CSS** is the paint and decoration, and **JavaScript** is the electricity and plumbing: lights turn on when you flip a switch, doors open, things respond to you. Without JS, the house is a still photograph.

## Core idea

Every browser has a built-in **JavaScript engine** (Chrome's is V8, Firefox's is SpiderMonkey). The browser downloads your JS, and the engine runs it on the user's machine. JS can:

- Read and change the page (the **DOM**, the browser's live tree of HTML elements)
- React to events (clicks, typing, scrolling)
- Make network requests to a back-end without reloading the page

```html
<button id="btn">Click me</button>
<p id="out"></p>

<script>
  document.getElementById("btn").addEventListener("click", () => {
    document.getElementById("out").textContent = "Hello from JS!";
  });
</script>
```

## Java vs JavaScript

They are **unrelated languages** that share part of a name. "Java is to JavaScript as car is to carpet." The name was a 1995 marketing decision, riding Java's fame.

||Java|JavaScript|
|---|---|---|
|**Typing**|Static (types checked before running)|Dynamic (types checked while running)|
|**Execution**|Compiled to bytecode, runs on the JVM|Interpreted/JIT-compiled by an engine|
|**Classic home**|Back-end|Browser (now both)|
|**Concurrency**|Multiple threads|Single thread plus an event loop|

## Where JS is used

- **Front-end (the browser):** the original and still the main use. Frameworks like **Angular, React, and Vue** build large single-page apps.
- **Back-end:** with **Node.js** (runs JS outside the browser, on a server).
- **Mobile apps:** React Native, Ionic.
- **Desktop apps:** Electron (VS Code, Discord, and Slack are built with it).
- **Tooling and scripts:** build tools, bundlers, test runners.

## Connection to the back-end

This links directly to your REST API lesson. The browser runs JS, and that JS talks to your Spring Boot server over HTTP:

```
Browser (JS) --HTTP/JSON--> Spring Boot (REST API) --SQL--> Database
```

```javascript
// Runs in the browser, calls your Spring Boot endpoint
async function loadBook() {
  const response = await fetch("http://localhost:8080/books/5");
  const book = await response.json();   // JSON text becomes a JS object
  console.log(book.title);              // "Clean Code"
}
loadBook();
```

JSON actually stands for **JavaScript Object Notation**: it was born from JS object syntax, which is why it fits so naturally.

**Division of labor:**

- **Back-end (Spring Boot):** business rules, database access, security, the single source of truth.
- **Front-end (JS):** displaying data, handling user interaction, calling the API.

**The CORS gotcha:** your page might be served from `localhost:4200` (a front-end dev server) while the API is on `localhost:8080`. Different port means different **origin**, and browsers block such requests by default as a security rule. The back-end must explicitly allow it:

```java
@RestController
@CrossOrigin(origins = "http://localhost:4200")
public class BookController { ... }
```

This is one of the first errors every Java and JS developer meets.

**Node.js as an alternative back-end:** JS can also _be_ the back-end, so a company can use one language everywhere. Node.js and Spring Boot solve the same problem (build a REST API) in different languages.

## History

- **1995:** Brendan Eich at **Netscape** creates the language in about 10 days. It was first called _Mocha_, then _LiveScript_, then renamed **JavaScript** for marketing reasons.
- **1996-97:** Microsoft makes its own version; the language is standardized as **ECMAScript** (ECMA-262), so "ES" versions are just JS standard versions.
- **1999-2005:** **AJAX** (JS requesting data in the background) lets pages update without a full reload. Gmail and Google Maps show what is possible.
- **2006:** **jQuery** smooths over browser differences and dominates web development.
- **2008:** Google's **V8** engine makes JS dramatically faster, making serious applications possible.
- **2009:** **Node.js** (Ryan Dahl) takes V8 out of the browser, and JS becomes a back-end language. **npm** (the package manager, like Maven for JS) follows in 2010.
- **2010-2016:** The framework era: AngularJS (2010), React (2013), Vue (2014), Angular 2+ (2016).
- **2012:** Microsoft releases **TypeScript**, JS with static types, which compiles down to plain JS. Angular is built on it.
- **2015:** **ES6/ES2015**, the biggest upgrade ever (`let`/`const`, arrow functions, classes, promises, modules). Since then the standard gets a yearly update.

## The pattern

Same as the computing history lesson: each era added a layer of abstraction (raw JS, then jQuery, then frameworks, then TypeScript), and JS grew from a 10-day scripting toy to one of the most widely used languages in the world.

## Gotchas

- **Single-threaded with an event loop:** JS does one thing at a time, so slow work must be **asynchronous** (`async`/`await`, promises). This is the hardest concept for Java developers, who are used to threads.
- **Dynamic typing surprises:** `"5" + 1` is `"51"`, but `"5" - 1` is `4`. Always use `===` (strict equality) instead of `==`.
- **Browsers only understand JS** (plus WebAssembly), so every other front-end language, TypeScript included, must compile to it.
- **Never trust the front-end:** users can edit JS in their own browser, so validation and security checks must _always_ be repeated on the Spring Boot side.



[[Computer & Programming]]
[[CS 50]]
[[Data-base]]