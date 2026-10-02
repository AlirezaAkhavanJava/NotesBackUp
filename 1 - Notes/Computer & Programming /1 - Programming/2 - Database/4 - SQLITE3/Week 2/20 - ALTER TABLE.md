

`ALTER TABLE` is used to **modify the structure of an existing table** without deleting and recreating the entire table.

SQLite supports a relatively small set of `ALTER TABLE` operations.

## Main kinds

### 1. Rename a table

```sql
ALTER TABLE users
RENAME TO customers;
```

Changes:

```text
users → customers
```

---

### 2. Rename a column

```sql
ALTER TABLE users
RENAME COLUMN username TO name;
```

Changes:

```text
username → name
```

---

### 3. Add a column

```sql
ALTER TABLE users
ADD COLUMN age INTEGER;
```

The existing table gets a new column:

```text
id | username | age
```

You can also specify constraints that SQLite allows for an added column:

```sql
ALTER TABLE users
ADD COLUMN country TEXT DEFAULT 'Germany';
```

---

### 4. Drop a column

Modern SQLite supports:

```sql
ALTER TABLE users
DROP COLUMN age;
```

This removes the column and its data.

There are restrictions on dropping a column—for example, you cannot simply drop a column if other schema objects depend on it in ways SQLite does not permit.

---

# SQLite's `ALTER TABLE` Summary

```text
ALTER TABLE
│
├── RENAME TO
│   └── Rename table
│
├── RENAME COLUMN
│   └── Rename column
│
├── ADD COLUMN
│   └── Add column
│
└── DROP COLUMN
    └── Remove column
```

### Important: SQLite does NOT have general `ALTER COLUMN`

For example, this is **not supported** as a general operation:

```sql
ALTER TABLE users
ALTER COLUMN age TYPE TEXT;
```

You also cannot generally modify an existing column's definition with syntax like:

```sql
ALTER TABLE users
MODIFY COLUMN age TEXT;
```

For more complicated structural changes—such as changing a column's datatype, removing/changing certain constraints, or restructuring relationships—the usual SQLite approach is:

```text
1. Create new table
2. Copy data
3. Drop old table
4. Rename new table
```

This is commonly called the **table-rebuild pattern**.


[[1 - SQL 🦬]]
[[1 - WHAT IS SQLITE3 🍕]]