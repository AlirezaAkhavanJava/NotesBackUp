

# 🧠 Data Segmentation in PostgreSQL

## 🔹 What is Data Segmentation?

**Data segmentation** means dividing your dataset into **logical or statistical groups (segments)** based on measurable criteria such as performance, sales, activity, or percentile.

It’s a key analytical concept used in:

- Business intelligence (customer tiers, top sellers)
    
- Marketing (targeting top 20% customers)
    
- Machine learning (feature binning, stratification)
    
- Risk and performance analysis
    

In SQL terms, segmentation is often done using **window functions**, particularly **ranking** and **distribution** functions.

---

## 🔹 Why Use Window Ranking Functions for Segmentation?

Because they let you **rank and group rows dynamically**, based on _relative performance_, without losing individual row detail.

You can segment data by:

- **Position** (Top N) — using `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`
    
- **Buckets** (equal-size groups) — using `NTILE(n)`
    
- **Percentiles** (statistical thresholds) — using `CUME_DIST()` or `PERCENT_RANK()`
    

---

## 🔹 Example: Segment Customers by Purchase Volume

```sql
SELECT
  customer_name,
  total_spent,
  NTILE(4) OVER (ORDER BY total_spent DESC) AS segment
FROM customers;
```

|customer_name|total_spent|segment|
|---|---|---|
|Alice|1200|1|
|Bob|1100|1|
|Emma|850|2|
|Noah|700|2|
|Ava|500|3|
|Liam|300|4|

📘 **Interpretation:**

- Segment 1 → Top 25% (High-value customers)
    
- Segment 4 → Bottom 25% (Low-value customers)
    

You can now analyze or target each group differently.

---

## 🔹 Example: Segment Products by Percentile

```sql
SELECT
  product_name,
  sales,
  ROUND(CUME_DIST() OVER (ORDER BY sales DESC)::numeric, 2) AS percentile
FROM products;
```

|product_name|sales|percentile|
|---|---|---|
|E|70|0.17|
|B|30|0.50|
|A|20|0.67|
|C|10|0.83|
|D|5|1.00|

📘 **Interpretation:**

- Top 20% → percentile ≤ 0.2
    
- Bottom 20% → percentile ≥ 0.8
    

This is **distribution-based segmentation** — perfect for identifying top/bottom performers.

---

## 🔹 Combining Segmentation with Business Logic

You can use segmentation results for:

- Conditional logic
    
    ```sql
    CASE 
      WHEN segment = 1 THEN 'Platinum'
      WHEN segment = 2 THEN 'Gold'
      WHEN segment = 3 THEN 'Silver'
      ELSE 'Bronze'
    END AS customer_tier
    ```
    
- Filtering specific tiers
    
    ```sql
    WHERE segment = 1 -- Top quartile
    ```
    

---

## 🧠 Summary

|Method|Function|Output|Use Case|
|---|---|---|---|
|**Positional Segmentation**|`ROW_NUMBER()`, `RANK()`|Integer|Top/Bottom N entities|
|**Quantile Segmentation**|`NTILE(n)`|1..n buckets|Equal-sized groups|
|**Percentile Segmentation**|`CUME_DIST()`, `PERCENT_RANK()`|0–1 float|Statistical cutoffs|

---

### 🧩 Key Takeaway:

> **Data segmentation** is the art of dividing data into meaningful groups.  
> **Window ranking functions** are the most powerful SQL tools to do it — letting you group by performance, value, or distribution _without losing row-level detail._


---


# 🧩 Advanced Example: Dynamic Segmentation by Revenue Percentile

### 🎯 Goal:

Classify each customer into **tiers** (Top 10%, Middle 50%, Bottom 40%) dynamically based on their total revenue.

This uses **window ranking + conditional logic**, and is a very common analytics pattern in production (finance, CRM, SaaS KPIs, etc.).

---

## 🔹 Step 1 — Base Data

Assume this table:

```sql
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  total_revenue NUMERIC
);
```

Example data:

|id|name|total_revenue|
|---|---|---|
|1|Alice|12000|
|2|Bob|9500|
|3|Carol|8700|
|4|Dan|4500|
|5|Emma|3500|
|6|Fred|1800|
|7|Gina|900|

