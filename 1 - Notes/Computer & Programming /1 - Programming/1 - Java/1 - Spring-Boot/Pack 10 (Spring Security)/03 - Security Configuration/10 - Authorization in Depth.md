

## The problem it solves

Authentication told you **who** is calling. Authorization answers the next question: **are they allowed to do this?**

A logged-in user is not a trusted user. Alice is authenticated, but she must not read Bob's orders, delete products, or open the admin panel. Without authorization rules, "logged in" means "can do anything." In practice, broken access control has topped the OWASP Top 10 list for years, because a rule is easy to forget on just one endpoint.

> Authentication proves identity. Authorization decides what that identity may touch.

## The picture: a hotel key card

|Hotel|Spring Security|
|---|---|
|The front desk checks your ID once|**Authentication** (the last lesson)|
|The card they hand you|The `Authentication` object with its **authorities**|
|The card opens your room, the gym, the lobby|Rules like `hasRole("USER")`|
|It doesn't open the staff office or other guests' rooms|`hasRole("ADMIN")`, ownership checks|
|Each door has its own reader|Checks at **several layers**: URL, method, data|
|A door can stay locked even if your card is valid|Rules can depend on **more than the card**: time, ownership, IP|

## The map

```
Part 1:  Where authorization happens        (the layers)
Part 2:  The vocabulary                     (authorities, roles, decisions)
Part 3:  URL rules                          (authorizeHttpRequests)
Part 4:  Method rules                       (@PreAuthorize and friends)
Part 5:  Ownership: "only MY data"          (the most important part)
Part 6:  Designing roles and permissions    (with PostgreSQL)
Part 7:  Writing your own rules             (AuthorizationManager)
Part 8:  What the client sees when denied
Part 9:  Views, JWT scopes, stale permissions
Part 10: Testing
Part 11: Try it yourself
```

---

# Part 1: Where authorization happens

You already know the request path. Authorization can run at **four different layers**:

```
Request
  │
  ▼
Security filters ── AuthorizationFilter   URL rules    "May you reach /admin/**?"
  │
  ▼
DispatcherServlet
  │
  ▼
Controller  ◀── method security proxy     Method rules "May you call deleteOrder()?"
  │
  ▼
Service     ◀── method security proxy     Method rules (again, closer to the logic)
  │
  ▼
Repository ──── your query                Data rules   "Only rows that belong to YOU"
```

|Layer|Good at|Blind to|
|---|---|---|
|**URL rules**|Whole sections of the site (`/admin/**`)|Which _object_ you're touching|
|**Method rules**|Protecting logic however it's reached (web, scheduler, message)|Rows not yet loaded|
|**Data rules**|"Only my rows"|Nothing, but you write them by hand|

Real apps use **all of them**. This is defense in depth. If a URL rule has a typo, the method rule still protects the service.

---

# Part 2: The vocabulary

## Authorities and roles

An **authority** is a string that says what someone may do. `Authentication.getAuthorities()` returns a list of them.

|Kind|Example|What it means|
|---|---|---|
|**Role**|`ROLE_ADMIN`|A broad hat ("I am an admin"). An authority that starts with `ROLE_`.|
|**Permission**|`orders:delete`|One specific action|

The prefix rule is the source of many bugs:

|You write|Spring checks for the authority|
|---|---|
|`hasRole("ADMIN")`|`ROLE_ADMIN` (prefix added for you)|
|`hasAuthority("ROLE_ADMIN")`|`ROLE_ADMIN` (exactly as written)|
|`hasAuthority("orders:delete")`|`orders:delete`|
|`hasRole("ROLE_ADMIN")`|**Error.** Spring refuses roles that already start with `ROLE_`.|

## Decisions

Every rule is evaluated by an **`AuthorizationManager`**. It looks at the current `Authentication` and the thing being accessed, then answers with an **`AuthorizationDecision`**: granted or denied. A denial becomes an **`AccessDeniedException`**, which you met in the filter-chain lesson.

```java
@FunctionalInterface
public interface AuthorizationManager<T> {
    AuthorizationDecision check(Supplier<Authentication> authentication, T object);
}
```

- `T` is what's being protected: an HTTP request for URL rules, a method call for method rules.
- The authentication comes as a **`Supplier`**, so it's loaded **lazily**. A `permitAll()` rule never needs to read the session at all.
- In newer versions (6.4 and later), this method is being renamed `authorize(...)` and returns an `AuthorizationResult`. The idea is the same. Lambdas that return `new AuthorizationDecision(...)` work in both, so check your version before writing a full class.

## Role hierarchies

