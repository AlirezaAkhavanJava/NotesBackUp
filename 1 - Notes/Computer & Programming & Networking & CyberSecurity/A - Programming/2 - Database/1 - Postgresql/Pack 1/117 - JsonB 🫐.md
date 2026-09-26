# **Mastering JSONB in PostgreSQL**  
*A Complete, In-Depth Tutorial to Become a JSONB Pro*

In PostgreSQL, **`JSONB`** stands for **JSON Binary** — it’s a data type that stores JSON data in a **binary (parsed and indexed)** form for **fast querying**.

- `JSON` → stores raw text (slower to query).
    
- `JSONB` → stores parsed binary (faster, smaller, searchable).
    

So `JSONB` = better version of `JSON`.

---

## **1. What is JSONB? (Deep Dive)**

| Feature | JSON | JSONB |
|--------|------|-------|
| **Storage Format** | Raw UTF-8 text | Decomposed binary format |
| **Parsing** | Parsed on every read | Parsed once on insert |
| **Query Speed** | Slow (re-parsing) | Fast (pre-parsed) |
| **Size on Disk** | Larger | ~10–15% smaller |
| **Key Order** | Preserved | **Not preserved** |
| **Duplicate Keys** | Allowed | Last one wins |
| **Indexing** | Not supported | Full GIN & BTREE support |

> **Bottom line**: Use **JSONB** 99% of the time unless you need to preserve key order or duplicates.

---

## **2. Creating Tables with JSONB**

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  data JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Best Practices:
- Always use `JSONB`, never `JSON` unless required.
- Set `DEFAULT '{}'` to avoid `NULL` issues.
- Use `NOT NULL` if your app logic depends on it.

---

## **3. Inserting & Updating JSONB**

### Basic Insert
```sql
INSERT INTO products (data) VALUES
('{"name": "Laptop", "price": 999, "tags": ["electronics", "portable"]}'),
('{"name": "Mouse", "price": 25, "in_stock": true, "tags": []}');
```

### Insert with Nested Objects & Arrays
```sql
INSERT INTO events (payload) VALUES
('{
  "user_id": 42,
  "action": "login",
  "metadata": {
    "ip": "192.168.1.1",
    "user_agent": "Mozilla/5.0...",
    "location": {"city": "Baku", "country": "AZ"}
  },
  "tags": ["auth", "success"]
}');
```

---

## **4. Querying JSONB – All Operators Explained**

| Operator | Meaning | Example | Result |
|--------|-------|--------|--------|
| `->` | Get JSON **object** by key | `data->'name'` | `{"name": "Laptop"}` → JSON |
| `->>` | Get **text** value by key | `data->>'name'` | `"Laptop"` → text |
| `#>` | Get nested object by **path** | `payload#>'{metadata,ip}'` | `"192.168.1.1"` |
| `#>>` | Get nested **text** by path | `payload#>>'{metadata,location,city}'` | `"Baku"` |
| `@>` | **Contains** (left ⊇ right) | `data @> '{"in_stock": true}'` | Rows where `in_stock = true` |
| `<@` | **Contained by** (left ⊆ right) | `data <@ '{"tags": ["electronics"]}'` | Tags include electronics |
| `?` | Key exists | `data ? 'price'` | `true` if `price` key exists |
| `?|` | Any of these keys exist | `data ?| '{name,price}'` | `true` if name OR price exists |
| `?&` | All of these keys exist | `data ?& '{name,price}'` | `true` if both exist |
| `||` | Concatenate JSONB | `data || '{"sale": true}'` | Merges objects |
| `-` | Delete key | `data - 'tags'` | Removes `tags` |
| `#-` | Delete by path | `data #- '{metadata,ip}'` | Removes nested `ip` |
| `@?` | JSONPath exists (PG 12+) | `data @? '$.price'` | `true` if price exists |
| `@@` | JSONPath query (PG 12+) | `data @@ '$.price > 50'` | Matches price > 50 |

---

