

## Mental model: three layers of rules

When you ask "is there a standard way to design URLs?", the answer is **yes, but it's three different kinds of standard**, and mixing them up is the main source of confusion.

|Layer|Who decides|Enforced by|Analogy|
|---|---|---|---|
|**1. Syntax**: what characters and structure a URL may have|RFC 3986 (the internet standard)|Browsers, servers, libraries. Break it and things fail|**Grammar** of a language|
|**2. Platform names**: context path, servlet path, path info|Java Servlet spec + Spring|Tomcat and Spring. Break it and routing fails|**Postal system's address format** (country / city / street / number)|
|**3. Design conventions**: nouns, plurals, versioning, filtering|The REST community, industry practice|Nobody. Break it and your API still works, but it's painful to use|**Good writing style**|

Layers 1 and 2 are laws. Layer 3 is etiquette, but etiquette that every professional API follows, so breaking it makes your API feel foreign.

A good analogy for the whole URL is a **postal address**:

```
Country → City → Street → Building → Apartment → "Fragile, leave at door"
host      port   context   controller  item        query string
                 path      path
```

Each level narrows down where to go, from the broadest to the most specific. You've already learned what each Spring annotation reads; this lesson names every part and explains the rules for designing each one.

---

# Part 1: Every part of the URL, with its name

Building on the anatomy from the `URI` lesson, here is the same URL, annotated with **both** the RFC names and the Java/Spring names:

```
https://api.example.com:8443/shop/api/v1/users/5/orders?status=PAID&page=2#top
└─┬──┘ └──────┬──────┘└─┬─┘└─────────────────┬────────┘└──────┬───────┘└┬─┘
scheme       host     port        path                    query      fragment
                              
Inside the path, Java splits it further:
/shop          /api/v1/users/5/orders
└─┬──┘         └────────────┬─────────┘
context path      what Spring MVC matches
```

The full path (everything after host:port) is called the **request URI** in the servlet API, and the servlet spec defines it as:

```
requestURI = contextPath + servletPath + pathInfo
```

|Name|Example|Who owns it|Spring knob|
|---|---|---|---|
|**scheme**|`https`|the client's choice, the server's capability|`server.ssl.*`|
|**host**|`api.example.com`|DNS / deployment|not in your code|
|**port**|`8443`|server config|`server.port`|
|**context path**|`/shop`|the **application**|`server.servlet.context-path`|
|**servlet path**|`` (empty) or `/v1`|the **DispatcherServlet's** mapping|`spring.mvc.servlet.path`|
|**path info**|`/api/v1/users/5/orders`|**your controllers**|`@RequestMapping` + `@GetMapping`|
|**query string**|`status=PAID&page=2`|the **caller**|`@RequestParam`|
|**fragment**|`top`|the **browser only**|never reaches Java|

### The servlet path, which I only touched on before

Tomcat can host several servlets inside one app, each with a URL pattern. Spring Boot registers **one**, `DispatcherServlet`, mapped to `/` (everything). Because it's mapped to the default pattern, the servlet path is empty and the whole remainder is what Spring matches.

If you change it:

```properties
spring.mvc.servlet.path=/v1
```

then `DispatcherServlet` is mapped to `/v1/*`. Now `/v1` is the servlet path, and Spring MVC matches only the rest. The consequence is that **non-MVC servlets and static resources** are treated differently, which is why this setting is rarely a good idea. Prefer a controller-level prefix.

**Why three prefixes at all?** History. A Java EE server hosted many _applications_ (context path), each containing many _servlets_ (servlet path), each handling many _resources_ (path info). Spring Boot collapses this to one app and one servlet, so the first two are usually empty and everything lives in the third.

---

# Part 2: Layer 1, syntax rules (the "grammar")

These are universal and enforced. Knowing them explains many mysterious bugs.

## 2.1 Which characters are allowed

RFC 3986 sorts characters into three groups:

|Group|Characters|Meaning|
|---|---|---|
|**Unreserved**|letters, digits, `-` `.` `_` `~`|safe anywhere, no encoding needed|
|**Reserved**|`: / ? # [ ] @` and `! $ & ' ( ) * + , ; =`|have **structural meaning**; if you want them as plain data, you must encode them|
|**Everything else**|space, `"`, `<`, `>`, non-ASCII, `%` itself...|must be **percent-encoded**|

