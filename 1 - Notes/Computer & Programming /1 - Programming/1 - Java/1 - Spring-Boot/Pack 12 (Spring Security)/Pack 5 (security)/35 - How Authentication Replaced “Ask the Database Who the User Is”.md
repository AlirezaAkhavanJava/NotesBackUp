


 _"Before Spring Security, I would call the repository on every request to find out who the user is. Now I just receive an `Authentication`. Where did the database call go?"_

Here is the short answer. The database call **did not disappear, it moved and now happens only once**. When you log in, Spring Security calls your `UserDetailsService`, which calls your repository one time. The user that comes back is placed inside the `Authentication` object, and that object is then kept for the rest of the session (or carried inside a JWT). On every later request, Spring Security hands you the saved object, so you don't need to touch the repository just to learn _who is calling_. In this lesson we follow that single database call from login to the last request, see exactly where the user is stored in between, and learn the price you pay: the data can become **stale**.

---

## 1. The world without it (what you would write by hand)

Imagine there is no Spring Security. You would save the username in the session at login, then look the user up again on every request:

```java
@GetMapping("/orders")
List<Order> myOrders(HttpSession session) {
    String username = (String) session.getAttribute("username");           // who is calling?
    if (username == null) throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);

    User user = userRepository.findByUsername(username)                    // DATABASE HIT, every request
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

    if (!user.isActive()) throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    if (!user.getRole().equals("USER")) throw new ResponseStatusException(HttpStatus.FORBIDDEN);

    return orderRepository.findByUserId(user.getId());
}
```

Every protected endpoint repeats the same four jobs: read the session, query the user, check the flags, check the role. With Spring Security the same endpoint becomes:

```java
@GetMapping("/orders")
List<Order> myOrders(@AuthenticationPrincipal AppUser user) {
    return orderRepository.findByUserId(user.getId());
}
```

|Job|By hand|With `Authentication`|
|---|---|---|
|Find who is calling|`session.getAttribute` + repository query, every request|Already in the `SecurityContext`|
|Check active / locked|`if (!user.isActive())` in every method|Checked once at login by `DaoAuthenticationProvider`|
|Check role|`if` in every method|`@PreAuthorize` or `authorizeHttpRequests` reads the authorities|
|Database queries to identify the user|**1 per request**|**1 per login**|

---

## 2. The timeline: where the database is hit

```
REQUEST 1: POST /login   (username + password)
   UsernamePasswordAuthenticationFilter
     -> AuthenticationManager
        -> DaoAuthenticationProvider
           -> DbUserDetailsService.loadUserByUsername("ahmed")
              -> userRepository.findByUsername("ahmed")        <== the ONE database query
           <- AppUser (id, username, hash, authorities)
        <- Authentication (principal = AppUser, authorities = [ROLE_USER])
     -> stored in SecurityContext -> saved into the HTTP session
     -> response: Set-Cookie: JSESSIONID=ABC123

REQUEST 2: GET /orders   (Cookie: JSESSIONID=ABC123)
   SecurityContextHolderFilter
     -> reads the SecurityContext from the session            <== NO database query
   authorization checks use the authorities in it             <== NO database query
   controller receives @AuthenticationPrincipal AppUser       <== NO database query

REQUEST 3, 4, 5 ...: same as request 2
```

So over 100 requests in one session, identifying the user costs **1** query instead of **100**.

---

## 3. Step by step in code

### 3.1 Step one: the single database call

```java
@Service
class DbUserDetailsService implements UserDetailsService {

    private final UserRepository repo;

    DbUserDetailsService(UserRepository repo) { this.repo = repo; }

    @Override
    public UserDetails loadUserByUsername(String username) {
        UserEntity e = repo.findByUsername(username)                        // the one SELECT
            .orElseThrow(() -> new UsernameNotFoundException(username));

        return new AppUser(e.getId(), e.getUsername(), e.getPasswordHash(),
                e.isActive(), List.of(new SimpleGrantedAuthority("ROLE_" + e.getRole())));
    }
}
```

