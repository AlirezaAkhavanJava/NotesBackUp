

An authentication filter is a small class that sits in front of your controllers and looks at every incoming HTTP request before your code runs. Its job is to pull the login information out of the raw request (a header, a form field, a cookie), turn it into an unverified `Authentication` object, hand it to the `AuthenticationManager`, and store the verified result so the rest of the app knows who is calling.

In the last lesson you built the judge (`ApiKeyAuthenticationProvider`) and the claim form (`ApiKeyAuthenticationToken`). Nothing was delivering the claim yet. The filter is the delivery person, and it's also where you decide what happens when delivery fails. This lesson follows one request from the network all the way to the `SecurityContextHolder`.

---

## Part 1: Where the Filter Lives

**Diagram: The Spring Security filter chain (simplified)**

```
HTTP request
   │
   ▼
[ SecurityContext filter ]                 restores saved login (if any)
   │
   ▼
[ ApiKeyAuthenticationFilter ]             ◄── the one you write
   │
   ▼
[ UsernamePasswordAuthenticationFilter ]   handles form logins
   │
   ▼
[ AnonymousAuthenticationFilter ]          marks "nobody" if still not logged in
   │
   ▼
[ AuthorizationFilter ]                    checks your hasRole(...) rules
   │
   ▼
Your controller
```

Spring Security is, at its core, a chain of filters. Each request walks through them in order, and each filter can inspect it, change it, or stop it. Your filter must run **before** the authorization check. Otherwise the app would ask "is this user allowed?" before it has found out who the user is.

---

## Part 2: Writing the Filter

**Code: `ApiKeyAuthenticationFilter.java`**

```java
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    private static final String HEADER = "X-API-KEY";

    private final AuthenticationManager authenticationManager;
    private final AuthenticationEntryPoint entryPoint;

    public ApiKeyAuthenticationFilter(AuthenticationManager authenticationManager,
                                      AuthenticationEntryPoint entryPoint) {
        this.authenticationManager = authenticationManager;
        this.entryPoint = entryPoint;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        String apiKey = request.getHeader(HEADER);

        if (apiKey == null || apiKey.isBlank()) {
            chain.doFilter(request, response);
            return;
        }

        try {
            Authentication result =
                    authenticationManager.authenticate(new ApiKeyAuthenticationToken(apiKey));

            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(result);
            SecurityContextHolder.setContext(context);
        } catch (AuthenticationException ex) {
            SecurityContextHolder.clearContext();
            entryPoint.commence(request, response, ex);
            return;
        }

        chain.doFilter(request, response);
    }
}
```

### Title: The class declaration and its fields

- `extends OncePerRequestFilter` is a Spring base class that guarantees your filter runs **once** per request, even when the request is forwarded internally. You implement `doFilterInternal` instead of the raw `doFilter`.
- `HEADER` is the name of the header your scripts will send.
- `authenticationManager` is who you ask "is this valid?". `entryPoint` is who writes the error response when the answer is no.

### Title: Reading the key from the request

- `request.getHeader(HEADER)` returns the value of `X-API-KEY`, or `null` if the header isn't there.

### Title: The "no header" branch

- If there's no key, the filter does _not_ reject. It calls `chain.doFilter(...)` and returns, passing the request along untouched.
- Why? This request might be for a public URL, or might be authenticated some other way. Rejecting is the job of the authorization rules later, not of this filter.

### Title: Asking the manager to verify

- `new ApiKeyAuthenticationToken(apiKey)` builds the **unverified** claim, using the first constructor from last lesson.
- `authenticationManager.authenticate(...)` is where your provider runs. The manager walks its providers, finds the one whose `supports()` says yes, and calls your `authenticate()`.

### Title: Saving the verified result

- On success, `result` is the **verified** token. The filter creates a fresh empty `SecurityContext`, puts the result inside, and sets it on the `SecurityContextHolder`.
- From this moment, any code in this request can ask "who is logged in?"

### Title: Handling a failed login

- On failure, the provider threw an `AuthenticationException`. The filter clears the context and asks the entry point to write the error response (a 401).
- The `return` is essential. It stops the request here, so it never reaches the controller.

### Title: Passing the request along

- If everything worked, `chain.doFilter(request, response)` hands the request to the next filter in the chain.

---

## Part 3: Plugging the Filter Into the Security Chain

**Code: `ApiSecurityConfig.java`**

