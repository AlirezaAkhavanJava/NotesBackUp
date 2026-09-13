## SQLite3 Data Types

SQLite is unusual compared with databases like PostgreSQL or MySQL because it uses **dynamic typing**.

SQLite has **five storage classes**:

|Storage Class|Meaning|Example|
|---|---|---|
|`NULL`|No value|`NULL`|
|`INTEGER`|Whole numbers|`42`, `-10`|
|`REAL`|Floating-point numbers|`3.14`, `-0.5`|
|`TEXT`|Strings|`'Alireza'`|
|`BLOB`|Raw binary data|Images, files, bytes|

### 1. `NULL`

Represents the absence of a value.

```sql
INSERT INTO users (username, age)
VALUES ('alireza', NULL);
```

Important: `NULL` is **not** the same as `0` or an empty string `''`.

---

### 2. `INTEGER`

Whole numbers.

```sql
CREATE TABLE users (
    id INTEGER
);
```

Examples:

```text
0
42
-100
999999
```

One important SQLite feature:

```sql
id INTEGER PRIMARY KEY
```

has special behavior: it normally becomes an alias for SQLite's internal `rowid`.

---

### 3. `REAL`

Floating-point numbers.

```sql
CREATE TABLE products (
    price REAL
);
```

Example:

```sql
INSERT INTO products (price)
VALUES (19.99);
```

---

### 4. `TEXT`

Strings of text.

```sql
CREATE TABLE users (
    username TEXT,
    email TEXT
);
```

Example:

```sql
INSERT INTO users (username, email)
VALUES ('alireza', 'user@example.com');
```

SQLite stores text using its configured text encoding, normally UTF-8.

---

### 5. `BLOB`

**Binary Large Object.**

Used for arbitrary binary data.

For example:

```sql
CREATE TABLE files (
    id INTEGER PRIMARY KEY,
    data BLOB
);
```

It can contain raw bytes such as an image or other binary file.

---

# The important part: SQLite does NOT strictly enforce these types

This is where SQLite differs significantly from PostgreSQL.

You might write:

```sql
CREATE TABLE users (
    age INTEGER
);
```

and then:

```sql
INSERT INTO users (age)
VALUES ('hello');
```

SQLite can accept this.

Why?

Because `INTEGER` in the declaration is not simply saying:

> "This column can ONLY contain integers."

Instead, SQLite uses **type affinity**.

---

# Type Affinity

SQLite assigns each column a **type affinity**, which influences how SQLite attempts to store values.

The five affinity categories are:

```text
INTEGER
TEXT
REAL
NUMERIC
BLOB
```

For example:

```sql
CREATE TABLE users (
    id INTEGER,
    username TEXT,
    score REAL
);
```

Conceptually:

```text
id       → INTEGER affinity
username → TEXT affinity
score    → REAL affinity
```

But the actual stored value can sometimes have a different storage class.

You can inspect the actual storage type using:

```sql
SELECT typeof(age)
FROM users;
```

For example:

```sql
SELECT typeof(42);
```

returns:

```text
integer
```

while:

```sql
SELECT typeof(3.14);
```

returns:

```text
real
```

and:

```sql
SELECT typeof('hello');
```

returns:

```text
text
```

---

# SQLite's Type System vs PostgreSQL

This is an important distinction if you're learning both.

### PostgreSQL

```sql
CREATE TABLE users (
    age INTEGER
);

INSERT INTO users (age)
VALUES ('hello');
```

Normally → **error**

PostgreSQL has comparatively strict static typing.

### SQLite

```sql
CREATE TABLE users (
    age INTEGER
);

INSERT INTO users (age)
VALUES ('hello');
```

SQLite may accept it because of its **dynamic typing + type affinity** model.

So remember:

```text
PostgreSQL
    ↓
Strict column types

SQLite
    ↓
Dynamic typing
    +
Type affinity
    +
5 storage classes
```

### One more important distinction

Don't confuse **declared types** with **storage classes**:

```sql
CREATE TABLE users (
    age INTEGER
);
```

`INTEGER` here is a **declared type / type affinity**.

But internally, a particular value is stored using one of:

```text
NULL
INTEGER
REAL
TEXT
BLOB
```

That's the core of SQLite's type system.

[[1 - WHAT IS SQLITE3]]