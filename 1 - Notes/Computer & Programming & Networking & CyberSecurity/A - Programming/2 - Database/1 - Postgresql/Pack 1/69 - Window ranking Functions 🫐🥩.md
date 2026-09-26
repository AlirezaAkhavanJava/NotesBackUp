

> A **window ranking function** in SQL (specifically PostgreSQL) is a **non-aggregate analytic function** that assigns a **positional value** (rank, number, or percentile) to each row **within a defined window (partition)** of a query result, based on a specified **ordering**.

---



### 📊 Conceptually

Think of a _window_ as a “movable lens” over your dataset.  
Ranking functions look through that lens and assign each row a rank or percentile according to its place among its peers.

---

### ⚙️ Core Properties

- **Partitioning:** divides data into logical groups (like sub-tables).
    
- **Ordering:** defines sequence within each partition.
    
- **Frame:** optionally restricts which rows are visible to the function (e.g., preceding/following).
    
- **Output:** numeric value expressing the row’s order, rank, or distribution.
    

---

### 🧩 Examples of Window Ranking Functions

|Category|Function|Description|
|---|---|---|
|Positional|`ROW_NUMBER()`|Sequential index per partition|
|Ordinal|`RANK()`, `DENSE_RANK()`|Relative order (with or without gaps)|
|Quantile|`NTILE(n)`|Bucket segmentation|
|Statistical|`PERCENT_RANK()`, `CUME_DIST()`|Percentile / distribution ratio|

## 🧩 Window Ranking Functions — Deep Dive

### 1️⃣ `ROW_NUMBER()`

**Purpose:** Assigns a unique, sequential integer to each row within a window partition.

**Mechanics:**

- Deterministic _only_ if `ORDER BY` is fully defined.
    
- Ignores ties — every row gets a distinct number.
    
- Computed after filtering (`WHERE`) but before final aggregation (`GROUP BY`).
    
- Uses the internal `WindowAgg` node in the query plan.
    

**Example:**

```sql
SELECT id, name, mark,
       ROW_NUMBER() OVER (PARTITION BY country ORDER BY mark DESC) AS row_num
FROM students;
```

**Use Case:**  
When you need a **stable, unique ordering**, e.g., pick the _top N rows per group_:

```sql
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY country ORDER BY mark DESC) AS rn
  FROM students
) t
WHERE rn <= 3;
```

**Senior Insight:**  
`ROW_NUMBER()` is the cleanest way to implement **“first N per group”** patterns efficiently. It avoids self-joins and performs linearly with window size.

---

### 2️⃣ `RANK()`

**Purpose:** Assigns the same rank to rows with identical ordering keys but **leaves gaps** in the ranking sequence.

**Mechanics:**

- Rank increases by the **count of rows in the previous rank**.
    
- Two identical marks share a rank; the next rank skips numbers.
    
- The computation involves checking peer groups (rows with equal sort keys).
    

**Example:**

```sql
SELECT name, mark,
       RANK() OVER (ORDER BY mark DESC) AS rank
FROM students;
```

**Use Case:**  
When you need **statistical or leaderboard accuracy**, where gaps in rank must reflect ties (e.g., “two users tied for 1st → next rank is 3rd”).

**Senior Insight:**  
`RANK()` preserves the **true ordinal position** in the ordered set. This matters in analytical pipelines (BI, reporting) where relative rank distributions are meaningful.

---

### 3️⃣ `DENSE_RANK()`

**Purpose:** Same as `RANK()`, but **without rank gaps** after ties.

**Mechanics:**

- Maintains a continuous sequence of integers.
    
- Internally equivalent to `RANK()` but increments rank counter differently — no gaps.
    

**Example:**

```sql
SELECT name, mark,
       DENSE_RANK() OVER (ORDER BY mark DESC) AS dense_rank
FROM students;
```

**Use Case:**  
When your downstream systems (e.g., dashboards or scoring models) expect **dense, contiguous rank categories**, such as tier levels (Top 1, 2, 3).

**Senior Insight:**  
`DENSE_RANK()` is best for **categorical ranking** — mapping continuous metrics to tiered groups.  
It also tends to be slightly faster than `RANK()` since rank gaps don’t need to be calculated explicitly.

---

### 4️⃣ `NTILE(n)`

**Purpose:** Distributes rows into `n` **approximately equal buckets** based on ordering.

**Mechanics:**

- Internally calculates bucket boundaries using integer division:  
    `(row_number - 1) * n / total_rows + 1`
    
- Buckets may differ by 1 row due to uneven division.
    

**Example:**

