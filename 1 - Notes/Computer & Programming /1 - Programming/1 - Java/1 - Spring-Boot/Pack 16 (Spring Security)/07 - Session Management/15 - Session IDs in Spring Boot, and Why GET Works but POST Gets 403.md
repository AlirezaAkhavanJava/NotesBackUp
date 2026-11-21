


## The problem it solves

You log in, and the session ID is working. A `GET` request returns your data, but the same session fails on a `POST` with a **403 Forbidden**. It looks like a contradiction, because the same cookie proves the same login in both cases.

It isn't one. Your cookie answers the question _"who are you?"_, and a `POST` needs the answer to a second question: _"did you really mean to send this?"_

> The **session ID** proves _who_ you are. The **CSRF token** proves the request _came from our own page_. GET needs only the first. POST needs both.

## The picture: a membership card and a counter slip

Imagine a library:

|Library|Spring Boot|
|---|---|
|Your **membership card**|The session ID in the `JSESSIONID` cookie|
|Browsing the shelves needs only the card|`GET` needs only the session|
|Borrowing a book needs the card **and** a slip that the librarian handed you at the counter|`POST` needs the session **and** the CSRF token|
|A stranger who finds your card can't get a slip unless they stand at the counter|An attacker's page can't read your page's token|
|The librarian keeps a copy of your slip number in the back|The server keeps the token **inside your session**|

## The map

```
Part 1: How the session ID works in Spring Boot (short recap)
Part 2: What the session ID can't prove
Part 3: Why GET passes
Part 4: Why POST fails, traced step by step
Part 5: How to make POST work (browser form, JavaScript, SPA, curl, APIs)
Part 6: The life of a CSRF token
Part 7: Other reasons a POST returns 403
Part 8: Try it yourself
```

---

# Part 1: How the session ID works (short recap)

|Step|Who|What happens|
|---|---|---|
|1|You|Submit the login form|
|2|Spring Security|Checks the password and builds an `Authentication`|
|3|Spring Security|Changes the session ID (fixation protection) and stores the login in the session as `SPRING_SECURITY_CONTEXT`|
|4|Tomcat|Sends `Set-Cookie: JSESSIONID=...`|
|5|Browser|Saves the cookie and **attaches it automatically** to every later request to that site|
|6|Every request|`SecurityContextHolderFilter` reads the session, finds your login, and puts you on the current thread|

The session ID is only a **key** to a server-side map. Everything about you lives on the server.

---

# Part 2: What the session ID can't prove

The browser attaches the cookie **automatically**, to every request going to your site, no matter **which page started that request**.

Imagine you're logged in to `shop.com`, and in another tab you open `evil.com`. That page contains a hidden form:

```html
<form action="https://shop.com/transfer" method="POST" id="f">
  <input type="hidden" name="to" value="attacker">
</form>
<script>document.getElementById('f').submit();</script>
```

Your browser sends `POST /transfer` to `shop.com` **with your session cookie attached**. The server sees a valid session ID and has no way of knowing that you never clicked anything.

So for requests that **change data**, the session ID alone isn't enough. The server needs something the attacker's page **cannot know**. That is the CSRF token.

---

# Part 3: Why GET passes

Spring Security's `CsrfFilter` sits early in the filter chain. Its logic is short:

```
Request arrives
  ├─ method is GET, HEAD, TRACE, or OPTIONS ?   → "safe method": skip the check, continue
  └─ any other method (POST, PUT, PATCH, DELETE):
         read the token from the request
         compare it with the token stored in the session
         match    → continue
         mismatch → reject with 403
```

|Method|CSRF check?|Why|
|---|---|---|
|`GET`, `HEAD`|No|They should only **read**. Even if an attacker forces one, nothing changes, and the same-origin policy stops the attacker's page from reading the response.|
|`OPTIONS`, `TRACE`|No|Informational|
|`POST`, `PUT`, `PATCH`, `DELETE`|**Yes**|They **change** things, which is what an attacker wants|

This is a convention, not magic. Spring trusts that your `GET` handlers don't change data. If you ever write `GET /deleteAccount`, the filter will happily let it through, and an attacker can trigger it with `<img src="https://shop.com/deleteAccount">`. That's why the rule is "never change state with GET."

---

# Part 4: Why POST fails, step by step

## Where the token lives

The default storage is `HttpSessionCsrfTokenRepository`. It keeps the token **in the HttpSession**, next to your login:

```
Session "7F3A..." (on the server)
   ├─ SPRING_SECURITY_CONTEXT → alice, ROLE_USER
   └─ CSRF token              → "9f2c71e0-..."
```

So there are two pieces to a successful POST, and they travel **differently**:

|Piece|How it reaches the server|Sent by|
|---|---|---|
|**Session ID**|`Cookie: JSESSIONID=...` header|The browser, **automatically**|
|**CSRF token**|`X-CSRF-TOKEN` header, or a form field named `_csrf`|**Your page's code**, on purpose|

