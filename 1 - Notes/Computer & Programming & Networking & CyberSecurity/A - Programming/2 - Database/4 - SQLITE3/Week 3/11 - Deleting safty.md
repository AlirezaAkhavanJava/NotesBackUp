

## 1. The mental model

Think of a company directory. Each row is a person, and other tables hold **sticky notes** that say "I belong to person #5".

- **Outgoing FKs** (your row points at parents): these are never a problem for deleting. When your row disappears, its pointers disappear with it.
- **Incoming FKs** (other rows point at your row): these are the problem. If you delete person #5, the sticky notes now point at nobody. These are called **orphans**, and the database has to decide what to do.

So when you say the row "has many FKs and is also referenced", only the **incoming references** matter for a delete.

I'll use this schema throughout:

```sql
customers(id PK)
orders(id PK, customer_id FK -> customers.id)     -- orders has an outgoing FK
order_items(id PK, order_id FK -> orders.id)      -- and is referenced by order_items
```

Deleting an order has to deal with `order_items`. It doesn't care about `customers`.

## 2. The five referential actions

You declare what should happen on delete when you create the FK:

```sql
FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE <action>
```

|Action|Meaning|
|---|---|
|`NO ACTION` (default)|Refuse the delete if children exist. The check happens at the end of the statement.|
|`RESTRICT`|Same refusal, but checked immediately.|
|`CASCADE`|Delete the children automatically.|
|`SET NULL`|Keep the children, set their FK column to NULL (the column must allow NULL).|
|`SET DEFAULT`|Keep the children, set their FK column to its default value.|

The `NO ACTION` vs `RESTRICT` difference matters in only one case. In PostgreSQL, a `DEFERRABLE` constraint with `NO ACTION` can be postponed to commit time, while `RESTRICT` can never be deferred. Otherwise they behave the same.

## 3. The biggest SQLite gotcha

**SQLite does not enforce foreign keys unless you turn them on, and it's off by default for every new connection.**

```sql
PRAGMA foreign_keys = ON;   -- run this every time you open a connection
PRAGMA foreign_keys;        -- 1 = on, 0 = off
```

If it's off, `DELETE` succeeds and silently leaves orphans, and nothing warns you. Two more details:

- The pragma is a no-op inside a transaction, so set it **before** `BEGIN`.
- Spring Boot with the SQLite JDBC driver may need `?foreign_keys=on` in the URL. Don't assume it's on.

PostgreSQL always enforces FKs, so there is no equivalent trap.

## 4. Step one: find out who references the row

Never delete blind. First discover which tables point at yours.

**SQLite:**

```sql
-- from inside the sqlite3 shell
PRAGMA foreign_key_list(orders);   -- OUTGOING FKs of orders

-- INCOMING: which tables reference 'orders'?
SELECT m.name AS child_table, p."from" AS child_col, p.on_delete
FROM sqlite_master m, pragma_foreign_key_list(m.name) p
WHERE m.type = 'table' AND p."table" = 'orders';
```

**PostgreSQL (psql):**

```sql
\d orders      -- the bottom section "Referenced by:" lists incoming FKs
```

or, as a query:

```sql
SELECT conrelid::regclass AS child_table,
       conname,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE contype = 'f' AND confrelid = 'orders'::regclass;
```

The definition string ends with the delete action, for example `ON DELETE CASCADE`.

## 5. Step two: look at what you're about to hit

```sql
SELECT * FROM orders WHERE id = 42;
SELECT COUNT(*) FROM order_items WHERE order_id = 42;
```

If the children themselves have children, repeat this down the chain. With `CASCADE`, the deletion spreads through the whole tree.

## 6. Step three: delete inside a transaction

A transaction gives you an undo button, so treat it as mandatory.

**PostgreSQL:**

```sql
BEGIN;
DELETE FROM orders WHERE id = 42 RETURNING *;   -- shows exactly what was removed
-- inspect the result, then:
ROLLBACK;   -- or COMMIT; once you're sure
```

**SQLite:**

```sql
PRAGMA foreign_keys = ON;
BEGIN;
DELETE FROM orders WHERE id = 42;
PRAGMA foreign_key_check;   -- lists any orphans; empty output = clean
COMMIT;                     -- or ROLLBACK;
```

Rolling back first is a free dry run. Pair `DELETE` with a `WHERE` that you've tested as a `SELECT` beforehand.

