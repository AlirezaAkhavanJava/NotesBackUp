
Think of a column's data type the way you think of a variable's type in Java: it tells MariaDB what kind of value lives there, how much space to reserve, and what operations make sense. The analogy holds for the basic idea, but it breaks down in one way: a column's type applies to every row in the table, and MariaDB checks it when data is _stored_, not when your code is compiled. So the type you pick is a promise about all your data, past and future.

Let's go through the main families.

## Whole numbers

```sql
TINYINT     -- 1 byte:  -128 to 127          (0 to 255 if UNSIGNED)
SMALLINT    -- 2 bytes: -32,768 to 32,767
MEDIUMINT   -- 3 bytes: about ±8.3 million
INT         -- 4 bytes: about ±2.1 billion   (up to 4.29 billion UNSIGNED)
BIGINT      -- 8 bytes: about ±9.2 quintillion
```

`INT` is the everyday choice for ids and counters. Use `BIGINT` when you expect to outgrow two billion rows, and `TINYINT` for small flags and codes. `UNSIGNED` means "no negatives", which doubles the positive range, so it suits ids and quantities.

`BOOLEAN` exists, but it's just a nickname for `TINYINT(1)`: 0 is false, 1 is true. Also, the number in `INT(11)` is only a legacy display hint. It does **not** limit how big the number can be, a common surprise.

## Numbers with decimals

```sql
DECIMAL(10,2)   -- exact: up to 10 digits total, 2 after the point
FLOAT           -- approximate, 4 bytes
DOUBLE          -- approximate, 8 bytes
```

Here's the rule worth memorizing: **use `DECIMAL` for money.** `FLOAT` and `DOUBLE` store binary approximations, so `0.1 + 0.2` can come out as `0.30000000000000004`. You've probably seen that in Java too, since it's the same IEEE floating-point behavior. `DECIMAL` stores exact digits, which is what you want when cents matter. Use `FLOAT`/`DOUBLE` for measurements where tiny rounding doesn't matter.

## Text

```sql
CHAR(2)          -- fixed length, always padded to 2 characters
VARCHAR(150)     -- variable length, up to 150 characters
TEXT             -- long text, up to about 64 KB
MEDIUMTEXT       -- up to about 16 MB
LONGTEXT         -- up to about 4 GB
```

`VARCHAR` is your default for names, emails, titles. `CHAR` is only worth it when the length truly never changes, like country codes (`'IR'`, `'US'`). Reach for `TEXT` when the content is long and unpredictable, like a message body. One practical difference: `TEXT` columns can't have a plain default value and are awkward to index, whereas `VARCHAR` works smoothly.

There's also a binary family (`BINARY`, `VARBINARY`, `BLOB`) for raw bytes. In practice, for images and files, most developers store the file on disk and keep only its path in the database.

## Dates and times

```sql
DATE        -- 2026-10-11
TIME        -- 14:30:00
DATETIME    -- 2026-10-11 14:30:00
TIMESTAMP   -- like DATETIME, but stored as UTC and converted to the session's time zone
YEAR        -- 2026
```

The `DATETIME` versus `TIMESTAMP` difference matters. `DATETIME` stores exactly what you give it. `TIMESTAMP` converts to and from time zones for you, but its range is more limited (older versions stop at 2038). `TIMESTAMP` fits "when was this row created or changed", and `DATETIME` fits "the event happens at this wall-clock time".

## A fixed menu of choices

```sql
status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending'
```

`ENUM` restricts a column to a fixed list of strings. It's convenient, but changing the list later means altering the table. Many developers prefer a small separate table plus a foreign key for anything that might grow.

## Modern extras

```sql
JSON    -- text that MariaDB checks is valid JSON
UUID    -- a native type for UUID values (MariaDB 10.7 and later)
```

Careful with `JSON` in MariaDB: it's really an alias for `LONGTEXT` with a validity check, not a special binary format like in MySQL. It works well for flexible side data, but if you find yourself querying inside it constantly, that's usually a sign the data wants real columns.

## Column "types" in the other sense: attributes and constraints

You might also mean the _roles_ a column plays. These are rules layered on top of the data type:

```sql
CREATE TABLE orders (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  reference   VARCHAR(30) NOT NULL UNIQUE,
  total       DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  note        VARCHAR(255) NULL,
  status      ENUM('pending','paid','shipped') DEFAULT 'pending',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

- **PRIMARY KEY** uniquely identifies each row; it's implicitly `NOT NULL` and `UNIQUE`.
- **FOREIGN KEY** links a column to another table's key, so you can't point at a user who doesn't exist.
- **UNIQUE** forbids duplicate values.
- **NOT NULL / NULL** says whether the value may be missing. `NULL` means "unknown or absent", which is _not_ the same as `0` or an empty string, and it behaves oddly in comparisons (`WHERE note = NULL` never matches; you write `WHERE note IS NULL`).
- **DEFAULT** supplies a value when you don't.
- **CHECK** rejects values that break a condition.
- **AUTO_INCREMENT** numbers rows for you.

There are also _generated columns_, whose value MariaDB computes from other columns, for example `full_name VARCHAR(200) AS (CONCAT(first_name, ' ', last_name))`. Handy, though you can leave them for later.

## How this lines up with Java

Since you're heading into Spring Boot, here's the mapping you'll meet when writing entities:

|MariaDB|Java|
|---|---|
|`INT`|`int` / `Integer`|
|`BIGINT`|`long` / `Long`|
|`VARCHAR`, `TEXT`|`String`|
|`DECIMAL`|`BigDecimal`|
|`BOOLEAN`|`boolean`|
|`DATE`|`LocalDate`|
|`DATETIME`, `TIMESTAMP`|`LocalDateTime` / `Instant`|

The `DECIMAL` to `BigDecimal` pairing is the same lesson as before: both are exact, which is why they belong together for money.

## Choosing quickly

When you're unsure, this covers most cases: `BIGINT` or `INT` for ids, `VARCHAR(n)` for short text, `TEXT` for long text, `DECIMAL` for money, `DATETIME` or `TIMESTAMP` for time, `BOOLEAN` for yes/no. Pick the smallest type that safely fits, because smaller columns make smaller indexes and faster queries. But don't squeeze too hard: running out of room later is much more painful than spending a few extra bytes today.


[[MySQL]]
