

## **1. Function (Expression) Index**

- **Definition:** An index built on the **result of a function or expression** rather than a column directly.
    
- **Purpose:** Optimize queries that filter or sort based on an expression.
    

**Syntax:**

```sql
CREATE INDEX idx_lower_name
ON students (LOWER(name));
```

**Example usage:**

```sql
SELECT * FROM students
WHERE LOWER(name) = 'alice';
```

- Without this index, PostgreSQL cannot use a standard index for `LOWER(name)`.
    
- Works for **computed values** like `age + 1`, `date_trunc('month', created_at)`, etc.
    

---

## **2. Unique Index**

- **Definition:** An index that **enforces uniqueness** of values in the indexed column(s).
    
- **Automatically created for:** `PRIMARY KEY` and `UNIQUE` constraints.
    

**Syntax:**

```sql
CREATE UNIQUE INDEX idx_email_unique
ON students(email);
```

**Key points:**

- Guarantees **no duplicate values** for the indexed column(s).
    
- Can be **single or multi-column**:
    

```sql
CREATE UNIQUE INDEX idx_name_country
ON students(name, country);
```

- Helps with **data integrity** and can also improve query performance.
    

---

## **3. Filtered Index (Partial Index)**

- **Definition:** An index that **only includes rows satisfying a specific condition**.
    
- PostgreSQL calls it a **partial index**.
    

**Syntax:**

```sql
CREATE INDEX idx_active_students
ON students(name)
WHERE active = true;
```

**Advantages:**

- Smaller and faster than indexing the whole table.
    
- Optimized for queries that **always filter on that condition**:
    

```sql
SELECT * FROM students
WHERE active = true AND name = 'Alice';
```

- Won’t help queries on rows where `active = false`.
    

---

### **Summary Table**

|Index Type|Purpose|Example|Notes|
|---|---|---|---|
|Function / Expression|Index on a computed value|`LOWER(name)`|Needed when query uses a function on a column|
|Unique|Enforce uniqueness|`UNIQUE(email)`|Supports `PRIMARY KEY` or `UNIQUE` constraints|
|Filtered / Partial|Index only part of the table|`WHERE active = true`|Smaller, faster for filtered queries|

---

💡 **Extra tip:** You can **combine these features**:

```sql
CREATE UNIQUE INDEX idx_active_email
ON students(email)
WHERE active = true;
```

- Only **active students** are indexed, and their **emails must be unique**.
    



###### Tags : [[1 - SQL 🥞]]