

`WHERE` is the clause that decides which rows a statement cares about. Put it on a `SELECT` and you get only the matching rows back. Put it on an `UPDATE` or `DELETE` and you change only the matching rows. Without it, the statement applies to every row in the table.

It looks like the simplest part of SQL, and the basics are. But `WHERE` is also where most of the real-world surprises live: `NULL` behaving strangely, conditions that quietly stop using your index, an alias you can't reference, an `OR` that matched more than you meant. This tutorial starts with the basics, then goes through the places where `WHERE` bites.

---

## A table to play with

Every example below uses this table:

```sql
CREATE TABLE employees (
    id          serial PRIMARY KEY,
    name        text NOT NULL,
    department  text,
    salary      numeric(10,2),
    hired_on    date NOT NULL,
    manager_id  int,
    email       text,
    is_active   boolean NOT NULL DEFAULT true
);
```

Some of its columns (`department`, `salary`, `manager_id`, `email`) allow `NULL`. That is deliberate, because `NULL` is the source of most `WHERE` confusion.

## The mental model: WHERE is a sieve

For every row, Postgres evaluates your condition. The result can be `TRUE`, `FALSE`, or `NULL` (unknown). **Only rows where the condition is exactly `TRUE` are kept.** Both `FALSE` and `NULL` rows are thrown away.

```sql
SELECT name, salary
FROM employees
WHERE salary > 50000;
```

Keep that "only `TRUE` survives" rule in mind. It explains almost every confusing result in the NULL section later.

## The everyday operators

**Comparison:** `=`, `<>` (or `!=`), `<`, `>`, `<=`, `>=`

```sql
WHERE department = 'Sales'
WHERE hired_on >= '2024-01-01'
WHERE salary <> 0
```

Note that SQL uses a single `=` for equality, and strings use single quotes. Double quotes are for identifiers like column names.

**Combining conditions:** `AND`, `OR`, `NOT`

```sql
WHERE department = 'Sales' AND salary > 60000
WHERE department = 'Sales' OR department = 'Support'
WHERE NOT is_active
```

**Precedence matters.** `NOT` binds tightest, then `AND`, then `OR`. So this does not mean what it looks like:

```sql
-- Intended: active employees in Sales or Support
WHERE is_active AND department = 'Sales' OR department = 'Support'
-- Actual: (active AND Sales) OR Support, so inactive Support staff slip in
```

Fix it with parentheses, and use them whenever `AND` and `OR` mix:

```sql
WHERE is_active AND (department = 'Sales' OR department = 'Support')
```

**Ranges and lists:**

```sql
WHERE salary BETWEEN 40000 AND 60000       -- inclusive on both ends
WHERE department IN ('Sales', 'Support', 'HR')
WHERE department NOT IN ('HR', 'Legal')
```

`BETWEEN a AND b` is just `>= a AND <= b`. The "both ends included" part causes trouble with timestamps, which we'll fix below.

## Matching text

```sql
WHERE name LIKE 'An%'        -- starts with An     (case-sensitive)
WHERE name ILIKE 'an%'       -- same, ignoring case (Postgres-specific)
WHERE email LIKE '%@example.com'
WHERE name LIKE 'J_n'        -- _ matches exactly one character: Jan, Jon
```

`%` means any number of characters (including none) and `_` means exactly one. To match a literal `%` or `_`, escape it with a backslash: `LIKE '100\%'`.

For real pattern matching, Postgres supports POSIX regular expressions:

```sql
WHERE name ~ '^(Ana|Bob)'      -- matches regex (case-sensitive)
WHERE name ~* '^ana'           -- case-insensitive
WHERE name !~ 'test'           -- does NOT match
```

## NULL: the part everyone trips over

`NULL` doesn't mean zero or empty string. It means "unknown." And comparing anything to an unknown gives an unknown answer:

```sql
SELECT NULL = NULL;      -- NULL, not true
SELECT NULL <> 5;        -- NULL, not true
SELECT 5 = NULL;         -- NULL
```

Since only `TRUE` survives a `WHERE`, this returns nothing, even if there are plenty of rows with no department:

```sql
SELECT * FROM employees WHERE department = NULL;   -- always empty
```

Use `IS NULL` and `IS NOT NULL`:

```sql
WHERE department IS NULL
WHERE manager_id IS NOT NULL
```

### The silent filter

