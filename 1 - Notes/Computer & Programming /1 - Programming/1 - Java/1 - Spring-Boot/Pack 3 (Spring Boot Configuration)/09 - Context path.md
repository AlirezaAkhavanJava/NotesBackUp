

## Mental model: the building's street number

Imagine one big building (the server) hosting several companies. Each company has its own **entrance prefix**: `/shop`, `/blog`, `/admin`. Everything that company serves sits behind its prefix.

The **context path** is that prefix: the part of the URL **between the host and your controller paths**, which identifies _the whole application_.

```
http://localhost:8080/shop/api/products/7
                      └─┬─┘└────────┬───────┘
                  context path   your mappings
                  (the app)      (@RequestMapping + @GetMapping)
```

## Why it exists (the history)

In classic Java EE, **one Tomcat ran many apps**, each deployed as a WAR file. Tomcat needed to know which app a request belonged to, so each app got a context path (`shop.war` became `/shop`). The server stripped the prefix and passed the rest to that app.

Spring Boot usually runs **one app per embedded server**, so the default context path is empty (`/`). Your controller URLs start right after the port.

## Setting it in Spring Boot

```properties
# application.properties
server.servlet.context-path=/shop
```

```yaml
# application.yml
server:
  servlet:
    context-path: /shop
```

Now every endpoint moves:

|Mapping in code|Without context path|With `/shop`|
|---|---|---|
|`@GetMapping("/api/products")`|`/api/products`|`/shop/api/products`|
|`@GetMapping("/actuator/health")`|`/actuator/health`|`/shop/actuator/health`|
|static files, `/error`|`/error`|`/shop/error`|

```bash
curl http://localhost:8080/shop/api/products     # works
curl http://localhost:8080/api/products          # 404
```

## Important: your code does NOT change

The context path is **not part of your mappings**. Inside the controller you still write `/api/products`. The server removes the context path before Spring MVC matches the route, so `@RequestMapping` never sees it.

```java
@RequestMapping("/api/products")   // stays exactly like this
```

This is the key difference from `@RequestMapping`: **`@RequestMapping` is per controller, context path is per application.**

## Context path vs servlet path vs `@RequestMapping`

A full URL path splits into layers:

```
/shop          /api/products        /7
context path   @RequestMapping      @GetMapping("/{id}")
(whole app)    (controller)         (method)
```

Spring Boot also has `spring.mvc.servlet.path`, which sets the `DispatcherServlet`'s own prefix, in between:

```properties
spring.mvc.servlet.path=/v1
```

```
/shop  /v1  /api/products
 ctx   servlet  mapping
```

You rarely need it. Prefer one context path or controller-level prefixes.

## Reading it in code

```java
@GetMapping("/where")
public String where(HttpServletRequest request) {
    return request.getContextPath();      // "/shop" (or "" when none)
}
```

More importantly, **build URLs with the builders** so the context path is included automatically:

```java
ServletUriComponentsBuilder.fromCurrentContextPath().path("/api/products/{id}")
        .buildAndExpand(7).toUri();
// http://localhost:8080/shop/api/products/7
```

This is exactly why the `Location` header example earlier used `ServletUriComponentsBuilder` instead of string concatenation: hardcoded strings break the moment a context path is added.

## Why and when to use it

|Reason|Example|
|---|---|
|Several apps behind one domain and port|`example.com/shop`, `example.com/blog`|
|A reverse proxy routes by prefix|nginx sends `/shop/**` to this app|
|Deploying a WAR into an external Tomcat|the WAR name often becomes the context path|
|Namespacing an API|`/api-service`|

## What if you don't set it?

Nothing breaks. The default is empty, and URLs start at the root. For most Spring Boot apps (especially in containers, one app per service) **you don't need one**.

## What if you add one and forget somewhere?

|Place that forgets it|Symptom|
|---|---|
|Angular `environment.ts` base URL|every call 404s|
|Health checks (Docker/Kubernetes `/actuator/health`)|probe fails, container restarts|
|Hardcoded redirects/links in code|pages or links point to nowhere|
|Postman collection / curl scripts|404|
|nginx proxy config|wrong path forwarded|

## Nuances and gotchas

**1. Context path vs the `/api` prefix.** `/api` is usually a controller-level convention (`@RequestMapping("/api/...")`). Context path is app-wide and set in configuration. Use the one that fits: if you only want to prefix REST endpoints and not the actuator or static files, use `@RequestMapping`. In Spring 6+ you can also prefix all `@RestController`s at once:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void configurePathMatch(PathMatchConfigurer c) {
        c.addPathPrefix("/api", HandlerTypePredicate.forAnnotation(RestController.class));
    }
}
```

**2. Must start with `/` and not end with `/`.** `/shop` is valid. `shop` or `/shop/` aren't accepted (Boot warns or fails at startup).

**3. In tests,** `MockMvc` does not include the context path by default, because it bypasses the server. A test that calls `/api/products` passes even though the real URL is `/shop/api/products`. Full server tests with `TestRestTemplate` (`@SpringBootTest(webEnvironment = RANDOM_PORT)`) do include it.

**4. CORS and Spring Security matchers don't include it.** They match against the path _after_ the context path, so write `/api/**`, not `/shop/api/**`.

**5. Behind a reverse proxy,** the proxy's external prefix and the app's context path can differ. Nginx can strip `/shop` before forwarding, in which case the app should have **no** context path. Mixing the two is a classic cause of doubled prefixes (`/shop/shop/api`). The `X-Forwarded-Prefix` header exists to tell the app about a stripped prefix, so generated links come out right (needs `server.forward-headers-strategy`).

**6. Cookies.** The session cookie's `Path` follows the context path, so with `/shop` the cookie is only sent for `/shop/**`.

**7. Environment variable form** (handy in Docker):

```bash
SERVER_SERVLET_CONTEXT_PATH=/shop java -jar app.jar
```

Spring Boot's relaxed binding maps that name automatically.

## Quick reference

|Question|Answer|
|---|---|
|Default|empty (`/`)|
|Property|`server.servlet.context-path=/shop`|
|Does my `@RequestMapping` include it?|No, never|
|Scope|the entire application, including actuator and static resources|
|Read at runtime|`request.getContextPath()`|
|Build links correctly|`ServletUriComponentsBuilder.fromCurrentContextPath()`|
|Matches in Security/CORS|write the path without it|

## Request path, step by step

```
GET http://localhost:8080/shop/api/products/7

1. Tomcat strips the context path   →  "/shop" removed
2. DispatcherServlet receives       →  /api/products/7
3. HandlerMapping matches           →  @RequestMapping("/api/products") + @GetMapping("/{id}")
```




[[Spring Framework]]