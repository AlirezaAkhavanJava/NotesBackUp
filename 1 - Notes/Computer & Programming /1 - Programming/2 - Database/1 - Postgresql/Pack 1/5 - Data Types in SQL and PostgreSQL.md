Date : 2025-08-30



## SQL Data Types (Standard)

SQL, as a standardized language, defines common data types supported by most relational database management systems (RDBMS). These are the foundation for PostgreSQL’s data types.



> In SQL, a **data type** tells the database what kind of information a column can hold, like numbers, words, or dates. Choosing the right data type ensures data is stored correctly and efficiently.

#### Common SQL Data Types

- **Numbers**:
    - `INT` (Integer): Stores whole numbers, like 1, 42, or -10.
    - `DECIMAL` or `NUMERIC`: Stores numbers with decimals, like 3.14 or 123.456.
- **Text**:
    - `CHAR(n)`: Fixed-length text (e.g., `CHAR(5)` always uses 5 characters).
    - `VARCHAR(n)`: Variable-length text (e.g., `VARCHAR(50)` for up to 50 characters).
    - **`TEXT`** → unlimited length (well, up to 1 GB), no need to specify size.
	- **`VARCHAR(n)`** → same as `TEXT` but enforces a max length `n`.
	- **`VARCHAR` without length** → same as `TEXT`.
- **Dates and Times**:
    - `DATE`: Stores dates, like `2025-08-30`.
    - `TIME`: Stores times, like `16:43:00`.
    - `TIMESTAMP`: Stores date and time, like `2025-08-30 16:43:00`.
- **Boolean**:
    - `BOOLEAN`: Stores `TRUE` or `FALSE`.

#### Example

```sql
CREATE TABLE students (
    id INT,
    name VARCHAR(50),
    birth_date DATE,
    average_grade DECIMAL(4,2),
    is_active BOOLEAN
);
```

This creates a table with columns for a student’s ID (number), name (text), birth date, grade (decimal), and active status (true/false).



> SQL data types specify the format, size, and constraints of data in a column. They ensure data integrity and optimize storage and query performance. Standard SQL types are portable across RDBMSs, but each system (like PostgreSQL) may extend or modify them.

#### Key Standard SQL Data Types

- **Numeric Types**:
    - `INTEGER` or `INT`: Whole numbers (e.g., -2147483648 to 2147483647).
    - `SMALLINT`: Smaller range of whole numbers (e.g., -32768 to 32767).
    - `BIGINT`: Larger range of whole numbers (e.g., -2^63 to 2^63-1).
    - `DECIMAL(p,s)` or `NUMERIC(p,s)`: Exact decimal numbers with `p` digits and `s` decimal places (e.g., `DECIMAL(5,2)` for 123.45).
    - `FLOAT` or `REAL`: Approximate floating-point numbers for scientific calculations.
- **Character Types**:
    - `CHAR(n)`: Fixed-length strings, padded with spaces if shorter than `n`.
    - `VARCHAR(n)`: Variable-length strings up to `n` characters.
    - `TEXT`: Unlimited-length text (implementation-dependent).
- **Date and Time Types**:
    - `DATE`: Calendar date (year, month, day).
    - `TIME`: Time of day, with or without time zone.
    - `TIMESTAMP`: Date and time, often with time zone support.
    - `INTERVAL`: Time duration (e.g., 3 days, 2 hours).
- **Boolean Type**:
    - `BOOLEAN`: Stores `TRUE`, `FALSE`, or `NULL`.

#### Example

```sql
INSERT INTO students (id, name, birth_date, average_grade, is_active)
VALUES (1, 'Alice Smith', '2005-03-15', 3.75, TRUE);
```

This inserts a record with an integer ID, variable-length name, date, decimal grade, and boolean status.

---
## PostgreSQL Data Types

PostgreSQL, an advanced open-source RDBMS, supports all standard SQL data types and adds its own powerful, specialized types. Below is a detailed breakdown, including PostgreSQL-specific features.



> PostgreSQL uses the same basic data types as SQL (numbers, text, dates) but adds some  extras, like storing lists, JSON data, or even geographic locations. It’s like a super-organized filing cabinet with more options for what you can store.

#### Simple PostgreSQL Data Types

