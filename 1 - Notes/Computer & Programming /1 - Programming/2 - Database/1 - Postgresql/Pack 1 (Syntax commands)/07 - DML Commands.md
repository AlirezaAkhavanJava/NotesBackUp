

**DML** stands for **Data Manipulation Language**. It is the group of SQL commands that add, change, and remove the **rows** inside your tables. The core commands are `INSERT`, `UPDATE`, and `DELETE`. PostgreSQL also gives you `MERGE` and the bulk loader `COPY`, plus two very handy extras: `ON CONFLICT` (upsert) and `RETURNING`.

In the DDL lesson we built the building: rooms, walls, doors. DML is everything that happens _inside_ it: people moving in, changing rooms, and leaving. Almost every button in your app ("Sign up", "Save", "Delete account") ends up as one of these commands, so this is the part of SQL you will run the most.

---

## 1. Where DML fits

|Group|Purpose|Commands|
|---|---|---|
|DDL|Structure|`CREATE`, `ALTER`, `DROP`, `TRUNCATE`|
|**DML**|**Change rows**|**`INSERT`, `UPDATE`, `DELETE`, `MERGE`, `COPY`**|
|DQL|Read rows|`SELECT`|
|TCL|Transactions|`BEGIN`, `COMMIT`, `ROLLBACK`|

Some books count `SELECT` as part of DML. Others give it its own group, DQL (Data Query Language). Here I treat it as DQL, and use it only to check our results.

---

## 2. Setup: two tables to practice on

Run this once in the Query Tool (a scratch database like `dummy` is perfect):

```sql
CREATE TABLE clients (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    email       varchar(255) NOT NULL UNIQUE,
    status      varchar(20) NOT NULL DEFAULT 'active',
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id  bigint NOT NULL REFERENCES clients (id),
    total      numeric(12,2) NOT NULL CHECK (total >= 0),
    placed_at  timestamptz NOT NULL DEFAULT now()
);
```

Every error message in this lesson comes from the rules above (`NOT NULL`, `UNIQUE`, `CHECK`, the foreign key). That is the point: DDL sets the rules, and DML runs into them.

**Two typing rules that trip up beginners:**

- Text values go in **single quotes**: `'Ali'`. Double quotes mean a _name_ (a column or table). Writing `VALUES ("Ali")` gives `column "Ali" does not exist`.
- To put a single quote inside text, double it: `'O''Brien'`.

---

## 3. `INSERT`: adding rows

**The problem it solves:** Getting new data into a table.

```sql
-- One row
INSERT INTO clients (name, email)
VALUES ('Ali Khan', 'ali@example.com');

-- Several rows in one command
INSERT INTO clients (name, email, status) VALUES
    ('Sara Lee',  'sara@example.com', 'active'),
    ('Tom Wu',    'tom@example.com',  'inactive'),
    ('Mia Costa', 'mia@example.com',  DEFAULT);
```

Line by line:

- `INSERT INTO clients (name, email)` names the table and the columns you will fill.
- `VALUES (...)` gives the values, in the **same order** as the columns.
- Columns you leave out get their default. That's why `id`, `status`, and `created_at` fill themselves.
- `DEFAULT` can also be written explicitly, as with Mia's status.
- The multi-row form is faster than many separate inserts, because it is one round trip.

### `RETURNING`: get the new row back

```sql
INSERT INTO clients (name, email)
VALUES ('Leo Park', 'leo@example.com')
RETURNING id, created_at;
```

Result:

|id|created_at|
|---|---|
|5|2026-10-25 14:40:12+00|

