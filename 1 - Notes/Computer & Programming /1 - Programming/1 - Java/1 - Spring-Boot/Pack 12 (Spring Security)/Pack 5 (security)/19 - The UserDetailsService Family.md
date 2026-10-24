

# The `UserDetailsService` Family: Who Implements It and When to Pick Each

 Spring Security gives you a few ready-made `UserDetailsService` implementations, and you can also write your own. The trick is knowing which one fits your situation.

## The family tree first

Before looking at each member, here is how the types relate:

```
UserDetailsService                      ← the one-method contract (read-only)
 │
 ├── UserDetailsManager                 ← adds create / update / delete / changePassword
 │    ├── InMemoryUserDetailsManager    ← users stored in a Map
 │    └── JdbcUserDetailsManager        ← users stored in SQL tables
 │
 ├── LdapUserDetailsService             ← users stored in LDAP / Active Directory
 ├── CachingUserDetailsService          ← a wrapper that caches another service's results
 └── Your own class                     ← users in JPA, MongoDB, a REST API, anything else
```

Two things to keep in mind:

- **`UserDetailsManager` extends `UserDetailsService`.** It adds write operations. If you need your app to create users or change passwords through code (for example, a registration endpoint), you need an implementation of this sub-interface.
- **Reactive apps (WebFlux) use a separate interface, `ReactiveUserDetailsService`.** The same ideas apply, but the methods return reactive types. We won't go deeper here since your projects use Spring MVC.

---

## Member 1: `InMemoryUserDetailsManager`

**Definition:** Stores users in a simple in-memory map. You create the users in code, and they exist only while the app is running.

**Why it exists:** Spring needed a way to get security working without a database, so developers could test quickly.

**What problem it solves:** It removes all setup work. You can prove that your rules and login flow work before you have any data layer.

**How it works:** Your users are passed to the constructor. Lookups are just map reads.

```java
@Bean
public UserDetailsService userDetailsService(PasswordEncoder encoder) {
    UserDetails alice = User.withUsername("alice")
            .password(encoder.encode("alice-secret"))
            .roles("USER")
            .build();
    return new InMemoryUserDetailsManager(alice);
}
```

**When to use it:**

- Learning and experiments
- Automated tests that need predictable users
- Demos that don't need to survive a restart

**When not to use it:** Anything real. Users vanish on restart, and passwords sit in your source code. Never ship this to production.

---

## Member 2: `JdbcUserDetailsManager`

**Definition:** Loads users and their authorities from relational database tables using plain JDBC SQL. Spring provides the default table layout.

**Why it exists:** Many apps store users in SQL databases, and developers kept writing the same lookup code. This class is the standard version, with fixed table names and columns that you can change if needed.

**What problem it solves:** You get a working database-backed login with almost no code. You only write the tables.

**How it works:** Spring expects two tables by default:

```sql
-- one row per user
CREATE TABLE users (
    username VARCHAR(50)  NOT NULL PRIMARY KEY,
    password VARCHAR(500) NOT NULL,
    enabled  BOOLEAN      NOT NULL
);

-- one row per role or authority a user has
CREATE TABLE authorities (
    username  VARCHAR(50) NOT NULL,
    authority VARCHAR(50) NOT NULL,
    CONSTRAINT fk_authorities_users FOREIGN KEY (username) REFERENCES users(username)
);
CREATE UNIQUE INDEX ix_auth_username ON authorities (username, authority);
```

Note: the official reference uses H2-specific types in its schema. Adapt the column types for PostgreSQL or MySQL, and check the Spring Security reference for the exact script your database needs.

Then you wire it to your `DataSource`:

```java
@Bean
public UserDetailsService userDetailsService(DataSource dataSource) {
    return new JdbcUserDetailsManager(dataSource);
}
```

Authorities in the table use the full name, such as `ROLE_ADMIN`. That's the one place you must remember the prefix yourself, because this class doesn't add it for you.

**When to use it:**

- A small app with a relational database and no existing user entity
- You want user management methods (`createUser`, `changePassword`) without writing them
- You're happy with a fixed table layout, or willing to customize the SQL queries

**When not to use it:** If you already have a JPA entity such as `AppUser` with its own columns and relationships, a custom `UserDetailsService` (Member 4) is usually cleaner. Two sources of truth for the same user table cause confusion.

---

## Member 3: `LdapUserDetailsService`

**Definition:** Loads users from an LDAP directory, such as Microsoft Active Directory or OpenLDAP.

**Why it exists:** Many companies keep staff accounts in one central directory. Their apps need to log in against that directory rather than keeping their own copy of every password.

**What problem it solves:** Single source of truth. When an employee leaves and their directory account is disabled, every LDAP-connected app locks them out automatically.

