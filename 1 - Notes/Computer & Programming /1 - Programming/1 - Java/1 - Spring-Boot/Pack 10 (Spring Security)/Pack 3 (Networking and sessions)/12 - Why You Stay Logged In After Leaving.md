


## The problem it solves

This looks like a contradiction. We said a session is temporary, usually 30 minutes of idle time, yet you open Facebook after a week and you're still logged in. And then you clear your browsing data and you're suddenly logged out everywhere.

The answer is that **"being logged in" is not one thing**. Several separate pieces each have their own lifetime, and the long-lasting one is not the session.

## Short answers

|Your question|Answer|
|---|---|
|Is it a browser feature to remember me?|Partly. The browser **stores and returns cookies**, but it doesn't know what they mean. The site decides what the cookie does.|
|Is it the session?|**Usually not.** It's a separate long-lived token, often called a remember-me or login token.|
|Why does clearing data log me out?|The long-lived token was a **cookie**, and you deleted it. Without it, the server has nothing to recognize you by.|

---

## Part 1: The pieces and their lifetimes

Think of three different things that can keep you logged in:

|Piece|Where it lives|Typical lifetime|Dies when|
|---|---|---|---|
|**Server-side session**|Server memory or Redis|Minutes to hours|Idle timeout, logout, restart|
|**Session cookie** (holds the session ID)|Browser|Until the browser closes (usually)|Browser closes, or you clear cookies|
|**Persistent login cookie** (remember-me token)|Browser, **plus a record on the server**|Days, weeks, or months|Its expiry date, logout, or you clear cookies|

The first two together are what we studied. The third piece is the answer to your question.

### Two meanings of "temporary" cookie

The cookie that carries the session ID usually has **no expiry date**, so the browser keeps it only while it's running. A cookie with an expiry date is **persistent**, and the browser saves it to disk and keeps it across restarts:

```http
Set-Cookie: JSESSIONID=7F3A...; HttpOnly; Secure
```

This one is a session cookie. There's no `Expires`, so it vanishes when you close the browser.

```http
Set-Cookie: remember-me=dXNlcjox...; Max-Age=1209600; Path=/; HttpOnly; Secure
```

This one is persistent. `Max-Age=1209600` is 14 days in seconds, so the browser writes it to disk and sends it back for two weeks, even after restarts.

The word "session" is confusing here because it appears twice:

|Term|What it is|
|---|---|
|**Session** (server-side)|The data on the server|
|**Session cookie** (browser-side)|A cookie with no expiry date|

They're different things that share a name.

---

## Part 2: What happens when you "come back after a week"

Here is the story that explains it all:

```
Day 1, 9:00   You log in, tick "Keep me logged in".
              Server creates:
                • a short SESSION (ID 7F3A...)         → cookie with no expiry
                • a long-lived REMEMBER-ME token       → cookie with Max-Age = 14 days
                  and stores a copy of it in its own database

Day 1, 9:45   You leave. The session times out and is deleted from server memory.
              The remember-me cookie is still in your browser, saved on disk.

Day 8, 20:00  You come back. Your browser sends:
                Cookie: remember-me=dXNlcjox...      (the old JSESSIONID is gone or unknown)

              The server thinks:
                1. No valid session. Normally you'd be a stranger.
                2. But there's a remember-me cookie. Let me check my database...
                3. The token matches a record. This is a known device.
                4. Create a BRAND-NEW session (new ID) for this user.
                5. Issue a fresh remember-me token (the old one is replaced).

              You see the site, already logged in.
```

You never saw any of it. The short-lived session expired as designed, and a **separate long-lived token** quietly created a new session for you. The session really is temporary. It just gets recreated automatically.

---

## Part 3: Why clearing browsing data logs you out

The remember-me token was stored **in your browser as a cookie**. Delete the cookie, and your browser has nothing to send. The server may still have its copy in the database, but it can't recognize you, because **you no longer hold the ticket**.

```
Before clearing:   Browser holds [remember-me cookie]  →  Server: "Welcome back, Alice"
After clearing:    Browser holds nothing               →  Server: "Who are you? Please log in."
```

### "Cache" and "cookies" are different things

Browsers let you clear several different kinds of data. They are often shown as separate checkboxes:

|Item|What it is|Logs you out?|
|---|---|---|
|**Cached images and files**|Saved copies of images, scripts, and CSS so pages load faster|**No**|
|**Cookies and other site data**|Cookies, `localStorage`, `IndexedDB`|**Yes**|
|**Browsing history**|List of pages you visited|No|
|**Saved passwords**|Your password manager entries|No (and they help you log in again)|

So if you only clear the **cache**, you stay logged in. It's the **cookies** that hold your login.

One more detail: some sites keep their tokens in `localStorage` instead of cookies, especially single-page apps using JWT. "Cookies and site data" clears that too, so the result is the same.

---

## Part 4: Is it a browser feature?

It's easy to blame the browser, so here is exactly what the browser does and what it doesn't do.

|The browser does|The browser does **not** do|
|---|---|
|Stores cookies (in memory or on disk, depending on expiry)|Understand what a cookie means|
|Sends cookies back to the matching site|Decide who you are|
|Deletes cookies when they expire or you clear them|Keep you logged in by itself|
|Optionally restores your last tabs and session cookies on startup|Know whether a login token is still valid|

The browser is a **delivery person**. It carries the ticket and hands it back, and the site decides everything else.

### Other browser features that look like "remembering you"

These are real browser features, but they work differently:

|Feature|What it does|How it differs from a login|
|---|---|---|
|**Password manager**|Saves your username and password and **autofills** the login form|You're still logging in. It just types for you.|
|**"Continue where you left off"** (Chrome and others)|Reopens your last tabs and **keeps session cookies alive** across restarts|Can make a "no-expiry" cookie survive, so you stay logged in after closing the browser|
|**Sync** (Chrome, Firefox)|Copies passwords and bookmarks between your devices|Doesn't make you logged in on the other device|

So if a site logs you out when you close the browser, but not on your friend's computer, the friend might simply have "continue where you left off" turned on.

---

## Part 5: How the server stores the remember-me token safely

A remember-me token is powerful: it logs someone in without a password. So a careless design is dangerous. Here are the two classic designs.

### Design 1: Simple hash-based token (weak)

The cookie holds something like `username + expiry + hash(username, expiry, password, secretKey)`. The server recomputes the hash to check it. There's nothing stored on the server, but a stolen cookie works until it expires, and the server can't tell it was stolen. Avoid this for important apps.

### Design 2: Persistent token (stronger)

The server stores records in a table, and the cookie contains two random values:

|Column|Meaning|
|---|---|
|`username`|Who it belongs to|
|`series`|A random ID that stays the same for this device's login|
|`token`|A random value that **changes every time it's used**|
|`last_used`|When it was last used|

The flow on each use:

```
1. Cookie arrives with (series=S1, token=T1)
2. Server finds the row with series S1
3. Token matches?
     YES → log the user in, then generate a NEW token T2
           (same series S1), save it, and send the new cookie
     NO  → The series is known but the token is wrong.
           That means an old token was reused, so someone
           probably stole the cookie. Delete ALL tokens for
           this user and make them log in again.
```

This **rotation** is the clever part. If an attacker steals the cookie and uses it first, your next visit presents an old token. The server sees "right series, wrong token," recognizes the theft, and wipes everything.

---

## Part 6: Spring Security's remember-me

In Spring Security, the feature is called **remember-me**. Here is the persistent-token version:

```java
@Bean
PersistentTokenRepository tokenRepository(DataSource dataSource) {
    JdbcTokenRepositoryImpl repo = new JdbcTokenRepositoryImpl();
    repo.setDataSource(dataSource);
    return repo;
}

@Bean
SecurityFilterChain filterChain(HttpSecurity http,
                                PersistentTokenRepository tokenRepository) throws Exception {
    http
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults())
        .rememberMe(r -> r
            .tokenRepository(tokenRepository)
            .tokenValiditySeconds(14 * 24 * 60 * 60)
            .key("a-long-random-secret-from-config"));
    return http.build();
}
```

Line by line:

