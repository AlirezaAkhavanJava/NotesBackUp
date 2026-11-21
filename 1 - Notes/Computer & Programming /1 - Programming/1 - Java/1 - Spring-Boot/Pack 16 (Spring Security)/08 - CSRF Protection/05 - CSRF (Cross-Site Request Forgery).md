


CSRF is one of the most common web attacks, and it works even when your login system is perfect. If you understand it, you'll know why Spring Security blocks some of your POST requests by default, and when it's safe to turn that protection off.

## The idea in one sentence

An attacker's website tricks **your logged-in browser** into sending a request to **another site** you're logged into, and that site thinks the request came from you.

## Why it works: browsers send cookies automatically

When you log in to `mybank.com`, the server gives your browser a **session cookie**. From then on, the browser attaches that cookie to **every request to `mybank.com`**. It does this no matter which page triggered the request. The cookie doesn't care whether the request came from the bank's own page or from some other site.

That automatic behavior is the whole weakness.

## A story of how the attack happens

1. You log in to `mybank.com`. Your browser stores the session cookie.
2. In another tab, you open `evil.com` (a link in an email, for example).
3. That page contains a hidden form like this:

```html
<form action="https://mybank.com/transfer" method="POST" id="f">
  <input type="hidden" name="to" value="attacker-account">
  <input type="hidden" name="amount" value="5000">
</form>
<script>document.getElementById("f").submit();</script>
```

4. The form submits itself. Your browser sends the POST to `mybank.com` and **attaches your session cookie**.
5. The bank sees a valid session, thinks you made the transfer, and does it.

You never clicked anything on the bank's site. The attacker also never saw your cookie. They only needed your browser to send it for them.

## What the attacker can and can't do

- **Can:** trigger actions that change state, such as transfers, password changes, email changes, and deletes.
- **Can't:** read the response. The browser's same-origin policy stops `evil.com` from seeing what `mybank.com` replied. So CSRF is about _doing_ things, not _stealing_ data.

This is also why **GET requests should never change data**. A simple `<img src="https://mybank.com/delete?id=5">` could trigger one.

## How the defense works: the CSRF token

The fix is to require something the attacker **cannot know**.

1. When the server renders a form, it includes a **random, secret token** tied to your session.
2. When you submit the form, the token comes back with the request.
3. The server compares the token with the one it expects. If it's missing or wrong, it rejects the request.

`evil.com` can make your browser send the cookie, but it can't read the token from the real site (because of the same-origin policy). So its forged request has no valid token and fails.

## How Spring Security handles it

`CsrfFilter` is on by default. It checks every request that **changes state** (POST, PUT, PATCH, DELETE). Safe methods like GET, HEAD, and OPTIONS skip the check.

With Thymeleaf, the token is added to your forms automatically. For a JavaScript front end, a common setup stores the token in a cookie that your script can read and send back as a header:

```java
http.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse()));
```

Your JavaScript reads the `XSRF-TOKEN` cookie and sends its value in the `X-XSRF-TOKEN` header. Only code running on **your** site can read that cookie, so the attacker's page can't copy it.

If you forget the token, you'll see a **403 Forbidden** on POST requests. This catches almost every beginner. It isn't a login problem. It's the CSRF check doing its job.

## When it's safe to disable

You'll often see this in JWT tutorials:

```java
http.csrf(csrf -> csrf.disable());
```

That is fine **only if** your API is stateless and authenticates with a token the client adds **manually** (the `Authorization: Bearer ...` header). The attack depends on the browser sending credentials _automatically_, and browsers don't do that for a header your JavaScript sets itself. No automatic credentials means nothing for the attacker to ride on.

The danger comes when you store a JWT in a **cookie** that the browser sends automatically. In that case you're exposed to CSRF again, so keep the protection on or use other defenses.

**Rule of thumb:**

- Browser app using session cookies → **keep CSRF protection on**.
- Pure API using a bearer token in a header → usually **safe to turn off**.

## Other defenses that help

- **SameSite cookies:** a cookie setting (`SameSite=Lax` or `Strict`) that tells the browser not to send the cookie on cross-site requests. Modern browsers default to `Lax`, which blocks many CSRF attacks. It is a strong extra layer, but it doesn't replace tokens.
- **Checking the `Origin` or `Referer` header:** the server verifies that the request came from your own site.
- **Re-entering the password** for very sensitive actions.

## Related concepts, in short

- **Same-origin policy:** a browser rule that stops a page from one site reading data from another site. It's why attackers can send requests but can't read the replies.
- **XSS (Cross-Site Scripting):** a different attack where the attacker gets their own script to run _inside your site_. XSS is more powerful than CSRF, because injected script can read the CSRF token and bypass the protection.
- **Session cookie:** a small piece of data the browser stores and sends back, which tells the server "this is the same logged-in user."

## Summary

CSRF abuses the fact that browsers send cookies automatically. An attacker's page makes your browser perform an action on a site where you're logged in. The defense is a secret token that only your real pages know. In Spring Security, `CsrfFilter` enforces it for you, and you can safely disable it only for stateless APIs that use header-based tokens.





[[Spring Security]]