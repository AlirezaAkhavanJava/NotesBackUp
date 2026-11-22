

## Part 1: The Problem CORS Solves

### Definition

**CORS (Cross-Origin Resource Sharing)** is a mechanism that lets a server tell the browser which _other_ websites are allowed to read its responses. It is an exception to a stricter default rule called the **same-origin policy**.

An **origin** is the combination of three things:

```
https://example.com:443
  ^scheme  ^host       ^port
```

Two URLs have the same origin only if the scheme, host, and port all match. So these are all different origins from each other:

- `http://localhost:4200`
- `http://localhost:8080`
- `https://localhost:8080`
- `http://127.0.0.1:8080`

### Why it exists

Your browser automatically attaches cookies to requests sent to a site you're logged into. Imagine you're logged into your bank at `bank.com`, and you then visit a malicious page at `evil.com`. Without restrictions, the JavaScript on `evil.com` could call `bank.com/api/balance`, the browser would attach your session cookie, and the script could read your balance.

The same-origin policy blocks this: JavaScript from one origin cannot _read_ the responses of requests to another origin. CORS is the controlled way for a server to say "I trust this other origin to read my responses."

### The problem you will hit

When you build an Angular front end and a Spring Boot back end, they run on different ports during development:

- Angular dev server: `http://localhost:4200`
- Spring Boot: `http://localhost:8080`

Angular's `HttpClient` calling `http://localhost:8080/api/tasks` is a cross-origin request. Spring Boot will process it, but the browser will block the response and show an error like:

```
Access to XMLHttpRequest at 'http://localhost:8080/api/tasks' from origin
'http://localhost:4200' has been blocked by CORS policy
```

The key fact to internalize: **CORS is enforced by the browser, not the server.** The server happily sends the response. The browser decides whether your JavaScript is allowed to see it. This is why the same request works fine in Postman or `curl`, which don't enforce CORS at all.

---

## Part 2: How the Browser and Server Negotiate

Understanding the mechanics makes the configuration much easier to reason about.

### Simple requests

A request is "simple" if it uses `GET`, `HEAD`, or `POST` with basic headers and a content type of `text/plain`, `multipart/form-data`, or `application/x-www-form-urlencoded`.

For these, the browser sends the request directly and adds an `Origin` header:

```
GET /api/tasks HTTP/1.1
Host: localhost:8080
Origin: http://localhost:4200
```

The server responds with an `Access-Control-Allow-Origin` header:

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:4200
```

The browser compares the two. If they match, your JavaScript can read the response. If not, the browser discards it and throws the error.

### Preflight requests

Most real API calls are **not** simple. Sending `Content-Type: application/json`, or using `PUT`, `DELETE`, or an `Authorization` header, makes a request non-simple. For these, the browser first sends a **preflight request**, an `OPTIONS` request asking permission:

```
OPTIONS /api/tasks HTTP/1.1
Origin: http://localhost:4200
Access-Control-Request-Method: POST
Access-Control-Request-Headers: content-type, authorization
```

The server must answer with permissions:

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:4200
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: content-type, authorization
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 3600
```

Only if this preflight answer grants permission does the browser send the real `POST`. This is why a CORS problem often appears as a failing `OPTIONS` request in the browser's Network tab, even though your controller's `POST` method looks correct.

### Why this matters for Spring

Spring has to answer these preflight `OPTIONS` requests itself, before your controller's method is ever called, and your controller doesn't have an `OPTIONS` handler. The CORS configuration is what teaches Spring how to answer them. That is the whole job of `CorsConfig`.

---

## Part 3: The Three Ways to Configure CORS in Spring

Spring offers three levels. Knowing when each applies saves a lot of confusion.

|Approach|Scope|Best for|
|---|---|---|
|`@CrossOrigin` on a controller or method|Specific endpoints|Quick experiments, one-off exceptions|
|`WebMvcConfigurer.addCorsMappings`|Global, by URL pattern|Apps **without** Spring Security|
|`CorsConfigurationSource` bean|Global, inside the security filter chain|Apps **with** Spring Security (most real apps)|

