
## What is **Rolling Average**?

> **Rolling Average** = **"Average of the last N items"** — it **slides** like a moving window.

It’s like asking:  
> “What’s my **average score** in the **last 3 tests**?”

---

### Candy Story: Rolling Average (Last 3 Days)

| Day   | Candies Got | **Rolling Avg (Last 3)** |
|-------|-------------|--------------------------|
| Day 1 | 1           | 1.0 (only 1)             |
| Day 2 | 3           | 2.0 (1+3)/2              |
| Day 3 | 5           | 3.0 (1+3+5)/3             |
| Day 4 | 2           | 3.3 (3+5+2)/3 ← Day 1 gone |
| Day 5 | 4           | 3.7 (5+2+4)/3             |

See?  
- Always **3 numbers**  
- **Old one drops**, **new one comes in**  
- Average **changes smoothly**

---

### Real Numbers: Test Scores

| Day       | Score | **Rolling Avg (Last 3)** |
|-----------|-------|--------------------------|
| Mon       | 70    | 70.0                     |
| Tue       | 80    | 75.0 (70+80)/2            |
| Wed       | 90    | 80.0 (70+80+90)/3         |
| Thu       | 60    | 76.7 (80+90+60)/3         |
| Fri       | 85    | 78.3 (90+60+85)/3         |

---

### In PostgreSQL – Rolling Average (Last 3)

```sql
SELECT 
  day_name,
  score,
  AVG(score) OVER (
    ORDER BY day_name 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_avg_3
FROM test_scores;
```

**Output**:

| day_name  | score | rolling_avg_3 |
|-----------|-------|---------------|
| Mon       | 70    | 70.0          |
| Tue       | 80    | 75.0          |
| Wed       | 90    | 80.0          |
| Thu       | 60    | 76.666...     |
| Fri       | 85    | 78.333...     |

**Magic Words**:
- `AVG(score)` → average
- `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` → last 3 rows
- Result is **decimal** (like 76.7) — normal!

---

## What is **Rolling Max**?

> **Rolling Max** = **"Highest value in the last N items"**

It’s like:  
> “What’s the **highest temperature** in the **last 7 days**?”

---

### Candy Story: Rolling Max (Last 3 Days)

| Day   | Candies Got | **Rolling Max (Last 3)** |
|-------|-------------|--------------------------|
| Day 1 | 1           | 1                        |
| Day 2 | 3           | 3 (higher than 1)         |
| Day 3 | 5           | 5 (highest so far)        |
| Day 4 | 2           | 5 (5 is still in window)  |
| Day 5 | 6           | 6 (new highest!)          |

See?  
- Only cares about **highest in the bubble**  
- When old high drops → new one may appear

---

### Real Numbers: Daily High Temperature

| Day       | Temp | **Rolling Max (Last 3)** |
|-----------|------|--------------------------|
| Mon       | 22   | 22                       |
| Tue       | 25   | 25                       |
| Wed       | 28   | 28                       |
| Thu       | 20   | 28 (still in window)      |
| Fri       | 30   | 30 (new high!)            |

---

### In PostgreSQL – Rolling Max (Last 3)

```sql
SELECT 
  day_name,
  temp,
  MAX(temp) OVER (
    ORDER BY day_name 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_max_3
FROM weather;
```

**Output**:

| day_name  | temp | rolling_max_3 |
|-----------|------|---------------|
| Mon       | 22   | 22            |
| Tue       | 25   | 25            |
| Wed       | 28   | 28            |
| Thu       | 20   | 28            |
| Fri       | 30   | 30            |

---

## Full Example: All Together!

```sql
-- Sample data
WITH daily_data AS (
  SELECT 'Mon'::text AS day, 70 AS score, 22 AS temp UNION ALL
  SELECT 'Tue', 80, 25 UNION ALL
  SELECT 'Wed', 90, 28 UNION ALL
  SELECT 'Thu', 60, 20 UNION ALL
  SELECT 'Fri', 85, 30
)
SELECT 
  day,
  score,
  temp,
  
  -- Rolling Average (Last 3)
  ROUND(AVG(score) OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS roll_avg_3,
  
  -- Rolling Max (Last 3)
  MAX(temp) OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS roll_max_3

FROM daily_data;
```

**Output**:

| day | score | temp | roll_avg_3 | roll_max_3 |
|-----|-------|------|------------|------------|
| Mon | 70    | 22   | 70.00      | 22         |
| Tue | 80    | 25   | 75.00      | 25         |
| Wed | 90    | 28   | 80.00      | 28         |
| Thu | 60    | 20   | 76.67      | 28         |
| Fri | 85    | 30   | 78.33      | 30         |

---

## Summary Table

| Name             | What It Does                     | SQL Function | Window Size       |
|------------------|----------------------------------|--------------|-------------------|
| **Rolling Average** | Avg of last N                   | `AVG()`      | `2 PRECEDING` → 3 total |
| **Rolling Max**     | Highest of last N               | `MAX()`      | Same              |
| **Rolling Min**     | Lowest of last N                | `MIN()`      | Same              |
| **Rolling Sum**     | Total of last N                 | `SUM()`      | Same              |

---

## Change Window Size

| Want             | Change This Line                                 |
|------------------|--------------------------------------------------|
| Last 7 days      | `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW`       |
| Last 1 month     | Use `RANGE INTERVAL '29 days' PRECEDING` (with dates) |

---

## Real-Life Uses

| Use Case                    | Rolling Avg | Rolling Max |
|-----------------------------|-------------|-------------|
| 7-day average temperature   | Yes         |             |
| Highest stock price last week |             | Yes         |
| 3-test average grade        | Yes         |             |
| Max speed in last 5 seconds |             | Yes         |

---

## Your Turn – Try This!

1. **Change to Rolling Average of Last 2**:
   ```sql
   ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
   ```

2. **Add Rolling Min**:
   ```sql
   MIN(score) OVER (...) AS roll_min_3
   ```

3. **Make your own**:
   - Your phone battery % each hour
   - Rolling average of last 3 hours

---

## You Now Know:

| You Learned | How to Write It |
|------------|-----------------|
| Rolling Average | `AVG() OVER (ORDER BY ... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` |
| Rolling Max     | `MAX() OVER (same)` |
| Window slides   | Old drops, new comes |
| Use `ROUND(..., 2)` | To show 78.33 not 78.33333 |

---



#### Tags : [[1 - SQL 🥞]]