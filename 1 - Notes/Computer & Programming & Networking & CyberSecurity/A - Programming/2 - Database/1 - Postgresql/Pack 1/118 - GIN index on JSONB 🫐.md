

### 🧠 **GIN Index on JSONB (PostgreSQL)**

**GIN** = _Generalized Inverted Index_  
It’s a special index type that makes **searching inside `JSONB` fields** fast.

---

### ⚙️ **1. Why it’s needed**

Normally, if you do:

```sql
SELECT * FROM users WHERE info @> '{"age": 25}';
```

PostgreSQL has to **scan every row** — slow for large tables.

A **GIN index** makes this search instant by indexing all JSONB keys and values.

---

### 🏗️ **2. Create a GIN Index**

```sql
CREATE INDEX idx_users_info ON users USING GIN (info);
```

✅ Works automatically for:

- `@>` (contains)
    
- `?` (key exists)
    
- `?|` (any key exists)
    
- `?&` (all keys exist)
    

---

### 🔍 **3. Example**

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  info JSONB
);

INSERT INTO users (info) VALUES
('{"name": "Ethan", "skills": ["Java", "Spring"], "age": 25}'),
('{"name": "Sara", "skills": ["Python"], "age": 30}');
```

Create index:

```sql
CREATE INDEX idx_users_info ON users USING GIN (info);
```

Now queries like:

```sql
SELECT * FROM users WHERE info @> '{"skills": ["Java"]}';
```

or

```sql
SELECT * FROM users WHERE info ? 'age';
```

will be **very fast**.

---

### 🧩 **4. Optional JSONB GIN Operators**

You can control how it indexes:

```sql
CREATE INDEX idx_users_info_ginjsonb ON users
USING GIN (info jsonb_path_ops);
```

- `jsonb_ops` → supports all operators (default).
    
- `jsonb_path_ops` → smaller, faster index, but supports only `@>`.
    

---

### ⚖️ **5. Summary**

|Feature|Description|
|---|---|
|Type|GIN (Generalized Inverted Index)|
|Works On|JSONB columns|
|Speed|Great for `@>`, `?`, `?|
|Index Methods|`jsonb_ops` (default) or `jsonb_path_ops`|
|Purpose|Query JSON data efficiently|

---

here’s a clear demo of **GIN index performance** on a JSONB column in PostgreSQL:

### 🧱 **1. Create a sample table**

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  info JSONB
);
```

---

### 🧩 **2. Insert sample data (10,000 rows)**

```sql
INSERT INTO users (info)
SELECT jsonb_build_object(
  'name', 'User' || i,
  'age', (random() * 50 + 20)::int,
  'city', (ARRAY['Baku','London','Tokyo','Berlin'])[floor(random()*4)+1]
)
FROM generate_series(1, 10000) AS s(i);
```

---

### 🕵️ **3. Query without index**

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE info @> '{"city": "Berlin"}';
```

You’ll see something like:

```
Seq Scan on users  (cost=0.00..450.00 rows=500 width=48)
Execution time: ~80–120 ms
```

➡️ PostgreSQL scans the **entire table** — slow for big data.

---

### ⚙️ **4. Add a GIN index**

```sql
CREATE INDEX idx_users_info_gin ON users USING GIN (info);
```

---

### ⚡ **5. Query again (with index)**

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE info @> '{"city": "Berlin"}';
```

Now you’ll see:

```
Bitmap Heap Scan on users  (cost=25.00..40.00 rows=500 width=48)
Execution time: ~1–3 ms
```

🚀 **Result:** query became **30–100× faster**, because GIN avoids scanning all rows.

---

### 🧠 **6. Recap**

|Step|Query Type|Time|Scan Type|
|---|---|---|---|
|Before index|`@>`|~100 ms|Seq Scan|
|After index|`@>`|~2 ms|Bitmap (GIN)|

##### Tags : [[1 - SQL 🦬]]