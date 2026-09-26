
Below is a **complete, authoritative guide** to **sub-query dependencies** in **PostgreSQL** — **what they are**, **how PostgreSQL tracks them**, **execution order**, **performance impact**, **visualization**, and **senior-level optimization strategies**.

---

## 1. What Are Sub-Query Dependencies?

> **A sub-query is *dependent* on an outer query if it references any column, variable, or object from that outer scope.**

| Type | Dependency | Example |
|------|------------|--------|
| **Non-dependent (Independent)** | No outer references | `(SELECT AVG(salary) FROM employees)` |
| **Dependent (Correlated)** | References outer column | `(SELECT COUNT(*) FROM bonuses b WHERE b.emp_id = e.id)` |
| **Lateral dependency** | References outer **per row** via `LATERAL` | `JOIN LATERAL (SELECT ... WHERE x = e.x)` |

---

## 2. PostgreSQL’s Internal Dependency Tracking

PostgreSQL builds a **dependency graph** during parsing/planning:

```text
Outer Query
├── SELECT list
│   └── SubPlan → InitPlan (non-correlated)
├── FROM clause
│   └── LATERAL SubPlan → per row
└── WHERE clause
    └── SubPlan → per row (correlated)
```

### Key Planner Nodes

| Node | Meaning |
|------|--------|
| `InitPlan` | Non-correlated → executed **once**, result cached |
| `SubPlan` | Correlated → executed **per outer row** |
| `LATERAL` | Explicit marker for per-row dependency |

---

## 3. Dependency Rules by Clause

| Clause | Dependency Allowed? | How Enforced |
|--------|---------------------|-------------|
| `SELECT` | Yes (correlated) | `SubPlan` per row |
| `FROM` | Only with `LATERAL` | `LATERAL` keyword required |
| `JOIN` | Only with `LATERAL` | Same as `FROM` |
| `WHERE` | Yes | `SubPlan` per row |
| `WITH` (CTE) | No direct correlation | Use `LATERAL` or join |

---

## 4. Execution Order & Dependency Flow

```sql
SELECT 
    e.name,
    (SELECT AVG(salary) FROM employees),           -- InitPlan: run ONCE
    (SELECT SUM(b.amount) FROM bonuses b WHERE b.emp_id = e.id)  -- SubPlan: per e
FROM employees e
JOIN LATERAL (
    SELECT review FROM reviews r 
    WHERE r.emp_id = e.id ORDER BY date DESC LIMIT 1
) r ON true
WHERE EXISTS (                                    -- SubPlan: per e
    SELECT 1 FROM promotions p WHERE p.emp_id = e.id
);
```

### Execution Sequence:
1. **InitPlan** → `(SELECT AVG(salary)...)` → **once**
2. **Outer scan** → `employees e`
3. For **each `e`**:
   - `LATERAL` sub-query → `reviews`
   - `WHERE EXISTS` → `promotions`
   - `SELECT` correlated → `bonuses`

---

## 5. Visual Dependency Graph

![[mermaid-diagram.svg]]

- **Blue** = Non-dependent (once)
- **Orange** = Dependent (per row)

---

## 6. Performance Impact of Dependencies

| Dependency Type | Cost | Mitigation |
|----------------|------|----------|
| **Non-dependent** | `O(1)` | Use always |
| **Correlated (`WHERE`/`SELECT`)** | `O(n)` | Index outer column |
| **LATERAL** | `O(n)` | Index + `LIMIT` |
| **Nested correlated** | `O(n²)` | **Avoid** — refactor |

### Bad: Nested Correlation
```sql
-- O(n²) — AVOID
SELECT e1.*,
       (SELECT COUNT(*) FROM employees e2 
        WHERE e2.manager_id = e1.id
          AND e2.id IN (SELECT emp_id FROM terminations))
FROM employees e1;
```

### Good: Refactor to Join/CTE
```sql
WITH terminated AS (
    SELECT emp_id FROM terminations
)
SELECT e1.*, COUNT(t.emp_id)
FROM employees e1
LEFT JOIN employees e2 ON e2.manager_id = e1.id
LEFT JOIN terminated t ON t.emp_id = e2.id
GROUP BY e1.id;
```

---

## 7. Senior-Level Optimization Patterns

### 1. **Promote Correlated → Non-correlated via CTE**
```sql
-- SLOW: correlated
SELECT e.*,
       (SELECT COUNT(*) FROM orders o WHERE o.emp_id = e.id)
FROM employees e;

-- FAST: non-correlated
WITH order_counts AS (
    SELECT emp_id, COUNT(*) AS cnt
    FROM orders
    GROUP BY emp_id
)
SELECT e.*, COALESCE(oc.cnt, 0)
FROM employees e
LEFT JOIN order_counts oc ON oc.emp_id = e.id;
```

### 2. **Use `LATERAL` for Top-N per Group**
```sql
SELECT e.*
FROM employees e
JOIN LATERAL (
    SELECT *
    FROM bonuses b
    WHERE b.emp_id = e.id
    ORDER BY amount DESC
    LIMIT 1
) top_bonus ON true;
```

### 3. **Materialize Heavy Dependencies**
```sql
-- PostgreSQL 12+
WITH heavy AS MATERIALIZED (
    SELECT complex_calc(...) FROM ...
)
SELECT ...
```

### 4. **Index Every Dependency Path**
```sql
CREATE INDEX idx_bonuses_emp_id ON bonuses(emp_id);
CREATE INDEX idx_reviews_emp_date ON reviews(emp_id, review_date DESC);
```

---

## 8. How to Inspect Dependencies

### `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.name,
       (SELECT COUNT(*) FROM bonuses b WHERE b.emp_id = e.id)
FROM employees e;
```

**Look for**:
- `InitPlan` → non-dependent
- `SubPlan` → correlated
- `Lateral Join` → per-row

---

## 9. Dependency Anti-Patterns

| Pattern | Problem | Fix |
|-------|--------|-----|
| `SELECT (SELECT ... WHERE x = e.x)` | Per-row scalar | Use `JOIN` |
| `FROM (SELECT ... WHERE y = e.y)` | No `LATERAL` | Add `LATERAL` |
| Nested `EXISTS` | `O(n²)` | Use `JOIN` or `CTE` |
| `ORDER BY` in correlated without `LIMIT` | Full sort per row | Add `LIMIT` |

---

## 10. Cheat Sheet: Dependency Decision Matrix

| You Want… | Dependency Type | Syntax |
|----------|------------------|--------|
| Same value for all rows | **Non-dependent** | `(SELECT ...)` |
| Value per row | **Correlated** | `(SELECT ... WHERE col = outer.col)` |
| Table per row | **LATERAL** | `JOIN LATERAL (SELECT ...) ON true` |
| Filter per row | **Correlated `EXISTS`** | `EXISTS (SELECT 1 ...)` |
| Avoid per-row cost | **Refactor to `JOIN`/`CTE`** | — |

---

## Final Summary

| Concept | Key Point |
|--------|----------|
| **Non-dependent** | Run **once** → `InitPlan` |
| **Correlated** | Run **per row** → `SubPlan` |
| **`LATERAL`** | Enables **per-row tables** |
| **Performance** | `O(1)` > `O(n)` > `O(n²)` |
| **Best Practice** | **Minimize dependencies**, **index them**, **refactor when possible** |

---

**Master dependencies → you control the planner.**  
**Every `e.col` in a sub-query = one more execution.**  
**Eliminate or index them.**

Use this guide to **audit, optimize, and explain** any sub-query performance issue in production.

##### Tags : [[1 - SQL 🦬]]