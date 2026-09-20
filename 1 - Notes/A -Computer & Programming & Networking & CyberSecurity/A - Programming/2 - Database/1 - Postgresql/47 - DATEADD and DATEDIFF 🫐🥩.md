

# **SQL / PostgreSQL: DATEADD and DATEDIFF**

## **1. Overview**

- **`DATEADD`**: Adds a specific interval to a date/time.
    
- **`DATEDIFF`**: Calculates the difference between two dates/times in a specified unit (days, months, years, etc.).
    

> ⚠️ PostgreSQL doesn’t have `DATEADD` and `DATEDIFF` functions like SQL Server. It uses **interval arithmetic** and functions like `AGE()` or subtraction. I’ll explain both the SQL Server style and the PostgreSQL way.

---

## **2. DATEADD**

### **2.1 SQL Server Syntax**

```sql
DATEADD(datepart, number, date)
```

- `datepart`: part of the date to add (`year`, `month`, `day`, `hour`, `minute`, `second`, etc.)
    
- `number`: integer (can be negative to subtract)
    
- `date`: original date value
    

**Example (SQL Server):**

```sql
SELECT DATEADD(day, 5, '2025-10-19') AS new_date;
-- Result: 2025-10-24
```

```sql
SELECT DATEADD(month, -2, '2025-10-19') AS new_date;
-- Result: 2025-08-19
```

---

### **2.2 PostgreSQL Equivalent**

PostgreSQL uses **interval arithmetic**:

```sql
-- Add days
SELECT '2025-10-19'::date + INTERVAL '5 days';

-- Subtract months
SELECT '2025-10-19'::date - INTERVAL '2 months';

-- Add years
SELECT '2025-10-19'::date + INTERVAL '1 year';
```

- You can also add fractions: `'1.5 hours'` or `'2.25 days'`.
    
- Works with `TIMESTAMP` as well.
    

```sql
SELECT TIMESTAMP '2025-10-19 10:00:00' + INTERVAL '3 hours';
-- Result: 2025-10-19 13:00:00
```

---

## **3. DATEDIFF**

### **3.1 SQL Server Syntax**

```sql
DATEDIFF(datepart, start_date, end_date)
```

- Returns the difference between two dates in the specified unit.
    

**Example (SQL Server):**

```sql
SELECT DATEDIFF(day, '2025-10-19', '2025-10-24') AS days_diff;
-- Result: 5

SELECT DATEDIFF(month, '2025-01-01', '2025-10-19') AS months_diff;
-- Result: 9
```

---

### **3.2 PostgreSQL Equivalent**

PostgreSQL doesn’t have `DATEDIFF` but you can:

#### **3.2.1 Subtract Dates**

```sql
SELECT '2025-10-24'::date - '2025-10-19'::date AS days_diff;
-- Result: 5 (integer)
```

- Direct subtraction returns the number of **days**.
    

#### **3.2.2 Use EXTRACT() with AGE()**

```sql
SELECT EXTRACT(YEAR FROM AGE('2025-10-24', '2023-10-19')) AS years_diff;
SELECT EXTRACT(MONTH FROM AGE('2025-10-24', '2025-01-01')) AS months_diff;
SELECT EXTRACT(DAY FROM AGE('2025-10-24', '2025-10-19')) AS days_diff;
```

- `AGE(timestamp1, timestamp2)` → interval
    
- `EXTRACT(part FROM interval)` → numeric value
    

#### **3.2.3 Interval Casting for Hours, Minutes, Seconds**

```sql
SELECT EXTRACT(EPOCH FROM (TIMESTAMP '2025-10-24 12:00:00' - TIMESTAMP '2025-10-19 10:00:00')) / 3600 AS hours_diff;
```

- `EXTRACT(EPOCH FROM interval)` → seconds
    
- Divide by 3600 for hours, 60 for minutes.
    

---

## **4. Key Notes**

1. **DATEADD vs interval:** PostgreSQL uses intervals (`+ INTERVAL`) instead of `DATEADD`.
    
2. **DATEDIFF vs subtraction:** For days, just subtract dates. For months/years, use `AGE()` + `EXTRACT()`.
    
3. **Negative values:** Both systems handle negative numbers for subtraction.
    
4. **Time-sensitive differences:** Use `TIMESTAMP` for precise hour/minute calculations.
    

---

## **5. Advanced Usage in PostgreSQL**

- **Add multiple intervals at once:**
    

```sql
SELECT '2025-10-19'::date + INTERVAL '1 year 2 months 3 days';
-- Result: 2026-12-22
```

- **Conditional date differences (like CASE + DATEDIFF):**
    

```sql
SELECT 
    CASE 
        WHEN start_date < end_date THEN end_date - start_date
        ELSE start_date - end_date
    END AS diff_days
FROM my_table;
```

- **Counting intervals in aggregation:**
    

```sql
SELECT 
    COUNT(*) FILTER (WHERE current_date - created_at > INTERVAL '30 days') AS old_records
FROM my_table;
```

---

✅ **TL;DR Goat Mode Summary:**

- `DATEADD` → PostgreSQL: `+ INTERVAL 'n unit'`
    
- `DATEDIFF` → PostgreSQL: subtract dates or use `AGE()` + `EXTRACT()`
    
- PostgreSQL = **intervals are king**; direct `DATEDIFF`/`DATEADD` don’t exist.
    
- Works for days, months, years, hours, minutes, seconds, or any combo.
    



### Tags : [[1 - SQL 🥞]]