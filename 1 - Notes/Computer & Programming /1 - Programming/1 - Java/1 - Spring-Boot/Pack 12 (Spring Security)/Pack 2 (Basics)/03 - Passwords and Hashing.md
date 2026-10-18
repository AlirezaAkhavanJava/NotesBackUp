

If you store passwords the wrong way, one database leak can expose every one of your users, and many of them reuse the same password on other sites. If you store them the right way, a leaked database is a bad day instead of a disaster. This topic is about the right way.

## The problem: you must check passwords, but never keep them

When Alice logs in, you need to know whether the password she typed is correct. The obvious approach is to save her password and compare. Don't do that.

Think about what happens if your database is stolen. It happens to companies of every size, and you should plan for it. If passwords are stored as plain text, the thief now has every user's password, and can try them on email, banks, and social media.

So you want to **check** a password without **storing** it. Hashing makes that possible.

## What a hash is

A **hash function** takes any input and produces a fixed-size scrambled output, called a **hash** (or digest).

```
SHA-256("hello")  →  2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
SHA-256("hellp")  →  a completely different-looking value
```

A good hash function has four properties:

- **Deterministic.** The same input always gives the same output.
- **One-way.** You can't work backward from the hash to the input.
- **Fixed size.** A 3-letter word and a whole book both produce the same length of output.
- **Sensitive.** Change one character and the output changes completely.

Now the login check works without storing the password:

1. When Alice signs up, you hash her password and store **only the hash**.
2. When she logs in, you hash what she typed and compare it to the stored hash.
3. If they match, the password was right.

You never need the original password again. A thief who steals the hashes can't simply read the passwords.

### Hashing is not encryption

People mix these up, so keep them apart:

||**Encryption**|**Hashing**|
|---|---|---|
|Direction|Two-way (encrypt, then decrypt)|One-way only|
|Needs a key?|Yes|No|
|Can you get the original back?|Yes, with the key|No|
|Use it for|Data you need to read later|Passwords you only need to verify|

If you encrypt passwords, anyone who steals the key can decrypt every one of them. Hashing has no key to steal.

## Why a plain hash is not enough

You might think `SHA-256(password)` solves everything. It doesn't, and the reason is important.

One-way doesn't mean unguessable. An attacker can't reverse a hash, but they can **guess**. They take a list of likely passwords, hash each one, and see which hashes match yours. Two things make this easy.

### Problem 1: Fast hashes are too fast

SHA-256 was designed to be quick. A modern graphics card can test **billions** of SHA-256 guesses every second. Most people's passwords fall to that speed in minutes or hours.

### Problem 2: Identical passwords give identical hashes

If a thousand users chose `password123`, a thousand rows in your table hold the same hash. An attacker cracks one and gets all of them. Worse, they can use a **rainbow table**: a huge precomputed list of "password → hash" pairs. Looking up a hash in it is nearly instant.

Two ideas fix these two problems: **salting** and **slow hashing**.

## Salting: making every hash unique

A **salt** is a random value, generated fresh for each user, and mixed into the password before hashing.

```
hash( "password123" + "x7Kq9aLm" )  →  one hash
hash( "password123" + "B2vTn04e" )  →  a totally different hash
```

Two users with the same password now get different hashes. This gives you three benefits:

- **Rainbow tables become useless.** The attacker would need a separate table for every possible salt.
- **Duplicates are hidden.** Nobody can tell which users share a password.
- **Cracking is one-at-a-time.** The attacker has to attack each user separately.

The salt is **not a secret**. You store it right next to the hash. Its job is only to make each hash unique, not to hide anything. Modern password hashing libraries create the salt for you and store it inside the output string, so you never handle it yourself.

## Slow hashing: making each guess expensive

The second fix is to use a hash function that is _deliberately slow_. Slow for you means about 100 milliseconds per login. That's invisible to a person. But for an attacker trying a billion guesses, it turns hours into centuries.

Password hashing algorithms have a **work factor** (also called cost): a setting that controls how slow they are. As computers get faster, you raise the number. That's why these are called **adaptive** hash functions.

The main algorithms:

|Algorithm|Notes|
|---|---|
|**Argon2**|The modern recommendation. Uses lots of memory, which makes cracking with GPUs expensive. Winner of a public password-hashing competition.|
|**bcrypt**|Older, very widely used, and well tested. A solid default. Ignores anything past about 72 bytes of the password.|
|**scrypt**|Memory-hard like Argon2. Good, less common in Java apps.|
|**PBKDF2**|Old and standards-approved, but easier to attack with GPUs. Use it only if a standard requires it.|

And the ones to **never** use for passwords: **MD5**, **SHA-1**, and plain **SHA-256**. They're built for speed, which is exactly what you don't want here.

## What a stored hash looks like

Here is a real bcrypt hash:

