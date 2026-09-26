# Schemas in PostgreSQL

Schemas are logical containers that organize database objects (tables, views, functions, etc.) into named groups. They provide a way to namespace database objects and manage access permissions.

## What are Schemas?

- **Logical namespaces** that contain database objects
- **Security boundaries** for access control
- **Organization tools** for grouping related objects
- **Default schema**: `public` is the default schema in most databases

## Basic Schema Operations

### Creating Schemas
```sql
-- Basic schema creation
CREATE SCHEMA sales;

-- Schema with authorization
CREATE SCHEMA hr AUTHORIZATION hr_user;

-- Create schema if not exists (PostgreSQL 9.3+)
CREATE SCHEMA IF NOT EXISTS marketing;
```

### Listing Schemas
```sql
-- List all schemas in current database
SELECT schema_name 
FROM information_schema.schemata;

-- List schemas with owners
SELECT 
    nspname as schema_name,
    pg_get_userbyid(nspowner) as owner
FROM pg_namespace
ORDER BY nspname;
```

### Dropping Schemas
```sql
-- Drop empty schema
DROP SCHEMA sales;

-- Drop schema with all contained objects
DROP SCHEMA hr CASCADE;

-- Drop if exists
DROP SCHEMA IF EXISTS temp_schema CASCADE;
```

## Working with Schemas

### Setting Search Path
```sql
-- Show current search path
SHOW search_path;

-- Set search path for current session
SET search_path TO sales, public;

-- Set user-specific search path
ALTER USER username SET search_path = inventory, public;

-- Database-level search path
ALTER DATABASE dbname SET search_path = hr, public;
```

### Creating Objects in Specific Schemas
```sql
-- Create table in specific schema
CREATE TABLE sales.customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

-- Create view in specific schema
CREATE VIEW sales.customer_summary AS
SELECT name, email FROM sales.customers;

-- Create function in specific schema
CREATE FUNCTION inventory.calculate_stock() 
RETURNS INTEGER AS $$
-- function body
$$ LANGUAGE plpgsql;
```

### Accessing Objects Across Schemas
```sql
-- Fully qualified name
SELECT * FROM sales.customers;

-- With current search path, you can use just the table name
SELECT * FROM customers;

-- Cross-schema joins
SELECT *
FROM sales.orders o
JOIN inventory.products p ON o.product_id = p.id;
```

## Schema Organization Patterns

### By Business Function
```sql
CREATE SCHEMA hr;
CREATE SCHEMA sales;
CREATE SCHEMA inventory;
CREATE SCHEMA finance;
```

### By Security Level
```sql
CREATE SCHEMA public_data;
CREATE SCHEMA confidential;
CREATE SCHEMA restricted;
```

### By Application
```sql
CREATE SCHEMA app1;
CREATE SCHEMA app2;
CREATE SCHEMA reporting;
```

## Practical Schema Setup Example

```sql
-- Create schemas for different departments
CREATE SCHEMA hr;
CREATE SCHEMA sales;
CREATE SCHEMA inventory;

-- Create tables in respective schemas
CREATE TABLE hr.employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    salary DECIMAL(10,2),
    hire_date DATE
);

CREATE TABLE sales.customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    region VARCHAR(50)
);

CREATE TABLE inventory.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),
    stock_quantity INTEGER
);

-- Create cross-schema view
CREATE VIEW sales.customer_orders AS
SELECT 
    c.name as customer_name,
    p.name as product_name,
    p.price
FROM sales.customers c
CROSS JOIN inventory.products p;
```

## Schema Permissions and Security

### Granting Schema Access
```sql
-- Allow user to use schema
GRANT USAGE ON SCHEMA sales TO sales_user;

-- Allow user to create objects in schema
GRANT CREATE ON SCHEMA sales TO sales_admin;

-- Allow user to access all tables in schema
GRANT SELECT ON ALL TABLES IN SCHEMA sales TO sales_reader;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA sales
GRANT SELECT ON TABLES TO sales_reader;
```

### Role-Based Schema Access
```sql
-- Create roles
CREATE ROLE sales_team;
CREATE ROLE hr_team;

-- Grant schema usage
GRANT USAGE ON SCHEMA sales TO sales_team;
GRANT USAGE ON SCHEMA hr TO hr_team;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA sales TO sales_team;
GRANT SELECT ON ALL TABLES IN SCHEMA hr TO sales_team;  -- Read-only HR access
```

## Moving Objects Between Schemas

```sql
-- Move table to different schema
ALTER TABLE public.customers SET SCHEMA sales;

-- Move view to different schema
ALTER VIEW public.customer_summary SET SCHEMA reporting;

-- Move function to different schema
ALTER FUNCTION calculate_bonus() SET SCHEMA hr;
```

## Schema Search Path Tricks

```sql
-- Temporary schema for testing
CREATE SCHEMA test_schema;
SET search_path TO test_schema, public;

-- Now all created objects go to test_schema
CREATE TABLE customers (...);  -- Goes to test_schema.customers

-- Reset search path
SET search_path TO public;

-- Schema-specific search path in functions
CREATE FUNCTION sales.process_order() 
RETURNS void AS $$
BEGIN
    SET LOCAL search_path TO sales, public;
    -- function operations
END;
$$ LANGUAGE plpgsql;
```

