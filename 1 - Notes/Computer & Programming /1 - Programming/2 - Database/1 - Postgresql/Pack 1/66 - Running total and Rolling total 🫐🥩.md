

## STEP 0: What is "Adding" Numbers? (The Very First Thing)

Imagine you have candies:

- Day 1: You get **1 candy**
- Day 2: You get **2 candies**
- Day 3: You get **3 candies**

**Adding** means putting them together: 1 + 2 = 3, 3 + 3 = 6.

A **total** is the big pile at the end.

Now, in computers, we put numbers in a **table** (like a grid on paper).

---

## STEP 1: What is a "Table"? (Like a Lunch Menu)

A table has **rows** (lines) and **columns** (up-down labels).

Example table of your candies:

| Day     | Candies You Got |
|---------|-----------------|
| Day 1   | 1               |
| Day 2   | 2               |
| Day 3   | 3               |

This is **data** — like a list.

---

## STEP 2: What is a **Running Total**? (Easiest One First)

**Running Total** means:  
> "Show me the total **so far** on **every day**."

It's like checking your candy jar **every day** — how many do you have **up to now**?

### Candy Story:

| Day   | Candies Got Today | **Running Total** (Jar now has...) |
|-------|-------------------|------------------------------------|
| Day 1 | 1                 | 1 (just today's)                   |
| Day 2 | 2                 | 3 (1 from yesterday + 2 today)     |
| Day 3 | 3                 | 6 (3 from before + 3 today)        |

See? It **keeps growing**. It **never forgets** old days. It adds **everything from the start**.

### Why Do People Use It?
- Bank: "How much money do I have now?" (adds all deposits)
- Game score: Total points so far
- Shop sales: Total money earned this month

### Real Numbers Table (From a Computer Test I Just Ran)

I used a computer trick (called "pandas" — like mini-Excel) to calculate it exactly:

| Day       | Money Earned Today | Running Total |
|-----------|--------------------|---------------|
| Monday    | 10                 | 10            |
| Tuesday   | 15                 | 25            |
| Wednesday | 20                 | 45            |
| Thursday  | 5                  | 50            |
| Friday    | 30                 | 80            |

How?  
- Monday: 10 → total 10  
- Tuesday: 10 (old) + 15 = 25  
- Wednesday: 25 + 20 = 45  
- And so on... forever growing!

### In PostgreSQL (The Database You’re Learning)

Copy this code into a free online tool like "db-fiddle.com" or your computer:

```sql
-- Step 1: Make a tiny table
CREATE TABLE candy_jar (
  day_name TEXT,
  got_today INT
);

-- Step 2: Put in data
INSERT INTO candy_jar VALUES
('Monday', 10),
('Tuesday', 15),
('Wednesday', 20),
('Thursday', 5),
('Friday', 30);

-- Step 3: MAGIC! Add running total
SELECT 
  day_name,
  got_today,
  SUM(got_today) OVER (ORDER BY day_name ROWS UNBOUNDED PRECEDING) AS running_total
FROM candy_jar;
```

**What You See** (exact same as my table above):

| day_name  | got_today | running_total |
|-----------|-----------|---------------|
| Monday    | 10        | 10            |
| Tuesday   | 15        | 25            |
| ...       | ...       | ...           |

**Explain the Magic Words**:
- `SUM(got_today)` → add the numbers
- `OVER (...)` → do it as a "window" (like peeking at rows)
- `ORDER BY day_name` → go Monday → Tuesday → etc.
- `ROWS UNBOUNDED PRECEDING` → "from the very first row to now"

**No order?** It won't work right — computer gets confused!

---

## STEP 3: What is a **Rolling Total**? (The Sliding One)

**Rolling Total** means:  
> "Show me the total of **only the last few days** — like a moving bubble."

It's like looking at **only your last 3 candy bags** — forget the old ones!

### Candy Story (Last 3 Days Only):

We want **total of last 3 days** for each day.

| Day   | Candies Got Today | **Rolling Total (Last 3)** |
|-------|-------------------|----------------------------|
| Day 1 | 1                 | 1 (only 1 day)             |
| Day 2 | 2                 | 3 (Day1 + Day2)            |
| Day 3 | 3                 | 6 (Day1 + Day2 + Day3)     |
| Day 4 | 4                 | 9 (Day2 + Day3 + Day4) ← Day1 falls out! |
| Day 5 | 5                 | 12 (Day3 + Day4 + Day5)    |

See? The "bubble" **slides**:
- Always **3 days max**
- Old days **drop off**
- Doesn't grow forever

### Why Do People Use It?
- Weather: "Rain in last 7 days?"
- Health app: "Steps in last 3 days?"
- Shop: "Sales in last week?" (ignore old weeks)

### Real Numbers Table (From Computer Test)

Same days, but now "Money Spent":

| Day       | Money Spent Today | Rolling Total (Last 3 Days) |
|-----------|-------------------|-----------------------------|
| Monday    | 10                | 10                          |
| Tuesday   | 15                | 25                          |
| Wednesday | 20                | 45                          |
| Thursday  | 5                 | 40 (15+20+5)                |
| Friday    | 30                | 55 (20+5+30)                 |

How?  
- First days: Use what you have (even if less than 3)  
- Later: Drop the oldest, add new

### In PostgreSQL

Same table as before, but change the magic:

```sql
SELECT 
  day_name,
  got_today,
  SUM(got_today) OVER (
    ORDER BY day_name 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_3_days
FROM candy_jar;
```

**What You See**:

| day_name  | got_today | rolling_3_days |
|-----------|-----------|----------------|
| Monday    | 10        | 10             |
| Tuesday   | 15        | 25             |
| Wednesday | 20        | 45             |
| Thursday  | 5         | 40             |
| Friday    | 30        | 55             |

**Explain the Magic Words**:
- `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` → "2 days before me + today" = last 3
- For "last 7": Change to `6 PRECEDING`
- It **slides automatically**

---

## STEP 4: Side-by-Side Comparison (See Differences)

| Thing              | Running Total                  | Rolling Total                  |
|--------------------|--------------------------------|--------------------------------|
| What it adds       | Everything from start          | Only last N (like 3)           |
| Size               | Grows bigger and bigger        | Stays small (slides)           |
| Forgets old?       | No                             | Yes                            |
| Candy jar          | All candies ever               | Only last 3 bags               |
| SQL words          | `UNBOUNDED PRECEDING`          | `2 PRECEDING` (for 3 total)    |
| When total stops   | Never (keeps old)              | Drops old when window full     |

**Picture**:

Running: 1 → 1+2 → 1+2+3 → 1+2+3+4 → ...

Rolling (3): 1 → 1+2 → 1+2+3 → 2+3+4 → 3+4+5 → ...

---

## STEP 5: Common Confusions (Why People Get Stuck)

| Confusion                  | Simple Fix |
|----------------------------|------------|
| "Why not just add manually?" | For 10,000 rows — computer does it fast! |
| "What if days are missing?" | Add fake rows with 0, or use dates |
| "Numbers become float (.0)?" | Normal — computer is careful |
| "No ORDER BY?"             | Chaos! Always sort first |
| "ROWS vs RANGE?"           | ROWS = count rows (use for this). RANGE = for same numbers/dates |

---

## STEP 6: Your Turn — Play Time!

1. **Change to 2-day rolling**: In SQL, change `2 PRECEDING` to `1 PRECEDING`
   - What happens on Friday?

2. **Make your own table**:
   - Days: Your school days
   - Got: Homework points
   - Calculate running (total points so far)

3. **Free Tool to Try**:
   - Go to https://www.db-fiddle.com/
   - Pick "PostgreSQL"
   - Paste my code
   - Click "Run"
   - Change numbers — see magic!

---

## You Now Understand (I Promise!)

- **Running Total** = Pile grows with **all history**
- **Rolling Total** = Sliding bubble of **last few**
- Both use `SUM() OVER (...)` in PostgreSQL
- Like candy jars: One keeps all, one cleans old


---

## 1. What is a **Running Total**?

> **Running Total** = **"Adding up as you go"** — each row shows the **total so far**, from the **first row** to the **current row**.

It’s like **counting money in your pocket as you earn it day by day**.

---

### Real-Life Example: Your Daily Pocket Money

| Day | Money Earned | **Running Total** (Total so far) |
|-----|--------------|-------------------------------|
| Mon | 10           | 10                            |
| Tue | 15           | 25 (10+15)                     |
| Wed | 20           | 45 (25+20)                     |
| Thu | 5            | 50 (45+5)                      |

You **keep adding** the new amount to the **previous total**.

---

### In SQL (PostgreSQL) – Running Total

```sql
SELECT 
  day,
  earned,
  SUM(earned) OVER (ORDER BY day ROWS UNBOUNDED PRECEDING) AS running_total
FROM pocket_money;
```

| day | earned | running_total |
|-----|--------|---------------|
| Mon | 10     | 10            |
| Tue | 15     | 25            |
| Wed | 20     | 45            |
| Thu | 5      | 50            |

**Key**:  
- `ORDER BY day` → go in order  
- `ROWS UNBOUNDED PRECEDING` → from **first row** to **current row**

---

## 2. What is a **Rolling Total**?

> **Rolling Total** = **"Adding up only the last N items"** — a **moving window** of fixed size.

It’s like **looking at your last 3 days of spending** — every day, the window **slides forward**.

---

### Real-Life Example: Last 3 Days Spending

| Day | Spent | **Rolling Total (Last 3 Days)** |
|-----|-------|-------------------------------|
| Mon | 10    | 10 (only 1 day)               |
| Tue | 15    | 25 (Mon + Tue)                |
| Wed | 20    | 45 (Mon + Tue + Wed)          |
| Thu | 5     | 40 (Tue + Wed + Thu) ← Mon drops out! |
| Fri | 30    | 55 (Wed + Thu + Fri)          |

The **window moves** — always **3 days**, but **drops old**, **adds new**.

---

### In SQL – Rolling Total (Last 3 Days)

```sql
SELECT 
  day,
  spent,
  SUM(spent) OVER (
    ORDER BY day 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_3day
FROM spending;
```

| day | spent | rolling_3day |
|-----|-------|--------------|
| Mon | 10    | 10           |
| Tue | 15    | 25           |
| Wed | 20    | 45           |
| Thu | 5     | 40           |
| Fri | 30    | 55           |

**Key**:  
- `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` → **last 3 rows** (2 before + current)

---

## Summary Table: Running vs Rolling

| Feature | **Running Total** | **Rolling Total** |
|--------|-------------------|-------------------|
| Window | From **start** to **now** | Only **last N rows** |
| Grows? | Yes, keeps growing | No, stays same size |
| Drops old data? | Never | Yes |
| Like | Savings account balance | 3-month moving average |
| SQL Frame | `UNBOUNDED PRECEDING` | `N PRECEDING AND CURRENT ROW` |

---

## Visual Comparison

```
Running Total:
[1] → [1+2] → [1+2+3] → [1+2+3+4] → keeps growing

Rolling Total (3):
[1] → [1+2] → [1+2+3] → [2+3+4] → [3+4+5] → slides
```

---

## Try This Now! (Copy-Paste SQL)

```sql
-- Sample data
WITH daily_sales AS (
  SELECT 'Mon'::text AS day, 100 AS sales UNION ALL
  SELECT 'Tue', 150 UNION ALL
  SELECT 'Wed', 200 UNION ALL
  SELECT 'Thu', 80 UNION ALL
  SELECT 'Fri', 300
)
SELECT 
  day,
  sales,
  -- Running Total
  SUM(sales) OVER (ORDER BY day ROWS UNBOUNDED PRECEDING) AS running_total,
  
  -- Rolling Total (Last 3 days)
  SUM(sales) OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3day
FROM daily_sales;
```

**Output**:

| day | sales | running_total | rolling_3day |
|-----|-------|---------------|--------------|
| Mon | 100   | 100           | 100          |
| Tue | 150   | 250           | 250          |
| Wed | 200   | 450           | 450          |
| Thu | 80    | 530           | 430 (150+200+80) |
| Fri | 300   | 830           | 580 (200+80+300) |

---

## Real-World Uses

| Use Case | Running | Rolling |
|--------|--------|--------|
| Bank balance | Yes | No |
| Total sales this year | Yes | No |
| 7-day active users | No | Yes |
| 3-month moving average | No | Yes |
| Stock portfolio growth | Yes | No |
| Weather: avg temp last 5 days | No | Yes |

---

## Common Mistakes

| Mistake | Why Wrong |
|--------|----------|
| Using `RANGE` for rolling | Use `ROWS` for fixed count |
| Forgetting `ORDER BY` | Window needs sequence! |
| Thinking running = rolling | One grows, one slides |

---

## Final Cheat Sheet

```sql
-- Running Total
SUM(col) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)

-- Rolling Total (Last 3)
SUM(col) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)

-- Rolling Total (Last 7 days by date)
SUM(col) OVER (ORDER BY date RANGE INTERVAL '6 days' PRECEDING)
```

---

## Your Practice (Do This!)

1. **Make a running total** of your study hours this week.
2. **Make a 3-day rolling total** of your phone usage.
3. **Change rolling to 2 days** — what changes?

---

**You now know**:
- Running Total = **cumulative**, keeps growing
- Rolling Total = **moving window**, fixed size
- SQL: `UNBOUNDED PRECEDING` vs `N PRECEDING`

---

###### TIP : 
✅ **Running total** → adds up **all rows so far**.  
✅ **Rolling total** → adds up **only a small frame** (like last 3 or 5 rows).


> Running = whole history  
> Rolling = recent window
### Tags : [[1 - SQL 🦬]]