


## The problem it solves

HTTP forgets you between requests, so the server needs a way to recognize you again. The session ID is the small token that makes this possible. To really understand it, follow one ID through its whole life: **born on the server, travels to the browser, comes back with every request, and eventually dies.**

Here is the journey in one picture:

```
 SERVER (Tomcat inside your app)                     BROWSER
 ┌─────────────────────────────┐                ┌──────────────────┐
 │ 1. Something asks for a     │                │                  │
 │    session                  │                │                  │
 │ 2. ID generator makes a     │                │                  │
 │    random ID                │                │                  │
 │ 3. Session object is stored │                │                  │
 │    in a map: ID → session   │                │                  │
 │ 4. Set-Cookie header added  │ ─────────────▶ │ 5. Cookie saved  │
 │                             │                │    in cookie jar │
 │ 7. Server finds session     │ ◀───────────── │ 6. Cookie sent   │
 │    by ID                    │                │   on each request│
 └─────────────────────────────┘                └──────────────────┘
```

---

## Part 1: Where the ID is created

### It's Tomcat, not your code

When you run a Spring Boot web app, Tomcat is running inside it. Tomcat has a component called the **session manager**. It does three jobs:

|Job|What it means|
|---|---|
|Generate IDs|Makes new random session IDs|
|Store sessions|Keeps a map from ID to session object|
|Expire sessions|Removes sessions that have been idle too long|

Your controller code and Spring Security never invent the ID. They **ask** Tomcat for a session, and Tomcat does the rest.

### What triggers creation

A session is created lazily, only when something asks for one:

|Trigger|Example|
|---|---|
|Your code asks for it|`request.getSession()` or `request.getSession(true)`|
|A controller parameter|`public String visit(HttpSession session)`|
|Spring Security at login|After a successful login, it needs somewhere to store "who you are"|

If nothing asks, **no session exists**. A visitor browsing public pages gets no ID and costs the server nothing.

### How the ID itself is made

Tomcat's ID generator does roughly this:

1. Gets **16 random bytes** from Java's `SecureRandom`. This is a cryptographically strong random source, not the everyday `Random` class.
2. Converts them to **hexadecimal text**, which gives 32 characters, like `7F3A9C1E5B2D48A0C6E91F4D2B8A7305`.

That's 128 bits of randomness. The number of possible IDs is so large that nobody can guess a valid one by trying. The ID contains **no information** about you. It isn't your username, your time of login, or anything else. It's a meaningless number that happens to point at your data.

This is why the generator matters for security. If IDs were predictable (for example a counter: 1, 2, 3...), an attacker could just try the next number and walk into someone else's session.

### What gets stored on the server

Tomcat creates a session object and puts it in a map:

```
Map<String, Session>
  "7F3A9C1E..."  →  Session { creationTime, lastAccessedTime, attributes{...} }
  "B20D44F9..."  →  Session { ... }
```

By default this map lives in **the memory of your running app**. The session object holds:

|Field|Meaning|
|---|---|
|ID|The key in the map|
|Creation time|When it was born|
|Last accessed time|Resets the idle timer on every request|
|Max inactive interval|How long idle sessions may live (default 30 minutes)|
|Attributes|A small map of your data, plus Spring Security's login state|

Because it's in memory, a normal app restart **loses all sessions** and everyone is logged out. (Tomcat can save sessions to disk on a clean shutdown, but Spring Boot turns that off by default. See `server.servlet.session.persistent`.)

---

## Part 2: How the ID leaves the server

Once the session exists, Tomcat needs to tell the browser about it. It does that by adding a header to the **response** it's already sending:

```http
HTTP/1.1 200
Set-Cookie: JSESSIONID=7F3A9C1E5B2D48A0C6E91F4D2B8A7305; Path=/; HttpOnly; Secure; SameSite=Lax
```

Reading it piece by piece:

|Part|Meaning|
|---|---|
|`Set-Cookie:`|"Browser, please store this"|
|`JSESSIONID=7F3A...`|The cookie's **name** and **value**. The value is the session ID.|
|`Path=/`|Send it for every URL on this site|
|`HttpOnly`|JavaScript can't read it|
|`Secure`|Only send it over HTTPS|
|`SameSite=Lax`|Don't send it on most cross-site requests|

Notice there's **no `Expires` or `Max-Age`**. That makes it a **session cookie** (a different meaning of the word "session"), which the browser normally discards when you close it. Don't confuse the two:

|Term|Lives where|Ends when|
|---|---|---|
|**Session** (server-side)|Server memory|Timeout, logout, or server restart|
|**Session cookie** (browser-side)|Browser|Browser closes (usually)|

The `Secure` flag is added by Tomcat when the request came over HTTPS, and Spring Boot's `server.servlet.session.cookie.*` properties control the rest.

---

## Part 3: Where the ID goes in the browser

### Saved in the cookie jar

The browser reads `Set-Cookie` and files the cookie under the **site that sent it**. You never write code for this. It's built into every browser.

You can see it yourself: open the browser developer tools, go to **Application → Cookies**, pick your site, and you'll find `JSESSIONID` with its value and flags.

### Sent back automatically

From now on, every request to that same site carries it:

```http
GET /orders HTTP/1.1
Host: localhost:8080
Cookie: JSESSIONID=7F3A9C1E5B2D48A0C6E91F4D2B8A7305
```

The browser decides when to attach it by matching the cookie rules (domain, path, `Secure`, `SameSite`). Your JavaScript doesn't add it. This is the same automatic behavior that makes CSRF possible, so remember: the cookie goes along even when a request is triggered from another site, and `SameSite` and CSRF tokens exist to deal with that.

---

## Part 4: The return trip to the server

When the request arrives, Tomcat does this:

1. Reads the `Cookie` header and extracts the `JSESSIONID` value.
2. Looks that value up in its map.
3. **Found and not expired:** it attaches that session to the request and resets the idle timer.
4. **Not found:** (expired, server restarted, forged) it treats you as having no session. If your code then asks for one, Tomcat creates a **brand-new session with a new ID** and sends a fresh `Set-Cookie`.

That last point surprises people. A forged or stale ID is not an error. It's simply ignored.

---

## Part 5: What Spring Security adds

Spring Security doesn't create IDs, but it controls **when** one is created or replaced. At login, this happens:

```
1. Browser submits the login form (may already hold an old JSESSIONID, or none)
2. Spring Security checks the password ✓
3. Session fixation protection: Tomcat swaps the session ID
   (same session data, brand-new ID)
4. Spring Security saves your login (the SecurityContext)
   as an attribute inside the session
5. Response sends Set-Cookie with the NEW ID
```

Step 3 is the part to focus on. It's calling this method on the request:

```java
request.changeSessionId();
```

This is a standard servlet method that keeps the session's data but gives it a new ID. The attack it stops: an attacker gets you to use an ID they already know. If the ID didn't change at login, they'd be logged in as you. After the swap, the ID they know points to nothing.

Step 4 stores your identity under an attribute name, roughly like this:

```
Session "9C41E0...":
   SPRING_SECURITY_CONTEXT → SecurityContext{ Authentication{ alice, [ROLE_USER] } }
```

So "being logged in" really means: _the session your cookie points to contains a SecurityContext._

---

## Part 6: See the whole journey in code

Here's a tiny controller that lets you watch creation happen:

```java
@RestController
public class SessionDemoController {

    @GetMapping("/peek")
    public String peek(HttpServletRequest request) {
        HttpSession existing = request.getSession(false);
        if (existing == null) {
            return "No session yet";
        }
        return "ID = " + existing.getId() + ", new? " + existing.isNew();
    }

    @GetMapping("/start")
    public String start(HttpSession session) {
        return "ID = " + session.getId() + ", new? " + session.isNew();
    }
}
```

Line by line:

- `request.getSession(false)` means "give me the session **only if it already exists**." Passing `false` stops Tomcat from creating one. Perfect for peeking.
- `if (existing == null)` handles the "no session yet" case, which is a normal state.
- `existing.getId()` returns the 32-character ID. Use this for learning and debugging, and never show it to users or put it in logs.
- `existing.isNew()` is `true` only during the request in which the session was created, because the browser hasn't confirmed it yet.
- `/start` takes `HttpSession session` as a parameter. Because that parameter **asks** for a session, Spring and Tomcat create one if it's missing. That is the creation moment.

### Run the experiment

```bash
# 1. No session yet
curl -i -c jar.txt -b jar.txt http://localhost:8080/peek

# 2. Create one (look for Set-Cookie in the response!)
curl -i -c jar.txt -b jar.txt http://localhost:8080/start

# 3. Now it exists, and new? is false
curl -i -c jar.txt -b jar.txt http://localhost:8080/peek

# 4. Look at what the "browser" saved
cat jar.txt
```

What you should notice:

|Call|What you see|What it proves|
|---|---|---|
|1|"No session yet", no `Set-Cookie`|Sessions are created lazily|
|2|`Set-Cookie: JSESSIONID=...` and `new? true`|The server created and sent it|
|3|The same ID, `new? false`|The browser sent it back and the server found it|
|4|A line containing `JSESSIONID`|The cookie jar holds the ID|

Then try a forged ID:

```bash
curl -i -H "Cookie: JSESSIONID=AAAAAAAA" http://localhost:8080/peek
```

You'll get "No session yet". The server doesn't know that ID, so it ignores it.

---

## The whole life of an ID

|Stage|Where the ID is|Who acts|
|---|---|---|
|Born|In Tomcat's memory, as a key in the session map|Tomcat (when asked)|
|Sent|In the `Set-Cookie` response header|Tomcat|
|Stored|In the browser's cookie jar|Browser|
|Returned|In the `Cookie` request header|Browser|
|Recognized|Matched against the map|Tomcat|
|Replaced|After login, swapped for a new ID|Spring Security + Tomcat|
|Dies|Removed from the map and the browser|Timeout, logout, or `invalidate()`|

---

## One related concept, briefly

**Why `SecureRandom` and not a counter or timestamp?** If an ID can be predicted, the whole system collapses, because anyone could claim any session. `SecureRandom` is designed so that seeing a million IDs tells you nothing about the next one. The ID's _only_ strength is being unguessable, which is why you must also protect it in transit (HTTPS) and from scripts (`HttpOnly`).





[[Spring Security]]