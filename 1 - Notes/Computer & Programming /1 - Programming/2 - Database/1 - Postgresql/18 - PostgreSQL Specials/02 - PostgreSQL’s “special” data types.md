


Most of the time you can build an app with `integer`, `text`, `boolean`, and `timestamp`. But PostgreSQL also ships types that understand specific kinds of data: IP addresses, time ranges, shapes on a plane, searchable documents, and so on. The benefit is that the database itself knows what the data means. It validates it, indexes it, and gives you operators for it, so you don't have to write that logic in Java.

The seven groups in your image are all of this kind. For each one I'll start with the problem it solves, then show examples, then the errors you're likely to hit, and then how it maps to Spring Boot. A summary table at the end ties the Spring Boot side together.

---

## 1. `bytea`: raw binary data

**The problem it solves:** You need to store bytes, not text. Think small images, file hashes, encrypted values, or a PDF thumbnail. A `text` column would corrupt or reject arbitrary bytes, and `bytea` stores them exactly as given.

```sql
CREATE TABLE avatars (
    id      serial PRIMARY KEY,
    user_id int NOT NULL,
    image   bytea NOT NULL
);

INSERT INTO avatars (user_id, image) VALUES (1, '\xDEADBEEF');
INSERT INTO avatars (user_id, image) VALUES (2, decode('48656c6c6f', 'hex'));

SELECT id, image, length(image) FROM avatars;
```

Walkthrough:

- `'\xDEADBEEF'` is the hex input format. `\x` means "what follows is hex," and every two hex digits are one byte, so this is 4 bytes.
- `decode('48656c6c6f', 'hex')` turns a hex string into bytes. Those bytes spell "Hello."
- `length(image)` returns the number of bytes.

|Value you write|Bytes stored|
|---|---|
|`'\xDEADBEEF'`|4|
|`decode('48656c6c6f','hex')`|5|
|`''::bytea`|0|

**Errors you may hit:**

- `invalid input syntax for type bytea`: your hex string has an odd number of digits or a bad character.
- Output looks like `\x48656c6c6f` in psql. That is normal. It is just how `bytea_output = 'hex'` displays bytes.
- Large values: a single value can be up to 1 GB, but moving huge files through normal queries is slow and memory-hungry. For big files, many teams store them on disk or object storage and keep only the path in PostgreSQL.

**In Spring Boot:** map it to `byte[]`.

```java
@Entity
public class Avatar {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private byte[] image;   // maps to bytea
}
```

**Gotcha:** don't put `@Lob` on a `byte[]` for PostgreSQL unless you really want it. `@Lob` can make Hibernate use PostgreSQL _Large Objects_ (an `oid` column pointing to a separate storage area), which behave differently and cause errors like `Large Objects may not be used in auto-commit mode`. Plain `byte[]` gives you real `bytea`.

_Related concept, Large Objects (`oid`):_ a separate PostgreSQL mechanism for streaming very big binary data in chunks. It is more complex than `bytea`, and you usually only need it for files much larger than a few hundred MB.

---

## 2. `inet` and `cidr`: IP addresses and networks

**The problem it solves:** Storing IPs as `varchar` means you can't ask "is this IP inside this network?" without parsing strings. These types validate the format (IPv4 and IPv6) and give you network operators.

- `inet` holds a host address, optionally with a netmask: `192.168.1.5` or `192.168.1.5/24`.
- `cidr` holds a network: `192.168.1.0/24`. It is stricter, because the bits after the mask must be zero.

```sql
CREATE TABLE login_attempts (
    id      serial PRIMARY KEY,
    ip      inet NOT NULL,
    at      timestamptz DEFAULT now()
);

CREATE TABLE blocked_networks (
    net cidr PRIMARY KEY
);

INSERT INTO blocked_networks VALUES ('203.0.113.0/24');
INSERT INTO login_attempts (ip) VALUES ('203.0.113.77'), ('198.51.100.4');

-- Which attempts come from a blocked network?
SELECT a.*
FROM login_attempts a
JOIN blocked_networks b ON a.ip << b.net;
```

Walkthrough: `<<` means "is strictly contained within." `203.0.113.77` falls inside `203.0.113.0/24`, so the first row matches and the second does not.

|Operator|Meaning|
|---|---|
|`<<` / `<<=`|contained in / contained in or equal|
|`>>` / `>>=`|contains / contains or equal|
|`&&`|overlaps|

**Errors you may hit:**

- `invalid input syntax for type inet: "999.1.1.1"`: not a valid address.
- `invalid cidr value: "192.168.1.5/24"` with `DETAIL: Value has bits set to right of mask.` The `/24` means only the first 24 bits are the network, so the last part must be `0`. Write `192.168.1.0/24` instead, or use `inet` if you want to keep the host part.
- For fast "is IP in network" lookups on large tables, use a GiST index: `CREATE INDEX ON blocked_networks USING gist (net inet_ops);`. A normal B-tree index can't speed up `<<`.

