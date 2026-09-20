

### 🧱 Imagine the situation

We have a small store with **OLTP (transaction) data**:

**Table:** `sales_raw`

|id|product|price|date|city|
|---|---|---|---|---|
|1|iPhone|1000|2025/01/03|NY|
|2|Galaxy|800|2025-01-03|New York|
|3|Pixel|NULL|2025/01/04|NYC|

---

### 🪣 Step 1️⃣ — **Extract**

We “take” the data from the source (maybe copied from the store DB):

```sql
SELECT * FROM sales_raw;
```

This is just reading the raw transactional data.

---

### ⚙️ Step 2️⃣ — **Transform**

Now we **clean it up**:

- Fix city names
    
- Fill missing price values
    
- Fix date format
    

```sql
SELECT 
  id,
  product,
  COALESCE(price, 0) AS price,             -- replace NULL with 0
  TO_DATE(date, 'YYYY/MM/DD') AS sale_date, -- fix date format
  CASE 
    WHEN city IN ('NY', 'NYC') THEN 'New York'
    ELSE city
  END AS city
FROM sales_raw;
```

✅ Now all data looks consistent and clean.

---

### 🚚 Step 3️⃣ — **Load**

We take the cleaned data and **insert it into the warehouse** table:

**Warehouse Table:** `sales_fact`

```sql
CREATE TABLE sales_fact (
  sale_id INT,
  product TEXT,
  price NUMERIC,
  sale_date DATE,
  city TEXT
);
```

Then load it:

```sql
INSERT INTO sales_fact (sale_id, product, price, sale_date, city)
SELECT 
  id,
  product,
  COALESCE(price, 0),
  TO_DATE(date, 'YYYY/MM/DD'),
  CASE WHEN city IN ('NY', 'NYC') THEN 'New York' ELSE city END
FROM sales_raw;
```

---

### 📊 Step 4️⃣ — **Analyze (OLAP)**

Now that data is clean and stored in the warehouse, we can do analysis:

```sql
SELECT city, SUM(price) AS total_sales
FROM sales_fact
GROUP BY city;
```

✅ Gives us insights — “Total sales by city.”

---

### 🧠 Summary

|Step|Action|Purpose|
|---|---|---|
|Extract|Get data from source|Copy raw data|
|Transform|Clean & fix it|Make it usable|
|Load|Save to warehouse|Ready for analysis|


##### Tags : [[1 - SQL 🥞]]