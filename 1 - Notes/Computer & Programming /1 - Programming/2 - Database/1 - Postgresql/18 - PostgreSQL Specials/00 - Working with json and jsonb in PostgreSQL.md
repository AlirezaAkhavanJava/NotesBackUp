

**JSON** (JavaScript Object Notation) is a text format for storing structured data as keys and values, like `{"name": "Ana", "age": 30}`. PostgreSQL lets you keep a whole JSON document inside a single column, and it gives you operators and functions to read, search, and change the data inside it. You get the flexibility of a document database without leaving your relational one.

PostgreSQL offers two JSON types: `json` and `jsonb`. They look the same when you read them, but they are stored differently, and that changes how fast and how powerful they are. In this lesson you will learn the difference, then use both types with each family of SQL commands: **DDL** (defining structure), **DML** (changing data), **DQL** (querying data), plus the "other" commands like indexes, transactions, and constraints.

---

## 1. `json` vs `jsonb`: the key difference

||`json`|`jsonb`|
|---|---|---|
|Storage|Exact copy of the text you inserted|Parsed into a binary format|
|Whitespace and key order|Kept|Not kept (keys get sorted)|
|Duplicate keys|Kept|Last one wins, others dropped|
|Insert speed|Slightly faster (no parsing)|Slightly slower (parses once)|
|Query speed|Slower (re-parses every time)|**Much faster**|
|Indexing|Not supported on the whole column|**GIN indexes supported**|
|Extra operators (`@>`, `?`)|No|**Yes**|

Let's see it in action:

```sql
SELECT '{"b": 1,   "a": 2, "a": 3}'::json;
-- {"b": 1,   "a": 2, "a": 3}

SELECT '{"b": 1,   "a": 2, "a": 3}'::jsonb;
-- {"a": 3, "b": 1}
```

- With `json`, you get your text back exactly as typed, spaces and duplicate key included.
- With `jsonb`, PostgreSQL cleans it up: keys sorted, duplicate `a` reduced to the last value.

**Use `jsonb` unless you have a special reason.** The only real reason to pick `json` is when you must preserve the exact original text (for audit or logging). Everything below uses `jsonb`, and most of it works on `json` too.

---

## 2. DDL: Data Definition Language

DDL commands define the _structure_ of your database: `CREATE`, `ALTER`, `DROP`.

### Creating a table with a JSON column

```sql
CREATE TABLE products (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       text NOT NULL,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb
);
```

Line by line:

- `attributes jsonb`: this column holds a JSON document.
- `NOT NULL`: the column can't be empty.
- `DEFAULT '{}'::jsonb`: if you don't provide a value, it becomes an empty JSON object. The `::jsonb` casts the text `'{}'` into the `jsonb` type.

### Adding a constraint to keep JSON clean

```sql
ALTER TABLE products
ADD CONSTRAINT attributes_is_object
CHECK (jsonb_typeof(attributes) = 'object');
```

- `jsonb_typeof(...)` returns the kind of JSON value: `object`, `array`, `string`, `number`, `boolean`, or `null`.
- This constraint rejects any row where `attributes` isn't a JSON object, so nobody can insert `[1,2,3]` by mistake.

You can also require a key to exist:

```sql
ALTER TABLE products
ADD CONSTRAINT attributes_has_color
CHECK (attributes ? 'color');
```

- The `?` operator means "does this key exist?" (more on it below).

### Adding and dropping columns

```sql
ALTER TABLE products ADD COLUMN metadata jsonb;
ALTER TABLE products DROP COLUMN metadata;
```

### Creating an index (DDL too)

```sql
CREATE INDEX idx_products_attributes
ON products USING GIN (attributes);
```

- `GIN` is an index type built for values that contain many parts (arrays, JSON, text search).
- This index speeds up the containment and key-existence operators (`@>`, `?`) you'll see below.

### Dropping

```sql
DROP INDEX idx_products_attributes;
DROP TABLE products;
```