Let's go through each with working code.

---

## Part 4: Approach One, `@CrossOrigin` on a Controller

### Definition

`@CrossOrigin` is an annotation that declares CORS rules directly on a controller class or method.

### Why it exists

Sometimes you only need to open one endpoint to one origin, and you don't want to touch global configuration.

### Example

```java
package com.example.demo.controller;

import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/tasks")
@CrossOrigin(origins = "http://localhost:4200")
public class TaskController {

    @GetMapping
    public List<String> getAllTasks() {
        return List.of("Learn Spring Boot", "Learn Angular");
    }

    @PostMapping
    public String createTask(@RequestBody String title) {
        return "Created: " + title;
    }
}
```

**What this does:**

- `@CrossOrigin(origins = "http://localhost:4200")` tells Spring that every method in `TaskController` accepts cross-origin requests from Angular's dev server.
- Spring automatically answers preflight `OPTIONS` requests for these endpoints.
- Other controllers in the app are unaffected, so they remain protected.

**The limitation:** You have to remember to annotate every controller. In a growing project, this becomes repetitive and easy to forget, which is why global configuration is usually preferred.

---

## Part 5: Approach Two, Global Config with `WebMvcConfigurer`

This is the class most tutorials mean when they talk about a `CorsConfig` file. It works when you are **not** using Spring Security.

### Definition

`WebMvcConfigurer` is an interface that lets you customize Spring MVC's behavior. Its `addCorsMappings` method lets you register CORS rules for URL patterns across the whole application.

### Example

```java
package com.example.demo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:4200")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}
```

**What each line does:**

- `@Configuration` registers this class with Spring so it is loaded at startup.
- `implements WebMvcConfigurer` plugs your customization into Spring MVC's setup.
- `addMapping("/api/**")` applies these rules to every URL starting with `/api/`. The `**` is a wildcard matching any depth of path, so `/api/tasks`, `/api/tasks/5`, and `/api/users/3/tasks` are all covered. URLs outside `/api/` are unaffected.
- `allowedOrigins("http://localhost:4200")` is the whitelist. Only this exact origin may read responses. The scheme, host, and port must match exactly, so `http://localhost:4201` would be refused.
- `allowedMethods(...)` lists the HTTP methods the browser may use. `OPTIONS` is included so preflight requests succeed.
- `allowedHeaders("*")` permits any request header. In production you would list only the headers you actually need, such as `Content-Type` and `Authorization`.
- `allowCredentials(true)` permits cookies and `Authorization` headers to be sent cross-origin. Your Angular `HttpClient` must also set `withCredentials: true` for this to take effect.
- `maxAge(3600)` tells the browser to cache the preflight answer for 3,600 seconds (one hour), so it doesn't repeat the `OPTIONS` request before every call.

---

## Part 6: Approach Three, CORS With Spring Security

This is the approach you need once your project includes Spring Security, which most real applications do eventually.

### Why the previous approach breaks with Security

Spring Security works through a chain of **servlet filters** that run _before_ requests reach Spring MVC. If a request is rejected by a security filter (for example, because it has no login token), it never reaches the MVC layer where `WebMvcConfigurer` is applied.

Preflight `OPTIONS` requests carry no credentials, so Security rejects them with `401` or `403`. The browser sees a failed preflight and reports a CORS error, even though your CORS config looks correct. The fix is to make Security aware of CORS, so the CORS check runs inside the security filter chain.

### Example

```java
package com.example.demo.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(Customizer.withDefaults())   // use the CorsConfigurationSource bean below
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll()      // demo only: open all endpoints
            );
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("http://localhost:4200"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Content-Type", "Authorization"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
```

**What this does, piece by piece:**

