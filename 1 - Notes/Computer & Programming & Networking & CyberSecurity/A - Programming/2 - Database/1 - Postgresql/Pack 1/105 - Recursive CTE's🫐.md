
A **recursive CTE (Common Table Expression)** in PostgreSQL is a query that **refers to itself** — it runs repeatedly until a certain condition is met.

### In simple words:

It’s like a loop inside SQL — it keeps running, each time using the result from the previous step, until no more new results appear.

### Structure:

```sql
WITH RECURSIVE cte_name AS (
  -- 1️⃣ Base query (starting point)
  SELECT ...
  UNION ALL
  -- 2️⃣ Recursive query (uses cte_name itself)
  SELECT ...
  FROM cte_name
  WHERE ...
)
SELECT * FROM cte_name;
```

### Usage:

- To handle **hierarchical or tree-like data** (e.g., employees and their managers).
    
- To **traverse** relationships like folders, categories, or graph paths.
    
- To **generate sequences** or accumulate results step-by-step.
    

Example: find all subordinates of a manager, or all parent-child links in a table.

---

> Recursive CTEs (Common Table Expressions) in PostgreSQL are a powerful feature that allow you to perform recursive queries on hierarchical or graph-based data. They're essentially CTEs that can reference themselves.

## Basic Syntax

```sql
WITH RECURSIVE cte_name AS (
    -- Base case (non-recursive term)
    SELECT ...
    UNION [ALL]
    -- Recursive case (recursive term)
    SELECT ... FROM cte_name ...
)
SELECT * FROM cte_name;
```

## Key Components

1. **Base Case**: The initial query that starts the recursion
2. **Recursive Case**: The part that references the CTE itself
3. **Termination Condition**: Implicitly stops when no more rows are returned

## Simple Example: Number Sequence

```sql
WITH RECURSIVE numbers AS (
    -- Base case: start with 1
    SELECT 1 as n
    UNION ALL
    -- Recursive case: increment until 10
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT * FROM numbers;
```

## Practical Example: Employee Hierarchy

```sql
-- Sample table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    manager_id INTEGER REFERENCES employees(id)
);

INSERT INTO employees VALUES 
(1, 'CEO', NULL),
(2, 'VP Engineering', 1),
(3, 'VP Sales', 1),
(4, 'Engineering Manager', 2),
(5, 'Senior Developer', 4);

-- Find all subordinates of a manager
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: start with the CEO
    SELECT id, name, manager_id, 1 as level
    FROM employees 
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: find direct reports
    SELECT e.id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy;
```

## Example: Organizational Chart with Path

```sql
WITH RECURSIVE org_chart AS (
    SELECT 
        id,
        name,
        manager_id,
        name::TEXT as path,
        1 as level
    FROM employees 
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id,
        e.name,
        e.manager_id,
        oc.path || ' -> ' || e.name,
        oc.level + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart ORDER BY level, name;
```

## Important Considerations

### 1. **Termination Conditions**
Always ensure your recursive query has a proper termination condition to prevent infinite loops.

### 2. **UNION vs UNION ALL**
- Use `UNION` to remove duplicates
- Use `UNION ALL` for better performance when duplicates are acceptable

### 3. **Cycle Detection**
PostgreSQL 14+ supports cycle detection:

```sql
WITH RECURSIVE graph_traversal AS (
    SELECT 
        node_id,
        ARRAY[node_id] as path,
        false as cycle
    FROM graph 
    WHERE node_id = 1
    
    UNION ALL
    
    SELECT 
        g.node_id,
        gt.path || g.node_id,
        g.node_id = ANY(gt.path)
    FROM graph g
    JOIN graph_traversal gt ON g.parent_id = gt.node_id
    WHERE NOT gt.cycle
)
SELECT * FROM graph_traversal;
```

## Common Use Cases

1. **Hierarchical data** (org charts, categories)
2. **Graph traversal** (social networks, routes)
3. **Bill of materials** (product assemblies)
4. **Data generation** (number sequences, dates)
5. **Tree structures** (file systems, comments)

## Performance Tips

- Use appropriate indexes on join columns
- Limit recursion depth when possible
- Consider using `LIMIT` in the outer query
- Monitor query execution plans

Recursive CTEs are incredibly useful for working with hierarchical data and can often replace multiple joins or application-level processing.

---

#### What are the differences between recursive and non-recursive CTE's

| Feature            | **Non-Recursive CTE**                                        | **Recursive CTE**                                                                     |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| **Definition**     | A normal CTE that runs **once** and doesn’t refer to itself. | A CTE that **calls itself** repeatedly until a condition stops it.                    |
| **Keyword**        | `WITH`                                                       | `WITH RECURSIVE`                                                                      |
| **Self-reference** | ❌ Cannot refer to itself.                                    | ✅ Refers to itself in its definition.                                                 |
| **Use case**       | Simplify complex queries or reuse a subquery result.         | Work with **hierarchical** or **tree-like** data (like org charts, categories, etc.). |
| **Execution**      | Runs one time → returns a fixed result set.                  | Runs repeatedly → builds results step-by-step.                                        |
| **Example**        | Get all users who joined in 2025.                            | Find all subordinates under a given manager.                                          |

**In short:**  
👉 Non-recursive CTE = a one-time helper query.  
👉 Recursive CTE = a looping query that grows its result each step.

##### Tags : [[1 - SQL 🦬]]