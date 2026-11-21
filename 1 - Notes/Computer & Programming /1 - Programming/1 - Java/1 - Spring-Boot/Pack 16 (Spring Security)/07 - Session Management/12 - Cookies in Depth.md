


## The problem they solve

HTTP forgets you after every request, so the server needs a way to leave a note on your side that says "remember this." A cookie is that note.

The browser can't just hand the note to every website, though. Your bank's note must never reach a random blog, and a note meant for `/admin` shouldn't go to `/blog`. Cookie attributes are the **delivery rules** that solve this.

> A cookie is a small piece of data **plus a set of rules** about when the browser may send it back.

## The cookie's life in three steps

```
1. SERVER → BROWSER   Set-Cookie: theme=dark; Max-Age=2592000; Path=/; Secure; HttpOnly; SameSite=Lax
2. BROWSER            stores it in the cookie jar, together with its rules
3. BROWSER → SERVER   Cookie: theme=dark      (on later requests, only if the rules match)
```

Look closely at step 3. The browser sends back **only the name and value**. The attributes (`Secure`, `HttpOnly`, `Path`, and so on) are instructions **for the browser**, and the server never sees them again. If your server asks "is this cookie `HttpOnly`?", it can't tell from the incoming request. The server only knows what it set.

---

# Part 1: Anatomy of a cookie

```http
Set-Cookie: remember-me=abc123; Domain=example.com; Path=/; Max-Age=1209600; Secure; HttpOnly; SameSite=Lax
```

|Piece|Job|Set by|
|---|---|---|
|`remember-me=abc123`|**Name and value.** The data itself.|Server|
|`Domain`|Which hosts may receive it|Server|
|`Path`|Which URL paths may receive it|Server|
|`Max-Age` / `Expires`|How long the browser keeps it|Server|
|`Secure`|Only send over HTTPS|Server|
|`HttpOnly`|Hide it from JavaScript|Server|
|`SameSite`|Whether to send it on cross-site requests|Server|

We'll go through the rules one at a time.

---

# Part 2: The rules, one by one

## 2.1 Name and value

Just text. Keep it small. Browsers limit a single cookie to about **4 KB** (name, value, and attributes together), and they limit how many cookies one site can store (roughly 50 to 180, depending on the browser).

And because the whole `Cookie` header travels with **every request** to that site, including images and CSS files, big cookies slow everything down. A common mistake is stuffing lots of data into cookies. Store a small ID, and keep the data on the server.

## 2.2 `Domain`: which hosts get it?

This one has a surprising default.

|What you write|Result|Who receives it|
|---|---|---|
|**No `Domain`**|**Host-only** cookie|**Only** the exact host that set it|
|`Domain=example.com`|**Domain** cookie|`example.com` **and every subdomain** (`www.`, `api.`, `blog.`)|

Here is a small example. The cookie is set by `www.example.com`:

|Cookie rule|Sent to `www.example.com`?|Sent to `api.example.com`?|Sent to `example.com`?|
|---|---|---|---|
|No `Domain`|Yes|No|No|
|`Domain=example.com`|Yes|Yes|Yes|

So leaving out `Domain` is actually the **stricter** choice. People often assume the opposite. Add `Domain` only when you truly want several subdomains to share a cookie (for example, single sign-on between `app.example.com` and `api.example.com`).

Two safety limits:

- A site can't set a cookie for **another** site. `evil.com` can't write `Domain=bank.com`.
- Browsers use the **Public Suffix List** to block cookies on shared endings like `.com` or `.co.uk`. Otherwise one site could set a cookie that every `.com` site receives.

Be careful with the security side. A `Domain=example.com` cookie is also sent to **any** subdomain, including one that is neglected or hijacked. That wider reach is a real risk.

## 2.3 `Path`: which URLs get it?

```http
Set-Cookie: cart=7; Path=/shop
```

|Request path|Cookie sent?|
|---|---|
|`/shop`|Yes|
|`/shop/items/5`|Yes|
|`/shopping`|**No** (it must match as a whole path segment)|
|`/blog`|No|

If you omit `Path`, the browser uses the directory of the URL that set the cookie, which often leads to surprises. Set `Path=/` explicitly unless you have a reason not to.

An important point: `Path` is **not a security feature**. It only controls where the browser _sends_ the cookie. Any script on your site can still read another path's cookie, using an invisible iframe, for example. Never rely on `Path` to hide something.

## 2.4 `Expires` and `Max-Age`: how long does it live?

