
UserDetails and UserDetailsService are the two interfaces that let Spring Security talk to _your_ user data without knowing anything about your database or entity classes. `UserDetails` is a contract describing "what Spring Security needs to know about one user" — username, password, authorities, and a few status flags. `UserDetailsService` is a one-method contract describing "how to find that user" — given a username, return a `UserDetails` or throw. Together, they're the bridge: Spring Security's authentication machinery (`DaoAuthenticationProvider`, the `AuthenticationManager`, etc.) calls `UserDetailsService.loadUserByUsername(...)`, gets back a `UserDetails`, and uses it to check the password and build the `Authentication` object that ends up in the `SecurityContext`.

Since your user has exactly one fixed role (not a set of roles), the implementation is simpler than the textbook multi-role version — you don't need a collection of authorities, just one.

## Implementing `UserDetails`

`UserDetails` requires these methods:

```java
public interface UserDetails extends Serializable {
    Collection<? extends GrantedAuthority> getAuthorities();
    String getPassword();
    String getUsername();
    boolean isAccountNonExpired();
    boolean isAccountNonLocked();
    boolean isCredentialsNonExpired();
    boolean isEnabled();
}
```

You write a small adapter class that wraps your domain object and answers these questions from it. It is **not** your entity — it's a separate class whose only job is to satisfy this interface.

```java
public class AccountOwnerDetails implements UserDetails {

    private final String username;
    private final String passwordHash;
    private final boolean enabled;
    private final boolean locked;
    private final AccountOwnerRole role; // single fixed role, e.g. enum USER/ADMIN

    public AccountOwnerDetails(String username, String passwordHash,
                                boolean enabled, boolean locked, AccountOwnerRole role) {
        this.username = username;
        this.passwordHash = passwordHash;
        this.enabled = enabled;
        this.locked = locked;
        this.role = role;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // one role -> one authority, not a loop over a collection
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override
    public String getPassword() { return passwordHash; }

    @Override
    public String getUsername() { return username; }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return !locked; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return enabled; }
}
```

A few things worth being precise about here:

- `getAuthorities()` returns `List.of(...)` with exactly one element because you have exactly one role per user — there's no reason to model it as a mutable `Set` or loop over anything. If you later add multiple roles or fine-grained permissions, this is the only method that changes.
- The `"ROLE_"` prefix is a Spring Security convention, not optional decoration. `hasRole("ADMIN")` in your security config internally checks for an authority literally named `"ROLE_ADMIN"`. If you build the authority as just `"ADMIN"`, `hasRole("ADMIN")` will silently never match, and you'd have to use `hasAuthority("ADMIN")` instead. Prefixing here keeps `hasRole(...)` usable.
- `isAccountNonLocked()` is the _inverse_ of your locked flag — the interface asks "is it NOT locked", so you negate it. This is the one method people most often get backwards.
- `isAccountNonExpired()` and `isCredentialsNonExpired()` return `true` here because nothing in your design tracks expiry; if you never implement expiry, these should just always be `true`, not `false`.

## Implementing `UserDetailsService`

This interface has one method:

```java
public interface UserDetailsService {
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

Your implementation's only job is: take a username, look up the matching record through your repository, and if found, wrap it in your `UserDetails` adapter; if not found, throw `UsernameNotFoundException`.

```java
@Service
public class AccountOwnerDetailsService implements UserDetailsService {

    private final AccountOwnerRepository repository;

    public AccountOwnerDetailsService(AccountOwnerRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) {
        var owner = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "No account found for username: " + username));

        return new AccountOwnerDetails(
                owner.getUsername(),
                owner.getPasswordHash(),
                owner.isEnabled(),
                owner.isLocked(),
                owner.getRole()
        );
    }
}
```

`UsernameNotFoundException` is important to throw rather than returning `null`. `DaoAuthenticationProvider` is written expecting either a `UserDetails` or an exception — a `null` return causes a `NullPointerException` deep inside Spring's authentication pipeline instead of a clean "bad credentials" failure. Throwing the right exception type here is what lets Spring Security turn this into a proper authentication failure response rather than a 500 error.

Register this as a `@Service` bean, and `DaoAuthenticationProvider` (which you've already seen wired up through `AuthenticationManager`/`AuthenticationConfiguration`) will pick it up automatically to load users during authentication — you don't call `loadUserByUsername` yourself anywhere in your controllers.


[[Spring Security]]