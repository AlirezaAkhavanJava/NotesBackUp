 
The important relationship is:

> **`JOIN` creates the rows you want to analyze; `GROUP BY` groups those joined rows so aggregate functions can calculate something per group.**

## 1. Basic pattern

```sql
SELECT
    table1.column,
    COUNT(table2.column)
FROM table1
JOIN table2
    ON table1.id = table2.table1_id
GROUP BY table1.column;
```

Think of the execution like:

```text
table1
   +
table2
   │
   ▼
 JOIN
   │
   ▼
joined rows
   │
   ▼
GROUP BY
   │
   ▼
groups
   │
   ▼
COUNT / SUM / AVG / MIN / MAX
```

---

## 2. Example: customers and orders

Suppose:

```text
customers
+----+-------+
| id | name  |
+----+-------+
| 1  | Alice |
| 2  | Bob   |
| 3  | Carol |
+----+-------+
```

and:

```text
orders
+----+-------------+--------+
| id | customer_id | price  |
+----+-------------+--------+
| 1  | 1           | 100    |
| 2  | 1           | 50     |
| 3  | 2           | 200    |
| 4  | 1           | 75     |
+----+-------------+--------+
```

First, the `JOIN` produces:

```text
Alice → 100
Alice → 50
Bob   → 200
Alice → 75
```

Then:

```sql
SELECT
    "customers"."name",
    COUNT("orders"."id") AS "order_count"
FROM "customers"
JOIN "orders"
    ON "customers"."id" = "orders"."customer_id"
GROUP BY "customers"."id", "customers"."name";
```

Result:

```text
name  | order_count
------+------------
Alice | 3
Bob   | 1
```

Carol doesn't appear because `JOIN` means `INNER JOIN`, so customers with no matching orders are removed.

---

# 3. `LEFT JOIN` + `GROUP BY`

This is extremely common.

```sql
SELECT
    "customers"."name",
    COUNT("orders"."id") AS "order_count"
FROM "customers"
LEFT JOIN "orders"
    ON "customers"."id" = "orders"."customer_id"
GROUP BY "customers"."id", "customers"."name";
```

Now:

```text
Alice | 3
Bob   | 1
Carol | 0
```

Why?

`LEFT JOIN` preserves every customer:

```text
Alice → order
Alice → order
Alice → order
Bob   → order
Carol → NULL
```

Then:

```sql
COUNT("orders"."id")
```

doesn't count the `NULL` order ID.

---

# 4. `SUM()` with JOIN

Instead of counting orders, calculate how much each customer spent:

```sql
SELECT
    "customers"."name",
    SUM("orders"."price") AS "total_spent"
FROM "customers"
JOIN "orders"
    ON "customers"."id" = "orders"."customer_id"
GROUP BY "customers"."id", "customers"."name";
```

Result:

```text
Alice | 225
Bob   | 200
```

The join gives you:

```text
customer + order price
```

and `GROUP BY` says:

```text
put all rows belonging to the same customer together
```

Then `SUM()` operates on each customer's group.

---

# 5. Grouping by a column from either table

You aren't required to group by the first table.

```sql
SELECT
    "products"."category",
    COUNT("orders"."id")
FROM "orders"
JOIN "products"
    ON "orders"."product_id" = "products"."id"
GROUP BY "products"."category";
```

Conceptually:

```text
orders
   ↓
JOIN products
   ↓
order + product information
   ↓
GROUP BY product category
   ↓
COUNT orders in each category
```

---

# 6. `WHERE` + `JOIN` + `GROUP BY`

These three often work together:

```sql
SELECT
    "customers"."name",
    SUM("orders"."price") AS "total"
FROM "customers"
JOIN "orders"
    ON "customers"."id" = "orders"."customer_id"
WHERE "orders"."price" > 50
GROUP BY "customers"."id", "customers"."name";
```

The conceptual order is:

```text
FROM
 ↓
JOIN
 ↓
WHERE
 ↓
GROUP BY
 ↓
aggregate functions
```

So `WHERE` filters **joined rows before they are grouped**.

---

# 7. `HAVING` after GROUP BY

Suppose you want only customers who spent more than 200:

```sql
SELECT
    "customers"."name",
    SUM("orders"."price") AS "total"
FROM "customers"
JOIN "orders"
    ON "customers"."id" = "orders"."customer_id"
GROUP BY "customers"."id", "customers"."name"
HAVING SUM("orders"."price") > 200;
```

Now the flow is:

```text
FROM
 ↓
JOIN
 ↓
WHERE
 ↓
GROUP BY
 ↓
aggregate
 ↓
HAVING
 ↓
result
```

`WHERE` filters **rows**.

`HAVING` filters **groups**.

---

# 8. Multiple tables

This becomes really powerful:

```sql
SELECT
    "customers"."name",
    "products"."category",
    COUNT("orders"."id") AS "orders",
    SUM("orders"."price") AS "revenue"
FROM "customers"
JOIN "orders"
    ON "customers"."id" = "orders"."customer_id"
JOIN "products"
    ON "orders"."product_id" = "products"."id"
GROUP BY
    "customers"."id",
    "customers"."name",
    "products"."category";
```

Now you're grouping by:

```text
customer + product category
```

For example:

```text
Alice | Books      | 5 | 250
Alice | Electronics| 2 | 700
Bob   | Books      | 3 | 120
```

---

## The mental model you should keep

Don't think:

```text
JOIN + GROUP BY = one thing
```

Think of them as two separate operations:

```text
JOIN
"Which rows should be connected?"
        ↓
GROUP BY
"Which joined rows belong to the same group?"
        ↓
COUNT / SUM / AVG / ...
"What calculation should I perform on each group?"
```

For SQL, this distinction is fundamental:

```sql
FROM ... JOIN ...
```

determines **the rows**

while:

```sql
GROUP BY ...
```

determines **the groups those rows belong to**.



[[1 - WHAT IS SQLITE3 🍕]]