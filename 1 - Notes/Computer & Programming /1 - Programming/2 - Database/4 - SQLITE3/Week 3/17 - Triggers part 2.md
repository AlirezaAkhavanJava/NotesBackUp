
In SQLite, a **trigger** is SQL code that runs automatically when a table is modified (INSERT, UPDATE, or DELETE), or when certain DDL/database events occur.

## Basic syntax

```sql
CREATE TRIGGER trigger_name
AFTER INSERT ON orders
BEGIN
    -- trigger body
END;
```

## When can a trigger fire?

- **BEFORE** / **AFTER** / **INSTEAD OF** (INSTEAD OF only works on views)
- **INSERT**, **UPDATE**, **DELETE** — or **UPDATE OF column1, column2** to fire only when specific columns change

Example that fires only when the price column changes:

```sql
CREATE TRIGGER price_watch
BEFORE UPDATE OF price ON products
BEGIN
    SELECT RAISE(ABORT, 'Price cannot change more than 20%');
END;
```

(`RAISE()` is a trigger-only function — valid options are `ABORT`, `IGNORE`, `FAIL`, or `ROLLBACK`.)

## Useful pseudo-tables

Inside a trigger body you can reference the affected rows with:

- `NEW` — the row being inserted or updated
- `OLD` — the row being deleted or updated

## Practical examples

**Audit log** — record every update:

```sql
CREATE TRIGGER audit_products
AFTER UPDATE ON products
BEGIN
    INSERT INTO audit_log(product_id, old_price, new_price, changed_at)
    VALUES (OLD.id, OLD.price, NEW.price, datetime('now'));
END;
```

**Auto-updated timestamp**:

```sql
CREATE TRIGGER touch_updated_at
AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
END;
```

## Good to know

- Trigger bodies can contain **multiple statements** (delimited by `;`) inside the `BEGIN ... END` block.
- Inside a trigger body, only `SELECT`, `INSERT`, `UPDATE`, `DELETE` — no `CREATE`, `DROP`, etc.
- You can't modify the table the trigger is attached to inside it (recursion isn't allowed by default).
- **Limitations**: no `WITH` clauses, `RETURNING`, `UPDATE ... FROM` in trigger bodies, and triggers can't be tied to `ALTER TABLE` events.
- View them with `SELECT * FROM sqlite_master WHERE type = 'trigger';`
- Drop with `DROP TRIGGER IF EXISTS trigger_name;`





[[SQlite]]