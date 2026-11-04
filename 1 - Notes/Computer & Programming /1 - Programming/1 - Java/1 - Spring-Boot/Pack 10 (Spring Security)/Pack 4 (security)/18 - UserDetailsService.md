
# `UserDetailsService`: Where Spring Learns Who Your Users Are

In the last lesson, the rules in `authorizeHttpRequests` checked whether the current user was logged in and had the right roles. But that raises an obvious question: **where does Spring get the user's name, password, and roles in the first place?** That's the job of `UserDetailsService`.

## The short answer

You need `UserDetailsService` to tell Spring Security **how to find a user by their username**. Spring Security doesn't know where your users live. They might be in a database, a file, an LDAP directory, or nowhere at all. This interface is the bridge: you implement it once, and Spring calls it every time someone tries to log in.

The rest of this lesson explains that in detail.

---

## Step 1: The problem Spring Security has to solve

Imagine a user types a username and password into your login form. Spring Security needs to answer three questions:

1. **Does this user exist?**
2. **Is the password they typed correct?**
3. **What roles does this user have?** (The rules from `authorizeHttpRequests` depend on this.)

Spring Security's core code is generic. It has no idea whether you store users in PostgreSQL, MongoDB, or a text file. So it needs a standard way to ask your app, "Tell me about the user named `alice`." That standard way is a single method, and that method lives in `UserDetailsService`.

Think of it as a contract. Spring says, "If you can answer 'who is this user?' in this exact shape, I can handle all the security logic for you."

---

## Step 2: What `UserDetailsService` is

**Definition:** `UserDetailsService` is an interface with one method. Given a username, it returns a `UserDetails` object describing that user, or throws an exception if no such user exists.

The actual interface in Spring Security is this small:

```java
public interface UserDetailsService {
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

Let's read it slowly:

- **`UserDetailsService`** is the name of the contract.
- **`loadUserByUsername`** is the one method you must write. The name says what it does: load a user, using the username as the key.
- **`String username`** is what the person typed into the login form.
- **`UserDetails`** is the return type, the object that describes the user (explained next).
- **`UsernameNotFoundException`** is thrown when no user matches.

**Why this design:** Spring only needs one question answered, so the interface asks for exactly that. Anything beyond that is your business. This is the "interface as a contract" idea: Spring depends on the shape of the answer, not on how you find it.

---

## Step 3: What `UserDetails` is

`UserDetailsService` returns a `UserDetails` object. This is the standard container for everything Spring Security needs to know about a user.

**Definition:** `UserDetails` is an interface that describes a user from a security point of view: their username, their hashed password, their permissions, and whether their account is usable.

Its main methods:

|Method|What it tells Spring|
|---|---|
|`getUsername()`|The user's login name|
|`getPassword()`|The stored password (always a hash, never plain text)|
|`getAuthorities()`|The roles or permissions, such as `ROLE_ADMIN`|
|`isEnabled()`|Whether the account is active|
|`isAccountNonLocked()`|Whether the account is locked (for example, after too many failed logins)|
|`isAccountNonExpired()`|Whether the account has passed its expiry date|
|`isCredentialsNonExpired()`|Whether the password must be changed|

**Why it exists:** Different apps track different account rules. Spring needs one consistent shape to read them all. So you convert your own user record into a `UserDetails`, and Spring takes it from there.

**The easy way to build one:** Spring provides a ready-made class, `User`, with a builder:

```java
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;

UserDetails alice = User.withUsername("alice")
        .password("$2a$10$hashedPasswordHere")  // must already be hashed
        .roles("USER")                          // becomes ROLE_USER internally
        .build();
```

Notice `.roles("USER")` adds the `ROLE_` prefix for you, just like `hasRole("USER")` expects. This matters later, because the access rules match against these authorities.

---

## Step 4: How it all fits together during a login

Here is the full flow when a user submits a login form:

```
1. User submits:  username = "alice", password = "alice-secret"
                         │
2. Spring calls:  userDetailsService.loadUserByUsername("alice")
                         │
3. Your code returns a UserDetails object (username, hashed password, roles)
                         │
