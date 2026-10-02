
## **Basic JOIN Formula**

```sql
SELECT <columns>
FROM <table1> [alias1]
<JOIN TYPE> <table2> [alias2]
ON <join_condition>
[WHERE <conditions>]
[GROUP BY <columns>]
[HAVING <conditions>]
[ORDER BY <columns>];
```

---

### **Parts explained**

1. **SELECT `<columns>`** → list the columns you want from both tables (e.g. `a.id, a.name, b.course_id`).
    
2. **FROM `<table1>` [alias1]** → main table you start from. You can give it an alias to make joins easier.
    
3. **`<table2>` [alias2]** →
    
    - `INNER JOIN`
        
    - `LEFT JOIN`
        
    - `RIGHT JOIN`
        
    - `FULL JOIN`
        
    - `CROSS JOIN`
        
4. **ON `<join_condition>`** → the rule that matches rows between tables.  
    Example: `a.id = b.student_id`.
    
5. **Optional clauses**:
    
    - `WHERE` → filter after join.
        
    - `GROUP BY` → group rows.
        
    - `HAVING` → filter grouped rows.
        
    - `ORDER BY` → sort results.
        

---

### **Generic Example**

```sql
SELECT a.column1, a.column2, b.column3
FROM tableA a
INNER JOIN tableB b
  ON a.common_column = b.common_column
WHERE a.condition = true
ORDER BY a.column1;
```

---

### **Real Example**

```sql
SELECT s.id, s.name, e.course_id
FROM Students s
INNER JOIN Enrollments e
  ON s.id = e.student_id
WHERE e.course_id = 101
ORDER BY s.name;
```

✅ This formula works for **all join types** — you just change the `<JOIN TYPE>` and the `<join_condition>`.

---

## 1) INNER JOIN

**What:** Returns only rows that satisfy the join condition in **both** tables.  
**When to use:** You want rows that have matching partners in both tables (most common join).

> **Return only the matching rows from the tables** 


>An **INNER JOIN** takes two (or more) tables, looks for rows where the **join condition** is true (matching column values), and returns only those rows.  
  Any row in either table that does **not** have a match is **excluded** from the result set.

**SQL:**

```sql
SELECT s.id, s.name, e.course
FROM students s
INNER JOIN enrollments e
  ON s.id = e.student_id;
```

**Sample data**  
`students`

|id|name|
|---|---|
|1|Alice|
|2|Bob|
|3|Carol|

`enrollments`

|student_id|course|
|---|---|
|1|Math|
|1|Physics|
|3|Art|

**Result**

|id|name|course|
|---|---|---|
|1|Alice|Math|
|1|Alice|Physics|
|3|Carol|Art|

**Notes / pitfalls**

- If multiple matches exist, rows are duplicated for each match (multiplicative).
    
- Fast with indexes on join columns; otherwise database may choose hash/merge/nested-loop.
    

---

## 2) LEFT OUTER JOIN (LEFT JOIN)

**What:** All rows from **left** table; matching rows from right or `NULL` when no match.  
**When to use:** Keep all left-side rows and optionally attach right-side data.

**SQL:**

```sql
SELECT s.id, s.name, e.course
FROM students s
LEFT JOIN enrollments e
  ON s.id = e.student_id;
```

**Result (using same sample data)**

|id|name|course|
|---|---|---|
|1|Alice|Math|
|1|Alice|Physics|
|2|Bob|NULL|
|3|Carol|Art|

**Notes**

- Use `WHERE e.student_id IS NULL` on the result to find rows **without** matches (anti-join).
    
- Useful for optional child records (customers with/without orders).
    

---

## 3) RIGHT OUTER JOIN (RIGHT JOIN)

**What:** Symmetric to LEFT JOIN: all rows from **right** table; left matches or `NULL`.  
**When to use:** Keep all right-side rows. (Often rewritten as LEFT JOIN by swapping table order.)

**SQL:**

```sql
SELECT s.id, s.name, e.course
FROM students s
RIGHT JOIN enrollments e
  ON s.id = e.student_id;
```

**When to avoid**

- Right joins are less common; prefer swapping tables and using LEFT JOIN for readability.
    

---

## 4) FULL OUTER JOIN (FULL JOIN)

**What:** All rows from **both** tables. Where no match, columns from the other table are `NULL`.  
**When to use:** You need rows present in either table and want to see missing matches from both sides.

**SQL:**

```sql
SELECT s.id AS student_id, s.name, e.student_id AS e_student_id, e.course
FROM students s
FULL JOIN enrollments e
  ON s.id = e.student_id;
```

**If `enrollments` had one extra row `student_id = 4, course = 'Music'`**, result:

|student_id|name|e_student_id|course|
|---|---|---|---|
|1|Alice|1|Math|
|1|Alice|1|Physics|
|2|Bob|NULL|NULL|
|3|Carol|3|Art|
|NULL|NULL|4|Music|

**Notes**

- Useful for reconciliation tasks.
    
- Be careful with `NULL` comparisons (e.g., `WHERE e.course IS NULL` identifies unmatched right rows).
    

---

## 5) CROSS JOIN

**What:** Cartesian product — every row from left combined with every row from right.  
**When to use:** You explicitly need all combinations (rare); or generate test data/combinatorics.

**SQL:**

```sql
SELECT s.name, c.name AS course
FROM students s
CROSS JOIN courses c;
```

**Example:** 3 students × 2 courses → 6 rows.

**Warning**

- Can produce huge result sets quickly. Use carefully.
    

---

## 6) SELF JOIN

**What:** A table joined to itself using aliases.  
**When to use:** Relational structures referencing same table (e.g., employee → manager).