```
$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
 │   │  └──────┬───────┘└──────────────┬───────────────┘
 │   │       salt                    hash
 │   └─ cost factor (2^10 rounds)
 └─ algorithm version
```

Everything needed to verify a password is packed into this one string: the algorithm, the cost, the salt, and the hash. You store it in a single column. When you verify, the library reads the salt and cost from the string, re-hashes the typed password, and compares.

Raising the cost by 1 doubles the work. So cost 10 → 12 makes hashing four times slower.

## A pepper: an optional extra

A **pepper** is a secret value mixed into every password, like a salt, but with two differences: it's the **same for all users**, and it's **not stored in the database**. It lives somewhere else, such as an environment variable or a secrets manager.

The idea is that a thief who steals only the database still lacks the pepper. It's a useful extra layer, but it's optional, and it adds complexity (losing the pepper breaks every login). Get salting and slow hashing right first.

## Hashing in Spring Security

Spring Security gives you one interface for all of this: **`PasswordEncoder`**. It has two main methods:

```java
String encode(CharSequence rawPassword);                        // hash it
boolean matches(CharSequence rawPassword, String encodedPassword); // verify it
```

Here is how you use it for signup and login:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();          // default cost is 10
}
```

```java
// Signup: store only the hash
String hash = passwordEncoder.encode("myS3cretPassword");
user.setPasswordHash(hash);
userRepository.save(user);

// Login: Spring does this for you, but this is what happens
boolean ok = passwordEncoder.matches(typedPassword, user.getPasswordHash());
```

Notice that you never compare with `equals`. You always call `matches`, because the salt is inside the stored string and only the encoder knows how to use it.

If you register your `PasswordEncoder` as a bean, Spring Security's authentication uses it automatically during login. You don't write the comparison yourself.

### Choosing a different algorithm

```java
new BCryptPasswordEncoder(12);                       // higher cost
Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8(); // Argon2 (needs the Bouncy Castle library)
```

### The recommended approach: DelegatingPasswordEncoder

Algorithms get replaced over time. What happens when you want to move from bcrypt to Argon2, but your database already holds thousands of bcrypt hashes?

Spring's answer is the `DelegatingPasswordEncoder`. It stores the algorithm name as a **prefix** in each hash:

```
{bcrypt}$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
{argon2}$argon2id$v=19$m=16384,t=2,p=1$...
```

When verifying, it reads the `{prefix}`, picks the matching algorithm, and checks the password. New hashes use your current favorite, and old ones keep working. You create it with:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}
```

If you ever see the error _"There is no PasswordEncoder mapped for the id 'null'"_, it means a stored password has no `{prefix}`. The fix is to store the hash with its prefix, or to use a specific encoder like `BCryptPasswordEncoder` directly.

## Good password habits for your own apps

Hashing protects stored passwords. A few policy choices protect the rest:

- **Favor length over complexity.** A long passphrase beats a short password full of symbols. Allow long passwords, including spaces.
- **Check against known-breached passwords.** Rejecting passwords that have appeared in public leaks is more useful than any "must contain a symbol" rule.
- **Don't force regular password changes.** It pushes people toward weak, predictable variations like `Summer2025!` → `Summer2026!`. Require a change when you suspect a breach.
- **Offer MFA.** Even a perfectly hashed password can be phished.
- **Rate-limit login attempts.** Slow hashing protects against offline guessing. Rate limiting protects against guessing through your login form.
- **Use the same error for "no such user" and "wrong password."** Otherwise an attacker can discover which accounts exist.
- **Never log passwords**, and never email them. If a "forgot password" feature can send someone their old password, that means you stored it in a recoverable form. A reset link is the right design.

## Mistakes to avoid

- **Storing plain text or encrypted passwords.**
- **Using MD5, SHA-1, or SHA-256** directly for passwords.
- **Inventing your own scheme**, like hashing twice or mixing in your own tricks. Use a proven library.
- **Using one fixed salt for everyone.** The salt must be random and unique per user.
- **Comparing hashes with `equals`.** Use `matches`.
- **Setting the cost too low** and never revisiting it. Aim for a login that takes roughly 100 to 500 milliseconds on your server.

## Summary

- **Never store passwords.** Store a hash, then compare hashes at login.
- A hash is **one-way**, unlike encryption, which is reversible.
- Plain fast hashes can be guessed at billions per second, so use **slow, adaptive** algorithms: **Argon2**, **bcrypt**, or **scrypt**.
- A **salt** is random and unique per user. It defeats rainbow tables and hides duplicate passwords. Libraries handle it for you.
- A **pepper** is an optional secret kept outside the database.
- In Spring Security, use a **`PasswordEncoder`** (ideally the `DelegatingPasswordEncoder`) and call **`matches`**, never `equals`.




[[Spring Security]]