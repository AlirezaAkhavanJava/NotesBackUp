



**DDL** stands for **Data Definition Language**. It is the group of SQL commands that create, change, and remove the _structure_ of your database: tables, columns, constraints, indexes, schemas, views, sequences, types, and so on. The main commands are `CREATE`, `ALTER`, `DROP`, and `TRUNCATE`, plus helpers like `COMMENT`.

Think of a building. DDL is the blueprint work: adding rooms, moving walls, demolishing a floor. The _data_ (the furniture and people inside) is handled by other command groups. DDL matters because every table, rule, and index you rely on exists only because a DDL command made it. A good schema catches bad data before it ever reaches your Java code.

PostgreSQL has a real advantage here: **DDL is transactional**. Most DDL commands can be wrapped in `BEGIN ... ROLLBACK`, so a failed migration can be undone cleanly. Many other databases can't do that.

---

## 1. Where DDL fits among SQL command groups

|Group|Full name|Purpose|Commands|
|---|---|---|---|
|**DDL**|Data Definition Language|Define structure|`CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `COMMENT`|
|DML|Data Manipulation Language|Change data|`INSERT`, `UPDATE`, `DELETE`|
|DQL|Data Query Language|Read data|`SELECT`|
|DCL|Data Control Language|Permissions|`GRANT`, `REVOKE`|
|TCL|Transaction Control Language|Transactions|`BEGIN`, `COMMIT`, `ROLLBACK`|

This lesson covers only the first row. I'll mention the others when they touch DDL.

---

## 2. Schemas and databases

**The problem it solves:** You want to organize objects, or keep separate apps apart, without mixing everything in one pile.

- A **database** is the top-level container. You connect to one database at a time.
- A **schema** is a namespace _inside_ a database. Tables live inside schemas. The default schema is `public`.

```sql
CREATE DATABASE shop_db;

CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE sales.orders (id serial PRIMARY KEY);

SELECT * FROM sales.orders;
```

Line by line:

- `CREATE DATABASE shop_db;` makes a new database. It cannot run inside a transaction block.
- `CREATE SCHEMA IF NOT EXISTS sales;` makes a folder-like namespace. `IF NOT EXISTS` stops an error if it's already there.
- `sales.orders` means "the `orders` table inside the `sales` schema."

You can set which schemas PostgreSQL searches by default:

```sql
SET search_path TO sales, public;
```

**Errors you may hit:**

- `database "shop_db" already exists`
- `schema "sales" does not exist`: you used it before creating it.
- `cannot drop the currently open database`: connect to a different database first.

In Spring Boot, `spring.jpa.properties.hibernate.default_schema=sales` points Hibernate at a schema.

---

## 3. `CREATE TABLE`

**The problem it solves:** Gives your data a home, with rules about what each column may hold.

```sql
CREATE TABLE customers (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       varchar(255) NOT NULL UNIQUE,
    full_name   text NOT NULL,
    age         int CHECK (age >= 0),
    status      varchar(20) NOT NULL DEFAULT 'active',
    created_at  timestamptz NOT NULL DEFAULT now()
);
```

Line by line:

- `id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY` is an auto-incrementing number. `PRIMARY KEY` means unique and not null, and it identifies each row.
- `email varchar(255) NOT NULL UNIQUE` means a value is required and no two rows can share it.
- `full_name text NOT NULL` means required text of any length.
- `age int CHECK (age >= 0)` means a rule that rejects negative ages.
- `status ... DEFAULT 'active'` means if you don't supply a value, `'active'` is used.
- `created_at timestamptz ... DEFAULT now()` means the current time is filled in automatically.

### Constraints, in short

|Constraint|What it enforces|Example|
|---|---|---|
|`PRIMARY KEY`|Unique + not null identity|`id bigint PRIMARY KEY`|
|`NOT NULL`|A value is required|`email text NOT NULL`|
|`UNIQUE`|No duplicates|`UNIQUE (email)`|
|`CHECK`|A custom rule|`CHECK (price > 0)`|
|`DEFAULT`|Value if none is given|`DEFAULT now()`|
|`FOREIGN KEY`|Points to a row in another table|see below|
|`EXCLUDE`|No overlapping values (ranges)|see the range types lesson|

### Foreign keys: linking tables

```sql
CREATE TABLE orders (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  bigint NOT NULL,
    total        numeric(12,2) NOT NULL CHECK (total >= 0),
    placed_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON DELETE CASCADE
);
```

Line by line:

- `customer_id` stores the id of a customer.
- `CONSTRAINT fk_orders_customer` gives the rule a name, which makes error messages and later changes easier.
- `FOREIGN KEY (customer_id) REFERENCES customers (id)` means every `customer_id` must match an existing customer.
- `ON DELETE CASCADE` means deleting a customer also deletes their orders.

|`ON DELETE` option|Behavior|
|---|---|
|`NO ACTION` (default)|Block the delete if children exist|
|`RESTRICT`|Like `NO ACTION`, checked immediately|
|`CASCADE`|Delete the children too|
|`SET NULL`|Set the child's column to `NULL`|
|`SET DEFAULT`|Set the child's column to its default|

### Other useful `CREATE TABLE` forms

```sql
-- Create only if missing
CREATE TABLE IF NOT EXISTS tags (id serial PRIMARY KEY, name text UNIQUE);

