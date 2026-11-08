

`LIMIT` is a clause at the end of a `SELECT` that tells PostgreSQL: "stop after this many rows." Instead of returning the whole result, you get only the first N rows. It is also the base of **pagination**, which means showing data page by page, together with its partner `OFFSET`, which skips rows before counting.

In the DQL lesson we saw that `LIMIT` runs **last**, after `WHERE`, `GROUP BY`, `HAVING`, `SELECT` and `ORDER BY`. That one fact explains almost everything about how `LIMIT` behaves. Let's go through it with the same `employees` table.

|id|name|salary|department_id|
|---|---|---|---|
|1|Ana|5000|1|
|2|Omar|4200|1|
|3|Lina|3900|2|
|4|Sam|NULL|NULL|

## 1. The basic form

```sql
SELECT name FROM employees LIMIT 2;
```

Returns two rows. Which two? **Any two.** Without `ORDER BY`, PostgreSQL does not promise an order, so the result can change between runs, after an `UPDATE`, or after a `VACUUM`. That makes `LIMIT` without `ORDER BY` fine for "show me a sample" in pgAdmin, but a bug in application code.

## 2. LIMIT with ORDER BY

```sql
SELECT name, salary
FROM employees
ORDER BY salary DESC NULLS LAST
LIMIT 2;
```

|name|salary|
|---|---|
|Ana|5000|
|Omar|4200|

Line by line:

- `ORDER BY salary DESC NULLS LAST` sorts the whole result first, highest salary first, and puts `NULL` at the end.
- `LIMIT 2` then keeps only the first two sorted rows.

This is the "top N" pattern. If you leave out `NULLS LAST`, Sam (`NULL`) would come **first** in `DESC` order, because PostgreSQL treats `NULL` as the largest value.

**Add a tie-breaker.** If two rows have the same salary, their order is not fixed, so the limited result can change. Add a unique column last:

```sql
ORDER BY salary DESC NULLS LAST, id
```

## 3. OFFSET: skipping rows

```sql
SELECT name FROM employees
ORDER BY id
LIMIT 2 OFFSET 2;
```

|name|
|---|
|Lina|
|Sam|

`OFFSET 2` skips the first two rows, then `LIMIT 2` takes the next two. The order you write them in does not matter (`OFFSET 2 LIMIT 2` works too).

**Page formula:** for page number `p` (starting at 1) with size `s`:

```sql
LIMIT s OFFSET (p - 1) * s
```

Page 3 with 10 rows per page is `LIMIT 10 OFFSET 20`.

## 4. The standard way: FETCH FIRST

`LIMIT` is PostgreSQL's (and MySQL's) way. The SQL standard way is:

```sql
SELECT name FROM employees
ORDER BY salary DESC NULLS LAST
OFFSET 0 ROWS
FETCH FIRST 2 ROWS ONLY;
```

It does the same thing, and it works in Oracle and SQL Server too. Use `LIMIT` for PostgreSQL-only code, and `FETCH FIRST` when you want portable SQL.

There is one extra option:

```sql
FETCH FIRST 2 ROWS WITH TIES
```

`WITH TIES` also returns any extra rows that tie with the last row on the `ORDER BY` value. If the 2nd and 3rd salary were equal, you would get 3 rows. It needs an `ORDER BY`.

## 5. Special values and rules

