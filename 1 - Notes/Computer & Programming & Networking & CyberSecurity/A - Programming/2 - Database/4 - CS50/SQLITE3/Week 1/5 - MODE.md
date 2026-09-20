In SQLite, **`.mode` is a SQLite CLI meta-command** that controls **how query results are formatted and displayed in your terminal**.

It does **not** change the database or the SQL query itself.

## `.mode` syntax

```text
.mode MODE [OPTIONS]
```

For example:

```sql
.mode table
```

means:

> "Display the results of future SQL queries using the `table` output format."

---

# Main `.mode` values

SQLite 3.46.1 supports these important modes:

|Mode|What it does|Example appearance|
|---|---|---|
|`list`|Values separated by a delimiter|`Alice|
|`csv`|CSV format|`"Alice",25,"Developer"`|
|`tabs`|Tab-separated values|`Alice 25 Developer`|
|`json`|JSON array/object output|`[{"name":"Alice","age":25}]`|
|`table`|ASCII table|`+-------+-----+`|
|`box`|Box-drawing table|`┌───────┬─────┐`|
|`column`|Aligned columns|`Alice 25 Developer`|
|`html`|HTML table|`<table>...</table>`|
|`markdown`|Markdown table|`\| name \| age \|`|
|`insert`|SQL `INSERT` statements|`INSERT INTO ...`|
|`quote`|SQL-quoted values|`'Alice','Developer'`|
|`ascii`|ASCII-separated output|Uses ASCII unit separators|
|`line`|One column per line|`name = Alice`|
|`explain`|Formatting intended for `EXPLAIN` output|Opcode-style columns|

The ones you'll use most while learning CS50 SQL are:

```text
.mode table
.mode box
.mode column
.mode list
.mode csv
.mode json
.mode markdown
```

---

# 1. `.mode table`

This is the classic database-table appearance.

```sql
.mode table
```

Then:

```sql
SELECT title, author
FROM longlist
LIMIT 3;
```

You'll get something approximately like:

```text
+----------------------+----------------+
|        title         |     author     |
+----------------------+----------------+
| Book One             | John Smith     |
| Book Two             | Jane Doe       |
| Book Three           | Bob Johnson    |
+----------------------+----------------+
```

Good for learning SQL because it makes the rows and columns obvious.

---

# 2. `.mode box`

This is a more modern-looking table.

```sql
.mode box
```

Example:

```text
┌──────────────────────┬───────────────┐
│        title         │    author     │
├──────────────────────┼───────────────┤
│ Book One             │ John Smith    │
│ Book Two             │ Jane Doe      │
│ Book Three           │ Bob Johnson   │
└──────────────────────┴───────────────┘
```

Personally, for your CS50 work, I'd use:

```sql
.mode box
.headers on
```

---

# 3. `.mode column`

This aligns values into columns.

```sql
.mode column
```

For example:

```text
title                 author
--------------------  -------------
Book One              John Smith
Book Two              Jane Doe
Book Three            Bob Johnson
```

This is useful, but it doesn't draw a table around the data.

---

# 4. `.mode list`

This is one of SQLite's simplest formats.

```sql
.mode list
```

You might see:

```text
Book One|John Smith
Book Two|Jane Doe
Book Three|Bob Johnson
```

The default separator is usually:

```text
|
```

You can change the separator with:

```sql
.separator ,
```

Then:

```sql
.mode list
```

could produce:

```text
Book One,John Smith
Book Two,Jane Doe
Book Three,Bob Johnson
```

---

# 5. `.mode csv`

Specifically formats the output as **CSV**.

```sql
.mode csv
```

Example:

```text
"Book One","John Smith"
"Book Two","Jane Doe"
"Book Three","Bob Johnson"
```

Useful when you want to send query results to another program such as Excel, Python, etc.

---

# 6. `.mode tabs`

Separates columns using tab characters.

```sql
.mode tabs
```

Conceptually:

```text
Book One    John Smith
Book Two    Jane Doe
Book Three  Bob Johnson
```

The spaces you see in the terminal are actually tab characters.

---

# 7. `.mode json`

Outputs query results as JSON.

```sql
.mode json
```

For:

```sql
SELECT title, author
FROM longlist
LIMIT 2;
```

you get something like:

```json
[
  {
    "title": "Book One",
    "author": "John Smith"
  },
  {
    "title": "Book Two",
    "author": "Jane Doe"
  }
]
```

Very useful when working with applications/APIs.

---

# 8. `.mode markdown`

Produces a Markdown table.

```sql
.mode markdown
```

Output:

```text
| title    | author     |
|----------|------------|
| Book One | John Smith |
| Book Two | Jane Doe   |
```

Useful if you're copying database results into GitHub README files, documentation, etc.

---

# 9. `.mode html`

Produces HTML table markup.

```sql
.mode html
```

Output is roughly:

```html
<tr><td>Book One</td><td>John Smith</td></tr>
<tr><td>Book Two</td><td>Jane Doe</td></tr>
```

Useful when SQLite output needs to be consumed by an HTML application.

---

# 10. `.mode line`

Instead of displaying data horizontally, SQLite displays **one column per line**.

```sql
.mode line
```

Example:

```text
title = Book One
author = John Smith
year = 2024

title = Book Two
author = Jane Doe
year = 2023
```

This is particularly useful when a row has many columns.

---

# `.mode` options

There are also modes that accept additional options.

For example:

```sql
.mode csv
```

can be combined with options related to quoting/formatting, while some modes can accept parameters controlling things such as separators.

You can see exactly what **your installed SQLite version** supports with:

```sql
.help .mode
```

That's important because SQLite CLI capabilities can differ slightly between versions.

You can also inspect your current CLI configuration with:

```sql
.show
```

---

# `.mode` vs `.headers`

This distinction is important.

`.mode` controls **the shape/style of the output**:

```sql
.mode table
```

while `.headers` controls whether the **column names** are displayed:

```sql
.headers on
```

So you can combine them:

```sql
.mode table
.headers on
```

Then:

```sql
SELECT title, author
FROM longlist
LIMIT 5;
```

gives you a proper table with:

```text
+----------------------+---------------+
|        title         |    author     |
+----------------------+---------------+
| ...                  | ...           |
| ...                  | ...           |
+----------------------+---------------+
```

---

## The important mental model

Think of SQLite's CLI as having **two layers**:

```text
             SQLite CLI
                 │
        ┌────────┴────────┐
        │                 │
      SQL             CLI commands
        │                 │
 SELECT ...           .mode table
 WHERE ...            .headers on
 JOIN ...             .separator ,
 INSERT ...           .output file
```

SQL commands operate on the **database**.

Commands beginning with `.` operate on **the SQLite command-line interface**.

So:

```sql
SELECT * FROM longlist;
```

is SQL.

But:

```text
.mode box
```

is **not SQL**. It's an instruction to the `sqlite3` program about how you want the results displayed.

### For your CS50 setup

I'd recommend starting each SQLite session with:

```text
.headers on
.mode box
```

Then your SQL:

```sql
SELECT *
FROM longlist
LIMIT 10;
```

That gives you a clean, readable database-console experience while you're learning.

[[1 - WHAT IS SQLITE3]]