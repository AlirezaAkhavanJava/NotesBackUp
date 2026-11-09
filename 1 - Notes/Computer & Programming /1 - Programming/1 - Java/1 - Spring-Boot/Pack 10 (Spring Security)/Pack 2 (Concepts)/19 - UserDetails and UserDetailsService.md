

`UserDetails` is Spring Security's own description of "a user who is allowed to try to log in." It is a small interface that holds the facts Spring Security needs about one account: who it is, what its stored password is, what it may do, and whether the account is usable right now. `UserDetailsService` is the lookup side. It takes a username and returns a `UserDetails` for it.

You write the lookup yourself, because only your application knows where users live (PostgreSQL, SQLite, LDAP, anywhere). Spring Security defines the shape and does everything else: comparing passwords, checking account flags, and building the `Authentication` object. So these two types are the bridge between **your database** and **Spring Security's login machinery**.

---

## 1. Two types, two jobs

|Type|Job|Methods|
|---|---|---|
|`UserDetails`|Data holder for one account|7 getters and flags|
|`UserDetailsService`|Finds that data by username|1 method|

```java
public interface UserDetailsService {
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

Notice the name: `loadUserByUsername`. "Username" just means _your login identifier_. If you log in with email, the email arrives in that parameter.

---

## 2. The seven methods, grouped

You already saw the list. Here is how to think about them in three groups:

**Identity:** `getUsername()`, `getPassword()`  
**Permissions:** `getAuthorities()`  
**Account status:** `isAccountNonExpired()`, `isAccountNonLocked()`, `isCredentialsNonExpired()`, `isEnabled()`

The status flags use "non" because `true` means "fine." This trips everyone up once. Returning `true` from `isAccountNonLocked()` means the account is **not** locked.

Each flag maps to a different business rule:

|Flag returns `false`|Exception thrown|Typical use|
|---|---|---|
|`isAccountNonExpired`|`AccountExpiredException`|Trial or contract accounts|
|`isAccountNonLocked`|`LockedException`|Too many failed logins|
|`isCredentialsNonExpired`|`CredentialsExpiredException`|"Change password every 90 days"|
|`isEnabled`|`DisabledException`|Email not verified yet, user deactivated|

All four extend `AccountStatusException`, so you can catch them and show a precise message.

---

## 3. What happens during a login, step by step

This is the most important part. Remember `AuthenticationManager` from your earlier lesson? It delegates to a `ProviderManager`, which asks an `AuthenticationProvider`. For username/password logins that provider is `DaoAuthenticationProvider`. It is the one that uses your `UserDetailsService`.

Here is its logic, simplified:

```java
// inside DaoAuthenticationProvider (simplified)
String username = authentication.getName();

UserDetails user = userDetailsService.loadUserByUsername(username);   // 1. your code runs

preAuthenticationChecks(user);        // 2. isAccountNonLocked, isEnabled, isAccountNonExpired

if (!passwordEncoder.matches(rawPassword, user.getPassword())) {      // 3. compare passwords
    throw new BadCredentialsException("Bad credentials");
}

postAuthenticationChecks(user);       // 4. isCredentialsNonExpired

return UsernamePasswordAuthenticationToken.authenticated(
        user,                         // 5. principal = your UserDetails
        null,                         //    credentials cleared
        user.getAuthorities());       //    authorities copied from your UserDetails
```

Line by line:

1. Spring calls **your** `loadUserByUsername`. This is the only database trip.
2. The "account state" flags are checked **before** the password. A locked account fails fast.
3. The `PasswordEncoder` compares the typed password with the stored hash. With bcrypt, this is where the salt and cost factor in the hash get used (see your bcrypt lesson). That is why `getPassword()` must return the **encoded** hash, never plain text.
4. The "credentials expired" flag is checked after the password is proven correct.
5. A successful result is an `Authentication`. Your `UserDetails` becomes its **principal** and its authorities become the token's authorities. Remember the `Authentication` interface you learned: `principal`, `credentials`, `authorities`. Now you can see where each one comes from.

---

## 4. Writing the service

```java
@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("No user with email " + email));
    }
}
```

Short and direct. Two rules:

- **Never return `null`.** If nothing is found, throw `UsernameNotFoundException`.
- **Don't check the password here.** Just load. `DaoAuthenticationProvider` does the checking.

If this is the only `UserDetailsService` bean in your app, Spring Boot wires it in automatically. If you build the provider yourself in your security config, you pass the service to it explicitly:

```java
@Bean
public AuthenticationProvider authenticationProvider(AppUserDetailsService uds,
                                                     PasswordEncoder encoder) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider(uds);
    provider.setPasswordEncoder(encoder);
    return provider;
}
```

---

## 5. Three ways to produce a `UserDetails`

### Option A: your entity implements it

You saw this one earlier. It is the shortest, but it mixes a persistence concern (JPA entity) with a security concern.

### Option B: Spring's built-in `User` builder

Good for quick setups and for returning from a service without touching your entity:

```java
return org.springframework.security.core.userdetails.User
        .withUsername(user.getEmail())
        .password(user.getPassword())
        .authorities(user.getRole().name())
        .accountLocked(!user.isActive())
        .build();