**How it works:** Spring connects to the directory server, searches for the user, and then checks the password against it. LDAP setup involves server addresses, search base, and filter settings, so it has more configuration than the other options.

**When to use it:**

- Your company's staff accounts live in Active Directory or another LDAP server
- You need login to match corporate accounts

**When not to use it:** When there's no directory server. Don't set up LDAP just to get a login page.

---

## Member 4: Your own implementation

**Definition:** A class you write that implements `UserDetailsService` and loads users from wherever you keep them. This is what you built in the last lesson.

**Why it exists:** Real apps have their own data models. Spring can't know your table names, your entity fields, or your MongoDB documents, so it leaves the lookup to you.

**What problem it solves:** It lets your existing domain model, such as a JPA `AppUser`, become the login source without duplicating it into another table.

**When to use it:**

- You already have a user entity in JPA, MongoDB, or another store
- You need custom rules, such as mapping a `role` column to authorities in a specific way
- Your users come from a REST API or another service

**Important:** Your class implements only `UserDetailsService`, which has the read-only method. If you also need registration or password change through Spring's API, implement `UserDetailsManager` instead, or write those operations as ordinary service methods in your own code.

---

## Member 5: `CachingUserDetailsService`

**Definition:** A wrapper. It doesn't store users itself. It sits in front of another `UserDetailsService` and remembers the answers, so repeated lookups for the same username skip the slow source.

**Why it exists:** Every login (and sometimes every request, depending on your setup) can trigger a user lookup. If that lookup hits a database or a remote directory each time, it adds delay and load.

**What problem it solves:** It reduces repeated lookups for the same users.

**The trade-off:** A cached user record can be stale. If an admin removes a role or disables an account, the cache may still hold the old version until it expires. Plan for this, especially for account locks and role changes.

**How you'll usually do it in a Spring Boot app:** Rather than wiring the wrapper class directly, many teams add caching to their own `loadUserByUsername` with Spring's cache abstraction, such as `@Cacheable`. Enable caching with `@EnableCaching` and add the annotation to the method. Check the official caching docs for the cache provider you choose.

**When to use it:**

- Your user store is slow or remote
- You have many logins or requests per user
- You can accept a short delay before role or lock changes take effect

**When not to use it:** When security changes must apply immediately, such as blocking a fired employee right now, unless you add cache eviction for those events.

---

## Decision guide

Ask these questions in order:

```
Is this only a learning project or a test?
    └── yes → InMemoryUserDetailsManager

Do staff accounts already live in Active Directory / LDAP?
    └── yes → LdapUserDetailsService

Do you already have a JPA / Mongo / REST user model?
    └── yes → Your own UserDetailsService
              (add caching if lookups are slow)

Do you have a relational database and no user model yet,
and you want the fastest path to a working login?
    └── yes → JdbcUserDetailsManager
```

Then check a second question: **do you need to create or change users through Spring's API?** If yes, choose one that implements `UserDetailsManager` (in-memory or JDBC), or plan to write those methods yourself.

---

## Comparison table

|Implementation|Where users live|Setup effort|Changes users via API|Best for|
|---|---|---|---|---|
|`InMemoryUserDetailsManager`|Code / memory|Very low|Yes|Learning, tests|
|`JdbcUserDetailsManager`|SQL tables (fixed layout)|Low|Yes|Simple DB-backed apps|
|`LdapUserDetailsService`|LDAP / Active Directory|High|Depends on setup|Corporate directories|
|Your own class|Anywhere you choose|Medium|Only if you add it|Real apps with domain models|
|`CachingUserDetailsService`|Wraps another source|Low to medium|Inherits from source|Slow or heavily used sources|

---

## Real scenarios

**Scenario A: Your first Spring Boot security test.** You want to see a login work in five minutes. Use `InMemoryUserDetailsManager` with two users, one admin and one normal user. Test your `hasRole("ADMIN")` rules.

**Scenario B: A small internal tool with a PostgreSQL database.** Three people will use it, and you don't want to design a user entity. `JdbcUserDetailsManager` gives you the login tables right away, and you can insert users with SQL.

**Scenario C: Your Family Inbox project.** Parents will register, verify their email, and update their profiles. You already plan a `Parent` JPA entity with extra fields. Write your own `UserDetailsService` that loads `Parent` by email, and add `UserDetailsManager` methods only if you need Spring's API for them. This matches your architecture and avoids a second user table.

**Scenario D: A company that uses Active Directory.** Staff log in with their Windows credentials. `LdapUserDetailsService` connects the app to the directory, so disabled accounts are blocked automatically.

**Scenario E: A busy public app with slow user lookups.** Thousands of logins per minute hit a remote user service. Wrap your own service with caching, using `@Cacheable`, and clear the cache when a user's role or lock status changes.





[[Spring Security]]