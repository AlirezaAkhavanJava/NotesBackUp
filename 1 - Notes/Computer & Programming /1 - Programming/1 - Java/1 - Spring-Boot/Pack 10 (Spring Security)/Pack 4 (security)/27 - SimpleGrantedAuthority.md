

```java
@Override  
public Collection<? extends GrantedAuthority> getAuthorities() {  
    return Collections.singleton(new SimpleGrantedAuthority("USER"));  
}
```

This snippet is the method inside a `UserDetails` class that answers one question for Spring Security: "What is this user allowed to do?" Spring Security calls `getAuthorities()` right after a successful login, takes whatever you return, and stores it inside the logged-in user's `Authentication` object. From then on, every access rule you write (`hasRole(...)`, `hasAuthority(...)`, `@PreAuthorize(...)`) is checked against that list.

The code itself is short, but it packs in four separate ideas: a method override, a generic return type with a wildcard, an immutable one-item set, and a Spring Security authority object. I'll take them one piece at a time, then point out one real problem hiding in this exact snippet.

## 1. Reading it piece by piece

```java
@Override
public Collection<? extends GrantedAuthority> getAuthorities() {
    return Collections.singleton(new SimpleGrantedAuthority("USER"));
}
```

### `@Override`

`UserDetails` is an interface that declares `getAuthorities()`. Your class promises to implement it, and `@Override` tells the compiler "I mean to replace the interface's method." If you misspell the name, the compiler complains instead of silently creating a different method.

### `Collection<? extends GrantedAuthority>`

This is the return type, and the `? extends` part is the one that confuses people. Read it as:

> "A collection of _some type_ that is a `GrantedAuthority`, or a subclass of it."

|What you return|Allowed?|Why|
|---|---|---|
|`Collection<GrantedAuthority>`|Yes|Exactly the base type|
|`Collection<SimpleGrantedAuthority>`|Yes|`SimpleGrantedAuthority` implements `GrantedAuthority`|
|`Collection<String>`|No|A `String` is not a `GrantedAuthority`|

Why not just write `Collection<GrantedAuthority>`? Because in Java, `List<SimpleGrantedAuthority>` is _not_ a `List<GrantedAuthority>`, even though `SimpleGrantedAuthority` is a `GrantedAuthority`. The wildcard `? extends` is what makes your more specific collection fit. The trade-off: the caller can _read_ authorities from it, but cannot _add_ to it. That's exactly what Spring Security needs.

### `Collections.singleton(...)`

`Collections.singleton(x)` builds a `Set` that contains exactly one element, `x`. Two facts about it:

- It is **immutable**. Calling `.add(...)` on the result throws `UnsupportedOperationException`.
- It is lightweight, since it stores just that single item.

A `Set` is a `Collection`, so it matches the return type.

### `new SimpleGrantedAuthority("USER")`

`GrantedAuthority` is an interface with one method, `getAuthority()`, which returns a `String`. `SimpleGrantedAuthority` is Spring Security's ready-made implementation: it just wraps a string. So this creates one permission whose name is `"USER"`.

Put together: **"Give this user exactly one authority, named USER, in a set nobody can modify."**

## 2. The catch: `"USER"` is not `"ROLE_USER"`

Spring Security treats _roles_ and _authorities_ as the same thing with one naming rule: a role is an authority whose name starts with `ROLE_`.

|Your security rule|What Spring Security actually looks for|
|---|---|
|`hasRole("USER")`|the authority `ROLE_USER`|
|`hasAuthority("USER")`|the authority `USER` exactly|
|`hasAuthority("ROLE_USER")`|the authority `ROLE_USER` exactly|

So with your snippet, this rule will **deny** the user:

```java
.requestMatchers("/dashboard").hasRole("USER")   // looks for ROLE_USER, finds only USER
```

There are two correct ways to fix it. Pick one and stay consistent:

```java
// Option A: keep roles, add the prefix in the authority
return Collections.singleton(new SimpleGrantedAuthority("ROLE_USER"));
// and use hasRole("USER")

// Option B: keep your authority name, and check it as an authority
return Collections.singleton(new SimpleGrantedAuthority("USER"));
// and use hasAuthority("USER")
```

This is one of the most common "why am I getting 403 even though I'm logged in?" bugs, so it's worth remembering.

## 3. Where this method sits in the flow

```
Login succeeds
   │
   ▼
DaoAuthenticationProvider calls userDetails.getAuthorities()
   │
   ▼
Authentication object is built with those authorities
   │
   ▼
Stored in SecurityContextHolder
   │
   ▼
Later request: /dashboard  ──►  rule hasRole("USER") ──► compares against stored authorities
                                           │
                              match ──► allowed     no match ──► 403 Forbidden
```

So the method is read once at login. The result travels with the user for the whole session.

## 4. Other ways to write the same thing

Your version is fine for a project where everyone has exactly one fixed role. Here are the variations you'll meet:

```java
// Several fixed authorities
return List.of(
    new SimpleGrantedAuthority("ROLE_USER"),
    new SimpleGrantedAuthority("ROLE_ADMIN"));

// Shortcut helper from Spring Security
return AuthorityUtils.createAuthorityList("ROLE_USER", "ROLE_ADMIN");

// Roles that come from your database entity
return user.getRoles().stream()
        .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
        .toList();
```

|Version|Best when|
|---|---|
|`Collections.singleton(...)`|One fixed role for everyone|
|`List.of(...)` / `Set.of(...)`|A few fixed roles|
|`AuthorityUtils.createAuthorityList(...)`|You want the shortest Spring Security style|
|Stream over database roles|Real apps where users have different roles|

## 5. Related concepts, in short

- **`GrantedAuthority`**: the interface for "one permission or role." It has a single method, `getAuthority()`. You can implement it yourself, but `SimpleGrantedAuthority` is enough almost always.
- **Role vs authority**: a role is a broad label (`ROLE_ADMIN`), an authority is any permission string (`orders:delete`). Spring Security stores both in the same list. The `ROLE_` prefix is just a convention that `hasRole` adds for you.
- **`Collections.singletonList(x)`**: the `List` twin of `singleton`. Same idea, immutable, one element.
- **`RoleHierarchy`**: an optional feature where you declare "ADMIN includes USER," so admins automatically pass `hasRole("USER")` checks without listing both roles on every user.





[[Spring Security]]