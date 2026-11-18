

Welcome to this lesson. In the last guide, you saw the properties that tell Spring Security where to find your token issuer and how to protect session cookies. Properties alone cannot say which URL needs which role, which requests are public, or whether your API should use sessions at all. That job belongs to a `SecurityFilterChain` bean, a Java object where you write those rules in code. In this tutorial we will build one from scratch for a REST API that accepts JWT access tokens, which is the setup you will use when an Angular front end calls a Spring Boot backend. By the end, you will understand every line of the configuration, why each line exists, what happens when a request arrives, and how to test each rule with real requests.

## Part 1: What Spring Security Does With a Request

**Definition.** Spring Security is a chain of servlet filters, meaning small objects that every incoming HTTP request passes through before it reaches your controller. Each filter does one job, such as reading a token, checking a password, or blocking a request. The `SecurityFilterChain` bean is the object that builds this chain for your application and decides which filters are active and how they behave.

**Why it exists.** A web application receives requests from many sources, and some of them should not reach your code. A single place that checks every request before it reaches a controller keeps that logic in one location, instead of scattering `if (user == null)` checks across every method.

**What problem it solves.** Without a filter chain, each controller would need to repeat the same checks, and it is easy to forget one. A missed check on one endpoint is exactly how data leaks happen.

**How it works.** When a request arrives, it moves through the filters in order. The bearer-token filter reads the `Authorization` header and validates the JWT. If the token is valid, Spring builds an `Authentication` object that describes the caller and their authorities (roles and scopes). Then the authorization filter compares the request URL and HTTP method against your rules, from top to bottom. The first rule that matches decides the outcome. If the caller lacks the required authority, the request is rejected. If the request is allowed, it reaches your controller.

**How you will use it.** You will write one `SecurityFilterChain` bean that lists your rules, plus a small converter that tells Spring how to read roles from your tokens. Everything else in this tutorial builds on that.

## Part 2: Project Setup

**Definition.** A project's dependencies are the libraries Maven downloads and puts on the classpath. For this tutorial you need Spring Web, which gives you REST controllers, and the OAuth2 Resource Server starter, which gives you JWT validation and the security integration.

**Why it exists.** Spring Boot starters bundle a library with the auto-configuration that wires it up. You get the behavior by adding one dependency rather than configuring every class manually.

**How it works.** In `pom.xml`, the two dependencies below pull in Spring Security 6.x, Spring's JWT decoder, and the servlet web stack.

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>
</dependencies>
```

Note that you do not need `spring-boot-starter-security` separately, because the resource-server starter already brings it in.

**How you will use it.** Add these once per project. Spring Boot's dependency management supplies the versions, so you leave out the `<version>` tags.

## Part 3: The Smallest Possible Configuration

Before adding rules, look at the skeleton. Every security configuration in this tutorial has this shape.

```java
package com.example.demo.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> { })
            );

        return http.build();
    }
}
```

**What each part does, line by line.**

`@Configuration` tells Spring that this class contains bean definitions. Spring scans it at startup and calls the methods annotated with `@Bean`.

`@EnableWebSecurity` switches on Spring Security's web support. Without it, your `HttpSecurity` configuration would not be applied to the servlet filter chain.

`SecurityFilterChain securityFilterChain(HttpSecurity http)` is the bean itself. Spring injects an `HttpSecurity` object, which is a builder. You call methods on it to describe your rules, then call `http.build()` at the end to produce the finished chain. The return type `SecurityFilterChain` is what Spring registers.

`.authorizeHttpRequests(auth -> auth ...)` opens the section where you list URL rules. The `auth ->` part is a lambda, which is a short way of writing a function. The lambda receives a configurer object, and everything inside the braces is a call on it. This style is called the Lambda DSL, and it replaced the older chained style that you may still see in old tutorials.

`.anyRequest().authenticated()` means that every request must carry a valid, authenticated identity. This is the safe default, and it is why the configuration is secure even though it has no specific rules.

`.oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> { }))` tells Spring to read bearer tokens from the `Authorization` header and validate them as JWTs. The `jwt(jwt -> { })` with an empty body means "use the defaults." The issuer and keys come from the property you already know from the previous guide: `spring.security.oauth2.resourceserver.jwt.issuer-uri`.

Here is the property that makes this configuration work:

```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://auth.example.com/realms/myapp
```

Spring fetches the issuer's discovery document at startup, finds the public keys, and uses them to verify each token's signature.

## Part 4: Writing URL Rules

Now add the rules that make the API useful. Some endpoints are public, some require a role, and some require a specific scope.

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/", "/public/**", "/actuator/health").permitAll()
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .requestMatchers(HttpMethod.GET, "/api/books/**").hasAuthority("SCOPE_books.read")
            .requestMatchers(HttpMethod.POST, "/api/books/**").hasAuthority("SCOPE_books.write")
            .anyRequest().authenticated()
        )
        .oauth2ResourceServer(oauth2 -> oauth2
            .jwt(jwt -> { })
        );

    return http.build();
}
```

