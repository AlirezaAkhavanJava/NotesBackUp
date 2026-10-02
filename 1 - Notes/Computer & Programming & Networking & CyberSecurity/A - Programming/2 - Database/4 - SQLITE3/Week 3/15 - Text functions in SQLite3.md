

## 1. The mental model

Think of a text value as a **row of numbered boxes**, one character per box, numbered from **1** (not 0). Text functions are tools that measure the row (`length`), cut a piece out (`substr`), find something in it (`instr`), swap pieces (`replace`), clean the ends (`trim`), or join rows together (`||`).

Two rules explain most of the surprises:

1. **Positions start at 1.**
2. **`NULL` is infectious.** Most text functions return `NULL` if an input is `NULL`, because "unknown" combined with anything is still unknown.

Try everything in the `sqlite3` shell. Debian 13 ships SQLite 3.46, so every function below is available. For readable output:

```sql
.headers on
.mode box
```

## 2. Measuring: `length(X)`

```sql
SELECT length('hello');        -- 5
SELECT length('héllo');        -- 5  (counts characters, not bytes)
SELECT length('');             -- 0
SELECT length(NULL);           -- NULL
```

For `TEXT` it counts characters. For a `BLOB` it counts bytes. For numbers, it counts the digits of their text form (`length(1234)` is 4).

## 3. Case: `upper(X)`, `lower(X)`

```sql
SELECT upper('Spring Boot');   -- SPRING BOOT
SELECT lower('Spring Boot');   -- spring boot
```

**Gotcha:** by default these only convert **ASCII** letters. `upper('é')` stays `é` unless SQLite was built with the ICU extension.

## 4. Cutting: `substr(X, start, length)`

```sql
SELECT substr('Spring Boot', 1, 6);   -- Spring   (start at 1, take 6)
SELECT substr('Spring Boot', 8);      -- Boot     (no length = to the end)
SELECT substr('Spring Boot', -4);     -- Boot     (negative = count from the right)
SELECT substr('Spring Boot', -4, 2);  -- Bo
```

`substring()` is an alias. A quirk: `substr('hello', 0, 3)` returns `'he'`, because position 0 is a phantom box before the first character that still "uses up" one unit of the length. Start at 1 and you avoid it.

## 5. Finding: `instr(X, Y)`

Returns the position of the first match, or **0** if not found:

```sql
SELECT instr('user@mail.org', '@');   -- 5
SELECT instr('user@mail.org', '#');   -- 0
```

`instr` and `substr` are a natural pair. This splits an email in two:

```sql
SELECT substr(e, 1, instr(e, '@') - 1) AS username,
       substr(e, instr(e, '@') + 1)    AS domain
FROM (SELECT 'user@mail.org' AS e);
-- user | mail.org
```

SQLite has no `split()` function, so this `instr` + `substr` pattern is how you do it.

## 6. Replacing: `replace(X, find, new)`

```sql
SELECT replace('2026-10-01', '-', '/');     -- 2026/10/01
SELECT replace('banana', 'a', '');          -- bnn   (replace with empty = delete)
```

It replaces **all** occurrences and is **case-sensitive**: `replace('Apple', 'a', 'x')` changes nothing, because `A` is not `a`.

## 7. Cleaning: `trim`, `ltrim`, `rtrim`

```sql
SELECT trim('   hi   ');          -- hi
SELECT ltrim('   hi   ');         -- 'hi   '  (left side only)
SELECT rtrim('   hi   ');         -- '   hi'  (right side only)
SELECT trim('xxhixx', 'x');       -- hi
SELECT trim('abcba', 'ab');       -- c
```

**The key detail:** the second argument is a **set of characters**, not a substring. `trim('abcba', 'ab')` strips any `a` or `b` from both ends until it hits `c`. With no second argument it trims **spaces only**, not tabs or newlines.

## 8. Joining: `||`, `concat`, `concat_ws`

```sql
SELECT 'Hello' || ' ' || 'World';        -- Hello World
SELECT 'a' || NULL;                       -- NULL   (infectious!)
SELECT concat('a', NULL, 'b');            -- ab     (skips NULLs)
SELECT concat_ws('-', 'a', NULL, 'b');    -- a-b    (separator first, skips NULLs)
```

Use `||` when you want `NULL` to propagate, and `concat`/`concat_ws` (added in 3.44) when missing values should just be ignored, such as building a full name from optional parts.

## 9. Formatting: `printf(fmt, ...)` / `format(...)`

It works like C's `printf`, and `format` is an identical alias.

```sql
SELECT printf('%05d', 42);                 -- 00042
SELECT printf('%.2f', 3.14159);            -- 3.14
SELECT printf('%-10s|', 'hi');             -- hi        |
SELECT printf('%s has %d items', 'cart', 3);   -- cart has 3 items
```

