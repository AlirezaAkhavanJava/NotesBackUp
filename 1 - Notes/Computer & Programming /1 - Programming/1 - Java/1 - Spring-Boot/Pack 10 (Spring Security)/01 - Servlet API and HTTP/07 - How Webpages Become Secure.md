

## The problem this solves

When you open a page, your request travels through many machines you don't control: your Wi-Fi router, your internet provider, and several networks in between. Any of them could **read** your data, **change** it, or **pretend to be** the real website.

Making a page secure means answering three questions:

1. **Can anyone else read this?** (confidentiality)
2. **Can anyone change this on the way?** (integrity)
3. **Am I really talking to the right website?** (authenticity)

Security also has a second half. Even with a perfect connection, the page itself can be attacked, for example by malicious scripts or tricked forms. So the full story has two parts: **securing the road** and **securing the building**.

---

## Part 1: Securing the road (the connection)

### Step by step: what happens when you type a URL

```
You type https://example.com
   │
   ├─ 1. DNS lookup        → "What is the IP address of example.com?"
   ├─ 2. TCP connection    → Browser and server open a channel
   ├─ 3. TLS handshake     → They agree on encryption and the server proves its identity
   ├─ 4. HTTP request      → Now sent encrypted: "GET /index.html"
   └─ 5. HTTP response     → Encrypted page comes back
```

Step 3 is where the security happens. Here is what the **TLS handshake** does, in plain words:

|Moment|What happens|Why it matters|
|---|---|---|
|Browser says hello|Lists the encryption methods it supports|They must agree on a common one|
|Server replies|Sends its **certificate**|This is the server's ID card|
|Browser checks the certificate|Is it signed by a trusted authority? Is it for this exact domain? Is it still valid?|Stops fake websites|
|Key exchange|Both sides create a shared secret key, without ever sending it directly|Even someone recording everything can't learn it|
|Encrypted chat begins|All data is scrambled with that key|Confidentiality and integrity|

### What is a certificate?

A certificate says: _"This public key belongs to example.com,"_ and it is **signed by a Certificate Authority (CA)**, such as Let's Encrypt. Your browser and operating system ship with a list of CAs they trust. If a certificate is signed by someone on that list, the browser trusts it.

Think of it like a passport. You trust it because a government you recognize issued it, not because the person holding it says so.

### What can go wrong

|Problem|What you see|Meaning|
|---|---|---|
|Certificate expired|Full-page warning|The ID card is out of date|
|Wrong domain|Full-page warning|The certificate is for a different site|
|Untrusted issuer|Full-page warning|Nobody you trust vouches for it|
|Mixed content|Console warning, some content blocked|An HTTPS page tried to load an `http://` image or script|

### Related concept: HSTS

Suppose you type `example.com` without `https://`. Your first request might go out unencrypted, and an attacker could grab it there. **HSTS** is a response header that tells the browser: _"For the next year, only ever use HTTPS for this site."_ After that, the browser upgrades the connection itself, before anything leaves your machine.

---

## Part 2: Securing the building (the page and server)

Encryption protects the road. It does nothing if the page itself has a hole. Think of a courier who delivers a package safely to a house that has no front door.

The server tells the browser how to behave using **response headers**. These are small instructions that arrive before the page content. Here is a realistic set:

```http
HTTP/2 200
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; script-src 'self'
x-content-type-options: nosniff
x-frame-options: DENY
referrer-policy: strict-origin-when-cross-origin
set-cookie: session=abc123; Secure; HttpOnly; SameSite=Lax; Path=/
```

### Line-by-line walkthrough

**`strict-transport-security: max-age=31536000; includeSubDomains`**  
This is HSTS. `max-age` is in seconds, so 31536000 is one year. `includeSubDomains` applies the rule to `api.example.com`, `blog.example.com`, and so on.

**`content-security-policy: default-src 'self'; script-src 'self'`**  
This is a whitelist of where content may come from.

- `default-src 'self'` means images, styles, fonts, and so on may only load from your own domain.
- `script-src 'self'` means JavaScript may only come from your own domain.

The problem it solves: if an attacker injects `<script src="https://evil.com/steal.js">` into your page (XSS), the browser refuses to run it, because `evil.com` isn't on the list. Inline scripts are blocked too unless you explicitly allow them.

**`x-content-type-options: nosniff`**  
Browsers sometimes "guess" a file's type. An attacker could upload a file that looks like an image but contains script. `nosniff` says: _trust the declared type, don't guess._

