
### Understanding Integer-based vs Percentage-based Ranking

---

## 1️⃣ What Are Window Ranking Functions?

Window ranking functions in SQL are **analytic (non-aggregate) functions** that assign each row a **rank or relative position** based on a defined ordering — all without collapsing the rows.

They are evaluated **over a “window”** of data defined by:

```sql
OVER (PARTITION BY column ORDER BY column)
```

This “window” groups rows logically and ranks them according to your chosen criteria.

---

## 2️⃣ Two Main Categories of Ranking Functions

Window ranking functions fall into **two conceptual groups**:

### 🧩 A. Integer-based Ranking Functions

Used for **positional ranking** — to find _top N_, _bottom N_, or _ordered lists_.

These functions output **discrete integer values** such as 1, 2, 3…

|Function|Description|Example Use|
|---|---|---|
|`ROW_NUMBER()`|Gives a unique sequential number per row (no ties)|Show first 3 students by score|
|`RANK()`|Assigns same rank for ties but leaves gaps|Show player ranks in leaderboard|
|`DENSE_RANK()`|Same as RANK but no gaps|Categorize into ranking levels|
|`NTILE(n)`|Divides rows into n equal buckets|Split customers into quartiles|

**Purpose:**  
Answer questions like —

> “Which are the **Top 3 products** by sales?”  
> or  
> “Which customers fall in the **Top 5 segments**?”

These functions produce **integer-based** ranks —  
perfect for sorting, filtering, and selecting top-performing rows.

---

### 📈 B. Percentage-based Ranking Functions

Used for **distribution analysis** — to measure _how far along_ a row is within the total ordered set.

They output **fractional values** between `0` and `1` (continuous scale).

|Function|Description|Example Use|
|---|---|---|
|`PERCENT_RANK()`|Relative rank position (based on rank formula)|Find top 10% performers|
|`CUME_DIST()`|Cumulative proportion of rows ≤ current row|Identify 90th percentile threshold|

**Purpose:**  
Answer questions like —

> “Which products fall in the **top 20%** of sales?”

These functions are ideal for **percentile, quantile, or probability-based analysis**, often used in data science and reporting.

---

## 3️⃣ Conceptual Difference

|Type|Output|Focus|Typical Use|
|---|---|---|---|
|**Integer-based**|1, 2, 3, …|Position|Top-N / Bottom-N selection|
|**Percentage-based**|0.0 → 1.0|Distribution|Percentile or quantile analysis|

🧮 In short:

- **Integer ranking** = _“What is the position of this row?”_
    
- **Percentage ranking** = _“What proportion of rows are above or below this one?”_
    

---

## 4️⃣ Visual Summary

- On the **left side** (integer-based):  
    Ranking is _discrete_. We’re counting rows → 1, 2, 3, 4, 5.
    
- On the **right side** (percentage-based):  
    Ranking is _continuous_. We’re measuring proportion → 0.0, 0.25, 0.5, 0.75, 1.0.
    

Both represent _order_, but at different levels of abstraction:

- **Position-based** ranking is ordinal.
    
- **Distribution-based** ranking is statistical.
    

---

## 5️⃣ Practical Tip (Senior-Level Insight)

When designing analytics:

- Use **integer-based** functions for _selection logic_ (e.g., top-N).
    
- Use **percentage-based** functions for _segmentation and normalization_ (e.g., 90th percentile).
    
- Always define an **ORDER BY** clause with unique tie-breakers for deterministic results.
    

---

**In essence:**

> Window ranking functions turn SQL from a set-based language into an _order-aware analytical engine_ — allowing you to measure both _where a row stands_ and _how it relates statistically_ to the whole dataset.



---

# 🧩 Window Ranking Functions — Practical Examples

Let’s assume we have a simple table:

```sql
CREATE TABLE products (
  product_name TEXT,
  sales INTEGER
);

INSERT INTO products (product_name, sales) VALUES
('E', 70),
('B', 30),
('A', 20),
('C', 10),
('D', 5);
```

---

## 1️⃣ `ROW_NUMBER()` – Sequential Ranking

