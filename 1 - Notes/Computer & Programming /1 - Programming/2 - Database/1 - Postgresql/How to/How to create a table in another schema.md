

### 🔹 Option 1: Fully qualify the schema in the CREATE statement

```sql
CREATE TABLE test.my_table (
    id SERIAL PRIMARY KEY,
    name TEXT
);
```

✅ This **directly creates** the table inside the `test` schema — no matter what your `search_path` is.

---

### 🔹 Option 2: Set your session to that schema first

```sql
SET search_path TO test;
CREATE TABLE my_table (
    id SERIAL PRIMARY KEY,
    name TEXT
);
```

✅ Now `my_table` will be created in `test`.

---

⚠️ If the schema doesn’t exist yet, create it first:

```sql
CREATE SCHEMA test;
```



Once your table is in a specific schema, you can query it in **two ways**:


### 🔹 Option 1: Fully qualify the schema in the query

```sql
SELECT * FROM test.my_table;
```

This works regardless of your current `search_path`.

---

### 🔹 Option 2: Set the schema in your session first

```sql
SET search_path TO test;

SELECT * FROM my_table;
```

Now you can just use the table name without the schema.

---

✅ **Tip:** You can check which schema is currently in use with:

```sql
SHOW search_path;
```



##### Tags : [[1 - SQL 🦬]]