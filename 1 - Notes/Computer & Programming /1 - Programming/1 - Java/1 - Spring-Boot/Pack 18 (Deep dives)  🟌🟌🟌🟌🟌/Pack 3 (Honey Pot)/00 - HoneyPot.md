

A honeypot is a decoy system that looks like a real, valuable target, such as an admin login page, a database panel, or an API, but holds nothing real. Attackers find it, poke at it, and try to break in. You sit quietly on the other side and record everything they do. Because no real user has any reason to visit it, almost every request it receives is suspicious. That makes the data very clean.

The benefit for you is that you learn how attacks actually look: which passwords bots try, which paths they scan, which tools they use. It also teaches you a lot about Spring Security, because you use it in an unusual way. Normally it keeps people out. In a honeypot, you let them reach your fake endpoints on purpose, make every login fail convincingly, and log it all.

## Two kinds of honeypot

|Kind|What it does|Effort|Example|
|---|---|---|---|
|Low-interaction|Pretends to be a service. Returns canned fake responses. Attackers can't really do anything.|Small|A fake `/wp-login.php` that always says "wrong password"|
|High-interaction|A real (but isolated) system the attacker can actually use.|Large and risky|A full sandboxed server|

Spring Boot is a great fit for **low-interaction** honeypots, so that's what you'd build. It's also the safer choice, because nothing the attacker sends ever gets executed.

## What a honeypot has to do

Every honeypot, whatever technology it uses, has the same four jobs:

1. **Attract**: look like a real target (believable pages, paths, headers).
2. **Capture**: record each request and each credential attempt.
3. **Contain**: make sure the attacker can't hurt anything real.
4. **Analyze**: turn the raw records into something you can learn from.

Everything you need in Spring Boot maps onto one of these.

## What you need in Spring Boot

|Job|Spring piece|What it does for you|
|---|---|---|
|Attract|`@Controller` + Thymeleaf|Serves fake login pages that look real|
|Attract|`@RestController`|Serves fake `/api/v1/users`, `/.env`, `/actuator/env`|
|Attract|A response header tweak|Fakes the server banner (`Server: Apache/2.4.41`)|
|Capture|`OncePerRequestFilter`|Sees every request before anything else|
|Capture|Spring Data JPA + PostgreSQL|Stores the events permanently|
|Capture|`@Async`|Saves events in the background so floods don't slow you down|
|Contain|Spring Security `SecurityFilterChain`|Opens the bait paths, locks down your real dashboard|
|Contain|Rate limiting|Stops a flood from filling your disk|
|Analyze|A dashboard (`/dashboard/**`)|Shows top IPs, top passwords, top paths|

And outside Spring: **Docker** (to isolate the app), **a throwaway server** (a cheap VPS, to get real traffic), and **PostgreSQL**.

Your starter dependencies: `spring-boot-starter-web`, `spring-boot-starter-security`, `spring-boot-starter-data-jpa`, `spring-boot-starter-thymeleaf`, the PostgreSQL driver, and Lombok.

## How the pieces work together

Picture one attacker request flowing through your app:

```
Request → Logging filter → Security chain → Controller → Fake response
              │ saves event       │ allows bait paths    │ always "fails"
              ▼
          PostgreSQL
```

Now let's go through each piece.

### 1. The logging filter is the heart of it

A `OncePerRequestFilter` runs exactly once for every request. You already know this type from JWT work. Here it does something different: it doesn't check anything, it just records.

The key idea is to capture first, then let the request continue. Even if the request later turns out to be a 404 for a path you never defined, you still have a record of it. Scanners hit hundreds of paths you haven't made, and those misses are valuable data.

To keep it fast, hand the saving to a background thread:

```java
@Service
@RequiredArgsConstructor
public class AttackEventService {
    private final AttackEventRepository repo;

    @Async
    public void record(AttackEvent event) {
        repo.save(event);
    }
}
```

```java
@SpringBootApplication
@EnableAsync
public class HoneypotApplication { ... }
```

Line by line: `@Async` tells Spring to run `record` on another thread, so the request doesn't wait for the database. `@EnableAsync` switches that feature on. Without it, `@Async` is silently ignored, which is a classic trap.

### 2. The fake login always fails

The most valuable thing you capture is **credentials**: the username and password the attacker tried. So you build a login form whose POST handler saves what was submitted and always redirects back with an error. You add a short delay (a second or so), because an instant rejection feels fake to a human, and a bot doesn't mind waiting.

Notice you do not use Spring Security's real authentication here. There's no `AuthenticationManager`, no user store. A real login system would be the wrong tool, because the whole point is that nothing can succeed.

### 3. Spring Security protects _you_, not the bait

Your `SecurityFilterChain` has two jobs:

|Path|Rule|Why|
|---|---|---|
|Bait paths (`/admin`, `/wp-login.php`, etc.)|`permitAll()`|Attackers must be able to reach them|
|`/dashboard/**` (your real stats page)|`hasRole("OWNER")`|Only you should see captured data|

You also disable CSRF on the fake forms. CSRF protection rejects requests that don't carry a valid token. Bots don't have one, so they'd be turned away before you could log them.

Even better, serve your real dashboard on a **different port** or only over a VPN. Then attackers never even see that it exists.

### 4. Make it believable

A honeypot that looks fake gets ignored by smart attackers. A few cheap tricks:

- **Fake banners**: set a `Server` header that matches a popular stack.
- **Trap files**: `/.env`, `/.git/config`, `/phpmyadmin`. These are the first things scanners look for.
- **Plausible data**: return a fake `.env` with made-up keys, not an empty page.

```java
@RestController
public class TrapController {
    @GetMapping("/.env")
    public String env() {
        return "DB_HOST=10.0.0.5\nDB_USER=admin\nAWS_KEY=AKIAFAKEFAKEFAKE1234\n";
    }
}
```

Every value here is invented. Nothing in this file points to anything real.

## Safety rules you can't skip

Your honeypot will receive hostile input on purpose, so a few habits matter more than any feature.

1. **Isolate it.** Run it in Docker on a separate server. Never on your home network or a machine with real data.
2. **No real secrets anywhere.** Not in the code, not in the config, not in the fake files.
3. **Treat everything captured as hostile.** Attackers will submit SQL injection and script tags as "usernames." Use JPA (parameter binding) and escape all output in your dashboard. Otherwise a stored `<script>` runs in your browser when you view the stats.
4. **Never execute attacker input.** Record it, never run it, evaluate it, or fetch URLs from it.
5. **Check the law where you deploy.** Storing IP addresses and credentials can have privacy implications in some places.

## A related concept: honeytokens

A honeytoken is a fake secret planted somewhere that no legitimate person would ever use, such as a fake API key in your fake `.env`. If anyone ever uses that key, you know with certainty the file was stolen. It's the same decoy idea, shrunk down to a single piece of data.

## A sensible path to build it

1. Spring Boot + PostgreSQL + the logging filter and `AttackEvent` entity
2. One fake login page that captures credentials
3. The Spring Security chain (bait open, dashboard locked)
4. Trap endpoints and fake banners
5. Docker Compose (app + database)
6. A simple dashboard (top IPs, top passwords, top paths)
7. Deploy to a throwaway VPS and watch the traffic arrive


[[HoneyPot]]