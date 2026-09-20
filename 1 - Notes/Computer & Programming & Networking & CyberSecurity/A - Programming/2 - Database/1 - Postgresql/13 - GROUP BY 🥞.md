Date : 2025-09-01


## *📘 Beginner Level — Basic GROUP BY*

### **1. What is `GROUP BY`**

The `GROUP BY` clause groups rows that have the same values into summary rows.  
It is almost always used with **aggregate functions** like `COUNT`, `SUM`, `AVG`, `MAX`, `MIN`.

**Syntax:**

```sql
SELECT column1, AGGREGATE_FUNCTION(column2)
FROM table_name
GROUP BY column1;
```

---

### **2. Basic Example**

```sql
SELECT country, COUNT(*)
FROM students
GROUP BY country;
```

→ Counts how many students are in each country.

---

### **3. GROUP BY with Multiple Columns**

```sql
SELECT country, gender, COUNT(*)
FROM students
GROUP BY country, gender;
```

→ Groups first by country, then by gender.



---

## **📗 Intermediate Level — GROUP BY with Filtering**

### **1. GROUP BY with WHERE**

Filter rows before grouping:

```sql
SELECT country, COUNT(*)
FROM students
WHERE age > 18
GROUP BY country;
```

---

### **2. GROUP BY with HAVING**

`HAVING` filters groups (like WHERE filters rows).

Example:

```sql
SELECT country, COUNT(*)
FROM students
GROUP BY country
HAVING COUNT(*) > 10;
```

→ Only countries with more than 10 students.

---

### **3. GROUP BY with ORDER BY**

```sql
SELECT country, COUNT(*)
FROM students
GROUP BY country
ORDER BY COUNT(*) DESC;
```

→ Sorts groups by student count.

---

### **4. GROUP BY with Aliases**

```sql
SELECT country, COUNT(*) AS student_count
FROM students
GROUP BY country
ORDER BY student_count DESC;
```

---



## **📙 Advanced Level — GROUP BY Tricks**

### **1. GROUP BY with Expressions**

```sql
SELECT EXTRACT(YEAR FROM birth_date) AS birth_year, COUNT(*)
FROM students
GROUP BY birth_year;
```

→ Groups by year of birth.

---

### **2. GROUP BY with ROLLUP (PostgreSQL-specific)**

`ROLLUP` creates subtotals and a grand total.

```sql
SELECT country, gender, COUNT(*)
FROM students
GROUP BY ROLLUP (country, gender);
```

Example output:

|country|gender|count|
|---|---|---|
|USA|M|10|
|USA|F|12|
|USA|NULL|22|
|UK|M|5|
|UK|F|7|
|UK|NULL|12|
|NULL|NULL|34|

---

### **3. GROUP BY with CUBE (PostgreSQL-specific)**

`CUBE` creates all combinations of grouping.

```sql
SELECT country, gender, COUNT(*)
FROM students
GROUP BY CUBE (country, gender);
```

---

### **4. GROUP BY with GROUPING SETS**

Allows custom group combinations.

```sql
SELECT country, gender, COUNT(*)
FROM students
GROUP BY GROUPING SETS (
    (country, gender),
    (country),
    (gender),
    ()
);
```

---

### **5. GROUP BY with Window Functions**

```sql
SELECT country, gender, COUNT(*) OVER (PARTITION BY country) AS country_count
FROM students;
```

→ Groups in windows without collapsing rows.

---



## **🚀 Tips & Tricks**

- `GROUP BY` always comes **after WHERE** and before ORDER BY.
    
- Columns in SELECT that are not aggregated **must** be in GROUP BY.
    
- HAVING filters groups, WHERE filters rows before grouping.
    
- For advanced grouping, learn `ROLLUP`, `CUBE`, and `GROUPING SETS`.
    
- Indexes can improve GROUP BY performance.
    

---


##### *Tags : [[1 - SQL 🥞]]