

## The map

|Class or annotation|Package|World|Its role in your filter|
|---|---|---|---|
|`HttpServletRequest`|`jakarta.servlet.http`|Servlet API|Gives you the incoming request and its headers|
|`HttpServletResponse`|`jakarta.servlet.http`|Servlet API|The outgoing response|
|`FilterChain`|`jakarta.servlet`|Servlet API|Passes the request to the next filter|
|`ServletException`|`jakarta.servlet`|Servlet API|Declared error type for servlet failures|
|`IOException`|`java.io`|Java|Declared error type for read/write failures|
|`OncePerRequestFilter`|`org.springframework.web.filter`|Spring Web|The base class your filter extends|
|`@Component`|`org.springframework.stereotype`|Spring|Makes the filter a bean|
|`@AllArgsConstructor`|`lombok`|Lombok|Writes the constructor for you|
|`UserDetails`|`...security.core.userdetails`|Spring Security|One user's data|
|`UserDetailsService`|`...security.core.userdetails`|Spring Security|Loads a user by name|
|`Authentication`|`...security.core`|Spring Security|"Who is logged in right now"|
|`UsernamePasswordAuthenticationToken`|`...security.authentication`|Spring Security|The ready-made `Authentication` you create|
|`WebAuthenticationDetailsSource`|`...security.web.authentication`|Spring Security|Collects request details (IP, session)|
|`SecurityContextHolder`|`...security.core.context`|Spring Security|Where the current `Authentication` is stored|
|`UsernamePasswordAuthenticationFilter`|`...security.web.authentication`|Spring Security|Imported but **not used** in this file|
|`JwtService`|`com.example.demo.service`|Your code|Reads and checks the token|

## World 1: The Servlet API

These classes belong to the layer underneath Spring. Tomcat creates the request and response objects and hands them down through every filter, so you receive them as parameters.

### `HttpServletRequest`

This object represents the incoming HTTP request. You read things from it and never create one yourself. The methods you will use most:

|Method|Returns|Example use|
|---|---|---|
|`getHeader("Authorization")`|The header value, or `null` if absent|Reading the Bearer header|
|`getRequestURI()`|The path, like `/api/me`|Skipping login paths|
|`getMethod()`|`GET`, `POST`, and so on|Treating `OPTIONS` differently|
|`getRemoteAddr()`|The client's IP|Auditing|
|`getCookies()`|An array of cookies|Reading a token from a cookie|

Header names are not case-sensitive, so `"authorization"` and `"Authorization"` find the same header. A missing header gives `null`, which is why your code checks for `null` before calling `startsWith`. Note the package is `jakarta.servlet`. Spring Boot 2 and older used `javax.servlet`, and old tutorials still show that name.

### `HttpServletResponse`

This is the reply going back to the client. A normal filter leaves it alone and lets the controller fill it in. You write to it directly only when you want to stop the request early:

```java
response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);   // 401
response.setContentType("application/json");
response.getWriter().write("{\"error\":\"Unauthorized\"}");
```

`SC_UNAUTHORIZED` is a constant for `401`. Your filter doesn't write anything right now, but the parameter is part of the method signature, and you pass it on to the next filter.

### `FilterChain`

This is the most important class in your filter. It represents **everything that comes after you**: the remaining filters and finally your controller. It has one method:

```java
filterChain.doFilter(request, response);
```

|What you do|What happens|
|---|---|
|Call `doFilter`|The next filter runs, and eventually the controller|
|Don't call it|The request stops in your filter|

Code placed after the `doFilter` call runs when the response is coming back. You rarely need that for JWT.

### `ServletException` and `IOException`

Your method signature says `throws ServletException, IOException`. These are the two checked exceptions that `doFilter` can throw.

- `ServletException` is the servlet API's general "something went wrong while handling this request" error.
- `IOException` means reading the request or writing the response failed, for example when the client disconnected.

You don't catch them. You only declare them so the code compiles, and the web server turns them into an error response.

## World 2: Spring Web and Lombok

### `OncePerRequestFilter`

This is an abstract base class that your filter extends. A plain servlet `Filter` can run more than once for the same request, for example during an internal forward or an error dispatch. `OncePerRequestFilter` marks the request after the first run and skips repeats. It also lets you write a simple method, `doFilterInternal`, instead of the raw `doFilter`.