---

## 🔹 Step 2 — Apply `CUME_DIST()` to Calculate Percentile

```sql
SELECT
  name,
  total_revenue,
  ROUND(CUME_DIST() OVER (ORDER BY total_revenue DESC)::numeric, 3) AS percentile
FROM customers
ORDER BY total_revenue DESC;
```

|name|total_revenue|percentile|
|---|---|---|
|Alice|12000|0.143|
|Bob|9500|0.286|
|Carol|8700|0.429|
|Dan|4500|0.571|
|Emma|3500|0.714|
|Fred|1800|0.857|
|Gina|900|1.000|

---

## 🔹 Step 3 — Segment with Conditional Logic

```sql
SELECT
  name,
  total_revenue,
  ROUND(CUME_DIST() OVER (ORDER BY total_revenue DESC)::numeric, 3) AS percentile,
  CASE
    WHEN CUME_DIST() OVER (ORDER BY total_revenue DESC) <= 0.10 THEN '🏆 Top 10%'
    WHEN CUME_DIST() OVER (ORDER BY total_revenue DESC) <= 0.60 THEN '⚡ Middle 50%'
    ELSE '🔻 Bottom 40%'
  END AS segment
FROM customers
ORDER BY total_revenue DESC;
```

|name|total_revenue|percentile|segment|
|---|---|---|---|
|Alice|12000|0.143|⚡ Middle 50%|
|Bob|9500|0.286|⚡ Middle 50%|
|Carol|8700|0.429|⚡ Middle 50%|
|Dan|4500|0.571|⚡ Middle 50%|
|Emma|3500|0.714|🔻 Bottom 40%|
|Fred|1800|0.857|🔻 Bottom 40%|
|Gina|900|1.000|🔻 Bottom 40%|

---

## 🔹 Step 4 — Explanation (Senior-Level Insights)

1. **`CUME_DIST()`** computes the _cumulative distribution_ — the proportion of rows with values ≤ current value.
    
    - It’s perfect for **percentile-based thresholds**.
        
    - Unlike `NTILE(10)`, it’s _statistically precise_, not approximate.
        
2. The **CASE** block dynamically maps numeric percentiles into meaningful _business tiers_ (e.g., "Top 10%").
    
3. This is **non-destructive segmentation**:
    
    - You don’t lose granularity — every row is still available.
        
    - You can join or aggregate these segments for dashboards or reports.
        
4. It scales: Even in a billion-row table, window functions are parallelizable in PostgreSQL (especially with partitioning).
    

---

## 🔹 Step 5 — (Optional) Group Analytics by Segment

```sql
WITH ranked AS (
  SELECT
    name,
    total_revenue,
    CASE
      WHEN CUME_DIST() OVER (ORDER BY total_revenue DESC) <= 0.10 THEN 'Top 10%'
      WHEN CUME_DIST() OVER (ORDER BY total_revenue DESC) <= 0.60 THEN 'Middle 50%'
      ELSE 'Bottom 40%'
    END AS segment
  FROM customers
)
SELECT
  segment,
  COUNT(*) AS total_customers,
  ROUND(AVG(total_revenue)) AS avg_revenue
FROM ranked
GROUP BY segment
ORDER BY avg_revenue DESC;
```

📊 **Output:**

|segment|total_customers|avg_revenue|
|---|---|---|
|Top 10%|1|12000|
|Middle 50%|4|6575|
|Bottom 40%|2|2200|

---

## 🧠 Summary Takeaways (Senior-Level)

|Concept|Meaning|Practical Use|
|---|---|---|
|**Segmentation**|Categorizing rows into value-based groups|Customer tiers, product ranks|
|**CUME_DIST()**|Cumulative percentile per row|Real percentile thresholds|
|**NTILE(n)**|Bucket division into equal-sized groups|Quartiles, deciles|
|**CASE + Window**|Dynamic classification|Tier labeling|
|**CTE Grouping**|Aggregated view per segment|Dashboard analytics|

---



##### Tags : [[1 - SQL 🥞]]