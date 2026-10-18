

Spring Security protects your app **before a request ever reaches your controller**. You don't write "is this user logged in?" inside every endpoint. The filters do that work once, in one place. Understanding them helps you debug 401 and 403 errors, add JWT login, and fix "why is my request blocked?" problems.

## What a filter is

A **servlet filter** is a piece of code that runs before (and after) a request reaches your servlet. In Spring MVC, that servlet is the `DispatcherServlet`, which sends requests on to your controllers. Filters are linked together in a **chain**. Each filter can look at the request, change it, stop it, or pass it to the next filter with `chain.doFilter(request, response)`.

Spring Security is built from a set of these filters, each with one job: one checks CSRF tokens, one handles login, one checks permissions, and so on.

## How Spring Security plugs into the servlet world

The servlet container (Tomcat) knows nothing about Spring beans. Spring Security needs a bridge, and there are three layers.

```
Request
   │
   ▼
Tomcat's filter chain
   │
   ├─ ... other servlet filters ...
   │
   ├─ DelegatingFilterProxy      ← the bridge (Tomcat knows this one)
   │        │
   │        ▼
   │   FilterChainProxy          ← Spring Security's front door (a Spring bean)
   │        │
   │        ▼
   │   SecurityFilterChain       ← the first chain whose URL pattern matches
   │        │
   │        ▼
   │   [ security filter 1 → 2 → 3 → ... → N ]
   │
   ▼
DispatcherServlet → your controller
```

- **`DelegatingFilterProxy`** is a filter that Tomcat can see. It does no security work. It finds a Spring bean and hands the request to it. (In Spring Boot, auto-configuration registers it for you.)
- **`FilterChainProxy`** is that Spring bean, and it is the real entry point of Spring Security. It looks at the request URL and picks which `SecurityFilterChain` to run.
- **`SecurityFilterChain`** is an ordered list of security filters for a group of URLs. You define one as a bean.

You can have several chains, for example one for `/api/**` (JWT) and one for everything else (form login). Only the **first matching** chain runs, so put the more specific one first using `@Order`.

## The filters in a default chain

The order matters a lot. Here are the main filters in the order they run (the exact list changes with your configuration):

|#|Filter|What it does|
|---|---|---|
|1|`SecurityContextHolderFilter`|Loads the saved security context (for example from the session) so later filters know who you are|
|2|`HeaderWriterFilter`|Adds security headers to the response (`X-Content-Type-Options` and others)|
|3|`CorsFilter`|Handles CORS rules|
|4|`CsrfFilter`|Rejects state-changing requests (POST, PUT, DELETE) without a valid CSRF token|
|5|`LogoutFilter`|Handles `/logout`|
|6|**Authentication filter**|Logs you in. This is `UsernamePasswordAuthenticationFilter` for form login, `BasicAuthenticationFilter` for HTTP Basic, or `BearerTokenAuthenticationFilter` for JWT/OAuth2|
|7|`AnonymousAuthenticationFilter`|If nobody is logged in, puts a placeholder "anonymous" user in the context|
|8|`ExceptionTranslationFilter`|Catches security exceptions from later filters and turns them into a redirect, a 401, or a 403|
|9|`AuthorizationFilter`|The final gate. It checks whether this user is allowed to access this URL|

You can see your real list by turning on `logging.level.org.springframework.security=DEBUG`. Spring prints the filter list at startup and traces each request.

## Two key objects

**`SecurityContextHolder`** stores "who is the current user" for the current request. It uses a `ThreadLocal`, so each request thread has its own copy. Inside it sits an `Authentication` object.

**`Authentication`** has three main parts: the **principal** (who you are), the **credentials** (the password or token, usually erased after login), and the **authorities** (your roles and permissions). It also has an `isAuthenticated()` flag. A token before login has the flag set to false, and after login it is true.

## Flow 1: logging in (form login)

1. You POST your username and password to `/login`.
2. `UsernamePasswordAuthenticationFilter` takes them and wraps them in an **unauthenticated** `UsernamePasswordAuthenticationToken`.
3. It hands that token to the **`AuthenticationManager`** (in practice a `ProviderManager`). Think of it as a coordinator that asks its providers one by one.
4. `DaoAuthenticationProvider` does the real check:
    - It calls your **`UserDetailsService`** to load the user by username.
    - It uses the **`PasswordEncoder`** to compare the typed password with the stored hash.
