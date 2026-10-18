


Once you understand these two ideas, you can reason clearly about almost every security feature you'll meet. They sound alike and they're often mentioned together, but they answer two different questions.

- **Authentication (AuthN)** asks: _Who are you?_
- **Authorization (AuthZ)** asks: _What are you allowed to do?_

## A hotel analogy

Think of checking into a hotel.

At the front desk, you show your passport. The clerk checks that you really are the person who booked the room. That's **authentication**.

The clerk then gives you a key card. It opens your room and the gym, but not the staff office or someone else's room. That's **authorization**.

Notice the order. The hotel can't decide what you may open until it knows who you are. Authentication always comes first, and authorization builds on it.

## Authentication: proving who you are

Authentication is the process of verifying an identity. You make a claim ("I'm alice"), and the system asks for proof. Proof usually comes from one or more of these _factors_:

- **Something you know**: a password or PIN.
- **Something you have**: a phone, a hardware key, or a one-time code.
- **Something you are**: a fingerprint or face scan.

Using two or more factors together is called **multi-factor authentication (MFA)**. It's much harder to break, because a stolen password alone is no longer enough.

When authentication succeeds, the system knows who you are. This verified identity is often called the **principal**.

## Authorization: deciding what you may do

Authorization happens _after_ the system knows who you are. It checks your permissions against the thing you're trying to do.

Common ways to express permissions:

- **Roles (RBAC, role-based access control)**: You're given a role like `USER` or `ADMIN`, and each role comes with a set of permissions. This is the simplest and most common approach.
- **Permissions or authorities**: Finer-grained rights, like `order:read` or `order:delete`.
- **Rules based on data**: For example, "you can edit an order only if you created it."

A normal user might view their own orders. An admin might view everyone's orders and delete accounts. Both are authenticated, but they're authorized differently.

## A quick example

You log in to an online shop.

1. You enter your email and password. The system checks them. **(Authentication)**
2. You click "My orders" and see your own orders. **(Authorization: allowed)**
3. You try to open `/admin/users`. The site refuses. **(Authorization: denied)**

At step 3 the system still knew exactly who you were. It just decided you weren't permitted to go there.

## 401 vs 403

HTTP has two status codes that map to these ideas, and they're easy to mix up because of historical naming:

|Code|Meaning|Real-world translation|
|---|---|---|
|**401 Unauthorized**|Not authenticated|"I don't know who you are. Log in first."|
|**403 Forbidden**|Authenticated, but not authorized|"I know who you are, and you can't do this."|

Despite its name, 401 is really about _authentication_. If you remember that, you'll debug access problems much faster.

## How this looks in Spring Security

Since you work with Spring Boot, it helps to see where each idea lives.

- **Authentication** is handled by an `AuthenticationManager`, which checks credentials (often through a `UserDetailsService` and a `PasswordEncoder`). If the credentials check out, the result is stored as the current user in the `SecurityContext`.
- **Authorization** happens after that, when Spring Security compares the user's _granted authorities_ (roles and permissions) against rules like `.requestMatchers("/admin/**").hasRole("ADMIN")` or annotations such as `@PreAuthorize("hasRole('ADMIN')")`.

Spring Security keeps the two steps separate in its design, just like the concepts themselves.

## Common mistakes to avoid

- **Treating "logged in" as "allowed."** Being authenticated doesn't mean you can do everything. Always check permissions too.
- **Only hiding buttons in the UI.** A hidden "Delete" button isn't security. The server must enforce authorization on every request.
- **Trusting data from the client.** Never accept something like `isAdmin=true` from a request. Decide roles on the server.

## Summary

- **Authentication** verifies _who you are_.
- **Authorization** decides _what you can do_.
- Authentication comes first, then authorization.
- 401 means "who are you?" and 403 means "you can't do that."




[[Spring Security]]