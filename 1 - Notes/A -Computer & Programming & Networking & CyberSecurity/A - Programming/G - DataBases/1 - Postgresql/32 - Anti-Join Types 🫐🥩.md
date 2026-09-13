

## **1 — NOT EXISTS Anti Join**

This is the most reliable and widely used Anti Join type.

**Definition**: Checks for the non-existence of matching rows.

**Example**:

```sql
SELECT *
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM submitted_homework sh
    WHERE sh.student_id = s.id
);
```

✅ **Pros**:

- Works well for large datasets.
    
- Handles NULLs correctly.
    
- Very flexible (multiple conditions possible).
    

⚠️ **Cons**:

- Can be slower if indexes aren’t available.
    

---

## **2 — LEFT JOIN + IS NULL Anti Join**

Uses a `LEFT JOIN` and filters rows where join produces NULL.

**Example**:

```sql
SELECT s.*
FROM students s
LEFT JOIN submitted_homework sh
ON s.id = sh.student_id
WHERE sh.student_id IS NULL;
```

✅ **Pros**:

- Easy to understand.
    
- Works with any SQL database.
    

⚠️ **Cons**:

- Can be slower for large datasets because it builds the join before filtering.
    

---

## **3 — NOT IN Anti Join**

Uses `NOT IN` to filter values not in another dataset.

**Example**:

```sql
SELECT *
FROM students
WHERE id NOT IN (
    SELECT student_id
    FROM submitted_homework
);
```

✅ **Pros**:

- Short, easy to write.
    

⚠️ **Cons**:

- Fails if the subquery contains NULL.
    
- Can be slower for large datasets.
    
- Less flexible for complex conditions.
    

---

## **4 — EXCEPT Anti Join**

Uses PostgreSQL’s `EXCEPT` keyword to subtract one dataset from another.

**Example**:

```sql
SELECT id, name
FROM students
EXCEPT
SELECT s.id, s.name
FROM students s
JOIN submitted_homework sh
ON s.id = sh.student_id;
```

✅ **Pros**:

- Very readable.
    
- Easy to write for simple cases.
    

⚠️ **Cons**:

- Requires matching column structure in both queries.
    
- Not as flexible for complex logic.
    

---

## **5 — Anti Join with LEFT ANTI SEMI JOIN (Conceptual in SQL Engines)**

Some databases have **native Anti Join optimizations** called _Left Anti Semi Join_.  
PostgreSQL doesn’t expose it directly — it translates queries internally.

**Example**:  
Conceptually similar to:

```sql
SELECT *
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM submitted_homework sh
    WHERE sh.student_id = s.id
);
```

⚡ This is **performance optimized internally** by the database engine.

---

## **6 — Anti Join with FILTER / EXCLUSION in Advanced PostgreSQL**

You can use filtering functions or conditions for Anti Join logic.

**Example**:

```sql
SELECT s.*
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM submitted_homework sh
    WHERE sh.student_id = s.id
      AND sh.submitted_date > CURRENT_DATE - INTERVAL '7 days'
);
```

This is a **conditional Anti Join** — not just “no match” but “no match under a condition.”

---

## **7 — Anti Join with CTE (Common Table Expression)**

Sometimes Anti Joins are written using CTEs for clarity.

**Example**:

```sql
WITH submitted AS (
    SELECT DISTINCT student_id
    FROM submitted_homework
)
SELECT *
FROM students s
WHERE s.id NOT IN (SELECT student_id FROM submitted);
```

✅ **Pros**:

- Makes complex queries easier to read.
    
- Great for multi-step logic.
    

⚠️ **Cons**:

- Extra complexity if not needed.
    

---

---

### **Summary Table — Anti Join Types**

|Type|SQL Pattern|Best For|
|---|---|---|
|**NOT EXISTS**|Subquery with NOT EXISTS|Large datasets, NULL-safe|
|**LEFT JOIN + IS NULL**|LEFT JOIN + WHERE IS NULL|Readability, small-medium datasets|
|**NOT IN**|WHERE NOT IN (subquery)|Simple queries, small datasets|
|**EXCEPT**|SELECT … EXCEPT SELECT …|Clear subtraction queries|
|**LEFT ANTI SEMI JOIN**|DB engine optimization|Large datasets, internal optimization|
|**Conditional Anti Join**|NOT EXISTS with conditions|Complex logic|
|**CTE Anti Join**|WITH + NOT IN / NOT EXISTS|Complex multi-step queries|

---

💡 Pro Tip:  
For **PostgreSQL**, **NOT EXISTS** is generally the safest, fastest, and most NULL-safe choice for Anti Joins unless there’s a specific reason to use another type.

---



#### Tags : [[1 - SQL 🥞]]