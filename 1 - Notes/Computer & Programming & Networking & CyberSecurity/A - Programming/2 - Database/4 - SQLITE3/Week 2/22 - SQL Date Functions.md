




### 1. `CURRENT_TIMESTAMP`

Returns the current date and time in **UTC**.

```sql
SELECT CURRENT_TIMESTAMP;
```

Example:

```text
2026-09-21 11:52:30
```

It is commonly used with `DEFAULT`:

```sql
created_at TEXT DEFAULT CURRENT_TIMESTAMP
```

---

### 2. `CURRENT_DATE`

Returns the current **UTC date**.

```sql
SELECT CURRENT_DATE;
```

```text
2026-09-21
```

---

### 3. `CURRENT_TIME`

Returns the current **UTC time**.

```sql
SELECT CURRENT_TIME;
```

```text
11:52:30
```

So these three form a useful group:

```text
CURRENT_DATE       → YYYY-MM-DD
CURRENT_TIME       → HH:MM:SS
CURRENT_TIMESTAMP  → YYYY-MM-DD HH:MM:SS
```

---

# SQLite Date/Time Functions

SQLite also provides:

### `date()`

Returns a date.

```sql
SELECT date('now');
```

### `time()`

Returns a time.

```sql
SELECT time('now');
```

### `datetime()`

Returns date + time.

```sql
SELECT datetime('now');
```

### `julianday()`

Returns a **Julian day number**, useful for date calculations.

```sql
SELECT julianday('2026-09-21');
```

### `unixepoch()`

Returns Unix time — seconds since:

```text
1970-01-01 00:00:00 UTC
```

```sql
SELECT unixepoch();
```

### `strftime()`

Formats/extracts parts of a date/time.

```sql
SELECT strftime('%Y-%m-%d', 'now');
```

---

## With `DEFAULT`

You will commonly see:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

SQLite's built-in date/time functionality is especially useful for **auditing fields**:

```sql
created_at
updated_at
deleted_at
```

One important detail: **`CURRENT_TIMESTAMP` is UTC**, not your machine's local timezone.


[[1 - SQL 🥞]]