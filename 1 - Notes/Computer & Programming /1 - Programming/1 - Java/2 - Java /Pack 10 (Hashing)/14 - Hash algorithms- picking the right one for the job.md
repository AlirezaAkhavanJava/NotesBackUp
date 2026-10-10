

We've used `hashCode()` and touched SHA-256 briefly. This lesson is about the whole family of hash algorithms and how to choose between them, which is where most real mistakes happen.

## The core intuition

Think of **three machines that all turn a document into a short stamp**, each built for a different job:

1. **The quick stamp** (like a post office sorting code): very fast, only needs to spread things evenly. Nobody is trying to forge it.
2. **The forensic fingerprint**: slower, built so that nobody can find two documents with the same stamp, or work backwards from a stamp to a document.
3. **The vault door**: deliberately slow, so an attacker who steals the stamps can only guess a few per second.

The mental model is a **single dial between speed and resistance to attack**. Fast algorithms are right for hash tables and wrong for passwords. Slow algorithms are right for passwords and wrong for hash tables. Most hashing bugs are the right idea with the wrong setting on that dial.

## The story

Your ticket is `SEC-204`: _"File service must deduplicate uploads, shard its cache, and store logins."_ You open `feat/upload-dedupe` and start reviewing `FileStore.java`.

**Commit `b71e3f0`** deduplicates uploads by their MD5, so identical files are stored once. The tests are green. In review, a colleague pastes two files, `invoice.pdf` and `malware.pdf`, that have the **same MD5** and different contents. They explain that an attacker uploads the harmless file first, and later uploads the second. Your service says "duplicate" and silently serves the first file's record for the second. The **surprise** is that this isn't theoretical: collisions in MD5 can be generated on demand, in seconds, on a laptop. You switch the dedupe key to SHA-256 and move on.

**Commit `c02d9aa`** stores logins as `SHA-256(salt + password)`. The teammate says "we salted it, so rainbow tables are useless." They're right about rainbow tables. Then you load a test dump of 10,000 stored hashes into a cracking tool, and the weak ones fall within minutes. The **surprise** is that the salt was never the problem. SHA-256 is **designed to be fast**, and a modern GPU can try billions of guesses per second. Your decision is to replace it with BCrypt, which is slow on purpose.

**Commit `e5a8d14`** verifies webhook signatures with `SHA-256(secret + body)`. This one passes every test too, and it has a subtle flaw (explained below). You replace it with HMAC.

Three commits, three different jobs, three wrong dial settings.

## Formal detail: the three families

### 1. Non-cryptographic hashes (hash tables, sharding, caches)

Goals are speed and good spread, nothing more. `String.hashCode()` belongs here. Better-spreading examples are **FNV-1a**, **MurmurHash3** and **xxHash**.

FNV-1a is small enough to read in full:

```java
static int fnv1a(byte[] data) {
    int h = 0x811C9DC5;              // offset basis (a fixed starting value)
    for (byte b : data) {
        h ^= (b & 0xFF);             // XOR the byte in first...
        h *= 0x01000193;             // ...then multiply by a prime (16777619)
    }
    return h;
}
```

Note the order: **XOR then multiply** (the "a" in FNV-1a). Multiplication spreads each byte's influence upward through the bits, which gives the avalanche effect we defined last time. For real use, take a vetted implementation, like Guava's `Hashing.murmur3_32_fixed()`, instead of your own.

The rule: **never use these for security.** They have no collision or reversal resistance at all.

A close relative is **CRC32** (`java.util.zip.CRC32`), a checksum for catching _accidental_ corruption like a flipped bit in a download. It's easy to forge on purpose, so it's never a defense against tampering.

### 2. Cryptographic hashes (integrity, signatures, dedupe)

These add three promises, listed by strength:

|Property|Meaning|
|---|---|
|**Preimage resistance**|Given a hash `h`, you can't find any input that produces it (one-way)|
|**Second-preimage resistance**|Given one input, you can't find a _different_ input with the same hash|
|**Collision resistance**|You can't find _any_ two inputs with the same hash|

Because of the birthday effect, finding a collision in an n-bit hash takes roughly 2^(n/2) work, so SHA-256 gives about 2¹²⁸ security against collisions. That's why long outputs matter. Your MD5 incident came from a break in the algorithm itself, which is a different thing from this generic bound.

Current status:

|Algorithm|Output|Status|
|---|---|---|
|MD5|128 bits|Collisions are practical. Don't use for anything adversarial|
|SHA-1|160 bits|Collision demonstrated publicly (2017). Deprecated|
|SHA-256 / SHA-512|256 / 512 bits|Sound. The default choice|
|SHA-3|224 to 512 bits|Sound, built on a different design (sponge) as a backup if SHA-2 ever falls|

For files, don't read everything into memory. Stream the bytes in:

```java
MessageDigest md = MessageDigest.getInstance("SHA-256");
try (InputStream in = Files.newInputStream(path)) {
    byte[] buf = new byte[8192];
    for (int n; (n = in.read(buf)) != -1; ) md.update(buf, 0, n);
}
String hex = HexFormat.of().formatHex(md.digest());   // HexFormat is Java 17+
```

You already use this idea on your Debian machine: `sha256sum debian.iso` computes this same fingerprint, and you compare it with the published `SHA256SUMS` file to confirm the download wasn't corrupted or swapped.

### 3. Password hashing (the deliberately slow ones)

Cryptographic hashes are fast by design, which is exactly what an attacker wants. Password algorithms add two things:

- **A per-password random salt.** It's stored inside the output, so two users with the same password get different hashes, and precomputed tables are useless.
- **A tunable cost.** You decide how much work one hash takes, and you raise it as hardware improves.

The main choices:

|Algorithm|Cost lever|Notes|
|---|---|---|
|**bcrypt**|`log2(rounds)`|Spring's default choice, with a limit of 72 bytes of password|
|**PBKDF2**|iteration count|Fast on GPUs, so needs very high iteration counts. Often required by compliance standards|
|**scrypt**|CPU + memory|Memory-hard, so GPUs lose their advantage|
|**Argon2id**|CPU + memory + parallelism|Current best-practice recommendation|

In Spring Boot:

```java
PasswordEncoder enc = new BCryptPasswordEncoder(12);   // cost 12 = 2^12 rounds
String stored = enc.encode("hunter2");                 // "$2a$12$..." (salt is inside)
enc.matches("hunter2", stored);                        // true: it re-hashes with the embedded salt
```

You never compare hashes yourself, and you never store the salt separately. Tune the cost so one hash takes roughly 100 to 500 ms on your own server.

For a path that survives upgrades, use `PasswordEncoderFactories.createDelegatingPasswordEncoder()`. It stores a prefix like `{bcrypt}` before each hash, so you can move to `{argon2}` later and old hashes keep working.

### The webhook flaw: length extension, and HMAC

Plain SHA-256 and SHA-512 (the Merkle-Damgård design) expose their internal state in the output. An attacker who knows `SHA-256(secret + body)` and the length of the secret can compute the hash of `secret + body + extra` **without knowing the secret**. So the "signature" of your webhook can be extended and forged.

The fix is **HMAC**, a construction that hashes the message with a secret key in a way that blocks this:

```java
Mac mac = Mac.getInstance("HmacSHA256");
mac.init(new SecretKeySpec(secret, "HmacSHA256"));
byte[] expected = mac.doFinal(body);

boolean ok = MessageDigest.isEqual(expected, receivedTag);   // constant-time comparison
```

`MessageDigest.isEqual` matters too. `Arrays.equals` returns as soon as it finds a mismatch, so response time leaks how many leading bytes were right. An attacker can use that timing to guess a signature byte by byte.

## Gotchas

- **Encryption, encoding and hashing are different things.** Hashing is one-way. Base64 is reversible encoding, and encryption is reversible with a key. "Encrypting passwords" with a hash is a common misuse of the word.
- **Hash algorithms need bytes, not strings.** Always pass an explicit charset (`StandardCharsets.UTF_8`), or the same text can hash differently on different machines.
- **Don't invent combinations** like `MD5(SHA1(password))`. They add complexity and no real strength.
- **Hashes of low-entropy inputs are guessable no matter what.** Hashing a 4-digit PIN with SHA-256 gives only 10,000 possible outputs. Nothing about the algorithm can fix that.
- **Name the algorithm in stored data.** Prefixes like `$2a$` and `{bcrypt}` let you migrate later. A bare hex string leaves you guessing.

## Definitions

- **Digest:** the fixed-size output of a hash algorithm.
- **Salt:** random per-item data mixed in before hashing so equal inputs give different outputs.
- **Work factor (cost):** the tunable amount of effort one password hash takes.
- **Rainbow table:** a precomputed table of hashes for common inputs, defeated by salting.
- **HMAC:** a hash combined with a secret key, used to authenticate messages.
- **Memory-hard:** an algorithm that needs lots of RAM per attempt, which limits GPU attacks.
- **Length extension:** forging a longer message's hash from a shorter one's, possible with plain SHA-2 when it's used as a keyed hash.

## Quick recap

- Choose by job: **fast and spread** for hash tables (Murmur, xxHash, FNV), **collision-resistant** for integrity and dedupe (SHA-256), **slow and salted** for passwords (bcrypt, Argon2id), **keyed** for signatures (HMAC).
- MD5 and SHA-1 are broken for adversarial use. Fast hashes like SHA-256 are the wrong tool for passwords even with a salt.
- Use `MessageDigest` for digests (stream large files), `Mac` for HMAC, and a Spring `PasswordEncoder` for passwords, never your own code.
- Compare secrets with `MessageDigest.isEqual`, and store the algorithm name alongside each hash so you can upgrade later.





[[Hashing]]
[[Algorithm & Design Pattern]]