## Hashing

**Hashing is the process of converting input data of any size into a fixed-size value called a hash (or hash value) using a hash function.**

```text
Input
  ↓
Hash Function
  ↓
Fixed-size Hash
```

Example:

```text
"hello"
   ↓ SHA-256
2cf24dba5fb0a30e26e83b2ac5b9e29e...
```

### The important idea

A hash function is designed to be **one-way**:

```text
"hello" → hash → 2cf24d...
```

You normally **cannot take `2cf24d...` and recover `"hello"`**.

Also, a tiny input change should produce a completely different hash:

```text
hello  → 2cf24d...
Hello  → 185f8d...
```

### Why do we use hashing?

Hashing is useful when you need to:

- **Quickly find data** → `HashMap`, `HashSet`
    
- **Detect changes** → file/integrity checks
    
- **Store passwords securely** → Argon2, bcrypt, scrypt
    
- **Build cryptographic systems** → signatures, blockchains, etc.
    

### Hashing vs Encryption

This distinction is critical:

|Hashing|Encryption|
|---|---|
|One-way|Two-way|
|No decryption|Can be decrypted|
|Used for integrity/passwords|Used for confidentiality|
|Same input → same hash|Same plaintext can produce different ciphertext with proper randomization|

In Java:

```java
String input = "hello";

MessageDigest digest = MessageDigest.getInstance("SHA-256");
byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
```

One important security note: **don't use plain SHA-256 to store user passwords**. Passwords should use a dedicated password-hashing algorithm such as **Argon2id, bcrypt, or scrypt**, because they're deliberately expensive to compute.


[[Java]]