```java
@Configuration
@EnableWebSecurity
public class ApiSecurityConfig {

    @Bean
    public SecurityFilterChain apiChain(HttpSecurity http,
                                        ApiKeyAuthenticationProvider provider) throws Exception {

        AuthenticationManager manager = new ProviderManager(provider);
        AuthenticationEntryPoint entryPoint = new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED);

        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/**").hasRole("SERVICE")
                .anyRequest().denyAll())
            .exceptionHandling(e -> e.authenticationEntryPoint(entryPoint))
            .addFilterBefore(new ApiKeyAuthenticationFilter(manager, entryPoint),
                             UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

**Table: What each line of the configuration does**

|Line|Meaning|
|---|---|
|`new ProviderManager(provider)`|A manager holding just your API key provider, keeping this chain self-contained|
|`HttpStatusEntryPoint(UNAUTHORIZED)`|Replies with a plain `401` and no redirect, which is what an API client wants|
|`csrf.disable()`|Fine here, because API-key clients don't use browser cookies|
|`STATELESS`|No HTTP session is created, so the key is checked on every request|
|`hasRole("SERVICE")`|Matches the `ROLE_SERVICE` authority your provider assigned|
|`anyRequest().denyAll()`|Blocks everything not listed, a safe default|
|`addFilterBefore(..., UsernamePasswordAuthenticationFilter.class)`|Places your filter early enough, before authorization|

**Warning: do not annotate the filter with `@Component`.** Spring Boot automatically registers any `Filter` bean as a servlet filter, so it would run twice: once on its own and once inside the security chain. Creating it with `new` inside the chain method avoids that.

---

## Part 4: The Whole Journey of One Request

**Diagram: From HTTP header to controller**

```
Script:  GET /api/orders      header  X-API-KEY: abc123
   │
   ▼
ApiKeyAuthenticationFilter
   │  reads header "abc123"
   │  builds ApiKeyAuthenticationToken("abc123")        [unverified]
   ▼
ProviderManager.authenticate(token)
   │  asks each provider: supports()?
   ▼
ApiKeyAuthenticationProvider
   │  hashes the key, looks it up in the database
   │  found   ──► returns token(principal, [ROLE_SERVICE])   [verified]
   │  missing ──► throws BadCredentialsException
   ▼
Back in the filter
   │  success: SecurityContextHolder.setContext(...)
   │  failure: 401 response, request stops
   ▼
AuthorizationFilter
   │  rule: /api/** needs hasRole("SERVICE")  ──► ROLE_SERVICE found ──► allowed
   ▼
Your controller runs
```

**Code: Reading the verified user inside a controller**

```java
@GetMapping("/api/orders")
public List<Order> orders(Authentication authentication) {
    String clientName = (String) authentication.getPrincipal();
    return orderService.findFor(clientName);
}
```

Spring injects the `Authentication` straight from the `SecurityContextHolder`. The principal is whatever your provider put in the verified token, here the client name.

---

## Part 5: What Each Outcome Looks Like

**Table: Request scenarios and responses**

|Request|What happens|Response|
|---|---|---|
|Valid key|Provider verifies, context is set, rules pass|`200`|
|No header at all|Filter skips, user stays anonymous, `hasRole` rule fails|`401` (from the entry point)|
|Wrong key|Provider throws `BadCredentialsException`, filter calls the entry point|`401`|
|Valid key but wrong role|Verified, but `hasRole("SERVICE")` fails|`403`|

Remember the difference: `401` means "I don't know who you are." `403` means "I know who you are, and you aren't allowed."

---

## Part 6: Testing It With curl

**Commands: Three requests, three expected results**

```bash
# no key: expect 401
curl -i http://localhost:8080/api/orders

# wrong key: expect 401
curl -i -H "X-API-KEY: wrong" http://localhost:8080/api/orders

# right key: expect 200
curl -i -H "X-API-KEY: abc123" http://localhost:8080/api/orders
```

---

## Part 7: Common Mistakes

**Table: Mistakes and their fixes**

|Mistake|What goes wrong|Fix|
|---|---|---|
|Marking the filter `@Component`|It runs twice|Create it with `new` in the chain|
|Rejecting when the header is missing|Public URLs break|Pass the request along and let the authorization rules decide|
|Forgetting `return` after the entry point|The request continues to the controller after a 401 was sent|Always `return` right after `commence(...)`|
|Placing the filter too late|Every request looks anonymous|Use `addFilterBefore` ahead of the authorization filter|
|Storing raw API keys|A database leak exposes every key|Store a hash (SHA-256 is acceptable for long random keys, unlike human-chosen passwords)|
|Wrong role prefix|`hasRole("SERVICE")` always fails|The provider must grant `ROLE_SERVICE`|

---

## Part 8: Related Concepts in Short

**Table: Neighboring ideas**

|Concept|One-line summary|
|---|---|
|`OncePerRequestFilter`|Spring's base class that makes a filter run exactly once per request. Use it for almost every custom security filter.|
|`SecurityFilterChain`|A list of filters applied to a group of URLs. You can define several chains, such as one for `/api/**` with API keys and another for the website with form login.|
|`AuthenticationEntryPoint`|Decides _how_ to respond when an unauthenticated user hits a protected resource. A web app redirects to a login page, an API sends a `401`.|
|`SecurityContextHolder`|A per-request (thread-bound) holder of the current `SecurityContext`. Filters write to it, and controllers and services read from it.|

---



[[Spring Security]]