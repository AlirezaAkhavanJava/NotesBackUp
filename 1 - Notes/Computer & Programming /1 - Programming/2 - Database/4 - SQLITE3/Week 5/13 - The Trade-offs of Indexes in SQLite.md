


An index is an optimization for **reading data**. The cost is that SQLite has to maintain another data structure alongside your table.

So the fundamental trade-off is:

```text
More indexes
    ↓
faster some reads
    +
more storage
    +
more write work
    +
more maintenance
```

The mistake is thinking:

> “Indexes make queries faster, therefore more indexes = faster database.”

That's not true.

---

## 1. The biggest cost: writes

Suppose you have:

```sql
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    director TEXT
);
```

And you create three indexes:

```sql
CREATE INDEX idx_title ON movies(title);
CREATE INDEX idx_year ON movies(year);
CREATE INDEX idx_director ON movies(director);
```

Now insert:

```sql
INSERT INTO movies(title, year, director)
VALUES ('Cars', 2006, 'John Lasseter');
```

SQLite doesn't just insert into `movies`.

Conceptually, it has to do:

```text
INSERT movie
     │
     ├── update table B-tree
     │
     ├── update idx_title
     │
     ├── update idx_year
     │
     └── update idx_director
```

So every additional relevant index creates additional work on writes.

The same principle applies to `UPDATE` and `DELETE`.

---

# 2. `UPDATE` can be especially interesting

Suppose:

```sql
CREATE INDEX idx_title ON movies(title);
```

Then:

```sql
UPDATE movies
SET title = 'Cars 2'
WHERE id = 10;
```

SQLite needs to update the indexed value.

Conceptually:

```text
old index entry:
"Cars" → row 10

        ↓ update

remove old entry
        ↓
add new entry

"Cars 2" → row 10
```

If you have several indexes involving columns being changed, several index structures may have to be updated.

So an index doesn't just affect `SELECT`.

It affects the entire **write path**.

---

# 3. Indexes consume disk space

Your table stores the actual rows:

```text
movies
 └── table B-tree
```

Every index is another B-tree:

```text
movies
 ├── table B-tree
 ├── title index
 ├── year index
 ├── director index
 └── ...
```

So:

```text
more indexes
      ↓
more database pages
      ↓
larger database file
```

For a tiny database this may not matter.

For millions of rows and many large indexes, it absolutely can.

And a composite index such as:

```sql
CREATE INDEX idx
ON movies(title, year, director);
```

is generally larger than:

```sql
CREATE INDEX idx
ON movies(title);
```

because each index entry has more key data.

---

# 4. Indexes can slow down `INSERT`

Imagine:

```text
1 table
+
0 indexes
```

versus:

```text
1 table
+
8 indexes
```

For every inserted row, SQLite has to maintain the relevant structures.

Conceptually:

```text
0 indexes:

INSERT
  ↓
table


8 indexes:

INSERT
  ↓
table
  ↓
index 1
index 2
index 3
index 4
index 5
index 6
index 7
index 8
```

The actual implementation is more sophisticated than this picture, but the principle is correct.

Therefore, if your application is **write-heavy**, unnecessary indexes can become expensive.

---

# 5. Indexes aren't always used

This is a very important trade-off.

Suppose you create:

```sql
CREATE INDEX idx_year
ON movies(year);
```

but your application almost never runs:

```sql
WHERE year = ?
```

Then you may be paying:

```text
storage
+
write overhead
+
maintenance
```

for almost no useful read benefit.

An unused index is often just **overhead**.

That's why index design should start with your **query workload**, not with:

> “This column looks important, let's index it.”

---

# 6. More indexes also give the query planner more choices

This sounds positive, and often it is.

Suppose:

```text
idx_title
idx_year
idx_director
idx_rating
idx_genre
```

A query might have several possible access paths.

SQLite's query planner has to determine which strategy is appropriate. SQLite's planner is cost-based and uses available information about the data and indexes when selecting a plan.

So indexes give the planner **more options**.

But that doesn't mean creating dozens of redundant indexes is beneficial.

The important distinction is:

```text
more useful choices
        ≠
more indexes
```

You want useful choices.

---

