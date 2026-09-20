
### PasswordEncoder in Spring Security – Quick & Clear (2025)

**What is it?**  
`PasswordEncoder` is the Spring Security tool that **safely stores passwords** so that even if your database is hacked, attackers can't read the real passwords.

**What does it actually do?**
- When a user registers or changes password → it turns "mySecret123" into something like:  
  `$2a$10$abc123xyz...longRandomString`
- When the user logs in → it re-hashes the entered password and compares it with the stored hash.

**Why you absolutely need it in 2025**
- Storing plain text or simple MD5/SHA-256 = **instant fail** in any security audit (and easy to crack).
- Modern attacks crack millions of weak hashes per second.
- Laws and payment systems (PCI-DSS, etc.) require proper hashing.

**The only correct choice in 2025: BCrypt**

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();        // Best default
    // or with strength 12 (a bit slower = safer)
    // return new BCryptPasswordEncoder(12);
}
```

That single bean is enough – Spring Security automatically uses it everywhere (registration, login, etc.).

**Other options (only use if you have a special reason)**

|Encoder|Use case|Safe in 2025?|
|---|---|---|
|`BCryptPasswordEncoder`|Default for new projects|Yes|
|`Argon2PasswordEncoder`|Maximum security (banks, etc.)|Yes (stronger but slower)|
|`SCryptPasswordEncoder`|Also very strong|Yes|
|`Pbkdf2PasswordEncoder`|Good compromise|Yes|
|MD5, SHA-1, SHA-256|Never use for passwords|No|

**One-line summary for your project**  
Just add this bean and you’re safe:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

Done. Your users’ passwords are now protected like in real banks and big companies.

###### Tags : [[1 - Spring Security 🍌]]