---

## 3. DML: Data Manipulation Language

DML commands change the _data_: `INSERT`, `UPDATE`, `DELETE`.

### INSERT

```sql
INSERT INTO products (name, attributes)
VALUES
  ('Laptop', '{"brand": "Acme", "ram": 16, "ports": ["usb", "hdmi"], "specs": {"cpu": "i7", "ssd": true}}'),
  ('Phone',  '{"brand": "Zeta", "ram": 8,  "ports": ["usb-c"],       "specs": {"cpu": "A15", "ssd": false}}');
```

PostgreSQL automatically converts the text to `jsonb` and rejects it if it's invalid JSON. If you write `{"brand": Acme}` (no quotes), you get an error right away.

You can also build JSON from normal values:

```sql
INSERT INTO products (name, attributes)
VALUES ('Tablet', jsonb_build_object('brand', 'Nova', 'ram', 4));
```

- `jsonb_build_object(key, value, key, value, ...)` builds an object from pairs.
- Its sibling `jsonb_build_array(...)` builds an array.

### UPDATE: changing a value inside the JSON

This is where `jsonb` shines. You rarely need to replace the whole document.

**Add or replace a top-level key with `||` (concatenate):**

```sql
UPDATE products
SET attributes = attributes || '{"color": "silver"}'
WHERE name = 'Laptop';
```

- `||` merges two JSON objects. If the key exists, it's replaced. If not, it's added.

**Set a value at a path with `jsonb_set`:**

```sql
UPDATE products
SET attributes = jsonb_set(attributes, '{specs,cpu}', '"i9"')
WHERE name = 'Laptop';
```

Line by line:

- `attributes`: the document to change.
- `'{specs,cpu}'`: the **path**, which means "inside `specs`, the key `cpu`".
- `'"i9"'`: the new value. Note the inner double quotes. A JSON string needs quotes, so you write it as text containing quotes.

By default, `jsonb_set` won't create a missing path. Add `true` as a fourth argument to allow creating the last key:

```sql
jsonb_set(attributes, '{specs,gpu}', '"rtx"', true)
```

**Remove a key with `-`:**

```sql
UPDATE products
SET attributes = attributes - 'color'
WHERE name = 'Laptop';
```

**Remove a nested key with `#-`:**

```sql
UPDATE products
SET attributes = attributes #- '{specs,ssd}';
```

**Change a number using extraction and casting:**

```sql
UPDATE products
SET attributes = jsonb_set(
      attributes,
      '{ram}',
      to_jsonb((attributes->>'ram')::int + 8)
    )
WHERE name = 'Laptop';
```

- `attributes->>'ram'` reads `ram` as text.
- `::int` turns it into a number so we can add 8.
- `to_jsonb(...)` turns the result back into a JSON value.

### DELETE

```sql
DELETE FROM products
WHERE attributes->>'brand' = 'Zeta';
```

Rows are deleted based on a value inside the JSON.

> **Important:** every `UPDATE` on a `jsonb` column rewrites the **whole** document on disk, even if you changed one key. For huge documents that are updated often, this can be slow. Keep that in mind when designing.

---

## 4. DQL: Data Query Language

DQL is the `SELECT` side: reading data. This is where you will learn the JSON operators, so let's define them first.

### The core operators

|Operator|Returns|Meaning|
|---|---|---|
|`->`|`jsonb`|Get a field (by key) or element (by index) **as JSON**|
|`->>`|`text`|Get a field or element **as text**|
|`#>`|`jsonb`|Get a value at a **path**, as JSON|
|`#>>`|`text`|Get a value at a path, as text|

### Reading values

```sql
SELECT
    name,
    attributes->'brand'        AS brand_json,
    attributes->>'brand'       AS brand_text,
    attributes->'ports'->0     AS first_port_json,
    attributes->'ports'->>0    AS first_port_text,
    attributes#>>'{specs,cpu}' AS cpu
FROM products;
```

