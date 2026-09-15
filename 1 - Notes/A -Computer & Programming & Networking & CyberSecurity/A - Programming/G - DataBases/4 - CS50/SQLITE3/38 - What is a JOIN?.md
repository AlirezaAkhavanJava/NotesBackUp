
A **JOIN** is a SQL operation that combines rows from two or more tables into a single result set, based on a related column between them — almost always a **foreign key** matching a **primary key**. Instead of running separate queries and stitching results together yourself, a JOIN merges the data at the database level, in one pass.

```sql
SELECT movies.title, people.name
FROM stars
JOIN movies ON movies.id = stars.movie_id
JOIN people ON people.id = stars.person_id;
```

## What problem it solves

Recall why we normalize data — splitting it into `movies`, `people`, `stars` instead of one giant flat table. That avoids duplication, but creates a new problem: **the information you want is now scattered across multiple tables.** A single row in `stars` is meaningless on its own — it's just two numbers (`movie_id`, `person_id`). You can't answer "who starred in what" by looking at any _one_ table alone.

**JOIN solves this by reassembling the scattered data back into one meaningful view, on demand**, without ever duplicating storage. You get the benefits of normalization (no redundancy) _and_ the benefits of a flat table (everything visible together) — just computed at query time instead of stored that way.

## Types of JOINs in SQLite3

SQLite3 supports: `INNER JOIN`, `LEFT JOIN` (aka `LEFT OUTER JOIN`), `CROSS JOIN`, and — since SQLite 3.39 (2022) — `RIGHT JOIN` and `FULL OUTER JOIN`. Let's go through each with the `movies` / `stars` / `people` schema.

---

### 1. INNER JOIN — "only matching rows on both sides"

Returns rows **only** where a match exists in _both_ tables. If a movie has no stars, it disappears entirely from the result.

```sql
SELECT movies.title, people.name
FROM movies
INNER JOIN stars ON stars.movie_id = movies.id
INNER JOIN people ON people.id = stars.person_id;
```

**Use when:** you only care about complete, matched pairs — e.g., "show me movies _that have_ stars, and who they are." Missing/unmatched data is irrelevant to your question.

Plain `JOIN` in SQLite3 defaults to `INNER JOIN` — they're identical.

---

### 2. LEFT JOIN — "everything from the left table, matched or not"

Returns **all** rows from the left (first) table, and matching rows from the right table. If there's no match, the right table's columns come back as `NULL`.

```sql
SELECT movies.title, ratings.rating
FROM movies
LEFT JOIN ratings ON ratings.movie_id = movies.id;
```

**Use when:** you want to keep every row from your main table even if related data is missing — e.g., "show every movie, and its rating if it has one, or NULL if not." This is the go-to for finding **gaps** — movies with no rating at all:

```sql
SELECT movies.title
FROM movies
LEFT JOIN ratings ON ratings.movie_id = movies.id
WHERE ratings.movie_id IS NULL;
```

That last pattern — `LEFT JOIN ... WHERE right_table.col IS NULL` — is a genuinely important professional idiom: it's how you find "orphans," i.e., rows with no relationship on the other side.

---

### 3. CROSS JOIN — "every combination of every row"

Returns the **Cartesian product** — every row from table A paired with every row from table B, with no matching condition at all.

```sql
SELECT movies.title, people.name
FROM movies
CROSS JOIN people;
```

If `movies` has 1,000 rows and `people` has 5,000, you get 5,000,000 rows. **Rarely useful directly** — mostly seen in generating combinations (e.g., a scheduling grid of every room × every timeslot), or as an accidental bug when someone forgets an `ON` condition on a regular JOIN.

⚠️ **Professional warning:** an accidental cross join (forgetting the `ON` clause, or using a comma-join without a `WHERE`) is one of the most common real-world SQL performance bugs — it can silently generate millions of rows.

---

### 4. RIGHT JOIN — mirror of LEFT JOIN (SQLite 3.39+)

All rows from the right table, matched or not.

```sql
SELECT movies.title, ratings.rating
FROM ratings
RIGHT JOIN movies ON ratings.movie_id = movies.id;
```

**Professional note:** rarely used in practice — almost anything written as a `RIGHT JOIN` can be rewritten as a `LEFT JOIN` by swapping table order, which is more conventional and more readable to most SQL developers. Prefer `LEFT JOIN` and reorder your tables instead.

---

### 5. FULL OUTER JOIN — everything from both sides (SQLite 3.39+)

All rows from both tables — matched where possible, `NULL` on whichever side has no match.

```sql
SELECT movies.title, ratings.rating
FROM movies
FULL OUTER JOIN ratings ON ratings.movie_id = movies.id;
```

**Use when:** you need a complete picture from both directions at once — e.g., "show me all movies and all ratings, flagging anything unmatched on either side." Less common day-to-day, but useful for data audits/reconciliation.

---

## How to use JOINs professionally — best practices

**1. Always qualify column names once you have 2+ tables**

```sql
-- Ambiguous, error-prone
SELECT title, name FROM movies JOIN people ...

-- Professional: always prefix
SELECT movies.title, people.name FROM movies JOIN people ...
```

**2. Use table aliases for readability on longer queries**

```sql
SELECT m.title, p.name
FROM movies AS m
JOIN stars AS s ON s.movie_id = m.id
JOIN people AS p ON p.id = s.person_id;
```

**3. Always specify the `ON` condition explicitly — never rely on implicit comma joins**

```sql
-- Avoid (old style, easy to accidentally cross-join)
SELECT * FROM movies, stars WHERE movies.id = stars.movie_id;

-- Correct modern style
SELECT * FROM movies JOIN stars ON movies.id = stars.movie_id;
```

**4. Filter before joining when possible (performance)**  
Put restrictive `WHERE` conditions on indexed columns, and make sure foreign key columns are indexed — SQLite3 doesn't auto-index foreign keys.

```sql
CREATE INDEX idx_stars_movie ON stars(movie_id);
CREATE INDEX idx_stars_person ON stars(person_id);
```

**5. Choose INNER vs LEFT deliberately, don't default blindly**  
Ask: _"Do I want to potentially lose rows that have no match?"_ If no → `LEFT JOIN`. If missing matches are irrelevant to the question → `INNER JOIN`.

**6. Chain joins in logical relationship order**  
When crossing a many-to-many relationship, join through the bridge table in the natural path: `movies → stars → people`, not out of order — it keeps the query readable and matches your mental model of the schema.

## Quick reference table

|JOIN type|Keeps unmatched rows from...|Common use|
|---|---|---|
|`INNER JOIN`|Neither side|Only show fully matched relationships|
|`LEFT JOIN`|Left table|Keep all of table A, show NULLs for missing matches; find orphans|
|`RIGHT JOIN`|Right table|Rare — usually rewritten as LEFT JOIN with swapped order|
|`CROSS JOIN`|N/A (no matching)|Generate all combinations — rare, often accidental|
|`FULL OUTER JOIN`|Both sides|Data reconciliation/audits|

## Practice exercise

Try writing: **"List every person, and the title of a movie they starred in — including people who have never starred in any movie (should show NULL for title)."**

Think about which JOIN type that requires before you write it — that's the real skill here. Want to give it a shot and I'll check your answer?


[[1 - WHAT IS SQLITE3]]