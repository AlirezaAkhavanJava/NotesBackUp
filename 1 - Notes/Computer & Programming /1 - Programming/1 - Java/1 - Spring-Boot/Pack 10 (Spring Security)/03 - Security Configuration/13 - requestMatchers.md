
# Request Matchers in Spring Security

A **request matcher** is the piece of Spring Security that answers one simple question: "Does this incoming HTTP request match the pattern I care about?" Every time someone calls your app, Spring Security needs to decide which rules apply to that request. Request matchers are how you point at the right requests, such as "everything under `/admin`" or "only POST requests to `/api/orders`".

You can think of them as the address labels on your security rules. A rule on its own says "must be logged in" or "must be an admin". The request matcher says _which doors_ that rule guards. Once you are comfortable with them, writing a security configuration feels much more natural.

## The problem it solves

Not every URL in your app deserves the same protection. The home page and login page should be open to everyone. `/profile` needs a logged-in user. `/admin/**` needs an admin. Spring Security needs a way to sort requests into these groups, and request matchers do the sorting.

## Where you use them

The most common place is the `SecurityFilterChain` bean:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(auth -> auth
        .requestMatchers("/", "/login", "/css/**").permitAll()
        .requestMatchers("/admin/**").hasRole("ADMIN")
        .requestMatchers(HttpMethod.POST, "/api/orders").authenticated()
        .anyRequest().authenticated()
    );
    return http.build();
}
```

Line by line:

1. **`.requestMatchers("/", "/login", "/css/**").permitAll()`** says these URLs are open to everyone. The `**` means "this folder and everything inside it".
2. **`.requestMatchers("/admin/**").hasRole("ADMIN")`** says only users with the `ADMIN` role can reach anything under `/admin`.
3. **`.requestMatchers(HttpMethod.POST, "/api/orders")`** matches only `POST` requests to that URL. A `GET` to the same path would not match this rule.
4. **`.anyRequest().authenticated()`** is the catch-all. It covers every request that no earlier rule matched.

## Order matters

Spring Security checks the rules **from top to bottom** and uses the **first one that matches**. So put specific rules first and general ones last.

|Order|Result|
|---|---|
|`/admin/**` → admin, then `anyRequest()` → authenticated|Works as you expect|
|`anyRequest()` → authenticated, then `/admin/**` → admin|The admin rule is never reached|

In fact, Spring Security refuses to start if you put `anyRequest()` before other rules, which protects you from this mistake.

## Pattern syntax

The default matching uses Ant-style or path-pattern syntax:

|Pattern|Matches|
|---|---|
|`/login`|Exactly `/login`|
|`/users/*`|`/users/5`, but not `/users/5/orders`|
|`/users/**`|`/users/5`, `/users/5/orders`, and deeper|
|`/files/*.pdf`|Any `.pdf` directly in `/files`|
|`/users/{id}`|`/users/5`, with `id` captured as a variable|

## The kinds of matchers

Most of the time `requestMatchers("/path")` is all you need. When you need more control, there are a few other forms:

- **Method + path:** `requestMatchers(HttpMethod.DELETE, "/api/**")` for rules that depend on the HTTP verb.
- **`PathPatternRequestMatcher`:** the modern, explicit way to build a matcher from a path pattern. It is the standard in recent Spring Security versions.
- **`RegexRequestMatcher`:** matches the URL against a regular expression, for unusual patterns.
- **`AntPathRequestMatcher`:** the older Ant-style matcher, which you will see in older tutorials. It is deprecated in newer versions in favor of path patterns.
- **`RequestMatcher` interface:** write your own. It has one method, `matches(HttpServletRequest)`, which returns `true` or `false`. You can use this to match on a header, an IP address, or anything else in the request.

```java
RequestMatcher fromOffice = request -> "10.0.0.5".equals(request.getRemoteAddr());
```

## Request matchers in other places

They are not only for `authorizeHttpRequests`. You will meet them again here:

```java
http.csrf(csrf -> csrf.ignoringRequestMatchers("/api/webhooks/**"));
```

This turns off CSRF protection for the webhook paths only. You can also use them in `securityMatcher(...)` to say which requests an entire filter chain handles, which is useful when you have one chain for `/api/**` and another for the web pages.

## Common mistakes

- **Forgetting that `/admin/*` is not `/admin/**`.** The single star stops at one level.
- **Putting a general rule before a specific one.** The specific rule then never runs.
- **Using `mvcMatchers` or `antMatchers` from old tutorials.** Those were removed in Spring Security 6. Use `requestMatchers` instead.
- **Securing only the URL when the real danger is the method.** A `permitAll()` on `/api/orders` also opens `DELETE` unless you split the rule by method.

## Related concept: `@PreAuthorize`

Request matchers protect **URLs**. `@PreAuthorize("hasRole('ADMIN')")` protects **methods** in your Java code, such as a service method. Many projects use both. Matchers give a broad outer fence, and `@PreAuthorize` adds fine-grained checks inside.




[[Spring Security]]