

# Understanding UserDetails in Spring Security

In the last lesson, `UserDetailsService` loaded a user and returned a `UserDetails` object. This lesson explains what that object is, why Spring Security needs it, and how to build your own.

## Part 1: Why Spring Security Needs Its Own User Type

Your application already has a user class, `AppUser`. It has an `id`, a `username`, a `password`, and a `role`, and it maps to a database table. Spring Security doesn't know anything about your class, though. It only knows the interface `UserDetails`.

Spring Security needs a standard shape so it can perform the same checks for every application, whatever your entity looks like. For every login, it needs to know:

- Who the user is (username)
- What the stored password hash is
- What the user is allowed to do (authorities)
- Whether the account is usable right now (enabled, locked, expired)

`UserDetails` is the adapter between your data and Spring's security logic. Your `UserDetailsService` converts an `AppUser` into a `UserDetails`, and from then on Spring works only with that standard object.

```
Your world                     Spring Security's world
──────────                     ───────────────────────
AppUser (entity)   ──────►     UserDetails (interface)
(your fields)                  (standard methods)
```

## Part 2: The Interface and Its Methods

`UserDetails` lives in the package `org.springframework.security.core.userdetails`. It declares seven methods:

|Method|Returns|Purpose|
|---|---|---|
|`getUsername()`|`String`|The login name|
|`getPassword()`|`String`|The stored password **hash** (not the raw password)|
|`getAuthorities()`|`Collection<? extends GrantedAuthority>`|The user's roles and permissions|
|`isEnabled()`|`boolean`|`false` means the account is disabled|
|`isAccountNonLocked()`|`boolean`|`false` means the account is locked (for example, after too many failed logins)|
|`isAccountNonExpired()`|`boolean`|`false` means the account has expired|
|`isCredentialsNonExpired()`|`boolean`|`false` means the password must be changed|

The last four methods have confusing names. Each one uses the double negative "NonX", so `true` means the account is **good**. `isAccountNonLocked()` returns `true` for an unlocked account. Remember that `true` is the healthy value.

Spring checks these flags **before** it compares passwords. If `isEnabled()` returns `false`, Spring throws `DisabledException` and never checks the password. The order of checks matters for security. A disabled account should not reveal whether the password was correct.

## Part 3: GrantedAuthority and the ROLE_ Prefix

`getAuthorities()` returns a collection of `GrantedAuthority` objects. Each one is a single permission or role, and the usual implementation is `SimpleGrantedAuthority`.

```java
new SimpleGrantedAuthority("ROLE_ADMIN")
```

Spring Security distinguishes between two kinds of entries:

- **Roles** are coarse groups, such as `ROLE_USER` or `ROLE_ADMIN`. By convention they start with `ROLE_`.
- **Authorities** are fine-grained permissions, such as `READ_REPORTS` or `DELETE_ORDERS`. They have no prefix.

The prefix matters because of how rules are checked:

```java
.requestMatchers("/admin/**").hasRole("ADMIN")      // looks for "ROLE_ADMIN"
.requestMatchers("/reports/**").hasAuthority("READ_REPORTS")  // looks for "READ_REPORTS" exactly
```

`hasRole("ADMIN")` adds `ROLE_` for you and searches for `ROLE_ADMIN`. If your stored authority is just `ADMIN`, the rule fails silently with a 403 error. This is one of the most common mistakes beginners make.

## Part 4: The Built-in User Class

Spring provides a ready-made implementation called `User`. The builder you used earlier is a convenient way to create one:

```java
UserDetails user = User.withUsername("alice")   // 1. start the builder with the username
        .password("$2a$10$N9qo8u...")          // 2. the stored BCrypt hash
        .roles("USER")                          // 3. adds ROLE_USER
        .disabled(false)                        // 4. optional: default is enabled
        .accountLocked(false)                   // 5. optional: default is unlocked
        .accountExpired(false)                  // 6. optional: default is not expired
        .credentialsExpired(false)              // 7. optional: default is not expired
        .build();                               // 8. create the immutable UserDetails object
```

Each step explained:

1. `withUsername` starts a builder and sets the username. The builder pattern lets you set optional values in any order.
2. `password` stores the hash. Pass the hash here, never the raw password, and Spring will compare it using your `PasswordEncoder`.
3. `roles` takes one or more role names without the prefix and adds `ROLE_` to each one.
4. to 7. These flags have safe defaults (`enabled`, unlocked, unexpired). Setting them explicitly makes your intent visible to anyone reading the code.
5. `build` creates the object. The result is immutable, so nothing can change its values after creation.

The built-in `User` works well for simple cases. For real applications, you usually want to keep the data in your own entity, which is where a custom implementation comes in.

## Part 5: Writing Your Own UserDetails Implementation

There are two ways to connect your entity to `UserDetails`:

1. **Make the entity implement `UserDetails` directly.** This is short but mixes database concerns with security concerns.
2. **Write a wrapper class** that implements `UserDetails` and holds your entity. This keeps the two concerns separate and is the approach most teams use.

We'll use the wrapper. Assume `AppUser` now has an `enabled` field, which is a useful addition:

```java
@Column(nullable = false)
private boolean enabled = true;   // new column in AppUser

public boolean isEnabled() { return enabled; }
```

Next, the wrapper class:

```java
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

public class AppUserPrincipal implements UserDetails {

    private final AppUser user;   // the entity we are wrapping

    public AppUserPrincipal(AppUser user) {
        this.user = user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // Convert the single stored role "USER" into the authority "ROLE_USER"
        return List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole()));
    }

    @Override
    public String getPassword() {
        return user.getPassword();   // the stored hash
    }

    @Override
    public String getUsername() {
        return user.getUsername();
    }

    @Override
    public boolean isEnabled() {
        return user.isEnabled();     // reads the database column
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;                 // no locking feature yet, so every account is unlocked
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;                 // no expiry feature yet
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;                 // passwords never expire in this example
    }

    // Extra method: lets controllers read the database id without touching the entity
    public Long getId() {
        return user.getId();
    }
}
```

What this class does:

- **`private final AppUser user`** keeps the entity inside the wrapper. The wrapper reads from it and never changes it.
- **`getAuthorities()`** converts your simple role string into the `ROLE_` form Spring expects. This is the one place where the conversion happens, so the rest of the app can keep using plain role names.
- **`getPassword()` and `getUsername()`** pass the stored values through unchanged.
- **`isEnabled()`** is the one flag that reads real data. The other three return `true` because the feature doesn't exist yet. Returning `true` is correct here, because a constant `false` would lock out every user.
- **`getId()`** is an extra method. `UserDetails` doesn't require it, but it's useful in controllers, so we add it.

Now update the service to return the wrapper:

```java
@Override
public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
    AppUser user = repository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

    return new AppUserPrincipal(user);   // wrap the entity instead of using User.withUsername(...)
}
```

Only the return line changed. `DaoAuthenticationProvider` still receives a `UserDetails`, so the rest of Spring Security works without modification. This is the purpose of an interface: you change the implementation and the consumers don't notice.

## Part 6: How Spring Uses UserDetails During a Request

Here is the full path through a login request.

```
1. Request arrives with Authorization: Basic ...
          │
2. DaoAuthenticationProvider calls loadUserByUsername("alice")
          │
          ▼
3. You return a UserDetails (AppUserPrincipal)
          │
4. Spring checks isEnabled(), isAccountNonLocked(), and so on
          │   (any false → exception, stop here)
          ▼
5. Spring calls passwordEncoder.matches(typed, getPassword())
          │   (false → BadCredentialsException)
          ▼
6. Spring builds an Authentication object:
       principal   = your AppUserPrincipal
       authorities = result of getAuthorities()
          │
          ▼
7. Authentication is stored in the SecurityContext for this request
          │
          ▼
8. Your controller and @PreAuthorize rules read from that context
```

Step 6 is the key idea. After login, the `UserDetails` object becomes the **principal**, which means "who is making this request." Everything downstream uses it.

## Part 7: Reading the Current User

Once a request is authenticated, your controller can access the `UserDetails` in two ways.

**Option A: `@AuthenticationPrincipal`** (recommended)

```java
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProfileController {

    @GetMapping("/me")
    public String me(@AuthenticationPrincipal AppUserPrincipal principal) {
        // Spring injects the principal stored in the SecurityContext for this request
        return "Logged in as " + principal.getUsername() + " (id " + principal.getId() + ")";
    }
}
```

`@AuthenticationPrincipal` tells Spring to fill the parameter with the current principal. You get your own type back, so you can call `getId()` directly without casting.

**Option B: `SecurityContextHolder`** (useful deep in service code)

```java
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

Authentication auth = SecurityContextHolder.getContext().getAuthentication();
AppUserPrincipal principal = (AppUserPrincipal) auth.getPrincipal();
```

This works anywhere in the request thread, but the cast is unsafe if the principal is not your type (for example, with anonymous users). Prefer `@AuthenticationPrincipal` in controllers.

Test it on Debian with a user who has a valid login:

```bash
curl -u alice:secret123 http://localhost:8080/me
# Output: Logged in as alice (id 1)
```

## Part 8: Testing the Disabled Flag

To see `isEnabled()` in action, disable a user directly in the H2 console:

```sql
UPDATE app_users SET enabled = FALSE WHERE username = 'alice';
```

Then try logging in again:

```bash
curl -i -u alice:secret123 http://localhost:8080/me
# Output: HTTP/1.1 401 Unauthorized
```

The password is correct, but Spring rejected the login before comparing it, because `isEnabled()` returned `false`. Spring throws a `DisabledException`, which is converted into a 401 response.

## Part 9: Summary

|Concept|What it means|
|---|---|
|`UserDetails`|Spring Security's standard view of a user|
|`getAuthorities()`|Roles and permissions, with `ROLE_` prefix for roles|
|`getPassword()`|The stored hash, compared using `PasswordEncoder`|
|`isEnabled()`, `isAccountNonLocked()`, and so on|Account health flags, checked before the password|
|`User.withUsername(...)`|Built-in implementation, good for simple cases|
|Wrapper class|Your own implementation, keeps entity and security concerns separate|
|`@AuthenticationPrincipal`|Gives a controller the current user|






[[Spring Security]]