```sql
SELECT product_name, sales,
       ROW_NUMBER() OVER (ORDER BY sales DESC) AS row_num
FROM products;
```

|product_name|sales|row_num|
|---|---|---|
|E|70|1|
|B|30|2|
|A|20|3|
|C|10|4|
|D|5|5|

📘 **Explanation:**  
Each row gets a unique sequential number based on descending sales.  
Useful for **“Top N per category”** queries.

---

## 2️⃣ `RANK()` – Ranking With Gaps

Let’s simulate ties by adding another product:

```sql
INSERT INTO products VALUES ('F', 30);
```

Now run:

```sql
SELECT product_name, sales,
       RANK() OVER (ORDER BY sales DESC) AS rank
FROM products;
```

|product_name|sales|rank|
|---|---|---|
|E|70|1|
|B|30|2|
|F|30|2|
|A|20|4|
|C|10|5|
|D|5|6|

📘 **Explanation:**  
`B` and `F` share the same sales, so they share rank 2.  
The next rank jumps to 4 → **gaps appear** after ties.

---

## 3️⃣ `DENSE_RANK()` – Ranking Without Gaps

```sql
SELECT product_name, sales,
       DENSE_RANK() OVER (ORDER BY sales DESC) AS dense_rank
FROM products;
```

|product_name|sales|dense_rank|
|---|---|---|
|E|70|1|
|B|30|2|
|F|30|2|
|A|20|3|
|C|10|4|
|D|5|5|

📘 **Explanation:**  
No gaps in ranks — rank values stay contiguous.  
Ideal when ranks represent **levels or tiers**.

---

## 4️⃣ `NTILE(4)` – Bucketing into Quantiles

```sql
SELECT product_name, sales,
       NTILE(4) OVER (ORDER BY sales DESC) AS quartile
FROM products;
```

|product_name|sales|quartile|
|---|---|---|
|E|70|1|
|B|30|1|
|F|30|2|
|A|20|3|
|C|10|3|
|D|5|4|

📘 **Explanation:**  
Splits dataset into 4 roughly equal groups —  
useful for **quartile or decile segmentation** (e.g., Top 25%).

---

## 5️⃣ `PERCENT_RANK()` – Relative Position (0 to 1)

```sql
SELECT product_name, sales,
       ROUND(PERCENT_RANK() OVER (ORDER BY sales DESC)::numeric, 2) AS percent_rank
FROM products;
```

|product_name|sales|percent_rank|
|---|---|---|
|E|70|0.00|
|B|30|0.20|
|F|30|0.20|
|A|20|0.60|
|C|10|0.80|
|D|5|1.00|

📘 **Explanation:**  
Shows each row’s position **as a fraction** of the dataset’s ordered list.  
Good for **percentile thresholds** (e.g., top 10%).

---

## 6️⃣ `CUME_DIST()` – Cumulative Distribution

```sql
SELECT product_name, sales,
       ROUND(CUME_DIST() OVER (ORDER BY sales DESC)::numeric, 2) AS cume_dist
FROM products;
```

|product_name|sales|cume_dist|
|---|---|---|
|E|70|0.17|
|B|30|0.50|
|F|30|0.50|
|A|20|0.67|
|C|10|0.83|
|D|5|1.00|

📘 **Explanation:**  
Cumulative proportion of rows **up to and including** the current one.  
Perfect for **distribution analysis** or **percentile classification**.

---

## 🧠 Summary

|Function|Output|Focus|Typical Use|
|---|---|---|---|
|`ROW_NUMBER()`|1, 2, 3…|Sequential order|Top-N queries|
|`RANK()`|Integers (with gaps)|Ordinal rank|Leaderboards|
|`DENSE_RANK()`|Integers (no gaps)|Level rank|Tier grouping|
|`NTILE(n)`|1..n|Bucketing|Quartiles, deciles|
|`PERCENT_RANK()`|0–1|Relative position|Percentile threshold|
|`CUME_DIST()`|0–1|Cumulative proportion|Distribution curve|

---




##### Tags : [[1 - SQL 🦬]]