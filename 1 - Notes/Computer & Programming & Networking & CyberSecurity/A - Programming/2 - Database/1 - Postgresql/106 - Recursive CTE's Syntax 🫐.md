In theory, the **syntax of a recursive CTE** defines a **self-referencing query** made up of two parts — an **anchor** and a **recursive** query — joined with `UNION [ALL]`.

### **Syntax (theoretical form):**

```sql
WITH RECURSIVE cte_name (column_list) AS (
    -- 1️⃣ Anchor query (base case)
    initial_query

    UNION [ALL]

    -- 2️⃣ Recursive query (refers to cte_name)
    recursive_query
)
SELECT * FROM cte_name;
```



```sql
-- SubQuery
WITH RECURSIVE Series AS (
	-- Anchor query
	SELECT 1 
	AS myNumber
	UNION ALL  -- connector 
	-- RECURSIVE Query
	SELECT
	myNumber + 1 
	FROM series
	WHERE myNumber < 120 --Stop point (break)
) 
-- Main Query 
SELECT * FROM series
```


### **Theory breakdown:**

- `WITH RECURSIVE` → tells PostgreSQL this CTE can call itself.
    
- **Anchor query** → produces the first set of rows (base result).
    
- `UNION [ALL]` → combines base and recursive results each step.
    
- **Recursive query** → repeatedly runs, using previous results from the CTE itself.
    
- The recursion stops automatically when **no new rows** are returned.
    

So in theory:

> A recursive CTE defines a **looping query expression** that starts with a base result (anchor) and repeatedly applies a recursive rule to build a complete hierarchical or sequential result set.

In a **recursive CTE**, there are two main parts:

### 1. **Anchor query**

- The **starting point** — runs **once**.
    
- Gets the **initial rows** (like the root of a tree).
    
- Example: get the top manager or the root category.
    

### 2. **Recursive query**

- The **repeating part** — runs **again and again**.
    
- Refers to the CTE itself to fetch the **next level** of data.
    
- Keeps running until no new rows appear.
    

### Example:

```sql
WITH RECURSIVE employee_tree AS (
  -- 🧱 Anchor query
  SELECT id, name, manager_id
  FROM employees
  WHERE manager_id IS NULL   -- top-level boss

  UNION ALL

  -- 🔁 Recursive query
  SELECT e.id, e.name, e.manager_id
  FROM employees e
  INNER JOIN employee_tree t ON e.manager_id = t.id
)
SELECT * FROM employee_tree;
```

**In short:**

- 🧱 **Anchor query** = starting rows.
    
- 🔁 **Recursive query** = keeps building the next levels.


---
Here's the complete syntax for recursive CTEs in PostgreSQL:

## Basic Syntax Structure

```sql
WITH RECURSIVE cte_name (column1, column2, ...) AS (
    -- Base case (non-recursive term)
    SELECT base_column1, base_column2, ...
    FROM table_name
    WHERE conditions
    
    UNION [ALL | DISTINCT]
    
    -- Recursive case (recursive term)
    SELECT recursive_column1, recursive_column2, ...
    FROM cte_name
    JOIN other_tables ON join_conditions
    WHERE termination_conditions
)
SELECT * FROM cte_name;
```

## Detailed Syntax Breakdown

### 1. **WITH RECURSIVE Clause**
```sql
WITH RECURSIVE cte_name (optional_column_list) AS (
    -- CTE definition here
)
```

### 2. **Base Case (Anchor Member)**
```sql
SELECT columns
FROM tables
WHERE initial_conditions
```

### 3. **Recursive Case (Recursive Member)**
```sql
SELECT columns
FROM cte_name  -- References the CTE itself
JOIN other_tables ON conditions
WHERE recursive_conditions
```

## Complete Syntax Examples

### Basic Number Sequence
```sql
WITH RECURSIVE numbers(n) AS (
    SELECT 1  -- Base case
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10  -- Recursive case
)
SELECT * FROM numbers;
```

### With Column Aliases
```sql
WITH RECURSIVE employee_tree (emp_id, emp_name, level, path) AS (
    SELECT 
        id, 
        name, 
        1 as level,
        name::TEXT as path
    FROM employees 
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id,
        e.name,
        et.level + 1,
        et.path || ' -> ' || e.name
    FROM employees e
    JOIN employee_tree et ON e.manager_id = et.emp_id
)
SELECT * FROM employee_tree;
```

### Advanced Syntax with Multiple CTEs
```sql
WITH RECURSIVE 
    cte1 (col1, col2) AS (
        SELECT a, b FROM table1 WHERE condition
        UNION ALL
        SELECT col1 + 1, col2 FROM cte1 WHERE col1 < 100
    ),
    cte2 (col3, col4) AS (
        SELECT c, d FROM table2
        UNION ALL
        SELECT col3 * 2, col4 FROM cte2 WHERE col3 < 1000
    )
SELECT * FROM cte1 JOIN cte2 ON cte1.col1 = cte2.col3;
```

## Key Syntax Elements

### 1. **UNION vs UNION ALL**
```sql
-- Removes duplicates (slower)
UNION

-- Keeps duplicates (faster, more common)
UNION ALL
```

### 2. **Column Definition**
```sql
-- Explicit column names
WITH RECURSIVE cte_name (id, name, level) AS (...)

-- Implicit column names (from first SELECT)
WITH RECURSIVE cte_name AS (...)
```

### 3. **Termination Conditions**
```sql
WHERE n < 100                    -- Maximum value
WHERE level < 5                  -- Maximum depth  
WHERE NOT EXISTS (...)           -- Conditional stop
WHERE NOT cycle                  -- Cycle detection
```

## Cycle Detection Syntax (PostgreSQL 14+)

```sql
WITH RECURSIVE cte_name (columns) AS (
    SELECT columns, ARRAY[id] as path, false as cycle
    FROM table
    WHERE conditions
    
    UNION ALL
    
    SELECT 
        columns,
        path || new_id,
        new_id = ANY(path)       -- Cycle detection
    FROM cte_name
    JOIN other_tables ON conditions
    WHERE NOT cycle              -- Stop on cycles
)
SELECT * FROM cte_name;
```

## Practical Template

```sql
WITH RECURSIVE hierarchy AS (
    -- Start with root nodes
    SELECT 
        id,
        name,
        parent_id,
        1 as level,
        ARRAY[id] as path,
        name::TEXT as breadcrumb
    FROM your_table
    WHERE parent_id IS NULL  -- or your starting condition
    
    UNION ALL
    
    -- Recursively get children
    SELECT 
        t.id,
        t.name,
        t.parent_id,
        h.level + 1,
        h.path || t.id,
        h.breadcrumb || ' > ' || t.name
    FROM your_table t
    INNER JOIN hierarchy h ON t.parent_id = h.id
    WHERE h.level < 20  -- Prevent infinite recursion
)
SELECT * FROM hierarchy
ORDER BY path;
```

## Important Notes

- **Termination**: The recursion stops when the recursive term returns no rows
- **Column Matching**: All SELECT statements must have the same number and compatible types of columns
- **Performance**: Use `UNION ALL` unless you specifically need to remove duplicates
- **Infinite Loops**: Always include proper termination conditions

This syntax allows you to work with hierarchical data, graph traversal, sequential data generation, and many other recursive patterns in PostgreSQL.
##### Tags : [[1 - SQL 🥞]]