Since SQLite has no `lpad`/`rpad`, `printf` is how you pad.

## 10. Pattern matching: `LIKE` and `GLOB`

These are operators, not functions, but they are core to text work.

```sql
SELECT 'Alireza' LIKE 'ali%';     -- 1   (case-insensitive for ASCII)
SELECT 'Alireza' LIKE '_lireza';  -- 1   (_ = exactly one character)
SELECT 'Alireza' GLOB 'ali*';     -- 0   (GLOB is case-sensitive)
SELECT 'Alireza' GLOB 'Ali*';     -- 1
```

||wildcards|case|
|---|---|---|
|`LIKE`|`%` (any run), `_` (one char)|insensitive (ASCII)|
|`GLOB`|`*`, `?`, `[a-z]`|sensitive|

## 11. Inspecting: `hex`, `unicode`, `char`, `quote`

```sql
SELECT hex('A');           -- 41
SELECT unicode('A');       -- 65
SELECT char(72, 105);      -- Hi
SELECT quote('it''s');     -- 'it''s'   (SQL-literal form, handy for debugging)
SELECT typeof('abc');      -- text
```

## 12. Aggregating text: `group_concat`

```sql
CREATE TABLE tags (post INTEGER, tag TEXT);
INSERT INTO tags VALUES (1,'java'), (1,'spring'), (2,'sql');

SELECT post, group_concat(tag, ', ') AS all_tags
FROM tags GROUP BY post;
-- 1 | java, spring
-- 2 | sql
```

It collapses many rows into one string per group. The order inside the string isn't guaranteed unless you control it.

## 13. A realistic combined example

```sql
CREATE TABLE users (id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT);
INSERT INTO users VALUES
  (1, '  aLIREZA ', 'akhavan', 'Ali.Akhavan@Example.COM'),
  (2, 'sara',       'karimi',  'sara@mail.org');

SELECT
  -- clean + proper-case the name: "Alireza"
  upper(substr(trim(first_name), 1, 1)) || lower(substr(trim(first_name), 2)) AS first,
  -- normalized email
  lower(trim(email))                                                         AS email,
  -- domain part
  lower(substr(email, instr(email, '@') + 1))                                AS domain,
  -- zero-padded display id
  printf('USR-%04d', id)                                                     AS code
FROM users;
-- Alireza | ali.akhavan@example.com | example.com | USR-0001
-- Sara    | sara@mail.org           | mail.org     | USR-0002
```

Here `trim` cleans, `substr` + `upper`/`lower` build the proper case, `instr` finds the `@`, and `printf` pads. This clean-then-reshape pattern is the most common use of these functions.

**Counting occurrences** has no built-in function, but there is a classic trick: delete the character and see how much shorter the string gets.

```sql
SELECT length('banana') - length(replace('banana', 'a', ''));   -- 3
```

## 14. Gotchas and what's missing

1. **No `reverse()`, `left()`, `right()`, `lpad()`, `rpad()`, `split()`** in core SQLite. Use `substr`, `printf`, and `instr` instead.
2. **No regex by default.** `X REGEXP Y` is parsed, but it errors with "no such function: REGEXP" unless you register an implementation (Python's `sqlite3` module and some tools do).
3. **`upper`/`lower` and `LIKE` are ASCII-only for case folding.** `LIKE` won't match `É` with `é`.
4. **`NULL` propagation** in `||` and most functions. Wrap with `coalesce(col, '')` when it matters.
5. **Type affinity:** SQLite is flexibly typed, so `length(123)` and `'1' || 2` both work by converting to text silently.
6. **Case-insensitive comparison** doesn't need `lower()` on both sides: declare the column `TEXT COLLATE NOCASE`, or write `WHERE name = 'bob' COLLATE NOCASE`.
7. **Performance:** wrapping a column in a function (`WHERE lower(email) = ...`) stops a normal index on that column from being used. An expression index, `CREATE INDEX ON users(lower(email))`, fixes it.

## Quick reference

|Goal|Function|
|---|---|
|How long?|`length`|
|Change case|`upper`, `lower`|
|Cut a piece|`substr`|
|Where is it?|`instr`|
|Swap / delete|`replace`|
|Strip edges|`trim`, `ltrim`, `rtrim`|
|Join|`\|`, `concat`, `concat_ws`|
|Pad / format|`printf`|
|Match a pattern|`LIKE`, `GLOB`|
|Many rows → one string|`group_concat`|

A good exercise: given the string `'John Smith'`, extract the first name and last name separately using only `instr` and `substr`.




[[1 - WHAT IS SQLITE3 🍕]]