**Why reserved characters exist:** they're the URL's punctuation. `/` separates path segments, `?` starts the query, `&` separates query pairs, `#` starts the fragment. If a user's name is `Tom & Jerry`, putting it raw in a query would split it into two parameters. So it travels as `Tom%20%26%20Jerry`.

```
?name=Tom & Jerry          ← broken: parsed as name="Tom ", then " Jerry"
?name=Tom%20%26%20Jerry    ← correct: name="Tom & Jerry"
```

This is the same reason you must never build URLs by string concatenation, and why `UriComponentsBuilder` encodes for you.

## 2.2 Percent-encoding and the `+` trap

Encoding is `%` plus the byte in hex: space = `%20`, `&` = `%26`, `é` = `%C3%A9` (the **UTF-8 bytes**, because URLs are bytes, not characters).

**Edge case, space as `+`:** in the **query string** of HTML forms (`application/x-www-form-urlencoded`), `+` means space. In the **path**, `+` is a literal plus sign.

```
/search?q=spring+boot      → q = "spring boot"
/files/spring+boot         → path variable = "spring+boot"   (plus stays a plus!)
/files/spring%20boot       → path variable = "spring boot"
```

Use `%20` when you're not sure; it works in both places.

## 2.3 Case sensitivity: different per part

|Part|Case-sensitive?|
|---|---|
|scheme (`HTTPS`)|No|
|host (`Example.COM`)|No (DNS is case-insensitive)|
|**path** (`/Users` vs `/users`)|**Yes**, by the spec|
|**query** names and values|**Yes** (decided by the app)|
|hex digits in `%2f` vs `%2F`|No|

Spring's matching is case-sensitive by default, so `/API/Products` is a 404 if you mapped `/api/products`. Some servers (Windows file systems, IIS) are case-insensitive, which is exactly why you must pick one convention and keep it. The convention is **all lowercase**.

## 2.4 Segments, slashes, and the trailing-slash question

The path is a list of **segments** separated by `/`. By the spec, `/users` and `/users/` are **different URLs** (the second has an empty last segment). Older Spring treated them as the same; Spring 6 follows the spec, as you saw with `@RequestMapping`.

Two more syntax edge cases:

- **Dot segments** `.` and `..` are normalized by clients and servers: `/a/b/../c` becomes `/a/c`. This is the root of **path traversal attacks** (`/files/../../etc/passwd`), and why Spring Security's firewall rejects suspicious paths and why I warned about building file paths from user input.
- **Empty segments** `//` (as in `/users//5`) are legal but ambiguous; Spring Security rejects them by default.

## 2.5 Path parameters with `;` (matrix variables)

The `;` character in a path segment can carry parameters _specific to that segment_: `/cars;color=red;year=2020/wheels`. Spring supports reading them with `@MatrixVariable`, but **strips them by default**. Java also uses `;jsessionid=...` historically for session tracking. Practical advice: ignore them, but know that a `;` in a URL isn't random noise, and that Spring discards it for security reasons.

## 2.6 Length and the fragment

- The RFC sets **no maximum length**, but practical limits exist: browsers handle roughly 2,000 characters reliably, and Tomcat limits the whole request header block (request line included) to **8 KB** by default (`server.max-http-request-header-size`). A giant `?ids=1,2,3,...,5000` list can return **400 or 431**, which is a reason to send large data in a body.
- The **fragment** never leaves the browser, as covered. Single-page apps (Angular) use it for client-side routing in "hash mode" (`/#/products/5`) so the server never sees the route.

---

# Part 3: Layer 2, how Spring reads each part

You already know the mapping, so here is the compact consolidation, with the _design role_ of each part:

```
https://api.example.com  /shop  /api/v1  /products  /7   ?sort=price,desc&page=2
└────── "where" ──────┘   │       │        │         │     └────── "how" ───────┘
                          │       │        │         └── item identity   (@PathVariable)
                          │       │        └── resource collection       (@RequestMapping on class)
                          │       └── API namespace + version            (class prefix or addPathPrefix)
                          └── application namespace                      (context path)
```

