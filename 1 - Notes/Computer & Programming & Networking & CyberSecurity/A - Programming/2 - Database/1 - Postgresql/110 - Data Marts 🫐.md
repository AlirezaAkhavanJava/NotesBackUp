
A **Data Mart** is a **smaller, focused version of a data warehouse** that contains data specific to one department, team, or business function.

### 🧠 Simple Definition

> A **data mart** is like a **mini data warehouse** built for a specific purpose — e.g., sales, marketing, finance, or HR — instead of storing all company data.

---

### 🧩 Example

- A **Sales Data Mart** stores only sales-related data: customers, transactions, revenue, regions.
    
- A **Marketing Data Mart** stores campaign data, ad performance, and leads.
    

---

### ⚙️ Types of Data Marts

1. **Dependent** — data comes **from a central data warehouse**.
    
2. **Independent** — data is collected **directly from sources** (no warehouse).
    
3. **Hybrid** — combines both approaches.
    

---

### 📊 Why Use Data Marts

- Faster access for specific teams.
    
- Easier to manage and cheaper than full data warehouses.
    
- Improves query performance by reducing data size.
    
- Allows each department to analyze data their way.
    

---

### 🏗️ In short

|Feature|Data Mart|Data Warehouse|
|---|---|---|
|Scope|Department-level|Organization-wide|
|Size|Smaller|Large|
|Cost|Lower|Higher|
|Data Source|Few (specific)|Many (integrated)|

---


### 🧱 **1. PostgreSQL Views**

A **View** in PostgreSQL is basically a **saved SQL query**.  
It doesn’t store data itself — it just **shows data from tables** every time you query it.

#### Example:

```sql
CREATE VIEW sales_summary AS
SELECT region, SUM(amount) AS total_sales
FROM sales
GROUP BY region;
```

Now you can just do:

```sql
SELECT * FROM sales_summary;
```

✅ **Key points:**

- No data duplication (it’s a “virtual table”).
    
- Auto-updates when base tables change.
    
- Useful for simplifying complex queries and restricting access.
    

---

### 🏢 **2. Data Marts**

A **Data Mart** is a **collection of data** designed for a specific business area (like Sales, HR, Finance).  
It’s part of a **data warehouse** architecture — built to analyze and report data efficiently.

In PostgreSQL terms, a Data Mart might be:

- A **separate schema or database** (e.g., `sales_mart`).
    
- Containing **denormalized tables or materialized views** that store precomputed results.
    
- Fed by **ETL processes** (Extract–Transform–Load).
    

---

### 🧩 **3. How They Work Together**

- **Views** are logical — no data stored.
    
- **Data Marts** are physical — they store data optimized for analysis.
    

You can **build a Data Mart in PostgreSQL** using:

```sql
CREATE MATERIALIZED VIEW sales_mart AS
SELECT region, SUM(amount) AS total_sales
FROM sales
GROUP BY region;
```

Then refresh it when new data arrives:

```sql
REFRESH MATERIALIZED VIEW sales_mart;
```

---

### ⚖️ Summary

|Feature|PostgreSQL View|PostgreSQL Data Mart|
|---|---|---|
|Type|Logical (virtual table)|Physical (stored data)|
|Data Storage|None|Yes|
|Purpose|Simplify queries|Support analytics|
|Refresh|Always up-to-date|Needs manual/ETL refresh|
|Scope|Developer-level|Business/department-level|



##### Tags : [[1 - SQL 🥞]]