```java
public class AppUser extends User {                    // Spring's User implements UserDetails
    private final Long id;

    public AppUser(Long id, String username, String hash, boolean active,
                   Collection<? extends GrantedAuthority> authorities) {
        super(username, hash, active, true, true, true, authorities);   // enabled, nonExpired, credsNonExpired, nonLocked
        this.id = id;
    }

    public Long getId() { return id; }
}
```

This is the same `loadUserByUsername` from the `AuthenticationManager` lesson. `DaoAuthenticationProvider` calls it, checks the password, and builds the trusted `Authentication` with your `AppUser` as the principal.

### 3.2 Step two: the object goes into the `SecurityContext`

For form login, `UsernamePasswordAuthenticationFilter` does this after a successful login:

```java
SecurityContext context = securityContextHolderStrategy.createEmptyContext();
context.setAuthentication(authentication);                       // your AppUser lives inside this
securityContextHolderStrategy.setContext(context);
securityContextRepository.saveContext(context, request, response);   // <== writes it to the session
```

The default `securityContextRepository` is `HttpSessionSecurityContextRepository`. It stores the whole context in the HTTP session under a fixed key.

### 3.3 Step three: see it in the session with your own eyes

```java
@GetMapping("/debug/session")
Map<String, Object> debug(HttpSession session) {
    SecurityContext stored = (SecurityContext) session.getAttribute(
            HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY);   // "SPRING_SECURITY_CONTEXT"

    Authentication auth = stored.getAuthentication();
    return Map.of(
        "sessionId", session.getId(),
        "principalClass", auth.getPrincipal().getClass().getSimpleName(),       // AppUser
        "authorities", auth.getAuthorities().toString());
}
```

The user is literally sitting in server memory (or your session store), attached to the session id.

### 3.4 Step four: each later request restores it

```java
// Simplified from SecurityContextHolderFilter
protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) {
    Supplier<SecurityContext> deferred = repository.loadDeferredContext(request);   // reads the session lazily
    try {
        securityContextHolderStrategy.setDeferredContext(deferred);
        chain.doFilter(request, response);               // your controller runs here
    } finally {
        securityContextHolderStrategy.clearContext();    // wipes the ThreadLocal for the next request
    }
}
```

The context is loaded **lazily**: if a request never asks who the user is, the session isn't even read. There is no `UserDetailsService` call in this path. That is the "replacement".

### 3.5 Step five: use it

```java
@GetMapping("/orders")
List<Order> myOrders(@AuthenticationPrincipal AppUser user) {
    return orderRepository.findByUserId(user.getId());     // one query, for the ORDERS, not for the user
}
```

The user id came from memory. The only query is the one that fetches orders, which is the data you actually wanted.

---

## 4. Prove it: count the queries

Turn on SQL logging:

```yaml
logging:
  level:
    org.hibernate.SQL: DEBUG
spring:
  jpa:
    show-sql: false     # use the logger above instead, to avoid duplicate lines
```

Then do this in order and watch the console:

1. `POST /login`: you see **one** `select ... from users where username=?`.
2. `GET /me` five times: you see **no** user query at all.
3. `GET /orders`: you see only the `select ... from orders where user_id=?`.

You can also make it an automated check with a query counter such as Hibernate statistics (`spring.jpa.properties.hibernate.generate_statistics=true`) and assert on `getPrepareStatementCount()`.

---

## 5. The same idea with JWT (no session at all)

With a session, the user lives **on the server**. With a JWT, the user data lives **inside the token that the client sends**:

```
POST /auth/login -> loadUserByUsername -> ONE database query -> token created with
    { "sub": "ahmed", "uid": 42, "roles": ["USER"], "exp": ... }

GET /api/orders
    Authorization: Bearer <token>
       -> JwtDecoder verifies the signature            (no database)
       -> JwtAuthenticationConverter builds Authentication from the claims   (no database)
       -> controller reads jwt.getClaim("uid")         (no database)
```