|Attribute|Meaning|Example|
|---|---|---|
|_(neither)_|**Session cookie.** Deleted when the browser closes, usually.||
|`Max-Age=3600`|Lives **3600 seconds** from now|1 hour|
|`Expires=Wed, 30 Oct 2026 10:00:00 GMT`|Dies at a **specific date**||

If both are present, **`Max-Age` wins**. Prefer `Max-Age`, because it doesn't depend on the clock being correct on the user's device. Browsers also cap the maximum lifetime. Chrome, for example, limits cookies to about 400 days, no matter what you ask for.

**How to delete a cookie:** a server can't reach into your browser, so it sends the same cookie again with an expiry in the past:

```http
Set-Cookie: theme=; Max-Age=0; Path=/
```

The `Path` and `Domain` must match the original exactly. If they don't, the browser treats it as a _different_ cookie and the original survives. This is a classic "why won't my cookie delete?" bug.

## 2.5 `Secure`

The browser sends this cookie **only over HTTPS**. Without it, the cookie also travels over plain HTTP, where anyone on the Wi-Fi can read it. (This is what Firesheep exploited.) Browsers treat `localhost` as secure enough, so you can test `Secure` cookies in development.

## 2.6 `HttpOnly`

JavaScript can't read this cookie. `document.cookie` skips it. The browser still sends it automatically with requests.

It protects against **XSS cookie theft**. The attacker's injected script can't see the cookie. Remember, though, it doesn't stop the script from sending _requests_ that carry the cookie.

## 2.7 `SameSite`: should it travel on cross-site requests?

First, a definition. A **site** means the scheme plus the registrable domain, so `app.example.com` and `api.example.com` are the **same site**, while `example.com` and `evil.com` are **different sites**. (A related word, **origin**, is stricter: it also includes the subdomain and port.)

|Value|Behavior|Good for|
|---|---|---|
|`Strict`|Sent **only** when the request starts from the same site|Highly sensitive actions|
|`Lax`|Same as Strict, **plus** top-level navigations that are safe (clicking a link)|Most login cookies|
|`None`|Always sent, even from other sites. **Requires `Secure`.**|Embedded widgets, cross-site APIs|

An example of the difference. You're logged in to `bank.com`, and you click a link to `bank.com` from an email:

|Cookie|Are you logged in on arrival?|
|---|---|
|`SameSite=Strict`|**No.** The click started on another site, so the cookie isn't sent on that first request.|
|`SameSite=Lax`|**Yes.** A link click is a safe top-level navigation.|

And a form submitted from `evil.com` to `bank.com` with `POST`:

|Cookie|Sent?|
|---|---|
|`Strict`|No|
|`Lax`|No (this is how it blunts CSRF)|
|`None`|Yes|

Chrome and Edge treat a cookie **without** `SameSite` as `Lax`. Other browsers differ, so always set it explicitly rather than depending on the default.

---

# Part 3: How the browser decides what to send

Before every request, the browser walks through its jar and asks each cookie a series of questions. A cookie must pass **all** of them:

```
For each cookie in the jar:
  1. Has it expired?                          → yes: delete it, skip
  2. Does the request host match its Domain?  → no: skip
  3. Does the request path match its Path?    → no: skip
  4. Is it Secure, and is the request HTTP?   → yes: skip
  5. Does SameSite allow this kind of request?→ no: skip
  Passed all → add "name=value" to the Cookie header
```

### A worked example

The jar holds these cookies, all set by `shop.example.com`:

|Cookie|Domain|Path|Secure|SameSite|
|---|---|---|---|---|
|`A`|_(host-only)_|`/`|yes|Lax|
|`B`|`example.com`|`/`|yes|Lax|
|`C`|_(host-only)_|`/cart`|no|Strict|
|`D`|`example.com`|`/`|yes|None|

Request: `GET https://api.example.com/cart`, typed in the address bar by the user.

|Cookie|Sent?|Why|
|---|---|---|
|`A`|No|Host-only for `shop.`, and this request goes to `api.`|
|`B`|**Yes**|`Domain=example.com` covers subdomains, path and Secure match|
|`C`|No|Host-only for `shop.`|
|`D`|**Yes**|Same as `B`, and `None` allows anything|

Try changing the request to `http://` (no TLS). Both remaining cookies drop out because of `Secure`.

### Gotchas worth knowing