This one catches people constantly. Suppose Dana's department is `NULL`. You want everyone _not_ in Sales:

```sql
SELECT name FROM employees WHERE department <> 'Sales';
```

Dana is **not** in the results. `NULL <> 'Sales'` is `NULL`, so her row is discarded. If you want her included, say so:

```sql
WHERE department <> 'Sales' OR department IS NULL
-- or, more compactly:
WHERE department IS DISTINCT FROM 'Sales'
```

`IS DISTINCT FROM` is a null-safe comparison: it treats `NULL` as a regular value, so `NULL IS DISTINCT FROM 'Sales'` is `TRUE`, and `NULL IS DISTINCT FROM NULL` is `FALSE`. Its counterpart is `IS NOT DISTINCT FROM`, a null-safe equals.

### The NOT IN trap

```sql
SELECT name FROM employees
WHERE id NOT IN (SELECT manager_id FROM employees);
-- intended: employees who are not anyone's manager
```

If even **one** `manager_id` is `NULL`, this returns **zero rows**. Here's why: `x NOT IN (1, 2, NULL)` expands to `x <> 1 AND x <> 2 AND x <> NULL`, and that last part is `NULL`, which poisons the whole `AND`. The result can never be `TRUE`.

Two safe fixes:

```sql
-- Filter the NULLs out of the subquery
WHERE id NOT IN (SELECT manager_id FROM employees WHERE manager_id IS NOT NULL)

-- Or use NOT EXISTS, which has no such problem (usually the better choice)
WHERE NOT EXISTS (
    SELECT 1 FROM employees m WHERE m.manager_id = employees.id
)
```

### Booleans and NULL

For a nullable boolean column, `WHERE flag` keeps `TRUE` rows and `WHERE NOT flag` keeps `FALSE` rows, but neither keeps `NULL` rows. When you need to be explicit, Postgres offers `IS TRUE`, `IS NOT TRUE`, `IS FALSE`, `IS NOT FALSE`, and `IS UNKNOWN`. For example, `WHERE flag IS NOT TRUE` returns both `FALSE` and `NULL` rows.

## Dates and timestamps: use half-open ranges

Because `BETWEEN` includes both endpoints, it's risky with timestamps. Say `created_at` is a `timestamptz`:

```sql
-- Looks like "all of January", but...
WHERE created_at BETWEEN '2025-01-01' AND '2025-01-31'
-- '2025-01-31' means midnight at the START of Jan 31, so everything later that day is missed
```

The robust pattern is to include the start and exclude the end:

```sql
WHERE created_at >= '2025-01-01'
  AND created_at <  '2025-02-01'
```

It works for any granularity, never double-counts a boundary row, and doesn't depend on how precise the timestamps are. It also lets Postgres use an index on the column.

## More operators worth knowing

**ANY and ALL** compare against a set or array:

```sql
WHERE salary > ANY (SELECT salary FROM employees WHERE department = 'HR')  -- more than at least one
WHERE salary > ALL (SELECT salary FROM employees WHERE department = 'HR')  -- more than every one
WHERE department = ANY (ARRAY['Sales', 'Support'])                         -- same as IN
```

`= ANY(array)` is especially handy when you pass an array as a single parameter instead of building a variable-length `IN` list.

**Arrays, ranges, and JSON** have their own operators that work in `WHERE`:

```sql
WHERE tags @> ARRAY['urgent']          -- array contains
WHERE validity @> now()                -- range contains a value
WHERE profile ->> 'city' = 'Berlin'    -- text extracted from a JSON column
WHERE profile @> '{"plan": "pro"}'     -- jsonb containment
```

**Row-wise comparison** compares several columns as one unit, which is perfect for pagination:

```sql
WHERE (hired_on, id) > ('2024-06-01', 120)
ORDER BY hired_on, id
LIMIT 50;
```

That fetches the "next page" after a known position without the cost of `OFFSET`.

## Subqueries in WHERE

A `WHERE` condition can contain a whole query:

```sql
-- Scalar subquery: returns a single value
WHERE salary > (SELECT avg(salary) FROM employees)

-- IN subquery: returns a list
WHERE department IN (SELECT name FROM departments WHERE region = 'EU')

-- EXISTS: "is there at least one matching row?"
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.employee_id = employees.id
)
```