**SQL (employees with manager_id):**

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m
  ON e.manager_id = m.id;
```

**Notes**

- Always use different aliases for the two roles.
    
- Useful for hierarchical queries (though recursive CTEs are often better for multi-level hierarchies).
    

---

## 7) NATURAL JOIN

**What:** Automatically joins on all columns with the same name in both tables. It also removes duplicate columns in the output.  
**SQL:**

```sql
SELECT * FROM students NATURAL JOIN enrollments;
```

**Caution**

- Implicit behavior: fragile and can break if schema changes.
    
- Generally **not recommended** in production; prefer explicit `ON` or `USING`.
    

---

## 8) JOIN ... USING(col1, col2)

**What:** Shorthand when both tables have columns with the same name(s). Produces a single copy of those column(s) in result.  
**SQL:**

```sql
SELECT *
FROM students s
JOIN enrollments e USING (id);  -- joins on s.id = e.id and returns id once
```

**Note vs ON**

- `USING` enforces equality on named columns and hides duplicate columns; `ON` is more general.
    

---

## 9) EQUI-JOIN vs NON-EQUI (Theta) JOIN

- **Equi-join:** join condition uses `=` (common).
    
- **Non-equi / theta-join:** uses operators like `<, >, <=, >=, BETWEEN` or arbitrary expressions.  
    **Example non-equi:** find price bands:
    

```sql
SELECT p.*, b.band_name
FROM products p
JOIN price_bands b
  ON p.price BETWEEN b.low AND b.high;
```

---

## 10) LATERAL JOIN (PostgreSQL-specific)

**What:** `LATERAL` allows a subquery (or function) in the FROM clause to reference columns of preceding FROM items. Very powerful for "top N per row" and set-returning functions.

**SQL example (pick most recent order per customer):**

```sql
SELECT c.id, c.name, o.*
FROM customers c
LEFT JOIN LATERAL (
  SELECT * FROM orders o
  WHERE o.customer_id = c.id
  ORDER BY o.created_at DESC
  LIMIT 1
) o ON true;
```

**When to use**

- When the right side needs the left side’s column(s) to compute its rows.
    
- Useful with `unnest()`, JSON functions, or functions returning sets.
    

---

## 11) SEMI-JOIN (conceptual) — `EXISTS` / `IN`

**What:** Returns rows from left that **have** a match in right, but does **not** duplicate right-side columns. Implemented via `EXISTS` or `IN`. It’s like “filter left for existence of related rows.”

**Example (EXISTS):**

```sql
SELECT * FROM students s
WHERE EXISTS (
  SELECT 1 FROM enrollments e WHERE e.student_id = s.id
);
```

**Performance note**

- `EXISTS` is typically good for correlated checks; DB optimizers implement it as semi-join.
    

---

## 12) ANTI-JOIN (conceptual) — `NOT EXISTS` or LEFT JOIN … IS NULL

**What:** Return rows from left that **do NOT** have a match in right.

**Pattern A — NOT EXISTS (recommended):**

```sql
SELECT * FROM students s
WHERE NOT EXISTS (
  SELECT 1 FROM enrollments e WHERE e.student_id = s.id
);
```

**Pattern B — LEFT JOIN anti-join:**

```sql
SELECT s.*
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
WHERE e.student_id IS NULL;
```

**Note**

- `NOT EXISTS` usually avoids pitfalls with `NULL` values and is generally preferred.
    

---

# Extra: Practical tips & performance

- **Index the join columns** (foreign keys, lookup keys) for speed.
    
- **Avoid wrapping join keys in functions** (e.g., `ON LOWER(a.col) = b.col`) — prevents index use. If needed, create functional indexes.
    
- **Use `EXPLAIN` / `EXPLAIN ANALYZE`** to see chosen join algorithm (nested loop, hash join, merge join).
    
- **Outer joins** preserve unmatched rows; be careful when adding `WHERE` clauses — they can turn an outer join into an effective inner join (filtering on right-table columns in WHERE removes NULL unmatched rows). If you need to filter right-side conditions but still keep unmatched left rows, place conditions in the `ON` clause or use `WHERE (right.col IS NULL OR right.col = ...)`.
    
- **Duplicates:** Remember joins can multiply rows. If you want unique left rows that simply have matches, use semi-join (`EXISTS`) rather than INNER JOIN + DISTINCT.
    
- **Large tables:** consider join order, statistics, and proper predicates — let the planner choose, but sometimes rephrasing helps.
    
- **Use explicit `ON` clauses** rather than NATURAL JOIN for clarity.
    

---

# Quick reference summary (which to use)

- Need matching rows from both → **INNER JOIN**
    
- Keep all left rows → **LEFT JOIN**
    
- Keep all right rows → **RIGHT JOIN** (or swap + LEFT JOIN)
    
- Keep everything from both → **FULL JOIN**
    
- All combinations → **CROSS JOIN**
    
- Table with itself → **SELF JOIN**
    
- Auto-match columns (avoid) → **NATURAL JOIN**
    
- Need row existence only → **SEMI-JOIN** (`EXISTS`)
    
- Need rows without match → **ANTI-JOIN** (`NOT EXISTS` / LEFT..IS NULL)
    
- Need correlated per-row subquery in FROM → **LATERAL JOIN**
    

---

If you want, I can:

- produce **visual Venn diagrams / ASCII diagrams** for each join, or
    
- give **focused examples** for one join type (with `EXPLAIN ANALYZE`) to show real planner behavior, or
    
- create a **cheat sheet** PDF with examples for quick reference.
    

Which next?

#### Tags : [[1 - SQL 🦬]]