## 7. Strategies, from safest to riskiest

**A. Do nothing special (`NO ACTION`/`RESTRICT`).** If children exist, the delete fails:

```
ERROR:  update or delete on table "orders" violates foreign key constraint ...  (SQLSTATE 23503)
```

SQLite reports `FOREIGN KEY constraint failed`. This is a feature: the database is protecting you. Use it for data that should not vanish casually, like financial records.

**B. Delete the children first, manually.** Order matters: leaves first, then up.

```sql
BEGIN;
DELETE FROM order_items WHERE order_id = 42;
DELETE FROM orders      WHERE id = 42;
COMMIT;
```

It's explicit, with no hidden surprises, but it gets tedious and error-prone with deep trees.

**C. Let the schema do it with `ON DELETE CASCADE`.** Good for true "part-of" relationships, since order items have no meaning without their order. Dangerous for loose references, because one careless delete on a customer could wipe their orders, invoices, and so on.

**D. `ON DELETE SET NULL`.** Good when the child should outlive the parent, for example `tickets.assigned_to` when an employee leaves.

**E. Soft delete (very common in real apps).** Don't delete at all:

```sql
ALTER TABLE orders ADD COLUMN deleted_at TIMESTAMP;
UPDATE orders SET deleted_at = CURRENT_TIMESTAMP WHERE id = 42;
```

Every query then filters `WHERE deleted_at IS NULL`. No FK problems, easy undo, and an audit trail. The cost is that you must remember the filter everywhere.

## 8. Changing an existing FK's action

**PostgreSQL** can alter it directly:

```sql
BEGIN;
ALTER TABLE order_items DROP CONSTRAINT order_items_order_id_fkey;
ALTER TABLE order_items
  ADD CONSTRAINT order_items_order_id_fkey
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
COMMIT;
```

**SQLite cannot alter constraints.** You must rebuild: create a new table with the right FK, copy the data over, drop the old table, then rename the new one. Do it inside a transaction.

## 9. Gotchas and edge cases

1. **Cascade chains.** `CASCADE` follows through multiple levels. Deleting one customer might delete orders, then items, then shipments. Always map the tree first.
2. **Index your FK columns.** PostgreSQL does not auto-index the child's FK column (it does index the parent's PK). Without an index on `order_items.order_id`, every parent delete does a full scan of the child table, which is brutal on big tables. SQLite has the same issue.
3. **Self-references.** A table like `employees(manager_id -> employees.id)` works the same way, but cascade can chain through the whole hierarchy.
4. **Circular references.** If A and B point at each other, neither can be deleted first. The solution is a `DEFERRABLE INITIALLY DEFERRED` constraint (PostgreSQL, and SQLite supports it too), which postpones the check until `COMMIT`, so both rows can go in one transaction.
5. **Don't disable enforcement as a shortcut.** `PRAGMA foreign_keys = OFF` or `SET session_replication_role = replica` makes the error vanish and leaves a corrupted database. Use it only for deliberate bulk loads, followed by a check.
6. **`TRUNCATE ... CASCADE` in PostgreSQL** empties every table that references the target. It is much more destructive than `DELETE`.
7. **Check what you have.** `PRAGMA foreign_key_check;` in SQLite finds orphans created while enforcement was off.

## 10. The connection to Spring Boot

Since you're learning it, there are two layers where "what happens to children" can be defined, and they are independent:

- **Database level:** `ON DELETE CASCADE` in the schema, as above.
- **JPA level:** `@OneToMany(cascade = CascadeType.REMOVE, orphanRemoval = true)` makes Hibernate issue the child `DELETE`s itself before deleting the parent.

If the two disagree, you get confusing behavior. A common clean combination is JPA cascade for convenience plus a DB-level FK (without cascade) as a safety net that catches bugs.

## Quick checklist

1. Make sure FK enforcement is on (SQLite: `PRAGMA foreign_keys = ON`).
2. List the incoming references (`\d table` or the pragma query).
3. Count what's affected with `SELECT`.
4. `BEGIN`, then `DELETE ... RETURNING *` (psql) or `DELETE` followed by `PRAGMA foreign_key_check` (SQLite).
5. `COMMIT` if correct, otherwise `ROLLBACK`.




[[1 - WHAT IS SQLITE3 🍕]]