-- Copy structure of another table
CREATE TABLE customers_backup (LIKE customers INCLUDING ALL);

-- Create from a query (structure + data)
CREATE TABLE big_orders AS
SELECT * FROM orders WHERE total > 1000;

-- Temporary table, disappears at the end of the session
CREATE TEMP TABLE scratch (x int);
```

**Errors you may hit:**

- `relation "customers" already exists`: use `IF NOT EXISTS`, or drop first.
- `there is no unique constraint matching given keys for referenced table "customers"`: the column you point at is not a primary key or unique.
- `type "varchr" does not exist`: a typo in the type name.
- `syntax error at or near ")"`: usually a trailing comma after the last column.

---

## 4. Identity columns vs `serial`

**The problem it solves:** Automatically generated ids.

|Option|Example|Notes|
|---|---|---|
|`serial` / `bigserial`|`id serial PRIMARY KEY`|Older style. Creates a sequence behind the scenes.|
|`GENERATED ALWAYS AS IDENTITY`|`id bigint GENERATED ALWAYS AS IDENTITY`|Modern, SQL standard. Blocks manual id values unless you use `OVERRIDING SYSTEM VALUE`.|
|`GENERATED BY DEFAULT AS IDENTITY`|same, with `BY DEFAULT`|Auto-generates, but lets you supply your own id.|

In Spring Boot, `@GeneratedValue(strategy = GenerationType.IDENTITY)` works with all of these.

---

## 5. `ALTER TABLE`

**The problem it solves:** Your app changes. You need to add a column, fix a type, or add a rule _without_ losing existing data.

```sql
-- Add a column
ALTER TABLE customers ADD COLUMN phone varchar(30);

-- Add a column with a default and NOT NULL
ALTER TABLE customers ADD COLUMN loyalty_points int NOT NULL DEFAULT 0;

-- Rename a column
ALTER TABLE customers RENAME COLUMN full_name TO name;

-- Rename the table
ALTER TABLE customers RENAME TO clients;

-- Change a column's type
ALTER TABLE clients ALTER COLUMN age TYPE smallint;

-- Change type with a conversion
ALTER TABLE clients ALTER COLUMN phone TYPE bigint USING phone::bigint;

-- Set or remove a default
ALTER TABLE clients ALTER COLUMN status SET DEFAULT 'pending';
ALTER TABLE clients ALTER COLUMN status DROP DEFAULT;

-- Set or remove NOT NULL
ALTER TABLE clients ALTER COLUMN phone SET NOT NULL;
ALTER TABLE clients ALTER COLUMN phone DROP NOT NULL;

-- Drop a column
ALTER TABLE clients DROP COLUMN phone;

-- Add and drop constraints
ALTER TABLE clients ADD CONSTRAINT uq_clients_email UNIQUE (email);
ALTER TABLE clients ADD CONSTRAINT chk_age CHECK (age BETWEEN 0 AND 150);
ALTER TABLE clients DROP CONSTRAINT chk_age;

