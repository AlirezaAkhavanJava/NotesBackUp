

## Part 1: History of Spring Security

### The problem it solves

In the early 2000s, Java web security meant writing your own login code or relying on whatever your application server offered. Server-based security was tied to one vendor (Tomcat's way, WebLogic's way), so moving your app meant rewriting your security. It was also coarse: you could protect a URL, but protecting _a method_ or _one object_ was hard.

Spring Security grew up to fix that. It gives you one security framework that works the same on any server and covers URLs, methods, and objects.

### The timeline

|Year|Version|What happened|
|---|---|---|
|2003|**Acegi Security**|Ben Alex starts a project called Acegi to bring security to Spring apps. It's powerful but notorious for needing hundreds of lines of XML.|
|2008|**Spring Security 2.0**|Acegi is renamed and officially joins the Spring portfolio. The big win is a **namespace** (short XML tags like `<http>`) that replaced those hundreds of lines with a few.|
|2009|**3.0**|Moves to Spring 3. Adds **SpEL** expressions such as `hasRole('ADMIN')`, and `@PreAuthorize`-style method security.|
|2013|**3.2**|A turning point. **CSRF protection and security headers** (HSTS, `X-Frame-Options`, and so on) are added, tied directly to the attacks from our earlier lessons. Java configuration arrives, so XML becomes optional.|
|2015|**4.0**|CSRF protection becomes **on by default** in the XML namespace as well. Better testing support (`@WithMockUser`).|
|2017|**5.0**|Built for Spring 5. Adds **OAuth 2.0 / OpenID Connect login**, **reactive (WebFlux) support**, and the `DelegatingPasswordEncoder`, which stores passwords like `{bcrypt}$2a$...` so hashing algorithms can be upgraded over time.|
|2019-2021|**5.2 to 5.5**|Resource server support (validating JWTs), then the old Spring Security OAuth project is retired, and its features move into the core.|
|2022|**5.7**|`WebSecurityConfigurerAdapter` is **deprecated**. You now define a `SecurityFilterChain` bean instead.|
|Nov 2022|**6.0**|Needs Java 17, Jakarta EE (`javax.*` becomes `jakarta.*`), and `authorizeHttpRequests` replaces `authorizeRequests`.|
|2024|**6.3 and 6.4**|Passkeys (**WebAuthn**) support and one-time-token login.|
|Nov 2025|**7.0**|Released alongside Spring Framework 7 and Spring Boot 4. Removes long-deprecated APIs, and the old `.and()` chaining style is gone in favor of lambdas. It also adds multi-factor authentication support.|

For the newest release details, check spring.io, since versions move quickly.

### The biggest shift: how configuration looks

This is the change you'll see most often in tutorials, so it's worth learning to recognize it.

