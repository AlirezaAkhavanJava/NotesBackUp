


Spring Security protects your app in two different "worlds." Which one you use depends on how your web app is built. The security ideas are the same in both: authentication, authorization, roles, password encoding, CSRF, and so on. What changes is the plumbing underneath. Knowing this saves you from copying the wrong config or the wrong class name.

## The one-sentence difference

- **Servlet way:** for traditional apps built on **Spring MVC** and the Servlet API. One request is handled by one thread, and the code is blocking.
- **Reactive way:** for apps built on **Spring WebFlux**. A few threads handle many requests, and the code is non-blocking and uses `Mono` and `Flux`.

You pick the security flavor that matches your web stack. You can't mix them in one app.

## The servlet way

### How it works

Servlet security is built on **Filters**. A filter is a small piece of code that sees every request before your controller does. Spring Security plugs in one special filter, and that filter fans out into a whole chain of security filters:

```
Request → DelegatingFilterProxy → FilterChainProxy → SecurityFilterChain
          (a bridge from the servlet     (Spring Security's    (the ordered list of
           container into Spring)         front door)           security filters)
```

Inside the chain, filters handle things like CSRF checks, login processing, session handling, and the final authorization check. If any filter says "no," the request stops there and never reaches your controller.

### How you configure it

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .formLogin(Customizer.withDefaults());
        return http.build();
    }
}
```

The key names to remember are `@EnableWebSecurity`, `HttpSecurity`, `SecurityFilterChain`, and `requestMatchers`.

### How it remembers who you are

The logged-in user is stored in `SecurityContextHolder`. By default it uses a **ThreadLocal**, which is a variable that belongs to the current thread. This works because one request equals one thread, so anywhere in your code on that thread you can write:

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
```

Or, more simply in a controller, use `@AuthenticationPrincipal`.

## The reactive way

### How it works

In WebFlux there are no servlet filters. Instead, you get **WebFilters**, which work on a `ServerWebExchange` (an object that holds both the request and the response). The chain idea is the same, but every step returns a `Mono<Void>` instead of blocking.

```
Request → WebFilterChainProxy → SecurityWebFilterChain → your handler
```

### How you configure it

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    SecurityWebFilterChain securityChain(ServerHttpSecurity http) {
        return http
            .authorizeExchange(ex -> ex
                .pathMatchers("/public/**").permitAll()
                .pathMatchers("/admin/**").hasRole("ADMIN")
                .anyExchange().authenticated())
            .formLogin(Customizer.withDefaults())
            .build();
    }
}
```

It looks almost the same, but every name is different: `@EnableWebFluxSecurity`, `ServerHttpSecurity`, `SecurityWebFilterChain`, `authorizeExchange`, and `pathMatchers`. Also notice there is no `throws Exception`.

### How it remembers who you are

A ThreadLocal doesn't work here. In reactive code, one request may hop between several threads during its life. So Spring Security stores the user in the **Reactor Context**, which travels with the request through the reactive pipeline instead of with the thread:

```java
Mono<String> name = ReactiveSecurityContextHolder.getContext()
        .map(ctx -> ctx.getAuthentication().getName());
```

You get a `Mono`, not a plain object. You have to stay inside the reactive chain to use it.

## Side by side

|Topic|Servlet|Reactive|
|---|---|---|
|Web framework|Spring MVC|Spring WebFlux|
|Core hook|`Filter`|`WebFilter`|
|Enable annotation|`@EnableWebSecurity`|`@EnableWebFluxSecurity`|
|Config object|`HttpSecurity`|`ServerHttpSecurity`|
|Chain bean|`SecurityFilterChain`|`SecurityWebFilterChain`|
|URL rules|`authorizeHttpRequests`, `requestMatchers`|`authorizeExchange`, `pathMatchers`|
|Current user holder|`SecurityContextHolder` (ThreadLocal)|`ReactiveSecurityContextHolder` (Reactor Context)|
|User lookup|`UserDetailsService`|`ReactiveUserDetailsService`|
|Auth manager|`AuthenticationManager`|`ReactiveAuthenticationManager`|
|Method security|`@EnableMethodSecurity`|`@EnableReactiveMethodSecurity`|
|Return types|Plain objects|`Mono` / `Flux`|

`PasswordEncoder` is the same in both worlds, and so are the annotations `@PreAuthorize` and `@PostAuthorize`. The ideas carry over even when the class names change.

## Which one should you use?

**Choose servlet** if you're building a typical Spring Boot web app or REST API with Spring MVC, JPA, or JDBC. It's the most common choice. It's easier to read and debug, and it has the most tutorials and community answers.

**Choose reactive** if your whole app is already WebFlux and non-blocking, for example when you use R2DBC, WebClient, or streaming. Mixing blocking code into a reactive app defeats its purpose.

A good rule: **let your web stack decide.** If you add `spring-boot-starter-web`, you get servlet security. If you add `spring-boot-starter-webflux`, you get reactive security. Spring Boot auto-configures the matching one for you.

## A quick related concept: Spring MVC vs WebFlux

These are Spring's two web stacks, and the security flavor follows from them. **Spring MVC** gives each request its own thread, and that thread waits while it does slow work like database calls. **WebFlux** uses a small number of threads and never waits. It starts the slow work, moves on, and comes back when the result is ready. WebFlux can handle huge numbers of concurrent connections with fewer resources, but your code has to be non-blocking all the way through.





[[Spring Security]]