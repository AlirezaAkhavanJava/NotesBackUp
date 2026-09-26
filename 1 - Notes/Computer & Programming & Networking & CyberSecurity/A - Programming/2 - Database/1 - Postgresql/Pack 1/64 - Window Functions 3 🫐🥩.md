


## PART 1: What is a Window Function? (Super Basic)

Imagine you have a **list of students and their scores**:

| name  | score |
|-------|-------|
| Ali   | 80    |
| Sara  | 90    |
| Khan  | 70    |
| Ayesha| 95    |

Now, you want to **rank** them, or show **running total**, or **compare each to average** — but **without losing the original rows**.

Normal SQL: `GROUP BY` → gives summary, loses details.  
**Window Function**: keeps all rows + adds smart calculations!

```sql
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank
FROM students;
```

**Output**:

| name  | score | rank |
|-------|-------|------|
| Ayesha| 95    | 1    |
| Sara  | 90    | 2    |
| Ali   | 80    | 3    |
| Khan  | 70    | 4    |

See? All rows are still there, but we added a **rank** using `OVER()`.

That `OVER()` is the **window** — it defines "over which rows" we calculate.

---

## PART 2: The 3 Parts of a Window Function

Every window function has:

```sql
FUNCTION() OVER ( [PARTITION BY ...] [ORDER BY ...] [FRAME] )
```

Let’s break it:

| Part | What it does | Example |
|------|--------------|--------|
| `PARTITION BY` | Splits data into groups (like GROUP BY) | `PARTITION BY class` |
| `ORDER BY` | Orders rows inside each partition | `ORDER BY score DESC` |
| `FRAME` | Says: "From current row, look back/forward how many?" | `ROWS BETWEEN 1 PRECEDING AND CURRENT ROW` |

---

## PART 3: What is the "Frame Clause"?

Think of the **frame** like a **moving window on a train**.

You’re looking out the window and asking:

> "Give me the average of the last 2 stations + this one."

That’s the **frame** — it defines **which rows** are included in the calculation **for the current row**.

By default: `RANGE UNBOUNDED PRECEDING AND CURRENT ROW`  
But we can change it!

---

## PART 4: ROWS vs RANGE (The Big Confusion!)

This is the **main thing** people get stuck on. Let’s make it **crystal clear**.

### Think of your data as a **numbered list**:

| Row# | name  | score |
|------|-------|-------|
| 1    | Khan  | 70    |
| 2    | Ali   | 80    |
| 3    | Sara  | 90    |
| 4    | Ayesha| 95    |

We ordered by score.

---

### `ROWS` = "Count physical rows"

> "Take 2 rows before me"

```sql
SUM(score) OVER (ORDER BY score ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
```

| Row | Frame includes | Calculation |
|-----|----------------|-----------|
| 1 (Khan) | Only row 1 | 70 |
| 2 (Ali)  | Row 1 + Row 2 | 70 + 80 = **150** |
| 3 (Sara) | Row 2 + Row 3 | 80 + 90 = **170** |

**ROWS** = count **positions**, even if values are same.

---

### `RANGE` = "Look at values, not positions"

> "Take all rows where score is within 10 points of me"

```sql
SUM(score) OVER (ORDER BY score RANGE BETWEEN 10 PRECEDING AND CURRENT ROW)
```

Now imagine two students have **same score**:

| Row# | name  | score |
|------|-------|-------|
| 1    | Khan  | 70    |
| 2    | Ali   | 80    |
| 3    | Sara  | 80    |
| 4    | Ayesha| 95    |

For **Sara (row 3, score 80)**:

- `RANGE BETWEEN 10 PRECEDING AND CURRENT ROW` → scores from **70 to 80**
- So includes: Khan (70), Ali (80), Sara (80) → **70 + 80 + 80 = 230**

Even though Ali is 1 row back, and Khan is 2 rows back — **RANGE cares about value difference**, not row position.

---

## Summary: ROWS vs RANGE

