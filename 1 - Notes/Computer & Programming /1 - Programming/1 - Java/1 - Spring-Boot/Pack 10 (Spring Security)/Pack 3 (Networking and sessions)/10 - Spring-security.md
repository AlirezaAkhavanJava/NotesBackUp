
Spring Security is the part of the Spring ecosystem that protects your application. If you've built a Spring Boot app, it's what decides who gets in and what they're allowed to do once they're inside.

**1. Authentication (who are you?)**  
It verifies a user's identity. The classic way is a username and password checked against a database, but it also supports:

- Form login and HTTP Basic
- JWT tokens for stateless REST APIs
- OAuth2 / OpenID Connect ("Log in with Google/GitHub")
- LDAP, SAML, and single sign-on setups

**2. Authorization (what can you do?)**  
Once you're identified, it controls access. You can restrict by URL, or protect individual methods:

```java
@PreAuthorize("hasRole('ADMIN')")
public void deleteUser(Long id) { ... }
```

So a normal user can view their profile, but only an admin can delete accounts.

**3. Password protection**  
It gives you proper password hashing (BCrypt, Argon2, and others) so you never store plain-text passwords.

**4. Protection against common attacks**  
Much of this is switched on by default, so you get it without extra work:

- **CSRF**: stops malicious sites from making requests on a logged-in user's behalf
- **Session fixation**: prevents attackers from hijacking sessions
- **Clickjacking and XSS-related headers**: adds security headers like `X-Frame-Options` and `Content-Security-Policy` support
- **HTTPS enforcement** and HSTS

**5. Session and token management**  
It handles login sessions (cookie-based) or stateless token-based setups, plus logout, "remember me," and limits on concurrent sessions.

**How it works under the hood**  
Spring Security is built on a chain of servlet filters. Every request passes through the **security filter chain** before it reaches your controllers. Each filter has a job: one reads credentials, one checks permissions, one adds headers, and so on. This is why you can add security to an app without rewriting your business code.

**A quick taste**  
Just adding the dependency to a Spring Boot project locks down every endpoint with a generated login page. From there you customize it:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/public/**").permitAll()
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated()
        )
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

**When you need it**  
Any time your app has users, private data, or admin features: web apps, REST APIs, microservices, anything handling logins or sensitive information.

In short: it takes the hard, easy-to-get-wrong parts of security (login, permissions, password storage, attack protection) and gives you well-tested, configurable building blocks instead of making you write them yourself.





[[Spring Security]]