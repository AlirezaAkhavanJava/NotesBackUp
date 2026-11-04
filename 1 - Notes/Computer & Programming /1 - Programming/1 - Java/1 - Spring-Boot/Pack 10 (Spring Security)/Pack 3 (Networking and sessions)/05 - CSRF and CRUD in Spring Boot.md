

CRUD is the most common thing you'll build in Spring Boot, and CSRF is the most common reason it breaks the first time Spring Security is added. You build the endpoints, test them, and then every POST, PUT, and DELETE returns **403 Forbidden** while GET works fine. This lesson explains why that happens and the right fix for each type of app.

## How CRUD connects to CSRF

CRUD operations map onto HTTP methods, and `CsrfFilter` only cares about the methods that **change data**:

|CRUD|HTTP method|Example|CSRF checked?|
|---|---|---|---|
|**C**reate|`POST`|`POST /api/tasks`|Yes|
|**R**ead|`GET`|`GET /api/tasks/5`|No|
|**U**pdate|`PUT` / `PATCH`|`PUT /api/tasks/5`|Yes|
|**D**elete|`DELETE`|`DELETE /api/tasks/5`|Yes|

This is why Read works and the other three fail. Reading data doesn't change anything, so an attacker gains nothing by forging it. The other three change data, so Spring demands proof that the request came from your own page.

The rule only works if your GET endpoints are truly read-only. A "delete" action built on GET would bypass CSRF protection completely.

## Step 1: the CRUD app (without security)

You know Spring Boot and PostgreSQL, so I'll keep this part brief. The dependencies are `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `spring-boot-starter-security`, and the PostgreSQL driver.

**Entity:**

```java
@Entity
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private boolean done;

    // getters and setters
}
```

**Repository:**

```java
public interface TaskRepository extends JpaRepository<Task, Long> {}
```

**Controller:**

```java
@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final TaskRepository repo;

    public TaskController(TaskRepository repo) {
        this.repo = repo;
    }

    @GetMapping                       // READ all
    public List<Task> all() {
        return repo.findAll();
    }

    @GetMapping("/{id}")              // READ one
    public ResponseEntity<Task> one(@PathVariable Long id) {
        return repo.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping                      // CREATE
    public ResponseEntity<Task> create(@RequestBody Task task) {
        task.setId(null);             // never trust an id from the client
        return ResponseEntity.status(HttpStatus.CREATED).body(repo.save(task));
    }

    @PutMapping("/{id}")              // UPDATE
    public ResponseEntity<Task> update(@PathVariable Long id, @RequestBody Task in) {
        return repo.findById(id).map(existing -> {
            existing.setTitle(in.getTitle());
            existing.setDone(in.isDone());
            return ResponseEntity.ok(repo.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")           // DELETE
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
```

In production you would use a DTO instead of exposing the entity directly, but this keeps the example focused on security.

## Step 2: what happens when Spring Security is added

Add `spring-boot-starter-security` and run the app. With zero configuration:

- Every endpoint requires login (Boot prints a generated password in the console).
- CSRF protection is **on**.
- Your `GET /api/tasks` works after login.
- Your `POST /api/tasks` returns **403**, even though you're logged in.

The 403 doesn't mean "you lack permission." The request lacked a valid CSRF token. In the DEBUG logs you'll see a message like "Invalid CSRF token found."

How you fix it depends on **what kind of client** calls your API. There are three common cases.

## Case A: server-rendered pages (Thymeleaf)

Your app returns HTML pages and the browser submits forms. This is the easiest case, because **Spring does almost everything for you.**

With Thymeleaf, use `th:action` and the hidden token is added automatically:

```html
<form th:action="@{/tasks}" method="post">
    <input type="text" name="title" />
    <button type="submit">Add</button>
</form>
```

Thymeleaf renders it with an extra hidden field:

```html
<input type="hidden" name="_csrf" value="9b1f...random..."/>
```

On submit, `CsrfFilter` compares that value to the one it expects for your session. Match means the request goes through.

**The catch with HTML forms:** they can only send GET and POST. For update and delete, the simplest approach is to use POST with a descriptive URL:

```html
<form th:action="@{/tasks/{id}/delete(id=${task.id})}" method="post">
    <button type="submit">Delete</button>
</form>
```

```java
@Controller
public class TaskPageController {
    // ...
    @PostMapping("/tasks/{id}/delete")
    public String delete(@PathVariable Long id) {
        repo.deleteById(id);
        return "redirect:/tasks";
    }
}
```

If you prefer real `PUT`/`DELETE` semantics, set `spring.mvc.hiddenmethod.filter.enabled=true` and add `<input type="hidden" name="_method" value="delete"/>` to the form. The CSRF token still works the same way.

The security config for this case needs nothing special. **Leave CSRF alone.**

## Case B: a JavaScript front end that uses session cookies

Your front end (React, Vue, plain JS) calls `/api/tasks` with `fetch`, and login uses the session cookie. Here you have to carry the token yourself, because there's no Thymeleaf to put it in a form.

The standard approach is to store the token in a **cookie that JavaScript can read**, then send it back in a **header**. This works because only code running on _your_ site can read your cookies. An attacker's page can make the browser _send_ the cookie but can't _read_ it, so it can't copy the value into a header.

**Security config:**

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
            .formLogin(Customizer.withDefaults())
            .httpBasic(Customizer.withDefaults())   // handy for testing with curl
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler()))
            .addFilterAfter(new CsrfCookieFilter(), BasicAuthenticationFilter.class);
        return http.build();
    }
}
```

Two pieces here need explaining.

1. **`CookieCsrfTokenRepository.withHttpOnlyFalse()`** stores the token in a cookie named `XSRF-TOKEN`. The `HttpOnly=false` part is deliberate, because your JavaScript must be able to read it. (This is different from the session cookie, which should stay `HttpOnly`.)
    
2. **`CsrfCookieFilter`** is needed because Spring Security 6 loads the token **lazily**, meaning only when something asks for it. If nothing asks, the cookie is never written, and your front end has nothing to read. This tiny filter forces the token to load on each request:
    

```java
public class CsrfCookieFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        CsrfToken token = (CsrfToken) request.getAttribute(CsrfToken.class.getName());
        if (token != null) {
            token.getToken();   // touching it makes Spring write the cookie
        }
        chain.doFilter(request, response);
    }
}
```

**The front-end side:** read the cookie and send it as the `X-XSRF-TOKEN` header on every state-changing request.

```javascript
function getCookie(name) {
  const part = document.cookie.split('; ').find(c => c.startsWith(name + '='));
  return part ? decodeURIComponent(part.split('=')[1]) : null;
}

async function createTask(title) {
  const res = await fetch('/api/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-XSRF-TOKEN': getCookie('XSRF-TOKEN')
    },
    body: JSON.stringify({ title })
  });
  return res.json();
}