5. If everything matches, you get back a fully **authenticated** token that includes your authorities.
6. The filter stores it in the `SecurityContextHolder`, and a `SecurityContextRepository` saves it (usually in the HTTP session).
7. The success handler redirects you, for example to the page you originally wanted.

If any step fails, an `AuthenticationException` leads to the failure handler, which usually redirects to `/login?error`.

## Flow 2: a normal request to a protected URL

Say you call `GET /admin/users` after logging in.

1. `SecurityContextHolderFilter` loads your context from the session, so the `Authentication` is now available.
2. Other filters (CORS, CSRF, headers) do their checks. A GET passes CSRF easily.
3. Authentication filters see you're already authenticated and have nothing more to do.
4. **`AuthorizationFilter`** asks: "Does this user have the authority required for `/admin/**`?"
    - **Yes:** the request continues to your controller.
    - **No:** it throws an `AccessDeniedException`.
5. Because **`ExceptionTranslationFilter`** sits just before the `AuthorizationFilter`, it catches that exception. This is why it is placed there.

What it does next depends on who you are:

- **Not logged in (anonymous):** it triggers the **`AuthenticationEntryPoint`**. For a web app that means a redirect to the login page, and for an API it usually means a **401**.
- **Logged in but lacking permission:** it triggers the **`AccessDeniedHandler`**, which returns a **403**.

That's the easiest way to remember 401 versus 403: _401 means "who are you?" and 403 means "I know who you are, but no."_

## Flow 3: a JWT request (stateless API)

This is the flow most people build themselves, so here it is in short:

1. The client sends `Authorization: Bearer <token>` on every request.
2. Your custom JWT filter (or `BearerTokenAuthenticationFilter`) reads the header and validates the token.
3. If it is valid, the filter builds an authenticated `Authentication` and puts it in the `SecurityContextHolder`.
4. The rest of the chain runs as in Flow 2, and `AuthorizationFilter` checks permissions.
5. Nothing is saved to a session, because the token itself proves who you are on each request.

## Writing your own filter

Extend `OncePerRequestFilter`. It guarantees your filter runs **once per request** even with forwards and error dispatches.

```java
public class JwtAuthFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            // validate the token, then build an Authentication from it
            Authentication auth = validateAndBuildAuth(token);
            SecurityContextHolder.getContext().setAuthentication(auth);
        }

        chain.doFilter(request, response); // always pass the request on
    }
}
```

Then register it in your `SecurityFilterChain`, telling Spring **where** in the order it belongs:

```java
@Bean
SecurityFilterChain api(HttpSecurity http, JwtAuthFilter jwtFilter) throws Exception {
    http
        .csrf(csrf -> csrf.disable())   // common for stateless token APIs
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/public/**").permitAll()
            .anyRequest().authenticated())
        .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
    return http.build();
}
```

`addFilterBefore`, `addFilterAfter`, and `addFilterAt` are how you place a filter relative to a built-in one.

## Common traps

- **Order is everything.** A filter placed after `AuthorizationFilter` is too late to authenticate anyone.
- **Don't also make your filter a plain `@Component`** unless you disable its auto-registration. Spring Boot registers any `Filter` bean in the main servlet chain, so it can run twice.
- **Always call `chain.doFilter(...)`** unless you deliberately want to stop the request, for example by writing a 401 yourself.
- **Debug with the logs.** The DEBUG output shows which filters ran and where a request was rejected.

## Related concepts, in short

- **CSRF:** an attack where another site tricks your logged-in browser into sending a request. The token check in `CsrfFilter` stops it. Stateless token APIs often disable it because browsers don't automatically attach a bearer token.
- **`PasswordEncoder`:** hashes passwords (for example with BCrypt) so the database never stores them in plain text.
- **Method security (`@PreAuthorize`):** permission checks on individual methods, using the same `Authentication` that the filters set up. It works at the method level, while `AuthorizationFilter` works at the URL level.

## The whole thing in one paragraph

A request enters Tomcat, passes through `DelegatingFilterProxy` into `FilterChainProxy`, which picks a `SecurityFilterChain`. Filters then run in order: load the context, check CSRF, authenticate (filling the `SecurityContextHolder`), and finally authorize. If something fails, `ExceptionTranslationFilter` turns it into a login redirect, a 401, or a 403. If everything passes, your controller finally runs.




[[Spring Security]]