


`AbstractHttpConfigurer` is the base class for one self-contained piece of HTTP security setup. Form login, CSRF protection, CORS, session management, and OAuth2 login are each built as a subclass of it. When you write `http.csrf(...)` or `http.formLogin(...)`, you are using one of these configurers behind the scenes.

You can extend it yourself to bundle your own filters and settings (for example, "our company's JWT setup") into one reusable unit. You then plug it into any `HttpSecurity` with a single line, instead of copying the same filter and session settings into every project. This lesson covers how the class works, how Spring uses it, and how to write your own.

---

## The problem it solves

Say you have a custom JWT filter. To make it work, your `SecurityFilterChain` needs to:

1. Disable CSRF.
2. Make sessions stateless.
3. Create the filter with the right `AuthenticationManager`.
4. Insert the filter before `UsernamePasswordAuthenticationFilter`.

That is four steps, and they all belong together. If you paste them into every security config, you will eventually forget one, and the app will break in a confusing way.

A configurer packs those steps into one class, so they travel together:

```java
http.with(new JwtConfigurer(), jwt -> jwt.secret("..."));
```

---

## The big picture: three types to know

|Type|What it is|Role|
|---|---|---|
|`HttpSecurity`|The builder you get in your config method|Collects settings and builds the `SecurityFilterChain`|
|`SecurityConfigurer`|An interface with `init()` and `configure()`|"I know how to configure part of the builder"|
|`AbstractHttpConfigurer`|An abstract class that implements `SecurityConfigurer` for `HttpSecurity`|The one you extend, with helpful extras|

Its signature is:

```java
public abstract class AbstractHttpConfigurer<T extends AbstractHttpConfigurer<T, B>, B extends HttpSecurityBuilder<B>>
```

The two generics look scary, but they are simple:

- `T` is your own class. It lets methods return `this` with the correct type, so your fluent calls chain properly.
- `B` is the builder type, which is almost always `HttpSecurity`.

So your class declaration will look like this:

```java
public class JwtConfigurer extends AbstractHttpConfigurer<JwtConfigurer, HttpSecurity>
```

---

## The lifecycle: `init()` then `configure()`

Spring builds the filter chain in phases. Every registered configurer goes through them in this order:

|Phase|Method|What you do here|
|---|---|---|
|1|`init(http)`|Set up shared state and tweak other parts of the config (disable CSRF, set session policy)|
|2|_(Spring sets up the `AuthenticationManager`)_|Nothing, this happens between phases|
|3|`configure(http)`|Create filters and add them to the chain|

All configurers finish `init()` before any of them runs `configure()`. This means that by the time `configure()` runs, every other configurer has already made its changes. That is why filters are created in `configure()`: everything they depend on is ready.

---

## Built-in examples

You have already used subclasses of `AbstractHttpConfigurer`:

|DSL call|Configurer class|
|---|---|
|`http.csrf(...)`|`CsrfConfigurer`|
|`http.formLogin(...)`|`FormLoginConfigurer`|
|`http.cors(...)`|`CorsConfigurer`|
|`http.sessionManagement(...)`|`SessionManagementConfigurer`|
|`http.httpBasic(...)`|`HttpBasicConfigurer`|

That is why you can write `csrf.disable()`. The base class gives every configurer a `disable()` method.

---

## Building your own: a JWT example

Here is a full custom configurer, followed by a line-by-line walkthrough.

```java
public class JwtConfigurer extends AbstractHttpConfigurer<JwtConfigurer, HttpSecurity> {

    private String headerName = "Authorization";
    private String secret;

    public JwtConfigurer headerName(String headerName) {
        this.headerName = headerName;
        return this;
    }

    public JwtConfigurer secret(String secret) {
        this.secret = secret;
        return this;
    }

    @Override
    public void init(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable());
        http.sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
    }

    @Override
    public void configure(HttpSecurity http) throws Exception {
        AuthenticationManager authManager = http.getSharedObject(AuthenticationManager.class);
        JwtAuthFilter filter = new JwtAuthFilter(authManager, headerName, secret);
        http.addFilterBefore(filter, UsernamePasswordAuthenticationFilter.class);
    }
}
```

**Walkthrough:**

- **`extends AbstractHttpConfigurer<JwtConfigurer, HttpSecurity>`** says that this is a configurer for `HttpSecurity`, and that its own type is `JwtConfigurer`.
- **`headerName` and `secret` fields** are the options your users can change. `headerName` has a sensible default.
- **`headerName(...)` and `secret(...)` methods** are the fluent setters. They return `this` so calls can chain: `jwt.headerName("X-Auth").secret("abc")`.
- **`init(...)`** changes _other_ parts of the security config. Here it turns off CSRF (not needed for stateless token auth) and makes sessions stateless.
- **`configure(...)`** builds the actual filter.
- **`http.getSharedObject(AuthenticationManager.class)`** fetches an object that `HttpSecurity` keeps for configurers to share. Spring has prepared the `AuthenticationManager` by this phase.
- **`http.addFilterBefore(...)`** places your filter just before the standard username/password filter in the chain.

### Using it

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .with(new JwtConfigurer(), jwt -> jwt
            .headerName("X-Auth")
            .secret("change-me"));
    return http.build();
}
```

`.with(configurer, customizer)` registers your configurer and then lets the lambda adjust its options.

If you read older tutorials, you will see `http.apply(new JwtConfigurer())` instead. `apply()` was deprecated in Spring Security 6.2 in favor of `with()`, and it is gone in newer versions, so use `with()`.

---

## Useful extras the base class gives you

|Method|What it does|
|---|---|
|`disable()`|Removes this configurer from the build, so `csrf.disable()` works|
|`and()`|Returns to the builder for chaining. This is the old non-lambda style and is being removed in newer versions, so prefer lambdas|
|`postProcess(...)`|Lets Spring finish wiring objects you create (injection, lifecycle callbacks)|

---

## Common pitfalls

1. **Don't also declare your filter as a `@Bean`.** Spring Boot automatically registers any `Filter` bean with the servlet container, so your filter would run twice: once outside the security chain and once inside. Create it with `new` inside `configure()`.
2. **Put filter creation in `configure()`, not `init()`.** In `init()`, other configurers may not have finished, so shared objects might be missing.
3. **Remember the filter's position.** `addFilterBefore` and `addFilterAfter` decide when your filter runs. Check the order if authentication behaves strangely.
4. **Don't build a configurer for a one-off.** If you need one filter in one app, adding it directly in the `SecurityFilterChain` bean is simpler. Configurers pay off when you reuse the setup or want a clean DSL.

---

## A quick related concept: `Customizer`

`Customizer<T>` is a functional interface with one method, `customize(T t)`. It is what makes the lambda style work. In `.csrf(csrf -> csrf.disable())`, the lambda is a `Customizer<CsrfConfigurer<HttpSecurity>>`. Spring creates the configurer and hands it to your lambda so you can adjust it. `.with(configurer, customizer)` uses the same idea.

---

## Recap

- `AbstractHttpConfigurer` packages one slice of HTTP security setup into a reusable class.
- Spring's own features (CSRF, form login, CORS) are built this way, so your custom ones work exactly like them.
- `init()` adjusts the shared configuration. `configure()` creates filters and adds them to the chain.
- You attach it with `http.with(new YourConfigurer(), customizer)`.




[[Spring Security]]