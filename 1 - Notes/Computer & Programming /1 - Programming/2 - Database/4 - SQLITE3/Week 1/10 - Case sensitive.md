In SQLite, **case sensitivity** means whether uppercase and lowercase letters are treated as different characters when comparing text.

### Case-sensitive

Case-sensitive means:

```text
'Java' ≠ 'java'
'JAVA' ≠ 'Java'
'Hello' ≠ 'hello'
```

The capitalization matters.

For example, with `GLOB`:

```sql
SELECT *
FROM longlist
WHERE author GLOB 'George*';
```

This matches `George Orwell`, but not `george orwell`.

---

### Case-insensitive

Case-insensitive means capitalization **doesn't matter**:

```text
'Java' = 'java'
'JAVA' = 'Java'
'Hello' = 'hello'
```

For example, SQLite's `LIKE` operator is **case-insensitive for ASCII characters by default**:

```sql
SELECT *
FROM longlist
WHERE author LIKE 'george%';
```

This can match:

```text
George Orwell
george orwell
GEORGE ORWELL
```

---

## Important SQLite difference

For normal ASCII English text, a useful rule is:

|Operator|Case behavior|
|---|---|
|`=`|Generally case-sensitive|
|`LIKE`|Case-insensitive by default|
|`GLOB`|Case-sensitive|
|`IN`|Follows normal `=` comparison behavior|
|`IS`|Case-sensitive for text|
|`IS NULL`|Not applicable to case|

For example:

```sql
WHERE author = 'George Orwell'
```

is different from:

```sql
WHERE author = 'george orwell'
```

But:

```sql
WHERE author LIKE 'george orwell'
```

will normally match `George Orwell` too.

### One important caveat

SQLite's default `LIKE` case-insensitivity is primarily for **ASCII characters** (`A-Z`). It does **not** provide full Unicode case folding.

So don't think of `LIKE` as "universally case-insensitive."

If you specifically want predictable case-insensitive comparison, a common approach is:

```sql
WHERE LOWER(author) = LOWER('George Orwell')
```

or, for a simple ASCII dataset:

```sql
WHERE LOWER(author) = 'george orwell'
```

**Mental model:**

```text
CASE-SENSITIVE
A ≠ a

CASE-INSENSITIVE
A = a
```

And in SQLite, remember the big three:

```text
=       → case-sensitive
LIKE    → case-insensitive (ASCII, by default)
GLOB    → case-sensitive
```

[[1 - WHAT IS SQLITE3 🍕]]