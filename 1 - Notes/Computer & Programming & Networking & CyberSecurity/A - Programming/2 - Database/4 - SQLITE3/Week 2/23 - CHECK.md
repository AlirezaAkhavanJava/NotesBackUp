

`CHECK` is a **column or table constraint** that requires a specified **Boolean expression to be true** when a row is inserted or updated.

If the expression evaluates to **false (`0`)**, SQLite rejects the operation.

### Basic syntax

```sql
column_name DATA_TYPE CHECK (condition)
```

### Example

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    age INTEGER CHECK (age >= 18)
);
```

This is valid:

```sql
INSERT INTO users (username, age)
VALUES ('Ali', 25);
```

This is rejected:

```sql
INSERT INTO users (username, age)
VALUES ('Ali', 15);
```

because:

```text
15 >= 18
↓
FALSE
```

---

## Common examples

### Range

```sql
age INTEGER CHECK (age BETWEEN 18 AND 100)
```

### Specific values

```sql
role TEXT CHECK (role IN ('USER', 'ADMIN'))
```

### Positive number

```sql
price REAL CHECK (price > 0)
```

### Multiple conditions

```sql
age INTEGER CHECK (age >= 18 AND age <= 100)
```

---

## Column-level `CHECK`

The condition normally refers to that column:

```sql
CREATE TABLE products (
    price REAL CHECK (price > 0)
);
```

## Table-level `CHECK`

A table constraint can check **multiple columns**:

```sql
CREATE TABLE orders (
    quantity INTEGER,
    price REAL,

    CHECK (quantity > 0 AND price > 0)
);
```

You can also compare columns:

```sql
CREATE TABLE events (
    start_date TEXT,
    end_date TEXT,

    CHECK (end_date >= start_date)
);
```

### Mental model

```text
INSERT / UPDATE
       │
       ▼
   CHECK(...)
       │
   ┌───┴───┐
 TRUE    FALSE
   │        │
   ▼        ▼
 Accept    Reject
```

**Definition:** `CHECK` is a constraint that prevents SQLite from storing a row when a specified condition evaluates to false.


[[1 - SQL 🥞]]