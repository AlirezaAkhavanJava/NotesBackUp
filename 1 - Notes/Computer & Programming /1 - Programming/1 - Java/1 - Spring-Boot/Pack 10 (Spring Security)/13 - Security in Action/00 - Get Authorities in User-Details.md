
`getAuthorities()` is one of the methods required by the `UserDetails` interface. Its job is to tell Spring Security _what a given user is allowed to do_ — it returns the set of permissions (roles and/or fine-grained permissions) attached to that user, as a collection of `GrantedAuthority` objects. Every access check you write later — `hasRole("ADMIN")`, `@PreAuthorize("hasAuthority('ORDER_DELETE')")`, `.anyRequest().authenticated()` — is ultimately reading from whatever this method returns.

```java
public interface GrantedAuthority extends Serializable {
    String getAuthority();
}
```

`GrantedAuthority` itself is a near-empty interface — one string, representing a single permission. `SimpleGrantedAuthority` is the plain implementation Spring provides:

```java
new SimpleGrantedAuthority("ROLE_ADMIN");
```

### Where the data comes from

`getAuthorities()` doesn't invent permissions — it converts whatever representation your entity stores into a `Collection<GrantedAuthority>`. How you store that representation is up to your design. Two common shapes:

**A. Comma-separated string on the entity** (what your `AppUser.roles` field does):

```java
@Override
public Collection<? extends GrantedAuthority> getAuthorities() {
    return Arrays.stream(user.getRoles().split(","))
        .map(String::trim)
        .filter(s -> !s.isEmpty())
        .map(SimpleGrantedAuthority::new)
        .toList();
}
```

Split the string, trim whitespace, drop empty tokens (guards against trailing commas), wrap each token in `SimpleGrantedAuthority`, collect into a list.

**B. A proper `Role`/`Permission` entity relationship** — if a user has a `Set<Role> roles` and each `Role` has a `Set<Permission> permissions`:

```java
@Override
public Collection<? extends GrantedAuthority> getAuthorities() {
    return user.getRoles().stream()
        .flatMap(role -> role.getPermissions().stream())
        .map(permission -> new SimpleGrantedAuthority(permission.getName()))
        .toList();
}
```

Same destination — a flat `Collection<GrantedAuthority>` — but sourced from relational data instead of a string. This is the shape you'd use once you've modeled roles as bundled permissions, which you've already learned separately.

### One naming rule to know

Spring Security treats the string `"ROLE_ADMIN"` and the string `"ADMIN"` differently depending on which check you use. `hasRole("ADMIN")` internally looks for an authority named `"ROLE_ADMIN"` — it adds the prefix for you. `hasAuthority("ADMIN")` looks for the literal string `"ADMIN"`, no prefix added. So whatever strings you put into `getAuthorities()` have to match the convention the checks elsewhere in your `SecurityFilterChain` expect — if you're using `hasRole(...)`, your stored strings need the `ROLE_` prefix; if you're using `hasAuthority(...)`, they don't.


[[Spring Security]]