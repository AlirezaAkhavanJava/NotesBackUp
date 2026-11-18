
A **rainbow table** is a precomputed data structure that lets an attacker turn a password hash back into a password quickly. Instead of storing every password with its hash, it stores only the two ends of long chains of hash computations. That makes the table far smaller than a full lookup list, at the cost of a little extra computing when you search it. It is a _time-memory tradeoff_: you spend computing time once, up front, and keep memory use low.

This is the exact attack that salting (from your last lesson) is designed to stop. To see why salting works so well, it helps to understand what a rainbow table is and why it only works against unsalted hashes.

## Start with the simple version: a plain lookup table

The most obvious precomputed attack is a dictionary of hash → password pairs:

|password|SHA-256 hash (shortened)|
|---|---|
|`123456`|`8d969e...`|
|`password`|`5e8848...`|
|`password123`|`ef92b7...`|
|`qwerty`|`65e84b...`|

Cracking a stolen hash is then one lookup:

```java
Map<String, String> table = new HashMap<>();   // hash -> password

String cracked = table.get(stolenHash);        // instant, or null if not present
```

The lookup is instant, but the storage is the problem. Each row holds a 32-byte hash plus the password. For all passwords up to 8 lowercase letters (about 209 billion of them), that is several terabytes. The table is fast but huge.

## The rainbow table idea: store chains, keep only the ends

A rainbow table compresses that huge table by storing **chains** and keeping only each chain's first and last password. To build a chain you need two functions:

- **H**: the real hash function (for example SHA-256). It goes password → hash.
- **R**: a **reduction function**. It goes hash → _some_ password. It is not the reverse of H (hashes cannot be reversed). It just maps a hash onto a plausible password in your search space, for example by taking some bytes of the hash and turning them into letters.

A chain alternates between the two:

```
p0 --H--> h0 --R--> p1 --H--> h1 --R--> p2 --H--> h2 --R--> p3
```

Here is a chain of length 3 as a table:

|step|value|
|---|---|
|start password|`p0` = `aaaaaa`|
|after H, R|`p1` = `kxqmbd`|
|after H, R|`p2` = `zrtnwc`|
|after H, R (end)|`p3` = `mdlyez`|

Only `aaaaaa` and `mdlyez` are saved. The two middle passwords are thrown away because they can be recomputed. A chain of length 1,000 covers about 1,000 passwords while storing just 2 values. That is the compression.

### Building a chain in code

```java
static String reduce(byte[] hash, int column) {
    // turn hash bytes into a 6-letter password; "column" changes the result per step
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < 6; i++) {
        int v = (hash[i] & 0xFF) + column;
        sb.append((char) ('a' + (v % 26)));
    }
    return sb.toString();
}

static String buildChain(String start, int length) throws Exception {
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    String p = start;
    for (int col = 0; col < length; col++) {
        byte[] h = md.digest(p.getBytes(StandardCharsets.UTF_8)); // H
        p = reduce(h, col);                                       // R
    }
    return p;   // the chain end
}
```

Line by line:

- `reduce(...)` is the reduction function. It maps a hash to a 6-letter string.
- `int col` is the column number, mixed into the reduction. This is the "rainbow" part, explained below.
- `buildChain` starts at `start`, then repeats hash → reduce `length` times, and returns the last password. You store the pair `(start, end)`.

## Looking up a hash in the table

Say you stole the hash `h` and want its password. You do not know which chain it sits in, or where in the chain.

1. Assume `h` is the **last** hash of a chain. Apply `R` to it and see if the result matches any stored chain end.
2. If there is no match, assume `h` is one step earlier: apply `R`, then `H`, then `R`, and check the ends again.
3. Keep stepping backwards, one more `H, R` pair each time.
4. When a computed end matches a stored end, you have found the right chain. Take that chain's **start** password and rebuild the chain from the beginning. The password whose hash equals `h` is somewhere along it.

```java
for (int col = chainLength - 1; col >= 0; col--) {
    String candidate = reduce(h, col);
    for (int c = col + 1; c < chainLength; c++) {
        candidate = reduce(sha256(candidate), c);
    }
    if (endsToStarts.containsKey(candidate)) {
        // rebuild from endsToStarts.get(candidate) and look for the password with hash h
    }
}
```

This costs extra computing (a few hundred thousand hashes per lookup), but the table stays small. A plain lookup table does the opposite: no computing, huge storage.

## Why it's called "rainbow"

Early versions of this idea (Hellman tables, 1980) used the **same** reduction function at every step. That caused a problem: if two chains ever produce the same password at the same step, they merge and are identical from then on. You waste space storing chains that cover the same passwords.

In 2003, Philippe Oechslin fixed this by using a **different reduction function for each column**. That is the `col` parameter in the code above. Two chains can now only merge if they collide at the _same_ column. If you drew each reduction function as a different colour, the chains would show bands of colour across the table, which is where the name comes from.

## Why salting defeats it

Everything above relies on `H` being the same for everyone: `H("password123")` is `ef92b7...` on every system. The table is built once and reused against any leaked database.

With a salt, the real function becomes `H(salt + password)`:

|user|salt|what must be precomputed|
|---|---|---|
|ali|`q8Zr..`|a table for `H(q8Zr.. + password)`|
|sara|`Lm41..`|a **different** table for `H(Lm41.. + password)`|

A table built for one salt is useless for any other. With a unique 16-byte salt per user, the attacker would need a separate table per user, and the cost of building one is the same as just guessing passwords directly. The attack stops being worthwhile.

You also saw this in your `BCryptPasswordEncoder` test: the same password produced two different hashes. A rainbow table for those would have to contain both, and there are 2^128 possible salts.

## What rainbow tables don't cover

- Slow hashes (bcrypt, Argon2) make building the table enormously expensive, so even unsalted they are impractical to precompute widely.
- Strong, long, random passwords fall outside the search space the table was built for.
- If the attacker targets one user with a known salt, they can still brute-force that single hash. Salting prevents _mass precomputation_, and a slow hash limits how fast guessing can go. You need both.

## Related concepts, briefly

- **Dictionary attack:** hashing a list of likely passwords at attack time and comparing. Nothing is precomputed, so it is not a table, but it is the attack that remains against salted hashes.
- **Brute force:** trying every possible password. Rainbow tables are a way to avoid repeating that work for each stolen hash.
- **Pepper:** a secret value kept outside the database and mixed into the hash. Even if someone builds tables, they cannot match your hashes without it.

## Quick recap

A rainbow table stores the start and end of long hash-reduce chains instead of every hash. To crack a hash, you walk the hash through the reduction functions to find a matching chain end, then rebuild that chain to find the password. It only works when everyone's hash function is the same, which is exactly what a unique per-password salt takes away.




[[Spring Security]]