async function deleteTask(id) {
  await fetch(`/api/tasks/${id}`, {
    method: 'DELETE',
    headers: { 'X-XSRF-TOKEN': getCookie('XSRF-TOKEN') }
  });
}
```

`GET` needs no header. Libraries like Axios and Angular's `HttpClient` do this cookie-to-header copy automatically for the `XSRF-TOKEN` / `X-XSRF-TOKEN` pair, which is where that naming convention comes from.

One detail: the plain `CsrfTokenRequestAttributeHandler` is the simple choice. Spring's default handler adds extra token masking against an attack called BREACH, and that masking makes the cookie value differ from what the header needs. For a production single-page app, the Spring Security reference documents a `SpaCsrfTokenRequestHandler` that keeps the masking and still works with a cookie. The setup above is the easier one for learning.

## Case C: a stateless API with JWT

Here your client sends `Authorization: Bearer <token>`, and there's no session or cookie involved.

```java
@Bean
SecurityFilterChain api(HttpSecurity http, JwtAuthFilter jwtFilter) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/auth/**").permitAll()
            .anyRequest().authenticated())
        .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
    return http.build();
}
```

Turning CSRF off is safe here because the attack needs the browser to attach credentials **automatically**. A bearer token is added by your own JavaScript code, so a forged cross-site request has no token.

This only holds if the JWT is **not** stored in a cookie. If it lives in a cookie the browser sends automatically, the attack works again, and you should keep CSRF protection on.

## Choosing the right case

|Your app|Authentication|CSRF setting|
|---|---|---|
|Thymeleaf pages|Session cookie|Leave default (on)|
|JS front end on the same site|Session cookie|On, using the cookie + header pattern|
|Mobile app or API for other clients|Bearer token in a header|Can be off|
|JWT stored in a cookie|Cookie|Keep on|

## Excluding specific endpoints

Sometimes a particular URL can't send a token, for example a payment provider's webhook. You can exempt just that path instead of turning protection off everywhere:

```java
.csrf(csrf -> csrf.ignoringRequestMatchers("/webhooks/**"))
```

Protect those endpoints in another way, such as verifying a signature from the sender.

## Testing your CRUD with CSRF

**With curl** (using `.httpBasic()` as above). First do a GET so the server gives you the cookie, then send it back:

```bash
# 1. GET: saves the XSRF-TOKEN cookie into jar.txt
curl -i -c jar.txt -u user:password http://localhost:8080/api/tasks

# 2. POST: send the cookie AND the matching header
curl -i -b jar.txt -u user:password \
  -H "X-XSRF-TOKEN: <value of XSRF-TOKEN from jar.txt>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn CSRF"}' \
  http://localhost:8080/api/tasks
```

**With MockMvc**, which is the best way to prove your rules work:

```java
@Test
void createWithoutCsrfIsForbidden() throws Exception {
    mockMvc.perform(post("/api/tasks")
            .with(user("ahmed"))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"title\":\"x\"}"))
        .andExpect(status().isForbidden());
}

@Test
void createWithCsrfWorks() throws Exception {
    mockMvc.perform(post("/api/tasks")
            .with(user("ahmed"))
            .with(csrf())                      // adds a valid token
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"title\":\"x\"}"))
        .andExpect(status().isCreated());
}
```

Notice that the first test exists to prove the protection is on. A test that only passes with `csrf()` can't tell you whether the protection works.

## Common mistakes

- **Disabling CSRF just to make the 403 go away.** It works, but it removes a real protection. First decide which case you're in.
- **A state-changing GET endpoint**, like `GET /tasks/5/delete`. GET isn't checked, so it can be attacked by a simple image tag.
- **Forgetting the `CsrfCookieFilter`** in Case B, then wondering why the `XSRF-TOKEN` cookie never appears.
- **Sending the header with the wrong name.** The default header is `X-XSRF-TOKEN`, and the default cookie is `XSRF-TOKEN`.
- **Mixing up 401 and 403.** 401 means "log in first." A 403 on a POST from a logged-in user usually means a missing or wrong CSRF token, or a real permission problem. The DEBUG logs tell you which.

## Related concepts, in short

- **`PUT` vs `PATCH`:** `PUT` replaces the whole resource, and `PATCH` changes only the fields you send. CSRF treats them the same.
- **DTO (Data Transfer Object):** a small class that represents the shape of your API's input and output, so your database entity isn't exposed directly. It also prevents clients from setting fields they shouldn't, like `id`.
- **Idempotency:** an operation is idempotent if repeating it gives the same result. `PUT` and `DELETE` are, and `POST` usually isn't. This matters for retries, not for CSRF.
- **CORS:** a browser rule about which _other_ sites may read your API's responses. It doesn't replace CSRF protection, because CSRF attacks only need the request to be _sent_, not read.

## Summary

CRUD maps to HTTP methods, and Spring Security's `CsrfFilter` blocks `POST`, `PUT`, `PATCH`, and `DELETE` unless the request carries a valid token. That's why only Read works at first. For server-rendered pages, Thymeleaf adds the token to your forms automatically. For a JavaScript front end using session cookies, store the token in a readable `XSRF-TOKEN` cookie and send it back in the `X-XSRF-TOKEN` header. For a stateless bearer-token API, it's safe to disable CSRF. Always decide based on whether the browser sends your credentials automatically.




[[Spring Security]]