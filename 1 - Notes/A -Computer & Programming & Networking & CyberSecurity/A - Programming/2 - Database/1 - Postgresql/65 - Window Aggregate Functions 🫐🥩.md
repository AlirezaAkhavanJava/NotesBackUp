

## What Are Window Aggregate Functions?

You already know **normal aggregate functions**:

```sql
SUM(), AVG(), COUNT(), MAX(), MIN()
```

They **collapse** many rows into **one**:

```sql
SELECT SUM(score) FROM students;  -- One number
```

But **Window Aggregate Functions** do this:

> "Do the SUM/AVG/COUNT... but **keep all the original rows**!"

They use `OVER()` to turn a normal aggregate into a **window function**.

---

## Simple Example: Total Score for Each Student (Same for All)

```sql
SELECT 
  name, 
  score,
  SUM(score) OVER () as total_score
FROM students;
```

| name   | score | total_score |
|--------|-------|-------------|
| Ali    | 80    | 335         |
| Sara   | 90    | 335         |
| Khan   | 70    | 335         |
| Ayesha | 95    | 335         |

`OVER ()` = empty window → **entire table**  
So `SUM(score) OVER ()` = **grand total**, repeated for every row.

**Use case**: Show each sale + total sales of the day.

---

## PART 1: The 3 Types of Window Aggregates

| Type | What it does | Example |
|------|--------------|--------|
| **No ORDER** | Same value for all rows in partition | `SUM() OVER (PARTITION BY class)` |
| **With ORDER** | Running / cumulative | `SUM() OVER (ORDER BY date)` |
| **With Frame** | Moving window | `AVG() OVER (ORDER BY date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)` |

---

## PART 2: 1. No ORDER → Group Total (Like GROUP BY but keeps rows)

```sql
SELECT 
  name, class, score,
  SUM(score) OVER (PARTITION BY class) as class_total
FROM students;
```

**Data**:

| name   | class | score |
|--------|-------|-------|
| Ali    | A     | 80    |
| Sara   | A     | 90    |
| Khan   | B     | 70    |
| Ayesha | B     | 95    |

**Output**:

| name   | class | score | class_total |
|--------|-------|-------|-------------|
| Ali    | A     | 80    | 170         |
| Sara   | A     | 90    | 170         |
| Khan   | B     | 70    | 165         |
| Ayesha | B     | 95    | 165         |

**Perfect for**: "Each student’s score + their class average"

---

## PART 3: 2. With ORDER → Running Total (Cumulative)

```sql
SELECT 
  name, score,
  SUM(score) OVER (ORDER BY score) as running_total
FROM students;
```

> If two students have the same `mark` (say 80), `RANGE` treats all rows with that value as the **same “current row”**.

**Output** (ordered by score):

| name   | score | running_total |
|--------|-------|---------------|
| Khan   | 70    | 70            |
| Ali    | 80    | 150           |
| Sara   | 90    | 240           |
| Ayesha | 95    | 335           |

This is **cumulative sum** — adds up as you go.

**Default frame**: `RANGE UNBOUNDED PRECEDING AND CURRENT ROW`  
→ from start to current row.

---

## PART 4: 3. With Frame → Moving Window (Like Excel)

### Moving Average (3-row window)

```sql
SELECT 
  name, score,
  AVG(score) OVER (
    ORDER BY score 
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) as moving_avg
FROM students 
ORDER BY score;
```

**How it works**:

| name   | score | Window rows | Calculation |
|--------|-------|-------------|-----------|
| Khan   | 70    | 70, 80      | (70+80)/2 = **75** |
| Ali    | 80    | 70,80,90    | (70+80+90)/3 = **80** |
| Sara   | 90    | 80,90,95    | (80+90+95)/3 = **88.3** |
| Ayesha | 95    | 90,95       | (90+95)/2 = **92.5** |

**Use case**: Smooth stock prices, sales trends.

---

## All Common Window Aggregates

| Function | Normal Use | Window Use |
|--------|-----------|-----------|
| `COUNT()` | Total rows | `COUNT() OVER (PARTITION BY dept)` → employees per dept |
| `SUM()` | Total | Running total, group total |
| `AVG()` | Average | Moving average |
| `MAX()` | Highest | Highest so far |
| `MIN()` | Lowest | Lowest in window |

---

## Real-Life Example: Sales Dashboard

```sql
SELECT 
  sale_date,
  amount,
  -- 1. Daily total
  SUM(amount) OVER (PARTITION BY sale_date) as daily_total,
  
  -- 2. Running total this month
  SUM(amount) OVER (
    ORDER BY sale_date 
    ROWS UNBOUNDED PRECEDING
  ) as running_total,
  
  -- 3. 7-day moving average
  AVG(amount) OVER (
    ORDER BY sale_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as avg_7day
FROM sales;
```

One query → full report!

---

## Advanced: Using RANGE with Aggregates

```sql
-- All sales within ±$50 of current sale
SUM(amount) OVER (
  ORDER BY amount 
  RANGE BETWEEN 50 PRECEDING AND 50 FOLLOWING
) as similar_sales
```

**Only works** if `ORDER BY` is **number or date**.

---

## Common Patterns (Copy-Paste Ready!)

### 1. Rank students
```sql
RANK() OVER (ORDER BY score DESC)
```

### 2. Class rank
```sql
RANK() OVER (PARTITION BY class ORDER BY score DESC)
```

### 3. % of total
```sql
score * 100.0 / SUM(score) OVER () as percent_of_total
```

### 4. Difference from average
```sql
score - AVG(score) OVER (PARTITION BY class) as vs_class_avg
```

---

## Summary Table

| Goal | Code |
|------|------|
| Total per group | `SUM() OVER (PARTITION BY group)` |
| Running total | `SUM() OVER (ORDER BY col)` |
| Moving avg (3) | `AVG() OVER (ORDER BY col ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)` |
| % of total | `col / SUM(col) OVER () * 100` |
| Rank in group | `RANK() OVER (PARTITION BY group ORDER BY col)` |

---

## Try This Now!

```sql
-- Create sample
CREATE TABLE sales (
  id SERIAL,
  sale_date DATE,
  amount NUMERIC
);

INSERT INTO sales VALUES
('2025-01-01', 100),
('2025-01-02', 150),
('2025-01-03', 120),
('2025-01-04', 180);

-- See magic
SELECT 
  sale_date,
  amount,
  SUM(amount) OVER (ORDER BY sale_date) as running,
  AVG(amount) OVER (ORDER BY sale_date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) as mov_avg
FROM sales;
```

---

## You Now Know:

- Window aggregates = **aggregate + keep rows**
- `OVER ()` = whole table
- `PARTITION BY` = group
- `ORDER BY` = sequence
- `ROWS` / `RANGE` = frame
- Real uses: running totals, moving averages, rankings

---



### Tags : [[1 - SQL 🥞]]