You need one extra import: `org.springframework.http.HttpMethod`.

**What each rule does.**

`requestMatchers("/", "/public/**", "/actuator/health").permitAll()` lets anyone, including people with no token, reach these paths. The `**` is a wildcard that matches everything under a path, so `/public/logo.png` and `/public/docs/intro` both match. Use `permitAll()` sparingly, because every path listed there is open to the world.

`requestMatchers("/admin/**").hasRole("ADMIN")` requires the caller to have the authority `ROLE_ADMIN`. Notice that you write `hasRole("ADMIN")` and Spring adds the `ROLE_` prefix for you. This prefix convention is important, and Part 6 explains it in detail.

`requestMatchers(HttpMethod.GET, "/api/books/**").hasAuthority("SCOPE_books.read")` restricts the rule to one HTTP method. Reading books requires the scope `books.read`. Writing books requires `books.write` in the next rule. Here you use `hasAuthority` instead of `hasRole`, because `hasAuthority` compares the exact string with no prefix added. The `SCOPE_` prefix comes from how Spring maps the `scope` claim in JWTs, which you will see in Part 6.

`.anyRequest().authenticated()` catches everything that did not match an earlier rule. It must come last.

**The most important rule about ordering.** Spring checks rules from top to bottom and uses the first match. If you wrote `anyRequest().authenticated()` at the top, every later rule would be ignored, because `anyRequest` matches everything. That mistake causes either open endpoints or confusing 403 errors, and it is one of the most common bugs in Spring Security. Put the most specific rules first and the catch-all last.

## Part 5: Disabling Sessions and CSRF for a JWT API