# 7. Redundant indexes are particularly wasteful

Suppose you have:

```sql
CREATE INDEX idx_title_year
ON movies(title, year);
```

and then also:

```sql
CREATE INDEX idx_title
ON movies(title);
```

You may not need both.

Because the composite index starts with:

```text
title
```

it can often support queries that only constrain `title`.

Conceptually:

```text
(title, year)
   ↑
leftmost part can support title lookups
```

SQLite's query-planner documentation discusses this leftmost-column behavior and recommends avoiding indexes where one index is a prefix of another in cases where the longer index can serve the same purpose.

So having both:

```text
(title)
(title, year)
```

can mean you're maintaining two structures where one may be enough.

This is called **redundant indexing**.

---

# 8. But removing an index requires care

Consider:

```text
idx_title
idx_title_year
```

It is tempting to say:

> “`idx_title_year` starts with title, so delete `idx_title`.”

Often that is reasonable.

But you need to consider the actual workload.

Why?

Because the smaller index:

```text
(title)
```

can be cheaper to scan and maintain than:

```text
(title, year)
```

and might be useful for certain queries.

So the professional approach isn't:

```text
"Composite index exists → smaller index is always useless."
```

It is:

```text
"Can the larger index satisfy the smaller index's workload,
and is the larger index an acceptable cost?"
```

---

# 9. Too many indexes can increase memory/cache pressure

SQLite reads database pages through its pager/cache machinery.

A larger database with many indexes means more pages that may be useful during execution.

You don't need to think:

> “SQLite loads every index into RAM.”

It doesn't.

But larger indexes mean a larger on-disk working set and potentially more pages involved in operations.

This matters much more as your database and workload grow.

---

# 10. There is also a subtle cost: indexes must stay consistent

An index is not a cache that can become stale.

If you have:

```text
movies
+
title_index
```

and insert:

```text
Cars
```

SQLite must keep the relationship correct:

```text
title_index
"Cars" → correct row
```

If you have ten indexes:

```text
movies
├── idx1
├── idx2
├── idx3
├── ...
└── idx10
```

all ten structures must remain consistent with the table.

That is part of the write cost.

---

# 11. So what does a "good" index strategy look like?

For a backend application, you generally want indexes around **real access patterns**.

For example:

```sql
SELECT *
FROM users
WHERE email = ?;
```

An index on:

```sql
CREATE INDEX idx_users_email
ON users(email);
```

makes sense if this is a frequent lookup.

But don't automatically index:

```text
name
age
country
created_at
updated_at
status
phone
address
...
```

just because every column _could_ theoretically be indexed.

Instead:

```text
important query
      ↓
identify filtering / joining / ordering
      ↓
design an index
      ↓
EXPLAIN QUERY PLAN
      ↓
benchmark
      ↓
keep or remove
```

---

# 12. There is a useful balance

Think about the two extremes.

### Almost no indexes

```text
Reads:   potentially slow
Writes:  cheap
Storage: low
```

### Huge number of indexes

```text
Reads:   potentially very fast for supported queries
Writes:  more expensive
Storage: higher
Maintenance: higher
```

The goal is somewhere in the middle:

```text
                  GOOD INDEX DESIGN

                    useful indexes
                         │
             ┌───────────┼───────────┐
             ↓           ↓           ↓
          faster       faster      faster
          reads        joins       ordering
             │
             └──────────────┐
                            ↓
                   acceptable write cost
```

---

# The most important trade-offs

|More indexes give you|But you pay with|
|---|---|
|Faster selective reads|Slower writes|
|Faster joins|More storage|
|Faster `ORDER BY` in some cases|More index maintenance|
|Possibility of covering indexes|Larger database|
|More choices for the planner|Potentially redundant indexes|

And one more thing: **indexes don't guarantee faster queries**. A poorly chosen index can be ignored by SQLite, and a query can sometimes legitimately be faster with a table scan.

---

## The senior-level way to think about indexes

Don't ask:

> “Should I index this column?”

Ask:

> “Given my application's read/write workload, what access paths do my important queries need, and what is the cost of maintaining those access paths?”

That's the mindset behind good database design.




[[SQlite]]