**In Spring Boot:** this is where people get stuck. Recent Hibernate 6 versions can map `inet` to `java.net.InetAddress`:

```java
@JdbcTypeCode(SqlTypes.INET)
@Column(columnDefinition = "inet")
private InetAddress ip;
```

If you use a plain `String` instead, the insert fails with:

```
column "ip" is of type inet but expression is of type character varying
```

That happens because the driver sends the value as `varchar`, and PostgreSQL won't implicitly convert it. Fixes:

1. Use the `InetAddress` mapping above, or
2. Add `?stringtype=unspecified` to your JDBC URL so the server infers the type, or
3. In native queries, cast explicitly: `CAST(:ip AS inet)`.

---

## 3. `macaddr`: hardware (MAC) addresses

**The problem it solves:** A MAC address like `08:00:2b:01:02:03` can be written many ways (dashes, dots, no separators). `macaddr` accepts all the common formats, validates them, and stores them in a canonical 6-byte form, so `08-00-2b-01-02-03` and `0800.2b01.0203` are recognized as the same value.

```sql
CREATE TABLE devices (
    id   serial PRIMARY KEY,
    name text,
    mac  macaddr UNIQUE
);

INSERT INTO devices (name, mac) VALUES
  ('Laptop', '08:00:2b:01:02:03'),
  ('Phone',  '08-00-2b-aa-bb-cc');

SELECT name, mac, trunc(mac) AS vendor_prefix FROM devices;
```

Walkthrough: both inputs are accepted in different formats and displayed as `08:00:2b:...`. `trunc(mac)` zeroes the last three bytes, leaving the vendor prefix (OUI), which is handy for "which manufacturer?" reports. The `UNIQUE` constraint also catches duplicates written in different formats.

**Errors you may hit:**

- `invalid input syntax for type macaddr: "08:00:2b:01:02"`: you gave 5 bytes instead of 6.
- For newer 8-byte (EUI-64) addresses, use `macaddr8`.
- The same "varchar vs macaddr" error as `inet` applies from Java.

**In Spring Boot:** there is no built-in Java type for it. The simplest approach is a `String` field plus `?stringtype=unspecified` in the JDBC URL, or an explicit `CAST(:mac AS macaddr)` in native queries. Validate the format in Java too (a `@Pattern`), so users get a friendly error before the database rejects it.

---

## 4. Range types: `int4range`, `daterange`, and friends

**The problem it solves:** Think of a hotel booking. With two columns (`start_date`, `end_date`) you must write the overlap logic yourself, and nothing stops two bookings from overlapping. A range type stores "from X up to Y" as one value, with operators for overlap and containment, and it lets the database enforce "no overlaps" by itself.

Built-in ranges: `int4range`, `int8range`, `numrange`, `daterange`, `tsrange` (timestamp), `tstzrange` (timestamp with time zone).

**Bounds notation:** `[` means inclusive, `)` means exclusive.

|Written|Meaning|
|---|---|
|`[1,10)`|1 up to 9 (10 excluded)|
|`[2026-11-01,2026-11-05)`|Nov 1 to Nov 4 (check-out day excluded)|
|`(,5]`|everything up to 5 (no lower limit)|

For discrete types (`int4range`, `daterange`) PostgreSQL always normalizes to `[)`. That is why `daterange('2026-11-01','2026-11-05','[]')` prints as `[2026-11-01,2026-11-06)`.

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE bookings (
    id      serial PRIMARY KEY,
    room_id int NOT NULL,
    stay    daterange NOT NULL,
    EXCLUDE USING gist (room_id WITH =, stay WITH &&)
);

INSERT INTO bookings (room_id, stay) VALUES (101, '[2026-11-01,2026-11-05)');
INSERT INTO bookings (room_id, stay) VALUES (101, '[2026-11-05,2026-11-08)');  -- OK
INSERT INTO bookings (room_id, stay) VALUES (101, '[2026-11-04,2026-11-06)');  -- ERROR