### **Real Query Examples**

#### 1. Get all product names and prices
```sql
SELECT 
  data->>'name' AS name,
  (data->>'price')::INT AS price
FROM products;
```

#### 2. Find users from Baku
```sql
SELECT * FROM events 
WHERE payload#>>'{metadata,location,city}' = 'Baku';
```

#### 3. Find products with tag "electronics"
```sql
SELECT * FROM products 
WHERE data @> '{"tags": ["electronics"]}';
```

#### 4. Find products cheaper than $100
```sql
SELECT * FROM products 
WHERE (data->>'price')::INT < 100;
```

#### 5. Find events with both "auth" and "success" tags
```sql
SELECT * FROM events 
WHERE payload @> '{"tags": ["auth", "success"]}';
```

---

## **5. Indexing JSONB – Make It Blazing Fast**

### **GIN Index (Most Important!)**

```sql
-- Index entire JSONB column (for @>, ? , etc.)
CREATE INDEX idx_products_data_gin ON products USING GIN (data);

-- Index specific keys (expression index)
CREATE INDEX idx_products_price ON products USING BTREE ((data->>'price')::INT);
CREATE INDEX idx_products_name ON products USING BTREE (data->>'name');
```

### When to use which?

| Use Case | Index Type |
|--------|------------|
| `@>`, `?`, `?&`, `?|` | `GIN` on whole column |
| Filter by specific field (e.g. price > 100) | `BTREE` on expression |
| Full-text search in JSON | `GIN` with `jsonb_path_ops` |

```sql
-- Optimized for @> containment
CREATE INDEX idx_products_data_gin ON products USING GIN (data jsonb_path_ops);
```

> Use `jsonb_path_ops` when you **only** use `@>` — slightly smaller & faster.

---

## **6. Advanced JSONB Functions**

| Function | Purpose | Example |
|--------|--------|--------|
| `jsonb_build_object()` | Build JSON dynamically | `jsonb_build_object('status', 'ok', 'count', 5)` |
| `jsonb_build_array()` | Build array | `jsonb_build_array('a', 1, true)` |
| `jsonb_set()` | Update nested value | `jsonb_set(data, '{price}', '899')` |
| `jsonb_insert()` | Insert into array/object | `jsonb_insert(data, '{tags,0}', '"new"')` |
| `jsonb_array_elements()` | Unnest array | Expand `skills` into rows |
| `jsonb_object_keys()` | Get all keys | List all top-level keys |

### Example: Update price
```sql
UPDATE products 
SET data = jsonb_set(data, '{price}', '899')
WHERE data->>'name' = 'Laptop';
```

### Example: Add a new tag
```sql
UPDATE products 
SET data = jsonb_set(
  data, 
  '{tags}', 
  (data->'tags') || '"promo"'
)
WHERE data->>'name' = 'Mouse';
```

### Example: Unnest skills
```sql
SELECT 
  info->>'name' AS user_name,
  skill.value AS skill
FROM users, 
jsonb_array_elements(info->'skills') AS skill;
```

---

## **7. JSONPath (PostgreSQL 12+) – SQL/JSON Standard**

```sql
-- Find products where price > 500
SELECT * FROM products 
WHERE data @@ '$.price > 500';

-- Find objects with "electronics" in tags array
SELECT * FROM products 
WHERE data @@ '$.tags[*] == "electronics"';

-- Complex: price between 100 and 1000 AND in_stock = true
SELECT * FROM products 
WHERE data @@ '$.price >= 100 && $.price <= 1000 && $.in_stock == true';
```

> JSONPath is **not indexed by default** → use with `GIN` + expressions for performance.

---

## **8. Performance Tips & Best Practices**

| Tip | Why |
|-----|-----|
| **Always use JSONB** | Faster, indexable, smaller |
| **Avoid selecting full JSONB** | Use `->>` to extract only needed fields |
| **Index frequently queried keys** | `(data->>'status')`, `(data->>'user_id')` |
| **Use `jsonb_set` + `||` for updates** | Immutable → safe for concurrency |
| **Partition large JSONB tables** | By date, tenant, etc. |
| **Use `COALESCE(data->>'field', 'default')`** | Handle missing keys safely |