Often an admin should be able to do everything a staff member can, and staff everything a user can. A **role hierarchy** says that once instead of repeating it on every rule:

```java
@Bean
static RoleHierarchy roleHierarchy() {
    return RoleHierarchyImpl.withDefaultRolePrefix()
            .role("ADMIN").implies("STAFF")
            .role("STAFF").implies("USER")
            .build();
}
```

- `withDefaultRolePrefix()` means the names get `ROLE_` added automatically.
- `.role("ADMIN").implies("STAFF")` reads as "ADMIN includes STAFF."
- The method is `static` because the bean is needed early, during method security setup.
- This builder is from 6.3 and later. Older versions use `setHierarchy("ROLE_ADMIN > ROLE_STAFF")`. In recent versions, a `RoleHierarchy` bean is picked up by both URL and method rules. Older ones need extra wiring, so confirm for your version.

---

# Part 3: URL rules

This is the `AuthorizationFilter` from the filter-chain lesson:

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/public/**", "/error").permitAll()
    .requestMatchers(HttpMethod.DELETE, "/orders/**").hasRole("ADMIN")
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .requestMatchers("/reports/**").hasAnyAuthority("reports:read", "ROLE_ADMIN")
    .anyRequest().authenticated());
```

Line by line:

- `permitAll()` lets everyone through the **gate**. The request still passes **every filter** (CSRF, headers, and so on).
- `requestMatchers(HttpMethod.DELETE, "/orders/**")` matches **only DELETE** requests. Rules without a method match all methods, which is a common source of holes (see mistakes).
- `hasAnyAuthority(...)` accepts either one.
- `anyRequest().authenticated()` is the catch-all. Rules are checked **top to bottom, and the first match wins**, so specific rules go first and general ones last.

## The rule methods

|Method|Allows|
|---|---|
|`permitAll()`|Everyone, including anonymous|
|`denyAll()`|Nobody|
|`authenticated()`|Anyone not anonymous (remember-me included)|
|`fullyAuthenticated()`|Authenticated, **not** via remember-me|
|`hasRole("X")` / `hasAnyRole(...)`|`ROLE_X`|
|`hasAuthority("p")` / `hasAnyAuthority(...)`|An exact authority string|
|`access(manager)`|Your own logic (Part 7)|

## Default deny

If **no rule matches**, access is **denied**. Use that. A strong pattern is a **whitelist**:

```java
.requestMatchers("/public/**", "/login", "/error").permitAll()
.requestMatchers("/admin/**").hasRole("ADMIN")
.anyRequest().authenticated()      // or .denyAll() for the strictest setup
```

New endpoints are then protected by default, and you open things on purpose.

## Matching details that bite

|Detail|What to know|
|---|---|
|`**`|`/admin/**` matches `/admin`, `/admin/x`, and `/admin/x/y`|
|Matching style|With Spring MVC, `requestMatchers(...)` follows MVC's own path rules. That's deliberate: the security rule and the controller must **agree** on which URL is which.|
|Trailing slash|In current Spring versions, `/orders` and `/orders/` are **different** URLs for MVC. Don't assume they're the same.|
|Case|Matching is case-sensitive.|
|Methods|Always think about **each** method (GET, POST, PUT, DELETE) on a path.|
|Error dispatch|`AuthorizationFilter` also checks the **error** dispatch, so `/error` needs `permitAll()`, or real 500s turn into confusing 401/403 responses.|
|Old tutorials|`antMatchers` and `mvcMatchers` are gone. Use `requestMatchers`.|

## URL rules that look inside the request

Path variables are available to expressions:

```java
.requestMatchers("/users/{name}/**")
    .access(new WebExpressionAuthorizationManager("#name == authentication.name or hasRole('ADMIN')"))
```

- `{name}` becomes `#name` inside the expression.
- `authentication.name` is the logged-in user's name.
- So users can reach their own `/users/alice/...` URLs, and admins can reach anyone's.

An expression that checks the caller's IP address works too:

```java
.requestMatchers("/actuator/**")
    .access(new WebExpressionAuthorizationManager("hasRole('ADMIN') and hasIpAddress('10.0.0.0/8')"))
```

Be careful with IP rules behind a proxy. The address Spring sees depends on your forwarded-headers settings (the networking lesson), and a client-supplied `X-Forwarded-For` header must never be trusted.

---

# Part 4: Method rules

## The problem it solves

URL rules protect **doors**, but the same service method may be reached from a controller, a scheduled job, and a message listener. A URL rule can't guard all of those. **Method security** puts the check on the method itself.

It works through a **proxy**: Spring wraps your bean in an object that runs the check before (or after) calling the real method.

```
caller → [proxy: check the rule] → your real method
              │
              └─ denied → AccessDeniedException (your code never runs)
```

## Turn it on

```java
@Configuration
@EnableMethodSecurity
public class MethodSecurityConfig { }
```

**If you forget this, every annotation below is silently ignored.** No error, no warning, just an open door. Always test that denial actually happens (Part 10). `@EnableMethodSecurity` replaces the old `@EnableGlobalMethodSecurity`, which old tutorials still show.

## The annotations

|Annotation|Runs|Enabled by default?|Uses|
|---|---|---|---|
|`@PreAuthorize("expr")`|**Before** the method|Yes|Most checks|
|`@PostAuthorize("expr")`|**After**, can see `returnObject`|Yes|"Is this result mine?"|
|`@PreFilter("expr")`|Filters an **input** collection|Yes|Trim a list of arguments|
|`@PostFilter("expr")`|Filters the **returned** collection|Yes|Hide rows the user can't see|
|`@Secured("ROLE_X")`|Before, simple authority names only|No (`securedEnabled = true`)|Legacy|
|`@RolesAllowed("ADMIN")`|Before, standard Java annotation|No (`jsr250Enabled = true`)|Legacy, portable|

Use `@PreAuthorize` and `@PostAuthorize` for new code. Note that `@Secured` needs the **full** authority (`@Secured("ROLE_ADMIN")`), while `@RolesAllowed("ADMIN")` adds the prefix itself.

## What you can write in the expression (SpEL)

The expression language is **SpEL** (Spring Expression Language).

|Expression|Meaning|
|---|---|
|`hasRole('ADMIN')`, `hasAnyRole('A','B')`|Role checks (prefix added)|
|`hasAuthority('orders:read')`|Exact authority|
|`isAuthenticated()`, `permitAll()`, `denyAll()`|The usual|
|`authentication`|The whole `Authentication` object|
|`principal`|Its principal (your `UserDetails`, or `AppPrincipal`)|
|`#userId`|The method's own parameter named `userId`|
|`returnObject`|The return value (`@PostAuthorize` only)|
|`filterObject`|One element (`@PreFilter` / `@PostFilter`)|
|`@beanName.method(...)`|Call a method on any Spring bean|
|`and`, `or`, `!`|Combine conditions|

`#userId` works only when parameter names are available. Spring Boot's build tooling compiles with `-parameters` by default. If your names are missing, use `@P("userId")` on the parameter.

## Examples

```java
@Service
public class OrderService {

    @PreAuthorize("hasRole('ADMIN')")
    public void deleteAll() { ... }

    @PreAuthorize("hasAuthority('orders:read')")
    public List<Order> listAll() { ... }

    @PreAuthorize("#username == authentication.name or hasRole('ADMIN')")
    public List<Order> ordersOf(String username) { ... }

    @PostAuthorize("returnObject.owner() == authentication.name or hasRole('ADMIN')")
    public Order find(long id) { ... }
}
```

Line by line:

- `deleteAll` is limited to admins.
- `listAll` needs one specific permission instead of a role.
- `ordersOf` lets you read your own orders, and lets admins read anyone's. `#username` is the parameter, and `authentication.name` is the logged-in user.
- `find` loads the order first, then checks that the **result** belongs to the caller. We write `returnObject.owner()` because `Order` is a Java record. Records expose `owner()` rather than `getOwner()`, so we call it as a method.

### Two annotations on one class

You can put `@PreAuthorize` on a class to apply it to every method, and a method-level annotation **replaces** it for that method:

```java
@PreAuthorize("hasRole('USER')")
@Service
public class ProfileService {
    public Profile mine() { ... }

    @PreAuthorize("hasRole('ADMIN')")
    public void delete(long id) { ... }
}
```

### Your own readable annotation

```java
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("hasRole('ADMIN')")
public @interface IsAdmin { }
```

Now write `@IsAdmin` instead of repeating the expression. If the rule changes, you change it once.

## `@PostFilter` and `@PreFilter`

```java
@PostFilter("filterObject.owner() == authentication.name or hasRole('ADMIN')")
public List<Order> listAll() { return repo.findAll(); }
```

This loads **every** order and **then** throws away the ones you can't see. It's correct but wasteful. With a million rows, you've read a million rows to show ten. For large tables, put the rule into the **query** instead (Part 5).

## The gotchas of proxies

|Gotcha|What happens|Fix|
|---|---|---|
|**Self-invocation**|`this.adminOnly()` called from another method in the **same class** skips the proxy, so no check|Move the protected method to another bean|
|**`private` or `final` methods**|Proxies can't intercept them|Make them public and non-final|
|**`@PostAuthorize` runs after the method**|A delete method that **already deleted** the row and then fails the check has done its damage|Use `@PreAuthorize` for anything that changes data|
|**Annotation on a controller only**|A scheduler or listener that calls the service directly skips it|Protect the service layer too|
|**Annotation on a class not managed by Spring**|`new OrderService()` has no proxy|Always inject beans|
|**A catch-all `@ExceptionHandler(Exception.class)`**|It catches `AccessDeniedException` and answers **500** instead of 403|Handle `AccessDeniedException` separately, or rethrow it|

That last one is a genuine trap. A method-security denial is thrown **inside** the DispatcherServlet, so your `@RestControllerAdvice` sees it, unlike URL-level denials, which happen earlier in the filters. Add this to your advice class:

```java
@ExceptionHandler(AccessDeniedException.class)
public void rethrow(AccessDeniedException e) {
    throw e;
}
```

- Rethrowing sends the exception back out to `ExceptionTranslationFilter`, which turns it into the correct 403 (or a login redirect for anonymous users).

---

# Part 5: Ownership, "only MY data"

## The problem it solves

This is the most common real-world authorization bug. Imagine:

```java
@GetMapping("/orders/{id}")
public Order get(@PathVariable long id) { return repo.findById(id).orElseThrow(); }
```

Alice is logged in, so she passes the URL rule. She changes `/orders/1` to `/orders/2` and reads **Bob's order**. Nobody hacked anything. The code simply never asked "does this order belong to you?" This flaw is called **IDOR** (Insecure Direct Object Reference), or **BOLA** (Broken Object Level Authorization) in API security.

URL rules and roles **cannot fix this**, because both Alice and Bob have the same role. You need a rule that looks at the **object**.

## Four ways to do it

### Way 1: Put the owner in the query (best when possible)

```java
public interface OrderRepository extends JpaRepository<Order, Long> {
    Optional<Order> findByIdAndOwnerUsername(Long id, String ownerUsername);
    List<Order> findByOwnerUsername(String ownerUsername);
}
```

```java
@GetMapping("/orders/{id}")
public Order get(@PathVariable long id, Authentication auth) {
    return repo.findByIdAndOwnerUsername(id, auth.getName())
               .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
}
```

- The other person's row is **never loaded**, so it can't leak by accident.
- Someone else's order and a non-existent order give the **same 404**. The attacker can't even tell which IDs exist. That's a nice side effect.
- It also scales, because the database does the filtering.

### Way 2: `@PostAuthorize` on the result

```java
@PostAuthorize("returnObject.owner() == authentication.name or hasRole('ADMIN')")
public Order find(long id) { return repo.findById(id).orElseThrow(); }
```

Simple, and it keeps the rule beside the method. The trade-off is that the row is loaded first, and the method has run. Fine for reads.

### Way 3: `@PreAuthorize` calling a bean

```java
@Component("orderAccess")
public class OrderAccess {

    private final OrderRepository repo;

    public OrderAccess(OrderRepository repo) { this.repo = repo; }

    public boolean isOwner(long orderId, String username) {
        return repo.existsByIdAndOwnerUsername(orderId, username);
    }
}
```

```java
@PreAuthorize("@orderAccess.isOwner(#id, authentication.name) or hasRole('ADMIN')")
public void cancel(long id) { ... }
```

Line by line:

- `@Component("orderAccess")` gives the bean a name that SpEL can use after `@`.
- `isOwner` does a cheap `exists` query and returns a boolean.
- The expression runs **before** the method, so a `cancel` for someone else's order never starts. This is the right choice for **writes**.
- The rule is plain Java, so you can unit test it without Spring.

### Way 4: A `PermissionEvaluator`

If you prefer the expression `hasPermission(#id, 'Order', 'cancel')`, implement `PermissionEvaluator` and register it through a `MethodSecurityExpressionHandler` bean. It gives one central place for object rules. For small apps, Way 3 is simpler.

## The principle behind all four

> **Never trust an ID that came from the client.** The URL, the JSON body, and the query string are all attacker-controlled. Check the object against the **server-side** identity (`authentication`).

A related danger is **mass assignment**: you bind JSON straight into an entity, and the client sends `{"role":"ADMIN"}` or `{"ownerId": 7}`. Use separate request classes (DTOs) that contain only the fields a user may set, and set the owner from `authentication`, never from the body.

---

# Part 6: Designing roles and permissions

## The problem it solves

Starting with three roles (`USER`, `STAFF`, `ADMIN`) is fine. But soon the question is "staff can refund orders, except large ones," and role names like `STAFF_WHO_CAN_REFUND` multiply. The usual cure is two layers:

|Layer|Meaning|Example|
|---|---|---|
|**Roles**|What people **are** (change rarely)|`ADMIN`, `SUPPORT`|
|**Permissions**|What the system lets you **do** (checked in code)|`orders:read`, `orders:refund`|
|**Mapping**|Which roles grant which permissions (data, editable)|`SUPPORT` → `orders:read`, `orders:refund`|

Code checks **permissions** (`hasAuthority('orders:refund')`), so adding a new role never means changing code.

## Tables (PostgreSQL)

```sql
create table role_permission (
    role       varchar(30) not null,
    permission varchar(60) not null,
    primary key (role, permission)
);

insert into role_permission values
  ('USER',    'orders:read'),
  ('SUPPORT', 'orders:read'),
  ('SUPPORT', 'orders:refund'),
  ('ADMIN',   'orders:read'),
  ('ADMIN',   'orders:refund'),
  ('ADMIN',   'users:manage');
```

This sits next to the `app_user` and `app_user_role` tables from the authentication lesson.

## Building the authorities at login

Inside your `UserDetailsService`:

```java
Set<GrantedAuthority> authorities = new HashSet<>();
for (String role : u.getRoles()) {
    authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
    for (String permission : permissionRepo.permissionsOf(role)) {
        authorities.add(new SimpleGrantedAuthority(permission));
    }
}
```

- Each role becomes `ROLE_<name>`, for broad URL rules.
- Each permission is added **as written**, for fine-grained method rules.
- A `HashSet` removes duplicates when two roles grant the same permission.

Then your rules read like sentences:

```java
@PreAuthorize("hasAuthority('orders:refund')")
public void refund(long orderId) { ... }
```

## Freshness warning

Authorities are collected **once, at login**, and stored in the session (or inside a JWT). Changing a role in the database does **not** change anyone who is already logged in. Plan for it:

|Event|What to do|
|---|---|
|An admin removes someone's role|Expire that user's sessions with `SessionRegistry` (the sessions lesson)|
|Using JWTs|Keep access tokens short, so the stale window is small|
|Very sensitive checks|Re-check the database inside the method instead of trusting the token|

---

# Part 7: Writing your own rules

When a rule doesn't fit `hasRole`, you write an **`AuthorizationManager`**.

## A URL rule: "owner or admin" for `/accounts/{id}/**`

```java
.requestMatchers("/accounts/{id}/**").access((authSupplier, context) -> {
    Authentication auth = authSupplier.get();
    String id = context.getVariables().get("id");

    boolean admin = auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    boolean owner = auth.getPrincipal() instanceof AppPrincipal p
            && String.valueOf(p.getId()).equals(id);

    return new AuthorizationDecision(admin || owner);
})
```

Line by line:

- `.access(...)` takes an `AuthorizationManager`. A lambda is enough, because the interface has a single method.
- `authSupplier.get()` loads the current `Authentication` (this is the lazy `Supplier` from Part 2).
- `context.getVariables().get("id")` reads the `{id}` from the URL path.
- `AppPrincipal` is the principal class from the authentication lesson, which carries the database id. For an **anonymous** user the principal is just a string, so the `instanceof` check is false and the rule denies.
- `new AuthorizationDecision(true or false)` is the verdict.

## A reusable manager class

```java
public class BusinessHoursManager implements AuthorizationManager<RequestAuthorizationContext> {

    private final Clock clock;

    public BusinessHoursManager(Clock clock) { this.clock = clock; }

    @Override
    public AuthorizationDecision check(Supplier<Authentication> auth,
                                       RequestAuthorizationContext ctx) {
        LocalTime now = LocalTime.now(clock);
        boolean open = !now.isBefore(LocalTime.of(8, 0)) && now.isBefore(LocalTime.of(18, 0));
        return new AuthorizationDecision(open);
    }
}
```

- It receives a `Clock` instead of calling the system time directly, so tests can pass a fixed clock.
- It's registered like the lambda: `.requestMatchers("/payroll/**").access(new BusinessHoursManager(clock))`.
- In the newest versions, rename the method to `authorize(...)` as noted in Part 2.

To combine managers (for example "must be HR **and** within business hours"), Spring provides `AuthorizationManagers.allOf(...)` and `anyOf(...)` in recent versions.

## A method rule from your own bean

Part 5, Way 3 is already this. Any Spring bean can be a rule, which makes SpEL a thin wrapper around plain Java. If a rule is more than one line of SpEL, move it into a bean. SpEL strings have no compiler to catch typos, and Java code does.

---

# Part 8: What the client sees when denied

Both URL and method denials throw `AccessDeniedException`. `ExceptionTranslationFilter` then decides the response based on **who** is asking:

|Who was denied|Response|Handled by|
|---|---|---|
|**Anonymous** (not logged in)|Redirect to login (form), or **401** (Basic or bearer)|`AuthenticationEntryPoint`|
|**Authenticated**, not allowed|**403 Forbidden**|`AccessDeniedHandler`|

For a JSON API, customize both:

```java
http.exceptionHandling(e -> e
    .authenticationEntryPoint((req, res, ex) -> {
        res.setStatus(401);
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"login required\"}");
    })
    .accessDeniedHandler((req, res, ex) -> {
        res.setStatus(403);
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"not allowed\"}");
    }));
```

Choosing between 403 and 404 is a design decision:

|Choice|Good|Cost|
|---|---|---|
|**403** for someone else's object|Honest and easy to debug|Tells attackers "that ID exists"|
|**404** for someone else's object|Hides which IDs exist|Slightly harder to debug|

The query-based approach (Part 5, Way 1) gives you the 404 behavior for free. Keep error bodies short: never echo the expression or the authorities back to the client.

---

# Part 9: Views, JWT scopes, and stale permissions

## Hiding buttons is not security

Thymeleaf can hide parts of a page by role (add `thymeleaf-extras-springsecurity6`):

```html
<a th:href="@{/admin}" sec:authorize="hasRole('ADMIN')">Admin panel</a>
<span sec:authentication="name">user</span>
```

This only improves the **experience**. Anyone can call the URL directly with `curl`, so the **server-side rule must exist anyway**. Treat hidden buttons as decoration.

## Authorization with JWTs

From the JWT lesson: the `Authentication` is built from the token's claims, and the same rules then apply. Mapping matters:

|Token claim|Becomes authorities|Rule you write|
|---|---|---|
|`scope: "orders.read orders.write"`|`SCOPE_orders.read`, `SCOPE_orders.write` (default)|`hasAuthority('SCOPE_orders.read')`|
|`roles: ["ADMIN"]` (custom)|Whatever you configure with `JwtGrantedAuthoritiesConverter`|`hasRole('ADMIN')`|

```java
JwtGrantedAuthoritiesConverter granted = new JwtGrantedAuthoritiesConverter();
granted.setAuthoritiesClaimName("roles");
granted.setAuthorityPrefix("ROLE_");

JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
converter.setJwtGrantedAuthoritiesConverter(granted);
```

- It reads the `roles` claim and prefixes each value with `ROLE_`. Pass it in with `oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(converter)))`.
- **Scopes** describe what a _client app_ may do on behalf of a user (OAuth2 delegation). **Roles** describe what the _user_ is. Keep the two ideas apart: a user who is an admin, using an app granted only `orders.read`, should only be able to read orders.
- Claims are **frozen until the token expires**, so keep access tokens short.

---

# Part 10: Testing authorization

Authorization bugs are silent: the wrong request succeeds. So **test denials** as carefully as successes.

```java
@SpringBootTest
@AutoConfigureMockMvc
class AuthorizationTests {

    @Autowired MockMvc mvc;
    @Autowired OrderService orders;

    @Test
    void anonymousIsRejected() throws Exception {
        mvc.perform(get("/orders/1")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "alice", roles = "USER")
    void ownerCanReadOwnOrder() throws Exception {
        mvc.perform(get("/orders/1")).andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "alice", roles = "USER")
    void userCannotReadSomeoneElsesOrder() throws Exception {
        mvc.perform(get("/orders/2")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "root", roles = "ADMIN")
    void adminCanReadAnyOrder() throws Exception {
        mvc.perform(get("/orders/2")).andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "alice", roles = "USER")
    void serviceRuleHoldsEvenWithoutTheWebLayer() {
        assertThrows(AccessDeniedException.class, () -> orders.find(2));
    }
}
```

Line by line:

- `@WithMockUser(roles = "USER")` fakes a logged-in user with `ROLE_USER`. It **skips authentication**, which is perfect here, since we're testing authorization.
- `status().isUnauthorized()` expects 401. That holds for Basic or bearer entry points. With form login, anonymous requests get a 302 redirect to `/login` instead.
- The last test calls the **service directly**, with no HTTP involved. It proves the method rule holds for any caller. This is the test that catches a missing `@EnableMethodSecurity`: if it's missing, no exception is thrown and the test fails loudly.
- Other tools you'll meet: `@WithUserDetails("alice")` (loads the real user, including your custom principal), `.with(user("x").roles("ADMIN"))`, and `.with(jwt().authorities(...))` for token-based apps.

A good habit is a small **matrix test**: for each sensitive endpoint, test anonymous, the wrong role, the right role, and (for owned data) a different user with the right role.

---

# Part 11: Try it yourself

## A tiny app

Create a Spring Boot project with the **web** and **security** starters. Add this configuration:

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    PasswordEncoder encoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    @Bean
    UserDetailsService users(PasswordEncoder enc) {
        return new InMemoryUserDetailsManager(
            User.withUsername("alice").password(enc.encode("pw")).roles("USER").build(),
            User.withUsername("bob").password(enc.encode("pw")).roles("USER").build(),
            User.withUsername("root").password(enc.encode("pw")).roles("ADMIN").build());
    }

    @Bean
    SecurityFilterChain chain(HttpSecurity http) throws Exception {
        http
            .csrf(c -> c.disable())                 // ONLY for these curl experiments
            .httpBasic(Customizer.withDefaults())
            .authorizeHttpRequests(a -> a
                .requestMatchers("/public/**", "/error").permitAll()
                .requestMatchers(HttpMethod.DELETE, "/orders/**").hasRole("ADMIN")
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated());
        return http.build();
    }
}
```

And a controller and service:

```java
@RestController
public class DemoController {

    private final OrderService orders;
    public DemoController(OrderService orders) { this.orders = orders; }

    @GetMapping("/public/ping")  public String ping()  { return "pong"; }
    @GetMapping("/admin/stats")  public String stats() { return "secret stats"; }
    @GetMapping("/orders/{id}")  public Order get(@PathVariable long id) { return orders.find(id); }
    @DeleteMapping("/orders/{id}") public String delete(@PathVariable long id) { return "deleted " + id; }
}

record Order(long id, String owner, String item) { }

@Service
class OrderService {

    private final Map<Long, Order> db = Map.of(
            1L, new Order(1, "alice", "Book"),
            2L, new Order(2, "bob", "Laptop"));

    @PostAuthorize("returnObject.owner() == authentication.name or hasRole('ADMIN')")
    public Order find(long id) {
        System.out.println("find(" + id + ") ran");
        return db.get(id);
    }
}
```

## The experiments

**1. Walk through every outcome:**

```bash
curl -i  http://localhost:8080/public/ping                          # 200   permitAll
curl -i  http://localhost:8080/orders/1                             # 401   anonymous
curl -i -u alice:pw http://localhost:8080/orders/1                  # 200   her own order
curl -i -u alice:pw http://localhost:8080/orders/2                  # 403   Bob's order
curl -i -u root:pw  http://localhost:8080/orders/2                  # 200   admin
curl -i -u alice:pw -X DELETE http://localhost:8080/orders/1        # 403   URL rule (ADMIN only)
curl -i -u root:pw  -X DELETE http://localhost:8080/orders/1        # 200
curl -i -u alice:pw http://localhost:8080/admin/stats               # 403   wrong role
```

A quick way to see only the status codes:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -u alice:pw http://localhost:8080/orders/2
```

Notice the 401 versus 403 split: anonymous gets 401, and a known-but-forbidden user gets 403.

**2. Prove that `@PostAuthorize` runs after the method:**  
Request `/orders/2` as alice and watch the console. You'll see `find(2) ran` printed, **and then** the 403. The method already executed. Think about what this would mean if it were a delete method.

**3. Break it on purpose (the most useful experiment):**  
Remove `@EnableMethodSecurity`, restart, and repeat:

```bash
curl -i -u alice:pw http://localhost:8080/orders/2
```

Alice now reads Bob's order, and **nothing warns you**. This is why Part 10's tests matter.

**4. Watch the decisions:**

```properties
logging.level.org.springframework.security=TRACE
```

Look for lines about authorizing the request, the matched rule, and the final decision. Turn it off afterward, since it's noisy.

**5. Test the rule order:** swap the position of `.anyRequest().authenticated()` with the `/admin/**` rule. Spring Boot's configuration builder refuses an `anyRequest()` rule that isn't last, so you'll get a startup error. That's the "first match wins" rule protecting you.

**6. Test a method you forgot:** add a `PUT /orders/{id}` handler without any matching URL rule. It falls into `anyRequest().authenticated()`, so **any** logged-in user can call it. This is exactly why method and ownership rules matter.

**7. Try the owner query:** change `find` to look up by owner name, as in Part 5 Way 1, and compare what Alice gets for Bob's order (404 versus 403).

**8. Role hierarchy:** add the `RoleHierarchy` bean from Part 2, then change `/admin/stats` to `hasRole('USER')`. Admin `root` (who has no `USER` role) can now pass, because `ADMIN` implies `USER`.

---

# Common mistakes

|Mistake|Why it hurts|Fix|
|---|---|---|
|Forgetting `@EnableMethodSecurity`|Annotations are silently ignored|Enable it, and write a test that expects `AccessDeniedException`|
|Only checking the role, never the owner|Any user reads any user's data (IDOR/BOLA)|Ownership in the query, `@PostAuthorize`, or a bean check|
|Trusting IDs, roles, or owners sent by the client|The client controls them|Derive the owner from `authentication`, use DTOs|
|`hasRole("ROLE_ADMIN")`|Rejected at startup|`hasRole("ADMIN")` or `hasAuthority("ROLE_ADMIN")`|
|Storing `ADMIN` but granting `ADMIN` (no prefix)|`hasRole("ADMIN")` never matches|Build authorities as `ROLE_` + name|
|`@Secured("ADMIN")`|`@Secured` needs the full name|`@Secured("ROLE_ADMIN")`|
|A rule for GET only|POST, PUT, DELETE fall into the next rule|Think about each method, or omit the method to match all|
|Rules in the wrong order|The first match wins, so a broad rule shadows a specific one|Specific first, `anyRequest()` last|
|No catch-all or `denyAll()`|New endpoints are accidentally open|End with `anyRequest().authenticated()` or `denyAll()`|
|`@PostAuthorize` on a method that changes data|The change is already done when the check fails|Use `@PreAuthorize` for writes|
|Self-invocation of a protected method|The proxy is bypassed|Move it to another bean|
|Catch-all exception handler|403 turns into 500|Handle or rethrow `AccessDeniedException`|
|Protecting only the controller|Jobs and listeners skip the check|Protect the service layer too|
|`@PostFilter` on huge tables|Loads everything, then discards|Filter in the query|
|Treating hidden buttons as security|`curl` ignores your HTML|Server-side rules always|
|Using `web.ignoring()` for public paths|Skips headers and every other filter|`permitAll()`|
|`/error` not permitted|Real errors show as 401/403|`requestMatchers("/error").permitAll()`|
|Trusting an old role in the session or JWT|Revoked rights keep working|Expire sessions, short tokens, re-check sensitive actions|
|Putting business rules in 200-character SpEL strings|No compiler, hard to test|Move them to a bean|
|Trusting `X-Forwarded-For` for IP rules|Clients can fake it|Only from your own proxy|
|Testing only the allowed path|The bug is the one that **shouldn't** work|Test anonymous, wrong role, and wrong owner|

---

## Related concept, briefly

**RBAC, ABAC, and ReBAC** are three ways to think about "who can do what":

- **RBAC (role-based):** access depends on your **role**. Simple and what most apps use. This is `hasRole`.
- **ABAC (attribute-based):** access depends on **attributes** of the user, the object, and the situation: department, time of day, document sensitivity, IP address. Your SpEL and custom managers are ABAC.
- **ReBAC (relationship-based):** access depends on **relationships**: "Alice is an editor of Document 7, and Document 7 lives in Bob's folder." This is how Google Docs-style sharing works. It's usually handled by a dedicated authorization service, since it gets complicated quickly.

Start with RBAC, add ABAC rules (like ownership) where roles aren't enough, and reach for a relationship model only when your sharing rules truly demand it.

---

## The whole picture

|Question|Answer|
|---|---|
|What is authorization?|Deciding what an authenticated identity may do|
|What data does it use?|The `Authentication`'s authorities, plus the request or object|
|What does a rule return?|An `AuthorizationDecision` through an `AuthorizationManager`|
|What happens on denial?|`AccessDeniedException`: login redirect or 401 for anonymous, 403 for known users|
|Role vs authority?|A role is an authority starting with `ROLE_`. `hasRole` adds the prefix.|
|Where do URL rules live?|`authorizeHttpRequests` (`AuthorizationFilter`), first match wins|
|Where do method rules live?|`@PreAuthorize` and friends, through proxies, after `@EnableMethodSecurity`|
|Pre or post?|`@PreAuthorize` before (for writes), `@PostAuthorize` after (for reads of owned objects)|
|How do I stop users reading each other's data?|Ownership checks: in the query, a bean, or `@PostAuthorize`|
|Where should I protect?|URL, service methods, **and** data queries|
|How do I model permissions?|Roles for people, permissions for actions, a mapping table in PostgreSQL|
|What if I need something custom?|A lambda or class implementing `AuthorizationManager`, or a bean called from SpEL|
|Does hiding a button protect anything?|No|
|How fresh are the authorities?|As fresh as the login (session) or token (JWT)|
|Biggest silent failures?|Forgetting `@EnableMethodSecurity`, missing ownership checks, wrong rule order|




[[Spring Security]]