**`x-frame-options: DENY`**  
This blocks other sites from putting your page inside an `<iframe>`, which prevents **clickjacking** (an invisible copy of your page placed over a decoy button). Modern sites often use CSP's `frame-ancestors` for the same job.

**`referrer-policy: strict-origin-when-cross-origin`**  
When you click a link, the browser normally tells the next site where you came from. This setting limits that to just the site name, not the full URL. This matters if your URLs contain things like `?token=...`.

**`set-cookie: ...`** The flags on a cookie each solve a different problem:

|Flag|Problem it solves|
|---|---|
|`Secure`|Cookie is only sent over HTTPS, so no leaking on plain HTTP|
|`HttpOnly`|JavaScript can't read it, so an XSS attack can't steal your session|
|`SameSite=Lax`|Cookie isn't sent on most cross-site requests, which blunts CSRF|
|`Path=/`|Which URLs the cookie applies to|

### Setting these in Spring Boot

Since you work with Spring Boot, here is how the same ideas look in code:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.headers(headers -> headers
        .contentSecurityPolicy(csp -> csp
            .policyDirectives("default-src 'self'; script-src 'self'"))
        .httpStrictTransportSecurity(hsts -> hsts
            .includeSubDomains(true)
            .maxAgeInSeconds(31536000))
    );
    return http.build();
}
```

Line by line:

- `HttpSecurity http` is the object you use to configure web security rules.
- `.headers(...)` opens the section for response headers.
- `.contentSecurityPolicy(...)` adds the CSP header with the policy string you give it.
- `.httpStrictTransportSecurity(...)` adds HSTS with a one-year lifetime.
- `http.build()` finishes the configuration.

Spring Security already adds several headers by default (such as `X-Content-Type-Options`), but CSP is something you usually write yourself. For cookies, you can add these lines to `application.properties`:

```properties
server.servlet.session.cookie.secure=true
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.same-site=lax
```

### Server-side habits that matter just as much

Headers are a safety net. The real work happens in your code:

|Habit|The attack it stops|
|---|---|
|Parameterized queries (`PreparedStatement`, JPA)|SQL injection|
|Encode output before putting user text in HTML|XSS|
|Hash passwords with bcrypt or Argon2, never store plain text|Stolen database becoming stolen passwords|
|CSRF tokens on state-changing forms|Forged requests|
|Validate input on the server, not just in the browser|Attackers skipping your JavaScript entirely|
|Keep dependencies updated|Known bugs like Log4Shell|

### Related concept: Same-origin policy and CORS

An **origin** is protocol + domain + port. By default, JavaScript on `https://a.com` can't read responses from `https://b.com`. This stops a random site from reading your bank page while you have it open in another tab. **CORS** is how a server says, _"it's okay, `a.com` may read my responses."_ It does this with a header like `Access-Control-Allow-Origin: https://a.com`. If you've ever seen a red CORS error in the console, this is the rule at work.

---

## Part 3: The Network tab

### What it is and why it matters

The Network tab is a recording of **every request your page makes**. It is the best place to _see_ all the theory above happening live. It answers questions like: Is this page using HTTPS? Which headers did the server send? Is a cookie missing its `Secure` flag? Why is the page slow?

**To open it:** press `F12` (or `Ctrl+Shift+I`) in Chrome, Edge, or Firefox, then click **Network**. Reload the page with `Ctrl+R` so the recording captures everything.

### Settings worth turning on

|Setting|What it does|
|---|---|
|**Preserve log**|Keeps requests when the page navigates or redirects (great for watching a login flow)|
|**Disable cache**|Forces fresh downloads so you see real behavior|
|**Throttling**|Simulates a slow connection|

### The main columns

|Column|Meaning|
|---|---|
|**Name**|The file or endpoint requested|
|**Status**|Result code (see below)|
|**Type**|document, script, stylesheet, image, fetch/xhr, font|
|**Initiator**|_What caused this request_, such as the HTML or a specific script line|
|**Size**|Bytes transferred (and uncompressed size)|
|**Time**|How long it took|
|**Waterfall**|A timeline bar chart showing when each request started and finished|

You can right-click the column header to add more, like **Protocol** (`h2` means HTTP/2) and **Domain**.

### Status codes you'll see most

|Code|Meaning|
|---|---|
|**200**|OK, success|
|**301 / 302**|Redirect (for example from `http://` to `https://`)|
|**304**|Not modified, so the browser used its cached copy|
|**400**|Bad request (your data was malformed)|
|**401**|Not authenticated (you need to log in)|
|**403**|Forbidden (logged in, but not allowed)|
|**404**|Not found|
|**500**|Server error (a bug on the server side)|

