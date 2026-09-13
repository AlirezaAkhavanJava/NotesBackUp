A **Data Warehouse (DW)** is a **centralized storage system** designed for **analyzing** large volumes of data — not for day-to-day transaction processing.

Think of it as a **read-optimized database** built for **business intelligence (BI), reporting, and analytics**.

![[Pasted image 20251118092245.png]]


>A **data warehouse** is basically a **big, organized storage place** where a company keeps **all its important data** from different systems **in one clean, consistent format** so they can analyze it easily.


>**Data warehouse = a giant clean database for reporting and analytics.**
---

### 🧠 Core Idea

It **collects, cleans, and integrates** data from multiple operational systems (like sales, finance, HR) into one consistent, historical database.

---

### 🏗️ Architecture Overview

1️⃣ **Source Systems** → OLTP databases (e.g. ERP, CRM, app DBs)  
2️⃣ **ETL/ELT Process** → Extract → Transform → Load data into warehouse  
3️⃣ **Data Warehouse** → Central repository (PostgreSQL, Snowflake, Redshift, etc.)  
4️⃣ **Data Marts** → Smaller subject-focused subsets (e.g. “Sales mart”)  
5️⃣ **BI Tools** → Power BI, Tableau, Looker, etc. for analytics and dashboards

---

### ⚙️ Key Characteristics

|Feature|Description|
|---|---|
|**Subject-Oriented**|Data organized by topic (sales, finance, customers).|
|**Integrated**|Data from many sources standardized into one format.|
|**Time-Variant**|Stores historical data (e.g. 5 years of sales).|
|**Non-Volatile**|Data is read-only after loading — not updated by users.|



### 🧩 Data Models

|Model|Description|
|---|---|
|**Star Schema**|Central fact table (measurable data) linked to dimension tables.|
|**Snowflake Schema**|Dimensions normalized into multiple related tables.|
|**Galaxy Schema**|Multiple fact tables sharing dimensions.|


---
### 📊 Example

**Fact Table:** `sales_fact`  

| sale_id | product_id | date_id | amount | quantity |

**Dimension Tables:**  
`product_dim`, `date_dim`, `customer_dim`, etc.

Query example:

```sql
SELECT d.year, p.category, SUM(f.amount) AS total_sales
FROM sales_fact f
JOIN date_dim d ON f.date_id = d.id
JOIN product_dim p ON f.product_id = p.id
GROUP BY d.year, p.category;
```

→ Aggregated yearly sales by product category.

---

### 🚀 Benefits

- Fast analytical queries (aggregations, trends)
    
- Unified view of business data
    
- Historical insight and trend tracking
    
- Supports dashboards and machine learning pipelines
    

---


##### Tags : [[1 - SQL 🥞]]