

`INSERT`, `UPDATE` and `DELETE` are the three DML commands (Data Manipulation Language) that change the **rows** inside a table. `INSERT` adds new rows, `UPDATE` changes values in existing rows, and `DELETE` removes rows. The table itself stays the same. That is the difference from DDL: `ALTER` and `DROP` change the structure, and these three change the data.

They look simple, but they hide the mistakes that cost the most in real projects: an `UPDATE` or `DELETE` without `WHERE` changes every row, an `INSERT` hits a duplicate key, and a delete is blocked by a foreign key. PostgreSQL also has features here that other databases lack, mainly `RETURNING` (get the changed rows back) and `ON CONFLICT` (insert or update in one command). This lesson goes through each command, then shows how they combine, and how Spring Boot uses them.

## The tables we use

|id|name|salary|department_id|hired_on|
|---|---|---|---|---|
|1|Ana|5000|1|2022-03-01|
|2|Omar|4200|1|2023-07-15|
|3|Lina|3900|2|2024-01-10|
|4|Sam|NULL|NULL|2024-09-02|

`departments` has `1 Backend`, `2 Frontend`, `3 QA`. For the upsert section, we also assume `employees` has a unique `email` column, as we added in the ALTER lesson:

```sql
ALTER TABLE employees ADD COLUMN email text UNIQUE;
```

---

# Part 1: INSERT

## Basic form

```sql
INSERT INTO employees (name, salary, department_id, hired_on)
VALUES ('Maya', 4800, 1, '2025-02-01');
```

Line by line:

- `INSERT INTO employees` says which table.
- `(name, salary, department_id, hired_on)` is the **column list**. Always write it. Without it, values must match _every_ column in table order, and the statement breaks the moment someone adds a column.
- `VALUES (...)` gives one value per listed column, in the same order.
- We left out `id` and `email`. A column you do not list gets its `DEFAULT`, or `NULL` if it has none. Here `id` is a `serial`, so PostgreSQL generates it.

PostgreSQL answers with a command tag: `INSERT 0 1`. The `1` is the number of rows inserted (the `0` is an old leftover you can ignore).

## Several rows in one statement

```sql
INSERT INTO employees (name, salary, department_id)
VALUES ('Noor', 4100, 2),
       ('Ravi', 3700, 3),
       ('Eli',  NULL, NULL);
```

One statement with many rows is much faster than many single-row statements, and it is all-or-nothing: if one row fails, none are inserted.

## Defaults and special values

```sql
INSERT INTO employees (name, salary) VALUES ('Zoe', DEFAULT);   -- DEFAULT keyword for one column
INSERT INTO logs DEFAULT VALUES;                                 -- every column uses its default
```

Text goes in single quotes, and a quote inside the text is doubled: `'O''Brien'`. Dates are written as text too: `'2025-02-01'`. In application code, never build this text yourself. Use parameters (`?` in JDBC), the same reason you learned `PreparedStatement`.

## INSERT ... SELECT: insert rows from a query

```sql
INSERT INTO employees_archive (id, name, salary)
SELECT id, name, salary
FROM employees
WHERE hired_on < '2023-01-01';
```

Instead of `VALUES`, any `SELECT` from the DQL lesson can feed the insert. The column count and types must match the column list.

## RETURNING: get the new rows back

```sql
INSERT INTO employees (name, salary)
VALUES ('Maya', 4800)
RETURNING id, name;
```

|id|name|
|---|---|
|5|Maya|

This gives you the generated `id` in the **same command**, with no second query. It works on `INSERT`, `UPDATE` and `DELETE`. It is the PostgreSQL way to read generated keys.

## ON CONFLICT: the upsert

An "upsert" means: insert the row, but if it already exists, update it instead.

```sql
INSERT INTO employees (name, email, salary)
VALUES ('Ana', 'ana@example.com', 5500)
ON CONFLICT (email)
DO UPDATE SET salary = EXCLUDED.salary
RETURNING id, name, salary;
```

- `ON CONFLICT (email)` says which unique column or index to watch.
- `DO UPDATE SET ...` runs **if** a row with that email already exists.
- `EXCLUDED` is a special name for the row you _tried_ to insert, so `EXCLUDED.salary` is `5500`.
- If the email is new, it is a normal insert.

If you only want to skip duplicates and not change anything:

```sql
INSERT INTO employees (name, email) VALUES ('Ana', 'ana@example.com')
ON CONFLICT (email) DO NOTHING;
```

Rules: `DO UPDATE` needs the conflict target (`(email)` or `ON CONSTRAINT name`), the target must be backed by a unique index or constraint, and one statement cannot try to change the same key twice (`ON CONFLICT DO UPDATE command cannot affect row a second time`).

## INSERT errors

|Error message|Cause|Fix|
|---|---|---|
|`null value in column "name" ... violates not-null constraint`|you left out a required column|provide a value|
|`duplicate key value violates unique constraint "employees_pkey"`|the key already exists|use a different key, or `ON CONFLICT`|
|`insert or update on table "employees" violates foreign key constraint ...`|`department_id` points to a department that does not exist|insert the department first|
|`INSERT has more expressions than target columns`|more values than listed columns|match the counts|
|`invalid input syntax for type integer: "abc"`|the value does not fit the type|fix the value or cast it with `::`|
|`value too long for type character varying(10)`|text longer than the column allows|shorten it, or `ALTER` the column|