-- Add a foreign key later
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_client FOREIGN KEY (customer_id) REFERENCES clients (id);
```

Notes:

- The `USING phone::bigint` clause tells PostgreSQL _how_ to convert existing values. (That `::` is the cast operator from the last lesson.) Without it, many type changes fail.
- Renaming a table or column doesn't update your Java code. Entities with `@Table(name="customers")` or `@Column(name="full_name")` must be updated by you.

**Errors you may hit:**

- `column "phone" of relation "clients" contains null values` when adding `NOT NULL`: fill the nulls first with an `UPDATE`, or add a default.
- `column "age" cannot be cast automatically to type ...` with `HINT: You might need to specify "USING age::...".`: add `USING`.
- `cannot drop column ... because other objects depend on it`: a view or constraint uses it. Use `DROP COLUMN ... CASCADE` only if you accept dropping those too.
- `check constraint "chk_age" is violated by some row`: existing data breaks your new rule. Fix the data, or add it as `NOT VALID` and validate later:

```sql
ALTER TABLE clients ADD CONSTRAINT chk_age CHECK (age >= 0) NOT VALID;
ALTER TABLE clients VALIDATE CONSTRAINT chk_age;
```

**A production warning:** some `ALTER TABLE` commands take a strong lock and can block other queries on large tables. Adding a column with a constant default is fast on modern PostgreSQL (11+), but changing a column's type often rewrites the whole table. Test on a copy first.

---

## 6. `DROP` and `TRUNCATE`

**The problem it solves:** Removing things you no longer need.

```sql
DROP TABLE orders;
DROP TABLE IF EXISTS orders;
DROP TABLE orders, order_items;
DROP TABLE customers CASCADE;
```

Line by line:

- `DROP TABLE orders;` removes the table, its data, its indexes, and its constraints.
- `IF EXISTS` avoids an error if it's already gone.
- `CASCADE` also drops things that depend on the table, such as foreign keys in _other_ tables and views. The other tables themselves are not dropped, only the dependent objects.

```sql
TRUNCATE TABLE orders;
TRUNCATE TABLE orders RESTART IDENTITY;
TRUNCATE TABLE customers, orders CASCADE;
```

`TRUNCATE` removes **all rows** quickly but keeps the table structure. `RESTART IDENTITY` resets auto-increment counters.

|Command|Removes rows|Removes the table|Can use `WHERE`|Speed on big tables|
|---|---|---|---|---|
|`DELETE FROM t` (DML)|Yes|No|Yes|Slower|
|`TRUNCATE t`|Yes (all)|No|No|Very fast|
|`DROP TABLE t`|Yes|Yes|No|Very fast|

**Errors you may hit:**

- `cannot drop table customers because other objects depend on it` with `HINT: Use DROP ... CASCADE`: a foreign key or view still references it.
- `cannot truncate a table referenced in a foreign key constraint`: truncate both tables together, or use `CASCADE`.
- `table "orders" does not exist`: add `IF EXISTS`.

Because PostgreSQL DDL is transactional, you can practice safely:

```sql
BEGIN;
DROP TABLE orders;
ROLLBACK;     -- the table is back
```

---

## 7. Indexes

**The problem it solves:** Searches on big tables get slow. An index is a sorted lookup structure, like the index at the back of a book, that lets PostgreSQL jump to rows instead of reading every row.

```sql
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE UNIQUE INDEX uq_clients_email ON clients (email);
CREATE INDEX idx_orders_placed_desc ON orders (placed_at DESC);
CREATE INDEX idx_clients_lower_email ON clients (lower(email));
CREATE INDEX idx_active_clients ON clients (id) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_orders_total ON orders (total);
DROP INDEX idx_orders_total;
```

Line by line:

- The first is a normal index on a foreign key column. PostgreSQL does **not** create these automatically for foreign keys, and joins and cascades benefit a lot from them.
- `UNIQUE INDEX` also enforces uniqueness.
- `placed_at DESC` helps queries that sort newest first.
- `lower(email)` is an **expression index**, used by queries such as `WHERE lower(email) = 'a@b.com'`.
- The `WHERE status = 'active'` form is a **partial index**. It is smaller and faster when you mostly query one slice of the data.
- `CONCURRENTLY` builds the index without blocking writes. It is slower and cannot run inside a transaction block.

Index types:

|Type|Best for|
|---|---|
|`btree` (default)|`=`, `<`, `>`, `BETWEEN`, sorting|
|`hash`|Simple equality only|
|`gin`|Arrays, `jsonb`, `tsvector`|
|`gist`|Ranges, geometry, exclusion constraints|
|`brin`|Huge tables with naturally ordered data (like timestamps)|

Remember `USING gin` from the full-text lesson? That is the same syntax: `CREATE INDEX ... ON t USING gin (col);`

**Errors you may hit:**

- `relation "idx_orders_customer" already exists`
- `could not create unique index ... DETAIL: Key (email)=(a@b.com) is duplicated.`: existing data already has duplicates.
- `CREATE INDEX CONCURRENTLY cannot run inside a transaction block`: run it on its own.

_Cost to remember:_ every index speeds up reads but slows down writes and uses disk space, so don't add them blindly.

---

## 8. Views and materialized views

**The problem it solves:** You keep writing the same long query. A view saves it under a name.

```sql
CREATE VIEW active_clients AS
SELECT id, name, email FROM clients WHERE status = 'active';

