

## 1. The Problem It Solves

When configuring Spring Security, you've probably seen something like this:

```java
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http
) throws Exception {

    return http
            .httpBasic(Customizer.withDefaults())
            .build();
}
```

Look at this part:

```java
Customizer.withDefaults()
```

What exactly is `Customizer`? Is it a class? What does `withDefaults()` do? And can we write our own customization?

Let's understand it step by step.

## 2. What Is Customizer?

`Customizer<T>` is a **functional interface** provided by Spring Security.

Its package is:

```java
org.springframework.security.config.Customizer
```

Its definition is essentially:

```java
@FunctionalInterface
public interface Customizer<T> {

    void customize(T object);

    static <T> Customizer<T> withDefaults() {
        return object -> {};
    }
}
```

Let's break it down.

|Part|Meaning|
|---|---|
|`@FunctionalInterface`|The interface has one abstract method|
|`<T>`|Generic type representing the object being customized|
|`customize(T object)`|Receives an object and allows us to configure it|
|`withDefaults()`|Returns a customizer that makes no additional changes|

**Simple definition:**

`Customizer<T>` is a functional interface that allows us to configure an object using a lambda expression.

It isn't limited to authentication. Spring Security uses it throughout its configuration API.

---

## 3. Why Is It a Functional Interface?

Remember that Java allows us to use lambda expressions with functional interfaces.

For example:

```java
@FunctionalInterface
public interface Greeting {
    void sayHello(String name);
}
```

We can implement it using a lambda:

```java
Greeting greeting = name -> {
    System.out.println("Hello " + name);
};
```

The same idea applies to `Customizer<T>`.

```java
Customizer<StringBuilder> customizer = builder -> {
    builder.append("Hello Spring Security");
};
```

Then we can execute it:

```java
StringBuilder builder = new StringBuilder();

customizer.customize(builder);

System.out.println(builder);
```

Output:

```java
Hello Spring Security
```

Notice what's happening:

1. We create a `Customizer<StringBuilder>`.
    
2. The lambda receives a `StringBuilder` object.
    
3. The lambda modifies that object.
    
4. Calling `customize()` executes our customization.
    

That's the basic idea behind Spring Security's `Customizer` interface.

---

## 4. What Does `Customizer.withDefaults()` Mean?

Consider:

```
.httpBasic(Customizer.withDefaults())
```

`withDefaults()` returns a customizer whose lambda body is empty.

Conceptually:

```
Customizer.withDefaults()
```

is equivalent to:

```
customizer -> {}
```

So this:

```
http.httpBasic(Customizer.withDefaults());
```

is equivalent to:

```
http.httpBasic(basic -> {});
```

Both tell Spring Security:

> Enable HTTP Basic authentication using its standard configuration without applying additional customizations.

### Important Detail

`withDefaults()` itself doesn't configure anything.

It performs no operation.

The `httpBasic()` method enables and configures HTTP Basic authentication; the customizer simply doesn't change the default settings.

This distinction is important.

---

## 5. How Does Spring Security Use Customizer Internally?

Let's imagine Spring Security has a simplified configuration method:

```
public class SecurityBuilder {

    public void httpBasic(Customizer<BasicConfig> customizer) {

        BasicConfig config = new BasicConfig();

        customizer.customize(config);

        // Continue building the security configuration
    }
}
```

Now suppose we call:

```
builder.httpBasic(config -> {
    config.setEnabled(true);
});
```

Internally:

```
Our Lambda
    |
    v
Customizer<BasicConfig>
    |
    v
httpBasic(customizer)
    |
    v
Creates or retrieves BasicConfig
    |
    v
customizer.customize(config)
    |
    v
Applies our changes
    |
    v
Builds security configuration
```

This example is conceptual, not the actual Spring Security source code.

In the real framework, `HttpSecurity` works with security configurer objects that contribute to building the filter chain.

The key idea is the same: **Spring Security gives your lambda a configuration object, and you use its methods to customize security behavior.**

---

## 6. Writing Our Own Customizer

Consider this security configuration:

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http
) throws Exception {

    return http
            .authorizeHttpRequests(auth -> auth
                    .requestMatchers("/public/**").permitAll()
                    .requestMatchers("/admin/**").hasRole("ADMIN")
                    .anyRequest().authenticated()
            )
            .httpBasic(Customizer.withDefaults())
            .build();
}
```

Look at:

```
auth -> auth
        .requestMatchers("/public/**").permitAll()
        .anyRequest().authenticated()
```

This is also a `Customizer`!

More specifically, its type is:

```
Customizer<AuthorizeHttpRequestsConfigurer<HttpSecurity>
        .AuthorizationManagerRequestMatcherRegistry>
```

Don't worry about the long generic type.

The important concept is:

- Spring Security provides the authorization configuration object.
    
- We receive that object as `auth`.
    
- We call methods on it to define authorization rules.
    

### We Can Write It Differently

Instead of:

```
.authorizeHttpRequests(auth -> auth
        .anyRequest().authenticated()
)
```

We could write:

```
.authorizeHttpRequests(auth -> {
    auth.anyRequest().authenticated();
})
```

Both are valid.

The first uses an expression lambda.

The second uses a block lambda.

Neither lambda returns an authentication result. The `Customizer` method returns `void`.

---

## 7. Customizing HTTP Basic Authentication

We can replace `withDefaults()` with our own customization.

For example:

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http
) throws Exception {

    return http
            .authorizeHttpRequests(auth -> auth
                    .anyRequest().authenticated()
            )
            .httpBasic(basic -> basic
                    .realmName("MyApplication")
            )
            .build();
}
```

