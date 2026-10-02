
In SQLite3, the `INSERT INTO` statement is used to add new rows of data into a table. Here are the different ways to use it:

## Basic Syntax

### 1. Insert with all column values (in order)
```sql
INSERT INTO table_name VALUES (value1, value2, value3, ...);
```

### 2. Insert with specified columns
```sql
INSERT INTO table_name (column1, column2, column3, ...)
VALUES (value1, value2, value3, ...);
```

### 3. Insert multiple rows at once
```sql
INSERT INTO table_name (column1, column2, column3)
VALUES 
    (value1, value2, value3),
    (value4, value5, value6),
    (value7, value8, value9);
```

## Examples

### Create a sample table
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    age INTEGER
);
```

### Insert a single row (all columns)
```sql
INSERT INTO users VALUES (1, 'Alice', 'alice@example.com', 30);
```

### Insert with specific columns (id auto-increments)
```sql
INSERT INTO users (name, email, age) 
VALUES ('Bob', 'bob@example.com', 25);
```

### Insert multiple rows
```sql
INSERT INTO users (name, email, age) VALUES 
    ('Charlie', 'charlie@example.com', 35),
    ('Diana', 'diana@example.com', 28),
    ('Eve', 'eve@example.com', 42);
```

### Insert with NULL values
```sql
INSERT INTO users (name, email, age) 
VALUES ('Frank', NULL, 40);
```

## Special Cases

### Insert or ignore duplicates
```sql
INSERT OR IGNORE INTO users (name, email, age) 
VALUES ('Alice', 'alice@example.com', 30);
```

### Insert or replace (upsert by primary key/unique)
```sql
INSERT OR REPLACE INTO users (id, name, email, age) 
VALUES (1, 'Alice Updated', 'alice@example.com', 31);
```

### Insert with a SELECT statement
```sql
INSERT INTO users (name, email, age)
SELECT name, email, age FROM temp_users WHERE age > 18;
```

## Using SQLite3 from Command Line

```bash
sqlite3 mydatabase.db
```

Then run:
```sql
INSERT INTO users (name, email, age) VALUES ('Grace', 'grace@example.com', 27);
```

## Using Python (sqlite3 module)

```python
import sqlite3

conn = sqlite3.connect('mydatabase.db')
cursor = conn.cursor()

# Single insert with parameters (safe from SQL injection)
cursor.execute(
    "INSERT INTO users (name, email, age) VALUES (?, ?, ?)",
    ('Henry', 'henry@example.com', 33)
)

# Multiple inserts
users = [
    ('Ivy', 'ivy@example.com', 29),
    ('Jack', 'jack@example.com', 45)
]
cursor.executemany(
    "INSERT INTO users (name, email, age) VALUES (?, ?, ?)",
    users
)

conn.commit()
conn.close()
```

## Key Points

- **String values** must be in single quotes: `'text'`
- **Numbers** don't need quotes: `42`
- **NULL** is written without quotes
- Use `?` placeholders when inserting from programming languages to prevent SQL injection
- `AUTOINCREMENT` columns can be omitted (SQLite assigns the next value)
- `INSERT OR IGNORE` skips rows that violate constraints
- `INSERT OR REPLACE` deletes the conflicting row and inserts the new one





[[1 - WHAT IS SQLITE3 🍕]]