|Method|You...|Purpose|
|---|---|---|
|`doFilterInternal(req, res, chain)`|**must** implement it|Your filter logic|
|`shouldNotFilter(request)`|may override it|Skip some paths entirely|

A useful override, which skips your filter for login and register:

```java
@Override
protected boolean shouldNotFilter(HttpServletRequest request) {
    return request.getRequestURI().startsWith("/api/auth/");
}
```

### `@Component`

This marks the class as a Spring bean, so Spring creates one instance at startup and can inject it into `SecurityConfig`. Without it, `SecurityConfig` could not receive the filter through its constructor.

### `@AllArgsConstructor` (Lombok)

Lombok is a library that writes repetitive code during compilation. This annotation generates a constructor with one parameter per field. For your class it produces the equivalent of:

```java
public JwtAuthenticationFilter(JwtService jwtService,
                               UserDetailsService userDetailsService) {
    this.jwtService = jwtService;
    this.userDetailsService = userDetailsService;
}
```

Spring sees one constructor and uses it for injection automatically, so you don't need `@Autowired`. Many developers prefer `@RequiredArgsConstructor`, which only includes `final` fields. Both give the same result here, but `@RequiredArgsConstructor` stays correct if you later add a non-final field. Your IDE needs the Lombok plugin and annotation processing turned on, or it will show errors even though Maven builds fine.

## World 3: Spring Security

### `UserDetails`

This interface is Spring Security's description of **one user**. Your database entity isn't this type, so you convert it (usually in `UserDetailsService`).

|Method|Meaning|
|---|---|
|`getUsername()`|The login name|
|`getPassword()`|The stored (hashed) password|
|`getAuthorities()`|The roles and permissions, like `ROLE_ADMIN`|
|`isEnabled()`|`false` blocks login|
|`isAccountNonLocked()`|`false` means the account is locked|
|`isAccountNonExpired()`|`false` means the account has expired|
|`isCredentialsNonExpired()`|`false` means the password must be changed|

In the filter, `userDetails.getAuthorities()` supplies the roles that later rules like `hasRole("ADMIN")` check.

### `UserDetailsService`

This interface has one method:

```java
UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
```

You write a class that implements it, usually by querying your repository. Your filter receives it by injection and calls it to get the user for the username found in the token. If the user doesn't exist, it throws `UsernameNotFoundException`, which your filter should handle.

### `Authentication`

This is Spring Security's answer to "who is making this request?" It holds:

|Method|In your filter|
|---|---|
|`getPrincipal()`|The `UserDetails` object|
|`getCredentials()`|`null`, because the token was the proof|
|`getAuthorities()`|The user's roles|
|`getDetails()`|The IP and session info|
|`isAuthenticated()`|`true`|

In your code, `Authentication authentication = SecurityContextHolder.getContext().getAuthentication();` reads the current value. If it is `null`, nobody has been authenticated for this request yet.

### `UsernamePasswordAuthenticationToken`

This is the ready-made class that implements `Authentication`. Despite its name, it isn't only for passwords. It has two constructors that mean different things:

|Constructor|Meaning|
|---|---|
|`new ...Token(username, password)`|**Not yet authenticated**: a login attempt waiting to be checked|
|`new ...Token(principal, credentials, authorities)`|**Already authenticated**: the proof has been verified|

Your filter uses the three-argument form, `(userDetails, null, userDetails.getAuthorities())`, because the JWT check has already succeeded. Using the two-argument form here would leave the token marked as unauthenticated, and your rules would reject the request.

### `WebAuthenticationDetailsSource`

This small class collects extra facts about the request:

```java
authenticationToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
```

`buildDetails(request)` returns a `WebAuthenticationDetails` object holding the client's IP (`getRemoteAddress()`) and the session id (`getSessionId()`). The line is optional. Security works without it, but it is useful for audit logs.

### `SecurityContextHolder`

This is a static holder for the `SecurityContext`, which in turn holds the current `Authentication`. By default it stores the context in a **thread-local**, so each request thread has its own.

|Call|What it does|
|---|---|
|`SecurityContextHolder.getContext()`|Returns the context for this thread|
|`.getAuthentication()`|Reads the current user (or `null`)|
|`.setAuthentication(auth)`|Stores the user, so later filters and controllers can see it|
|`SecurityContextHolder.clearContext()`|Removes it|

This is the handoff point of your whole filter. After you call `setAuthentication`, the `AuthorizationFilter` and your controllers can see who the user is.

### `UsernamePasswordAuthenticationFilter`