|Gotcha|What it means|
|---|---|
|**Ports are ignored**|A cookie set by `localhost:8080` is also sent to `localhost:3000`. So your Spring Boot app and your front-end dev server **share cookies**. This explains many odd dev-time bugs, such as one app overwriting another's `JSESSIONID`.|
|**Names collide**|Two cookies with the same name, domain, and path replace each other. With different paths or domains, **both** are sent. The server may then see `session=old; session=new` and use the wrong one.|
|**More specific path comes first**|In the `Cookie` header, longer paths are listed first.|
|**Subdomains can overwrite**|A sibling subdomain can set a `Domain=example.com` cookie that overwrites yours. Don't trust cookies blindly, even from "your own" site.|

---

# Part 4: Cookie prefixes: rules the browser enforces for you

Browsers support two special name prefixes that make the browser **reject** the cookie unless it follows strict rules:

|Prefix|Browser demands|
|---|---|
|`__Secure-`|Must have `Secure`|
|`__Host-`|Must have `Secure`, **`Path=/`**, and **no `Domain`**|

```http
Set-Cookie: __Host-session=abc; Secure; HttpOnly; Path=/; SameSite=Lax
```

`__Host-` locks the cookie to the exact host. No subdomain can overwrite it, because it can't carry a `Domain`. That closes the "sibling subdomain" hole from the table above. It's a cheap, strong upgrade for session cookies.

---

# Part 5: First-party vs third-party cookies

|Type|Meaning|Example|
|---|---|---|
|**First-party**|Set by the site shown in the address bar|You visit `shop.com`, and `shop.com` sets a cart cookie|
|**Third-party**|Set by **another** site whose content is embedded in the page|`shop.com` embeds an ad or a video from `ads.net`, and `ads.net` sets its own cookie|

Third-party cookies let one company recognize you across many websites, which is how a lot of ad tracking works. For that reason Safari and Firefox block them by default, and Chrome has been changing its plans over the years, so check current status if it matters for your project.

To keep legitimate embeds working (a chat widget, say) without cross-site tracking, browsers added **partitioned cookies** (the `Partitioned` attribute, also called CHIPS). The cookie is stored separately for each top-level site, so the widget on `a.com` can't recognize you on `b.com`. You'll only need this when you embed your own service into other people's pages.

---

# Part 6: Working with cookies in Spring Boot

### Setting a cookie

```java
@GetMapping("/theme/dark")
public ResponseEntity<String> setTheme() {
    ResponseCookie cookie = ResponseCookie.from("theme", "dark")
            .httpOnly(true)
            .secure(true)
            .sameSite("Lax")
            .path("/")
            .maxAge(Duration.ofDays(30))
            .build();

    return ResponseEntity.ok()
            .header(HttpHeaders.SET_COOKIE, cookie.toString())
            .body("Theme saved");
}
```

Line by line:

- `ResponseCookie.from("theme", "dark")` starts a cookie with a name and value.
- `.httpOnly(true)` hides it from JavaScript. For a theme preference that your JavaScript wants to read, you'd leave this off. For anything sensitive, keep it on.
- `.secure(true)` sends it only over HTTPS.
- `.sameSite("Lax")` sets the cross-site rule. Spring's `ResponseCookie` supports this directly, which the older `jakarta.servlet.http.Cookie` class does not.
- `.path("/")` makes it valid for the whole site.
- `.maxAge(Duration.ofDays(30))` makes it persistent for 30 days. Without it, you'd get a session cookie.
- `.header(SET_COOKIE, cookie.toString())` turns the object into the `Set-Cookie` header text.

### Reading a cookie

```java
@GetMapping("/page")
public String page(@CookieValue(name = "theme", defaultValue = "light") String theme) {
    return "Your theme is " + theme;
}
```

- `@CookieValue(name = "theme")` pulls that cookie out of the incoming `Cookie` header.
- `defaultValue = "light"` is used when the cookie is missing. Without a default, a missing cookie would cause an error response.

### Deleting a cookie

```java
ResponseCookie delete = ResponseCookie.from("theme", "")
        .path("/")
        .maxAge(0)
        .build();
```

`maxAge(0)` means "expire now." Note the `path("/")`: it has to match the original cookie, or nothing is deleted.

### Setting a domain cookie

```java
ResponseCookie.from("sso", token).domain("example.com").path("/")...
```

`.domain(...)` makes the cookie shared with subdomains. Use it deliberately, since it widens the cookie's reach.

### Session cookie settings in one place

For the `JSESSIONID` cookie Tomcat creates, you don't build it yourself. You set its rules with properties:

```properties
server.servlet.session.cookie.name=__Host-JSESSIONID
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.same-site=lax
server.servlet.session.cookie.path=/
```