4. Spring compares the typed password with the stored hash
   (using a PasswordEncoder, which we'll cover next)
                         │
5. If they match → Spring builds an Authentication object
                   (who the user is + their authorities)
                         │
6. The rules in authorizeHttpRequests now check against that Authentication
```

This shows the role of `UserDetailsService` clearly. It's step 2 and 3: **it supplies the facts**. Spring does the checking. You never write `if (password.equals(...))` in a controller, and that's deliberate. Password logic is hard to get right, and Spring's version has been tested by many people.

---

## Step 5: Example 1: In-memory users (for learning)

The simplest version stores users directly in code. It's great for practice, but not for real apps, since users disappear when the app restarts.

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class InMemoryUsersConfig {

    @Bean
    public UserDetailsService userDetailsService(PasswordEncoder encoder) {
        UserDetails alice = User.withUsername("alice")
                .password(encoder.encode("alice-secret"))
                .roles("USER")
                .build();

        UserDetails admin = User.withUsername("admin")
                .password(encoder.encode("admin-secret"))
                .roles("ADMIN", "USER")
                .build();

        return new InMemoryUserDetailsManager(alice, admin);
    }
}
```

**What each part does:**

- `@Bean` on the method tells Spring: "Create this object and manage it. Other parts of the app, including the security system, can use it."
- `User.withUsername("alice")` starts building a user record.
- `.password(encoder.encode("alice-secret"))` hashes the password before storing it. The `PasswordEncoder` is injected as a parameter, and we'll cover it in the next lesson.
- `.roles("ADMIN", "USER")` gives `alice`'s admin account two roles.
- `new InMemoryUserDetailsManager(alice, admin)` is Spring's built-in `UserDetailsService`. It holds the users in a `Map`, in memory.

**Important:** You need a `PasswordEncoder` bean for this to compile and work. The short version: it's the tool that turns `"alice-secret"` into an unreadable hash. We'll go through it in detail once you're ready.

**Why this is useful:** It lets you test the whole login and rule system in minutes, without a database.

---

## Step 6: Example 2: Users from a database (real apps)

Real apps keep users in a database. Here you write the lookup yourself. Assume you have an entity and a Spring Data repository:

```java
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.GeneratedValue;

@Entity
public class AppUser {
    @Id
    @GeneratedValue
    private Long id;

    private String username;
    private String passwordHash;   // always store the hash, never the raw password
    private String role;           // e.g. "USER" or "ADMIN"

    // getters and setters omitted for brevity
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public String getRole() { return role; }
}
```

```java
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}
```

Now the piece that connects them:

```java
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class DatabaseUserDetailsService implements UserDetailsService {

    private final AppUserRepository repository;

    public DatabaseUserDetailsService(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser user = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("No user named " + username));

        return User.withUsername(user.getUsername())
                .password(user.getPasswordHash())   // already hashed in the database
                .roles(user.getRole())
                .build();
    }
}
```

**Line by line:**

- `implements UserDetailsService` is the contract you promise to fulfill.
- The constructor receives the repository. Spring creates the repository and passes it in. This is dependency injection, which you've likely seen already.
- `repository.findByUsername(username)` asks the database for the user. Spring Data generates this query from the method name.
- `.orElseThrow(...)` handles the case where no user exists. It throws the exception Spring expects.
- `User.withUsername(...)` converts your entity into the `UserDetails` shape Spring understands.

**Why the password is already a hash:** The database stores something like `$2a$10$...`, not `alice-secret`. Spring will hash the typed password and compare the two hashes. Plain-text passwords in a database are a serious security risk.

**What you don't need to write:** No password comparison, no session creation, no role checking. Spring handles all of that once it has the `UserDetails`.

---

## Step 7: Why the exception matters for security

Notice that `UsernameNotFoundException` is thrown when the user doesn't exist. You might expect that message to be shown to the user, like "No user named bob." That would be a mistake.

**The problem:** If the login page says "user not found" for unknown names and "wrong password" for known names, an attacker can test usernames and learn which accounts exist. This is called **user enumeration**.

**What Spring does:** By default, `DaoAuthenticationProvider` (the component that uses your `UserDetailsService`) converts this exception into a generic "Bad credentials" message. Your user sees the same error either way. That protects you without any extra code.

**Your takeaway:** Write the exception with a clear message for your logs, but don't expose its text to the browser.

---

## Step 8: What if you don't define one?

Remember the default behavior from the previous lesson? If you define no `UserDetailsService` and no authentication setup, Spring Boot creates a default user called `user` with a random password, printed in the console at startup.

**Why this matters:** Once you define your own `UserDetailsService` bean, Spring Boot backs off and uses yours instead. That's how you replace the default with your real users.

---

## Step 9: When you might not need it at all

`UserDetailsService` is for **username and password login handled by your app**. Some setups don't need it:

|Setup|Do you need `UserDetailsService`?|Why|
|---|---|---|
|Form login with your own users|Yes|Your app checks the password|
|HTTP Basic with your own users|Yes|Same reason|
|`oauth2Login` ("Sign in with Google")|No|Google checks the password|
|`oauth2ResourceServer` with JWT|No|The token issuer already vouched for the user|
|Quick testing with fixed accounts|Optional (in-memory works)|Convenient, not required|

So the rule of thumb is: **if your app stores and checks passwords, you need `UserDetailsService`. If someone else checks them, you don't.**

---

## Real scenarios

**Scenario A: A learning project.** You're building a small Spring Boot app to practice. In-memory users (Example 1) are enough. Restart the app and the users reset, which is fine for practice.

**Scenario B: A company's internal admin site.** Employees log in with usernames and passwords stored in PostgreSQL. Use the database version (Example 2). Roles like `ADMIN` and `EMPLOYEE` come from a column in the table.

**Scenario C: Your Family Inbox project.** Parents log in to the web app. Since you're building a Spring Boot backend with a database, you'd store users in a table and use Example 2. Later, when you add Android, the same `UserDetailsService` still works for the login endpoint.

**Scenario D: A Spring Boot API that uses Google login.** Your Angular front-end uses "Sign in with Google," and the API only checks JWT tokens. You don't need `UserDetailsService` at all. The `oauth2ResourceServer` setup from the previous lesson is the right fit.

---

## Quick reference

|Piece|Role|
|---|---|
|`UserDetailsService`|Finds a user by username (you implement it)|
|`loadUserByUsername()`|The single method you write|
|`UserDetails`|The standard shape describing a user|
|`User.withUsername(...)`|Spring's helper for building `UserDetails`|
|`UsernameNotFoundException`|The exception for "no such user"|
|`InMemoryUserDetailsManager`|A ready-made in-memory version for learning|

---



[[Spring Security]]