**The problem it solves:** You usually need the generated `id` right away (to create the client's first order, for example). `RETURNING` gives it to you in the same command, with no second query. This is what Spring Data uses behind the scenes after `save()`.

### `INSERT ... SELECT`: copy rows from a query

```sql
CREATE TABLE clients_archive (LIKE clients);

INSERT INTO clients_archive
SELECT * FROM clients WHERE status = 'inactive';
```

`LIKE clients` copies the column layout. The `INSERT ... SELECT` then fills it with the rows the query returns.

### Inserting into an identity column

```sql
INSERT INTO clients (id, name, email) VALUES (100, 'Old User', 'old@example.com');
```

```
ERROR: cannot insert a non-DEFAULT value into column "id"
DETAIL: Column "id" is an identity column defined as GENERATED ALWAYS.
HINT: Use OVERRIDING SYSTEM VALUE to override.
```

If you really need your own id (for example when importing old data):

```sql
INSERT INTO clients (id, name, email)
OVERRIDING SYSTEM VALUE
VALUES (100, 'Old User', 'old@example.com');
```

Afterwards, the counter doesn't know about id 100, so repair it with the `setval` trick from the pgAdmin lesson.

### Errors you may hit

|Error|Cause|Fix|
|---|---|---|
|`null value in column "name" of relation "clients" violates not-null constraint`|You skipped a required column|Provide the value|
|`duplicate key value violates unique constraint "clients_email_key"` with `Key (email)=(ali@example.com) already exists.`|Email is taken|Use a new value, or an upsert (next section)|
|`insert or update on table "orders" violates foreign key constraint "orders_client_id_fkey"`|`client_id` doesn't exist in `clients`|Insert the client first|
|`new row for relation "orders" violates check constraint "orders_total_check"`|Negative total|Fix the value|
|`INSERT has more target columns than expressions`|Column list and values don't match in count|Count both lists|
|`invalid input syntax for type bigint: "abc"`|Wrong type|Send the right type, or cast with `::`|

---

## 4. Upsert: `INSERT ... ON CONFLICT`

**The problem it solves:** "Insert this row, but if it already exists, update it instead." Without it you'd have to check first, then insert or update, and two users doing that at the same time can still collide. `ON CONFLICT` does it in **one atomic step**.

```sql
INSERT INTO clients (name, email)
VALUES ('Ali K.', 'ali@example.com')
ON CONFLICT (email)
DO UPDATE SET name = EXCLUDED.name, status = 'active';
```

Line by line:

- `ON CONFLICT (email)` says "if this insert would break the unique rule on `email`..."
- `DO UPDATE SET ...` says "...then update the existing row instead."
- `EXCLUDED` is a special name for **the row you tried to insert**. So `EXCLUDED.name` means `'Ali K.'`.

Or, to ignore duplicates silently:

```sql
INSERT INTO clients (name, email)
VALUES ('Ali Khan', 'ali@example.com')
ON CONFLICT (email) DO NOTHING;
```

You can add `RETURNING` to either form to see what happened.

**Errors you may hit:**

- `there is no unique or exclusion constraint matching the ON CONFLICT specification`: the column you named isn't `UNIQUE` or a primary key.
- `ON CONFLICT DO UPDATE command cannot affect row a second time`: your `VALUES` list contains the _same_ key twice. Remove the duplicate.
- Gaps in ids: a conflicting attempt still uses up an identity number. That is normal.

---

## 5. `UPDATE`: changing existing rows

**The problem it solves:** Fixing or changing data that is already stored.

```sql
-- One row
UPDATE clients SET status = 'inactive' WHERE id = 3;

-- Several columns, with an expression
UPDATE clients
SET name = upper(name), status = 'vip'
WHERE email LIKE '%@corp.com';

-- Use the old value
UPDATE orders SET total = total + 5
WHERE placed_at >= now() - interval '1 day';
```

Line by line:

- `UPDATE clients` names the table.
- `SET ...` lists the new values. On the right side, a column name means "its current value."
- `WHERE ...` picks _which_ rows. **Without `WHERE`, every row changes.**
- PostgreSQL replies with a count, such as `UPDATE 2`. Always read it. If you expected 1 and got 0 (or 5000), something is wrong.

### The most important habit in this whole lesson

```sql
BEGIN;
UPDATE clients SET status = 'inactive';          -- oops, forgot WHERE
SELECT status, count(*) FROM clients GROUP BY status;   -- look at the damage
ROLLBACK;                                         -- undo everything
```

Wrap risky `UPDATE` and `DELETE` commands in `BEGIN ... ROLLBACK`, check with a `SELECT`, and only change `ROLLBACK` to `COMMIT` when the result is right. A good second habit: write the `WHERE` first, and test it as a `SELECT` before turning it into an `UPDATE`.

### `UPDATE ... FROM`: change rows using another table

```sql
UPDATE orders o
SET total = round(o.total * 0.90, 2)
FROM clients c
WHERE o.client_id = c.id AND c.status = 'vip';
```

This gives VIP clients a 10% discount on their orders. Line by line: `orders o` gives the table a short alias, `FROM clients c` brings in the second table, and the `WHERE` both joins the two (`o.client_id = c.id`) and filters. In `SET`, the column on the left stays unqualified (`total`, not `o.total`).

### `UPDATE ... RETURNING`

```sql
UPDATE clients SET status = 'active' WHERE id = 3 RETURNING id, status;
```

### Gotchas

- **`NULL` needs `IS NULL`.** `WHERE phone = NULL` matches nothing, ever. Write `WHERE phone IS NULL`.
- **PostgreSQL never edits a row in place.** An `UPDATE` writes a _new version_ of the row and marks the old one dead. The dead rows are cleaned up later by `VACUUM` (which runs automatically). This design is called MVCC, and it is why readers are never blocked by writers.
- `UPDATE` fires any `BEFORE/AFTER UPDATE` triggers, such as the `set_updated_at` one from the last lesson.

---

## 6. `DELETE`: removing rows

**The problem it solves:** Removing data you no longer need.

```sql
DELETE FROM clients WHERE id = 5;
DELETE FROM orders WHERE placed_at < now() - interval '2 years';
```

Again, **no `WHERE` means every row is deleted**. The reply is a count, like `DELETE 1`.

### `DELETE ... USING`: delete based on another table

```sql
DELETE FROM orders o
USING clients c
WHERE o.client_id = c.id AND c.status = 'inactive';
```

### `DELETE ... RETURNING`

```sql
DELETE FROM orders WHERE total = 0 RETURNING id, client_id;
```

### Move rows between tables in one command

You can combine `DELETE ... RETURNING` with a CTE (a `WITH` block) to archive and delete in one safe step:

```sql
WITH removed AS (
    DELETE FROM clients WHERE status = 'inactive' RETURNING *
)
INSERT INTO clients_archive SELECT * FROM removed;
```

Line by line: the `DELETE` runs first and hands its deleted rows to the name `removed`. The `INSERT` then copies those rows into the archive. Everything happens in one statement, so you can't lose rows halfway.

### The foreign key error

```sql
DELETE FROM clients WHERE id = 1;
```

```
ERROR: update or delete on table "clients" violates foreign key constraint
"orders_client_id_fkey" on table "orders"
DETAIL: Key (id)=(1) is still referenced from table "orders".
```

The client still has orders. Your options:

1. Delete the orders first.
2. Redefine the foreign key with `ON DELETE CASCADE` (children vanish too) or `ON DELETE SET NULL`.
3. Don't delete at all. Use a **soft delete**: add a `deleted_at` column and `UPDATE` it instead. Many apps prefer this because deletion can't be undone.

### `DELETE` vs `TRUNCATE`

||`DELETE FROM t`|`TRUNCATE t`|
|---|---|---|
|Category|DML|DDL-like|
|`WHERE` allowed|Yes|No|
|Speed on big tables|Slower|Very fast|
|Fires row triggers|Yes|No|
|Resets identity counter|No|With `RESTART IDENTITY`|

---

## 7. `MERGE`: one command for insert, update, and delete

`MERGE` arrived in PostgreSQL 15, so your PostgreSQL 17 server has it, with extras added in 17.

**The problem it solves:** You have a batch of incoming data (an import, a sync) and you want to compare it with a table: update the matches, insert the new ones, and maybe remove the rest.

```sql
CREATE TEMP TABLE staging (name text, email text);
INSERT INTO staging VALUES ('Ali Khan', 'ali@example.com'), ('Zoe Ng', 'zoe@example.com');

MERGE INTO clients c
USING staging s ON c.email = s.email
WHEN MATCHED THEN
    UPDATE SET name = s.name
WHEN NOT MATCHED THEN
    INSERT (name, email) VALUES (s.name, s.email);
```

Line by line:

- `MERGE INTO clients c` is the target table.
- `USING staging s` is the incoming data.
- `ON c.email = s.email` defines what "the same row" means.
- `WHEN MATCHED` runs for rows found in both. Here it updates the name.
- `WHEN NOT MATCHED` runs for incoming rows with no match. Here it inserts them.

New in PostgreSQL 17: `WHEN NOT MATCHED BY SOURCE THEN DELETE` (act on target rows with no incoming match) and `RETURNING` on `MERGE`.

||`ON CONFLICT`|`MERGE`|
|---|---|---|
|Needs a unique constraint|Yes|No, any `ON` condition|
|Handles delete too|No|Yes|
|Concurrency safety under heavy parallel writes|Stronger (designed for it)|Can raise unique violations if two sessions race|
|Best for|Simple "insert or update one key"|Batch sync with several rules|

Error: `MERGE command cannot affect row a second time` means several incoming rows matched the same target row.

---

## 8. `COPY`: loading and exporting lots of rows

**The problem it solves:** Inserting 100,000 rows with individual `INSERT`s is slow. `COPY` is PostgreSQL's fast path for bulk data.

```sql
-- Load a CSV file that lives on the SERVER
COPY clients (name, email)
FROM '/var/lib/postgresql/clients.csv'
WITH (FORMAT csv, HEADER true);

-- Export a query to a CSV
COPY (SELECT id, name FROM clients WHERE status = 'active')
TO '/var/lib/postgresql/active.csv'
WITH (FORMAT csv, HEADER true);
```

The file path is on the **database server's machine**, and the `postgres` OS user must be able to read it. That needs a superuser, or the `pg_read_server_files` / `pg_write_server_files` roles. On your own machine, the friendlier choices are:

- `\copy` in `psql`, which uses _your_ files and needs no special rights: `\copy clients (name, email) FROM 'clients.csv' CSV HEADER`
- pgAdmin: right-click a table, then **Import/Export Data**.

**Errors:** `could not open file ... for reading: Permission denied`, `missing data for column "email"` (a CSV row is too short), `extra data after last expected column` (too long), `invalid input syntax for type ...` (bad value on a specific line, which the message names).

---

## 9. Transactions: making DML safe

A **transaction** groups commands so they succeed or fail _together_:

```sql
BEGIN;
INSERT INTO clients (name, email) VALUES ('Nia Ode', 'nia@example.com') RETURNING id;   -- say it returns 8
INSERT INTO orders (client_id, total) VALUES (8, 49.90);
COMMIT;      -- save both
```

If the second command fails, run `ROLLBACK;` and the client insert disappears too. Without a transaction, you could end up with a client but no order.

|Command|Meaning|
|---|---|
|`BEGIN`|Start a group|
|`COMMIT`|Save everything in the group|
|`ROLLBACK`|Throw everything away|
|`SAVEPOINT a` / `ROLLBACK TO a`|Undo back to a mark inside the group|

By default, each single statement is its own transaction and commits immediately (**auto-commit**). pgAdmin's Query Tool has an auto-commit toggle in its toolbar, so check it when you want to test with `ROLLBACK`.

If a command fails inside a transaction, PostgreSQL refuses all further commands:

```
ERROR: current transaction is aborted, commands ignored until end of transaction block
```

Run `ROLLBACK;` and start again.

---

## 10. DML in Spring Boot

|SQL|Spring Data / JPA|Notes|
|---|---|---|
|`INSERT`|`repository.save(newEntity)`|With `IDENTITY` ids, Hibernate uses `INSERT ... RETURNING`-style retrieval to get the id|
|`UPDATE`|`repository.save(existingEntity)`, or just change a managed entity inside `@Transactional`|Hibernate sends the `UPDATE` at commit ("dirty checking")|
|`DELETE`|`repository.deleteById(id)`||
|Bulk `UPDATE`/`DELETE`|`@Modifying @Query`|See below|
|Upsert|Native query with `ON CONFLICT`|JPA has no upsert|
|`COPY`|`CopyManager` from the PostgreSQL driver|For big imports|

A bulk update, which changes many rows in **one SQL command** instead of loading each entity:

```java
public interface ClientRepository extends JpaRepository<Client, Long> {

    @Modifying(clearAutomatically = true)
    @Transactional
    @Query("update Client c set c.status = :status where c.createdAt < :before")
    int deactivateOld(@Param("status") String status,
                      @Param("before") Instant before);
}
```

Line by line: `@Modifying` marks the query as `UPDATE`/`DELETE` rather than `SELECT`. `@Transactional` is required, or you get `TransactionRequiredException: Executing an update/delete query`. The `int` return is the row count, the same number PostgreSQL shows as `UPDATE 7`. `clearAutomatically = true` empties Hibernate's cache afterward, because a bulk command changes rows behind its back, and stale entities would otherwise show old values.

An upsert, as a native query:

```java
@Modifying
@Transactional
@Query(value = """
    INSERT INTO clients (name, email) VALUES (:name, :email)
    ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
    """, nativeQuery = true)
int upsert(@Param("name") String name, @Param("email") String email);
```

How SQL errors reach Java:

|PostgreSQL error|Java exception|
|---|---|
|Unique, foreign key, not-null, or check violation|`DataIntegrityViolationException` (the real cause names the constraint, such as `clients_email_key`)|
|Deadlock|`CannotAcquireLockException`|
|Connection problems|`DataAccessResourceFailureException`|

Catch `DataIntegrityViolationException` in a service or `@ControllerAdvice` and turn it into a friendly message like "That email is already registered."

**Performance note:** `saveAll()` on a list sends one `INSERT` per row by default. For large batches, set `spring.jpa.properties.hibernate.jdbc.batch_size=50`. Be aware that `GenerationType.IDENTITY` disables Hibernate's insert batching. For heavy imports, use a sequence-based id strategy, `JdbcTemplate.batchUpdate`, or `COPY`.

---

## Related concepts, in short

- **ACID:** the four promises of a transaction. _Atomic_ (all or nothing), _Consistent_ (rules stay satisfied), _Isolated_ (concurrent users don't see each other's half-done work), _Durable_ (committed data survives a crash).
- **Locks and concurrency:** `UPDATE` and `DELETE` lock the rows they touch until commit. A second session changing the same row waits. Keep transactions short.
- **Triggers:** functions that run automatically on DML, like the `set_updated_at` trigger from the last lesson.
- **`VACUUM`:** background cleanup of the dead row versions that `UPDATE` and `DELETE` leave behind.

---

## Quick cheat sheet

```sql
INSERT INTO t (a, b) VALUES (1, 'x') RETURNING id;
INSERT INTO t (a, b) VALUES (1, 'x'), (2, 'y');
INSERT INTO t2 SELECT * FROM t WHERE ...;
INSERT ... ON CONFLICT (key) DO UPDATE SET a = EXCLUDED.a;
INSERT ... ON CONFLICT DO NOTHING;

UPDATE t SET a = 1, b = 'z' WHERE id = 7 RETURNING *;
UPDATE t SET a = o.a FROM other o WHERE t.id = o.t_id;

DELETE FROM t WHERE id = 7 RETURNING *;
DELETE FROM t USING other o WHERE t.id = o.t_id AND ...;

MERGE INTO t USING s ON t.k = s.k
  WHEN MATCHED THEN UPDATE SET ...
  WHEN NOT MATCHED THEN INSERT ...;

COPY t (a, b) FROM '/path/file.csv' WITH (FORMAT csv, HEADER true);

BEGIN;  ...  COMMIT;   -- or ROLLBACK;
```

[[PostgreSQL]]