SELECT * FROM active_clients;

CREATE OR REPLACE VIEW active_clients AS
SELECT id, name, email, created_at FROM clients WHERE status = 'active';

DROP VIEW active_clients;
```

A normal view stores **only the query**, so it always shows current data.

A **materialized view** stores the **result**, so it is fast but can be stale until refreshed:

```sql
CREATE MATERIALIZED VIEW daily_sales AS
SELECT placed_at::date AS day, sum(total) AS revenue
FROM orders
GROUP BY 1;

REFRESH MATERIALIZED VIEW daily_sales;
```

(Here `GROUP BY 1` means "group by the first selected column.")

**Errors you may hit:**

- `cannot change name of view column "x" to "y"` with `CREATE OR REPLACE VIEW`: you can add columns at the end but not rename or reorder existing ones. Drop and recreate instead.

---

## 9. Sequences

**The problem it solves:** A counter that hands out unique numbers, used behind `serial` and identity columns. You can also use one directly.

```sql
CREATE SEQUENCE invoice_no_seq START 1000 INCREMENT 1;

SELECT nextval('invoice_no_seq');   -- 1000
SELECT nextval('invoice_no_seq');   -- 1001
SELECT currval('invoice_no_seq');   -- 1001

ALTER SEQUENCE invoice_no_seq RESTART WITH 5000;
DROP SEQUENCE invoice_no_seq;
```

Gaps in ids are **normal**. A rolled-back insert still consumes a number.

---

## 10. Custom types: `ENUM` and `DOMAIN`

**The problem it solves:** Restricting a column to a fixed set of values, or reusing a validated type.

```sql
CREATE TYPE order_status AS ENUM ('new', 'paid', 'shipped', 'cancelled');

ALTER TABLE orders ADD COLUMN status order_status NOT NULL DEFAULT 'new';