Results for the Laptop row (before our updates):

|brand_json|brand_text|first_port_json|first_port_text|cpu|
|---|---|---|---|---|
|`"Acme"`|`Acme`|`"usb"`|`usb`|`i7`|

- `->` keeps the JSON quotes (`"Acme"`). `->>` gives plain text (`Acme`).
- `->0` reads the first element of an array. Arrays start at index 0.
- `#>>'{specs,cpu}'` digs into nested objects in one step.

**Tip:** use `->>` when you want to compare, sort, or show a value. Use `->` when you want to keep digging deeper.

### Filtering with WHERE

```sql
SELECT name
FROM products
WHERE attributes->>'brand' = 'Acme';
```

For numbers, cast first. The `->>` always returns text:

```sql
SELECT name
FROM products
WHERE (attributes->>'ram')::int >= 16;
```

### The `jsonb`-only superpowers

**Containment `@>`: "does the left contain the right?"**

```sql
SELECT name
FROM products
WHERE attributes @> '{"brand": "Acme"}';
```

You can match nested structure too:

```sql
WHERE attributes @> '{"specs": {"ssd": true}}'
```

Or check that an array holds a value:

```sql
WHERE attributes @> '{"ports": ["hdmi"]}'
```

This is the operator your GIN index accelerates.

**Key existence `?`, `?|`, `?&`:**

|Operator|Meaning|
|---|---|
|`?`|Does this one key exist?|
|`?\|`|Does **any** of these keys exist?|
|`?&`|Do **all** of these keys exist?|

```sql
SELECT name FROM products WHERE attributes ? 'ram';
SELECT name FROM products WHERE attributes ?| array['ram', 'color'];
SELECT name FROM products WHERE attributes ?& array['ram', 'brand'];
```

### JSONPath: a mini query language (PostgreSQL 12+)

```sql
SELECT name
FROM products
WHERE attributes @@ '$.ram > 10';

SELECT jsonb_path_query(attributes, '$.ports[*]') FROM products;
```

- `$` is the root of the document.
- `.ram` goes into the key `ram`.
- `[*]` means "every element of the array".
- `@@` runs a JSONPath predicate and returns true or false.

It's powerful for complex searches, but the simple operators above cover most daily work.

### Expanding JSON into rows

Sometimes you want one row per array element or per key.

```sql
SELECT name, port
FROM products,
     jsonb_array_elements_text(attributes->'ports') AS port;
```

Result:

|name|port|
|---|---|
|Laptop|usb|
|Laptop|hdmi|
|Phone|usb-c|

```sql
SELECT key, value
FROM products,
     jsonb_each(attributes)
WHERE name = 'Laptop';
```

- `jsonb_each` turns each top-level key/value pair into a row.
- `jsonb_object_keys(attributes)` returns just the keys.

### Aggregating rows back into JSON

```sql
SELECT jsonb_agg(name) FROM products;
-- ["Laptop", "Phone", "Tablet"]

SELECT jsonb_object_agg(name, attributes->>'brand') FROM products;
-- {"Laptop": "Acme", "Phone": "Zeta", "Tablet": "Nova"}

SELECT to_jsonb(p) FROM products p;
-- turns an entire row into a JSON object
```

This is extremely handy for building API responses straight from SQL.

### Useful inspection functions

```sql
SELECT jsonb_typeof(attributes->'ram');   -- number
SELECT jsonb_array_length(attributes->'ports');
SELECT jsonb_pretty(attributes) FROM products;   -- readable, indented output
```

---

## 5. Other commands that matter

These don't fit neatly into DDL, DML, or DQL, but you'll use them with JSON.

### Indexes: making JSON queries fast (DDL)

You saw the whole-column GIN index. There are more choices:

```sql
-- Smaller, faster GIN, supports only @> (not ?)
CREATE INDEX idx_attr_path
ON products USING GIN (attributes jsonb_path_ops);

-- B-tree index on ONE extracted value (best for = and ORDER BY)
CREATE INDEX idx_attr_brand
ON products ((attributes->>'brand'));
```

