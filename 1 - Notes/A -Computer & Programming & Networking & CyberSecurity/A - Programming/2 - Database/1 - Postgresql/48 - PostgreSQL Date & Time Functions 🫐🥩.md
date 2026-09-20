


## **1. Basic Date/Time Types**

- `DATE` → YYYY-MM-DD
    
- `TIME [WITHOUT TIME ZONE]` → HH:MM:SS
    
- `TIMESTAMP [WITHOUT TIME ZONE]` → YYYY-MM-DD HH:MM:SS
    
- `TIMESTAMP WITH TIME ZONE` → stores time zone info
    

**Example:**

```sql
SELECT
    CURRENT_DATE AS today,
    CURRENT_TIME AS now_time,
    CURRENT_TIMESTAMP AS now_timestamp,
    NOW() AS now_timestamp2;
```

---

## **2. Adding/Subtracting Intervals (DATEADD replacement)**

```sql
-- Add 5 days
SELECT '2025-10-19'::date + INTERVAL '5 days';

-- Subtract 2 months
SELECT '2025-10-19'::date - INTERVAL '2 months';

-- Add 1 year, 3 months, 10 days
SELECT '2025-10-19'::date + INTERVAL '1 year 3 months 10 days';

-- Add hours/minutes/seconds
SELECT TIMESTAMP '2025-10-19 10:00:00' + INTERVAL '3 hours 30 minutes';
```

---

## **3. Date Difference (DATEDIFF replacement)**

### **3.1 Difference in days**

```sql
SELECT '2025-10-24'::date - '2025-10-19'::date AS days_diff;
-- Result: 5
```

### **3.2 Difference in months/years**

```sql
SELECT EXTRACT(YEAR FROM AGE('2025-10-24', '2023-10-19')) AS years_diff;
SELECT EXTRACT(MONTH FROM AGE('2025-10-24', '2025-01-01')) AS months_diff;
SELECT EXTRACT(DAY FROM AGE('2025-10-24', '2025-10-19')) AS days_diff;
```

### **3.3 Difference in hours/minutes/seconds**

```sql
SELECT EXTRACT(EPOCH FROM (TIMESTAMP '2025-10-24 12:00:00' - TIMESTAMP '2025-10-19 10:00:00')) AS seconds_diff;
SELECT EXTRACT(EPOCH FROM (TIMESTAMP '2025-10-24 12:00:00' - TIMESTAMP '2025-10-19 10:00:00')) / 3600 AS hours_diff;
SELECT EXTRACT(EPOCH FROM (TIMESTAMP '2025-10-24 12:00:00' - TIMESTAMP '2025-10-19 10:00:00')) / 60 AS minutes_diff;
```

---

## **4. AGE() Function**

- Returns an **interval** between two timestamps (end_date - start_date).
    

```sql
SELECT AGE('2025-10-24', '2023-10-19') AS age_interval;
-- Result: 2 years 5 days  (interval)

-- Extract specific part
SELECT EXTRACT(YEAR FROM AGE('2025-10-24', '2023-10-19')) AS years_diff;
SELECT EXTRACT(MONTH FROM AGE('2025-10-24', '2025-01-01')) AS months_diff;
SELECT EXTRACT(DAY FROM AGE('2025-10-24', '2025-10-19')) AS days_diff;
```

---

## **5. EXTRACT() Function**

- Get parts of date/time:
    

```sql
SELECT
    EXTRACT(YEAR FROM CURRENT_DATE) AS year_now,
    EXTRACT(MONTH FROM CURRENT_DATE) AS month_now,
    EXTRACT(DAY FROM CURRENT_DATE) AS day_now,
    EXTRACT(DOW FROM CURRENT_DATE) AS day_of_week,  -- 0=Sunday, 1=Monday...
    EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) AS epoch_seconds;
```

---

## **6. DATE_TRUNC()**

- Truncates a timestamp to a specific precision:
    

```sql
SELECT DATE_TRUNC('year', '2025-10-19 15:23:45'::timestamp) AS year_start;
-- 2025-01-01 00:00:00

SELECT DATE_TRUNC('month', '2025-10-19 15:23:45'::timestamp) AS month_start;
-- 2025-10-01 00:00:00

SELECT DATE_TRUNC('day', '2025-10-19 15:23:45'::timestamp) AS day_start;
-- 2025-10-19 00:00:00
```

- Can truncate to hour, minute, second, etc.
    

---

## **7. TO_CHAR() – Formatting Dates**

```sql
SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') AS formatted_date;
SELECT TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS formatted_timestamp;
SELECT TO_CHAR(CURRENT_DATE, 'Day, DD Month YYYY') AS fancy_date;
```

---

## **8. NOW(), CURRENT_DATE, CURRENT_TIME**

```sql
SELECT NOW() AS now_timestamp;       -- current timestamp
SELECT CURRENT_DATE AS today;        -- date only
SELECT CURRENT_TIME AS current_time; -- time only
```

---

## **9. Conditional Date Calculations (CASE + Date)**

```sql
SELECT
    name,
    birthdate,
    CASE
        WHEN birthdate <= CURRENT_DATE - INTERVAL '18 years' THEN 'Adult'
        ELSE 'Minor'
    END AS category
FROM students;
```

---

## **10. Aggregations with Intervals**

```sql
-- Count users created more than 30 days ago
SELECT COUNT(*) FILTER (WHERE CURRENT_DATE - created_at::date > INTERVAL '30 days') AS old_users
FROM users;

-- Sum durations in hours
SELECT SUM(EXTRACT(EPOCH FROM (end_time - start_time))/3600) AS total_hours
FROM work_logs;
```

---

## ✅ **Goat Mode Summary**

- **Add/Subtract Dates** → `+ INTERVAL` or `- INTERVAL`
    
- **Difference in Days** → subtract dates directly
    
- **Difference in Months/Years** → `AGE()` + `EXTRACT()`
    
- **Difference in Seconds/Hours** → `EXTRACT(EPOCH FROM interval)`
    
- **Truncate Dates** → `DATE_TRUNC('unit', timestamp)`
    
- **Format Dates** → `TO_CHAR(date, 'format')`
    
- **Conditional Logic** → `CASE` + interval math
    


### Tags : [[1 - SQL 🥞]]