

Cryptography sounds like a topic for mathematicians. But as a developer, you only need to know three tools and which job each one does. Once you can tell them apart, you can read almost any security design, from password storage to HTTPS to JWTs, and see what's going on.

Here's the quick map:

|Tool|Question it answers|Direction|
|---|---|---|
|**Hashing**|"Is this the same data as before?"|One-way|
|**Encryption**|"How do I keep this secret but still read it later?"|Two-way, with a key|
|**Digital signatures**|"Who made this, and was it changed?"|Sign with one key, verify with another|

They solve different problems. A common beginner mistake is to reach for the wrong one, so we'll keep them separate.

## Hashing: a one-way fingerprint

A **hash function** takes any amount of data and produces a short, fixed-size value called a **hash** (or digest). Think of it as a fingerprint of the data.

```
SHA-256("hello")        →  2cf24dba5fb0a30e26e83b2ac5b9e29e...
SHA-256("hello!")       →  a totally different value
SHA-256(a 4 GB movie)   →  still just 64 hex characters
```

A good hash has these properties:

- **Deterministic.** The same input always gives the same output.
- **One-way.** You can't rebuild the input from the hash.
- **Fixed size.** Tiny or huge input, the output length is the same.
- **Sensitive.** Change one character and the whole output changes.
- **Collision-resistant.** It's practically impossible to find two different inputs with the same hash.

### What hashing is used for

**1. Passwords.** You store a hash instead of the password. You already know this one. For passwords, you use _slow_ hashes like bcrypt or Argon2, which Spring's `PasswordEncoder` handles for you.

**2. Integrity checks.** Did this file arrive unchanged? Download pages often publish a hash next to the file. You hash your copy and compare. If even one byte differs, the hashes won't match.

```java
MessageDigest md = MessageDigest.getInstance("SHA-256");
byte[] hash = md.digest(Files.readAllBytes(Path.of("installer.zip")));
System.out.println(HexFormat.of().formatHex(hash));
```

Git uses the same idea. Every commit ID is a hash of its contents, so changing history changes the IDs.

### What hashing can't do

A plain hash has no secret in it. Anyone can compute `SHA-256` of anything. So if an attacker changes a file _and_ recomputes the hash, you can't tell. A hash proves "this data matches this fingerprint." It does not prove _who_ made the fingerprint.

To fix that, you need a key. That's where signatures come in, and we'll get there in a moment.

For general hashing, use **SHA-256** or stronger. Avoid **MD5** and **SHA-1**, because attackers can create collisions for both.

## Encryption: two-way scrambling with a key

Encryption turns readable data (**plaintext**) into scrambled data (**ciphertext**) using a **key**. Anyone with the right key can turn it back.

```
plaintext  --[encrypt + key]-->  ciphertext  --[decrypt + key]-->  plaintext
```

This is the big difference from hashing. A hash is a one-way street. Encryption is a round trip, and it's meant for data you need to read again later: a stored card number, a private message, a file on disk.

There are two kinds, and the difference is in the keys.

### Symmetric encryption: one shared key

The same key encrypts and decrypts. Picture a house key. It locks the door and it unlocks the door.

The standard algorithm is **AES**. Here's AES-256 in Java, using the **GCM** mode:

```java
KeyGenerator kg = KeyGenerator.getInstance("AES");
kg.init(256);
SecretKey key = kg.generateKey();

byte[] iv = new byte[12];                  // a fresh random value for every message
new SecureRandom().nextBytes(iv);

Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");

cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, iv));
byte[] encrypted = cipher.doFinal("meet at noon".getBytes(StandardCharsets.UTF_8));

cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, iv));
String back = new String(cipher.doFinal(encrypted), StandardCharsets.UTF_8);
```

A few terms from that code:

- **IV (initialization vector)** or **nonce**: a random value used once per message. It makes sure the same plaintext encrypts differently each time. You can store it next to the ciphertext, but you must never reuse it with the same key.
- **GCM** is a mode that also detects tampering. If someone alters the ciphertext, decryption fails instead of returning garbage.

**Strength:** symmetric encryption is very fast, so it's good for large amounts of data.

**Weakness:** both sides need the same secret key. How do you get the key to your friend without someone else grabbing it on the way? That's called the **key distribution problem**.

### Asymmetric encryption: a key pair

Asymmetric encryption solves that problem with **two keys** that are mathematically linked:

- A **public key**, which you share with everyone.
- A **private key**, which you never share.

Whatever one key locks, only the other can unlock. For encryption, you use the public key to lock and the private key to unlock.

