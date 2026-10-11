Time is where MariaDB has the most traps, so it gets the most space here. After that, I'll cover the types we haven't touched yet.

## The five time types

```sql
DATE         -- 2026-10-11
TIME         -- 14:30:00
DATETIME     -- 2026-10-11 14:30:00
TIMESTAMP    -- 2026-10-11 14:30:00 (but stored as UTC, see below)
YEAR         -- 2026
```

|Type|Range|Storage|
|---|---|---|
|`DATE`|1000-01-01 to 9999-12-31|3 bytes|
|`TIME`|-838:59:59 to 838:59:59|3 bytes|
|`DATETIME`|1000-01-01 to 9999-12-31|5 bytes|
|`TIMESTAMP`|1970-01-01 to 2038-01-19 (older versions)|4 bytes|
|`YEAR`|1901 to 2155 (and `0000`)|1 byte|

As far as I know, MariaDB 11.5 and later extend the `TIMESTAMP` limit to 2106 on 64-bit systems, which would include the version Debian 13 ships. Still, check with `SELECT VERSION();` if the 2038 limit matters to you.

`TIME` has a range of over 800 hours because it's designed to hold a **duration** as well as a time of day, like "36:15:00". MariaDB has no `INTERVAL` column type like Postgres does, so `TIME` is the closest thing, and for longer or more precise durations most people store a plain number of seconds in an `INT` or `BIGINT`.

## DATETIME vs TIMESTAMP: the one that matters

You'll compare these against Postgres's `timestamp` and `timestamptz`, and the comparison is useful but imperfect:

- **`DATETIME`** stores exactly the wall-clock value you give it, with no time zone logic. It behaves like Postgres `timestamp without time zone`.
- **`TIMESTAMP`** converts your value to UTC when storing it, and converts back to the session's time zone when reading. That's the _behavior_ of `timestamptz`.

The analogy breaks in one place: like `timestamptz`, `TIMESTAMP` doesn't actually store the zone, only the UTC instant. But unlike Postgres, what you get back depends on the **session's** `time_zone` setting, and by default that follows the server's zone:

```sql
SELECT @@global.time_zone, @@session.time_zone;   -- often SYSTEM
SET time_zone = '+00:00';                          -- offsets always work
SET time_zone = 'Asia/Tehran';                     -- named zones need the tz tables loaded
```

Named zones only work if the time zone tables have been filled in, which on Debian you do once with `mariadb-tzinfo-to-sql /usr/share/zoneinfo | sudo mariadb mysql`. Otherwise you'll get an "unknown time zone" error, which surprises people.

A practical rule: use `TIMESTAMP` for "when did this row change" and `DATETIME` for "something that happens at this local time" (a meeting at 09:00 wherever you are).

## Fractional seconds

By default, time types keep whole seconds only. Ask for more with a precision from 0 to 6:

```sql
created_at DATETIME(3)     -- milliseconds
updated_at TIMESTAMP(6)    -- microseconds
```

Be aware that MariaDB **truncates** extra digits rather than rounding, which differs from MySQL. This matters for Spring Boot, because Java's `Instant` and `LocalDateTime` carry nanoseconds, and a column with the default precision silently drops everything below one second.

## Automatic timestamps

This is a very common pattern, and it works on both `TIMESTAMP` and `DATETIME`:

```sql
CREATE TABLE posts (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  title      VARCHAR(200) NOT NULL,
  created_at DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP
                       ON UPDATE CURRENT_TIMESTAMP
);
```

`ON UPDATE CURRENT_TIMESTAMP` is something Postgres users miss, because there you'd need a trigger to get the same effect. Here the database refreshes `updated_at` on its own whenever another column in the row changes.

## Functions you'll use constantly

```sql
SELECT NOW(), CURDATE(), CURTIME();
SELECT DATE_ADD(NOW(), INTERVAL 7 DAY);
SELECT DATEDIFF('2026-12-25', CURDATE());            -- difference in days
SELECT TIMESTAMPDIFF(HOUR, created_at, NOW()) FROM posts;
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i');         -- like to_char
SELECT STR_TO_DATE('11/10/2026', '%d/%m/%Y');        -- like to_date
SELECT YEAR(created_at), MONTH(created_at) FROM posts;
```

Note that the format codes use `%i` for minutes and `%H` for 24-hour time, which differ from Postgres's `MI` and `HH24`.

## Spring Boot mapping

|MariaDB|Java|
|---|---|
|`DATE`|`LocalDate`|
|`TIME`|`LocalTime` (or `Duration`)|
|`DATETIME`|`LocalDateTime`|
|`TIMESTAMP`|`Instant` or `OffsetDateTime`|

A common safe setup is to store everything in UTC, use `Instant` in your entities, and set `spring.jpa.properties.hibernate.jdbc.time_zone=UTC` so the driver and database agree.

## Types we haven't covered yet

**Numeric aliases.** These are just nicknames you'll see in other people's schemas: `BOOL`, `NUMERIC` and `DEC` (both mean `DECIMAL`), and `SERIAL`, which expands to `BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE`. It's a shortcut with a similar spirit to Postgres's `SERIAL`, though it's not the same mechanism.

**BIT.** Stores raw bits, `BIT(8)` being 8 flags in one byte. You'll rarely need it, and `TINYINT` or `SET` is usually friendlier.

**Binary strings.** `BINARY(n)` and `VARBINARY(n)` are the fixed and variable-length siblings of `CHAR` and `VARCHAR`, with no character set. They suit hashes and tokens:

```sql
password_hash BINARY(32)
```

**Network addresses.** MariaDB has native types that Postgres's `inet` would cover:

```sql
ip4 INET4,    -- 4 bytes, stores 192.168.1.10
ip6 INET6     -- 16 bytes, stores IPv4 or IPv6
```

They store compact binary but show and accept the normal text form, and they sort correctly. There's no `CIDR` type or subnet operators like Postgres has, so subnet matching needs more manual work.

**UUID.** We mentioned it earlier. It stores 16 bytes internally and displays the usual dashed text. One tip: random UUIDs as primary keys scatter inserts across the index and can slow InnoDB down on big tables. MariaDB's `UUID_v7()` function (in recent versions) generates time-ordered values that avoid that.

**Spatial types.** `GEOMETRY`, `POINT`, `LINESTRING`, and `POLYGON` store geographic shapes and support spatial indexes and functions like `ST_Distance`. This is the rough counterpart to PostGIS, but much more basic, so for serious geo work Postgres is the stronger choice.

**VECTOR.** Newer MariaDB versions (11.7 and later) add a `VECTOR(n)` type with vector indexes, aimed at AI embedding search, similar in purpose to `pgvector`. Since Debian 13 ships a recent MariaDB, you'd likely have it, but I'd check `SELECT VERSION();` before relying on it.

**JSON.** Mentioned before, and the caveat remains: in MariaDB it's `LONGTEXT` with a validity check, not a binary format like Postgres's `jsonb`. You can reach into it with `JSON_VALUE(col, '$.name')` and `JSON_EXTRACT`, but you can't index it directly, so you'd use a generated column for that.

## What MariaDB doesn't have

Since you know Postgres, it's worth knowing what's _missing_ so you don't go looking:

- no **array** columns (use a child table or JSON)
- no **range** types like `daterange`
- no `INTERVAL` or `timestamptz` as separate types
- no `hstore`, no user-defined composite types, and no `CREATE DOMAIN`
- no `MONEY` type (and you wouldn't want it anyway: `DECIMAL` is the right choice)

MariaDB's strengths lie in simplicity and predictable behavior, while Postgres wins on type richness.




[[MySQL]]