**Rule of thumb for where a prefix belongs**, from broadest to narrowest:

|Prefix|Put it in|Because|
|---|---|---|
|Which **machine/service**|host (`api.example.com`)|DNS and the load balancer can route it before your app is involved|
|Which **application** on one server|context path|application-wide, applies to actuator and static files too|
|"This is the API" and its **version**|controller-level prefix|only REST endpoints get it|
|Which **resource**|controller `@RequestMapping`|one controller per resource|
|Which **item**|`@PathVariable`|identity|
|**Options**|`@RequestParam`|view and filter|

**Subdomain vs path for the API** (`api.example.com/products` vs `example.com/api/products`): subdomains let you scale and secure the API separately and avoid cookie sharing with the website; but they're a **different origin**, so the browser enforces **CORS** (the config you wrote for Angular). A path on the same host is same-origin and needs no CORS. Neither is wrong; it's a deployment decision.

---

# Part 4: Layer 3, REST design conventions (the "style guide")

Now the part you noticed: _conventions about how each piece should be designed_. These come from **REST** (Representational State Transfer), the architectural style in which a URL **identifies a resource** and the HTTP **method says what to do with it**.

## 4.1 The core idea: URLs are nouns, methods are verbs

> **A URL names a _thing_. The HTTP method is the _action_.**

Analogy: a library catalogue. The shelf location "Section C, shelf 4" is the _address of the book_ (URL). "Borrow", "return", "reserve" are _actions_ (methods). You don't have a different shelf location for each action.

```
❌ GET    /getAllUsers
❌ POST   /createUser
❌ POST   /deleteUser?id=5
❌ GET    /user/delete/5          ← worse: GET must never change data

✅ GET    /users
✅ POST   /users
✅ DELETE /users/5
```

**Why it works this way:** HTTP already has a small, universal vocabulary of verbs with **guaranteed semantics**. If your URL also contains the verb, you duplicate that vocabulary badly and every client must learn your private dialect.

## 4.2 Method semantics: why the verb choice isn't cosmetic

|Method|Safe? (no side effects)|Idempotent? (N calls = 1 call)|Cacheable?|Body|
|---|---|---|---|---|
|GET|✅|✅|✅|no|
|HEAD|✅|✅|✅|no|
|PUT|❌|✅|❌|yes|
|DELETE|❌|✅|❌|usually no|
|POST|❌|❌|rarely|yes|
|PATCH|❌|not guaranteed|❌|yes|

**Why this matters for URL design:** infrastructure _relies_ on these guarantees. Browsers prefetch GET links; crawlers follow them; proxies cache them; clients and gateways **auto-retry** idempotent calls. If you design `GET /orders/5/cancel`, then a search-engine crawler or a browser's link preview can **cancel orders**. This is a real, classic production incident. The URL design rule "never change state with GET" is a safety rule, not a style preference.

## 4.3 Collection vs item

```
/products         ← the COLLECTION  (GET list, POST create)
/products/7       ← one ITEM        (GET, PUT, PATCH, DELETE)
```

This two-URL pattern covers all of CRUD, which is exactly the table from the first lesson.

**Plural nouns:** `/products`, not `/product`. Reason: the collection is the primary concept, and the item is "one element of the collection", so `/products/7` reads naturally as "product 7 of products". Consistency matters more than the choice: don't mix `/user` and `/orders`.

## 4.4 Hierarchy means ownership (and how deep to go)

```
/users/5/orders          ← orders that BELONG to user 5
/users/5/orders/42       ← order 42 of user 5
```

Read left to right as "contains": it's the same as a filesystem path. This is the **sub-resource** pattern from the `OrderController` example.

**The depth rule:** go at most **2 levels** of nesting. Beyond that, URLs get long and fragile:

```
❌ /users/5/orders/42/items/3/product/reviews
✅ /order-items/3         (if item ids are globally unique)
✅ /reviews?productId=9   (flatten, filter with a query)
```

