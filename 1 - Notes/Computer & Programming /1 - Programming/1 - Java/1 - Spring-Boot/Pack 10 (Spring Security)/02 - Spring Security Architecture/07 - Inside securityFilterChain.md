

# Inside `securityFilterChain`: Your Security Building Blocks, Explained

 You've already got the core idea of `authorizeHttpRequests`. Now let's open up the whole method and look at every part of it. I checked the current Spring Security reference (the version Spring Boot 4 uses) so the examples match what the official docs show.

Here's the map for this lesson:

```
securityFilterChain(HttpSecurity http)        ← the method you write
 │
 ├── 1. The HttpSecurity builder     (the tool you configure with)
 ├── 2. Customizer lambdas           (how every setting is written)
 ├── 3. securityMatcher              (which requests this chain handles)
 ├── 4. authorizeHttpRequests        (who may access what)
 ├── 5. Protection: csrf, cors, headers
 ├── 6. Sessions: sessionManagement
 ├── 7. Ways to log in: formLogin, httpBasic, oauth2Login, oauth2ResourceServer
 ├── 8. Leaving and errors: logout, exceptionHandling
 └── 9. http.build()                 (turns your settings into a real chain)
```

---

## Part 1: The Foundations

### 1.1 What a `SecurityFilterChain` is

**Definition:** A `SecurityFilterChain` is an ordered list of filters. Every incoming HTTP request passes through these filters one by one before it reaches your controller.

**Why it exists:** A web request has to be checked for many things: Is the user logged in? Is the form token valid? Is the request from an allowed website? Is the session still active? Spring Security handles each of these with a separate filter, and the chain is the line those filters stand in.

**What problem it solves:** Without a chain, each controller would need to check everything itself. You'd write the same login check in 40 methods, and one forgotten check would leave a hole.

**How it works:**

```
Request → [filter 1: session] → [filter 2: CSRF check] → [filter 3: login check]
        → [filter 4: authorization rules] → Your @RestController
```

If any filter says "no," the chain stops the request and sends back an error (401 or 403). If all filters pass, your controller runs.

**How you'll use it:** You rarely build the filters yourself. Instead, you use `HttpSecurity` to turn filters on, off, or configure them. That's what the method body is for.

### 1.2 The `HttpSecurity` parameter

**Definition:** `HttpSecurity` is a builder object. Spring gives it to your method, and you call methods on it to describe the chain you want.

**Why it exists:** There are dozens of filters, and each one has settings. A builder lets you describe them in a readable way without writing filter code by hand.

**How it works:** Each method on `HttpSecurity` configures one part of the chain and returns the same builder, so you can keep chaining. Then `http.build()` produces the final chain.

```java
http.authorizeHttpRequests(...)  // configures access rules
    .csrf(...)                   // configures CSRF protection
    .formLogin(...);             // configures a login form
```

Note: In Spring Security 7 (used by Boot 4), the lambda style is the standard. Each method takes a lambda, and the old `.and()` chaining is no longer used. Spring's official docs now show every example in this style, so we'll use it too.

### 1.3 The `Customizer` lambda: the pattern you'll see everywhere

**Definition:** Most configuration methods take a `Customizer`, which is a lambda that receives a configuration object and lets you set options on it.

```java
http.csrf(csrf -> csrf.disable());
//        ↑      ↑
//        |      └── the object you configure (a CsrfConfigurer)
//        └── the lambda parameter name you choose
```

**Why it exists:** Each feature has its own options. A lambda gives you a fresh, scoped object for each feature, so the options for `csrf` never mix up with the options for `formLogin`.

**The shortcut:** When you want the default settings, you don't need a lambda at all:

```java
import org.springframework.security.config.Customizer;

http.formLogin(Customizer.withDefaults());  // same as formLogin(form -> {})
```

**How you'll use it:** Read each lambda parameter as "the settings for this one feature." Pick short, clear names like `authorize`, `csrf`, `session`, `form`.

### 1.4 `securityMatcher`: which requests does this chain handle?