The `EXISTS` example is a **correlated subquery**: it refers to the outer row (`employees.id`) and is conceptually evaluated per outer row. Postgres is smart about it and usually turns `EXISTS`/`NOT EXISTS` into efficient semi-joins and anti-joins, so don't avoid them out of performance fear. `EXISTS` only cares whether a row exists, so what you `SELECT` inside (`1`, `*`, anything) doesn't matter.

## Why you can't use some things in WHERE

Postgres processes a query's clauses in a logical order that differs from how you write them:

1. `FROM` (and joins)
2. **`WHERE`**
3. `GROUP BY`
4. `HAVING`
5. `SELECT` (this is where aliases are created)
6. `ORDER BY`
7. `LIMIT`

Two famous errors come straight from this order.

**You can't use a select-list alias in WHERE**, because the alias doesn't exist yet when `WHERE` runs:

```sql
SELECT salary * 12 AS yearly FROM employees
WHERE yearly > 600000;                 -- ERROR: column "yearly" does not exist

-- Repeat the expression...
WHERE salary * 12 > 600000
-- ...or wrap it in a subquery/CTE
SELECT * FROM (SELECT salary * 12 AS yearly FROM employees) e WHERE yearly > 600000;
```

(`ORDER BY` runs after `SELECT`, so aliases _are_ allowed there.)

**You can't use aggregates or window functions in WHERE**, because rows haven't been grouped yet:

```sql
WHERE count(*) > 5          -- ERROR: aggregate functions are not allowed in WHERE
```

That's what `HAVING` is for.

### WHERE vs HAVING vs FILTER

- **`WHERE`** filters individual rows _before_ grouping.
- **`HAVING`** filters groups _after_ aggregation.
- **`FILTER`** filters rows _inside a single aggregate_.

```sql
SELECT department, count(*) AS headcount
FROM employees
WHERE is_active                        -- row filter: only active people are counted
GROUP BY department
HAVING count(*) > 5;                   -- group filter: only departments with 6+ people

SELECT
    count(*)                                   AS everyone,
    count(*) FILTER (WHERE is_active)          AS active,
    avg(salary) FILTER (WHERE department = 'Sales') AS avg_sales_salary
FROM employees;
```

Put row-level conditions in `WHERE`, not `HAVING`. It's faster, because rows are discarded before the grouping work happens.

## WHERE vs ON in joins

For an `INNER JOIN`, putting a condition in `ON` or `WHERE` gives the same result. For an `OUTER JOIN`, it very much does not:

```sql
-- All customers, with their 2025 orders (customers with none still appear)
SELECT c.name, o.id
FROM customers c
LEFT JOIN orders o
       ON o.customer_id = c.id AND o.created_at >= '2025-01-01';

-- Condition in WHERE: customers with no 2025 orders vanish
SELECT c.name, o.id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.created_at >= '2025-01-01';
```

In the second query, unmatched customers get `NULL` for `o.created_at`, the `WHERE` rejects those rows, and the `LEFT JOIN` has silently become an `INNER JOIN`. The rule of thumb: for the **optional** side of an outer join, conditions on it belong in `ON`.

## Making WHERE fast

A `WHERE` clause on a big table is only as fast as Postgres's ability to avoid reading every row, and that means indexes. Use `EXPLAIN` to see what the planner chose:

```sql
EXPLAIN ANALYZE
SELECT * FROM employees WHERE email = 'ana@example.com';
```

Look for `Index Scan` or `Index Only Scan` versus `Seq Scan` (reading the whole table). A seq scan isn't automatically bad (for tiny tables, or when you're fetching most rows, it's the right choice), but on a selective filter over a large table it's a red flag.

A few rules separate conditions that can use an index from ones that can't.

**Don't wrap the column in a function.** Postgres can't use a plain index on `email` for this:

```sql
WHERE lower(email) = 'ana@example.com'     -- index on email is useless here
```

Either index the expression itself, or avoid the function:

```sql
CREATE INDEX ON employees (lower(email));  -- expression index, now the query above is fast
```

The same applies to date math: `WHERE date_trunc('month', hired_on) = '2025-01-01'` can't use an index on `hired_on`, but the half-open range `hired_on >= '2025-01-01' AND hired_on < '2025-02-01'` can.

