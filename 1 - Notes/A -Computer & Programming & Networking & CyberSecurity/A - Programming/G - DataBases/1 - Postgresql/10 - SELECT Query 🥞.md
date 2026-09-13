Date : 2025-09-01


### Query :

```sql
SELECT column1, column2, aggregate_function(column3)
FROM table_name
WHERE condition
GROUP BY column1, column2
HAVING aggregate_condition
WINDOW window_name AS (PARTITION BY column1 ORDER BY column2)
ORDER BY column1 ASC, column2 DESC
LIMIT 10
OFFSET 5;
```

---

### **Clause definitions in PostgreSQL context:**

1. **`SELECT`**
    
    - Columns or expressions to return.
        
    - PostgreSQL supports expressions, functions, and `DISTINCT`.
        
    - Example: `SELECT name, COUNT(*)`
        
2. **`FROM`**
    
    - Table(s) to select from; supports joins (`INNER JOIN`, `LEFT JOIN`, etc.).
        
3. **`WHERE`**
    
    - Filters rows **before** aggregation or grouping.
        
    - Example: `WHERE age > 25 AND active = TRUE`
        
4. **`GROUP BY`**
    
    - Groups rows to allow aggregation (`SUM`, `AVG`, `COUNT`).
        
    - PostgreSQL requires all selected non-aggregated columns to appear in `GROUP BY`.
        
5. **`HAVING`**
    
    - Filters groups **after aggregation**.
        
    - Example: `HAVING COUNT(*) > 5`
        
6. **`WINDOW`** _(PostgreSQL-specific)_
    
    - Defines named window specifications for window functions.
        
    - Example: `WINDOW w AS (PARTITION BY department ORDER BY salary DESC)`
        
7. **`ORDER BY`**
    
    - Sorts the final result set. Can reference columns or aliases.
        
8. **`LIMIT`**
    
    - Restricts the number of rows returned.
        
9. **`OFFSET`**
    
    - Skips a number of rows before returning results.
        

---

✅ **Extra PostgreSQL tips:**

- You can combine **window functions** with `GROUP BY` and `ORDER BY`.
    
- `DISTINCT ON (column)` is a PostgreSQL-specific feature to get the first row of each group.
    
- `RETURNING` can be used in `INSERT/UPDATE/DELETE` to get affected rows directly.
    



##### *Tags : [[1 - SQL 🥞]]