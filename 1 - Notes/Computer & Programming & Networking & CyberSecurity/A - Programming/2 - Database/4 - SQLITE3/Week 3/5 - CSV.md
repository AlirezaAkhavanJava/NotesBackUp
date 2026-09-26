 Let's understand **what SQLite is actually doing when you import a CSV**, rather than just memorizing `.import`.

## 1. First: what is a CSV?

CSV = **Comma-Separated Values**.

Example:

```csv
id,title,accession_number,acquired
1,Ancient Coins,ACC-001,2024
2,Medieval Books,ACC-002,2023
3,Paintings,ACC-003,2025
```

Conceptually, it's just a text file containing rows and columns:

```text
          column
             ↓
1 | Ancient Coins | ACC-001 | 2024
2 | Medieval Books| ACC-002 | 2023
3 | Paintings     | ACC-003 | 2025
↑
row
```

The important thing:

**A CSV file does not contain SQLite tables.**

It's just text.

---

# 2. SQLite has to parse that text

Suppose you already have:

```sql
CREATE TABLE collections(
    id INTEGER,
    title TEXT NOT NULL,
    accession_number TEXT NOT NULL UNIQUE,
    acquired NUMERIC,
    PRIMARY KEY(id)
);
```

SQLite knows:

```text
collections
├── id
├── title
├── accession_number
└── acquired
```

But the CSV is just:

```text
1,Ancient Coins,ACC-001,2024
```

So the SQLite CLI reads the line and splits it according to the CSV format:

```text
1
Ancient Coins
ACC-001
2024
```

Then it associates them with the table columns **by position**:

```text
CSV field 1 → id
CSV field 2 → title
CSV field 3 → accession_number
CSV field 4 → acquired
```

That's the fundamental idea behind `.import`.

---

# 3. `.import` is a SQLite CLI command

This is important.

When you type:

```sql
.import collections.csv collections
```

`.import` is **not SQL**.

It's a command understood by the `sqlite3` command-line program.

Compare:

```sql
SELECT * FROM collections;
```

This is SQL.

Whereas:

```text
.mode csv
.import collections.csv collections
```

are commands for the SQLite shell.

---

# 4. Why `.mode csv`?

SQLite's shell can read data in different formats.

For example:

```text
.mode column
```

might display:

```text
id  title
--  ----------------
1   Ancient Coins
2   Medieval Books
```

But CSV mode tells SQLite:

> "Interpret incoming data as CSV."

So:

```sql
.mode csv
```

changes how the shell handles CSV-formatted input/output.

---

# 5. Now let's import

Imagine `collections.csv` contains:

```csv
id,title,accession_number,acquired
1,Ancient Coins,ACC-001,2024
2,Medieval Books,ACC-002,2023
3,Paintings,ACC-003,2025
```

Start SQLite:

```bash
sqlite3 museum.db
```

Then:

```sql
.mode csv
.import --skip 1 collections.csv collections
```

The important part is:

```text
--skip 1
```

Why?

Because the first line isn't actual data.

It's the header:

```text
id,title,accession_number,acquired
```

So:

```text
--skip 1
```

means:

> Skip the first line.

Without it, SQLite would try to import:

```text
id
title
accession_number
acquired
```

as an actual row.

---

# 6. What actually happens internally?

Think of the operation like this:

```text
collections.csv
       │
       ▼
┌─────────────────────┐
│ SQLite CSV parser   │
└──────────┬──────────┘
           │
           ▼
      fields separated
           │
           ▼
┌─────────────────────────────┐
│ 1 │ Ancient Coins │ ACC-001│ 2024
└─────────────────────────────┘
           │
           ▼
       INSERT into
       collections
```

Conceptually, SQLite is doing something similar to:

```sql
INSERT INTO collections
VALUES (1, 'Ancient Coins', 'ACC-001', 2024);
```

Then:

```sql
INSERT INTO collections
VALUES (2, 'Medieval Books', 'ACC-002', 2023);
```