```java
@GetMapping("/api/orders")
List<Order> myOrders(@AuthenticationPrincipal Jwt jwt) {
    Long userId = jwt.getClaim("uid");                       // the id you put in the token at login
    return orderRepository.findByUserId(userId);
}
```

Where is the user kept in each approach?

||Session login|JWT login|
|---|---|---|
|Who stores the user|The server (session store)|The client (inside the token)|
|Browser sends|`JSESSIONID` cookie|`Authorization: Bearer ...`|
|User object type|Your `AppUser`|`Jwt` (claims)|
|Server memory per user|Yes|None|
|Database queries per request to identify the user|0|0|
|Can you change the user's data instantly?|Yes, edit the stored object|No, wait for the token to expire|

---

## 6. The price: the saved copy gets old

Because the user is **copied at login**, it does not follow later changes in the database.

```
10:00  Ahmed logs in. AppUser says role = ADMIN, active = true.
10:05  An admin demotes Ahmed to USER and disables his account in the database.
10:06  Ahmed calls /admin/stats. The Authentication still says ROLE_ADMIN.   <== still allowed
```

What stays old and what you should do:

|Data inside the saved user|Risk if stale|What to do|
|---|---|---|
|Username, id|None (they don't change)|Safe to trust|
|Display name, avatar|Cosmetic only|Reload when needed|
|**Roles / authorities**|**Real security risk**|Short token life, or invalidate sessions on change|
|**Active / locked / banned flag**|**Real security risk**|Same, plus a check on sensitive actions|
|Password hash|Old hash is not used again|Not relevant after login|

### 6.1 Refresh the saved user after a profile change

When the user edits their own profile, update the copy in the context and save it back:

```java
@PostMapping("/profile")
void updateProfile(@RequestBody ProfileForm form,
                   @AuthenticationPrincipal AppUser current,
                   HttpServletRequest request, HttpServletResponse response) {

    userService.update(current.getId(), form);                       // database changed

    AppUser fresh = (AppUser) userDetailsService.loadUserByUsername(current.getUsername());   // read it again

    Authentication old = SecurityContextHolder.getContext().getAuthentication();
    Authentication refreshed = UsernamePasswordAuthenticationToken.authenticated(
            fresh, old.getCredentials(), fresh.getAuthorities());

    SecurityContext context = SecurityContextHolder.createEmptyContext();
    context.setAuthentication(refreshed);
    SecurityContextHolder.setContext(context);
    new HttpSessionSecurityContextRepository().saveContext(context, request, response);    // persist into the session
}
```

### 6.2 Force logout when an admin changes someone else

You can't edit another person's session directly, but you can **expire it** with a `SessionRegistry`:

```java
@Bean
SessionRegistry sessionRegistry() { return new SessionRegistryImpl(); }

@Bean
HttpSessionEventPublisher httpSessionEventPublisher() { return new HttpSessionEventPublisher(); }   // needed so the registry hears about session end
```

```java
http.sessionManagement(s -> s.maximumSessions(5).sessionRegistry(sessionRegistry()));
```

```java
void forceLogout(String username) {
    sessionRegistry.getAllPrincipals().stream()
        .filter(p -> p instanceof AppUser u && u.getUsername().equals(username))
        .flatMap(p -> sessionRegistry.getAllSessions(p, false).stream())
        .forEach(SessionInformation::expireNow);          // next request from that session is rejected
}
```

Ahmed's next request is rejected, he logs in again, and the single login query loads his new role.

### 6.3 Re-check the database only for dangerous actions

A good compromise is to trust the saved copy for normal pages and ask the database for the few actions that matter:

```java
@PostMapping("/admin/delete-user/{id}")
@PreAuthorize("hasRole('ADMIN')")                     // fast check from the saved authorities
void deleteUser(@PathVariable Long id, @AuthenticationPrincipal AppUser caller) {
    UserEntity freshCaller = userRepository.findById(caller.getId()).orElseThrow();
    if (!freshCaller.isActive() || !"ADMIN".equals(freshCaller.getRole())) {
        throw new AccessDeniedException("Your permissions changed");      // the database has the final word
    }
    userService.delete(id);
}
```

---

## 7. Mistakes that bring the database call back (or break the saved copy)

### 7.1 Putting the JPA entity itself into the principal

```java
// Risky: UserEntity inside the session
return new CustomUserDetails(userEntity);     // wraps the @Entity
```

Problems: the entity must be `Serializable` for sessions, it becomes **detached** after the request ends, and touching a lazy field later (`user.getOrders().size()`) throws `LazyInitializationException`. Copy only the simple fields you need (id, username, authorities) into a small class like `AppUser`.

### 7.2 Calling the repository just to learn the user

```java
// Unneeded: you already have the user
String name = SecurityContextHolder.getContext().getAuthentication().getName();
UserEntity u = userRepository.findByUsername(name).orElseThrow();     // extra query, every request
return orderRepository.findByUserId(u.getId());
```

Take the id from the principal instead. If you really need a _reference_ to the user entity (for example to set a `@ManyToOne` on a new order) without a `SELECT`, use:

```java
Order order = new Order();
order.setUser(userRepository.getReferenceById(user.getId()));      // a proxy, no query yet
orderRepository.save(order);
```

### 7.3 Storing too much in the principal

Session data is serialized and often sent to a store like Redis. Keep the principal small: id, username, a few flags, authorities. Not the user's whole order history.

### 7.4 Non-serializable principal

```java
java.io.NotSerializableException: com.example.AppUser
```

`UserDetails` already extends `Serializable`, but **every field inside** must be serializable too. Keep fields simple.

---

## 8. Optional: cache the login lookup itself

Even the single login query can be avoided for very busy systems by caching `loadUserByUsername`. Spring Security has a hook for this on `DaoAuthenticationProvider`:

```java
@Bean
DaoAuthenticationProvider daoProvider(UserDetailsService uds, PasswordEncoder encoder, CacheManager cacheManager) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(uds);
    provider.setPasswordEncoder(encoder);
    provider.setUserCache(new SpringCacheBasedUserCache(cacheManager.getCache("users")));
    return provider;
}
```

Use this carefully. The cache keeps a copy of the user (including the **password hash**), so a changed password or a disabled account is not noticed until you evict the entry. Evict it whenever you change the user:

```java
@CacheEvict(cacheNames = "users", key = "#username")
public void changePassword(String username, String newPassword) { ... }
```

Most apps don't need this. One query per login is cheap.

---

## 9. Keeping sessions outside one server

The saved user lives in the web server's memory by default, so a second server instance wouldn't have it, and a restart would wipe it. **Spring Session** moves the session store to Redis (which connects nicely to what you are learning next):

```xml
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

```yaml
spring:
  session:
    store-type: redis
  data:
    redis:
      host: localhost
      port: 6379
```

Nothing else changes in your code. The same `Authentication` (with your `AppUser`) is serialized into Redis, and any server instance can load it. That is also why section 7.4 matters.

---

## Related concepts, in short

- **`SecurityContextRepository`:** the strategy that saves and loads the `SecurityContext`. The default is the HTTP session. A stateless app uses `RequestAttributeSecurityContextRepository` (per request only).
- **Stateful vs stateless:** stateful means the server remembers you (session). Stateless means each request proves itself (JWT). Both avoid a per-request user query. They differ in _where_ the data waits.
- **Opaque tokens and introspection:** the token is a random string, and the resource server asks the IdP "who is this?". It is not a database hit on your side, but it is a network call, usually cached.
- **`UserDetailsChecker`:** the small object that tests the locked/disabled/expired flags at login. It runs once, which is why those flags can go stale afterward.






[[Spring Security]]