**Definition:** `securityMatcher` tells the chain which URLs it applies to. Requests that don't match skip this chain entirely.

**Why it exists:** Real apps often have different kinds of traffic. A JSON API and a website with login pages need different security. Without `securityMatcher`, a single chain would have to handle both, and the settings would conflict.

**Problem it solves:** It lets you run several chains side by side, each for a different group of URLs.

**Code:**

```java
http.securityMatcher("/api/**")
    // this chain only handles requests under /api/
```

**Important rule:** If you define more than one `SecurityFilterChain` bean, Spring checks them in order. Use `@Order` to decide which one is checked first. A chain with no `securityMatcher` matches everything, so it should come last.

### 1.5 `http.build()`: the final step

**Definition:** `build()` takes all your settings and produces the real filter chain object.

```java
return http.build();   // turns your settings into a SecurityFilterChain
```

**Why it's needed:** Until `build()` runs, nothing is active. Your settings are just a plan. `build()` makes the plan real.

**What happens if you don't define a chain at all?** Spring Boot creates a default one. It protects every URL with a login, which is why a new Spring Boot app asks for a password, and that password is printed in the console at startup. Your bean replaces this default.

---

## Part 2: Access Rules with `authorizeHttpRequests`

You already know the basic shape. Now let's look at all the decisions and matchers.

### 2.1 The rule list works like a waiting line

**Definition:** Inside `authorizeHttpRequests`, you write a list of rules. Each rule has a _matcher_ (which requests) and a _decision_ (what access is needed).

**How it works:** Spring checks rules from top to bottom. The first rule whose matcher fits the request wins, and the rest are ignored.

**Why order matters:** Put general rules at the bottom and specific rules at the top. Suppose you wrote this:

```java
.authorizeHttpRequests(authorize -> authorize
    .anyRequest().authenticated()                    // matches everything
    .requestMatchers("/api/products/**").permitAll() // never reached!
)
```

Spring rejects this at startup, because the second rule could never run. The catch-all `anyRequest()` must be last.

### 2.2 Matchers: how you describe the requests

|Matcher|What it matches|Example|
|---|---|---|
|`requestMatchers("/path")`|One exact path|`"/login"`|
|`requestMatchers("/path/**")`|The path and everything below it|`"/api/orders/**"`|
|`requestMatchers(HttpMethod.GET, "/path")`|Only that HTTP method|`GET /api/products`|
|`requestMatchers("/users/*/profile")`|`*` matches exactly one segment|`/users/42/profile`|
|`anyRequest()`|Every request|(catch-all)|

Many paths can be listed in one call:

```java
.requestMatchers("/", "/css/**", "/js/**", "/login").permitAll()
```

### 2.3 Decisions: what the requester must be

|Decision|Meaning|Typical use|
|---|---|---|
|`permitAll()`|Anyone, logged in or not|Home page, public catalog|
|`denyAll()`|Nobody|Blocking an endpoint for now|
|`authenticated()`|Any logged-in user|Personal data|
|`hasRole("ADMIN")`|Has `ROLE_ADMIN`|Admin-only actions|
|`hasAnyRole("USER", "ADMIN")`|Has at least one role|Shared features|
|`hasAuthority("REPORT_READ")`|Has this exact string|Fine-grained permissions|
|`access(customManager)`|Your own logic|Complex rules|

**Role versus authority:** `hasRole("ADMIN")` checks for `ROLE_ADMIN` behind the scenes. Spring adds the `ROLE_` prefix for you. `hasAuthority` checks the exact string. If you use `hasAuthority("ROLE_ADMIN")`, you must write the prefix yourself.

### 2.4 Why `permitAll` and `denyAll` both exist

**Why:** They express the two ends of your policy. A strong habit is "deny by default": end with `.anyRequest().denyAll()` and then explicitly open each endpoint. A new endpoint stays locked until you decide to open it.

```java
.authorizeHttpRequests(authorize -> authorize
    .requestMatchers("/api/products/**").permitAll()
    .requestMatchers("/api/orders/**").authenticated()
    .anyRequest().denyAll()          // anything else is refused
)
```

