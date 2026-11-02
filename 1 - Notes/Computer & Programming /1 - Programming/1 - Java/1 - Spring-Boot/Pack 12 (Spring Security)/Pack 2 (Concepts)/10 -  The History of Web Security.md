


The history of web security is a story of one pattern repeating: the web gets a new feature, people find a way to abuse it, and a defense gets bolted on afterward. If you know the story, today's security rules stop looking like random checklists. Each one is a scar from a real attack.

## 1. The trusting web (1989-1993)

The first web was built by researchers sharing documents. Nobody was trying to steal anything, so security wasn't a goal.

HTTP, the protocol browsers use to talk to servers, sent everything as **plain text**. Anyone between you and the server could read it, and nothing checked who the server really was. That was fine for physics papers. It stopped being fine once people wanted to buy things online.

## 2. Encryption arrives (1994-1999)

Netscape fixed the plain-text problem by inventing **SSL** (Secure Sockets Layer), which encrypts traffic between browser and server. It also solved a second problem: how do you know you're talking to the real bank? Servers present a **certificate**, which is a digital ID card vouched for by a trusted authority.

SSL 2.0 (1995) had serious flaws, so SSL 3.0 followed in 1996. In 1999 the standard was renamed **TLS** (Transport Layer Security), the name still used today. When people say "SSL," they almost always mean TLS.

Two other inventions from this era shaped everything after:

- **Cookies (1994):** small pieces of data a site stores in your browser. They let a site remember that you're logged in. They also became the most valuable thing to steal.
- **JavaScript (1995):** code that runs inside your browser. It made pages interactive, but it also meant a website could run code on your machine. That forced browsers to invent the **same-origin policy**, a rule that says a script from one site can't read data from another site.

## 3. The injection era (1998-2005)

Websites started using databases and user input, and developers started gluing the two together carelessly. This is where the classic attacks were born.

|Attack|Roughly when|The idea in one line|
|---|---|---|
|SQL injection|1998|Attacker types SQL code into a form, and your database runs it|
|Cross-site scripting (XSS)|1999-2000|Attacker gets _their_ JavaScript to run on _your_ page|
|CSRF|~2001|Attacker tricks your logged-in browser into sending a request you never intended|

Here is what SQL injection looks like. Imagine a login written in Java like this:

```java
String sql = "SELECT * FROM users WHERE name = '" + name + "'";
```

If someone types `' OR '1'='1` as their name, the query becomes:

```sql
SELECT * FROM users WHERE name = '' OR '1'='1'
```

`'1'='1'` is always true, so the query returns every user. The root problem is that the database can't tell your _code_ from the attacker's _data_, because you mixed them into one string. The fix is **parameterized queries** (also called prepared statements), which keep code and data separate.

This was also the era of worms like Code Red and Nimda (2001), which spread by exploiting server bugs. In response, **OWASP** (the Open Web Application Security Project) formed in 2001 and published its first **Top 10** list of the most common web flaws in 2003. That list is still updated and still widely used.

## 4. The Web 2.0 era (2005-2010)

Pages became apps. Ajax (JavaScript fetching data in the background) and user-generated content exploded. That meant more places for attackers to inject things.

In 2005, the **Samy worm** hit MySpace. One user wrote a bit of JavaScript in his profile that added him as a friend and copied itself to the profile of every visitor. Within about a day, over a million profiles were infected. It was harmless in intent, but it proved XSS could spread like a virus.

Defenses started appearing:

- **HttpOnly cookies:** a flag that hides a cookie from JavaScript, so XSS can't steal it.
- **Output encoding:** converting `<script>` into harmless text before showing user input.
- **Clickjacking** (2008) was discovered, where an invisible page sits over a real button. It led to the `X-Frame-Options` header.

## 5. The HTTPS wake-up call (2010-2016)

For years, many sites used HTTPS only on the login page. Then in 2010, a browser extension called **Firesheep** let anyone on coffee-shop Wi-Fi hijack other people's Facebook and Twitter sessions with one click. It worked because the session cookie traveled unencrypted after login.

That made the problem impossible to ignore. Several things followed:

- **HSTS** (2012): a header telling browsers "only ever talk to me over HTTPS."
- A string of TLS bugs: BEAST, CRIME, **Heartbleed** (2014, a flaw in OpenSSL that leaked server memory), and POODLE.
- Edward Snowden's 2013 revelations about mass surveillance, which pushed the whole industry toward encrypting everything.
- **Let's Encrypt** (public beta late 2015): free, automated certificates. HTTPS stopped being expensive and became the default.

## 6. The modern era (2016-now)

The basics got better, so attackers moved to new targets.

- **TLS 1.3** (2018) made encryption faster and removed old, risky options.
- **Content Security Policy (CSP)** lets a site declare exactly which scripts may run, which limits the damage of XSS.
- **SameSite cookies** (browsers made `Lax` the default around 2020) blunt CSRF by default.
- **Spectre** (2018) showed that even CPU behavior could leak data between sites, so browsers began isolating each site in its own process.
- **Passkeys and WebAuthn** replace passwords with cryptographic keys, which defeats phishing.
- **Supply-chain attacks** became a major theme: attackers poison a library you depend on instead of attacking you directly. The 2018 event-stream incident and the 2020 SolarWinds breach are famous examples.
- **Log4Shell** (December 2021) was a flaw in Log4j 2, a logging library used by a huge share of Java applications. Logging a malicious string could make the server run attacker-controlled code. It was one of the most serious vulnerabilities in years, and it was a reminder that your dependencies are part of your attack surface.

## The big lessons

1. **Mixing data with code causes injection.** SQL injection and XSS are the same mistake in different places.
2. **Defaults matter more than documentation.** Free HTTPS and SameSite-by-default did more than a decade of "please be careful" advice.
3. **Every new feature is a new attack surface.** Cookies, JavaScript, and Ajax each opened a new class of attack.
4. **Security is layered.** No single fix wins. You combine HTTPS, input handling, safe cookies, CSP, and dependency hygiene.

## Two related concepts, briefly

**Same-origin policy:** a browser rule that lets a page only read data from the same site (same protocol, domain, and port). Without it, any website you visit could read your email tab. **CORS** is the controlled way for a server to relax that rule.

**OWASP Top 10:** a regularly updated list of the most critical web risks, built from real-world data. It's a great checklist for learning what to defend against, and many of its categories map directly onto the eras above.

Since you work with Java and Spring Boot, you can see this history reflected in Spring Security's defaults: it enables CSRF protection, sets security headers like HSTS, and encourages password hashing out of the box. Those defaults exist because of the attacks above.




[[Spring Security]]