Here:

```
basic -> basic.realmName("MyApplication")
```

is our custom `Customizer`.

The `basic` variable represents an `HttpBasicConfigurer<HttpSecurity>` object provided by Spring Security.

We call:

```
.realmName("MyApplication")
```

to configure the realm name used by HTTP Basic authentication.

The realm may appear in an authentication challenge such as:

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="MyApplication"
```

So remember:

```
.httpBasic(Customizer.withDefaults())
```

means enable HTTP Basic without additional customization.

While:

```
.httpBasic(basic -> basic.realmName("MyApplication"))
```

means enable HTTP Basic and customize its realm.

---

## 8. Why Does Spring Security Use Customizer So Much?

Because it makes configuration easier to read and organize.

Compare these two approaches.

### Without a Lambda-Based API

Imagine configuring security like this:

```
HttpBasicConfigurer config = new HttpBasicConfigurer();

config.realmName("MyApplication");

http.apply(config);
```

This is only a conceptual example of a more manual configuration style.

### With Customizer

```
http.httpBasic(basic ->
        basic.realmName("MyApplication")
);
```

The second approach is shorter and keeps related configuration together.

This style is often called a **fluent configuration API** or **DSL (Domain-Specific Language)**.

Spring Security uses it extensively.

---

## 9. Other Places We Use Customizer

### Form Login

```
.formLogin(Customizer.withDefaults())
```

Enables form-based login with its standard configuration.

Or customize it:

```
.formLogin(form -> form
        .loginPage("/login")
        .permitAll()
)
```

Remember that using a custom login page means your application must provide that page.

### CSRF Protection

```
.csrf(Customizer.withDefaults())
```

Uses the standard CSRF configuration.

Or configure it:

```
.csrf(csrf -> csrf
        .ignoringRequestMatchers("/webhooks/**")
)
```

This excludes the specified paths from CSRF checks. Such exclusions should be made only when justified by the endpoint's security model.

### Session Management

```
.sessionManagement(session -> session
        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
)
```

Here, the lambda configures the session management behavior.

`STATELESS` tells Spring Security not to create or use an HTTP session to obtain the `SecurityContext`.

---

## 10. Can We Create a Customizer Separately?

Yes.

Instead of writing a lambda directly inside `authorizeHttpRequests()`, we can store it in a variable.

```
Customizer<AuthorizeHttpRequestsConfigurer<HttpSecurity>
        .AuthorizationManagerRequestMatcherRegistry> rules =
        auth -> auth
                .requestMatchers("/public/**").permitAll()
                .anyRequest().authenticated();
```

Then use it:

```
http.authorizeHttpRequests(rules);
```

This works because the method expects a `Customizer` of the appropriate type.

The lambda doesn't need to be written directly inside the method call.

That said, for simple security configurations, inline lambdas are generally easier to read.

---

## 11. Common Mistakes

|Mistake|Correct understanding|
|---|---|
|`Customizer` is a class|It is a functional interface|
|`withDefaults()` creates a new security filter|It returns a no-op customizer|
|`withDefaults()` turns every security feature on|The surrounding configuration method decides which feature to enable|
|Customizers must use `withDefaults()`|We can provide our own lambda|
|The lambda receives `HttpSecurity` every time|Its parameter type depends on the configuration method|
|`Customizer` is only used in Spring Security|It is commonly used in Spring Security, but the functional-interface concept applies more broadly|

---

## 12. The Whole Picture

Consider:

```
@Bean
public SecurityFilterChain securityFilterChain(
        HttpSecurity http
) throws Exception {

    return http
            .authorizeHttpRequests(auth -> auth
                    .requestMatchers("/public/**").permitAll()
                    .anyRequest().authenticated()
            )
            .httpBasic(Customizer.withDefaults())
            .build();
}
```

There are two different uses of `Customizer` here.

**First:**

```
.authorizeHttpRequests(auth -> auth
        .anyRequest().authenticated()
)
```

We provide a custom lambda to specify our authorization requirements.

**Second:**

```
.httpBasic(Customizer.withDefaults())
```

We provide an empty customizer because we don't need to change HTTP Basic's default configuration.

### Final Definition

`Customizer<T>` is a generic functional interface in Spring Security that accepts a configuration object and allows us to customize its behavior using a lambda expression.

`Customizer.withDefaults()` returns an empty customizer that makes no additional changes to the configuration object.

**Remember this mental model:**

```
Customizer<T>
      |
      +-- withDefaults()
      |       |
      |       +-- Use standard configuration
      |
      +-- Custom Lambda
              |
              +-- Modify configuration
```

The most important thing to understand is that `**Customizer**` **itself doesn't implement authentication or authorization. It is simply a mechanism for supplying configuration instructions to Spring Security.**



[[Spring Security]]