How to choose:

|Your query looks like…|Best index|
|---|---|
|`attributes @> '{...}'` or `attributes ? 'key'`|GIN on the column|
|Only `@>` queries, want it smaller|GIN with `jsonb_path_ops`|
|`attributes->>'brand' = 'Acme'` or sorting|B-tree on the expression|

Notice the double parentheses in `((attributes->>'brand'))`. They are required for expression indexes.

### Transactions (TCL: Transaction Control Language)

Group several changes so they succeed or fail together:

```sql
BEGIN;
UPDATE products SET attributes = attributes || '{"on_sale": true}' WHERE id = 1;
UPDATE products SET attributes = attributes - 'ram' WHERE id = 2;
COMMIT;   -- or ROLLBACK; to undo both
```

### Permissions (DCL: Data Control Language)

```sql
GRANT SELECT ON products TO reporting_user;
```

### Inspecting query plans

```sql
EXPLAIN ANALYZE
SELECT * FROM products WHERE attributes @> '{"brand": "Acme"}';
```

Look for `Bitmap Index Scan` on your GIN index. If you see `Seq Scan`, the index isn't being used (common on very small tables, which is normal).

### Generated columns: promoting a JSON field to a real column

```sql
ALTER TABLE products
ADD COLUMN brand text GENERATED ALWAYS AS (attributes->>'brand') STORED;
```

PostgreSQL keeps `brand` in sync automatically, and you can index and query it like any normal column.

---

## 6. Quick map: which command family is which?

|Family|Full name|Commands|JSON example|
|---|---|---|---|
|**DDL**|Data Definition|`CREATE`, `ALTER`, `DROP`|Create a `jsonb` column, add a `CHECK`, build a GIN index|
|**DML**|Data Manipulation|`INSERT`, `UPDATE`, `DELETE`|`jsonb_set`, `\|`, `-`|
|**DQL**|Data Query|`SELECT`|`->`, `->>`, `@>`, `?`, JSONPath|
|**TCL**|Transaction Control|`BEGIN`, `COMMIT`, `ROLLBACK`|Group several JSON updates|
|**DCL**|Data Control|`GRANT`, `REVOKE`|Control who can read the table|

---

## 7. Related concept: when NOT to use JSON (short summary)

JSON columns are great for data whose shape changes (product attributes, settings, API payloads). But they have no foreign keys, weaker type checking, and rewrite the full document on update. **If a field is always present, queried often, or joined with other tables, make it a normal column.** A good pattern is: normal columns for the stable core, one `jsonb` column for the flexible extras.

---

## 8. Common mistakes to avoid

1. **Forgetting `->>` returns text.** Comparing `attributes->>'ram' > 10` compares text. Cast it: `(attributes->>'ram')::int > 10`.
2. **Forgetting inner quotes in `jsonb_set`.** To set a string, write `'"i9"'`, not `'i9'`.
3. **Using `json` and expecting `@>` or GIN.** Those are `jsonb` only.
4. **Querying without an index** on a large table, then wondering why it's slow.
5. **Storing everything as one giant JSON blob.** Use it where it fits, not everywhere.

---

## 9. Using it from Java (a short peek)

Since you work with Java and JDBC, here's how you would read a `jsonb` column:

```java
String sql = "SELECT attributes->>'brand' FROM products WHERE id = ?";
try (PreparedStatement ps = conn.prepareStatement(sql)) {
    ps.setInt(1, 1);
    try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) System.out.println(rs.getString(1));
    }
}
```

To insert, cast the parameter so PostgreSQL knows it's JSON:

```java
String sql = "INSERT INTO products (name, attributes) VALUES (?, ?::jsonb)";
```

- `?::jsonb` tells PostgreSQL to convert the incoming text into `jsonb`.

---






[[PostgreSQL]]