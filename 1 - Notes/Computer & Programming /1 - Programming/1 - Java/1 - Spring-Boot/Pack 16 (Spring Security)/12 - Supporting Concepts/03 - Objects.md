`java.util.Objects` is a small utility class that ships with Java (since Java 7). It contains static helper methods for the everyday chores you do with objects: checking for null, comparing two objects safely, building hash codes, and producing readable `toString()` output. You never create an instance of it. You just call `Objects.something(...)`.

In Spring Security, `Objects` doesn't appear as a "feature" you configure. It shows up in the code you write _around_ Spring Security: your custom `UserDetails`, your own authentication classes, your JWT filters, your permission checks. Security code is where a careless `null` or a sloppy `equals()` can turn into a real bug, so these helpers earn their place there. One honest note: Spring Security's own source mostly uses Spring's `Assert` class for validation, not `Objects`, so I'll cover that too.

## 1. The methods you'll actually use

|Method|What it does|Returns|
|---|---|---|
|`Objects.requireNonNull(x, "msg")`|Throws `NullPointerException` with your message if `x` is null|`x` itself|
|`Objects.equals(a, b)`|Null-safe `a.equals(b)`|`boolean`|
|`Objects.hash(a, b, c)`|Builds a hash code from several fields|`int`|
|`Objects.isNull(x)` / `nonNull(x)`|Same as `x == null` / `x != null`, handy in streams|`boolean`|
|`Objects.requireNonNullElse(x, def)`|Gives `x`, or `def` if `x` is null|`T`|
|`Objects.toString(x, "fallback")`|`String.valueOf`-like, with your own text for null|`String`|

A tiny example of the "null-safe" idea:

```java
String a = null;
String b = "ADMIN";

a.equals(b);               // NullPointerException!
Objects.equals(a, b);      // false, no crash
Objects.equals(null, null); // true
```

`Objects.equals(a, b)` is true when both are null, or when `a` is non-null and `a.equals(b)` is true. That's the whole rule.

## 2. Usage 1: fail fast in constructors

Imagine a custom class that holds a user's identity for security checks:

```java
public class AppPrincipal {

    private final Long id;
    private final String username;

    public AppPrincipal(Long id, String username) {
        this.id = Objects.requireNonNull(id, "id must not be null");
        this.username = Objects.requireNonNull(username, "username must not be null");
    }
}
```

Line by line:

- `Objects.requireNonNull(id, "...")` checks `id`. If it's null, the constructor stops right there with a clear message.
- If it's not null, the method returns `id`, so you can assign it in the same line. That's why you see `this.id = Objects.requireNonNull(...)`.
- The payoff: an `AppPrincipal` can never exist in a half-broken state. A principal with a null username silently flowing into your authorization logic is exactly the kind of bug you want to catch at creation time, not three layers later.

## 3. Usage 2: `equals()` and `hashCode()` in a custom `UserDetails`

Spring Security's `UserDetails` is the interface that describes a logged-in user. Spring Security's own `User` class implements `equals()` and `hashCode()` based on the username only. If you write your own `UserDetails`, you should do the same thoughtfully, because Spring Security uses these comparisons in places like session management (finding all sessions of one user in `SessionRegistry`).

```java
public class AppUserDetails implements UserDetails {

    private final String username;
    private final String password;
    private final Collection<? extends GrantedAuthority> authorities;

    // constructor, getters, and other UserDetails methods omitted

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof AppUserDetails other)) return false;
        return Objects.equals(username, other.username);
    }

    @Override
    public int hashCode() {
        return Objects.hash(username);
    }
}
```

Line by line:

- `if (this == o) return true;` is a quick shortcut: same object, so equal.
- `o instanceof AppUserDetails other` checks the type and gives you a typed variable `other` in one step (Java 16+ pattern matching). It also returns false when `o` is null.
- `Objects.equals(username, other.username)` compares the usernames without risking a null crash.
- `Objects.hash(username)` produces a hash code from the same field. The rule you must follow: **whatever you compare in `equals()` must be what you hash in `hashCode()`**. If two objects are equal, they must have the same hash code.

