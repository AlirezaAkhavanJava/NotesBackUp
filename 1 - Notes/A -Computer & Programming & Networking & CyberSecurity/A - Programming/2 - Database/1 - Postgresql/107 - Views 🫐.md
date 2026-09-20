

# ✅ Views in PostgreSQL 

## 1. **Definition**

A **view** is a **saved SELECT query** that acts like a **virtual table**.

- Doesn’t store data
    
- Shows live data from base tables
    
- Used like a normal table
    

---

## 2. **Why We Use Views**

- **Simplify complex queries**
    
- **Hide sensitive columns** (security)
    
- **Consistency** (same logic everywhere)
    
- **Abstraction** (schema changes won’t break apps)
    
- **Reuse logic**
    

---

## 3. **Basic Syntax**

### Create

```sql
CREATE VIEW view_name AS
SELECT ...
```

### Drop

```sql
DROP VIEW view_name;
```

---

## 4. **Types of Views**

### **1. Simple View**

Single table, no aggregates.

```sql
CREATE VIEW active_users AS
SELECT id, name FROM users WHERE active = true;
```

### **2. Complex View**

Joins, formulas, grouping.

```sql
CREATE VIEW order_details AS
SELECT o.id, c.name, p.product_name
FROM orders o
JOIN customers c ON ...
JOIN products p ON ...
```

### **3. Materialized View**

Stores data physically.

```sql
CREATE MATERIALIZED VIEW sales_summary AS
SELECT ...;
REFRESH MATERIALIZED VIEW sales_summary;
```

---

## 5. **Updatable Views**

A view is **updatable** only if:

- Comes from **one table**
    
- No **GROUP BY**, **DISTINCT**, **UNION**, **AGGREGATES**
    
- Columns map directly to the underlying table
    

Example (updatable):

```sql
UPDATE active_users SET name = 'Ethan' WHERE id = 1;
```

For complex views → use **INSTEAD OF triggers**.

---

## 6. **Views vs Tables**

|Feature|Table|View|
|---|---|---|
|Stores data|✅ Yes|❌ No|
|Created with|CREATE TABLE|CREATE VIEW|
|Performance|Fast|Slower (recomputed)|
|Use case|Real data storage|Query abstraction|

---

## 7. **Views vs CTEs**

- **View** = saved query, reusable anytime
    
- **CTE** = temporary query inside one SQL statement
    

---

## 8. **Key Limitations**

- Non-materialized views = slower
    
- Many views are **not updatable**
    
- Breaking changes in base tables break views
    

##### Tags : [[1 - SQL 🥞]]