**An honest refinement of my earlier example:** if `orderId` is globally unique (the usual case with a database sequence or UUID), then `/users/5/orders/42` contains **redundant** information (`5`). It's still valuable as an _ownership check_ (`order 42 must belong to user 5`, which helps against the IDOR problem), but the alternative `/orders/42` plus an authorization check is equally valid. The nested form is best when the child's identity is **only meaningful within the parent** (e.g. `/orders/42/items/1`, where item numbers restart per order).

## 4.4b Path or query? Revisit with this lens

You already have the rule "identity in the path, options in the query". The design reasoning behind it:

- Path segments form a **hierarchy** → natural for containment.
- Query parameters form an **unordered set of optional modifiers** → natural for filtering.
- The path is the part caches, proxies, and bookmarks treat as "the resource's name".

## 4.5 Naming style

|Rule|Good|Bad|Why|
|---|---|---|---|
|Lowercase|`/order-items`|`/OrderItems`|paths are case-sensitive, lowercase avoids mismatches|
|Hyphens between words|`/order-items`|`/order_items`|hyphens are the readable, search-engine-friendly word separator; underscores disappear when a link is underlined|
|No file extensions|`/users/5`|`/users/5.json`|format is negotiated with `Accept`, not baked into the name (content negotiation again)|
|No verbs|`/users`|`/getUsers`|method is the verb|
|No trailing slash|`/users`|`/users/`|they're different URLs, so pick one|
|No technology|`/users`|`/UserServlet.do`|implementation details leak and age badly|
|Stable, opaque IDs|`/users/9f1c…`|`/users/by-row/17`|clients must not depend on internals|

**Query parameter names** have no single standard, so pick **one** style and keep it everywhere: `camelCase` (`pageSize`) to match your JSON, or `snake_case`. Don't mix.

## 4.6 Query parameter conventions

These patterns are so common that **Spring Data follows them by default**, so the conventions pay off directly:

|Purpose|Convention|Example|
|---|---|---|
|Filter|field name = value|`?status=PAID&role=admin`|
|Paging|`page`, `size` (Spring Data: 0-based)|`?page=0&size=20`|
|Sorting|`sort=field,direction` (repeatable)|`?sort=price,desc&sort=name,asc`|
|Search text|`q`|`?q=mechanical+keyboard`|
|Range|`from`/`to` or `minPrice`/`maxPrice`|`?from=2026-09-01&to=2026-09-30`|
|Field selection|`fields=`|`?fields=id,name`|
|Include related|`include=` / `expand=`|`?expand=orders`|
|Multiple values|repeat the key or comma-separate|`?ids=1&ids=2` / `?ids=1,2`|

**Pagination edge case:** `page`/`size` (offset paging) gets slow and inconsistent on huge, changing tables, because inserted rows shift pages, and `OFFSET 1000000` is expensive. Large feeds use **cursor/keyset paging** (`?after=<opaque-token>&limit=20`). Know the first now; the second when your data grows.

## 4.7 The hard part: actions that aren't CRUD

Not everything is "create/read/update/delete a noun". What about "cancel an order", "send an email", "reset a password", "publish a post"? Four accepted strategies, from best to most pragmatic:

**1. Model it as a state change** (PATCH the field):

```
PATCH /orders/42        {"status": "CANCELLED"}
```

Best when the action is just a field transition and the rules are simple.

**2. Model the action as a sub-resource you create** (a noun!):

```
POST /orders/42/cancellation       → 201, creates a "cancellation" record
POST /users/5/password-resets      → creates a password reset request
```

Best when the action has its own data, history, or can be queried later ("show me the cancellation reason").

**3. A verb sub-resource ("controller resource")**, the pragmatic escape hatch:

```
POST /orders/42/cancel
POST /emails/send
```

Widely used (GitHub, Stripe) when it's clearer than contortions. Rules: **always POST** (never GET), and place the verb at the **end** of the path.

**4. A processing endpoint for computations** that don't map to a stored resource: `POST /prices/calculate`.

**Why this matters:** a pure-noun purist and a pragmatist both have a point. Contorting the model to avoid a verb helps nobody; but sprinkling verbs everywhere destroys the uniform interface. Default to 1 or 2, use 3 when it genuinely reads better.