This class is imported in your file but **never used there**. It is Spring Security's built-in filter for form login. It appears in your `SecurityConfig` instead, in the line `addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)`. That line uses it as a landmark: "put my filter just before this one." You can delete the import from the filter file, and your IDE shows it grayed out.

## World 4: Your own `JwtService`

Your filter calls two of its methods:

|Method|Purpose|
|---|---|
|`extractUserName(...)`|Verifies the token's signature and reads the `sub` claim|
|`isTokenValid(jwt, userDetails)`|Checks that the token belongs to this user and hasn't expired|

The filter doesn't know how a JWT works. It only asks `JwtService` two questions, which keeps the crypto in one place.

## How the classes work together, line by line

```java
final String authorizationHeader = request.getHeader("Authorization");   // HttpServletRequest
```

Reads the Bearer header, or `null`.

```java
if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer")) {
    filterChain.doFilter(request, response);                              // FilterChain
    return;
}
```

No token means this isn't an authenticated request, so the filter hands over and stops.

```java
final String jwt = authorizationHeader.substring(7);
final String username = jwtService.extractUserName();                     // JwtService
```

Cuts off the prefix and reads the username from the token.

```java
Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
if (username != null && authentication == null) {                         // SecurityContextHolder
```

Only continues if there is a username and nobody is authenticated yet.

```java
UserDetails userDetails = userDetailsService.loadUserByUsername(username);   // UserDetailsService
if (jwtService.isTokenValid(jwt, userDetails)) {
```

Loads the real user and checks the token against them.

```java
UsernamePasswordAuthenticationToken authenticationToken =
        new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
authenticationToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
SecurityContextHolder.getContext().setAuthentication(authenticationToken);
```

Builds the "already authenticated" object, adds the request details, and stores it.

## Three bugs in the pasted code

1. **The final `filterChain.doFilter(request, response);` is missing.** After storing the authentication, the method ends and the request never reaches your controller. The client gets an empty `200` response. This is the most serious one.
2. **`jwtService.extractUserName()` has no argument.** Unless your method really takes no parameter, it needs the token: `extractUserName(jwt)`. Without it, the service has nothing to read.
3. **`startsWith("Bearer")` has no trailing space.** Then `substring(7)` assumes `"Bearer "` is 7 characters. A header like `BearerXYZ` passes the check and produces a broken token. Use `"Bearer "`.

There is also a robustness gap. A forged, expired or malformed token makes `extractUserName` throw `JwtException`, and the same happens when the user doesn't exist. Exceptions thrown inside a filter don't reach `@ControllerAdvice`, so the client would get a raw error. Catch them and let the request continue unauthenticated.

## The corrected filter

```java
@AllArgsConstructor
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        final String authorizationHeader = request.getHeader("Authorization");

        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authorizationHeader.substring(7);

        try {
            final String username = jwtService.extractUserName(jwt);

            if (username != null
                    && SecurityContextHolder.getContext().getAuthentication() == null) {

                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                if (jwtService.isTokenValid(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authenticationToken =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails, null, userDetails.getAuthorities());
                    authenticationToken.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContext context = SecurityContextHolder.createEmptyContext();
                    context.setAuthentication(authenticationToken);
                    SecurityContextHolder.setContext(context);
                }
            }
        } catch (JwtException | IllegalArgumentException | UsernameNotFoundException e) {
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
```

What changed: the missing `doFilter` is added, the token is passed to `extractUserName`, the prefix check has its space, and bad tokens are caught. The context is also built with `createEmptyContext()` and `setContext(...)`. This is the pattern the Spring Security documentation recommends, because it avoids modifying a context object that another thread might share. The old `getContext().setAuthentication(...)` works too, but this form is safer. Add `SecurityContext`, `JwtException` and `UsernameNotFoundException` to your imports, and remove the unused `UsernamePasswordAuthenticationFilter` import.

## A related concept: `Filter` vs `OncePerRequestFilter` vs `GenericFilterBean`

The servlet API defines a plain `Filter` interface with a raw `doFilter` method. Spring adds `GenericFilterBean`, which gives a filter access to its Spring configuration, and `OncePerRequestFilter` extends that and adds the "run only once per request" guarantee plus `doFilterInternal`. For any filter that reads the request and sets security state, `OncePerRequestFilter` is the right base class. A plain `Filter` is only worth it when you need to run on every internal dispatch.





[[Spring Security]]