An attacker's page can trigger the first (the browser does it for them) but can't supply the second, because it can't read your page to learn the token. That asymmetry is the whole defense.

## The failing request

```
POST /notes
Cookie: JSESSIONID=7F3A...           ← session is valid ✔
(no X-CSRF-TOKEN header, no _csrf field)   ← token missing ✘
```

What the server does:

```
1. SecurityContextHolderFilter: session found → you are alice
2. CsrfFilter: POST is not a safe method
      expected token = the one in the session        "9f2c71e0-..."
      actual token   = header or form field          (nothing)
      → mismatch → AccessDeniedHandler → 403
3. DispatcherServlet and your controller are never reached
```

You are correctly identified as alice, yet the request dies at the CSRF filter. That's exactly your "GET works, POST doesn't."

## The succeeding request

```
POST /notes
Cookie: JSESSIONID=7F3A...
X-CSRF-TOKEN: 9f2c71e0-...           ← matches the session's token ✔
```

The filter finds a match, passes the request on, and your controller runs.

## The default 403 gives you no clue

With Spring Boot, a CSRF rejection shows up as a plain error:

```json
{"timestamp":"...","status":403,"error":"Forbidden","path":"/notes"}
```

Nothing there says "CSRF." To see the reason, enable debug logging:

```properties
logging.level.org.springframework.security=DEBUG
```

Then you'll find a line such as `Invalid CSRF token found for http://localhost:8080/notes`. If the server has no session for you at all, you'll see a message saying it couldn't verify the token because your session was not found.

---

# Part 5: How to make POST work

How you supply the token depends on who is sending the request.

## 5.1 A server-rendered form (Thymeleaf)

```html
<form th:action="@{/notes}" method="post">
  <input name="text">
  <button>Save</button>
</form>
```

Using `th:action` makes Thymeleaf add a hidden field for you:

```html
<input type="hidden" name="_csrf" value="...token...">
```

If you write a plain `action="/notes"` instead, **the hidden field is not added**, and every submit gets a 403. This is the most common beginner cause.

## 5.2 JavaScript on a Thymeleaf page

Put the token in the page, then read it in JavaScript:

```html
<meta name="_csrf" th:content="${_csrf.token}">
<meta name="_csrf_header" th:content="${_csrf.headerName}">
```

```javascript
const token  = document.querySelector('meta[name="_csrf"]').content;
const header = document.querySelector('meta[name="_csrf_header"]').content;

fetch('/notes', {
  method: 'POST',
  headers: { [header]: token, 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'hello' })
});
```

Line by line:

- The two `<meta>` tags carry the token value and the **header name** (`X-CSRF-TOKEN`) from the server into the page. `th:content` fills them in when the page is rendered.
- `querySelector(...).content` reads them back in JavaScript.
- `[header]: token` uses the header name as a computed key, so the code works even if the name is changed in configuration.
- The browser attaches the session cookie by itself for a same-origin `fetch`. You only add the token.

## 5.3 A single-page app (React, Vue, Angular) with cookies

There's no server-rendered page to put the token in, so a common pattern is to let Spring write the token into a **cookie** that JavaScript can read:

```java
http.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse()));
```

- `CookieCsrfTokenRepository` stores the token in a cookie called `XSRF-TOKEN`.
- `withHttpOnlyFalse()` allows JavaScript to read it. This is safe because the attacker's site **can't read your site's cookies**.
- Your JavaScript copies the cookie's value into an `X-XSRF-TOKEN` header on each POST. Axios and Angular do this automatically.

Two warnings from the earlier lesson, because they trip people up:

- In Spring Security 6 and later, the token loads **lazily**, so the cookie may not be written until something reads the token. Single-page apps need a small extra request handler and filter. The reference documentation's "Single-Page Applications" section gives the exact recipe for your version.
- This cookie is separate from `JSESSIONID`. Don't confuse the two.

## 5.4 `curl` and Postman

These tools aren't pages, so nothing hands them a token. You fetch one yourself (Part 8 shows it step by step). In Postman, the same rule holds: send the session cookie and the `X-CSRF-TOKEN` header together.

## 5.5 Stateless APIs: turning CSRF off

If your API authenticates with a **token in the `Authorization` header** (JWT) and doesn't use cookies, then the browser attaches nothing automatically, and there's nothing to forge:

```java
http
    .csrf(csrf -> csrf.disable())
    .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
```

Only do this when **both** conditions are true: the API doesn't rely on cookies for authentication, and it doesn't keep sessions. Disabling CSRF on an app that uses session cookies **removes the protection and leaves the hole open**. "The POST gave me a 403, so I'll turn CSRF off" is a very common and very risky shortcut.

---

