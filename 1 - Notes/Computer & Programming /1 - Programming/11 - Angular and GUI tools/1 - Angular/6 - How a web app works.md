
# Topic 1: How a web app actually works

## The intuition

A **web browser is a runtime**, just like the JVM. The JVM takes bytecode and runs it, and the browser takes three kinds of files and runs them:

|File type|Job|Restaurant analogy|
|---|---|---|
|**HTML**|_what exists_ on the page (headings, buttons, lists)|The furniture: tables, chairs, menu|
|**CSS**|_how it looks_ (colors, sizes, layout)|The decor: paint, lighting|
|**JavaScript**|_what it does_ (react to clicks, fetch data)|The waiters: they move and act|

Angular is a tool that helps you write the third one (and generate the first two) without going insane. To see why it exists, you first need to see the pain it removes.

## The mechanics

**The DOM.** When the browser reads HTML, it builds a **tree of objects in memory** called the DOM (Document Object Model). Think of an object graph, like a parsed XML file that you can modify while it's alive:

```
<body>
 ├── <h1>  "Shop"
 └── <ul>
      ├── <li> "Keyboard"
      └── <li> "Mouse"
```

What you _see_ on screen is a picture of this tree. Change the tree, and the screen changes.

**Plain JavaScript (no Angular)** manipulates that tree by hand:

```html
<h1>Clicks: <span id="count">0</span></h1>
<button id="btn">Click me</button>

<script>
  let count = 0;
  document.getElementById('btn').addEventListener('click', () => {
    count++;
    document.getElementById('count').textContent = count;  // YOU update the screen
  });
</script>
```

Notice that two things exist here: the **data** (`count`) and the **screen**. It's _your job_ to keep them in sync. Forget one line and the screen lies.

Now imagine 200 pieces of data, 50 places they appear, and lists that grow and shrink. Manually syncing all that is where projects rot. **Angular's core promise** is that you describe _what the screen should look like for the current data_, and Angular updates the DOM for you.

## Multi-page vs single-page

A **traditional site** (like Spring MVC with Thymeleaf) works like this: every click asks the server for a **whole new HTML page**, and the browser throws away the old page and loads the new one. The server does the rendering.

A **single-page app (SPA)**, which Angular builds, works differently:

1. The browser loads **one** HTML page and your JavaScript bundle, **once**.
2. From then on, clicks do **not** load new pages. JavaScript rewrites parts of the DOM directly.
3. When data is needed, JavaScript calls your Spring Boot API in the background and receives **JSON** (data only, no HTML), then updates the screen.

```
Browser ──(once)──► gets index.html + JS bundle
   │
   └── click ──► JS calls GET /api/products ──► Spring Boot ──► JSON
                          │
                          └── JS updates just the list on screen
```

The restaurant version is that the traditional site rebuilds the whole dining room for every customer request, while the SPA keeps the room and only swaps the dish on the table.

## Nuances and gotchas

- **JavaScript runs on the user's machine, so it's untrusted.** Anyone can open DevTools (F12) and change your code or fake requests. Angular is presentation only, and Spring Boot must re-check everything. I said this earlier, and this is the _reason_ for it.
- **Single-threaded.** JavaScript does one thing at a time. Slow work blocks the whole page, and this is why network calls are _asynchronous_: you say "call me back when the data arrives" (we'll meet this in Observables). It's different from the Java threads you know.
- **SPA trade-offs.** The first load is heavier (you download the whole app up front), and search engines and link-preview bots that don't run JavaScript see an empty page. The fix is server-side rendering (SSR), which is an advanced topic later. The back button also has to be simulated by JavaScript, which is what Angular's router does.
- **Browsers only speak JavaScript.** TypeScript (next topic) gets _translated_ to JavaScript before the browser sees it, just like `.java` becomes `.class`.

## Recap in one sentence

The browser is a runtime that builds a tree (the DOM) from HTML, styles it with CSS, and animates it with JavaScript. An SPA loads once and updates that tree in place using data from your API, and Angular automates the painful part, keeping the tree in sync with your data.





[[1 - Angular]]