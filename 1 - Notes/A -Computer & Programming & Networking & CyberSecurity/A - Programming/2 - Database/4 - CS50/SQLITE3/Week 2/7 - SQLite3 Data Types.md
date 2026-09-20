

SQLite's type system is unusual compared with PostgreSQL, MySQL, or Java.

The most important fact is:

> **SQLite does not have the traditional fixed-column-type system that many relational databases have.**

SQLite uses **dynamic typing** with a concept called **type affinity**.

---

# 1. SQLite's five storage classes

Internally, SQLite stores values using **five storage classes**:

|Storage class|Meaning|Examples|
|---|---|---|
|`NULL`|Missing/unknown value|`NULL`|
|`INTEGER`|Whole number|`42`, `-10`, `0`|
|`REAL`|Floating-point number|`3.14`, `-2.5`|
|`TEXT`|Text/string|`'Hello'`|
|`BLOB`|Raw binary data|Images, arbitrary bytes|

These are the **actual fundamental storage classes**.

---

# 2. `NULL`

Represents the absence of a value.

```sql
CREATE TABLE users (
    id INTEGER,
    nickname TEXT
);
```

You can insert:

```sql
INSERT INTO users (id, nickname)
VALUES (1, NULL);
```

`NULL` does **not** mean:

```text
0
```

and does not mean:

```text
''
```

It means:

> There is no value.

For example:

```sql
SELECT *
FROM users
WHERE nickname IS NULL;
```

Use `IS NULL`, not:

```sql
nickname = NULL
```

---

# 3. `INTEGER`

Stores whole numbers.

```sql
CREATE TABLE products (
    id INTEGER,
    quantity INTEGER,
    price_cents INTEGER
);
```

Examples:

```text
0
10
-50
100000
```

SQLite integers are signed and stored using 1, 2, 3, 4, 6, or 8 bytes depending on the value.

A particularly important SQLite feature:

```sql
id INTEGER PRIMARY KEY
```

has special behavior.

If you don't provide the `id`, SQLite can automatically generate an integer row ID.

```sql
INSERT INTO users (name)
VALUES ('Ali');
```

---

# 4. `REAL`

Stores floating-point numbers.

```sql
CREATE TABLE measurements (
    temperature REAL,
    weight REAL
);
```

Examples:

```text
36.5
3.14
-0.25
```

SQLite uses an **IEEE-754 64-bit floating-point representation** for `REAL`.

Because floating-point numbers have precision limitations, don't use `REAL` when exact decimal arithmetic is required, such as financial calculations.

---

# 5. `TEXT`

Stores strings.

```sql
CREATE TABLE users (
    name TEXT,
    email TEXT
);
```

Examples:

```text
'Ali'
'hello@example.com'
'Java Developer'
```

SQLite stores text using its configured text encoding, commonly UTF-8.

---

# 6. `BLOB`

**BLOB** means **Binary Large Object**.

It stores raw bytes without interpreting them as text.

For example:

```sql
CREATE TABLE files (
    id INTEGER PRIMARY KEY,
    data BLOB
);
```

BLOBs can represent:

```text
images
PDFs
encrypted data
binary files
arbitrary bytes
```

However, application databases often store large files outside the database and store their path/URL instead.

---

# 7. What about `BOOLEAN`?

This is where SQLite differs from databases such as PostgreSQL.

SQLite does **not** have a separate Boolean storage class.

You can write:

```sql
CREATE TABLE users (
    active BOOLEAN
);
```

SQLite accepts `BOOLEAN` as a declared type, but internally it uses integer values.

Conventionally:

```text
0 → false
1 → true
```

For example:

```sql
INSERT INTO users (active)
VALUES (1);
```

And:

```sql
SELECT *
FROM users
WHERE active = 1;
```

---

# 8. What about `DATE` and `DATETIME`?

SQLite also doesn't have dedicated date/time storage classes.

You can write:

```sql
CREATE TABLE events (
    created_at DATETIME
);
```

but SQLite doesn't turn `DATETIME` into a special date type.

SQLite commonly stores dates/times as:

### TEXT

```text
2026-09-17 14:30:00
```

### INTEGER

Unix timestamp:

```text
1789655400
```

### REAL

