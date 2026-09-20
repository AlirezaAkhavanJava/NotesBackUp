

## **📘 Beginner Level — Basic TOP**

### **1. What is `TOP`**

- `TOP` is used in SQL (mainly in SQL Server, not standard SQL) to limit the number of rows returned by a query.
    
- **PostgreSQL does not use `TOP`**, it uses `LIMIT`.
    

**Syntax in SQL Server:**

```sql
SELECT TOP n column1, column2
FROM table_name;
```

Example:

```sql
SELECT TOP 5 name, age
FROM students;
```

→ Returns the first 5 rows.

---

### **2. Equivalent in PostgreSQL**

PostgreSQL uses `LIMIT`:

```sql
SELECT name, age
FROM students
LIMIT 5;
```

---


## **📗 Intermediate Level — TOP/LIMIT with ORDER BY**

### **1. SQL Server Example**

```sql
SELECT TOP 3 name, age
FROM students
ORDER BY age DESC;
```

→ Returns 3 oldest students.

### **2. PostgreSQL Equivalent**

```sql
SELECT name, age
FROM students
ORDER BY age DESC
LIMIT 3;
```

---

### **3. OFFSET in PostgreSQL**

PostgreSQL supports skipping rows:

```sql
SELECT name, age
FROM students
ORDER BY age DESC
LIMIT 3 OFFSET 2;
```

→ Skips first 2 rows, returns next 3.


---

## **📙 Advanced Level — TOP/LIMIT Tricks**

### **1. TOP with PERCENT (SQL Server)**

```sql
SELECT TOP 10 PERCENT name, age
FROM students
ORDER BY age DESC;
```

→ Returns the top 10% of rows.

PostgreSQL equivalent:

```sql
SELECT name, age
FROM students
ORDER BY age DESC
LIMIT (SELECT ROUND(0.1 * COUNT(*)) FROM students);
```

---

### **2. TOP with ties (SQL Server)**

Keeps all rows with same order value:

```sql
SELECT TOP 3 WITH TIES name, age
FROM students
ORDER BY age DESC;
```

PostgreSQL equivalent:

```sql
SELECT name, age
FROM students
ORDER BY age DESC
FETCH FIRST 3 ROWS WITH TIES;
```

---

### **3. LIMIT with Subqueries**

```sql
SELECT *
FROM (
    SELECT name, age
    FROM students
    ORDER BY age DESC
    LIMIT 5
) subquery;
```

→ Useful when combining with other queries.

---

### **4. LIMIT with Window Functions**

```sql
SELECT name, age
FROM (
    SELECT name, age, ROW_NUMBER() OVER (ORDER BY age DESC) AS rn
    FROM students
) t
WHERE rn <= 5;
```

→ More control over "top N" rows.

---

## **🚀 Quick Summary**

|Feature|SQL Server|PostgreSQL|
|---|---|---|
|Limit rows|`TOP n`|`LIMIT n`|
|Skip rows|—|`OFFSET n`|
|Top percentage|`TOP n PERCENT`|Calculated with LIMIT|
|Ties|`WITH TIES`|`FETCH FIRST n ROWS WITH TIES`|

---

💡 **Memory tip:**  
In PostgreSQL → think **`LIMIT` (+OFFSET)** instead of `TOP`.
##### Tags : [[1 - SQL 🥞]]