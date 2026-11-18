
Spring Security sits in front of your controllers and checks every request before your code ever runs. Because of that, your business code stays clean, and you don't have to remember to check permissions in each method.

## Step 1: Every request goes through a chain of filters

A servlet filter is a small piece of code that can inspect or stop a request before it reaches your app. Spring Security installs a whole line of them.

```
Browser → [Filter 1] → [Filter 2] → [Filter 3] → ... → DispatcherServlet → Your Controller
```

Two pieces make this work:

- **DelegatingFilterProxy** is a single filter registered with the servlet container (Tomcat). It hands every request over to Spring.
- **FilterChainProxy** is a Spring bean that receives the request and picks the right **SecurityFilterChain** for it. You can even have different chains for different URLs, for example one for `/api/**` and one for the web pages.

When you write a `SecurityFilterChain` bean like the one earlier, you're configuring this line of filters.

## Step 2: The filters do different jobs

Each filter has one responsibility. These are the ones you'll hear about most:

|Filter|What it does|
|---|---|
|`SecurityContextHolderFilter`|Loads who is logged in (e.g. from the session)|
|`CsrfFilter`|Rejects forged requests|
|`UsernamePasswordAuthenticationFilter`|Handles the login form submission|
|`BearerTokenAuthenticationFilter`|Reads JWT/OAuth2 tokens from headers|
|`ExceptionTranslationFilter`|Turns security errors into a 401 or 403 response|
|`AuthorizationFilter`|Last gate: decides if you may access this URL|

The order matters. Authentication filters run first so that by the time `AuthorizationFilter` runs, Spring already knows who you are.

## Step 3: Authentication, which proves who you are

Here's what happens when someone submits a username and password:

1. The login filter grabs the credentials and wraps them in an **Authentication** object. At this point it's marked "not yet authenticated."
2. It passes that object to the **AuthenticationManager**, which is the front door for the "is this person real?" question.
3. In practice the manager is usually a **ProviderManager**, which asks its list of **AuthenticationProviders** one by one. Each provider knows how to verify one kind of login (username/password, JWT, LDAP, and so on).
4. For username/password, the provider (`DaoAuthenticationProvider`) does two things:
    - Calls your **UserDetailsService** to load the user from your database (this is the piece you usually write yourself).
    - Uses a **PasswordEncoder** (like BCrypt) to compare the typed password against the stored hash.
5. If the check passes, you get back a fully authenticated `Authentication` object that holds the user's name and their **authorities** (roles and permissions, like `ROLE_ADMIN`).

If anything fails, an `AuthenticationException` is thrown and the user gets a 401 or is sent back to the login page.

A minimal `UserDetailsService` looks like this:

```java
@Service
public class MyUserService implements UserDetailsService {

    private final UserRepository repo;

    public MyUserService(UserRepository repo) { this.repo = repo; }

    @Override
    public UserDetails loadUserByUsername(String username) {
        User u = repo.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("No such user"));
        return org.springframework.security.core.userdetails.User
            .withUsername(u.getUsername())
            .password(u.getPasswordHash())
            .roles(u.getRole())
            .build();
    }
}
```

Spring Security never touches your database directly. It just asks you for a `UserDetails`, so it works with PostgreSQL, SQLite, or anything else.

## Step 4: The SecurityContext remembers who you are

After a successful login, the `Authentication` object is stored in the **SecurityContext**, which lives in the **SecurityContextHolder**. By default it's tied to the current thread, so any code running for that request can ask "who is the current user?":

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
String name = auth.getName();
```

Or, more conveniently, in a controller:

```java
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user) {
    return user.getUsername();
}
```

How it survives between requests depends on your setup:

- **Session-based:** the context is saved in the HTTP session, and the browser sends a `JSESSIONID` cookie each time.
- **Stateless (JWT):** nothing is stored on the server. Every request carries a token, and a filter rebuilds the `Authentication` from it each time.

## Step 5: Authorization, which decides what you may do

Now that Spring knows who you are, it checks whether you're allowed in. This happens in two places:

- **URL level:** `AuthorizationFilter` compares the request against your rules (`.requestMatchers("/admin/**").hasRole("ADMIN")`).
- **Method level:** with `@EnableMethodSecurity`, annotations like `@PreAuthorize` wrap your beans in a proxy that checks permissions just before the method runs.

Both compare the user's authorities (stored in the `Authentication`) against what the rule requires. If you don't have the right authority, you get a **403 Forbidden**.

## Step 6: Errors become proper HTTP responses

The `ExceptionTranslationFilter` catches security exceptions and decides what to do:

- **Not logged in** (`AuthenticationException`): start authentication, meaning redirect to the login page or send 401.
- **Logged in but not allowed** (`AccessDeniedException`): send 403.

A handy way to remember it: **401 means "I don't know who you are,"** and **403 means "I know who you are, and the answer is no."**

## The whole journey in one picture

```
Request
  ↓
FilterChainProxy picks the matching SecurityFilterChain
  ↓
Load existing login (session or token)  →  SecurityContext
  ↓
CSRF check
  ↓
Not logged in yet? Login filter → AuthenticationManager
                                   → AuthenticationProvider
                                   → UserDetailsService + PasswordEncoder
  ↓
AuthorizationFilter: allowed to access this URL?
  ↓
Your controller (+ @PreAuthorize check on the method)
  ↓
Response (security headers added on the way out)
```

## Why Spring Boot makes this feel so easy

Spring Boot auto-configures a default chain the moment `spring-boot-starter-security` is on your classpath. It locks every endpoint, creates a login form, and generates a random password you'll see in the console. The moment you define your own `SecurityFilterChain` bean, Boot steps aside and uses yours.

If you want to see all this for yourself, add `logging.level.org.springframework.security=TRACE` to `application.properties`. You'll watch each filter run in order for every request, which makes the whole flow click.




[[Spring Security]]