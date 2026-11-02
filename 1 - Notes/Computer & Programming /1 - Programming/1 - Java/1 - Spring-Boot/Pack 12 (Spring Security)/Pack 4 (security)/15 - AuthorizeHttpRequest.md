
```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig {


    @Bean
    public SecurityFilterChain securityFilterChain
     (HttpSecurity http) throws Exception {
        http.
                authorizeHttpRequests(
                        request -> request.anyRequest().authenticated()
                );
        return http.build();

    }

}
```

# `authorizeHttpRequests`: Deciding Who Can Reach Which URL

## What it is

`authorizeHttpRequests` is a method on `HttpSecurity`, the object Spring Security gives you to describe how HTTP requests should be secured. It takes a configuration lambda, and inside that lambda you write **rules**. Each rule has two parts:

1. **A matcher**, which decides whether a rule applies to an incoming request. It looks at things like the URL path and the HTTP method.
2. **An access decision**, which says what the requester must be to get through. Examples are "anyone," "must be logged in," or "must have the ADMIN role."

In your code:

```java
request -> request.anyRequest().authenticated()
```

This reads as: "For any request whatsoever, the requester must be authenticated." The matcher is `anyRequest()`, which matches everything. The decision is `authenticated()`, which means the user must have logged in.

## The problem it solves

Without this, every endpoint in your application is open to anyone who can reach the server. Consider a Spring Boot app with these endpoints:

- `GET /api/products` (public catalog)
- `POST /api/orders` (only logged-in customers)
- `DELETE /api/users/{id}` (only admins)

Spring Security applies a default filter chain to every request. Your `SecurityFilterChain` bean replaces that default with the rules you define. `authorizeHttpRequests` is the part of that chain that answers the question: **given this request and this user, is access allowed?**

Without it, you would have to write the access check inside every controller method by hand, which is repetitive and easy to forget. Centralizing the rules in one place means one forgotten check can't silently expose an endpoint.

## How it works, step by step

When an HTTP request arrives, the following happens in order:

1. The request enters the **filter chain**, a series of filters, one of which is the authorization filter created by `authorizeHttpRequests`.
2. The authorization filter takes the request and walks through your rules **from top to bottom**.
3. The first rule whose matcher fits the request is used. The rest are ignored.
4. That rule's decision is checked against the current user's `Authentication` object, which holds who they are and what authorities they have.
5. If the check passes, the request continues to your controller. If it fails, the request is stopped and the client gets an error response (typically 401 if the user isn't logged in, 403 if they are logged in but not allowed).

The "first match wins" rule is the most important thing to internalize. Order matters.

## Example 1: Your current code, traced through

```java
http.authorizeHttpRequests(
        request -> request.anyRequest().authenticated()
);
```

What each piece does:

- `http.authorizeHttpRequests(...)` registers the authorization rules with the filter chain.
- The lambda's parameter `request` is a registry object. You call methods on it to add rules.
- `.anyRequest()` creates a matcher that accepts every request, regardless of URL or method.
- `.authenticated()` sets the decision to "the user must be logged in."

Result: every request, to every URL, requires a logged-in user. Since this configuration sets no login method (no form login, no HTTP Basic), nobody can log in, so every request will be rejected. This is correct behavior, but it's a useful thing to notice: securing everything is only half the setup. You also need a way for users to prove who they are.

## Example 2: Public and protected endpoints

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(request -> request
            .requestMatchers("/api/products/**").permitAll()
            .requestMatchers("/api/orders/**").authenticated()
            .anyRequest().denyAll()
    );
    return http.build();
}
```

What each rule does:

- `.requestMatchers("/api/products/**")` matches any path starting with `/api/products/`. The `**` means "this path and anything beneath it." `permitAll()` lets everyone through, logged in or not. Use this for public data like a product catalog.
- `.requestMatchers("/api/orders/**")` matches order-related paths. `authenticated()` requires a logged-in user.
- `.anyRequest().denyAll()` is the catch-all. Any request that didn't match the rules above is refused. This is a strong default: a newly added endpoint is locked until you explicitly open it.

Notice that the more specific rules come first. If `anyRequest()` came first, it would match everything and the later rules would never run.

## Example 3: Role-based access

```java
http.authorizeHttpRequests(request -> request
        .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/products/**").hasRole("ADMIN")
        .requestMatchers(HttpMethod.DELETE, "/api/products/**").hasRole("ADMIN")
        .requestMatchers("/api/orders/**").hasAnyRole("CUSTOMER", "ADMIN")
        .anyRequest().authenticated()
);
```

What each rule does:

- `HttpMethod.GET` restricts a matcher to one HTTP verb. Anyone can read products.
- `hasRole("ADMIN")` requires the user to have the authority `ROLE_ADMIN`. Spring adds the `ROLE_` prefix for you when you use `hasRole`. If you use `hasAuthority("ROLE_ADMIN")` instead, you must write the prefix yourself.
- `hasAnyRole("CUSTOMER", "ADMIN")` passes if the user has either role.
- The final `anyRequest().authenticated()` covers anything not listed above. It means "any other endpoint still needs a login."

This pattern, restricting by both URL and method, is how most real applications are structured.

## Example 4: Using a custom authority

Roles are a convenient shorthand, but you can also check any authority string:

```java
http.authorizeHttpRequests(request -> request
        .requestMatchers("/api/reports/**").hasAuthority("REPORT_READ")
        .anyRequest().authenticated()
);
```

Here the rule checks for the exact authority `REPORT_READ`. This is useful when permissions are finer-grained than roles, for example when one role should be able to read reports but not change them.

## Example 5: Matching by pattern at the start of the path

If you need to match a pattern in the middle of a path, Spring offers `MvcRequestMatcher`-style patterns through `requestMatchers` as well:

```java
http.authorizeHttpRequests(request -> request
        .requestMatchers("/api/users/*/profile").authenticated()
        .requestMatchers("/api/**").hasRole("USER")
        .anyRequest().permitAll()
);
```

What this does:

- `*` matches exactly one path segment. So `/api/users/42/profile` matches, but `/api/users/42/x/profile` does not.
- `/api/**` matches everything under `/api/`, with any depth.

Think of `*` as "one segment of any value" and `**` as "any number of segments."

## Example 6: Seeing the rule order problem

This is a mistake many beginners make:

```java
http.authorizeHttpRequests(request -> request
        .anyRequest().authenticated()
        .requestMatchers("/api/products/**").permitAll()
);
```

This configuration throws an exception at startup. Once you call `anyRequest()`, Spring won't let you add more matchers after it, because they could never be reached. The catch-all must always be last.

## Common decisions the rule ends with

|Decision|Meaning|
|---|---|
|`permitAll()`|Anyone, logged in or not|
|`denyAll()`|Nobody|
|`authenticated()`|Any logged-in user|
|`hasRole("X")`|Must have `ROLE_X`|
|`hasAnyRole("X", "Y")`|Must have at least one of these roles|
|`hasAuthority("X")`|Must have the exact authority string `X`|




[[Spring Security]]