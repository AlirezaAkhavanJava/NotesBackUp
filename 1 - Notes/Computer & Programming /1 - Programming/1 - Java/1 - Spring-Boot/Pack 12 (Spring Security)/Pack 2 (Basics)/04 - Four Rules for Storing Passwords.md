

You can follow these four rules in an afternoon, and they protect your users from the worst thing that can happen to a login system: a database leak. They also build on each other. Each rule exists because the one before it wasn't quite enough.

Let's walk through them in order.

## Rule 1: Never store passwords in plain text

**The benefit:** if someone steals your database, they don't get your users' passwords.

A plain-text password column looks like this:

|username|password|
|---|---|
|alice|`sunflower42`|
|bob|`sunflower42`|

Anyone who can read this table can log in as anyone. That includes a thief with a copy of your database, a backup left on a public server, or an employee who shouldn't have access.

The damage spreads beyond your app. People reuse passwords. Alice's `sunflower42` probably also opens her email. Your leak becomes her problem everywhere.

So the rule is simple. Your database should never contain something that _is_ a password. The next rule shows what to store instead.

## Rule 2: Hashing is one-way

**The benefit:** you can check a password without ever keeping it.

A **hash function** takes an input and produces a scrambled, fixed-length output called a **hash**. You can go forward, from password to hash. You can't go backward, from hash to password.

A helpful picture is a meat grinder. You can turn a steak into mince, but nobody can turn the mince back into the steak.

Here's the login flow:

1. **Signup:** hash the password and store only the hash.
2. **Login:** hash what the user typed and compare it with the stored hash.
3. **Match?** Then the password was right.

You never need the original. You can see this in plain Java:

```java
MessageDigest md = MessageDigest.getInstance("SHA-256");

byte[] h1 = md.digest("hello".getBytes(StandardCharsets.UTF_8));
byte[] h2 = md.digest("hello".getBytes(StandardCharsets.UTF_8));
byte[] h3 = md.digest("hellp".getBytes(StandardCharsets.UTF_8));

System.out.println(HexFormat.of().formatHex(h1)); // 2cf24dba5fb0a30e...
System.out.println(HexFormat.of().formatHex(h2)); // exactly the same
System.out.println(HexFormat.of().formatHex(h3)); // totally different
```

This shows two properties:

- **Deterministic:** the same input always gives the same hash. That's what makes the login comparison work.
- **Sensitive:** changing one letter changes the whole output. A hash gives no hint about how close a guess was.

### One-way doesn't mean unguessable

This is the part people miss. An attacker can't _reverse_ a hash, but they can _guess_. They take a likely password, hash it, and compare. If it matches, they've found the password.

So "one-way" stops a thief from reading passwords directly, but it doesn't stop them from guessing. Rules 3 and 4 deal with guessing.

## Rule 3: Salt every password

**The benefit:** attackers can't crack many accounts at once, and they can't use precomputed lookup tables.

Without a salt, the same password always gives the same hash. That causes two problems.

**Problem A: duplicates give themselves away.** If 500 users picked `password123`, 500 rows hold the same hash. Crack one, and you've cracked all 500. The attacker can also see which hash is most common and guess that it's a popular password.

**Problem B: rainbow tables.** A **rainbow table** is a giant precomputed list of "password → hash" pairs. The attacker does the hard work once, ahead of time. Then cracking your leaked hash is just a lookup.

A **salt** is a random value, created fresh for each user and mixed into the password before hashing:

```
hash("password123" + "x7Kq9aLm")  →  one hash
hash("password123" + "B2vTn04e")  →  a different hash
```

Now:

- Two users with the same password have different hashes.
- A rainbow table would have to be rebuilt for every possible salt, which isn't practical.
- The attacker has to crack each user separately.

Two details to remember:

- **A salt is not a secret.** You store it right next to the hash. Its only job is to make each hash unique.
- **You don't handle it yourself.** Password libraries generate the salt and pack it into the output string.

Watch Spring do it:

```java
var encoder = new BCryptPasswordEncoder();

String a = encoder.encode("password123");
String b = encoder.encode("password123");

System.out.println(a.equals(b));                          // false
System.out.println(encoder.matches("password123", a));    // true
System.out.println(encoder.matches("password123", b));    // true
```