---

## **9. Common Patterns & Real-World Use Cases**

### 1. **User Profiles (Flexible Schema)**
```sql
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY,
  profile JSONB DEFAULT '{}'
);

-- Add phone later? No schema change!
UPDATE user_profiles 
SET profile = profile || '{"phone": "+994501234567"}'
WHERE user_id = 'abc123';
```

### 2. **Event Tracking / Analytics**
```sql
INSERT INTO events (payload) VALUES (
  jsonb_build_object(
    'event', 'page_view',
    'url', '/products/123',
    'user_id', 42,
    'session', 'xyz',
    'timestamp', NOW()
  )
);
```

### 3. **E-commerce Product Catalog**
```sql
-- Search by category, price range, tags
SELECT * FROM products 
WHERE data @> '{"category": "laptops"}'
  AND (data->>'price')::INT BETWEEN 500 AND 2000
  AND data ? 'in_stock';
```

---

## **10. Debugging & Inspection**

```sql
-- Pretty print JSONB
SELECT jsonb_pretty(data) FROM products LIMIT 1;

-- See all keys in a column
SELECT DISTINCT jsonb_object_keys(data) FROM products;

-- Count how many have a field
SELECT COUNT(*) FROM products WHERE data ? 'discount';
```

---

## **11. Migration: JSON → JSONB**

```sql
-- Convert column
ALTER TABLE users ALTER COLUMN info TYPE JSONB USING info::JSONB;

-- Or create new column
ALTER TABLE users ADD COLUMN info_b JSONB;
UPDATE users SET info_b = info::JSONB;
ALTER TABLE users DROP COLUMN info;
ALTER TABLE users RENAME COLUMN info_b TO info;
```

---

## **12. JSONB vs Document DBs (MongoDB, etc.)**

| Feature | PostgreSQL JSONB | MongoDB |
|--------|------------------|--------|
| ACID Transactions | Yes | Yes (multi-doc) |
| SQL + Joins | Yes | Limited |
| Indexing | Full GIN/BTREE | Yes |
| Schema Flexibility | Yes | Yes |
| Best for | Mixed relational + flexible data | Pure document apps |

> **Use JSONB when you already use PostgreSQL and need flexibility without losing SQL power.**

---

## **Final Checklist: Are You a JSONB Master?**

- [ ] You always use `JSONB`, not `JSON`  
- [ ] You know `->` vs `->>` vs `#>` vs `#>>`  
- [ ] You use `GIN` indexes on JSONB columns  
- [ ] You use `jsonb_set`, `||`, `-` for updates  
- [ ] You extract fields in `SELECT`, not full JSON  
- [ ] You use JSONPath for complex queries  
- [ ] You handle missing keys with `COALESCE` or `?`  
- [ ] You’ve built at least one real app with JSONB  

---

## **Mini Project: Build a Todo API Backend**

```sql
CREATE TABLE todos (
  id SERIAL PRIMARY KEY,
  data JSONB DEFAULT '{
    "title": "", 
    "completed": false, 
    "tags": [], 
    "due_date": null
  }'
);

CREATE INDEX idx_todos_gin ON todos USING GIN (data);
CREATE INDEX idx_todos_completed ON todos ((data->>'completed'));
```

```sql
-- Get incomplete todos due today
SELECT * FROM todos 
WHERE data->>'completed' = 'false'
  AND data->>'due_date' = CURRENT_DATE::TEXT;
```

---

## **Resources**

- [Official Docs: JSON Types](https://www.postgresql.org/docs/current/datatype-json.html)
- [JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [Use The Index, Luke! – JSONB](https://use-the-index-luke.com/sql/where-clause/json)

---


##### Tags : [[1 - SQL 🦬]]