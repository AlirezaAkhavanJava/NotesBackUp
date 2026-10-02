

There are two big categories:

1. **Scalar functions** → operate on individual values.
    
2. **Aggregate/window functions** → operate across multiple rows.
    

---

# 1. Aggregate Functions

These combine multiple rows into a single result.

|Function|Purpose|Example|
|---|---|---|
|`COUNT()`|Count rows/values|`COUNT(*)`|
|`SUM()`|Add values|`SUM(price)`|
|`AVG()`|Calculate average|`AVG(score)`|
|`MIN()`|Find minimum|`MIN(age)`|
|`MAX()`|Find maximum|`MAX(age)`|
|`GROUP_CONCAT()`|Combine values into one string|`GROUP_CONCAT(name)`|

### Examples

```sql
SELECT COUNT(*) FROM longlist;
```

```sql
SELECT AVG(rating) FROM longlist;
```

```sql
SELECT MIN(year) FROM longlist;
```

```sql
SELECT MAX(year) FROM longlist;
```

```sql
SELECT SUM(price) FROM books;
```

---

# 2. Window Functions

These are especially important because **`ROW_NUMBER()` belongs here**.

Unlike aggregate functions, window functions usually **don't collapse rows**.

For example:

```sql
SELECT
    ROW_NUMBER() OVER (ORDER BY title) AS row_number,
    title
FROM longlist;
```

### Important SQLite window functions

|Function|Purpose|
|---|---|
|`ROW_NUMBER()`|Sequential row number|
|`RANK()`|Rank with gaps|
|`DENSE_RANK()`|Rank without gaps|
|`PERCENT_RANK()`|Relative rank|
|`CUME_DIST()`|Cumulative distribution|
|`NTILE()`|Divide rows into groups|
|`LAG()`|Get previous row's value|
|`LEAD()`|Get next row's value|
|`FIRST_VALUE()`|First value in window|
|`LAST_VALUE()`|Last value in window|
|`NTH_VALUE()`|Nth value in window|

### Example

```sql
SELECT
    title,
    rating,
    ROW_NUMBER() OVER (ORDER BY rating DESC) AS row_number
FROM longlist;
```

Result:

```text
1 | Book A | 9.8
2 | Book C | 9.5
3 | Book B | 9.1
```

---

# 3. String Functions

These work with text.

|Function|Purpose|
|---|---|
|`length()`|Length of string|
|`lower()`|Convert to lowercase|
|`upper()`|Convert to uppercase|
|`trim()`|Remove whitespace|
|`ltrim()`|Remove whitespace from left|
|`rtrim()`|Remove whitespace from right|
|`substr()`|Extract part of string|
|`replace()`|Replace text|
|`instr()`|Find position of substring|
|`printf()`|Format a string|
|`concat()`|Concatenate values|
|`concat_ws()`|Concatenate with separator|

Examples:

```sql
SELECT length(title)
FROM longlist;
```

```sql
SELECT upper(title)
FROM longlist;
```

```sql
SELECT lower(title)
FROM longlist;
```

```sql
SELECT substr(title, 1, 5)
FROM longlist;
```

```sql
SELECT replace(title, 'The', 'A')
FROM longlist;
```

---

# 4. Numeric / Mathematical Functions

SQLite provides functions for numerical operations.

|Function|Purpose|
|---|---|
|`abs()`|Absolute value|
|`round()`|Round number|
|`ceil()`|Round up|
|`floor()`|Round down|
|`mod()`|Modulo|
|`sign()`|Sign of number|
|`sqrt()`|Square root|
|`pow()`|Power|
|`exp()`|Exponential|
|`ln()`|Natural logarithm|
|`log()`|Logarithm|
|`log10()`|Base-10 logarithm|
|`log2()`|Base-2 logarithm|
|`sin()`|Sine|
|`cos()`|Cosine|
|`tan()`|Tangent|
|`asin()`|Inverse sine|
|`acos()`|Inverse cosine|
|`atan()`|Inverse tangent|
|`atan2()`|Two-argument arctangent|
|`pi()`|π|

For example:

```sql
SELECT round(AVG(rating), 2)
FROM longlist;
```

---

# 5. Date & Time Functions

SQLite doesn't have a dedicated `DATE`/`TIME` type like PostgreSQL.

Instead, it provides date/time functions.

|Function|Purpose|
|---|---|
|`date()`|Return date|
|`time()`|Return time|
|`datetime()`|Return date + time|
|`julianday()`|Julian day number|
|`unixepoch()`|Unix timestamp|
|`strftime()`|Format date/time|
|`timediff()`|Difference between times|

Examples:

```sql
SELECT date('now');
```