```sql
SELECT name, mark,
       NTILE(4) OVER (ORDER BY mark DESC) AS quartile
FROM students;
```

**Use Case:**  
Segmenting data for **quantile analysis**, **AB testing**, or **percentile grouping** (e.g., top 25%, bottom 25%).

**Senior Insight:**  
`NTILE()` is effectively a built-in quantile estimator for ordered datasets — ideal for analytical segmentation, but not for precise percentile math (use `PERCENT_RANK()` or `CUME_DIST()` for that).

---

## 🧠 Expert Notes

- All ranking functions are **non-aggregate**, evaluated per row.
    
- They can coexist with `PARTITION BY` to provide group-local rankings without collapsing rows.
    
- `ORDER BY` inside the window clause defines _evaluation order_, independent of global query order.
    
- Performance scales roughly **O(n log n)** due to internal sort — consider pre-sorting or partitioning strategies for large datasets.
    
- Common optimization: materialize the base ordering into a **CTE** or **indexed view**.
    


---

## 📊 5️⃣ `PERCENT_RANK()`

**Purpose:**  
Calculates the **relative rank** of each row as a fraction between `0` and `1`, showing how far along the ordered dataset that row is.

**Formula:**  
[  
\text{PERCENT_RANK} = \frac{\text{RANK} - 1}{\text{total rows} - 1}  
]

**Mechanics:**

- Always returns `0` for the first row.
    
- Returns `1` for the last row (if there’s more than one row).
    
- Identical ordering keys (ties) get the same percent rank.
    
- Computed after `RANK()` within the same window context.
    

**Example:**

```sql
SELECT name, mark,
       PERCENT_RANK() OVER (ORDER BY mark DESC) AS percent_rank
FROM students;
```

**Use Case:**  
Used in **statistical normalization**, **score scaling**, and **percentile-based cutoffs**.  
For example: filtering the **top 10%** of students.

```sql
SELECT * FROM (
  SELECT *, PERCENT_RANK() OVER (ORDER BY mark DESC) AS pr
  FROM students
) t
WHERE pr <= 0.10;
```

**Senior Insight:**  
`PERCENT_RANK()` is a **non-linear rank estimator** — not a true percentile. It measures **position**, not **distribution density**.  
In analytics, it’s used for **percentile thresholds** where absolute value gaps don’t matter — only position in the order does.

---

## 📈 6️⃣ `CUME_DIST()`

**Purpose:**  
Computes the **cumulative distribution** of rows up to and including the current row — i.e., the proportion of rows with values **less than or equal** to the current one.

**Formula:**  
[  
\text{CUME_DIST} = \frac{\text{number of rows with value ≤ current}}{\text{total rows}}  
]

**Mechanics:**

- Values range between `>0` and `1`.
    
- Unlike `PERCENT_RANK()`, it doesn’t depend on rank gaps — it directly counts all preceding rows.
    
- Always **non-decreasing** through the ordered set.
    

**Example:**

```sql
SELECT name, mark,
       CUME_DIST() OVER (ORDER BY mark DESC) AS cume_dist
FROM students;
```

**Use Case:**  
Ideal for **percentile classification** — e.g.,  
assigning students into 90th percentile or identifying bottom 25%.

**Senior Insight:**  
`CUME_DIST()` models **empirical cumulative distribution (ECDF)** — foundational for data normalization and statistical modeling.  
It’s often used before z-score transformations or for percentile-based segmentation.

---

## 🧠 Summary Table (for reference)

|Function|Type|Handles Ties|Gaps?|Range|Typical Use|
|---|---|---|---|---|---|
|`ROW_NUMBER()`|Positional|No|N/A|Integers|Top-N per group|
|`RANK()`|Ordinal|Yes|Yes|Integers|Leaderboards, analytics|
|`DENSE_RANK()`|Ordinal|Yes|No|Integers|Tier grouping|
|`NTILE(n)`|Quantile|N/A|N/A|1..n|Segmentation|
|`PERCENT_RANK()`|Relative|Yes|Yes|0–1|Percentile position|
|`CUME_DIST()`|Cumulative|Yes|No|0–1|Percentile distribution|

---

**Pro tip (senior-level):**  
When designing analytical queries:

- Use `CUME_DIST()` when your thresholds depend on **value distribution** (true percentiles).
    
- Use `PERCENT_RANK()` when you care about **position ranking**, not statistical spread.
    
- Both are **non-deterministic** if `ORDER BY` lacks unique keys — always include a tie-breaker column for reproducibility.
    

---




##### Tags : [[1 - SQL 🦬]]