Picture a mailbox with a slot. Anyone can drop a letter in (that's the public key). Only you have the key to open the box and read what's inside (that's the private key).

So if Bob wants to send Alice a secret:

1. Alice publishes her public key.
2. Bob encrypts his message with Alice's public key.
3. Only Alice's private key can decrypt it, so only Alice can read it.

No secret ever had to travel. That's the breakthrough. Common algorithms are **RSA** and **elliptic-curve** schemes (such as **ECDSA** and **X25519**).

**Weakness:** it's much slower than symmetric encryption, and it handles only small amounts of data.

### Putting the two together

Real systems use both, in what's called **hybrid encryption**:

1. Use asymmetric cryptography to safely agree on a fresh symmetric key.
2. Use that symmetric key (AES) to encrypt the actual data, quickly.

That's exactly what **HTTPS** does. When your browser connects to a site, they use asymmetric methods to set up a shared key, then switch to fast AES for the rest of the conversation.

||**Symmetric**|**Asymmetric**|
|---|---|---|
|Keys|One shared secret key|Public key + private key|
|Speed|Very fast|Slow|
|Good for|Large data|Small data, key exchange|
|Main problem|Sharing the key safely|Speed|
|Examples|AES|RSA, elliptic curves|

## Digital signatures: proof of origin and integrity

A **digital signature** proves two things about a piece of data:

- **Authenticity:** it came from a specific person or system.
- **Integrity:** it hasn't been changed since they signed it.

It uses the same key pair idea, but flips the roles:

- You **sign** with your **private** key. Only you can do this.
- Anyone **verifies** with your **public** key. Everyone can do this.

It works like a wax seal on a letter. Only you own the seal, so only you can make it. But anyone can look at it and recognize that it's yours. And if the letter is opened and changed, the seal is broken.

### How it works

1. The signer **hashes** the data to get a small fingerprint.
2. The signer **encrypts that hash with their private key**. The result is the signature.
3. The verifier hashes the data themselves, then uses the signer's **public key** to open the signature.
4. If the two hashes match, the signature is valid.

If anyone changes even one byte of the data, the hashes won't match and verification fails. And nobody without the private key can produce a signature that passes. In Java:

```java
KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
kpg.initialize(2048);
KeyPair pair = kpg.generateKeyPair();

byte[] data = "order #5: 42.00".getBytes(StandardCharsets.UTF_8);

// Sign with the PRIVATE key
Signature signer = Signature.getInstance("SHA256withRSA");
signer.initSign(pair.getPrivate());
signer.update(data);
byte[] signature = signer.sign();

// Verify with the PUBLIC key
Signature verifier = Signature.getInstance("SHA256withRSA");
verifier.initVerify(pair.getPublic());
verifier.update(data);
System.out.println(verifier.verify(signature));   // true
```

If you change `data` after signing, `verify` returns `false`.

### Signatures don't hide anything

This is the most important point to remember. A signature does **not** make data secret. The data stays fully readable. The signature only proves who made it and that it wasn't altered.

### This is what makes tokens trustworthy

Remember the JWT from earlier, with its `header.payload.signature` shape? Now you can see how it works. The server signs the header and payload. When the token comes back, the server checks the signature. If anyone edited the payload (say, changing `"role": "USER"` to `"role": "ADMIN"`), the signature would no longer match, and the token would be rejected.

That's why we said a JWT is _signed, not encrypted_. The payload is readable by anyone. The signature just makes it tamper-proof.

JWTs use two flavors of signing:

|JWT algorithm|How it works|Who can verify|
|---|---|---|
|**HS256**|A **shared secret** (a type of signature called an **HMAC**, a hash mixed with a secret key)|Only parties who know the secret|
|**RS256** / **ES256**|A **private/public key pair**|Anyone with the public key|

HS256 is simple and good when one service both creates and checks tokens. RS256 is better when many services need to _verify_ tokens but only one should be able to _create_ them. You hand out the public key freely and keep the private key locked away.

### But how do you know the public key is really theirs?

Good question. If an attacker swaps in their own public key, they could sign things and you'd trust them. The solution is a **certificate**: a document that says "this public key belongs to example.com," and is itself _signed_ by a trusted organization called a **certificate authority (CA)**. Your browser comes with a list of CAs it trusts. This is the system behind the padlock icon in your address bar.

## How all three work together: one HTTPS request

When you open `https://shop.example.com`, all three tools are working:

1. The server shows its **certificate**. Your browser checks the CA's **digital signature** on it. (_Signatures_)
2. Browser and server use **asymmetric** math to agree on a shared key. (_Asymmetric encryption_)
3. Everything after that is encrypted with **AES**. (_Symmetric encryption_)
4. Each message carries a check that it wasn't tampered with. (_Hashing and signing ideas_)

Then, once you log in, the server stores your password as a **hash** and may hand you a **signed token**.

## Where you'll meet these in Spring Boot

- **Hashing** → `PasswordEncoder` (BCrypt, Argon2) for passwords.
- **Signatures** → JWT validation in the OAuth2 resource server, where Spring checks the token's signature against a key.
- **Symmetric encryption** → Spring Security Crypto has `Encryptors` for encrypting stored values, and `TextEncryptor` for simple text.
- **HTTPS** → set up in `application.properties` with `server.ssl.*` settings, or terminated by a proxy like nginx.

## Mistakes to avoid

- **Encrypting passwords instead of hashing them.** Encryption is reversible, and a stolen key exposes everyone.
- **Thinking Base64 is encryption.** Base64 is just an _encoding_, a way to write bytes as text. Anyone can reverse it with no key.
- **Inventing your own algorithm.** Use proven libraries and standard algorithms. Custom cryptography is almost always broken.
- **Using AES in ECB mode**, or reusing an IV or nonce with the same key. Use **AES-GCM** with a fresh random IV every time.
- **Hardcoding keys** in source code or committing them to Git. Keep them in environment variables or a secrets manager.
- **Using MD5 or SHA-1** for anything security-related.
- **Assuming "signed" means "secret."** A signed JWT is readable by anyone.
- **Using a fast hash for passwords.** Use bcrypt, scrypt, or Argon2.

## Summary

- **Hashing** is a one-way fingerprint. Use it for passwords (with slow algorithms) and integrity checks. It has no key, so on its own it can't prove who created the data.
- **Encryption** is two-way scrambling with a key, for data you need to read again.
    - **Symmetric** (AES): one shared key. Fast, but you must share the key safely.
    - **Asymmetric** (RSA, elliptic curves): a public/private key pair. Solves key sharing, but it's slow. Real systems combine both.
- **Digital signatures** are proof that data came from someone and wasn't changed. You sign with the private key and verify with the public key. They don't hide the data. This is what makes JWTs and HTTPS certificates trustworthy.





[[Spring Security]]