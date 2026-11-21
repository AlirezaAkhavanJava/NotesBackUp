A **role** in Spring Security is not a special built-in object. Spring Security only knows one thing: a `GrantedAuthority`, which is just a string such as `"order:read"` or `"ROLE_ADMIN"`. A _permission_ is one of those strings describing a single action. A _role_ is a name you give to a group of permissions, so you can assign the whole group to a user in one step instead of attaching ten permissions to every user.

So "creating a role as bundled permissions" means two things in your code: you define the permissions, you define which role contains which permissions, and then you flatten the role into a list of `GrantedAuthority` objects when Spring asks "what is this user allowed to do?" That list is the `authorities` field of the `Authentication` object you learned about earlier.

## Step 1: define the permissions

```java
public enum Permission {
    USER_READ("user:read"),
    USER_WRITE("user:write"),
    ORDER_READ("order:read"),
    ORDER_WRITE("order:write"),
    ORDER_DELETE("order:delete");

    private final String value;

    Permission(String value) { this.value = value; }

    public String getValue() { return value; }
}
```

Each constant is one small, specific action. Using an enum means a typo becomes a compile error instead of a silent security hole.

## Step 2: define the roles as sets of permissions

```java
public enum Role {
    USER(Set.of(
        Permission.USER_READ,
        Permission.ORDER_READ
    )),
    MANAGER(Set.of(
        Permission.USER_READ,
        Permission.ORDER_READ,
        Permission.ORDER_WRITE
    )),
    ADMIN(Set.of(
        Permission.USER_READ,
        Permission.USER_WRITE,
        Permission.ORDER_READ,
        Permission.ORDER_WRITE,
        Permission.ORDER_DELETE
    ));

    private final Set<Permission> permissions;

    Role(Set<Permission> permissions) { this.permissions = permissions; }

    public Set<Permission> getPermissions() { return permissions; }

    public List<SimpleGrantedAuthority> getAuthorities() {
        List<SimpleGrantedAuthority> authorities = new ArrayList<>();

        // every permission becomes an authority: "order:read", ...
        for (Permission p : permissions) {
            authorities.add(new SimpleGrantedAuthority(p.getValue()));
        }

        // the role itself also becomes an authority: "ROLE_ADMIN"
        authorities.add(new SimpleGrantedAuthority("ROLE_" + this.name()));

        return authorities;
    }
}
```

Line by line, the important part is `getAuthorities()`. It takes the bundle and turns it into the flat list Spring understands. `ADMIN` becomes `["user:read", "user:write", "order:read", "order:write", "order:delete", "ROLE_ADMIN"]`. The `ROLE_` prefix is a Spring convention: anything starting with `ROLE_` is treated as a role by `hasRole(...)`.

## Step 3: store the role on the user and expose it through UserDetails

```java
@Entity
public class User implements UserDetails {

    @Id @GeneratedValue
    private Long id;
    private String email;
    private String password;

    @Enumerated(EnumType.STRING)
    private Role role;

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return role.getAuthorities();   // <-- the bundle is expanded here
    }

    // getUsername(), getPassword(), isEnabled() ... as before
}
```

`@Enumerated(EnumType.STRING)` stores `"ADMIN"` in the column instead of the number `2`. If you ever reorder the enum, the numeric version would silently change everyone's role.

This is the link back to your earlier lessons: when `AuthenticationManager` succeeds, or when your `JwtAuthenticationFilter` loads the user and builds a `UsernamePasswordAuthenticationToken`, it passes `userDetails.getAuthorities()` as the authorities. With JWT, the token usually carries only the username. The authorities are loaded fresh from the database on each request, so changing a role takes effect immediately.

## Step 4: protect endpoints

You can check authorities in the filter chain:

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers(HttpMethod.GET, "/api/orders/**").hasAuthority("order:read")
    .requestMatchers(HttpMethod.DELETE, "/api/orders/**").hasAuthority("order:delete")
    .requestMatchers("/api/admin/**").hasRole("ADMIN")
    .anyRequest().authenticated()
);
```

Or on the method itself (you need `@EnableMethodSecurity` on a configuration class):

```java
@PreAuthorize("hasAuthority('order:delete')")
@DeleteMapping("/{id}")
public void delete(@PathVariable Long id) { ... }
```

Two details trip people up:

- `hasRole("ADMIN")` automatically looks for `ROLE_ADMIN`. Do not write `hasRole("ROLE_ADMIN")`.
- `hasAuthority("order:delete")` matches the exact string, with no prefix added.

A good habit is to protect endpoints with **permissions** (`hasAuthority`) and use roles only as the way to assign them. Then if `MANAGER` later gains delete rights, you change the enum once and no controller needs to change.

## Alternative: roles stored in the database

The enum approach is simple and fine when roles rarely change. If admins must create new roles at runtime, model it as tables instead:

```java
@Entity
public class RoleEntity {
    @Id @GeneratedValue
    private Long id;
    private String name;                      // "MANAGER"

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "role_permissions",
        joinColumns = @JoinColumn(name = "role_id"),
        inverseJoinColumns = @JoinColumn(name = "permission_id"))
    private Set<PermissionEntity> permissions;
}
```

Then `User` has a `RoleEntity`, and `getAuthorities()` loops over its permissions the same way as before. The trade-off is more tables, more setup, and a need to seed the data.

## Related concept: role hierarchy

If you want `ADMIN` to automatically include everything `MANAGER` can do, Spring has a `RoleHierarchy` bean (for example `"ROLE_ADMIN > ROLE_MANAGER > ROLE_USER"`). It builds on roles only and does not expand permissions for you, which is another reason the enum bundle above is often the clearer choice.

## Summary

1. A permission is a string authority; a role is a named set of those strings.
2. Define both as enums (or tables), and let the role expand itself in `getAuthorities()`.
3. Return that list from `UserDetails.getAuthorities()`, so it ends up in the `Authentication` object.
4. Protect endpoints with `hasAuthority(...)` for permissions and `hasRole(...)` for roles.

[[Spring Security]]