|Form|Result|
|---|---|
|`LIMIT 0`|no rows (columns still returned, handy to check a query's shape)|
|`LIMIT NULL` or `LIMIT ALL`|no limit at all|
|`LIMIT -1`|error: `LIMIT must not be negative`|
|`OFFSET 0`|same as having no offset|
|`LIMIT 1.5`|a number is cast to bigint, so the value is rounded|
|`LIMIT (SELECT ...)`|allowed if the subquery returns one value|

`LIMIT` takes a **parameter** as well, which matters in Spring: `LIMIT :size OFFSET :offset`.

## 6. Where LIMIT can appear

**Inside a subquery**, for "top N per group" or "latest row":

```sql
SELECT * FROM departments d
WHERE d.id = (SELECT department_id FROM employees ORDER BY salary DESC NULLS LAST LIMIT 1);
```

The inner query returns the department of the best-paid employee, because `LIMIT 1` makes sure it returns one value.

**Inside a LATERAL join**, to get the top 2 employees of each department:

```sql
SELECT d.name, top.name, top.salary
FROM departments d
CROSS JOIN LATERAL (
    SELECT e.name, e.salary
    FROM employees e
    WHERE e.department_id = d.id
    ORDER BY e.salary DESC NULLS LAST
    LIMIT 2
) top;
```

`LATERAL` lets the subquery use `d.id` from the row before it, so the `LIMIT 2` is applied **per department**. A plain `LIMIT 2` at the end would give only two rows in total.

**With UNION:** each part needs parentheses if it has its own `LIMIT`.

```sql
(SELECT name FROM employees ORDER BY salary DESC NULLS LAST LIMIT 1)
UNION ALL
(SELECT name FROM departments ORDER BY name LIMIT 1);
```

**Not allowed directly in `UPDATE` or `DELETE`.** `DELETE FROM employees LIMIT 1` is a syntax error. Use a subquery:

```sql
DELETE FROM employees
WHERE id IN (SELECT id FROM employees ORDER BY hired_on LIMIT 1);
```

This links back to your DML lesson.

## 7. Performance: what LIMIT really saves

`LIMIT` does not always make a query fast. It depends on whether PostgreSQL has to compute everything before it can pick the first rows.

- **Fast case:** `ORDER BY id LIMIT 10` when `id` has an index. PostgreSQL reads the index in order and stops after 10 rows.
- **Slow case:** `ORDER BY` on a column with no index. PostgreSQL must read and sort **all** rows, then throw most of them away.
- **Slow case:** a large `OFFSET`. `OFFSET 1000000 LIMIT 10` still reads and discards a million rows.

You can check with:

```sql
EXPLAIN ANALYZE SELECT * FROM employees ORDER BY id LIMIT 10;
```

Look for `Limit` on top of an `Index Scan`. A `Sort` node below the `Limit` means PostgreSQL sorted everything.

### Keyset pagination (the fast alternative to OFFSET)

Instead of skipping rows, remember the last row you saw and continue after it:

```sql
SELECT id, name FROM employees
WHERE id > 20          -- last id from the previous page
ORDER BY id
LIMIT 10;
```

This uses the index to jump straight to the right place, so page 1 and page 100000 cost the same. The trade-off is that you cannot jump to "page 57" directly, only to "the next page".

## 8. Common mistakes

|Mistake|What happens|Fix|
|---|---|---|
|`LIMIT` without `ORDER BY`|rows are random, and pages can repeat or skip rows|always sort|
|Sorting by a non-unique column only|rows jump between pages|add `id` as a tie-breaker|
|Huge `OFFSET`|slow queries|keyset pagination|
|Filtering with `WHERE` after you expected `LIMIT` first|`WHERE` runs **before** `LIMIT`|use a subquery if you need "limit first, then filter"|
|`DELETE ... LIMIT`|syntax error|`WHERE id IN (subquery with LIMIT)`|
|Counting total pages with `LIMIT`|`COUNT(*)` ignores the limit|run a separate `SELECT COUNT(*)`|

## 9. LIMIT in Spring Boot

With Spring Data JPA you rarely write `LIMIT` yourself:

```java
List<Employee> findTop2ByOrderBySalaryDesc();               // derived query
Page<Employee> findByDepartmentId(Long id, Pageable pageable);
```

And when you call it:

```java
Pageable pageable = PageRequest.of(0, 10, Sort.by("salary").descending());
Page<Employee> page = repository.findByDepartmentId(1L, pageable);
```

What each part does:

- `Top2` becomes `LIMIT 2`.
- `PageRequest.of(0, 10, ...)` means page index 0 (pages start at 0 here), size 10, so Spring runs `LIMIT 10 OFFSET 0`.
- `Page` makes Spring run an **extra** `SELECT COUNT(*)` to know the total pages. If you do not need the total, return `Slice<Employee>`, which skips that count query and is cheaper.
- In a native query, you write it yourself: `@Query(value = "select * from employees order by id limit :size offset :offset", nativeQuery = true)`.

## Related concept, in short

- **OFFSET:** skips a number of rows before `LIMIT` starts counting. Together they make pages, but a large `OFFSET` is slow.
- **Cursor:** a way to read a big result in batches without loading it all (`DECLARE ... CURSOR`). JDBC does this with `setFetchSize()`, which is different from `LIMIT` because it does not change the result, only how it is delivered.

## Quick summary

- `LIMIT n` keeps the first `n` rows and runs last in a query.
- Always pair it with `ORDER BY`, and add a unique tie-breaker.
- `OFFSET` skips rows, `FETCH FIRST ... WITH TIES` is the standard form with tie support.
- `LIMIT` is not allowed in `UPDATE` and `DELETE`. Use a subquery.
- Big offsets are slow, so use keyset pagination for large tables.
- In Spring, `Top2`, `Pageable` and `Slice` produce `LIMIT` for you.




[[PostgreSQL]]