ALTER TYPE order_status ADD VALUE 'refunded';
ALTER TYPE order_status RENAME VALUE 'new' TO 'created';
```

```sql
CREATE DOMAIN email_address AS text
    CHECK (VALUE ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$');

CREATE TABLE subscribers (email email_address PRIMARY KEY);
```

A `DOMAIN` is a base type plus a built-in rule, reusable across many tables.

**Errors you may hit:**

- `invalid input value for enum order_status: "paid2"`
- You **cannot remove** an enum value easily. Plan values carefully, or use a `varchar` with a `CHECK`, or a lookup table.
- From Spring: `column "status" is of type order_status but expression is of type character varying`. Use `CAST(:s AS order_status)` or `@JdbcTypeCode(SqlTypes.NAMED_ENUM)` in Hibernate 6.

---

## 11. Comments and metadata

```sql
COMMENT ON TABLE clients IS 'People who bought something';
COMMENT ON COLUMN clients.status IS 'active | pending | blocked';
```

Handy for documentation. In psql, `\d+ clients` shows them.

**Useful psql commands to inspect DDL results:**

|Command|Shows|
|---|---|
|`\l`|Databases|
|`\dn`|Schemas|
|`\dt`|Tables|
|`\d clients`|Columns, indexes, constraints of one table|
|`\di`|Indexes|
|`\dv`|Views|
|`\ds`|Sequences|
|`\dT`|Custom types|

---

## 12. DDL inside transactions

```sql
BEGIN;

CREATE TABLE audit_log (id bigserial PRIMARY KEY, note text);
ALTER TABLE clients ADD COLUMN notes text;
CREATE INDEX idx_audit_note ON audit_log (note);

COMMIT;    -- or ROLLBACK; to undo everything
```

If any statement fails, the whole block is aborted, and you get `current transaction is aborted, commands ignored until end of transaction block` until you `ROLLBACK`. This all-or-nothing behavior is why PostgreSQL migrations are safer than in many other databases.

---

## 13. DDL in Spring Boot

You have three common ways to run DDL:

|Approach|Setting / tool|When to use|
|---|---|---|
|Hibernate auto-DDL|`spring.jpa.hibernate.ddl-auto=update`|Quick prototypes only|
|Validate only|`spring.jpa.hibernate.ddl-auto=validate`|Check that entities match the real tables|
|**Migration tools**|**Flyway** or **Liquibase**|Real projects|

With Flyway, you put plain SQL files in `src/main/resources/db/migration/`:

```
V1__create_customers.sql
V2__create_orders.sql
V3__add_phone_to_customers.sql
```

Each file runs once, in order, and Flyway remembers which have run. Example `V3__add_phone_to_customers.sql`:

```sql
ALTER TABLE customers ADD COLUMN phone varchar(30);
```

Why this is better than `ddl-auto=update`: `update` can only add things, never safely rename or drop, and it gives you no history. Migrations give you a reviewable, repeatable record of every schema change.

How entity annotations relate to DDL:

|Java|DDL it corresponds to|
|---|---|
|`@Entity @Table(name="customers")`|`CREATE TABLE customers`|
|`@Id @GeneratedValue(IDENTITY)`|`GENERATED ... AS IDENTITY PRIMARY KEY`|
|`@Column(nullable=false, unique=true, length=255)`|`NOT NULL UNIQUE varchar(255)`|
|`@ManyToOne @JoinColumn(name="customer_id")`|`FOREIGN KEY (customer_id) REFERENCES ...`|
|`@Index` in `@Table(indexes=...)`|`CREATE INDEX`|

---

## Related concepts, in short

- **DML (`INSERT`, `UPDATE`, `DELETE`):** changes the _rows_ inside tables that DDL created. It is the natural next lesson.
- **DCL (`GRANT`, `REVOKE`):** controls who may use the objects. For example, `GRANT SELECT ON clients TO report_user;`.
- **Locks:** DDL takes locks. `ALTER TABLE` can wait behind a long-running query, and then block everything queued behind _it_. Set `lock_timeout` before risky changes on busy systems.
- **System catalogs:** PostgreSQL stores your table definitions in tables of its own, such as `pg_class` and `information_schema.columns`. You can query them: `SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'clients';`.

---

## Quick cheat sheet

```sql
CREATE SCHEMA s;                        DROP SCHEMA s CASCADE;
CREATE TABLE t (...);                   DROP TABLE IF EXISTS t;
ALTER TABLE t ADD COLUMN c type;        ALTER TABLE t DROP COLUMN c;
ALTER TABLE t RENAME COLUMN a TO b;     ALTER TABLE t ALTER COLUMN c TYPE new USING c::new;
ALTER TABLE t ADD CONSTRAINT n ...;     ALTER TABLE t DROP CONSTRAINT n;
CREATE [UNIQUE] INDEX i ON t (c);       DROP INDEX i;
CREATE VIEW v AS SELECT ...;            DROP VIEW v;
CREATE SEQUENCE s;                      CREATE TYPE x AS ENUM (...);
TRUNCATE t RESTART IDENTITY;            COMMENT ON TABLE t IS '...';
```




[[PostgreSQL]]