and so on.

The CLI handles this for you.

---

# 7. Column order matters

This is one of the most important things to understand.

Suppose your table is:

```sql
id
title
accession_number
acquired
```

and your CSV is:

```csv
1,Ancient Coins,ACC-001,2024
```

Everything matches.

But suppose your CSV is:

```csv
Ancient Coins,1,2024,ACC-001
```

SQLite doesn't magically know that the first value is supposed to be `title`.

It effectively sees:

```text
id                 = Ancient Coins
title              = 1
accession_number   = 2024
acquired           = ACC-001
```

which is wrong.

So the basic `.import` workflow assumes the CSV's fields correspond to the target table **in the expected order**.

---

# 8. What about types?

Your table says:

```sql
id INTEGER
title TEXT
accession_number TEXT
acquired NUMERIC
```

CSV itself doesn't really enforce those types.

For example:

```csv
1,Ancient Coins,ACC-001,2024
```

is just text in the file.

SQLite then applies its type rules when inserting the values.

That's why CSV is best thought of as:

> **serialized tabular text**, not a database.

---

# 9. What happens with constraints?

Your table has:

```sql
PRIMARY KEY(id)
```

and:

```sql
UNIQUE(accession_number)
```

So suppose your database already contains:

```text
1 | Ancient Coins | ACC-001 | 2024
```

and your CSV contains:

```csv
1,Another Collection,ACC-001,2025
```

The import tries to insert it.

But:

```text
id = 1
```

already exists.

And:

```text
accession_number = ACC-001
```

already exists.

So SQLite rejects the conflicting row.

This is one reason importing isn't simply "paste this text into the database."

The imported data still has to obey the table's schema and constraints.

---

# 10. The header is not automatically mapped to columns

This is a subtle but important point.

Consider:

```csv
title,id,acquired,accession_number
Ancient Coins,1,2024,ACC-001
```

You might think:

> "SQLite sees the names and knows what each value means."

The basic `.import` command does **not** work that way.

The header isn't being used as a magical mapping mechanism.

The values are fundamentally positional.

That's why the safer design for arbitrary CSV files is sometimes:

```text
CSV
 ↓
temporary/staging table
 ↓
explicit INSERT ... SELECT
 ↓
real table
```

For example:

```sql
CREATE TABLE staging(
    title TEXT,
    id INTEGER,
    acquired NUMERIC,
    accession_number TEXT
);
```

Import:

```sql
.mode csv
.import --skip 1 collections.csv staging
```

Then explicitly map:

```sql
INSERT INTO collections(id, title, accession_number, acquired)
SELECT
    id,
    title,
    accession_number,
    acquired
FROM staging;
```

Now **you control the mapping**.

---

# 11. Think of `.import` as a pipeline

This mental model is useful:

```text
CSV file
   │
   │  read text
   ▼
CSV parser
   │
   │  split into fields
   ▼
rows + columns
   │
   │  positional mapping
   ▼
SQLite table
   │
   │  constraints/type rules
   ▼
database records
```

So `.import` isn't some special CSV-to-database magic.

It's basically:

> **read rows from a text file and insert them into a SQLite table.**

---

# 12. The commands you should remember

For a normal CSV with a header:

```sql
.mode csv
.import --skip 1 collections.csv collections
```

Then verify:

```sql
SELECT * FROM collections;
```

Check the schema:

```sql
.schema collections
```

Check row count:

```sql
SELECT COUNT(*) FROM collections;
```

---

## The deeper distinction

There are actually **three different things** here:

```text
CSV
 ↓
file format

sqlite3 CLI
 ↓
program that understands commands such as .import

SQLite database
 ↓
actual structured storage with tables, indexes, constraints, etc.
```

That's the architecture you want to keep in your head.

**CSV is just the data source. `.import` is the transport mechanism. The SQLite table is the destination.**





[[1 - WHAT IS SQLITE3 🍕]]