```

The downside is that `getPrincipal()` later returns this plain object. It has no `id` and no `fullName`, so you must look the user up again to get them.

### Option C: a small wrapper class (often the cleanest)

Your entity stays clean, and your principal can carry extra data:

```java
public class AppUserPrincipal implements UserDetails {

    private final User user;                     // your JPA entity

    public AppUserPrincipal(User user) { this.user = user; }

    public Long getId() { return user.getId(); } // extra, for your own code

    @Override public String getUsername() { return user.getEmail(); }
    @Override public String getPassword() { return user.getPassword(); }
    @Override public Collection<? extends GrantedAuthority> getAuthorities() {
        return user.getRole().getAuthorities();   // see section 6
    }
    @Override public boolean isEnabled()               { return user.isActive(); }
    @Override public boolean isAccountNonLocked()      { return !user.isLocked(); }
    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
}
```

Then in a controller you can read the current user's id without any repository call. This connects to your lesson on how the `Authentication` object replaces repeated lookups:

```java
@GetMapping("/me")
public Long me(@AuthenticationPrincipal AppUserPrincipal principal) {
    return principal.getId();
}
```

---

## 6. Authorities: what `getAuthorities()` should return

Each authority is a `GrantedAuthority`, which is really just a string wrapper. Your roles-and-permissions lesson applies directly here:

```java
List.of(new SimpleGrantedAuthority("ROLE_ADMIN"),   // a role (prefix ROLE_)
        new SimpleGrantedAuthority("user:delete")); // a permission
```

- `hasRole("ADMIN")` looks for `ROLE_ADMIN`.
- `hasAuthority("user:delete")` looks for the exact string.

So whatever you return from `getAuthorities()` is exactly what your `hasRole`, `hasAuthority` and `@PreAuthorize` rules are matched against. A missing `ROLE_` prefix is the number one cause of surprise 403 errors.

---

## 7. Where `UserDetailsService` appears again: your JWT filter

In your JWT lessons, `JwtAuthenticationFilter` also calls `loadUserByUsername`. The reason is different from the login case:

```java
String email = jwtService.extractUserName(token);

if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {
    UserDetails userDetails = userDetailsService.loadUserByUsername(email);   // fresh load

    if (jwtService.isTokenValid(token, userDetails)) {
        UsernamePasswordAuthenticationToken authToken =
                new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authToken);
    }
}
```

There is no password check here, because the signed token already proves identity. The filter only needs a trusted `UserDetails` to build the `Authentication`. Loading fresh from the database also means a user who was disabled or had their role changed is respected on the very next request, even if their token is still unexpired. That is a real benefit.

---

## 8. Gotchas worth knowing

- **Hidden "user not found."** By default, `DaoAuthenticationProvider` converts `UsernameNotFoundException` into `BadCredentialsException`. The client can't tell "wrong email" from "wrong password." This is deliberate, to stop attackers from discovering which emails exist.
- **Credentials get erased.** After a successful login, `ProviderManager` calls `eraseCredentials()` on the result. Your principal's password may be `null` afterwards. Don't rely on `getPassword()` after authentication.
- **Principal can go stale.** The `UserDetails` stored in the session or `SecurityContext` is a snapshot. If you rename the user in the database, the old principal still holds the old name until the next login (or next JWT request, which reloads).
- **Entity as `UserDetails` and Lombok.** If you put `@Data` on such an entity, `equals`/`hashCode`/`toString` can pull in the password and lazy relations. Be careful, as you learned in the entity methods lesson.
- **Case sensitivity.** `findByEmail` is case-sensitive in PostgreSQL. Normalize emails (for example, lowercase) before saving and before looking up.

---

## 9. Related concepts, in short

- **`UserDetailsManager`**: extends `UserDetailsService` with `createUser`, `updateUser`, `deleteUser`, `changePassword`, `userExists`. `InMemoryUserDetailsManager` and `JdbcUserDetailsManager` implement it. Use it if you want Spring to manage users for you.
- **`UserDetailsPasswordService`**: lets Spring re-encode a password with a newer algorithm or stronger cost factor at login time, so old hashes upgrade themselves.
- **`CredentialsContainer`**: the small interface with `eraseCredentials()`. Spring's built-in `User` implements it, and your own principal can too.
- **`UserDetailsChecker`**: the hook that runs the four status-flag checks. You can replace it if you need custom rules.

---

## Quick recap

1. `UserDetails` = seven methods: three core (`username`, `password`, `authorities`) plus four status flags.
2. `UserDetailsService` = one method that finds a `UserDetails` or throws `UsernameNotFoundException`.
3. `DaoAuthenticationProvider` calls your service, checks flags, compares the bcrypt hash, then builds the `Authentication` with your `UserDetails` as the principal.
4. You can add as many extra fields as you like (id, fullName), but Spring Security only calls those seven.
5. Your JWT filter loads the same `UserDetails` again on every request, so changes in the database take effect immediately.



[[Spring Security]]