SELECT * FROM bookings WHERE stay @> DATE '2026-11-02';
```

Line by line:

- `CREATE EXTENSION btree_gist` lets a GiST index handle plain equality (`room_id WITH =`) alongside ranges.
- `EXCLUDE USING gist (room_id WITH =, stay WITH &&)` means "no two rows may have the same room AND overlapping stays." It works like a `UNIQUE` constraint, but for overlap.
- The second insert starts exactly when the first ends. Because the end is exclusive, they don't overlap, so it succeeds.
- The third insert overlaps (Nov 4 is inside the first stay) and is rejected.
- `@>` means "contains," so the last query finds the booking covering Nov 2.

**Errors you may hit:**

- `conflicting key value violates exclusion constraint "bookings_room_id_stay_excl"`: the overlap rule did its job. In Spring, catch `DataIntegrityViolationException` and show "room already booked."
- `range lower bound must be less than or equal to range upper bound`: you wrote `[10,1)`.
- `data type integer has no default operator class for access method "gist"`: you forgot `btree_gist`.
- `malformed range literal`: a syntax slip such as a missing bracket.

**In Spring Boot:** Hibernate has no standard built-in mapping for ranges. Your options:

1. **hypersistence-utils** (the `io.hypersistence` library), which provides a `Range<T>` type you can annotate onto a field.
2. Keep two plain columns in the entity and convert in the database or the query.
3. Use native queries for range logic and expose only start/end dates in Java. This is the simplest and often enough.

```java
@Query(value = """
    SELECT COUNT(*) FROM bookings
    WHERE room_id = :room AND stay && daterange(:from, :to)
    """, nativeQuery = true)
long countOverlaps(@Param("room") int room,
                   @Param("from") LocalDate from,
                   @Param("to") LocalDate to);
```

_Related concept, multiranges (PostgreSQL 14+):_ types like `datemultirange` hold several ranges in one value, such as "available Mon-Wed and Fri-Sun."

---

## 5. Geometric types: `point`, `polygon`, and friends

**The problem it solves:** Simple 2D geometry (positions on a floor plan, a drawn zone on a diagram, the distance between two coordinates) can live directly in the database, without extra software.

Types: `point`, `line`, `lseg` (line segment), `box`, `path`, `polygon`, `circle`.

```sql
CREATE TABLE shops (
    id   serial PRIMARY KEY,
    name text,
    pos  point
);

INSERT INTO shops (name, pos) VALUES
  ('A', '(1,2)'), ('B', '(4,6)'), ('C', point(10,10));

-- Distance between A and B
SELECT '(1,2)'::point <-> '(4,6)'::point AS dist;   -- 5

-- Is a point inside a polygon?
SELECT polygon '((0,0),(0,10),(10,10),(10,0))' @> point '(3,3)';   -- true

-- Closest shop to (0,0)
SELECT name FROM shops ORDER BY pos <-> point '(0,0)' LIMIT 1;
```

Walkthrough: `<->` is the distance operator, and the first query is a 3-4-5 triangle, so the answer is 5. `@>` means "contains," so the polygon contains the point. The last query sorts by distance and takes the nearest, which a GiST index can speed up.

**Important limitation:** these are flat, plane geometry types. They know nothing about the curved Earth. For real latitude/longitude work (distance in meters, "within 5 km"), use the **PostGIS** extension instead.

**Errors you may hit:**

- `invalid input syntax for type point: "1,2,3"`: wrong number of coordinates.
- `invalid input syntax for type polygon`: unbalanced parentheses.
- Using lat/long here and getting "distances" in degrees rather than kilometers. That is the sign you need PostGIS.

**In Spring Boot:** no default mapping. Options:

- **Hibernate Spatial** with PostGIS and JTS types (`org.locationtech.jts.geom.Point`), which is the proper route for real geographic data.
- For these simple types, use a native query, or the driver's `org.postgresql.geometric.PGpoint` through a custom type.
- Often simplest: store `x` and `y` as two `double` fields, or compute geometry only inside queries.

---

## 6. `tsvector`: full-text search

**The problem it solves:** `LIKE '%running%'` is slow on big tables, can't rank results, and won't find "run" or "ran." Full-text search breaks text into normalized words (lowercased, stemmed, with filler words removed) so searching is fast and smart.

Two types work together:

- `tsvector` is the _document_: the processed words with their positions.
- `tsquery` is the _search_: what you are looking for.

```sql
SELECT to_tsvector('english', 'The quick brown foxes are running');
-- 'brown':3 'fox':4 'quick':2 'run':6

SELECT to_tsvector('english', 'The quick brown foxes are running')
       @@ to_tsquery('english', 'fox & run');
-- true
```

Look at what happened: "The" and "are" disappeared (stop words), "foxes" became `fox`, and "running" became `run`. The numbers are word positions. `@@` means "matches," and `&` means AND.

A realistic setup with an index:

```sql
CREATE TABLE articles (
    id     serial PRIMARY KEY,
    title  text,
    body   text,
    search tsvector GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,''))
    ) STORED
);

CREATE INDEX articles_search_idx ON articles USING gin (search);