**Leading wildcards defeat B-tree indexes.** `LIKE 'An%'` can use an index (with the right operator class, such as `text_pattern_ops`, if your database doesn't use the C collation), but `LIKE '%son'` and `ILIKE '%son%'` cannot. For substring or fuzzy search, the `pg_trgm` extension with a GIN or GiST index is the standard answer.

**Match the types.** Comparing a column to a value of a different type can force a cast on the column side and prevent index use. Filter an `int` column with an integer, not a string-typed parameter, and a `timestamptz` column with a timestamp, not text.

**Partial indexes fit common filters.** If you almost always query active rows, index only those:

```sql
CREATE INDEX ON employees (department) WHERE is_active;
```

It's smaller, faster to maintain, and used when your query's `WHERE` implies the index's condition.

**OR can be tricky.** `WHERE a = 1 OR b = 2` may need a bitmap OR across two indexes, or fall back to a scan. When it's slow, rewriting as a `UNION` of two selective queries is a classic fix.

**Selectivity decides.** Even with a perfect index, if your condition matches 40% of the table the planner will reasonably choose a sequential scan. And keep statistics fresh (`ANALYZE`), because the planner chooses plans based on its estimate of how many rows each condition matches.

## Don't rely on evaluation order

SQL doesn't promise that conditions are checked left to right, or that `AND` short-circuits the way it does in programming languages. So this is unsafe:

```sql
WHERE b <> 0 AND a / b > 2     -- may still raise "division by zero"
```

If a condition must only be evaluated when another is true, force the order with `CASE`:

```sql
WHERE CASE WHEN b <> 0 THEN a / b > 2 ELSE false END
```

## WHERE in UPDATE and DELETE: the dangerous one

On `SELECT`, a wrong `WHERE` gives you the wrong rows to look at. On `UPDATE` and `DELETE`, it destroys data:

```sql
UPDATE employees SET salary = 0;      -- every row. Oops.
DELETE FROM employees;                -- every row. Oops.
```

Habits that protect you:

- **Write the `WHERE` first.** Test it as a `SELECT`, then change the verb:
    
    ```sql
    SELECT * FROM employees WHERE department = 'Temp' AND hired_on < '2023-01-01';
    -- happy with those rows? now:
    DELETE FROM employees WHERE department = 'Temp' AND hired_on < '2023-01-01';
    ```
    
- **Use a transaction** for anything manual, and check the reported row count before committing:
    
    ```sql
    BEGIN;
    UPDATE employees SET is_active = false WHERE hired_on < '2015-01-01';
    -- UPDATE 37   <- expected? 
    COMMIT;         -- or ROLLBACK;
    ```
    
- **Add `RETURNING *`** to see exactly which rows were touched.
    
- When you need to empty a whole table deliberately, `TRUNCATE` is the right tool, and it states your intent clearly.
    

Also: if you build `WHERE` conditions in application code, always pass values as bound parameters rather than gluing them into the SQL string. That's the defense against SQL injection, and it also lets Postgres cache plans more effectively.

## Small things that save time

- `WHERE true` and `WHERE 1=1` are valid and do nothing. Some people use them as a stable first line when generating queries dynamically, so every added condition can simply start with `AND`.
- String comparisons with `=` are case-sensitive and depend on the column's collation. Use `ILIKE`, `lower()` on both sides (with a matching expression index), or the `citext` extension for case-insensitive columns.
- `WHERE x IN (...)` with a very long literal list works but gets unwieldy. For large lists, `= ANY($1)` with an array parameter or a join against a `VALUES` list is cleaner.
- `WHERE CURRENT OF cursor_name` exists for updating or deleting the row a cursor is currently positioned on. It's rare, but good to recognize.

## Try it yourself

Practice questions, roughly in order of difficulty. Try writing each query before you look anything up:

1. Find all active employees in Sales who earn more than 50,000.
2. Find employees with no manager. Then find employees whose department is anything except Sales, **including** those with no department.
3. Find everyone hired during 2024, using a half-open date range.
4. Find employees who don't manage anyone, first with `NOT IN`, then with `NOT EXISTS`. Add a `NULL` manager and see which version breaks.
5. List departments with more than 3 active employees, using both `WHERE` and `HAVING` in the right places.
6. Write a `LEFT JOIN` from departments to employees that keeps empty departments but counts only active employees. (Hint: where does the `is_active` condition go?)
7. Run `EXPLAIN` on `WHERE lower(email) = '...'` before and after creating the expression index, and compare the plans.



[[PostgreSQL]]