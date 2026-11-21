
---
# Understanding `SecurityFilterChain` Method Parameters in Spring Security

## 1. What Are We Doing Here?

Look at this method:

```java
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http
) throws Exception {

    return http.build();
}
```

You already know about Spring's Dependency Injection (DI), right?

**That's exactly what's happening here!**

Let's break it down.

```java
public SecurityFilterChain securityFilterChain(HttpSecurity http)
```

|Part|Meaning|
|---|---|
|`public`|The method is accessible from other classes|
|`SecurityFilterChain`|The return type|
|`securityFilterChain`|The method name|
|`HttpSecurity http`|A dependency provided by Spring|
|`throws Exception`|Allows checked exceptions from security configuration and building to propagate|

The important part is:

```java
HttpSecurity http
```

We are asking Spring:

> When you call this method, please provide an `HttpSecurity` object so I can configure my application's HTTP security.

Spring resolves this parameter through its dependency injection mechanism.

---

## 2. Why Do We Receive `HttpSecurity`?

Remember that `HttpSecurity` is a **builder**.

We use it to configure our security filters and security behavior.

For example:

```java
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http
) throws Exception {

    http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/public/**").permitAll()
            .anyRequest().authenticated()
    );

    http.httpBasic(Customizer.withDefaults());

    return http.build();
}
```

Here's what happens:

1. Spring creates and configures an `HttpSecurity` builder.
    
2. Spring injects that builder into our `@Bean` method.
    
3. We configure the builder.
    
4. We call `http.build()`.
    
5. The builder creates a `SecurityFilterChain`.
    
6. Spring registers the returned object as a bean.
    

The important relationship is:

```
Spring ApplicationContext
        |
        | Resolves method parameters
        v
securityFilterChain(HttpSecurity http)
        |
        | Configure security
        v
HttpSecurity Builder
        |
        | http.build()
        v
SecurityFilterChain Object
        |
        | Registered as a Bean
        v
Spring ApplicationContext
```

**Notice something important:** We are not creating `HttpSecurity` using `new HttpSecurity(...)`.

Spring Security provides the builder through its configuration infrastructure.

---

## 3. Can We Add Other Parameters Besides `HttpSecurity`?

**Absolutely!**

And this is the most important concept to understand.

Spring's dependency injection is not limited to constructors.

Spring can also inject dependencies into `@Bean` method parameters.

For example:

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http,
        PasswordEncoder passwordEncoder,
        UserDetailsService userDetailsService
) throws Exception {

    return http.build();
}
```

Spring can resolve all three parameters if suitable beans are available.

However, the example above doesn't actually use `passwordEncoder` or `userDetailsService`, so including those parameters is unnecessary.

Just because you **can** inject a dependency doesn't mean you **should**.

### A Practical Example

Imagine you create a custom authentication filter.

```
@Component
public class MyCustomFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        filterChain.doFilter(request, response);
    }
}
```

Now you want to add it to Spring Security's filter chain.

You can inject it directly into your configuration method:

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http,
        MyCustomFilter customFilter
) throws Exception {

    return http
            .authorizeHttpRequests(auth -> auth
                    .anyRequest().authenticated()
            )
            .httpBasic(Customizer.withDefaults())
            .addFilterBefore(
                    customFilter,
                    BasicAuthenticationFilter.class
            )
            .build();
}
```

Look at this:

```
HttpSecurity http,
MyCustomFilter customFilter
```

Spring provides both dependencies.

- `HttpSecurity` is provided by Spring Security.
    
- `MyCustomFilter` is provided by our application as a Spring bean.
    

We are using method-parameter dependency injection.

**Production note:** A servlet `Filter` declared as a `@Component` may also be automatically registered by Spring Boot outside the security chain. For a real custom security filter, avoid accidentally registering it twice. You can disable its servlet-container registration with a `FilterRegistrationBean`, while still adding it explicitly to the security chain.

---

## 4. Is Injecting `HttpSecurity` the Production Standard?

**Yes. It's the standard modern way to configure servlet-based HTTP security in Spring Security.**

For example:

```
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/public/**").permitAll()
                        .anyRequest().authenticated()
                )
                .httpBasic(Customizer.withDefaults())
                .build();
    }
}
```