SELECT id, title
FROM articles
WHERE search @@ websearch_to_tsquery('english', 'spring boot "connection pool"')
ORDER BY ts_rank(search, websearch_to_tsquery('english', 'spring boot "connection pool"')) DESC;
```

Line by line:

- `GENERATED ALWAYS AS (...) STORED` keeps the `search` column up to date automatically whenever title or body changes.
- `coalesce(...)` avoids `NULL` wiping out the whole vector.
- `USING gin` is the index type designed for this, and it makes searches fast.
- `websearch_to_tsquery` accepts text the way users type it in a search box, including quotes and `-word`.
- `ts_rank` sorts the best matches first.

**Errors you may hit:**

- `syntax error in tsquery: "spring boot"`: `to_tsquery` expects operators between words. For user-typed text, use `plainto_tsquery` or `websearch_to_tsquery`.
- `functions in index expression must be marked IMMUTABLE`: you called `to_tsvector(text)` without the language. Always pass the config (`'english'`).
- `string is too long for tsvector`: a single document is limited to about 1 MB.
- Results look wrong because you indexed with `'english'` but searched with `'simple'`. Keep the config consistent.

**In Spring Boot:** don't map the `tsvector` column to an entity field at all. It is a search helper, not business data. Leave it out of the entity (the database fills it) and search with a native query:

```java
@Query(value = """
    SELECT * FROM articles
    WHERE search @@ websearch_to_tsquery('english', :q)
    ORDER BY ts_rank(search, websearch_to_tsquery('english', :q)) DESC
    """, nativeQuery = true)
List<Article> search(@Param("q") String q);
```

Because the column is generated, add `@Column(insertable = false, updatable = false)` if you ever do map it, so Hibernate never tries to write it.

_Related concept, GIN vs GiST indexes:_ GIN is the usual choice for `tsvector` (faster reads, slower writes). GiST is smaller and quicker to update but slower to search.

---

## 7. `money`: currency amounts (use with caution)

**The problem it solves:** It stores a currency amount in an 8-byte fixed-point format with two decimals, and formats it with the currency symbol.

```sql
SELECT '12.50'::money + '7.25'::money;   -- $19.75
```

**Why most developers avoid it:**

|Issue|What happens|
|---|---|
|Locale-dependent|Display and parsing follow `lc_monetary`. The same value can show as `$1,234.50` or `1.234,50 €`, and moving a dump to another server can break loading.|
|Fixed precision|Always the same number of decimals for the locale, with no flexibility.|
|No currency stored|The symbol is just formatting, so `$5` and `€5` are the same data.|
|Awkward in Java|Drivers return it as a formatted string.|

**Errors you may hit:**

- `invalid input syntax for type money: "1,2,3"`.
- From JDBC: `Bad value for type double : $1,000.00`, because the driver tries to read the formatted text as a number.
- Rounding surprises when you cast from floating-point or divide.

**The recommendation:** use `numeric(12,2)` for money, and store the currency code in a separate column such as `currency char(3)`.

**In Spring Boot:**

```java
@Column(precision = 12, scale = 2)
private BigDecimal amount;      // numeric(12,2)

@Column(length = 3)
private String currency;        // "USD", "EUR"
```

`BigDecimal` with `numeric` is exact, locale-independent, and well supported. Never use `double` or `float` for money in Java either.

---

## Spring Boot mapping summary

|PostgreSQL type|Easiest Java mapping|Notes|
|---|---|---|
|`bytea`|`byte[]`|Skip `@Lob` (it can switch to `oid`)|
|`inet`|`InetAddress` with `@JdbcTypeCode(SqlTypes.INET)`|`String` needs `stringtype=unspecified` or a `CAST`|
|`cidr`|`String`|Cast in native queries|
|`macaddr`|`String`|Validate in Java, cast in SQL|
|`int4range`, `daterange`, ...|hypersistence-utils `Range<T>`, or native queries|No standard Hibernate mapping|
|`point`, `polygon`|PostGIS and Hibernate Spatial, or native queries|Geographic data needs PostGIS|
|`tsvector`|Usually not mapped|Query with native `@@`|
|`money`|Avoid it. Use `BigDecimal` with `numeric(12,2)`||

**General rules that prevent most errors:**

1. When Java sends a plain string to a special column, PostgreSQL says `column "x" is of type ... but expression is of type character varying`. The fix is a `CAST(:param AS type)`, a proper Hibernate type, or `?stringtype=unspecified` on the JDBC URL.
2. For anything Hibernate doesn't understand, a **native query** is a perfectly good solution.
3. Let the database enforce rules where it can (exclusion constraints, `cidr` validation), and catch `DataIntegrityViolationException` in Spring to turn them into friendly messages.
4. Use `ddl-auto=validate` (or Flyway/Liquibase migrations) so Hibernate doesn't try to create special columns as plain text.






[[PostgreSQL]]
[[Spring Framework]]