A red row usually means failure, and the cause could be a blocked request (CORS or CSP), a network error, or a 4xx/5xx status.

### Click on a request: the detail panels

Click any row and a panel opens with tabs. Each one is useful for security.

**Headers**  
Shows the request URL, method (`GET`, `POST`...), status, and **both** the request headers (what the browser sent) and **response headers** (what the server sent). This is where you check for `strict-transport-security`, `content-security-policy`, and `set-cookie`. If a header from Part 2 isn't there, the server isn't sending it.

**Payload**  
The data you _sent_: form fields, JSON body, or query parameters. This is where you'd notice if a password is going somewhere it shouldn't, such as in the URL.

**Preview / Response**  
The data you _received_. _Preview_ shows it formatted (JSON as a tree), and _Response_ shows the raw text. A common security finding: an API returns more fields than the screen shows, like an internal ID or an email.

**Initiator**  
A call stack showing which script triggered the request. It helps you spot unexpected third-party calls.

**Timing**  
Breaks one request into phases:

|Phase|Meaning|
|---|---|
|Queueing|Waiting for the browser to get to it|
|DNS Lookup|Finding the IP address|
|Initial connection|Opening the TCP connection|
|**SSL**|The TLS handshake from Part 1|
|Request sent|Sending your request|
|**Waiting (TTFB)**|Time to first byte, which is the server thinking|
|Content Download|Receiving the body|

You can literally see the TLS handshake cost here, and you'll notice it disappears on later requests to the same site, because the browser reuses the connection.

**Cookies**  
Shows cookies sent with the request and cookies the response tried to set. Yellow warning icons appear when something is wrong, such as a cookie rejected for a bad `SameSite` setting.

---

## Part 4: Other visible components that show security

### The address bar icon

Browsers show a padlock or a "connection" icon. Click it to see whether the connection is secure and to view the **certificate**: who issued it, the domain it covers, and its expiry date. A padlock only means the _connection_ is encrypted. It does **not** mean the site is honest. Phishing sites can also have valid certificates.

### The Application tab (Chrome/Edge) or Storage tab (Firefox)

This is where you inspect **cookies** in detail (with columns for `HttpOnly`, `Secure`, `SameSite`), plus `localStorage` and `sessionStorage`.

A useful rule: never keep session tokens in `localStorage`. Any XSS can read it with JavaScript. An `HttpOnly` cookie can't be read that way.

### The Console tab

This is where the browser _tells you_ when it blocks something. You'll see messages such as:

- `Refused to load the script ... because it violates the following Content Security Policy directive` (CSP at work)
- `Blocked by CORS policy: No 'Access-Control-Allow-Origin' header` (same-origin policy at work)
- `Mixed Content: The page was loaded over HTTPS, but requested an insecure resource` (mixed content)

These messages are your debugging friends. Each one is the browser enforcing a rule from Part 2.

### The Security / Privacy panel

Chrome has a dedicated panel for connection and certificate details (its name and location have changed between versions). It summarizes whether the page and its resources used valid HTTPS.

---

## Try it yourself (5-minute exercise)

**1. Check headers from your Debian terminal:**

```bash
curl -I https://example.com
```

`-I` fetches only the headers. Look for the security headers from Part 2. Try it on a few big sites and compare.

**2. Look at the TLS handshake:**

```bash
curl -v https://example.com 2>&1 | head -30
```

`-v` is verbose mode. You'll see the TLS version, the cipher chosen, and the certificate details.

**3. In the browser:** open any login page, turn on **Preserve log**, log in, and find the login `POST` request. Check three things: Is it HTTPS? Is the password in the **Payload** and not the URL? Does the `set-cookie` response header have `Secure; HttpOnly; SameSite`?

**4. Break something on purpose:** run a small Spring Boot app with the CSP from earlier, then add an inline `<script>alert(1)</script>` to a page. Watch the Console report the block. That's CSP protecting you.

---

## Putting it all together

|Layer|Tool|Where you can see it|
|---|---|---|
|Connection|HTTPS / TLS, certificates, HSTS|Address bar, Network → Timing (SSL), Headers|
|Browser rules|Same-origin policy, CORS, CSP|Console errors, Headers|
|Cookies|Secure, HttpOnly, SameSite|Network → Cookies, Application tab|
|Server code|Parameterized queries, hashing, validation|Not visible, so it must be built in|

The key idea: **no single layer is enough.** HTTPS protects the road, headers and cookie flags tell the browser how to defend itself, and your server code stops attacks that get past both.




[[Spring Security]]