**Old style (before 5.7, now removed):**

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
            .antMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated()
            .and()
            .formLogin();
    }
}
```

**Modern style (6.x and 7):**

```java
@Configuration
public class SecurityConfig {
    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .formLogin(Customizer.withDefaults());
        return http.build();
    }
}
```

Line by line:

- Instead of extending a base class, you declare a **bean**. This fits Spring's normal style and lets you define several chains (for example one for `/api/**` and one for the web UI).
- `authorizeHttpRequests(auth -> ...)` is the lambda style. Everything about "who may access what" lives inside one block, so there is no more fragile `.and()` chaining.
- `requestMatchers` replaced `antMatchers` and `mvcMatchers`, which were easy to confuse.
- `Customizer.withDefaults()` means "turn this on with default settings."

### The idea that never changed: the filter chain

Through all these versions, the core design stayed the same. Spring Security is a **chain of servlet filters** that every request passes through before it reaches your controller.

```
Request → [CSRF filter] → [Authentication filter] → [Authorization filter] → DispatcherServlet → Controller
```

Each filter has one job, and you can add, remove, or reorder them. This is why Spring Security's defaults line up so well with the history of web security: each attack you learned about became a filter or a default.

### Related concept, briefly: Authentication vs authorization

**Authentication** asks "who are you?" (login). **Authorization** asks "what may you do?" (roles and permissions). Spring Security's types mirror this: `AuthenticationManager` handles the first, and `AuthorizationManager` handles the second.

---

## Part 2: Spring Boot Networking

### The problem it solves

Before Spring Boot, deploying a Java web app meant installing a separate server like Tomcat, building a **WAR** file, and dropping it into that server. Boot flipped this around: your app **contains** its own server. You build one JAR and run `java -jar app.jar`. Networking is then something you configure in your own app, in one place.

Networking in Boot has two sides:

1. **Inbound:** requests coming _into_ your app (the server).
2. **Outbound:** requests your app makes _to_ other services (the clients).

### Inbound: the embedded server

Adding `spring-boot-starter-web` brings in **Tomcat** by default. Other choices:

|Server|When you'd pick it|
|---|---|
|**Tomcat**|The default, solid and widely understood|
|**Jetty**|Lightweight, popular for some async workloads|
|**Undertow**|Fast and compact (check that your Boot version still supports it)|
|**Netty**|Used by the reactive stack (`spring-boot-starter-webflux`)|

### What happens when a request arrives

```
Browser
  │  TCP connection + TLS handshake
  ▼
Embedded Tomcat  (a thread from the worker pool takes the request)
  │
  ▼
Servlet filters  (Spring Security, CORS, logging...)
  │
  ▼
DispatcherServlet  (Spring MVC's front door)
  │  finds the matching @RequestMapping
  ▼
Your @RestController method
  │  returns an object
  ▼
HttpMessageConverter  (turns it into JSON)
  │
  ▼
Response back to the browser
```

Key points:

- Tomcat uses a **thread per request**. A thread picks up your request and is busy until the response is done. This is why slow calls inside controllers hurt: they hold a thread.
- The **DispatcherServlet** is a single entry point that routes each request to the right controller method.
- **Message converters** (Jackson for JSON) convert Java objects to and from the request and response bodies.

### The basic network settings

All of these go in `application.properties`:

```properties
server.port=8080
server.address=127.0.0.1
server.compression.enabled=true
server.http2.enabled=true
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```

Line by line:

- `server.port` is the port to listen on. Use `0` to pick a random free port, which is handy in tests.
- `server.address` is which network interface to listen on. `127.0.0.1` means "only this machine." The default listens on all interfaces. This is a useful security habit for local services.
- `server.compression.enabled` gzips responses so they cross the network smaller.
- `server.http2.enabled` turns on HTTP/2, which multiplexes many requests over one connection. (Browsers use HTTP/2 only over HTTPS.)
- `server.shutdown=graceful` makes the app finish in-flight requests before stopping, instead of cutting them off.
- `spring.lifecycle.timeout-per-shutdown-phase` is how long it waits before giving up.

### Tuning Tomcat's capacity

```properties
server.tomcat.threads.max=200
server.tomcat.max-connections=8192
server.tomcat.accept-count=100
server.tomcat.connection-timeout=20s
```

These three numbers are often confused, so here is how they relate:

|Setting|Meaning|Analogy|
|---|---|---|
|`threads.max`|How many requests are processed _at the same time_|Cashiers working|
|`max-connections`|How many open connections Tomcat will hold|People allowed inside the shop|
|`accept-count`|Queue length once connections are full|People waiting outside the door|
|`connection-timeout`|How long to wait for a client to send data|Patience for a slow customer|

### Virtual threads (a modern alternative)

Since Boot 3.2 with Java 21, one line changes the model:

```properties
spring.threads.virtual.enabled=true
```

**Virtual threads** are very cheap threads managed by the JVM. Your code stays simple and blocking, but waiting on a database or another service no longer ties up a scarce operating-system thread. This gets much of the scalability of reactive programming without rewriting your code in a reactive style.

### Turning on HTTPS in Boot

Boot 3.1 introduced **SSL bundles**, a tidy way to describe certificates:

```properties
server.port=8443
server.ssl.bundle=web
spring.ssl.bundle.pem.web.keystore.certificate=classpath:certs/server.crt
spring.ssl.bundle.pem.web.keystore.private-key=classpath:certs/server.key
```

Line by line:

- `server.ssl.bundle=web` says "use the bundle named `web` for HTTPS."
- The next two lines define that bundle: the certificate and its private key in PEM format. You can also use a Java keystore (`jks` or `p12`) instead.
- The word `web` is just a name you choose.

For local experiments on Debian, you can create a self-signed certificate with `openssl`. Browsers will warn about it, which is exactly the certificate-trust behavior from the earlier lesson.

To redirect HTTP to HTTPS using Spring Security:

```java
http.requiresChannel(channel -> channel.anyRequest().requiresSecure());
```

### When you're behind a reverse proxy

In real deployments, Nginx or a cloud load balancer usually sits in front, handles HTTPS, and forwards plain HTTP to your app. The problem: your app now thinks every request is `http://` from the proxy's IP, so redirects and generated links come out wrong.

The proxy passes the truth in headers like `X-Forwarded-For` and `X-Forwarded-Proto`. Tell Boot to trust them:

```properties
server.forward-headers-strategy=framework
```

Only enable this when you really are behind a proxy you control. Otherwise a client could forge those headers.

### CORS in Spring Boot

Recall that CORS is how a server allows another origin to read its responses. Here is a global configuration:

```java
@Bean
WebMvcConfigurer corsConfigurer() {
    return new WebMvcConfigurer() {
        @Override
        public void addCorsMappings(CorsRegistry registry) {
            registry.addMapping("/api/**")
                    .allowedOrigins("https://app.example.com")
                    .allowedMethods("GET", "POST");
        }
    };
}
```

Line by line:

- `addMapping("/api/**")` applies the rules only to URLs under `/api`.
- `allowedOrigins(...)` lists exactly which sites may read responses. Avoid `"*"` when credentials are involved.
- `allowedMethods(...)` lists the HTTP methods allowed.

If you use Spring Security, also enable `http.cors(Customizer.withDefaults())`, so the CORS check happens _before_ the security filters. Otherwise the browser's preflight `OPTIONS` request gets rejected as unauthenticated.

### Outbound: calling other services

Your app often needs to call other HTTP APIs. Spring has several clients:

|Client|Style|Status|
|---|---|---|
|**RestTemplate**|Blocking, older|In maintenance mode, but common in existing code|
|**RestClient**|Blocking, fluent|The modern recommended choice (Spring 6.1+)|
|**WebClient**|Reactive, non-blocking|Good for reactive apps and streaming|
|**HTTP Interface**|Declarative (like Feign)|You write an interface, Spring generates the client|

Here is `RestClient`:

```java
RestClient client = RestClient.builder()
        .baseUrl("https://api.example.com")
        .defaultHeader("Accept", "application/json")
        .build();

User user = client.get()
        .uri("/users/{id}", 42)
        .retrieve()
        .body(User.class);
```

Line by line:

- `RestClient.builder()` starts configuring a reusable client. Build it once and share it.
- `.baseUrl(...)` sets the common prefix so each call only needs a path.
- `.defaultHeader(...)` adds a header to every request.
- `.get().uri("/users/{id}", 42)` makes a GET to `/users/42`. The `{id}` placeholder is filled safely, which also protects against injection in the URL.
- `.retrieve()` sends the request and gets ready to read the response. It throws an exception on 4xx or 5xx statuses.
- `.body(User.class)` converts the JSON response into a `User` object.

And the declarative style:

```java
public interface UserApi {
    @GetExchange("/users/{id}")
    User getUser(@PathVariable long id);
}
```

You describe the call, and Spring builds the implementation, which keeps client code tidy.

### Timeouts: the setting people forget

By default, a client may wait a very long time for an answer. If another service hangs, your threads pile up waiting, and your own app goes down with it. Always set timeouts:

```properties
spring.http.client.connect-timeout=2s
spring.http.client.read-timeout=5s
```

(These properties exist in recent Boot versions. On older ones, set timeouts on the request factory in code.)

- **Connect timeout:** how long to wait to establish the connection.
- **Read timeout:** how long to wait for data once connected.

For serious systems, add retries and circuit breakers (Resilience4j) on top.

### Related networking features, briefly

**WebSockets and SSE:** HTTP is request-then-response. When the server must push updates (chat, live dashboards), you can use **WebSocket** (a two-way channel) or **Server-Sent Events** (one-way server to browser, simpler). Spring supports both.

**Actuator:** adding `spring-boot-starter-actuator` exposes endpoints like `/actuator/health` for load balancers to check. Secure these, and expose only what you need, because they reveal internals.

### Seeing it in the Network tab

Everything above shows up in the browser you learned about last lesson:

- `server.compression.enabled` appears as a `content-encoding: gzip` response header.
- `server.http2.enabled` appears as `h2` in the **Protocol** column.
- CORS appears as the preflight `OPTIONS` request.
- Spring Security's headers (HSTS, `X-Content-Type-Options`) appear in **Response Headers**.

### Try it yourself

1. **Change the port and address:** set `server.port=9090` and `server.address=127.0.0.1`. Then run `curl -i http://localhost:9090/` from Debian, and try it from another machine to see the difference.
2. **Watch compression:** enable it, then run `curl -i -H "Accept-Encoding: gzip" http://localhost:8080/api/big`. Look for `Content-Encoding: gzip`.
3. **Break a timeout on purpose:** write a `RestClient` call to a slow endpoint, with `read-timeout=1s`, and watch the exception.
4. **Compare the two lessons:** add Spring Security, then use the Network tab to find the `Set-Cookie` and `Strict-Transport-Security` headers it adds by itself.

### How the two halves connect

|Concern|Spring Security|Spring Boot networking|
|---|---|---|
|HTTPS|`requiresChannel`, HSTS header|`server.ssl.*` bundles|
|Behind a proxy|Needs correct scheme to enforce HTTPS|`forward-headers-strategy`|
|CORS|`http.cors(...)` ordering|`addCorsMappings`|
|Request pipeline|Filters run _before_ DispatcherServlet|Embedded server hands requests to the filters|





[[Spring Security]]