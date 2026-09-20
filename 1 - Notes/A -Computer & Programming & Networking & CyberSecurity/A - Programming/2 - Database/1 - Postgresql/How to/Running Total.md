
A running total or rolling total is **the summation of a sequence of numbers which is updated each time a new number is added to the sequence, by adding the value of the new number to the previous running total**. Another term for it is partial sum.

To calculate running totals in SQL, you typically **use window functions with the SUM() aggregation and an OVER clause**. A running total accumulates values row by row based on a specified order, such as dates or IDs.


```SQL
SELECT
    name,
    hire_date,
    SUM(salary) OVER (ORDER BY hire_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM employees;
```


[[1 - SQL 🥞]]