```sql
SELECT time('now');
```

```sql
SELECT datetime('now');
```

```sql
SELECT strftime('%Y', 'now');
```

---

# 6. NULL Functions

These are extremely useful in real SQL.

### `COALESCE()`

Returns the first non-NULL value.

```sql
SELECT COALESCE(nickname, 'Unknown')
FROM users;
```

Conceptually:

```text
nickname
────────
Alice
NULL
Bob
```

becomes:

```text
Alice
Unknown
Bob
```

---

### `NULLIF()`

Returns `NULL` if two values are equal.

```sql
SELECT NULLIF(score, 0)
FROM students;
```

Useful for avoiding things such as division by zero.

---

# 7. Type Functions

### `typeof()`

Tells you SQLite's runtime storage type.

```sql
SELECT typeof(age)
FROM users;
```

Possible results:

```text
integer
real
text
blob
null
```

This is particularly useful when you're learning SQLite because SQLite uses **dynamic typing**.

---

### `quote()`

Converts a value into an SQL literal.

```sql
SELECT quote(name)
FROM users;
```

---

# 8. JSON Functions

Modern SQLite can have JSON functionality through its JSON support.

Important functions include:

|Function|Purpose|
|---|---|
|`json()`|Validate/normalize JSON|
|`json_object()`|Create JSON object|
|`json_array()`|Create JSON array|
|`json_extract()`|Extract JSON value|
|`json_type()`|Get JSON type|
|`json_valid()`|Check whether JSON is valid|
|`json_set()`|Modify JSON|
|`json_insert()`|Insert into JSON|
|`json_remove()`|Remove JSON element|
|`json_array_length()`|Get JSON array length|

Example:

```sql
SELECT json_object(
    'title', title,
    'year', year
)
FROM longlist;
```

---

# 9. Conditional Functions

### `iif()`

SQLite's shorthand conditional function.

```sql
SELECT
    name,
    iif(score >= 50, 'Pass', 'Fail')
FROM students;
```

Conceptually:

```text
score >= 50
    │
   YES → Pass
    │
    NO → Fail
```

You will also frequently use the SQL `CASE` expression:

```sql
SELECT
    name,
    CASE
        WHEN score >= 90 THEN 'A'
        WHEN score >= 80 THEN 'B'
        WHEN score >= 70 THEN 'C'
        ELSE 'F'
    END AS grade
FROM students;
```

`CASE` is **not technically a function**, but you absolutely should learn it alongside these functions.

---

# 10. Random / Utility Functions

### `random()`

Generates a pseudo-random integer.

```sql
SELECT random();
```

### `randomblob()`

Generates a random BLOB.

```sql
SELECT randomblob(16);
```

### `last_insert_rowid()`

Returns the row ID from the most recent successful `INSERT`.

```sql
SELECT last_insert_rowid();
```

Very useful when working with automatically generated IDs.

---

# The ones I'd learn FIRST

Don't try to memorize the entire SQLite function library. For **CS50 SQL**, I'd learn them in this order:

### Level 1 — essential

```text
COUNT()
SUM()
AVG()
MIN()
MAX()

LENGTH()
LOWER()
UPPER()
SUBSTR()
REPLACE()

ROUND()

COALESCE()
NULLIF()

ROW_NUMBER()
```

### Level 2 — very useful

```text
RANK()
DENSE_RANK()
LAG()
LEAD()

CASE
typeof()

DATE()
TIME()
DATETIME()
strftime()
```

### Level 3 — specialized

```text
GROUP_CONCAT()

JSON functions
Math/trigonometric functions
random()
randomblob()
```

---

## One important distinction

Don't confuse **functions** with **SQLite shell commands**.

You just learned:

```sql
ROW_NUMBER()
```

That's an **SQL function**.

But:

```text
.mode box
.headers on
.tables
.schema
.databases
.quit
```

are **SQLite CLI commands**.

So your SQLite knowledge is really:

```text
SQLite
│
├── SQL
│   ├── SELECT
│   ├── INSERT
│   ├── UPDATE
│   ├── DELETE
│   ├── JOIN
│   ├── WHERE
│   ├── GROUP BY
│   ├── ORDER BY
│   └── Functions
│       ├── COUNT()
│       ├── AVG()
│       ├── LENGTH()
│       ├── ROW_NUMBER()
│       └── ...
│
└── SQLite CLI
    ├── .mode
    ├── .headers
    ├── .tables
    ├── .schema
    ├── .databases
    ├── .open
    ├── .import
    ├── .dump
    └── .quit
```

That's the distinction I recommend keeping very clear while you're going through CS50.

[[1 - WHAT IS SQLITE3 🍕]]