Why only the username? Because identity of a user should not change when their password or authorities change. If you included `authorities` and an admin changed the user's role, the "same" user would suddenly look like a different one to a `Set` or `Map`.

## 4. Usage 3: null-safe checks on the security context

`SecurityContextHolder.getContext().getAuthentication()` can return `null` (for example, on a public endpoint with no login). A safe pattern:

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();

if (Objects.isNull(auth) || !auth.isAuthenticated()) {
    throw new AccessDeniedException("Not logged in");
}
```

Line by line:

- `Objects.isNull(auth)` is the same as `auth == null`. Some people find it reads nicely, but the real benefit is in streams (next section).
- The `||` short-circuits: if `auth` is null, Java never evaluates `auth.isAuthenticated()`, so there's no `NullPointerException`.

Another handy trick is comparing the logged-in user with the owner of a resource:

```java
boolean isOwner = Objects.equals(auth.getName(), document.getOwnerUsername());
```

If `getOwnerUsername()` is null for some old record, this simply gives `false`. It does not blow up.

## 5. Usage 4: streams over authorities

A user's roles come as a collection of `GrantedAuthority`. When you map them, nulls can sneak in. `Objects::nonNull` is a ready-made filter:

```java
Set<String> roles = auth.getAuthorities().stream()
        .map(GrantedAuthority::getAuthority)
        .filter(Objects::nonNull)
        .collect(Collectors.toSet());
```

Line by line:

- `.map(GrantedAuthority::getAuthority)` turns each authority object into its string, like `"ROLE_ADMIN"`.
- `.filter(Objects::nonNull)` keeps only non-null strings. This is a _method reference_, which is a short way to write `s -> s != null`.
- `.collect(Collectors.toSet())` gathers the results.

## 6. Usage 5: defaults and readable logging

```java
String clientIp = Objects.requireNonNullElse(request.getHeader("X-Forwarded-For"), request.getRemoteAddr());
```

If the header is missing (null), you get the fallback value. Careful: the fallback must not be null itself, or this method throws.

For audit logs, `Objects.toString(value, "anonymous")` is useful:

```java
log.info("Login attempt by {}", Objects.toString(request.getParameter("username"), "anonymous"));
```

## 7. A security-specific warning about `equals`

`Objects.equals()` is **not** a constant-time comparison. For ordinary things like usernames, that's fine. But never use it to compare secrets such as tokens, API keys, or password hashes. A normal comparison can stop at the first different character, which can leak timing information to an attacker.

- For passwords, use `PasswordEncoder.matches(raw, encoded)`.
- For raw secrets or tokens, use `MessageDigest.isEqual(byte[], byte[])`, which is constant-time.

## 8. Related concepts, in short

- **`org.springframework.util.Assert`**: Spring's own validation helper, and the one Spring Security uses internally. `Assert.notNull(x, "message")` throws `IllegalArgumentException` (not `NullPointerException`), and it has friends like `Assert.hasText(...)` and `Assert.isTrue(...)`. You'll see it all over Spring Security's source.
- **`org.springframework.util.ObjectUtils`**: Spring's utility for things `Objects` doesn't cover, such as `ObjectUtils.isEmpty(x)`, which works for null, empty strings, arrays, collections, and maps.
- **`Optional`**: a container that says "this value may be missing." Think of `Objects` as quick guards on a value, and `Optional` as a way to carry "maybe empty" through your method signatures. `userRepository.findByUsername(name)` returning `Optional<User>` is the classic case.

## 9. Quick rules of thumb

|Situation|Use|
|---|---|
|Constructor argument must exist|`Objects.requireNonNull`|
|Comparing two possibly-null values|`Objects.equals`|
|Writing `hashCode()`|`Objects.hash` with the same fields as `equals()`|
|Filtering nulls in a stream|`Objects::nonNull`|
|Null fallback value|`Objects.requireNonNullElse`|
|Comparing tokens or passwords|**Not** `Objects.equals`. Use `PasswordEncoder` or `MessageDigest.isEqual`|
|Validating in Spring-style code|`Assert.notNull` / `Assert.hasText`|






[[Spring Security]]