## 4.8 Singletons and the current user

Some resources have exactly one instance per context:

```
/users/5/profile      ← each user has one profile (singular noun, no id)
/me                   ← "the currently authenticated user"
/me/orders            ← my orders
```

**Why `/me` is a design win beyond convenience:** it removes the user ID from the URL entirely, so a client _cannot_ ask for someone else's data by editing a number. It's a structural defense against the IDOR problem from earlier, since the identity comes from the **authentication token**, not from the URL.

## 4.9 Many-to-many and bulk

```
PUT    /students/5/courses/9       ← enroll student 5 in course 9 (idempotent: doing it twice = same state)
DELETE /students/5/courses/9       ← unenroll
GET    /courses/9/students         ← the same relationship from the other side
```

Bulk operations don't have a single standard. Common choices: `POST /products/batch` with an array body, or `DELETE /products?ids=1,2,3` for small lists. Decide how **partial failure** is reported (207 Multi-Status, or a per-item result array), because "3 of 5 succeeded" doesn't fit a single status code.

## 4.10 Versioning: where the version lives

|Strategy|Example|Pros|Cons|
|---|---|---|---|
|**URI path**|`/api/v1/products`|visible, simple, easy to route and cache, testable in a browser|"version" isn't really part of a resource's identity (purists object)|
|**Header**|`X-API-VERSION: 2` (via `headers =`)|URLs stay clean|invisible, harder to test and share|
|**Media type**|`Accept: application/vnd.shop.v2+json` (via `produces =`)|most "RESTful"|complex for clients|
|**Query param**|`/products?version=2`|trivial|easily forgotten, muddles caching|

Industry default: **URI path versioning** (`/v1`), because simplicity wins. You've already seen the first three work with `path`, `headers`, and `produces`, which is why those attributes exist.

**Version only on breaking changes** (removing or renaming a field, changing meaning). Adding a field is non-breaking, so no new version. And a version applies to the **whole API surface**, not per endpoint, otherwise clients juggle `/v1/users` with `/v3/orders`.

## 4.11 IDs in URLs

|Choice|Pros|Cons|
|---|---|---|
|Sequential (`1, 2, 3`)|short, human-friendly, index-friendly|**guessable**: anyone can enumerate `/users/1`, `/users/2`... and reveals business size|
|UUID|unguessable, can be generated by the client, merge-friendly|long, slightly slower indexes|
|Slug (`/articles/spring-boot-intro`)|readable, SEO-friendly|must be unique and handle renames|

**Key rule:** an unguessable ID is **not** authorization. A UUID makes enumeration hard, but you still must check that the caller may see that resource.

---

# Part 5: Putting it together, bad vs good

```
❌ BAD
GET  http://example.com/App/API/getUserOrders.php?UserID=5&Status=paid&PageNumber=1
POST http://example.com/App/API/CancelOrder?id=42
GET  http://example.com/App/API/deleteUser/5

✅ GOOD
GET    https://api.example.com/v1/users/5/orders?status=PAID&page=0&size=20
POST   https://api.example.com/v1/orders/42/cancellation
DELETE https://api.example.com/v1/users/5
```

Defects in the bad version, each now a named rule: mixed case (4.5), file extension and technology leakage (4.5), verbs in URLs (4.1), `UserID` exposed as a query for identity (4.4b), GET that deletes (4.2), inconsistent parameter naming (4.5), no version (4.10).

A well-designed controller then follows naturally:

```java
@RestController
@RequestMapping("/api/v1/users/{userId}/orders")       // namespace + version + parent
public class OrderController {

    @GetMapping                                        // collection: filter + page via query
    public Page<OrderResponse> list(@PathVariable Long userId,
                                    @RequestParam(required = false) OrderStatus status,
                                    Pageable pageable) { ... }   // reads ?page=&size=&sort=

    @PostMapping("/{orderId}/cancellation")            // action as a noun sub-resource
    @ResponseStatus(HttpStatus.CREATED)
    public CancellationResponse cancel(@PathVariable Long userId,
                                       @PathVariable Long orderId) { ... }
}
```

