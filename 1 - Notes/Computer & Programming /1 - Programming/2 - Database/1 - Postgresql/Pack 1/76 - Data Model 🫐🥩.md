### 🧠 What Is a Data Model?

A **Data Model** is simply a **blueprint** of how data is stored, connected, and organized in a database.

Think of it like an **architect’s plan** before building a house:

- It shows **what tables exist**
    
- What **columns** they have
    
- How they’re **related** to each other
    

It’s how we translate **real-world things** (like customers, orders, products) into **database tables**.

---

### 🧱 Example

Let’s say we have an online store.

|Real world|Database representation|
|---|---|
|Customer|`customers` table|
|Product|`products` table|
|Order|`orders` table|
|Each order belongs to a customer|`orders.customer_id` is a **foreign key**|

---

### 📊 The Three Main Types of Data Models

|Type|Description|Example|
|---|---|---|
|**Conceptual Model**|High-level — defines what entities exist and how they relate.|"Customers place Orders"|
|**Logical Model**|Adds more detail: fields, data types, relationships, keys.|`Customer(id, name, email)`|
|**Physical Model**|The actual database design (SQL tables, indexes, constraints).|`CREATE TABLE customers (...)`|

---

### 🧩 Relationships

|Relationship|Meaning|Example|
|---|---|---|
|**1 : 1**|One record relates to one other.|A person → one passport|
|**1 : N**|One record connects to many.|A customer → many orders|
|**M : N**|Many records connect to many.|Products ↔ Orders (via `order_products` join table)|

---

### 🧠 Normalization (in OLTP)

Used in **transactional systems** to reduce redundancy.

Rules (forms):

1. **1NF:** No repeating groups (each field atomic)
    
2. **2NF:** Each non-key depends on the whole key
    
3. **3NF:** No transitive dependencies
    

✅ Result: Data is clean and consistent  
❌ But joins become heavy (so it’s not ideal for analytics).

---

### 🧱 Denormalization (in OLAP / Data Warehouse)

Used in **data warehouses** to make **queries faster**.

Instead of many small linked tables, we combine them.

Example:

- Fact: `sales_fact` (numeric data like amount, quantity)
    
- Dimensions: `product_dim`, `customer_dim`, `date_dim`
    

📐 Schema type: **Star Schema** or **Snowflake Schema**

---

### 🌟 Star Schema (Most Common in Warehouses)

```
          product_dim
               |
customer_dim -- sales_fact -- date_dim
               |
           store_dim
```

💡 One central **Fact Table** (numbers) surrounded by **Dimension Tables** (descriptions).

---

### 🧰 In Short

|Environment|Goal|Model Type|
|---|---|---|
|OLTP (apps)|Store and manage daily transactions|**Normalized model**|
|OLAP (analytics)|Analyze historical data quickly|**Denormalized model (star/snowflake)**|

##### Tags : [[1 - SQL 🦬]]