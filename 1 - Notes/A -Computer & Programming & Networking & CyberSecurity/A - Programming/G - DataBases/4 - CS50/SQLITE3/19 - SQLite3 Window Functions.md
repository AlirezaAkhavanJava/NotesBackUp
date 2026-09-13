


Window functions in SQLite3 are analytical functions that perform calculations across a set of table rows that are related to the current row. Unlike aggregate functions (which collapse multiple rows into a single result), window functions preserve individual rows while adding calculated values.

### Key Concepts

**Window Frame**: The set of rows used for calculation relative to the current row
**Partition**: Groups rows for separate window calculations
**Ordering**: Determines the sequence of rows within each partition

---

## Common Window Functions

### Ranking Functions
- **`ROW_NUMBER()`** - Sequential row number within partition
- **`RANK()`** - Rank with gaps for ties (1,2,2,4)
- **`DENSE_RANK()`** - Rank without gaps (1,2,2,3)
- **`NTILE(n)`** - Divides rows into n roughly equal buckets

### Value Functions
- **`LAG(expr, offset, default)`** - Access previous rows
- **`LEAD(expr, offset, default)`** - Access following rows
- **`FIRST_VALUE(expr)`** - First value in window frame
- **`LAST_VALUE(expr)`** - Last value in window frame
- **`NTH_VALUE(expr, n)`** - Nth value in window frame

### Aggregate Functions (used as window functions)
- `SUM()`, `AVG()`, `COUNT()`, `MAX()`, `MIN()` - Can all be used as window functions

---

## Syntax

```sql
window_function_name(expression) OVER (
    [PARTITION BY column_list]
    [ORDER BY column_list]
    [frame_specification]
)
```

### Frame Specification
```sql
{ROWS | RANGE} BETWEEN frame_start AND frame_end
```
where frame_start/frame_end can be:
- `UNBOUNDED PRECEDING`
- `CURRENT ROW`
- `n PRECEDING`
- `n FOLLOWING`
- `UNBOUNDED FOLLOWING`

---

## Practical Examples

### Sample Data
```sql
CREATE TABLE sales (
    id INTEGER,
    region TEXT,
    salesperson TEXT,
    amount INTEGER,
    sale_date DATE
);

INSERT INTO sales VALUES
(1, 'North', 'Alice', 1000, '2024-01-15'),
(2, 'North', 'Bob', 1500, '2024-01-20'),
(3, 'South', 'Charlie', 2000, '2024-01-10'),
(4, 'North', 'Alice', 1200, '2024-02-15'),
(5, 'South', 'Charlie', 1800, '2024-02-10'),
(6, 'North', 'Bob', 900, '2024-02-20');
```

### 1. Ranking Examples
```sql
-- Rank salespeople by amount within each region
SELECT 
    region,
    salesperson,
    amount,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY amount DESC) as row_num,
    RANK() OVER (PARTITION BY region ORDER BY amount DESC) as rank,
    DENSE_RANK() OVER (PARTITION BY region ORDER BY amount DESC) as dense_rank
FROM sales;
```

### 2. Running Totals (Cumulative Sum)
```sql
-- Running total by region ordered by date
SELECT 
    region,
    salesperson,
    amount,
    sale_date,
    SUM(amount) OVER (
        PARTITION BY region 
        ORDER BY sale_date
        ROWS UNBOUNDED PRECEDING
    ) as running_total
FROM sales
ORDER BY region, sale_date;
```

### 3. Lag and Lead (Comparing with Previous/Next)
```sql
-- Compare each sale with previous sale
SELECT 
    salesperson,
    amount,
    sale_date,
    LAG(amount, 1) OVER (PARTITION BY salesperson ORDER BY sale_date) as prev_sale,
    amount - LAG(amount, 1) OVER (PARTITION BY salesperson ORDER BY sale_date) as difference,
    LEAD(amount, 1) OVER (PARTITION BY salesperson ORDER BY sale_date) as next_sale
FROM sales;
```

### 4. Moving Averages
```sql
-- 3-day moving average
SELECT 
    region,
    amount,
    sale_date,
    AVG(amount) OVER (
        PARTITION BY region 
        ORDER BY sale_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as moving_avg_3day
FROM sales;
```

### 5. Percentile and Bucketing
```sql
-- Divide into quartiles
SELECT 
    salesperson,
    amount,
    NTILE(4) OVER (ORDER BY amount DESC) as quartile
FROM sales;
```

### 6. First and Last Values
```sql
-- First and last sale amount per region
SELECT 
    region,
    salesperson,
    amount,
    FIRST_VALUE(amount) OVER (
        PARTITION BY region 
        ORDER BY sale_date
    ) as first_sale,
    LAST_VALUE(amount) OVER (
        PARTITION BY region 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_sale
FROM sales;
```

### 7. Complex Example: Percentage of Total
```sql
-- Percentage of regional total
SELECT 
    region,
    salesperson,
    amount,
    ROUND(100.0 * amount / SUM(amount) OVER (PARTITION BY region), 2) as pct_of_region,
    ROUND(100.0 * amount / SUM(amount) OVER (), 2) as pct_of_total
FROM sales
ORDER BY region, pct_of_region DESC;
```

---

## Important Notes

1. **Frame Defaults**:
   - Without `ORDER BY`: Frame is all rows in partition
   - With `ORDER BY` and no frame: Default is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`

2. **Performance**: Window functions can be expensive on large datasets; consider indexing columns used in `PARTITION BY` and `ORDER BY`

3. **`LAST_VALUE` Quirk**: Must specify the frame as `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` to get true last value in partition

4. **SQLite Version**: Window functions were introduced in SQLite 3.25.0 (2018-09-15). Check your version with `SELECT sqlite_version();`

5. **Nested Window Functions**: You can nest window function calls in expressions

6. **Named Windows**: You can define named windows for reuse:
```sql
SELECT 
    amount,
    SUM(amount) OVER win as running_total,
    AVG(amount) OVER win as moving_avg
FROM sales
WINDOW win AS (PARTITION BY region ORDER BY sale_date ROWS UNBOUNDED PRECEDING);
```

[[1 - WHAT IS SQLITE3]]