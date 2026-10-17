
**What is it?**  
Spring Security is a ready-made "security guard" for your Spring Boot application.

**What does it do? (3 main things)**
1. **Checks who you are** → login with username/password, Google, JWT token, etc.
2. **Decides what you’re allowed to see/do** → e.g., normal users can view, only admins can delete.
3. **Protects you from hackers** → blocks CSRF attacks, secure passwords, session hijacking, etc. automatically.

**Why do you need it?**
- Without it, anyone can access any page or API in your app (very dangerous).
- Writing login + roles + protection yourself takes weeks and is full of bugs.
- Spring Security does all of that correctly in 10–20 lines of code.

**Real-life example**  
You build a website or mobile backend .  
With Spring Security → users must log in, admins have special pages, passwords are safe, hackers are blocked.  
Without Spring Security → everyone (even random people from the internet) can delete your data.

**Bottom line**  
If your app has any login or different user roles (99% of real apps), you need Spring Security. It’s the standard, free, and trusted solution used by banks, shops, and big companies worldwide.



---
### What is `WebSecurity` and `@EnableWebSecurity` in Spring Security?

Let’s clear this up with the **2025 reality** (Spring Boot 3.x + Spring Security 6.x).

| Component                | What it was (old versions ≤ 5.7) | What it is now (Spring Security 5.8 → 6.x → today) | Do you still need it in 2025? |
|--------------------------|-----------------------------------|----------------------------------------------------|-------------------------------|
| `@EnableWebSecurity`     | Mandatory annotation            | **Still exists but completely optional**           | Almost never needed anymore  |
| `WebSecurity`            | Important class you often used  | **Deprecated and almost unused**                   | You almost never touch it now |

### Modern Reality (Spring Boot 3.1+ / Spring Security 6+)

Since Spring Security 5.8 (2022) and especially Spring Boot 3 (2023 onwards), the recommended and default way is:

You only need **one** `@Configuration` class with a `SecurityFilterChain` bean.

```java
@Configuration
// @EnableWebSecurity   ← You can delete this line in 99% of projects!
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .formLogin(form -> form.loginPage("/login"))
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());

        return http.build();
    }
}
```

That’s it. No `@EnableWebSecurity`, no `WebSecurityConfigurerAdapter`, no `WebSecurity` customizing.

### So When Do You Still Use Them in 2025?

Only in **very rare advanced cases**:

| Use Case                                  | You need `@EnableWebSecurity` or `WebSecurity` |
|-------------------------------------------|-------------------------------------------------|
| You have **multiple** `SecurityFilterChain` beans and want to control ordering explicitly | Yes (add `@EnableWebSecurity` + `@Order`)       |
| You want to completely **ignore** certain paths (bypass Spring Security entirely, e.g., /static/**, /webjars/**, actuator endpoints) | Use `WebSecurity.ignoring()` (still works)     |
| You are migrating a very old project      | Yes, temporarily                                |

#### Example: Ignoring static resources (one of the few remaining valid uses)

```java
@Configuration
@EnableWebSecurity   // Only needed because we customize WebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        // normal config
    }

    // This is the only common reason to use WebSecurity today
    @Bean
    public WebSecurityCustomizer webSecurityCustomizer() {
        return (web) -> web.ignoring()
            .requestMatchers("/css/**", "/js/**", "/images/**", "/favicon.ico");
    }
}
```

Or even simpler in 2025 (recommended):

```yaml
# application.yml → Spring Boot auto-configures ignoring these
spring:
  web:
    resources:
      add-mappings: true   # default
  security:
    ignored: /css/**,/js/**,/images/**,/favicon.ico
```

### Summary – 2025 Best Practice

| What you write                          | Required? | Comment                                      |
|-----------------------------------------|-----------|----------------------------------------------|
| `@Configuration` + `SecurityFilterChain` bean | Yes       | This is enough in 99% of projects            |
| `@EnableWebSecurity`                    | No        | Optional, only for advanced cases            |
| Extending `WebSecurityConfigurerAdapter`| No        | Removed since Spring Security 5.7 (2022)     |
| Using `WebSecurity`                     | Rarely    | Only to ignore paths or very custom setups   |

Bottom line in November 2025:
For almost all new projects (and most existing ones), just do this and forget about `@EnableWebSecurity` and `WebSecurity`:

```java
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) { ... }
}
```


###### Tags : [[1 - Spring Security 🍌]]