Julian day number.

SQLite provides date/time functions for working with these representations.

---

# 9. SQLite type affinity

Now we reach the unusual part.

You can declare:

```sql
CREATE TABLE test (
    value INTEGER
);
```

But SQLite's `INTEGER` declaration does **not necessarily mean**:

> "Only integers are allowed here."

SQLite determines a column's **type affinity** based on its declared type.

There are five affinities:

|Affinity|General purpose|
|---|---|
|`INTEGER`|Integer-oriented values|
|`TEXT`|Text-oriented values|
|`REAL`|Floating-point values|
|`NUMERIC`|Numeric values|
|`BLOB`|No preferred type|

---

# 10. Type affinity example

Consider:

```sql
CREATE TABLE test (
    value INTEGER
);
```

SQLite can still accept values that aren't strictly integers in many situations.

For example:

```sql
INSERT INTO test VALUES ('123');
```

SQLite may convert the text `'123'` to the integer:

```text
123
```

This is because of **type affinity**.

This is fundamentally different from a strongly enforced type system.

---

# 11. Declared types

SQLite allows many type names:

```sql
INTEGER
TEXT
VARCHAR(255)
CHAR(20)
BOOLEAN
DATE
DATETIME
DECIMAL(10,2)
NUMERIC
REAL
BLOB
```

But these aren't all separate SQLite storage types.

For example:

```sql
VARCHAR(255)
```

has **TEXT affinity**.

And:

```sql
BOOLEAN
```

has **NUMERIC affinity**.

And:

```sql
DATETIME
```

also has **NUMERIC affinity**.

---

# 12. The five affinity rules

SQLite determines affinity from the declared type name.

Simplified:

### Contains `INT`

→ `INTEGER` affinity

```sql
INTEGER
INT
BIGINT
UNSIGNED BIG INT
```

### Contains `CHAR`, `CLOB`, or `TEXT`

→ `TEXT` affinity

```sql
CHAR(20)
VARCHAR(255)
TEXT
CLOB
```

### Contains `REAL`, `FLOA`, or `DOUB`

→ `REAL` affinity

```sql
REAL
FLOAT
DOUBLE
DOUBLE PRECISION
```

### Contains `BLOB` or has no declared type

→ `BLOB` affinity

### Otherwise

→ `NUMERIC` affinity

For example:

```sql
BOOLEAN
DATE
DATETIME
DECIMAL(10,2)
NUMERIC
```

generally get `NUMERIC` affinity.

---

# 13. Important distinction

Don't confuse these:

```text
Declared type
      ↓
Type affinity
      ↓
Actual storage class
```

For example:

```sql
price DECIMAL(10,2)
```

doesn't mean SQLite has a special `DECIMAL` storage type.

Instead:

```text
DECIMAL(10,2)
      ↓
NUMERIC affinity
      ↓
SQLite decides how the particular value is stored
      ↓
INTEGER / REAL / TEXT / etc.
```

---

# 14. SQLite vs Java

Since you're working with Java, this distinction is useful.

Java:

```java
int age = 25;
double price = 19.99;
String name = "Ali";
boolean active = true;
```

Java has a **static type system**.

SQLite is much more flexible:

```sql
age INTEGER
price REAL
name TEXT
active BOOLEAN
```

but SQLite's runtime storage model is based on:

```text
NULL
INTEGER
REAL
TEXT
BLOB
```

So don't think:

> SQLite `INTEGER` = Java `int`

They are related conceptually, but they're **not the same type system**.

---

# 15. Quick reference

```text
SQLite Storage Classes
────────────────────────────────────
NULL       → absence of value
INTEGER    → whole numbers
REAL       → floating-point numbers
TEXT       → strings
BLOB       → raw binary data
```

Common declared types:

```text
INTEGER
TEXT
VARCHAR
CHAR
REAL
FLOAT
DOUBLE
NUMERIC
DECIMAL
BOOLEAN
DATE
DATETIME
BLOB
```

But remember:

> **SQLite fundamentally has five storage classes, not dozens of independent data types.**

And the key concept to learn next is **type affinity**, because that's what explains why SQLite's type behavior can look strange compared with PostgreSQL or Java.



[[1 - WHAT IS SQLITE3]]