Two settings in a REST API with JWTs are different from a traditional website. You need to understand why before you copy them.

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
        )
        .authorizeHttpRequests(auth -> auth
            // ... rules from Part 4 ...
        )
        .oauth2ResourceServer(oauth2 -> oauth2
            .jwt(jwt -> { })
        );

    return http.build();
}
```

You need the import `org.springframework.security.config.http.SessionCreationPolicy`.

**What `csrf.disable()` does.** CSRF, cross-site request forgery, is an attack where a malicious website tricks a browser into sending a request with the victim's cookies. CSRF protection is needed when the browser automatically attaches credentials. A JWT sent in an `Authorization` header is not attached automatically by the browser. A malicious site cannot read your token, so it cannot add the header. Because of that, CSRF protection adds nothing here, and disabling it is the standard choice for a token-based API.

**Important caveat.** This reasoning holds only if your tokens are sent in the header. If you ever store the JWT in a cookie, CSRF becomes a real risk again, and you should keep it enabled.

**What `STATELESS` does.** By default, Spring creates an HTTP session on login and stores the authenticated user there. `STATELESS` tells Spring never to create or use a session. Each request must prove its identity with its own token. This matches the purpose of a JWT: the token itself carries the identity, so the server does not need to remember it. Stateless APIs also scale more easily, because any server instance can handle any request without shared memory.

**How you will use it.** Use this combination for REST APIs that accept bearer tokens. If you later build a server-rendered website with a login form, you would remove these two settings and keep the session-based defaults.

## Part 6: Teaching Spring Where Roles Come From

This is the part that causes the most confusion, so take your time with it. Spring Security does not invent authorities. It reads them from the token and converts each one into a `GrantedAuthority`, which is a string such as `ROLE_ADMIN` or `SCOPE_books.read`. The default converter only reads the `scope` claim. Your tokens may put roles in a different claim, such as `roles`, so you need a custom converter.

**The default behavior.** If a JWT contains `"scope": "books.read books.write"`, Spring creates `SCOPE_books.read` and `SCOPE_books.write`. This is why scope rules use `hasAuthority("SCOPE_...")`.

**The custom converter.** Suppose your identity provider puts roles in a claim called `roles`, like this:

```json
{
  "sub": "alireza",
  "scope": "books.read",
  "roles": ["ADMIN", "USER"]
}
```

Add this bean to the same `SecurityConfig` class:

```java
@Bean
JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtGrantedAuthoritiesConverter scopeConverter = new JwtGrantedAuthoritiesConverter();

    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(jwt -> {
        Collection<GrantedAuthority> authorities = new ArrayList<>(scopeConverter.convert(jwt));

        List<String> roles = jwt.getClaimAsStringList("roles");
        if (roles != null) {
            for (String role : roles) {
                authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
            }
        }
        return authorities;
    });

    return converter;
}
```

Add these imports: `org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter`, `org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter`, `org.springframework.security.core.GrantedAuthority`, `org.springframework.security.core.authority.SimpleGrantedAuthority`, `java.util.ArrayList`, `java.util.Collection`, `java.util.List`.

**What each line does.**

`JwtGrantedAuthoritiesConverter scopeConverter` is Spring's built-in converter for the `scope` claim. Reusing it means you keep the `SCOPE_` behavior without rewriting it.

`JwtAuthenticationConverter converter` is the object that turns a validated `Jwt` into an `Authentication`. Spring uses it in place of the default.

`setJwtGrantedAuthoritiesConverter(jwt -> { ... })` supplies your own function for building the authority list. The lambda receives the validated token.

`new ArrayList<>(scopeConverter.convert(jwt))` starts with the scope authorities, so nothing is lost.

`jwt.getClaimAsStringList("roles")` reads the `roles` claim as a list of strings. It returns `null` if the claim is missing, which is why the `if (roles != null)` check is there. Without it, a token that lacks roles would crash the request.

`"ROLE_" + role` adds the prefix. This is the crucial step. `hasRole("ADMIN")` looks for the exact string `ROLE_ADMIN`. If you forget the prefix, the rule silently fails and returns 403 for admins, which is a frustrating bug to find.

**Why the prefix exists.** Spring separates roles from fine-grained authorities so the two cannot be confused. Roles are coarse groups, like `ADMIN`. Authorities are precise permissions, like `books.write`. The prefix makes it obvious at a glance which kind of check you are doing.

**Remember to wire the converter.** The converter only matters if the security chain uses it. Update the `jwt` section:

```java
.oauth2ResourceServer(oauth2 -> oauth2
    .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
);
```

When you call `jwtAuthenticationConverter()` inside a `@Bean` method, Spring returns the managed bean, not a new object, so the converter is applied consistently.

## Part 7: Protecting Methods With Annotations

URL rules protect whole paths. Sometimes you need protection that depends on the method itself, such as "only admins can delete a book, but any user can read one." For that you use method security.

First, enable it on the configuration class:

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    // ...
}
```

Then annotate controller methods:

```java
package com.example.demo.controller;

import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/books")
public class BookController {

    @GetMapping
    public List<String> listBooks(@AuthenticationPrincipal Jwt jwt) {
        return List.of("Effective Java", "Spring in Action");
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public void deleteBook(@PathVariable long id) {
        // Only reached when the caller has ROLE_ADMIN
    }
}
```

**What each part does.**

`@EnableMethodSecurity` activates the annotation processing. Without it, `@PreAuthorize` is ignored silently, which is a common surprise. This annotation replaced the older `@EnableGlobalMethodSecurity` in Spring Security 6.