Note `Pageable`: with Spring Data on the classpath, that single parameter automatically binds the `page`, `size`, and `sort=field,dir` conventions from 4.6. That is the payoff of following the community convention.

---

# Part 6: Edge cases and gotchas

**1. A URL is not an API; it's a contract.** Once published, clients bake your URLs into their code. Renaming `/users` to `/members` is a breaking change. Design URLs as if you can't change them, because you can't, cheaply.

**2. Sensitive data never goes in a URL.** Whole URLs (path **and** query) are written to access logs, proxy logs, browser history, and the `Referer` header sent to other sites. Tokens, passwords, and personal data belong in headers or the body.

**3. `404` vs `405` vs `400` tells the client what's wrong with the URL**: nothing at that path (404), path exists but wrong verb (405), path matched but a required query or header is missing (400). A deliberate design choice: return **404 instead of 403** when revealing existence of a resource would itself leak information.

**4. Encoded slashes.** `%2F` inside a segment is rejected by default by Tomcat and Spring Security, because it can disguise path traversal. If an ID can contain `/` (such as a file path), put it in the **query** or **body**, or use `{*path}` deliberately.

**5. Internationalized URLs.** Non-ASCII characters (`/produkte/straße`) travel as percent-encoded UTF-8 bytes. Hostnames use a separate scheme (IDN / punycode). Keep API paths ASCII; keep unicode in query values and bodies.

**6. Redirects and `Location`.** After POST, the `Location` header holds the new resource's URL, and that URL is the **canonical name**. This ties directly to `URI` and `ResponseEntity.created(...)`. Always build it with the builders so context path, scheme, and proxy prefix are right.

**7. Caching works on the _whole_ URL, query string included.** `/products?page=1&sort=name` and `/products?sort=name&page=1` are **different cache keys** even though they mean the same. Be consistent about parameter order on the client where caching matters.

**8. Don't put the HTTP method in a query** (`?_method=DELETE`) unless a legacy client (an HTML form can only do GET/POST) forces you; Spring offers `HiddenHttpMethodFilter` for that case.

**9. Reverse proxies can rewrite URLs.** The URL the client typed and the one your app sees can differ (stripped prefix, changed host). `X-Forwarded-*` headers carry the original, and URL builders use them if `server.forward-headers-strategy` is set. Hardcoded absolute URLs break here.

**10. Consistency beats cleverness.** An imperfect but uniform design (always plural, always `page`/`size`, always the same error shape) is far more usable than a "pure" design with exceptions. If you're unsure, copy a well-documented API (GitHub, Stripe) and keep your own consistent.

---

# Quick reference: the checklist

|#|Rule|Layer|
|---|---|---|
|1|Encode reserved/unsafe characters; build with `UriComponentsBuilder`|syntax|
|2|Paths are case-sensitive: use lowercase|syntax|
|3|No trailing slash; `/a` ≠ `/a/`|syntax|
|4|Context path = app prefix, set in config, never in `@RequestMapping`|platform|
|5|URL = noun, HTTP method = verb|convention|
|6|Plural collection, `/{id}` for an item|convention|
|7|Nest for ownership, max 2 levels deep|convention|
|8|Filter, sort, page, search → query params|convention|
|9|Never change state with GET|convention (safety)|
|10|Non-CRUD actions → state change, noun sub-resource, or `POST .../verb`|convention|
|11|Version in the path (`/v1`), only on breaking changes|convention|
|12|`/me` for the current user|convention (security)|
|13|No secrets, no technology, no extensions in URLs|convention (security)|
|14|One naming style, everywhere|convention|

## How it connects to everything so far

```
URL design  ──► decides WHAT you write in @RequestMapping / @GetMapping (paths, nesting)
            ──► decides WHICH data channel: @PathVariable vs @RequestParam
            ──► decides the verb mapping and status codes (@ResponseStatus, ResponseEntity)
            ──► decides the Location header you build with URI
            ──► decides package/controller boundaries (one controller per resource)
            ──► sits under the context path and next to CORS config
```




[[Spring Framework]]