| Feature | ROWS | RANGE |
|--------|------|-------|
| Based on | Physical position | Value difference |
| Good for | Running totals, moving averages | Same-value groups, financial data |
| Example | Last 3 sales | All sales within $50 |

---

## PART 5: Frame Clause Syntax (All Options)

```sql
ROWS BETWEEN <start> AND <end>
```

| Option | Meaning |
|--------|--------|
| `UNBOUNDED PRECEDING` | From first row in partition |
| `CURRENT ROW` | This row |
| `UNBOUNDED FOLLOWING` | To last row |
| `n PRECEDING` | n rows before |
| `n FOLLOWING` | n rows after |

---

## REAL EXAMPLE: Running Total

```sql
SELECT 
  name,
  score,
  SUM(score) OVER (ORDER BY score ROWS UNBOUNDED PRECEDING) as running_total
FROM students;
```

**Output**:

| name  | score | running_total |
|-------|-------|---------------|
| Khan  | 70    | 70            |
| Ali   | 80    | 150           |
| Sara  | 90    | 240           |
| Ayesha| 95    | 335           |

This is **cumulative sum** — super useful!

---

## PART 6: Moving Average (3-row window)

```sql
SELECT 
  name, score,
  AVG(score) OVER (
    ORDER BY score 
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) as moving_avg
FROM students;
```

**How it works**:

| name  | Frame | Avg |
|-------|-------|-----|
| Khan  | Only Khan + Ali | (70+80)/2 = **75** |
| Ali   | Khan + Ali + Sara | (70+80+90)/3 = **80** |
| Sara  | Ali + Sara + Ayesha | (80+90+95)/3 = **88.3** |
| Ayesha| Sara + Ayesha | (90+95)/2 = **92.5** |

Perfect for smoothing data!

---

## PART 7: Advanced: RANGE with Dates (Real World!)

Imagine sales per day:

| date       | sales |
|------------|-------|
| 2025-01-01 | 100   |
| 2025-01-03 | 150   |
| 2025-01-07 | 200   |

You want **total sales in last 7 days** for each day.

```sql
SUM(sales) OVER (
  ORDER BY date 
  RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
)
```

For Jan 7:
- Looks back 7 days → includes Jan 1, Jan 3, Jan 7 → **100 + 150 + 200 = 450**

Even though they are not consecutive rows — **RANGE uses date difference**.

---

## PART 8: Common Mistakes

| Mistake | Why Wrong |
|--------|----------|
| Using `RANGE` with non-numeric order | Only works with numbers/dates |
| Forgetting `ORDER BY` | Frame needs order! |
| Using `ROWS` when you want same-value groups | Use `RANGE` instead |

---

## FINAL CHEAT SHEET

| Goal | Use |
|------|-----|
| Running total | `ROWS UNBOUNDED PRECEDING` |
| Moving average (n rows) | `ROWS BETWEEN n PRECEDING AND n FOLLOWING` |
| Total of same scores | `RANGE UNBOUNDED PRECEDING` |
| Last 7 days sales | `RANGE INTERVAL '7 days' PRECEDING` |

---

## Try This Query (Copy-Paste!)

```sql
-- Sample data
WITH sales AS (
  SELECT '2025-01-01'::date as date, 100 as amount UNION ALL
  SELECT '2025-01-03'::date, 150 UNION ALL
  SELECT '2025-01-07'::date, 200 UNION ALL
  SELECT '2025-01-10'::date, 300
)
SELECT 
  date, amount,
  SUM(amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING) as running_rows,
  SUM(amount) OVER (ORDER BY date RANGE UNBOUNDED PRECEDING) as running_range
FROM sales;
```

See the difference? (Should be same here because dates are unique)

---

## You Now Know:

- Window functions keep all rows
- `OVER()` defines the window
- `PARTITION BY` = groups
- `ORDER BY` = sequence
- **Frame clause** = which rows to include
- `ROWS` = count rows
- `RANGE` = value-based
- Real examples: running total, moving avg, date ranges

---



### Tags : [[1 - SQL 🦬]]