- **Numbers**: Like `INT`, `SMALLINT`, `BIGINT`, `NUMERIC`, and `FLOAT`.
- **Text**: Like `VARCHAR`, `CHAR`, and `TEXT`.
- **Dates/Times**: Like `DATE`, `TIME`, `TIMESTAMP`.
- **Boolean**: `TRUE` or `FALSE`.
- **Extras**:
    - `JSON`: Stores data like a webpage’s information (e.g., `{ "name": "Alice", "age": 20 }`).
    - `ARRAY`: Stores lists, like `[1, 2, 3]` or `["apple", "banana"]`.

#### Example

```sql
CREATE TABLE products (
    product_id INT,
    name TEXT,
    price NUMERIC(10,2),
    tags TEXT[]
);
INSERT INTO products (product_id, name, price, tags)
VALUES (1, 'Laptop', 999.99, ARRAY['electronics', 'portable']);
```

This creates a table with a number, text, decimal price, and an array of tags.



> PostgreSQL extends standard SQL data types with additional flexibility and functionality. It ensures strict type checking and provides types for advanced use cases, such as JSON, arrays, and geospatial data. These types are particularly useful for modern applications like web development or data analytics.

#### Key PostgreSQL Data Types

- **Numeric Types**:
    - `SMALLINT`: 2 bytes, -32768 to 32767.
    - `INTEGER` or `INT`: 4 bytes, -2147483648 to 2147483647.
    - `BIGINT`: 8 bytes, -2^63 to 2^63-1.
    - `NUMERIC(p,s)`: Arbitrary precision, e.g., `NUMERIC(10,2)` for up to 10 digits with 2 decimal places.
    - `REAL`: 4-byte floating-point, 6 decimal digits precision.
    - `DOUBLE PRECISION`: 8-byte floating-point, 15 decimal digits precision.
    - `SERIAL`: Auto-incrementing integer, often used for IDs (e.g., `SERIAL` for 1, 2, 3...).
- **Character Types**:
    - `CHAR(n)`: Fixed-length, padded with spaces.
    - `VARCHAR(n)`: Variable-length, up to `n` characters (1 GB max in PostgreSQL).
    - `TEXT`: Variable-length with no specific limit (up to 1 GB).
- **Date and Time Types**:
    - `DATE`: Stores dates (e.g., `2025-08-30`).
    - `TIME [WITH TIME ZONE]`: Time of day, optionally with time zone.
    - `TIMESTAMP [WITH TIME ZONE]`: Date and time, optionally with time zone (e.g., `2025-08-30 16:43:00+02`).
    - `INTERVAL`: Time spans, e.g., `3 days 2 hours`.
- **Boolean Type**:
    - `BOOLEAN`: `TRUE`, `FALSE`, or `NULL`.
- **PostgreSQL-Specific Types**:
    - `JSON` and `JSONB`: Store JSON data; `JSONB` is binary and supports indexing for faster queries.
    - `ARRAY`: Stores arrays of any data type (e.g., `INT[]` for `[1, 2, 3]`).
    - `UUID`: Stores universally unique identifiers (e.g., `123e4567-e89b-12d3-a456-426614174000`).
    - `INET` and `CIDR`: Store IP addresses and network ranges (e.g., `192.168.1.1`).
    - `GEOMETRY` (with PostGIS): Stores geospatial data like points, lines, or polygons.

#### Example

```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    profile JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    ip_address INET
);
INSERT INTO users (username, profile, created_at, ip_address)
VALUES (
    'alice',
    '{"age": 25, "city": "New York"}',
    '2025-08-30 16:43:00+02',
    '192.168.1.1'
);
```

This table uses a `SERIAL` ID, text, JSON data, timestamp with time zone, and IP address.


---


> PostgreSQL’s type system is highly extensible, allowing custom data types and operators. It optimizes storage and performance through type-specific indexing (e.g., GIN for JSONB, GiST for geometry) and supports advanced features like type casting, domain types, and composite types. PostgreSQL’s data types are designed for scalability, precision, and modern application needs, such as handling semi-structured or geospatial data.



- **Numeric Types**:
    - `SERIAL`, `SMALLSERIAL`, `BIGSERIAL`: Auto-incrementing integers for primary keys (2, 4, or 8 bytes).
    - `NUMERIC`: Supports arbitrary precision, ideal for financial calculations where exactness is critical.
    - `MONEY`: Stores currency amounts with locale-aware formatting (e.g., `$999.99`).
