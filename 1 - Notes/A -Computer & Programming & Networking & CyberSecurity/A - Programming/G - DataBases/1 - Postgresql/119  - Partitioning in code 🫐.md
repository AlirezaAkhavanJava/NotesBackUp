
### 🧱 **1. What “Partitioning” Means**

**Partitioning** = splitting one big table into **smaller pieces** (partitions) based on a rule — like date, region, or category.  
It improves performance and manageability.

---

### 💻 **2. In PostgreSQL (code example)**

#### Example: Partition sales by year

```sql
-- Parent table
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    amount NUMERIC,
    sale_date DATE
) PARTITION BY RANGE (sale_date);
```

#### Create child partitions

```sql
CREATE TABLE sales_2023 PARTITION OF sales
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE sales_2024 PARTITION OF sales
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

Now:

```sql
INSERT INTO sales (amount, sale_date) VALUES (500, '2024-05-10');
```

➡️ Automatically goes into `sales_2024`.

---

### ⚙️ **3. Querying**

```sql
SELECT * FROM sales WHERE sale_date BETWEEN '2024-01-01' AND '2024-06-01';
```

PostgreSQL automatically scans only the matching partition (fast).

---

### 🧩 **4. Types of Partitioning**

|Type|Example|Use Case|
|---|---|---|
|RANGE|By date/number range|Time-based data|
|LIST|By fixed values|Country, category|
|HASH|By hash of key|Uniform data split|

---

### 🧰 **5. Maintenance**

You can add new partitions easily:

```sql
CREATE TABLE sales_2025 PARTITION OF sales
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

---

### ⚡ **6. Benefits**

- Faster queries on specific ranges.
    
- Easier data cleanup (drop a partition).
    
- Reduces index size.
    
- Better performance on large datasets.
    



##### Tags : [[1 - SQL 🥞]]