# Part 6: The life of a CSRF token

|Moment|What happens|
|---|---|
|**Created**|When something first needs it, for example a page that renders a form, or your own `CsrfToken` parameter. It's generated **lazily** and saved in the session. (This is one way a session quietly gets created for an anonymous visitor.)|
|**Sent to the page**|Through the hidden `_csrf` field, the meta tag, or a cookie|
|**Masked**|In Spring Security 6 and later, each page gets a **differently scrambled** version of the same token, as protection against the BREACH compression attack. All the versions validate, so don't be surprised that the value changes on every page load.|
|**Rotated at login**|When you log in, Spring Security **throws away the old token and creates a new one**. A form loaded **before** login carries the old token. After login you need a fresh one. Single-page apps must fetch the token again after logging in.|
|**Dies with the session**|If the session expires or is destroyed, the token goes with it|

## The "my form worked yesterday" bug

You open a long form and spend 40 minutes filling it in. The session expires after 30 idle minutes, so the **token is gone with it**. You press Submit, and the POST fails with a 403 even though everything looked fine. The fixes are a session timeout warning, a small keep-alive request, or a friendlier error page. It's not a bug in your code.

## The "wrong browser" and "wrong cookie" cases

The token belongs to **one session**. A token from Chrome's session doesn't work with Firefox's session cookie. When you test with `curl`, make sure you use the **same cookie jar** for the page that gave you the token and for the POST that uses it.

---

# Part 7: Other reasons a POST returns 403 (or something similar)

Not every failing POST is CSRF. Here is how to tell:

|Symptom|Likely cause|How to confirm|
|---|---|---|
|403 on POST/PUT/DELETE, but the same URL works on GET|**Missing or wrong CSRF token**|Debug logs say "Invalid CSRF token"|
|403 on both GET and POST|A **role or URL rule** denies you|Debug logs say access denied by `AuthorizationFilter`|
|403 only for POST, and logs show no CSRF message|A rule written **for POST only**, such as `requestMatchers(HttpMethod.POST, "/admin/**").hasRole("ADMIN")`|Check your `authorizeHttpRequests`|
|403 from `@PreAuthorize`|Method security denied you|The log line names the method|
|401 or a redirect to `/login`|You're not authenticated (expired or missing session)|Check the cookie and session timeout|
|405 Method Not Allowed|No controller handles that method on that path|Compare with your `@PostMapping`|
|415 Unsupported Media Type|Wrong `Content-Type`|Add `-H "Content-Type: application/json"`|
|Browser shows a CORS error, no useful status|Cross-origin call blocked by the **browser**|Check the Network tab's preflight request|
|403 after the session was fine a minute ago|The session expired, so the token is gone|Look at the `JSESSIONID` and timeout|
|Logout button gives 403|Logout is a POST and needs the token|Use a form with `th:action`|
|Login page POST gives 403|The login form lacks the token (custom login page with a plain `action`)|Use `th:action` or add the hidden field|

A quick test to separate the cases: send the **same POST with a valid token**. If it now works, it was CSRF. If it still returns 403, the cause is authorization.

---

# Part 8: Try it yourself

Use a small app with form login, the web and security starters, and a CSRF-protected endpoint:

```java
@RestController
public class NoteController {

    @GetMapping("/api/me")
    public String me(Authentication auth) {
        return "Hello " + auth.getName();
    }

    @GetMapping("/csrf")
    public Map<String, String> csrf(CsrfToken token) {
        return Map.of("header", token.getHeaderName(),
                      "param",  token.getParameterName(),
                      "token",  token.getToken());
    }

    @PostMapping("/api/notes")
    public String create(@RequestBody Map<String, String> body) {
        return "saved: " + body.get("text");
    }
}
```

Line by line:

- `/api/me` is a harmless `GET` that proves the session works.
- `/csrf` takes a `CsrfToken` as a parameter, which Spring fills with the current request's token. It returns the header name, the form-field name, and the token value. **This endpoint is for learning.** In a real app you'd deliver the token through the page or a cookie instead.
- `/api/notes` is the `POST` we'll try to reach.

Now the experiments. First, log in and keep the cookie:

```bash
TOKEN=$(curl -s -c jar.txt http://localhost:8080/login | grep -oP 'name="_csrf"[^>]*value="\K[^"]+')
curl -s -o /dev/null -w "login: %{http_code}\n" -b jar.txt -c jar.txt \
     -d "username=alice&password=secret&_csrf=$TOKEN" http://localhost:8080/login
```

- The first line loads the login page, saves the pre-login cookie, and pulls the CSRF token out of the HTML.
- The second line submits the login form with that token. You should see `302`. (Even the login POST needs a token, which proves the rule applies to every POST.)

**1. GET works with only the session:**

```bash
curl -i -b jar.txt http://localhost:8080/api/me
```

