

# ✅ **REPLACE VIEW — Study Version**

## 1. **What It Does**

`CREATE OR REPLACE VIEW` updates an existing view's definition **without dropping it**.

- Keeps permissions
    
- Keeps dependencies
    
- Simply updates the query inside the view
    

---

## 2. **Syntax**

```sql
CREATE OR REPLACE VIEW view_name [(column_list)]
AS
SELECT ...
[WITH [CASCADED | LOCAL] CHECK OPTION];
```

---

## 3. **Use Cases**

	Add/remove columns
	Change JOINs
	Modify filtering logic
	Add CHECK OPTION
	Update aggregations
	Change security filters

---

## 4. **Examples**

### Replace a view to add columns

```sql
CREATE OR REPLACE VIEW active_customers AS
SELECT id, name, email, phone
FROM customers
WHERE active = true;
```

### Change logic

```sql
CREATE OR REPLACE VIEW high_value_orders AS
SELECT order_id, amount
FROM orders
WHERE amount > 500;
```

### Add aggregations

```sql
CREATE OR REPLACE VIEW customer_stats AS
SELECT 
    c.id, c.name,
    COUNT(o.id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name;
```

---

## 5. **CHECK OPTION**

Forcing inserts/updates to satisfy view conditions.

```sql
CREATE OR REPLACE VIEW recent_orders AS
SELECT *
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
WITH CHECK OPTION;
```

---

## 6. **Important Rules**

1. **Column count must match** (if view already existed and you don't rename columns).
    
2. **Permissions stay the same**.
    
3. **Dependencies stay intact**.
    
4. **Materialized views do NOT support REPLACE**.
    
    - Must `DROP` → `CREATE` again.
        

---

## 7. **Materialized View Replacement**

```sql
DROP MATERIALIZED VIEW sales_summary;
CREATE MATERIALIZED VIEW sales_summary AS
SELECT ...;
```

---

## 8. **Common Patterns**

### Versioning

```sql
CREATE OR REPLACE VIEW customer_summary_v2 AS SELECT ...;
```

### Migration updates

```sql
CREATE OR REPLACE VIEW order_view AS
SELECT id, total_amount
FROM orders_new;
```

---

# 🧠 **Memory Tips**

- **“OR REPLACE View = edit mode for views.”**
    
- **Materialized views cannot be replaced.**
    
- **Permissions are preserved.**
    
- **Column shape must match.**
    

---


##### Tags : [[1 - SQL 🥞]]