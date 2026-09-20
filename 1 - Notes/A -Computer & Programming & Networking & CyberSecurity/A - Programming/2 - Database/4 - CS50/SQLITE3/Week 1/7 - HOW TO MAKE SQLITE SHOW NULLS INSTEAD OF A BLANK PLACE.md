 SQLite’s CLI displays `NULL` as an empty field by default.

Use the `.nullvalue` shell command:

```sql
.nullvalue NULL
```

Then run your query again:

```sql
SELECT "title", "translator", "author"
FROM "longlist"
WHERE "translator" IS NULL;
```

You’ll get:

```text
┌─────────────────────────────────────────┬────────────┬───────────────────┐
│                  title                  │ translator │      author       │
├─────────────────────────────────────────┼────────────┼───────────────────┤
│ The Perfect Nine                        │ NULL       │ Ngũgĩ wa Thiong'o │
│ The Enlightenment of The Greengage Tree │ NULL       │ Shokoofeh Azar    │
└─────────────────────────────────────────┴────────────┴───────────────────┘
```

### Important distinction

`.nullvalue` is a **SQLite shell setting**, not SQL.

```sql
.nullvalue NULL
```

changes how the **SQLite CLI displays NULL values**.

You can also choose any text you want:

```sql
.nullvalue '<NULL>'
```

or:

```sql
.nullvalue N/A
```

To see the current setting:

```sql
.show
```

Look for:

```text
nullvalue: NULL
```


[[1 - WHAT IS SQLITE3]]