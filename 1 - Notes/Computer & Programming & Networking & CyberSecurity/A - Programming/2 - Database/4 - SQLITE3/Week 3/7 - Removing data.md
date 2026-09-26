
In **SQLite3**, removing data depends on what exactly you want to remove.

### 1. Remove specific rows — `DELETE`

```sql
DELETE FROM collections
WHERE id = 5;
```

Removes the row whose `id` is `5`.

You can use any condition:

```sql
DELETE FROM collections
WHERE title = 'Books';
```

### 2. Remove multiple rows

```sql
DELETE FROM collections
WHERE acquired < 2020;
```

Every matching row is deleted.

### 3. Remove **all rows** but keep the table

```sql
DELETE FROM collections;
```

The table still exists, but it becomes empty.

### 4. Remove the entire table

```sql
DROP TABLE collections;
```

This removes the **table structure and all its data**.

### Mental model

```text
DELETE FROM table WHERE condition;
       │       │        │
       │       │        └── Which rows?
       │       └─────────── Which table?
       └─────────────────── Remove rows
```

So:

```sql
DELETE FROM collections WHERE id = 5;
```

means **"remove the row from `collections` where `id` equals 5."**

And:

```sql
DROP TABLE collections;
```

means **"destroy the `collections` table itself."**


[[1 - WHAT IS SQLITE3 🍕]]