### 2.5 Advanced: `shouldFilterAllDispatcherTypes`

The official docs mention a setting for a less common case: forwards and includes inside the server. By default, Spring checks authorization on the first request only. Turning this on checks it on every dispatch:

```java
.authorizeHttpRequests(authorize -> authorize
    .shouldFilterAllDispatcherTypes(true)
    .anyRequest().authenticated()
)
```

You won't need this in most beginner apps. It's good to know it exists for when you're debugging forwards.

---

## Part 3: Protection Features

### 3.1 CSRF: `csrf`

**Definition:** CSRF means _Cross-Site Request Forgery_. It's an attack where a malicious website tricks your browser into sending a request to your site, using the login cookie your browser already holds.

**Why it exists:** Browsers automatically attach cookies to requests going to a site. So if you're logged into your bank, a malicious page could make your browser send a "transfer money" request. CSRF protection requires each form submission to include a secret token the malicious page can't know.

**How it works:**

```java
.csrf(csrf -> csrf.disable())   // turn it off
```

**When to disable it:** Only when your API doesn't use cookies for login. A typical REST API that sends a JWT in the `Authorization` header is not vulnerable to this attack, so disabling CSRF there is normal and correct. A website with a login form and session cookies should keep CSRF on.

### 3.2 CORS: `cors`

**Definition:** CORS (_Cross-Origin Resource Sharing_) is the browser rule that blocks a web page on one domain from calling an API on another domain, unless the API says that's allowed.

**Why it exists:** Without this rule, any website could call your bank's API using your cookies. CORS is the browser's safety rule, and the server opts in to specific domains.

**How it works:** Spring reads CORS settings from a `CorsConfigurationSource` bean. The `cors` method turns that support on inside the chain:

```java
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("https://my-frontend.com"));
    config.setAllowedMethods(List.of("GET", "POST", "DELETE"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type"));

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}

// inside securityFilterChain:
http.cors(Customizer.withDefaults());  // uses the CorsConfigurationSource bean above
```

