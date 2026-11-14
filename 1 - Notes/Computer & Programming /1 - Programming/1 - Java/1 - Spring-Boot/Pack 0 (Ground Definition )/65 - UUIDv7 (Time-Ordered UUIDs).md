


UUIDv7 is a UUID variant (defined in RFC 9562, the same spec that formalized v4) whose first 48 bits are a literal Unix millisecond timestamp instead of random data. The remaining bits are still mostly random, but because the high-order bits are time-based, **newly generated UUIDv7 values sort close to each other and close to the end of an ascending sequence** — the same property that makes `BIGINT` sequences index-friendly. This directly attacks the fragmentation problem from before: a `UUIDv7` insert lands near the right edge of the B-tree, not scattered randomly across it, so you get most of the performance characteristics of a sequential key while keeping the full 128-bit, hard-to-guess value.

**Layout of a UUIDv7 value:**

|Bits|Content|
|---|---|
|48|Unix timestamp in milliseconds (big-endian)|
|4|version field — fixed `0111` (7)|
|12|sub-millisecond counter — extra ordering precision within the same millisecond|
|2|variant field — fixed `10`|
|62|random bits|

Compare that to UUIDv4, which you've been using so far: _every_ bit except the 4 version bits and 2 variant bits is random. That's the entire reason v4 fragments indexes — there's no shared prefix between consecutively generated values at all.

### The trade-off this introduces

A UUIDv4 leaks nothing about when it was created. A UUIDv7 does — anyone holding the value can read the creation timestamp straight off the first 48 bits, the same way `uuid_extract_timestamp()` does on the database side. If `publicId` is shown in a URL, that means an outside observer can tell roughly _when_ that account was created, even though they still can't enumerate or guess other accounts' ids (the random tail still makes that infeasible). For most apps this is an acceptable trade — order history, blog posts, and similar resources already reveal approximate creation time through other means (sort order, "posted 3 days ago," etc.) — but it's worth being a conscious choice rather than an accident. PostgreSQL's `uuidv7()` accepts an optional shift interval argument specifically to offset the embedded timestamp if you need to mask the real creation time.

### Generating UUIDv7

**Database-generated** (your Postgres is already version 18, which added this natively — no extension needed):

```sql
public_id UUID NOT NULL DEFAULT uuidv7()
```

**Application-generated**, via Hibernate (6.5+, which ships with Spring Boot 3.3+):

```java
@Column(name = "public_id", nullable = false, updatable = false)
@UuidGenerator(style = UuidGenerator.Style.VERSION_7)
private UUID publicId;
```

This replaces the `= UUID.randomUUID()` field initializer from before — `@UuidGenerator` is a Hibernate-level generator, so it assigns the value during the persist lifecycle rather than at object construction, the same way `@GeneratedValue` assigns `id` at persist time rather than having it preset in Java. (`Style.RANDOM` is Hibernate's equivalent for plain v4, `Style.VERSION_7` is the one that matters here — there's also `VERSION_6`, a different time-ordered layout from the same RFC, which you won't need unless something specifically calls for it.)

Which of the two to use follows the same reasoning as before: pick the database default if anything other than your Spring app might insert rows directly; pick the Hibernate generator if everything goes through JPA and you want the value visible in the Java object the moment `save()` returns, without a round-trip read-back.

### One honest implication worth naming

The entire reason you originally needed a _separate_ internal `BIGINT` id was that UUIDv4 was too fragmenting to serve as the primary key. UUIDv7 weakens that justification — it's largely why some teams now use UUIDv7 as the _sole_ primary key and drop the dual-identifier pattern altogether, since it's "good enough" at both jobs: externally safe-ish and internally index-friendly. That's a legitimate alternative design, but it's a bigger structural decision than swapping a generator — it means every foreign key in your schema goes from 8 bytes to 16, and the timestamp-leak trade-off above applies to _every_ reference, not just a public-facing column. Your current design doesn't require that change — you can drop `UuidGenerator.Style.VERSION_7` straight into the existing `publicId` column with everything else (the `Long id` as the real PK, `Orders.account_id` referencing it) untouched. Treat the "use it as the only key" route as a separate decision to make deliberately later, not something this swap commits you to now.



[[Spring Framework]]