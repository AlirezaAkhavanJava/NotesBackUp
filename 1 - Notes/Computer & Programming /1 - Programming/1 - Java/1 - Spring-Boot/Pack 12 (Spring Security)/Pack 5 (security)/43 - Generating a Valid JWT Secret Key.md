

A valid JWT secret key is a block of truly random bytes that is long enough for your signing algorithm, stored as Base64 text so it can live safely in a config file. "Valid" has two meanings here. The key must be **strong enough** for jjwt to accept it, and it must be **in the format** your code expects. Your `generateKey()` method calls `Decoders.BASE64.decode(SECRET_KEY)`, so your secret must be a Base64 string that decodes to at least 32 bytes.

You can get this wrong in two ways: a key that is too short throws `WeakKeyException`, and a string that is not valid Base64 throws a decoding error. Both appear only when the first token is created, which is why it helps to generate the key the right way from the start.

## What "valid" means in numbers

|Algorithm|Minimum key size|Base64 text length (approx.)|
|---|---|---|
|HS256|32 bytes (256 bits)|44 characters|
|HS384|48 bytes (384 bits)|64 characters|
|HS512|64 bytes (512 bits)|88 characters|

The size is measured **after decoding**, not as the length of the text. A 32-character Base64 string only decodes to 24 bytes, and that is too short for HS256. Base64 turns every 3 bytes into 4 characters, so the text is about a third longer than the bytes it carries.

jjwt picks the algorithm from the key's size. A 64-byte key means HS512, and a 32-byte key means HS256. Using 64 bytes is a good default, because it is accepted by all three.

## Method 1: OpenSSL (Debian)

OpenSSL is already installed on most Debian systems:

```bash
openssl rand -base64 64
```

It prints something like this (one long line, wrapped here for reading):

```
q3ZkV8m1xH2pR7tYb0nLwQ9sUeJ4cAaF6dGhK5oPzXiM3vNlBy8TjWrCfEuS1gDq
7aHkZxO2mYtLpV0nR4wQbJ6c9eFsUiG5dA==
```

Copy that text exactly. `rand -base64 64` generates 64 random bytes and encodes them, so it decodes back to 64 bytes. It works because OpenSSL uses the operating system's cryptographically secure random source.

If your OpenSSL wraps the output across several lines, join them into one line with no spaces. Newlines inside the value cause a decoding error.

## Method 2: PowerShell (Windows)

This version uses .NET's secure random generator, which is better than `Get-Random` for secrets:

```powershell
$bytes = New-Object byte[] 64
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

Line by line:

- `New-Object byte[] 64` creates an empty array of 64 bytes.
- `RandomNumberGenerator...GetBytes($bytes)` fills it with cryptographically secure random bytes.
- `[Convert]::ToBase64String($bytes)` turns them into Base64 text.

I'm recommending this over the one-liner with `Get-Random` from my first answer. `Get-Random` is not designed for cryptographic use, and this version is the safer habit.

## Method 3: Let jjwt generate it

You already have jjwt in your project, so you can generate the key with Java. Run this once as a small `main` method or a test:

```java
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Encoders;
import javax.crypto.SecretKey;

public class KeyGenerator {
    public static void main(String[] args) {
        SecretKey key = Jwts.SIG.HS512.key().build();
        String base64 = Encoders.BASE64.encode(key.getEncoded());
        System.out.println(base64);
    }
}
```

Line by line:

- `Jwts.SIG.HS512.key().build()` creates a random key of the correct size for HS512, which is 64 bytes.
- `key.getEncoded()` returns the raw bytes.
- `Encoders.BASE64.encode(...)` converts the bytes to the Base64 text.

The advantage is that the key is guaranteed to match what jjwt expects, and the same `Encoders.BASE64` is the mirror of the `Decoders.BASE64` in your code. Run it **once**, copy the output, and delete the program or leave it as a utility. Do not call it every time the app starts.

## Method 4: Python, if you have it

Debian comes with Python 3, and this works on both systems:

```bash
python3 -c "import secrets, base64; print(base64.b64encode(secrets.token_bytes(64)).decode())"
```

On Windows, use `python` instead of `python3`. The `secrets` module is Python's secure random source.

## Where to put it after you generate it

Paste the output into an environment variable, not into your source code:

```bash
# Debian
export JWT_SECRET="q3ZkV8m1...your-generated-text...=="
```

```powershell
# Windows (open a new terminal afterwards)
setx JWT_SECRET "q3ZkV8m1...your-generated-text...=="
```

```properties
# application.properties
jwt.secret=${JWT_SECRET}
```

Then your `@Value("${jwt.secret}")` field receives it. Use quotes around the value in the shell, because Base64 can contain `+`, `/` and `=`, and some of those mean something special in a shell.

## Check that your key is valid

A quick test that catches problems before they reach production:

```java
byte[] bytes = Decoders.BASE64.decode(secret);
System.out.println("Key size: " + bytes.length + " bytes");   // want 32 or more
Keys.hmacShaKeyFor(bytes);                                    // throws if too weak
```

If the first line prints 64, you have an HS512-ready key. If decoding throws, the text is not valid Base64. If `hmacShaKeyFor` throws `WeakKeyException`, the key is under 32 bytes.

## Common mistakes

- **Writing your own secret.** A string like `mysecretkey123` is not random, and it fails Base64 decoding or the length check.
- **Using an online "key generator" website.** You would be pasting a secret you didn't create from a machine you don't control. Generate it locally.
- **Generating a new key on every startup.** Every restart then invalidates all existing tokens.
- **Committing the key to Git.** Once it is in the history, treat it as leaked and generate a new one.
- **Reusing one key everywhere.** Give dev, staging and production their own keys.
- **Copying with extra whitespace.** A trailing space or newline in the environment variable can break decoding. Check the value if you get a Base64 error.

## A related concept: Base64 vs Base64URL

Base64 uses the characters `+` and `/`, while Base64URL replaces them with `-` and `_` so the text is safe in URLs. JWT tokens themselves use Base64URL, but your secret is usually plain Base64, which is what `Decoders.BASE64` reads. If you ever generate a key in Base64URL form, decode it with `Decoders.BASE64URL` instead. Using the wrong one gives a decoding error that looks like a corrupted key.






[[Spring Security]]