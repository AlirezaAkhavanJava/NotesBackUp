
A honeypot is a decoy system built to look like a real, valuable target (a login page, an admin panel, an API) so attackers interact with it instead of your real systems. Nothing on it is real, so any traffic it receives is suspicious by definition. You record what attackers try (usernames, passwords, paths, tools) and learn from it. It's a defensive tool, and it's a great project for going beyond your level because it touches filters, security config, persistence, and deployment.

For a Spring Boot web honeypot, the twist on Spring Security is that you use it backwards. Normally it keeps people out. Here you deliberately let attackers reach fake endpoints, make every login attempt fail convincingly, and silently log everything.

## What you'll build

```
Internet → [Honeypot app (Docker)] → logs → PostgreSQL → dashboard
              ├─ fake /admin, /wp-login.php, /phpmyadmin, /.env, /api/v1/users
              ├─ fake login form (always fails, after a small delay)
              └─ logging filter (records every request)
```

## Build it in four phases

**Phase 1: Log every request.** A `OncePerRequestFilter` (the same kind of filter you'd write for JWT) that saves IP, method, path, User-Agent, and headers into an `AttackEvent` table.

```java
@Entity
public class AttackEvent {
    @Id @GeneratedValue private Long id;
    private Instant time = Instant.now();
    private String ip, method, path, userAgent;
    private String usernameTried, passwordTried;
    @Column(length = 2000) private String headers;
    // getters/setters (or Lombok @Data)
}
```

```java
@Component
@RequiredArgsConstructor
public class HoneypotLoggingFilter extends OncePerRequestFilter {
    private final AttackEventRepository repo;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        AttackEvent e = new AttackEvent();
        e.setIp(req.getRemoteAddr());
        e.setMethod(req.getMethod());
        e.setPath(req.getRequestURI());
        e.setUserAgent(req.getHeader("User-Agent"));
        repo.save(e);
        chain.doFilter(req, res);
    }
}
```

Line by line: the filter runs before every request, builds an event from the request data, saves it, then lets the request continue. In real use, save asynchronously (`@Async`) so a flood of requests can't slow you down.

**Phase 2: Fake login that captures credentials.** The key idea is that it never succeeds.

```java
@Controller
@RequiredArgsConstructor
public class FakeLoginController {
    private final AttackEventRepository repo;

    @GetMapping({"/admin", "/wp-login.php", "/login"})
    public String form() { return "fake-login"; }   // Thymeleaf page that looks real

    @PostMapping({"/admin/login", "/wp-login.php"})
    public String attempt(@RequestParam String username,
                          @RequestParam String password,
                          HttpServletRequest req) throws InterruptedException {
        AttackEvent e = new AttackEvent();
        e.setIp(req.getRemoteAddr());
        e.setPath(req.getRequestURI());
        e.setUsernameTried(username);
        e.setPasswordTried(password);
        repo.save(e);

        Thread.sleep(1200);                 // feels like a real auth check
        return "redirect:/admin?error";     // always fails
    }
}
```

**Phase 3: Spring Security configuration.** Open the trap paths to everyone, and add protections around the honeypot itself. Disable CSRF on the fake form, otherwise bots get rejected before you can log them.

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    SecurityFilterChain chain(HttpSecurity http, HoneypotLoggingFilter logFilter) throws Exception {
        http
          .csrf(csrf -> csrf.disable())            // the fake form must accept anything
          .authorizeHttpRequests(a -> a
              .requestMatchers("/dashboard/**").hasRole("OWNER")   // YOUR real dashboard
              .anyRequest().permitAll())                           // everything else is bait
          .addFilterBefore(logFilter, UsernamePasswordAuthenticationFilter.class)
          .httpBasic(Customizer.withDefaults());
        return http.build();
    }
}
```

You'll want your real dashboard on a separate port or behind a VPN so attackers never see it.

**Phase 4: Make it believable and useful.**

- Add trap endpoints that attackers love: `/.env`, `/.git/config`, `/phpmyadmin`, `/actuator/env`, `/api/v1/users`. Return fake but plausible data.
- Fake a server banner by setting the `Server` header to something like `Apache/2.4.41`.
- Add rate limiting and log rotation so you don't fill your disk.
- Build a small dashboard: top IPs, most-tried passwords, most-hit paths, attempts per hour.

## Safety rules (important)

1. **Isolate it.** Run it in Docker on a separate VPS or network segment, never on the same machine or network as anything real.
2. **Never put real data or real credentials in it.** Everything fake, everything disposable.
3. **Treat captured input as hostile.** Attackers will send SQL injection and script payloads. Use JPA parameter binding and escape everything you show in your dashboard, or your honeypot becomes the vulnerable thing.
4. **Never let it execute anything.** Don't run, evaluate, or fetch attacker-supplied input. Just record it.
5. **Check your local rules.** Collecting IPs and credentials can have legal or privacy implications depending on where you deploy.

## A related concept: honeytokens

A honeytoken is a fake secret (a fake API key, a fake database row) that alerts you the moment anyone uses it. Your fake `/.env` file could contain a fake key, and any later use of it tells you the file was stolen. It's cheap and very effective.

## Suggested order

1. Spring Boot + PostgreSQL + the logging filter
2. One fake login page and the credential capture
3. Docker Compose (app + database)
4. Trap endpoints and the dashboard
5. Deploy to a throwaway VPS and watch real traffic arrive, usually within hours


[[Spring Security]]
[[Spring Framework]]
[[Java]]
[[Networking]]