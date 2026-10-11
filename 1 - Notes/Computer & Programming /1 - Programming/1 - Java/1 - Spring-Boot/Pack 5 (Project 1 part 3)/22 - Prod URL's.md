
# Why those URLs carry long query strings

## Short answer

Everything after the `?` in both URLs is **tracking data added by Google**, not part of the page address. The real URLs are:

```
https://sdbullion.com/
https://sdbullion.com/customer/account/login/
```

The site would show the same pages without the extra parts. They exist so Google's systems can measure where you came from and tie your visits together.

## Mental model: a luggage tag

Imagine you arrive at a hotel with a **luggage tag** stapled to your suitcase. The tag doesn't change what's inside the suitcase, but it tells the hotel which airline you came with and which trip you're on. The hotel (website) doesn't need the tag to give you a room (the page). The airline and the hotel's accounting department use it to link things together.

Query parameters added by third parties are luggage tags on URLs.

## Parameter 1: `srsltid` (on the main page)

```
https://sdbullion.com/?srsltid=AU7gw4XC...
```

- **Name:** "Search Result ID", added by Google.
- **When:** you clicked the site from a Google result, usually a product or shopping listing (Merchant Center "auto-tagging").
- **Purpose:** the site's analytics can attribute the visit to "organic Google listing" and to the specific listing you clicked.
- **Value:** an opaque token. Only Google can interpret it.

## Parameter 2: `_gl` (on the login page)

```
?_gl=1*1g90k5z*_up*MQ..*_ga*MTMzNzAyOTY3MS4xNzkxMDA4NTI4*_ga_DWEH7P4F4K*czE3OTEw...
```

This is Google Analytics' **cross-domain linker**. It is built from `*`-separated pieces, each a key followed by a value:

|Piece|Meaning|
|---|---|
|`1`|linker format version|
|`1g90k5z`|checksum/fingerprint, so GA can detect a tampered or stale value|
|`_up` / `MQ..`|user-property data (`MQ` is base64 for `1`, and `..` replaces the `==` padding)|
|`_ga` / `MTMz...`|your **client ID**, base64-encoded|
|`_ga_DWEH7P4F4K` / `czE3...`|session data for the GA4 property whose measurement ID is `DWEH7P4F4K`|

You can decode these yourself in your Debian terminal, because it's your own data:

```bash
echo 'MTMzNzAyOTY3MS4xNzkxMDA4NTI4' | base64 -d
# 1337029671.1791008528
#   └ random ID   └ Unix timestamp of your first visit (early Oct 2026)

echo 'czE3OTEwMDg1MjckbzEkZzAkdDE3OTEwMDg1MjckajYwJGwwJGgyNzU2NTY0ODQ=' | base64 -d
# s1791008527$o1$g0$t1791008527$j60$l0$h275656484
#  s = session start, o1 = your 1st session, t = timestamp ...
```

So the URL literally carries "this is visitor 1337029671, and this is their first session".

### Why a URL, and not just a cookie?

Cookies belong to **one domain**. If you move from `shop.com` to `checkout-provider.com`, the second domain can't read the first one's `_ga` cookie, so analytics would see **two different people**. The fix is to pass the identity **inside the link**, since the URL travels with you. The destination reads `_gl`, adopts the same client ID, and the sessions are stitched together.

Here the login page is on the same host, so it's a bit unusual. Likely reasons are that the site's tag setup applies the linker to every link, or that it treats several domains or subdomains as one property, so it tags links by default. I can't see their configuration, so treat that as the probable explanation, not a certainty.

## Why they're in the query string, not the path

This ties straight back to the previous lesson:

- The **path** is the resource's identity: `/customer/account/login/` is _the login page_.
- The **query** is "optional modifiers that don't change identity". Tracking data fits that exactly, which is why trackers always use it. Putting it in the path would change _which resource_ you asked for and break routing.
- The **fragment** (`#...`) would also work technically, but it never reaches the server, so server-side tools couldn't read it.

## How the server treats them: it ignores them

Nothing in the site's routing reads `srsltid` or `_gl`. Only JavaScript in the browser (the Google tag) does. In Spring terms:

```java
@GetMapping("/customer/account/login")
public String login() { ... }
```

A request to `/customer/account/login?_gl=...&srsltid=...` still matches. Spring only reads query parameters you ask for with `@RequestParam`, and **unknown ones are silently ignored**. They only block a match if you wrote a `params = "..."` condition that they don't satisfy.

## The other thing you noticed: `/customer/account/login/`

This looks like **Magento** (an e-commerce platform), though I'm inferring that from the pattern. Its URL scheme is:

```
/customer / account / login /
 module     controller  action
```

That's a different design philosophy from the REST rules I taught. It's a **server-rendered website** (HTML pages for humans), not a **JSON API** (for programs):

||REST API (what you're building)|Classic website (Magento)|
|---|---|---|
|URL names|nouns, the method is the verb|module/controller/**action** (`login`)|
|Trailing slash|avoid it|normal; the platform canonicalizes with it|
|Consumer|Angular, mobile apps|browsers, search engines|

So the earlier rules aren't violated here; they simply target a different kind of system. Both are internally consistent.

## Consequences of this design

**1. The same page has many URLs.** `/` and `/?srsltid=AAA` and `/?srsltid=BBB` are different URLs for identical content. Cache layers (CDN, proxy) key on the **whole URL, query included**, so each variant can miss the cache. This is the cache-key gotcha from the last lesson in real life. Sites reduce the damage by configuring the CDN to ignore known tracking parameters, and by adding `<link rel="canonical" href="https://sdbullion.com/">` so search engines treat all variants as one page.

**2. Privacy.** `_gl` contains a persistent client ID. If you copy and share that URL, you also share an identifier that links your visit to your browsing profile. When sending someone a link, delete everything from the `?` onward.

**3. Messy sharing and bookmarks.** Many browsers and apps now strip known tracking parameters automatically. Firefox has this in its strict tracking protection, which is relevant on your Debian setup.

## Nuances and edge cases

**1. The parameters change your URLs but not your server logic, until you accidentally depend on them.** If you ever build a site with Spring and add a `params =` condition or a strict query-validation filter, a surprise `?_gl=` can cause 400s. Be lenient: ignore what you don't recognize.

**2. `_gl` has a short lifetime.** The checksum and timestamp mean the receiving page accepts it only for a limited window (a couple of minutes), which prevents old shared links from re-attributing a stranger to your session.

**3. It adds length.** Together these parameters add around 200 characters. Not a problem, but it shows how tracking can eat into the practical URL-length budget I mentioned (browsers about 2,000, Tomcat's header limit 8 KB).

**4. Other well-known examples of the same pattern** (you'll see them everywhere): `utm_source`, `utm_medium`, `utm_campaign` (campaign tags), `gclid` (Google Ads click ID), `fbclid` (Facebook), `msclkid` (Microsoft Ads). All are third-party tags in the query string that the origin server ignores.

**5. In your own Spring apps:** if you use Spring Security, redirects after login (`?continue=` or `?redirect=`) are a related query-string pattern, but those **are** read by the server, and they must be validated to prevent open-redirect attacks. Tracking parameters are harmless; functional parameters need scrutiny.

## Quick reference

|Part|Who adds it|Who reads it|Affects the page?|
|---|---|---|---|
|`/customer/account/login/`|the site (Magento routing)|the server|yes, it _is_ the page|
|`?srsltid=...`|Google Search|Google Analytics / merchant tools|no|
|`?_gl=...`|Google tag (browser JavaScript)|Google tag on the next page|no|





[[Spring Framework]]
[[Networking]]