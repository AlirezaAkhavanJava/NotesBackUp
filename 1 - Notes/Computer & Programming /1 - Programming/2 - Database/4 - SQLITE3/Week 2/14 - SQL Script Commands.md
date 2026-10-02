

An **SQL script** is a text file containing one or more SQL statements that are executed together. A `schema.sql` file typically defines the **structure** of a database: databases, tables, columns, keys, indexes, and constraints.

## Basic `schema.sql` Example

```sql
-- ============================================
-- schema.sql
-- Database schema definition script
-- ============================================

-- 1. Create the database
CREATE DATABASE IF NOT EXISTS shop_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE shop_db;

-- 2. Create a table
CREATE TABLE IF NOT EXISTS customers (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    phone       VARCHAR(20),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create a table with a foreign key
CREATE TABLE IF NOT EXISTS orders (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT NOT NULL,
    order_date   DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status       ENUM('pending','paid','shipped','cancelled') DEFAULT 'pending',
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 4. Create an index
CREATE INDEX idx_orders_date ON orders(order_date);

-- 5. Create a view
CREATE OR REPLACE VIEW v_customer_orders AS
SELECT c.id, c.first_name, c.last_name,
       o.id AS order_id, o.total_amount, o.status
FROM customers c
JOIN orders o ON o.customer_id = c.id;

-- 6. Insert seed data (optional)
INSERT INTO customers (first_name, last_name, email)
VALUES ('John', 'Doe', 'john@example.com');
```

## How to Run the Script

**MySQL / MariaDB**
```bash
mysql -u root -p < schema.sql
```

**PostgreSQL**
```bash
psql -U postgres -d mydb -f schema.sql
```

**SQLite**
```bash
sqlite3 mydb.sqlite < schema.sql
```

**SQL Server (sqlcmd)**
```bash
sqlcmd -S localhost -U sa -P password -i schema.sql
```

**From inside a SQL client**
```sql
SOURCE /path/to/schema.sql;    -- MySQL
\i /path/to/schema.sql         -- PostgreSQL (psql)
.read /path/to/schema.sql      -- SQLite
```

## Key Command Categories in a Schema Script

| Category | Commands |
|----------|----------|
| **Database** | `CREATE DATABASE`, `DROP DATABASE`, `USE`, `ALTER DATABASE` |
| **Tables** | `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`, `TRUNCATE TABLE` |
| **Constraints** | `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `CHECK`, `NOT NULL`, `DEFAULT` |
| **Indexes** | `CREATE INDEX`, `CREATE UNIQUE INDEX`, `DROP INDEX` |
| **Views** | `CREATE VIEW`, `CREATE OR REPLACE VIEW`, `DROP VIEW` |
| **Data** | `INSERT`, `UPDATE`, `DELETE` |
| **Transactions** | `BEGIN`, `COMMIT`, `ROLLBACK` |
| **Safety** | `IF EXISTS`, `IF NOT EXISTS`, `CASCADE` |

## Best Practices

1. **Idempotency** – use `IF NOT EXISTS` / `IF EXISTS` so the script can run repeatedly.
2. **Order matters** – create parent tables (with PKs) before child tables (with FKs).
3. **Wrap in a transaction** (for PostgreSQL/SQL Server):
   ```sql
   BEGIN;
   -- your DDL here
   COMMIT;
   ```
4. **Separate concerns** – keep `schema.sql` (structure) separate from `seed.sql` (data).
5. **Comment sections** – use `--` for single-line and `/* ... */` for block comments.
6. **Use consistent naming** – e.g., plural table names, `snake_case` columns.

Would you like an example for a specific database (PostgreSQL, SQL Server, Oracle) or a specific domain (e-commerce, blog, school)?

[[1 - WHAT IS SQLITE3 🍕]]
[[1 - SQL 🦬]]