# Rules in PostgreSQL

Rules are a powerful feature that allow you to define query rewriting. They can transform queries before execution.

## What are Rules?

- **Query rewrite system** that modifies incoming queries
- **Triggers alternative** for certain use cases
- **Powerful but complex** - use with caution
- **Two types**: `SELECT` rules and `INSERT/UPDATE/DELETE` rules

## Basic Rule Syntax

```sql
CREATE [OR REPLACE] RULE rule_name AS ON event
    TO table_name [WHERE condition]
    DO [ALSO | INSTEAD] { NOTHING | command | (command; command...) }
```

## Rule Examples

### 1. View Updating with INSTEAD OF Rules
```sql
-- Create a view
CREATE VIEW customer_contacts AS
SELECT id, name, email, phone FROM customers;

-- Create rules to make view updatable
CREATE RULE update_customer_contacts AS
    ON UPDATE TO customer_contacts
    DO INSTEAD
    UPDATE customers SET
        name = NEW.name,
        email = NEW.email,
        phone = NEW.phone
    WHERE id = OLD.id;

CREATE RULE insert_customer_contacts AS
    ON INSERT TO customer_contacts
    DO INSTEAD
    INSERT INTO customers (name, email, phone)
    VALUES (NEW.name, NEW.email, NEW.phone);
```

### 2. Logging Rules
```sql
-- Create audit log table
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    action TEXT,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP DEFAULT NOW()
);

-- Rule to log all updates
CREATE RULE log_customer_updates AS
    ON UPDATE TO customers
    DO ALSO
    INSERT INTO audit_log (table_name, action, old_data, new_data)
    VALUES ('customers', 'UPDATE', row_to_json(OLD), row_to_json(NEW));
```

### 3. Security Rules
```sql
-- Rule to prevent deletion of active customers
CREATE RULE prevent_active_customer_deletion AS
    ON DELETE TO customers
    WHERE OLD.status = 'active'
    DO INSTEAD NOTHING;

-- Rule to automatically archive deleted records
CREATE RULE archive_deleted_customers AS
    ON DELETE TO customers
    DO ALSO
    INSERT INTO customer_archive 
    SELECT *, NOW() FROM OLD;
```

### 4. Default Value Rules
```sql
-- Rule to set default created_at timestamp
CREATE RULE set_created_at AS
    ON INSERT TO orders
    DO ALSO
    UPDATE orders SET created_at = NOW()
    WHERE id = NEW.id;
```

## Advanced Rule Examples

### Partitioning with Rules
```sql
-- Create partitioned tables
CREATE TABLE orders_2023 (LIKE orders INCLUDING ALL);
CREATE TABLE orders_2024 (LIKE orders INCLUDING ALL);

-- Rule to redirect inserts based on year
CREATE RULE route_orders_by_year AS
    ON INSERT TO orders
    DO INSTEAD (
        INSERT INTO orders_2023 SELECT * FROM NEW WHERE EXTRACT(YEAR FROM order_date) = 2023;
        INSERT INTO orders_2024 SELECT * FROM NEW WHERE EXTRACT(YEAR FROM order_date) = 2024;
    );
```

### Read-Only Table Rule
```sql
-- Make a table read-only
CREATE RULE prevent_orders_modification AS
    ON UPDATE TO orders
    DO INSTEAD NOTHING;

CREATE RULE prevent_orders_deletion AS
    ON DELETE TO orders
    DO INSTEAD NOTHING;
```

## Managing Rules

### Listing Rules
```sql
-- List all rules in database
SELECT 
    schemaname,
    tablename,
    rulename,
    definition
FROM pg_rules
ORDER BY schemaname, tablename;

-- Rules for specific table
SELECT rulename, definition 
FROM pg_rules 
WHERE tablename = 'customers';
```

### Dropping Rules
```sql
-- Drop a specific rule
DROP RULE rule_name ON table_name [CASCADE | RESTRICT];

-- Examples
DROP RULE log_customer_updates ON customers;
DROP RULE IF EXISTS prevent_deletion ON orders CASCADE;
```

## Important Considerations

### Rules vs Triggers
- **Rules**: Query rewriting, happen before parsing
- **Triggers**: Row-level operations, happen during execution
- **Rules** are more powerful but can be confusing
- **Triggers** are generally preferred for most use cases

### Rule Limitations
```sql
-- Rules don't work well with RETURNING clauses
CREATE RULE problematic_rule AS
    ON INSERT TO table1
    DO ALSO INSERT INTO table2 VALUES (NEW.id);  -- RETURNING might not work as expected

-- Rules can have unexpected behavior with multiple commands
```

## Best Practices

1. **Use schemas** to organize related database objects
2. **Set appropriate search paths** for different applications
3. **Use rules sparingly** - they can be hard to debug
4. **Prefer triggers over rules** for most data manipulation needs
5. **Document rule behavior** thoroughly
6. **Test rules extensively** - they modify query behavior

Schemas and rules are powerful PostgreSQL features that, when used appropriately, can greatly enhance database organization, security, and functionality.

##### Tags : [[1 - SQL 🦬]]