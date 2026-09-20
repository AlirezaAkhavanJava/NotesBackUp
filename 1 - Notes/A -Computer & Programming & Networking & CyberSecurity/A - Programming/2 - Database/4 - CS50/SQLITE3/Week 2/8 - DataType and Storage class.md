
The key difference is:

> **A data type describes what a value is supposed to represent. A storage class describes how SQLite actually stores that value internally.**

In SQLite, these concepts are deliberately separated.

### 1. Data type

A **data type** is a classification of data.

For example:

```text
INTEGER → whole numbers
TEXT    → strings
REAL    → floating-point numbers
BLOB    → binary data
```

When you define a table:

```sql
CREATE TABLE users (
    id INTEGER,
    name TEXT,
    age INTEGER
);
```

`INTEGER` and `TEXT` are **declared types**.

---

### 2. Storage class

A **storage class** describes the actual representation SQLite uses for a particular value.

SQLite has exactly five storage classes:

```text
NULL
INTEGER
REAL
TEXT
BLOB
```

For example:

```sql
INSERT INTO users (age)
VALUES (25);
```

The value `25` is actually stored using the **INTEGER storage class**.

---

### 3. Why are they different in SQLite?

Because SQLite uses **dynamic typing**.

Consider:

```sql
CREATE TABLE test (
    value INTEGER
);
```

You declared `value` as `INTEGER`.

But SQLite doesn't treat that declaration as an absolute restriction in the same way a strongly typed database might.

SQLite gives the column an **INTEGER affinity**, which influences how values are converted/stored.

For example:

```sql
INSERT INTO test VALUES ('123');
```

SQLite can recognize that `'123'` represents an integer and store it as:

```text
INTEGER → 123
```

So:

```text
Declared type
      ↓
   INTEGER
      ↓
Type affinity
      ↓
INTEGER affinity
      ↓
Actual value
      ↓
Storage class
      ↓
INTEGER
```

---

### 4. A more interesting example

Suppose:

```sql
CREATE TABLE test (
    value NUMERIC
);
```

Now:

```sql
INSERT INTO test VALUES ('123');
INSERT INTO test VALUES ('3.14');
INSERT INTO test VALUES ('hello');
```

SQLite can store these with different storage classes:

```text
value       storage class
─────────────────────────
123         INTEGER
3.14        REAL
hello       TEXT
```

Even though all three values are in the same `NUMERIC`-affinity column.

That's the important distinction.

---

### 5. Think of it like Java

A rough analogy:

```text
Java
────────────────────
Declared type → int
Actual value  → 25
```

SQLite:

```text
SQLite
────────────────────────────
Declared type  → NUMERIC
Affinity       → NUMERIC
Actual value   → 25
Storage class  → INTEGER
```

It's not a perfect Java analogy, but it helps.

---

### 6. The hierarchy to remember

```text
                    SQLite column
                         │
                         ▼
                  Declared type
                  "INTEGER"
                         │
                         ▼
                  Type affinity
                  "INTEGER"
                         │
                         ▼
                    actual value
                       "25"
                         │
                         ▼
                  Storage class
                    "INTEGER"
```

So when studying SQLite, keep these three terms separate:

|Concept|Question it answers|
|---|---|
|**Declared type**|What type did I define for the column?|
|**Type affinity**|What type does SQLite prefer for values in this column?|
|**Storage class**|How is this particular value actually stored?|

This distinction is one of the most important things to understand about **SQLite's type system**.


[[1 - WHAT IS SQLITE3]]