`@PreAuthorize("hasRole('ADMIN')")` runs a check before the method body executes. If the check fails, the method is never called. Notice that here the role is written with quotes inside a Spring Expression Language string, and the prefix is still added automatically.

`@AuthenticationPrincipal Jwt jwt` injects the validated token into the method. This is useful when you need the caller's username (`jwt.getSubject()`) or other claims inside your business logic.

**URL rules versus method rules.** Use URL rules for broad access policy, such as "everything under `/admin` needs admin." Use `@PreAuthorize` for rules that depend on the specific resource or action. You will often use both together.

## Part 8: Testing Each Rule With curl

Security is only real when you test it. Start the application, obtain a token from your identity provider (the method depends on the provider), and export it.

```bash
export TOKEN="eyJhbGciOi..."
```

Then test the cases. Each command should produce a specific outcome.

```bash
# 1. Public endpoint, no token. Expect 200 OK.
curl -i http://localhost:8080/public/hello

# 2. Protected endpoint, no token. Expect 401 Unauthorized.
curl -i http://localhost:8080/api/books

# 3. Protected endpoint, valid token with books.read scope. Expect 200 OK.
curl -i -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/books

# 4. Admin endpoint, valid token without ROLE_ADMIN. Expect 403 Forbidden.
curl -i -H "Authorization: Bearer $TOKEN" http://localhost:8080/admin/stats

# 5. Method-protected delete, token without ROLE_ADMIN. Expect 403 Forbidden.
curl -i -X DELETE -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/books/1
```

**How to read the results.** A **401** means Spring could not establish who you are, so the token is missing, malformed, expired, or has the wrong issuer. A **403** means Spring knows who you are but you lack the required authority. When you see unexpected results, this distinction tells you where to look: 401 points to token validation, and 403 points to your authority mapping or rules.

**A useful debugging trick.** Temporarily log the authorities. Add this to any controller method while you test:

```java
System.out.println(SecurityContextHolder.getContext().getAuthentication().getAuthorities());
```

You need the import `org.springframework.security.core.context.SecurityContextHolder`. If you see `[SCOPE_books.read]` but not `ROLE_ADMIN`, the converter is not adding roles, and the fault is in Part 6. Remove the print statement when you finish.

## Part 9: Putting It All Together

Here is the complete `SecurityConfig` class, so you can see how the pieces fit.

```java
package com.example.demo.config;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/public/**", "/actuator/health").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/books/**").hasAuthority("SCOPE_books.read")
                .requestMatchers(HttpMethod.POST, "/api/books/**").hasAuthority("SCOPE_books.write")
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())));

        return http.build();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter scopeConverter = new JwtGrantedAuthoritiesConverter();

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Collection<GrantedAuthority> authorities = new ArrayList<>(scopeConverter.convert(jwt));

            List<String> roles = jwt.getClaimAsStringList("roles");
            if (roles != null) {
                for (String role : roles) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
                }
            }
            return authorities;
        });

        return converter;
    }
}
```

And the matching properties, which you already know from the last guide:

```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=${JWT_ISSUER_URI}
```

Keeping the issuer in an environment variable lets you point the same code at a local test server or at production.

## Common Mistakes to Watch For

- **Putting `anyRequest()` first.** It makes every later rule dead code. Keep it last.
- **Forgetting the `ROLE_` prefix in your converter.** `hasRole` then silently denies admins.
- **Mixing `hasRole` and `hasAuthority`.** `hasRole("ADMIN")` expects `ROLE_ADMIN`. `hasAuthority("ADMIN")` expects the exact string `ADMIN`. Pick one style and stay consistent.
- **Using old API names.** `authorizeRequests()` and `antMatchers()` belong to Spring Security 5. Use `authorizeHttpRequests()` and `requestMatchers()` in version 6.
- **Forgetting `@EnableMethodSecurity`.** Your `@PreAuthorize` annotations do nothing without it.
- **Reading 401 and 403 as the same thing.** They point to different causes, as explained in Part 8.



[[Spring Security]]