This is a recommended approach for modern Spring Boot servlet applications.

But remember:

`**HttpSecurity**` **is not the only parameter you're allowed to use. It is simply the builder you need to construct this particular kind of security filter chain.**

In production, inject additional dependencies only when your security configuration actually needs them.

---

## 5. Why Not Use Constructor Injection Instead?

You could write:

```
@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final MyCustomFilter customFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        return http
                .addFilterBefore(
                        customFilter,
                        BasicAuthenticationFilter.class
                )
                .build();
    }
}
```

This also uses dependency injection.

The difference is **where the dependency is injected**.

|Method Parameter Injection|Constructor Injection|
|---|---|
|Dependency is provided when the bean factory method executes|Dependency is provided when the configuration object is constructed|
|Good for dependencies needed by one `@Bean` method|Good for dependencies shared across the configuration class|
|Keeps dependencies local to the method|Stores dependencies in fields|
|No fields required|Typically uses `private final` fields|

Both are valid.

For Spring Security configuration, keeping `HttpSecurity` as a method parameter is the normal approach.

For your own application dependencies, either constructor injection or bean-method parameter injection can be appropriate.

---

## 6. Can We Use Something Other Than `HttpSecurity`?

That depends on which application technology we are using.

### Spring MVC / Servlet-Based Application

We use:

```
HttpSecurity
```

And return:

```
SecurityFilterChain
```

### Spring WebFlux / Reactive Application

We use:

```
ServerHttpSecurity
```

And return:

```
SecurityWebFilterChain
```

For example:

```
@Bean
public SecurityWebFilterChain securityWebFilterChain(
        ServerHttpSecurity http
) {

    return http
            .authorizeExchange(exchange -> exchange
                    .anyExchange().authenticated()
            )
            .httpBasic(Customizer.withDefaults())
            .build();
}
```

Notice that these are two different security architectures.

|Spring MVC|Spring WebFlux|
|---|---|
|Servlet-based|Reactive|
|`HttpSecurity`|`ServerHttpSecurity`|
|`SecurityFilterChain`|`SecurityWebFilterChain`|
|Servlet `Filter`|WebFlux `WebFilter`|

For your Spring Boot REST API projects that use `spring-boot-starter-web`, you normally use `HttpSecurity`.

You cannot simply replace `HttpSecurity` with an unrelated class and expect it to build a servlet `SecurityFilterChain`.

---

## 7. What Happens If Spring Cannot Find a Parameter?

Imagine writing:

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http,
        MySecurityService securityService
) throws Exception {

    return http.build();
}
```

But `MySecurityService` is not registered as a Spring bean.

Spring cannot resolve that parameter.

The application context will normally fail to start with a dependency resolution error.

To fix it, make sure the dependency is registered.

For example:

```
@Service
public class MySecurityService {
}
```

Or:

```
@Bean
public MySecurityService mySecurityService() {
    return new MySecurityService();
}
```

Spring can then inject it.

---

## 8. The Whole Picture

Remember these important points:

|Concept|Explanation|
|---|---|
|`@Bean`|Registers the method's returned object as a Spring bean|
|`HttpSecurity`|Builder for servlet-based HTTP security|
|Method parameter injection|Spring resolves dependencies when invoking the bean method|
|`http.build()`|Builds the configured `SecurityFilterChain`|
|Additional parameters|Allowed if Spring can resolve them|
|Production approach|Inject only the dependencies needed by the configuration|
|`ServerHttpSecurity`|Reactive equivalent used with Spring WebFlux|

### Final Mental Model

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http,
        MyCustomFilter customFilter
) throws Exception {

    return http
            .addFilterBefore(
                    customFilter,
                    BasicAuthenticationFilter.class
            )
            .build();
}
```

Read this code in plain English:

> Spring, I want to create a `SecurityFilterChain` bean. To create it, I need an `HttpSecurity` builder and my custom filter. Please provide these dependencies, and I will configure the builder and return the resulting security filter chain.

**The key lesson:**

`HttpSecurity` is not a mandatory parameter because of Java's method syntax. It is the standard Spring Security builder for creating servlet-based HTTP security configurations.

You can inject other dependencies alongside it, just like you do with your services, controllers, and repositories.



[[Spring Security]]