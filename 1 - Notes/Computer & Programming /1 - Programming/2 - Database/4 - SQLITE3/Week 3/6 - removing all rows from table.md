
To remove **all rows** from a SQLite table:

```sql
DELETE FROM table_name;
```

For example:

```sql
DELETE FROM collections;
```

This removes every row but **keeps the table itself**:

```text
collections
├── id
├── title
├── accession_number
└── acquired
```

The schema, indexes, and constraints remain.

### Check before and after

```sql
SELECT COUNT(*) FROM collections;
```

Then:

```sql
DELETE FROM collections;
```

Then:

```sql
SELECT COUNT(*) FROM collections;
```

You should get:

```text
0
```

### `DELETE` vs `DROP`

These are very different:

```sql
DELETE FROM collections;
```

→ Removes the **rows**.

```sql
DROP TABLE collections;
```

→ Removes the **entire table**.

For your case, use `DELETE`.



[[1 - WHAT IS SQLITE3 🍕]]