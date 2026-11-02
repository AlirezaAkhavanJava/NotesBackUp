


These are the four words you'll see everywhere in security code. Each one answers a small, specific question, and once you can tell them apart, the Spring Security API stops feeling like a wall of jargon.

Here's the quick map:

|Term|Question it answers|Example|
|---|---|---|
|**Credentials**|How do you prove who you are?|A password|
|**Principal**|Who are you?|The user `alice`|
|**Authority**|What specific thing may you do?|`order:delete`|
|**Role**|What group of permissions do you have?|`ADMIN`|

## Credentials: your proof

**Credentials** are the secret you present to prove your identity. The most common example is a password. Others include an API key, a JWT token, or a one-time code.

Credentials are only used during **authentication**. Once you're verified, the system shouldn't need them again.

Two practical rules follow from this:

- **Never store passwords in plain text.** Store a hash made with something like BCrypt. In Spring, that's the job of the `PasswordEncoder`.
- **Spring clears credentials after login.** After successful authentication, Spring Security erases the password from the `Authentication` object, so the secret doesn't linger in memory.

## Principal: who you are

The **principal** is the identity of the user who has been authenticated. It answers "who is making this request?"

Often it's just a username, but in Spring Security it's usually a richer object. If you use `UserDetailsService`, the principal is a `UserDetails` object holding the username, the account status (enabled, locked), and the user's authorities.

You can read the current principal in a controller like this:

```java
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user) {
    return "Hello, " + user.getUsername();
}
```

Before login, there is no principal. After login, the principal is the verified user. That's why people say "the logged-in principal."

## Authority: one specific permission

An **authority** is a single permission, written as a plain string. It describes one thing you're allowed to do:

- `order:read`
- `order:delete`
- `user:create`

In Spring Security, every authority is represented by a `GrantedAuthority`. A user can hold many of them. When Spring decides whether you may do something, it checks whether you have the right authority.

## Role: a group of authorities

A **role** is a named bundle of permissions, like `USER`, `MANAGER`, or `ADMIN`. Instead of giving a person ten separate authorities, you give them one role that implies all ten. It's easier to manage and easier to read.

For example:

- `USER` can `order:read`
- `ADMIN` can `order:read` and `order:delete`

### The one detail that trips people up

In Spring Security, a role is _just an authority with the prefix `ROLE_`_. So the role `ADMIN` is stored as the authority `ROLE_ADMIN`.

```java
// These two are the same thing underneath:
hasRole("ADMIN")           // Spring adds the prefix for you
hasAuthority("ROLE_ADMIN") // you write the prefix yourself
```

That's why `hasRole("ADMIN")` works even though the stored value is `ROLE_ADMIN`. Meanwhile, `hasAuthority("order:delete")` checks a plain authority with no prefix.

### Role or authority: which should you use?

- Use **roles** for broad groups of users ("this person is an admin").
- Use **authorities** when you need fine control ("this person may delete orders but not refund them").

Many real apps combine both: a role like `MANAGER` that grants a set of fine-grained authorities.

## How they all fit together

Here's one login, start to finish:

1. Alice submits her username and password. These are the **credentials**.
2. The system verifies them against the stored hash. This is **authentication**.
3. It creates her **principal**, a `UserDetails` for `alice`, carrying her `ROLE_ADMIN` and her authorities.
4. She requests `DELETE /orders/5`. Spring checks her **authorities** against the rule. This is **authorization**.
5. She has `order:delete` (through her role), so the request goes through.

In Spring Security, all of this is wrapped in an `Authentication` object:

```
Authentication
 ├── principal    → who you are (UserDetails: alice)
 ├── credentials  → your proof (password, cleared after login)
 └── authorities  → what you may do (ROLE_ADMIN, order:delete)
```

That structure is a nice thing to memorize, because it contains three of the four terms directly. Roles are simply authorities that start with `ROLE_`.

## Summary

- **Credentials** prove your identity (a password). Used once, then cleared.
- **Principal** is the verified identity of the current user.
- **Authority** is one specific permission, like `order:delete`.
- **Role** is a named group of permissions, stored as an authority with the `ROLE_` prefix.






[[Spring Security]]