**Why this matters for you:** Your Angular front-end (which you're learning) will run on its own address during development. Without a CORS setup, the browser will block its calls to Spring Boot.

### 3.3 Security headers: `headers`

**Definition:** Security headers are extra instructions your server sends with each response, telling the browser how to behave safely.

**Why it exists:** Browsers support several safety features that only work if the server asks for them. Spring turns many of these on by default.

**Common example:** Blocking your page from being shown inside someone else's frame (clickjacking):

```java
.headers(headers -> headers
    .frameOptions(frame -> frame.sameOrigin())   // only same-site framing allowed
)
```

**How you'll use it:** Usually you leave the defaults alone. Change them only when you have a clear reason, such as embedding a page in an iframe on the same site.

---

## Part 4: Sessions

### 4.1 `sessionManagement`

**Definition:** A session is the server's memory of a logged-in user between requests. The server creates a session ID, stores it in a cookie, and uses it to recognize the user on the next click.

**Why it exists:** HTTP has no memory. Each request is independent. Sessions give the server a way to remember "this is the same user who logged in two minutes ago."

**The trade-off:** Sessions live on the server, so a server holds memory for each logged-in user. A _stateless_ setup skips sessions entirely: every request must carry proof of identity, usually a JWT.

```java
import org.springframework.security.config.http.SessionCreationPolicy;

.sessionManagement(session -> session
    .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
)
```

The policy options:

|Policy|Meaning|Use for|
|---|---|---|
|`IF_REQUIRED` (default)|Create a session only when needed|Normal websites|
|`STATELESS`|Never create or use sessions|JWT-based REST APIs|
|`ALWAYS`|Always create a session|Rare cases|
|`NEVER`|Don't create one, but use one if it exists|Rare cases|

**Why it matters with CSRF:** Stateless APIs usually disable CSRF too, because there's no session cookie to abuse. Sessions and CSRF go together.

---

## Part 5: Ways to Prove Who You Are

These features are how users log in. Pick the one that fits your app. Most apps use one or two.

### 5.1 `formLogin`: a login page for browsers

**Definition:** Form login shows an HTML login page. The user types a username and password, and Spring checks them.

**Why it exists:** Websites need a way to collect credentials from humans. Form login is the classic answer.

**How it works:** When a user visits a protected page without logging in, Spring redirects them to the login page. After a successful login, it creates a session and sends them back.

```java
.formLogin(form -> form
    .loginPage("/login")                       // your own login page
    .defaultSuccessUrl("/dashboard", true)     // where to go after login
    .permitAll()                               // the login page itself must be public
)
```

**When to use it:** A server-rendered site (Thymeleaf pages, for example). Don't use it for a pure JSON API, since the browser redirect makes no sense there.

### 5.2 `httpBasic`: username and password in each request

**Definition:** HTTP Basic sends the username and password in the `Authorization` header on every request, encoded in Base64.

**Why it exists:** It's the simplest possible login mechanism. Tools like `curl` and Postman can use it without a login page.

```java
.httpBasic(Customizer.withDefaults())
```

**Important:** Base64 is encoding, not encryption. Anyone who sees the request can decode the password. Always use HTTPS in production. Use Basic mainly for testing and internal tools.

### 5.3 `oauth2ResourceServer`: accepting tokens from another system

**Definition:** A resource server is your API, which trusts tokens (usually JWTs) issued by an external authorization server such as Keycloak, Auth0, or Google.

**Why it exists:** In larger systems, you don't want every app managing its own passwords. A central server handles login and hands out signed tokens. Your API checks the signature and accepts the request if it's valid.

**How it works:** The client sends `Authorization: Bearer <token>`. Spring checks the token's signature against the issuer's public keys and reads its claims.

```java
.oauth2ResourceServer(oauth2 -> oauth2
    .jwt(Customizer.withDefaults())
)
```

The issuer address goes in your `application.properties`:

```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://my-auth-server.com/realms/demo
```

Spring then fetches the public keys automatically. This is the setup you'll most likely use for a Spring Boot API that serves an Angular front-end.

### 5.4 `oauth2Login`: "Sign in with Google" style login

**Definition:** An OAuth2 client is your app acting as a client of an external provider. `oauth2Login` lets users sign in through that provider, such as Google or GitHub, and then your app creates its own logged-in session.

**Why it exists:** Users don't have to create a new password for your app. Also, you don't have to store passwords.

```java
// Needs the spring-boot-starter-oauth2-client dependency
.oauth2Login(Customizer.withDefaults())
```

**How you'll use it:** Provider details go in `application.properties`:

```properties
spring.security.oauth2.client.registration.google.client-id=YOUR_ID
spring.security.oauth2.client.registration.google.client-secret=YOUR_SECRET
```

**The difference from the resource server:** `oauth2Login` is for users who click a login button in a browser. `oauth2ResourceServer` is for API clients who already hold a token.

---

## Part 6: Leaving and Handling Errors

### 6.1 `logout`

**Definition:** Logout ends the user's session and clears their login.

**Why it exists:** Logging out should delete server-side state. Otherwise, someone using a shared computer could return to your site and still be logged in.

```java
.logout(logout -> logout
    .logoutUrl("/logout")         // the URL that triggers logout
    .logoutSuccessUrl("/")        // where to send the user afterward
)
```

### 6.2 `exceptionHandling`

**Definition:** Exception handling decides what happens when a security check fails.

**Why it exists:** By default, a browser user who gets blocked is redirected to a login page, while an API client gets a bare error. Sometimes you want a custom response, such as JSON with a clear message.

```java
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.http.HttpStatus;

.exceptionHandling(ex -> ex
    .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
)
```

This means: "If the user isn't logged in, respond with plain 401 and no redirect." That's what most REST APIs want.

---

## Part 7: Real Scenarios

Here's how the pieces fit together in real apps. Read each scenario, ask "why these choices?", then compare with the alternatives.

### Scenario A: A public product API for a mobile app

**Situation:** Anyone can browse products. Only logged-in customers can place orders. Admins can add products.

**Why these choices:**

- The app is an API with JWT tokens, so it's stateless and CSRF is off.
- Browsing is public, so `GET` requests are `permitAll`.
- Orders need a login, so they're `authenticated`.
- Only admins create products, so `POST` is `hasRole("ADMIN")`.

```java
@Bean
public SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(authorize -> authorize
            .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
            .requestMatchers(HttpMethod.POST, "/api/products/**").hasRole("ADMIN")
            .requestMatchers("/api/orders/**").authenticated()
            .anyRequest().denyAll())
        .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));
    return http.build();
}
```

**What we could use instead:** If your app had no mobile clients and no JWT provider, you could use `httpBasic` for simple testing. For a real product, JWT is the usual choice.

### Scenario B: A server-rendered admin dashboard

**Situation:** Staff log in through a web page. The site uses Thymeleaf templates.

**Why these choices:**

- Browsers need a login page, so `formLogin`.
- Sessions are normal here, so the default session policy stays.
- CSRF stays **on**, because the browser sends cookies with form posts.

```java
@Bean
@Order(2)
public SecurityFilterChain webChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(authorize -> authorize
            .requestMatchers("/", "/css/**", "/login").permitAll()
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated())
        .formLogin(form -> form
            .loginPage("/login")
            .defaultSuccessUrl("/dashboard", true)
            .permitAll())
        .logout(logout -> logout.logoutUrl("/logout").logoutSuccessUrl("/"));
    return http.build();
}
```

### Scenario C: One app with both a website and an API

**Situation:** Your app serves `/api/**` as JSON for an Angular app, and also serves regular web pages under `/` and `/admin/**`.

**Why two chains:** The API needs JWT and no sessions. The website needs sessions and login pages. One chain can't do both cleanly.

**How:** Give each chain a `securityMatcher` and an `@Order`. The API chain comes first, and the website chain is the fallback:

```java
@Bean
@Order(1)
public SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher("/api/**")          // only handles /api/**
        .csrf(csrf -> csrf.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
    return http.build();
}

@Bean
@Order(2)
public SecurityFilterChain webChain(HttpSecurity http) throws Exception {
    // no securityMatcher: handles everything not matched by the chain above
    http
        .authorizeHttpRequests(a -> a
            .requestMatchers("/", "/login").permitAll()
            .anyRequest().authenticated())
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

### Scenario D: Health checks that load balancers can reach

**Situation:** Your hosting service pings `/actuator/health` to check if your app is alive. The ping has no login.

**Why:** If health checks require a login, the server would look broken and get restarted in a loop.

```java
.requestMatchers("/actuator/health").permitAll()
.anyRequest().authenticated()
```

### Scenario E: "Sign in with Google" for a small internal tool

**Situation:** Only your company's staff should use an internal dashboard. They already have Google accounts.

**Why oauth2Login:** You don't want to manage passwords. Google does that for you.

```java
.authorizeHttpRequests(a -> a.anyRequest().authenticated())
.oauth2Login(Customizer.withDefaults())
```

---

## Quick Reference: Every Component at a Glance

|Component|Controls|Typical choice for a REST API|Typical choice for a website|
|---|---|---|---|
|`securityMatcher`|Which URLs this chain handles|`/api/**`|`/**` or omitted|
|`authorizeHttpRequests`|Access rules|Always used|Always used|
|`csrf`|Form/cookie attack protection|Disabled|Enabled|
|`cors`|Cross-domain browser access|Configured for your front-end|Usually not needed|
|`headers`|Browser safety headers|Defaults|Defaults|
|`sessionManagement`|Server-side sessions|`STATELESS`|Default|
|`formLogin`|Browser login page|Not used|Used|
|`httpBasic`|Username/password per request|Testing only|Rarely|
|`oauth2ResourceServer`|Accepting JWT tokens|Used|Rarely|
|`oauth2Login`|"Sign in with Google" style|Rarely|Used|
|`logout`|Ending a session|Not needed|Used|
|`exceptionHandling`|Response when blocked|Return 401|Redirect to login|

---



[[Spring Security]]