**A sequence trap:** if you insert rows with your own ids (`INSERT ... (id, ...) VALUES (10, ...)`), the `serial` sequence does not know. Later, an insert without `id` can collide with `duplicate key ... employees_pkey`. Fix it by moving the sequence forward:

```sql
SELECT setval(pg_get_serial_sequence('employees', 'id'), (SELECT MAX(id) FROM employees));
```

---

# Part 2: UPDATE

## Basic form

```sql
UPDATE employees
SET salary = 5200
WHERE id = 1;
```

- `SET` lists the new values.
- `WHERE` picks **which rows** change. The tag `UPDATE 1` tells you one row changed.

**Without `WHERE`, every row changes.** `UPDATE employees SET salary = 0;` zeroes the whole table, and PostgreSQL does not ask. A good habit: first run the same `WHERE` as a `SELECT` and look at the rows, then change `SELECT *` to `UPDATE ... SET`.

## Calculating from the old value

```sql
UPDATE employees
SET salary = salary * 1.10
WHERE department_id = 1;
```

|id|name|salary (before)|salary (after)|
|---|---|---|---|
|1|Ana|5000|5500.00|
|2|Omar|4200|4620.00|

The right side of `=` always sees the **old** values of the row. That is why you can write `salary = salary * 1.10`, and why this swap works:

```sql
UPDATE t SET a = b, b = a;   -- really swaps the two columns
```

`NULL` stays `NULL` through arithmetic, so Sam's salary does not change in `salary * 1.10`.

## Several columns

```sql
UPDATE employees
SET salary = 6000, department_id = 2
WHERE id = 1;

UPDATE employees
SET (salary, department_id) = (6000, 2)    -- same thing, grouped form
WHERE id = 1;
```

## UPDATE with another table: FROM

To use data from another table, add `FROM`:

```sql
UPDATE employees e
SET salary = e.salary + 100
FROM departments d
WHERE d.id = e.department_id
  AND d.name = 'Backend';
```

- `FROM departments d` brings the second table in.
- The `WHERE` joins the two tables, then filters.
- In `SET`, write the column **without** the alias (`SET salary = ...`, not `SET e.salary = ...`, which is a syntax error). On the right side, aliases are fine.

You can also use a subquery:

```sql
UPDATE employees
SET salary = (SELECT AVG(salary) FROM employees)
WHERE salary IS NULL;
```

## RETURNING with UPDATE

```sql
UPDATE employees SET salary = salary + 50 WHERE id = 2
RETURNING id, name, salary;
```

You get the **new** values. In PostgreSQL 18 and newer, `RETURNING` can also give the old values with `old.salary`.

## What UPDATE does inside PostgreSQL

PostgreSQL never edits a row in place. An `UPDATE` writes a **new version** of the row and marks the old version as dead. The dead versions are cleaned later by `VACUUM` (which runs automatically). The practical result: updating every row of a big table can temporarily make it about twice as large. For huge updates, change the rows in batches.

---

# Part 3: DELETE

## Basic form

```sql
DELETE FROM employees WHERE id = 4;
```

The tag `DELETE 1` shows how many rows were removed. Like `UPDATE`, a `DELETE` without `WHERE` removes **every row**, but the table itself stays (that is the difference from `DROP`, from the last lesson).

## DELETE with another table: USING

```sql
DELETE FROM employees e
USING departments d
WHERE e.department_id = d.id
  AND d.name = 'QA';
```

`USING` is the `DELETE` version of `UPDATE ... FROM`: it brings in a second table so the `WHERE` can use it. A subquery works too:

```sql
DELETE FROM employees
WHERE department_id IN (SELECT id FROM departments WHERE name = 'QA');
```

`DELETE` has no `LIMIT`. To remove only a few rows, use a subquery with `LIMIT` (from the LIMIT lesson):

```sql
DELETE FROM employees
WHERE id IN (SELECT id FROM employees ORDER BY hired_on LIMIT 10);
```

## RETURNING with DELETE

```sql
DELETE FROM employees WHERE salary IS NULL RETURNING *;
```

PostgreSQL shows you the rows it just removed. That is a useful safety net: you see exactly what disappeared.

## Foreign keys can block a DELETE

```sql
DELETE FROM departments WHERE id = 1;
```

```
ERROR:  update or delete on table "departments" violates foreign key constraint
        "employees_department_id_fkey" on table "employees"
```

Employees still point to department 1. What happens is decided by the foreign key's `ON DELETE` rule, set when the key is created (see your DDL lesson):

|Rule|What a delete of the parent row does|
|---|---|
|`NO ACTION` (default) / `RESTRICT`|error, the delete is refused|
|`CASCADE`|also deletes the child rows|
|`SET NULL`|sets the child's column to `NULL`|
|`SET DEFAULT`|sets the child's column to its default|

