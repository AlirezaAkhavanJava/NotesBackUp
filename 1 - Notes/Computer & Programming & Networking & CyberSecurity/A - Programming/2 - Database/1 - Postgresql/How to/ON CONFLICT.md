
### **1. `ON CONFLICT`**

Used in **`INSERT ... ON CONFLICT ...`** (also called “upsert”) to handle violations of **unique constraints**.

**Syntax:**

```sql
INSERT INTO table_name (col1, col2)
VALUES (val1, val2)
ON CONFLICT (col1) 
DO UPDATE SET col2 = EXCLUDED.col2;
```

**Explanation:**

- `(col1)` → column(s) with a unique constraint or primary key.
    
- `EXCLUDED.col2` → refers to the value that was attempted to be inserted (the “would-be row”).
    
- You can also do `DO NOTHING` instead of `DO UPDATE` if you want to skip conflicting inserts.
    

**Example:**

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE,
    name TEXT
);

INSERT INTO users (email, name)
VALUES ('goat@example.com', 'Mr. Goat')
ON CONFLICT (email) 
DO UPDATE SET name = EXCLUDED.name;
```

Here, if the email already exists, the `name` is updated instead of raising an error.

---

### **2. `EXCLUDE` / Exclusion Constraints**

`EXCLUDE` is **not part of INSERT**, it’s a **table-level constraint** to prevent conflicting data based on an **operator**, not just equality.

**Syntax:**

```sql
CREATE TABLE reservations (
    room INT,
    during TSRANGE,
    EXCLUDE USING GIST (
        room WITH =,
        during WITH &&
    )
);
```

**Explanation:**

- Prevents **overlapping time ranges for the same room**.
    
- `USING GIST` → uses a GiST index to enforce the exclusion.
    
- `&&` → range overlap operator; `=` → equality.
    
- Essentially: "No two rows can have the same room **and** overlapping time ranges."
    

**Key Differences from `ON CONFLICT`:**

|Feature|ON CONFLICT|EXCLUDE|
|---|---|---|
|Type|Insert-time handling|Constraint at table level|
|Triggers on|Unique violation|Custom operators (e.g., ranges)|
|Action|DO NOTHING / DO UPDATE|Blocks insert/update if violation|
|Scope|Specific columns|Multiple columns + operators|

---

💡 **TL;DR Goat Mode:**

- `ON CONFLICT`: “I tried to insert, but if it clashes with a unique key, fix it or skip it.”
    
- `EXCLUDE`: “I never want this weird overlap to happen in this table, no matter what, period.”
    

---

[[1 - SQL 🦬]]