- **Character Types**:
    - `TEXT` and `VARCHAR` have a 1 GB limit, but `TOAST` (PostgreSQL’s storage mechanism) compresses large values.
    - No practical difference between `TEXT` and `VARCHAR` without a length constraint in PostgreSQL.
- **Date and Time Types**:
    - `TIMESTAMP WITH TIME ZONE` adjusts for time zones and stores data in UTC internally.
    - `INTERVAL` supports complex operations, e.g., adding `INTERVAL '1 month'` to a date.
- **JSON and JSONB**:
    - `JSON`: Stores JSON as text, preserving exact formatting.
    - `JSONB`: Binary format, supports indexing (e.g., GIN) and operators (e.g., `->` to access fields).
    - Example: `SELECT profile->>'city' FROM users;` extracts the `city` field from a JSONB column.
- **Arrays**:
    - Supports multi-dimensional arrays of any type (e.g., `TEXT[][]` for a 2D array of strings).
    - Example: `SELECT tags[1] FROM products;` retrieves the first tag from an array.
- **UUID**:
    - 128-bit unique identifiers, ideal for distributed systems.
    - Generated with the `uuid-ossp` extension: `SELECT gen_random_uuid();`.
- **Network Address Types**:
    - `INET`: Stores IPv4/IPv6 addresses (e.g., `192.168.1.1`).
    - `CIDR`: Stores network ranges (e.g., `192.168.1.0/24`).
    - `MACADDR`: Stores MAC addresses.
- **Geospatial Types (via PostGIS)**:
    - `GEOMETRY`: Stores points, lines, polygons, etc., with spatial operations (e.g., distance, intersection).
    - Example: `SELECT ST_Distance(ST_Point(0,0), ST_Point(3,4));` calculates the distance between two points.
- **Custom Types**:
    - `CREATE TYPE`: Define composite types (like structs) or enumerated types.
    - Example: `CREATE TYPE mood AS ENUM ('happy', 'sad', 'neutral');`.
- **Domain Types**:
    - Custom types with constraints, e.g., `CREATE DOMAIN positive_int AS INTEGER CHECK (VALUE > 0);`.

#### Example (Advanced)

```sql
-- Enable PostGIS and uuid-ossp extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create a table with advanced PostgreSQL types
CREATE TABLE events (
    event_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    details JSONB,
    event_time TIMESTAMP WITH TIME ZONE,
    location GEOMETRY(POINT),
    categories TEXT[]
);

-- Insert data
INSERT INTO events (name, details, event_time, location, categories)
VALUES (
    'Tech Conference',
    '{"topic": "AI", "attendees": 500}',
    '2025-09-01 09:00:00+02',
    ST_SetSRID(ST_Point(-122.4194, 37.7749), 4326),
    ARRAY['tech', 'conference', 'AI']
);

-- Query JSONB and geometry
SELECT name, details->>'topic' AS topic, ST_AsText(location) AS location
FROM events
WHERE 'AI' = ANY(categories);
```

This creates a table with a UUID, JSONB, timestamp, geospatial point, and array, then queries it.

## Key Differences Between SQL and PostgreSQL

- **Standard SQL**: Defines portable types like `INT`, `VARCHAR`, `TIMESTAMP`, supported by most RDBMSs.
- **PostgreSQL**: Extends SQL with types like `JSONB`, `ARRAY`, `UUID`, and `GEOMETRY`, plus extensibility for custom types.
- **Performance**: PostgreSQL optimizes storage (e.g., TOAST for large data) and supports specialized indexes (e.g., GIN, GiST).
- **Use Cases**: PostgreSQL’s types are ideal for modern applications (e.g., web apps with JSON, GIS systems with PostGIS).

## Choosing Data Types

- **Use `INT` or `SERIAL`** for IDs and counters.
- **Use `NUMERIC`** for exact financial calculations.
- **Use `TEXT` or `VARCHAR`** for flexible text storage.
- **Use `TIMESTAMP WITH TIME ZONE`** for global applications.
- **Use `JSONB`** for semi-structured data.
- **Use `ARRAY` or `GEOMETRY`** for specialized needs like lists or spatial data.

## Resources

- [PostgreSQL Documentation: Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [PostGIS Documentation](https://postgis.net/docs/)



##### *Tags : [[1 - SQL 🦬]]