You get `200` and `Hello alice`. The session was enough.

**2. POST with only the session fails:**

```bash
curl -i -b jar.txt -X POST http://localhost:8080/api/notes \
     -H "Content-Type: application/json" -d '{"text":"hi"}'
```

You get `403`. You're logged in, and the CSRF filter stopped you.

**3. Fetch a token for this session:**

```bash
CSRF=$(curl -s -b jar.txt -c jar.txt http://localhost:8080/csrf | grep -oP '"token":"\K[^"]+')
echo "$CSRF"
```

Use the **same jar**, so the token is tied to your session. (The token fetched before login is no longer valid. This is the rotation at login.)

**4. POST with the session and the token works:**

```bash
curl -i -b jar.txt -X POST http://localhost:8080/api/notes \
     -H "Content-Type: application/json" -H "X-CSRF-TOKEN: $CSRF" \
     -d '{"text":"hi"}'
```

You get `200` and `saved: hi`. Both halves are present now.

**5. A token from the wrong session fails:**

```bash
curl -i -X POST http://localhost:8080/api/notes \
     -H "Content-Type: application/json" -H "X-CSRF-TOKEN: $CSRF" -d '{"text":"hi"}'
```

With no cookie jar this time, there is no session, so there's no stored token to match. The result is `403` (or a redirect to login). A token only works with the session that issued it.

**6. See the reason in the logs:** turn on `logging.level.org.springframework.security=DEBUG` and repeat experiment 2. Look for the "Invalid CSRF token" line.

**7. Watch tokens change but still validate:** call `/csrf` three times and compare the values. They differ each time (masking). Use any of them in a POST and they all work.

**8. Break it from the browser's side:** open the Network tab on a Thymeleaf page with a form. Click the POST request, open **Payload**, and find `_csrf`. Then change `th:action` to a plain `action` and submit again. The field disappears, and the 403 arrives.

**9. See the ordering:** put a breakpoint in the controller and POST without a token. The breakpoint never triggers, because the request dies in the filter chain before the DispatcherServlet.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Disabling CSRF because POST returns 403|Removes the protection from a cookie-based app|Send the token. Disable only for stateless, header-token APIs.|
|Plain `action="/..."` in a Thymeleaf form|No hidden `_csrf` field|Use `th:action`|
|Using a token from a different session or jar|It doesn't match the stored one|Use the same cookie jar for both calls|
|Using a token fetched before login|The token is rotated at login|Fetch a fresh token after login|
|Changing state with GET|The filter doesn't check GET|Use POST, PUT, or DELETE|
|Putting the token in a URL query string|It leaks into logs and the `Referer` header|Use a header or a form field|
|Exposing the session ID or token in logs|Anyone with the log can use it|Don't log either|
|Long forms and short session timeouts|The token disappears with the session|Keep-alive or a timeout warning|
|Treating every 403 as CSRF|Role rules also return 403|Check the logs|
|Expecting CORS settings to replace CSRF|CORS controls reading, not sending|Keep CSRF protection|
|Assuming `SameSite` is enough|It's a second layer, not a replacement|Keep both|

---

## Related concept, briefly

**`SameSite` cookies:** a cookie attribute that tells the browser not to attach the cookie to most **cross-site** requests. With `SameSite=Lax` (the default in modern browsers), a form POST from `evil.com` to your site is sent **without your session cookie**, so the attack fails even before the CSRF filter sees it. Think of it as a second lock on the same door: the CSRF token is Spring's lock, and `SameSite` is the browser's lock. Keep both, because `SameSite` has edge cases (older browsers, subdomains, and "site" being looser than "origin").

---

## The whole picture

|Question|Answer|
|---|---|
|What does the session ID prove?|_Who_ you are|
|Where is the session stored?|On the server, keyed by the ID in the `JSESSIONID` cookie|
|Why does GET work with just the session?|`CsrfFilter` skips safe methods (GET, HEAD, OPTIONS, TRACE)|
|Why does POST fail with just the session?|The browser sends cookies automatically, so POST also needs proof it came from your page|
|What is the proof?|The CSRF token, stored in the session and sent in a header or form field|
|How does the token travel?|`X-CSRF-TOKEN` header or `_csrf` form field, added by your page's code|
|Why can't an attacker's page supply it?|The same-origin policy stops it from reading your page|
|When is the token rotated?|At login|
|When does it die?|When the session does|
|How do I send it from a form?|`th:action` adds it automatically|
|From JavaScript?|Meta tags or the `XSRF-TOKEN` cookie, then a header|
|From curl?|Fetch it with the same cookie jar, then add `-H "X-CSRF-TOKEN: ..."`|
|When can I turn CSRF off?|Only for stateless APIs that don't rely on cookies|
|Is every POST 403 a CSRF problem?|No. Check logs for authorization denials too.|




[[Spring Security]]