- `.cors(Customizer.withDefaults())` switches on CORS handling inside the security filter chain. `withDefaults()` tells Spring to look for a `CorsConfigurationSource` bean and use it. This single line is what makes preflight requests pass through Security.
- `corsConfigurationSource()` is a bean that holds the rules. Spring discovers it automatically.
- `CorsConfiguration` is a plain object holding the same settings as the `WebMvcConfigurer` example: origins, methods, headers, credentials, and cache time.
- `UrlBasedCorsConfigurationSource` maps URL patterns to rule sets. `registerCorsConfiguration("/api/**", config)` applies the rules to `/api/` paths only.
- `anyRequest().permitAll()` is included only so the example runs without a login. In a real app you would require authentication for protected endpoints. The CORS rules are separate from authorization: CORS decides _which origins may read responses_, while authorization decides _which users may access an endpoint_.

Notice that a `WebMvcConfigurer` CORS config and a `CorsConfigurationSource` bean are alternatives, not a pair. If you use Spring Security, the `CorsConfigurationSource` bean is the one that matters. Keeping both can create confusing duplicate behavior.

---

## Part 7: Verifying Your Configuration

Don't guess. You can test CORS directly with `curl` by pretending to be the browser.

Start your Spring Boot app, then run:

```bash
curl -i -X OPTIONS http://localhost:8080/api/tasks \
  -H "Origin: http://localhost:4200" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"
```

**What this does:** It sends a preflight request exactly as a browser would, claiming to come from Angular and asking to use `POST`. The `-i` flag prints response headers so you can inspect them.

**A correct response looks like this:**

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:4200
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS
Access-Control-Max-Age: 3600
```

**A broken response** usually shows either a `401` or `403` status (the Security problem from Part 6), or no `Access-Control-Allow-Origin` header at all (the origin doesn't match your whitelist).

You can also run the test with a wrong origin, such as `-H "Origin: http://evil.com"`. The response should omit the `Access-Control-Allow-Origin` header, which is exactly the protection you want.

In the browser, open DevTools (F12), go to the Network tab, and look at the `OPTIONS` entry for your request. Its response headers show what Spring actually sent.

---

## Part 8: Common Mistakes and How to Avoid Them

**Combining wildcard origins with credentials.** `allowedOrigins("*")` together with `allowCredentials(true)` is forbidden by the CORS specification, and Spring will throw an `IllegalArgumentException` at startup. You must list explicit origins. If you need many origins matching a pattern, use `allowedOriginPatterns("https://*.yourdomain.com")` instead.

**Forgetting `withCredentials` on the Angular side.** If your backend allows credentials but your Angular request doesn't send them, the cookies never arrive. In Angular, set `this.http.get(url, { withCredentials: true })`.

**Putting CORS rules in the wrong layer.** A `WebMvcConfigurer` config does nothing for requests blocked by Security. If you use Security and CORS still fails, check whether `.cors(...)` is in your filter chain.

**Hardcoding the origin.** Writing `http://localhost:4200` directly in code means you must edit and redeploy to change it for production. A cleaner approach moves the value into configuration:

```properties
# application.properties
app.cors.allowed-origins=http://localhost:4200
```

```java
@Value("${app.cors.allowed-origins}")
private String allowedOrigins;
```

Then pass `allowedOrigins` into your config. Different environments can then supply different values without any code change.

---

## Part 9: Putting It Into Practice

Here is a sequence you can follow to see every piece work together:

1. Create a Spring Boot project with the Web dependency, and add a `TaskController` as shown in Part 4. Run it and visit `http://localhost:8080/api/tasks` in your browser. It should display the JSON list.
2. Use the `curl` preflight test from Part 7 with no CORS config in place. Observe that the response lacks `Access-Control-Allow-Origin`.
3. Add the `CorsConfig` class from Part 5, restart, and run the `curl` test again. Observe the header appearing.
4. Change the origin in the `curl` test to `http://evil.com` and confirm the header disappears. This shows the whitelist is doing its job.
5. Once you start your Angular app, make an `HttpClient` call to `http://localhost:8080/api/tasks`. The request should succeed without a CORS error.

Working through this sequence will make the concepts concrete in a way reading alone cannot.

---




[[Spring Framework]]