```sql
ALTER TABLE employees
    ADD CONSTRAINT fk_dept FOREIGN KEY (department_id)
    REFERENCES departments(id) ON DELETE SET NULL;
```

`CASCADE` is convenient but dangerous: one `DELETE` can remove thousands of rows in other tables.

## DELETE vs TRUNCATE

`DELETE` without `WHERE` removes rows one by one (slow on big tables, and it leaves dead rows for `VACUUM`). `TRUNCATE employees;` empties the whole table at once and is much faster, but you cannot use `WHERE` with it. We compared them in the DROP lesson.

---

# Part 4: Combining and using them safely

## Wrap changes in a transaction

```sql
BEGIN;
UPDATE employees SET salary = salary * 1.10 WHERE department_id = 1;
SELECT id, name, salary FROM employees WHERE department_id = 1;   -- check the result
COMMIT;                                                            -- or ROLLBACK;
```

Until `COMMIT`, nobody else sees your changes, and `ROLLBACK` undoes everything. Each statement outside a transaction is committed on its own (autocommit).

## Data-modifying CTEs

`INSERT`, `UPDATE` and `DELETE ... RETURNING` can sit inside a `WITH`, from the CTE lesson. This moves rows from one table to another in **one statement**:

```sql
WITH moved AS (
    DELETE FROM employees
    WHERE hired_on < '2023-01-01'
    RETURNING id, name, salary
)
INSERT INTO employees_archive (id, name, salary)
SELECT id, name, salary FROM moved;
```

- The `DELETE` runs first and returns the removed rows as `moved`.
- The `INSERT` reads `moved` and writes them to the archive.
- Both happen together, so no row is lost or copied twice.

## Counting the affected rows

Every command returns a tag: `INSERT 0 3`, `UPDATE 2`, `DELETE 1`. In JDBC this number is the return value of `executeUpdate()` (your PreparedStatement lesson). If you expected one row and got `0`, your `WHERE` matched nothing.

---

# Part 5: In a Spring Boot project

With Spring Data JPA, you rarely write these three commands yourself:

|You write|Hibernate sends|
|---|---|
|`repository.save(newEmployee)` (id is `null`)|`INSERT`|
|`repository.save(existingEmployee)` (id exists)|`UPDATE` (after a `SELECT` to load it, if it is not already loaded)|
|`repository.deleteById(4L)`|a `SELECT` first, then `DELETE`|
|`repository.saveAll(list)`|many `INSERT`s, batched if configured|

For changes to many rows at once, write the query yourself:

```java
@Modifying(clearAutomatically = true)
@Transactional
@Query("update Employee e set e.salary = e.salary * 1.10 where e.department.id = :deptId")
int raiseSalaries(@Param("deptId") Long deptId);
```

- `@Modifying` tells Spring this query changes data, not reads it.
- `@Transactional` makes sure it runs in a transaction (see your proxy lesson).
- `clearAutomatically = true` empties the persistence context afterwards. Otherwise, entities already loaded in memory still show the **old** salary, because this query goes straight to the database.
- The `int` return value is the number of rows affected.

Two more points:

- **Upserts and `RETURNING`** are PostgreSQL SQL, so use a native query (`nativeQuery = true`) or `JdbcTemplate` for them.
- **Batching inserts:** set `spring.jpa.properties.hibernate.jdbc.batch_size=50`. Hibernate cannot batch inserts for `GenerationType.IDENTITY` ids, because it needs each generated id immediately. Use a sequence-based generator if you insert many rows.

---

## Related concept, in short

**MERGE** (PostgreSQL 15 and newer) is the standard SQL version of "insert, update or delete depending on whether a row matches." It compares a source with a target table and runs different actions for matched and unmatched rows:

```sql
MERGE INTO employees t
USING new_data s ON t.email = s.email
WHEN MATCHED THEN UPDATE SET salary = s.salary
WHEN NOT MATCHED THEN INSERT (name, email, salary) VALUES (s.name, s.email, s.salary);
```

For a simple upsert on one unique key, `ON CONFLICT` is shorter and safer under concurrent writes. `MERGE` is better when you need several different actions.

## Quick summary

- `INSERT` adds rows. Always list the columns, and use `RETURNING` to get generated ids.
- `ON CONFLICT (col) DO UPDATE` is the upsert, and `EXCLUDED` is the row you tried to insert.
- `UPDATE ... SET ... WHERE` changes rows. The right side sees old values, and joins use `FROM`.
- `DELETE FROM ... WHERE` removes rows. Joins use `USING`, and foreign keys decide whether the delete is blocked, cascaded or set to `NULL`.
- Without `WHERE`, `UPDATE` and `DELETE` touch every row. Run the `SELECT` first, and use a transaction.
- `RETURNING` works on all three, and data-modifying CTEs can chain them in one statement.
- In Spring, `save`/`deleteById` are simple, bulk changes need `@Modifying @Query` with `@Transactional`, and PostgreSQL-only features need a native query.




[[PostgreSQL]]