The same password produced two different hashes, and both still verify. That's because each hash carries its own salt inside it. This is also why you must call `matches` and never compare hashes with `equals`.

## Rule 4: Use slow, purpose-built algorithms

**The benefit:** every guess an attacker makes becomes expensive, so cracking takes years instead of minutes.

Salting stops shortcuts, but an attacker can still guess one password at a time against one hash. The question now is _how many guesses per second_ they can make.

Here's the surprise. Most hash functions are designed to be **fast**. SHA-256 is great for checking that a file wasn't corrupted, and its speed is a virtue there. A modern graphics card can test billions of SHA-256 guesses every second.

Here's a rough sense of scale. There are about 200 billion possible 8-letter lowercase passwords (26 to the 8th power):

|Hash type|Guesses per second (rough)|Time to try all 200 billion|
|---|---|---|
|Fast hash (plain SHA-256)|billions|**under a minute**|
|Slow hash (bcrypt)|thousands|**many months**|

These numbers are estimates and depend on the hardware. The gap between the two rows is the point.

So for passwords you want the opposite of fast. You want a hash that is **deliberately slow**. Taking 100 milliseconds is invisible to a person logging in once. But it multiplies the attacker's cost by a huge factor, because they need billions of guesses.

The tools built for this are called **password hashing algorithms**:

- **bcrypt:** old, widely used, well tested. A solid default.
- **scrypt:** also slow, and it requires a lot of memory, which makes cracking hardware more expensive.
- **Argon2:** the modern recommendation. It's memory-hard, and it won a public competition for password hashing.

They share one feature: a **work factor** (or cost). It's a setting that controls how slow the hash is. As computers get faster, you turn the number up. In bcrypt, each +1 doubles the work.

You can feel the slowness yourself:

```java
var fast = MessageDigest.getInstance("SHA-256");
var slow = new BCryptPasswordEncoder(12);

long t1 = System.nanoTime();
fast.digest("password123".getBytes(StandardCharsets.UTF_8));
long t2 = System.nanoTime();
slow.encode("password123");
long t3 = System.nanoTime();

System.out.println("SHA-256: " + (t2 - t1) / 1_000_000.0 + " ms");
System.out.println("bcrypt:  " + (t3 - t2) / 1_000_000.0 + " ms");
```

Run it. SHA-256 finishes in a tiny fraction of a millisecond, and bcrypt takes a noticeable moment. That gap is the protection.

Avoid **MD5**, **SHA-1**, and **plain SHA-256** for passwords. They're fast, and for this job fast is the problem.

## How the four rules stack up

Imagine your database leaks. Here's what the attacker faces, one layer at a time:

1. **Rule 1** means they don't find passwords, only hashes.
2. **Rule 2** means they can't reverse the hashes. They have to guess.
3. **Rule 3** means they can't use rainbow tables or crack everyone at once. They attack one user at a time.
4. **Rule 4** means each guess costs real time and money.

A strong password, like a long passphrase, survives all of this. A weak one like `password123` may still fall, which is why length and breached-password checks matter. But the thief now faces a slow, expensive job instead of an instant one.

## What this looks like in Spring Boot

Spring Security wraps all four rules into one interface, `PasswordEncoder`:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

```java
user.setPasswordHash(passwordEncoder.encode(rawPassword));    // signup
passwordEncoder.matches(typedPassword, user.getPasswordHash()); // login
```

That one bean gives you hashing (Rule 2), a random salt (Rule 3), and a slow algorithm (Rule 4). Rule 1 is up to you: never put the raw password in a column, a log line, or an email.

## Summary

- **Never store plain text.** A leak would hand over every password.
- **Hashing is one-way.** You can check a password without keeping it, but attackers can still guess.
- **Salting adds random data per user.** Identical passwords get different hashes, and rainbow tables stop working.
- **Use slow algorithms** like bcrypt, scrypt, or Argon2. Fast hashes like plain SHA-256 let attackers try billions of guesses per second.





[[Spring Security]]