- `JdbcTokenRepositoryImpl` is a ready-made class that stores tokens in your database (PostgreSQL works fine). It expects a table called `persistent_logins`, which has the columns from the table above.
- `.rememberMe(...)` switches the feature on.
- `.tokenRepository(...)` says "use the persistent, rotating design, and store the tokens here."
- `.tokenValiditySeconds(14 * 24 * 60 * 60)` makes the cookie live 14 days.
- `.key(...)` is a secret used to sign the cookie. Keep it in configuration, not in source code.

The table:

```sql
create table persistent_logins (
    username  varchar(64) not null,
    series    varchar(64) primary key,
    token     varchar(64) not null,
    last_used timestamp   not null
);
```

On the login page, the user opts in with a checkbox whose name Spring expects:

```html
<input type="checkbox" name="remember-me"> Keep me logged in
```

When that box is ticked, Spring Security creates the `remember-me` cookie after login. When the session later expires and the cookie arrives, a filter called `RememberMeAuthenticationFilter` checks it, logs you in, and creates a new session with a new ID.

Two things to note:

- When you log out, Spring Security also deletes the remember-me token from the database and the cookie.
- A remember-me login is treated as **less trusted** than a fresh password login. Spring lets you require a real login for sensitive pages, using `fullyAuthenticated()` in your rules. That's how sites ask for your password again before changing your email.

---

## Part 7: What big websites really do

Large sites like Google, Facebook, or GitHub follow the same pattern, with their own names:

|Idea|What you'll see|
|---|---|
|Short-lived thing that does the work|An access token or session cookie|
|Long-lived thing that renews it|A persistent login cookie (valid for weeks or months)|
|Server-side record|A row listing your devices ("Chrome on Windows, last active yesterday")|
|"Log out of all devices"|The server deletes all those rows|
|"Trust this device"|Another long-lived cookie that lets you skip two-factor codes|

---

## Try it yourself

**1. Spot the difference in the browser:**  
Open the Application tab (Chrome or Edge) or Storage tab (Firefox), choose **Cookies**, and look at the **Expires / Max-Age** column on a site you stay logged in to. A date far in the future marks the persistent login cookie. `Session` marks the temporary kind.

**2. Delete just one cookie:**  
On a site where you're logged in, delete only the **session** cookie (`JSESSIONID`) and reload. If the site has remember-me, you stay logged in and get a **new** session cookie. Then delete the **remember-me** cookie too, and reload. Now you're logged out.

**3. Prove cache is not the problem:**  
Clear only "Cached images and files," then reload. You'll still be logged in.

**4. Watch it in your own Spring Boot app:**  
Add the remember-me config above, log in with the checkbox ticked, and look at the cookies. You'll see `JSESSIONID` (no expiry) and `remember-me` (14 days). Delete `JSESSIONID`, reload, and notice you stay logged in with a different `JSESSIONID`. Then look at the `persistent_logins` table and watch the `token` value change after each use.

**5. Check the headers with curl:**

```bash
curl -i -c jar.txt -d "username=alice&password=secret&remember-me=on" http://localhost:8080/login
cat jar.txt
```

`-d` sends form data, and `remember-me=on` is the ticked checkbox. The cookie jar shows an expiry time for the `remember-me` cookie, and `0` for the session cookie.

---

## Related concept, briefly

**Idle timeout vs absolute timeout:** an **idle timeout** ends a session after a period of _no activity_ (the 30 minutes we've been using). An **absolute timeout** ends it a fixed time after login, _no matter how active you are_. Banks often use both: you're logged out after 10 idle minutes, and also after 8 hours total. Remember-me tokens are essentially a deliberate, controlled exception to these limits, which is why they need extra protection.

---

## The whole picture

|Question|Answer|
|---|---|
|Is the session permanent?|No, it expires in minutes or hours|
|Why am I still logged in after weeks?|A separate long-lived **persistent cookie** quietly creates a new session|
|Is that the browser's feature?|The browser only stores and sends cookies. The site's server decides what they mean.|
|Why does clearing data log me out?|Clearing **cookies** deletes the long-lived token, and the server can't recognize you|
|Does clearing only the cache log me out?|No, cache and cookies are different|
|What's safer, a simple or persistent token?|The persistent, rotating token, since reuse reveals theft|
|What's Spring Security's feature called?|`rememberMe`|





[[Spring Security]]