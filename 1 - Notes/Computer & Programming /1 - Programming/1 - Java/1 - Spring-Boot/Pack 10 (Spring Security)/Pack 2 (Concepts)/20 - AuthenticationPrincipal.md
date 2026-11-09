

`@AuthenticationPrincipal` is a parameter annotation. It tells Spring MVC: "inject the **principal** of the current `Authentication` into this controller method." You get your logged-in user's object directly, without touching `SecurityContextHolder`.

Remember the `Authentication` object from your earlier lessons: it holds `principal`, `credentials` and `authorities`. This annotation simply calls `getPrincipal()` on it for you. In your setup, the principal is the `UserDetails` that `loadUserByUsername` returned (or that your JWT filter built).

---

## Without vs with it

```java
// Manual way
@GetMapping("/me")
public String me() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    UserDetails user = (UserDetails) auth.getPrincipal();   // cast needed
    return user.getUsername();
}

// With the annotation
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user) {
    return user.getUsername();
}
```

Same result, but shorter, with no cast, and easier to test.

---

## Using your own principal class

If your principal is your own class (like `AppUserPrincipal` from the last lesson), use that type directly:

```java
@GetMapping("/orders")
public List<OrderDto> myOrders(@AuthenticationPrincipal AppUserPrincipal principal) {
    return orderService.findByUserId(principal.getId());   // no repository lookup for the user
}
```

This is the payoff from your lesson on the `Authentication` object replacing repeated database lookups.

---

## Reading only one field: `expression`

```java
@GetMapping("/me/id")
public Long myId(@AuthenticationPrincipal(expression = "id") Long id) {
    return id;
}
```

The expression is evaluated against the principal (`principal.getId()` here), and you receive just that value.

---

## Gotchas

|Situation|What happens|
|---|---|
|Not logged in (anonymous)|The parameter is `null`, because the principal is the string `"anonymousUser"` and doesn't match your type|
|Wrong parameter type|Also `null`, with no error, so check the type matches what your `UserDetailsService` returns|
|`errorOnInvalidType = true`|Throws an exception instead of silently giving `null`|
|Principal is Spring's built-in `User`|You can't read `id`, since it only has the seven interface fields|

Endpoints protected by `.authenticated()` never see the anonymous case, so `null` mainly shows up on public endpoints.

---

## Related, in short

- **`@CurrentSecurityContext`**: injects the whole `SecurityContext` (or part of it by expression) instead of only the principal.
- **`Principal` or `Authentication` as a parameter**: Spring MVC can also inject these directly. `Authentication` gives you authorities too, and `Principal` only gives `getName()`.

---

## Recap

1. It injects `authentication.getPrincipal()` into your controller method.
2. The parameter type must match your principal class (`UserDetails` or your own).
3. `expression` lets you pick one field.
4. You get `null` for anonymous users or a type mismatch.


[[Spring Security]]