Using the `__Host-` prefix here is optional but good, provided you serve over HTTPS and don't set a domain.

---

# Part 7: See cookies yourself

### In the browser

1. Open the developer tools, then **Application → Cookies** (Chrome and Edge) or **Storage → Cookies** (Firefox).
2. Pick a site. You'll see every attribute as a column: **Domain, Path, Expires/Max-Age, HttpOnly, Secure, SameSite**.
3. Double-click a value to edit it, or delete a cookie and reload to watch behavior change.
4. In the **Network** tab, click a request and open **Cookies**. It shows which cookies were **sent** and which were **blocked**, with a yellow warning and a reason (for example, a `SameSite` mismatch).
5. In the **Console**, type `document.cookie`. You'll see only the cookies **without** `HttpOnly`.

### With curl

Create a tiny endpoint like `/theme/dark` above, then:

```bash
curl -i -c jar.txt http://localhost:8080/theme/dark
cat jar.txt
```

In the response, find the `Set-Cookie:` header. In `jar.txt` you'll see lines with tab-separated fields:

```
#HttpOnly_localhost   FALSE   /   TRUE   1764000000   theme   dark
```

|Field|Meaning|
|---|---|
|`#HttpOnly_` prefix|The cookie is `HttpOnly`|
|`localhost`|The domain|
|`FALSE`|Whether subdomains are included (it's host-only here)|
|`/`|The path|
|`TRUE`|The `Secure` flag|
|`1764000000`|Expiry as a Unix timestamp (`0` means session cookie)|
|`theme`, `dark`|Name and value|

Note: curl won't send a `Secure` cookie back over plain `http://`, which is the browser rule you just learned.

Now send it back:

```bash
curl -i -b jar.txt http://localhost:8080/page
```

`-b jar.txt` sends the stored cookies. The response should say "Your theme is dark."

To see the wrong-path rule in action, set a cookie with `.path("/shop")` and request `/blog`. The cookie won't be sent.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Storing sensitive data (passwords, user info) directly in a cookie|Cookies live on the user's machine, so they can be read and edited|Store a random ID and keep data on the server|
|No `HttpOnly` on session or login cookies|XSS can steal them|Always add it|
|No `Secure`|Sniffable on HTTP|Always add it|
|Leaving out `SameSite`|Behavior differs between browsers|Set `Lax` (or `Strict`) explicitly|
|Setting `Domain` "just in case"|Cookie reaches every subdomain|Leave it off unless you need sharing|
|Trying to delete with a different `Path`|The original cookie survives|Use the same `Path` and `Domain`|
|Big cookies|Sent on every request, slowing everything|Keep them tiny|
|Trusting cookie values blindly|The user can edit non-`HttpOnly` cookies in dev tools, and attackers can forge them|Use random IDs or signed values, and validate on the server|
|Assuming ports separate cookies|Apps on different `localhost` ports share cookies|Use different cookie names, or different hostnames in development|

---

## Related concept, briefly

**Cookies vs `localStorage` vs `sessionStorage`:** these are the three places a browser can store data for a site, and they behave differently.

||Cookie|`localStorage`|`sessionStorage`|
|---|---|---|---|
|Sent to the server automatically|**Yes**|No|No|
|Readable by JavaScript|Unless `HttpOnly`|Always|Always|
|Lifetime|Set by you|Until cleared|Until the tab closes|
|Size|~4 KB|~5 MB|~5 MB|
|Shared between tabs|Yes|Yes|No (each tab has its own)|

Pick a cookie when the **server** needs the value on every request (logins). Pick storage when only your **JavaScript** needs it (UI preferences, cached data). For secrets, storage is riskier, because any XSS can read it.

---

## The whole picture

|Question|Answer|
|---|---|
|What is a cookie?|A small note plus rules for when the browser may send it back|
|What does the server see on later requests?|Only `name=value`, never the attributes|
|Who decides when it's sent?|The browser, by checking expiry, Domain, Path, Secure, and SameSite|
|Strictest `Domain` choice?|Leave it off (host-only)|
|What does `Path` secure?|Nothing. It only filters when the cookie is sent.|
|How do you protect a session cookie?|`Secure`, `HttpOnly`, `SameSite`, and the `__Host-` prefix|
|How do you delete one?|Send it again with `Max-Age=0` and the same Domain and Path|
|Gotcha for local development|Cookies ignore ports, so `localhost` apps share them|




[[Spring Security]]