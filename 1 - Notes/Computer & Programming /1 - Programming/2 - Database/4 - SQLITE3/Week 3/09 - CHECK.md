

## `CHECK`

`CHECK` is a **constraint that requires an expression to be true** whenever a row is inserted or updated.

```sql
CREATE TABLE collections (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    deleted INTEGER CHECK (deleted IN (0, 1))
);
```

Now:

```sql
INSERT INTO collections (title, deleted)
VALUES ('Ancient Vase', 0);
```

works.

But:

```sql
INSERT INTO collections (title, deleted)
VALUES ('Ancient Vase', 5);
```

fails because:

```text
5 IN (0, 1)
```

is false.

### Another example

```sql
CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    salary INTEGER CHECK (salary >= 0)
);
```

This works:

```sql
INSERT INTO employees (name, salary)
VALUES ('Alice', 5000);
```

This doesn't:

```sql
INSERT INTO employees (name, salary)
VALUES ('Bob', -100);
```

SQLite rejects it.

### `CHECK` on multiple columns

You can also validate a relationship between columns:

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    price INTEGER,
    discount INTEGER,

    CHECK (discount <= price)
);
```

So:

```text
price = 100
discount = 20
```

is valid.

But:

```text
price = 100
discount = 150
```

is rejected.

### Important distinction

`CHECK` protects **data integrity**, not user access.

```text
CHECK
  ↓
"Is this value/row valid?"

Authorization
  ↓
"Is this user allowed to access/change this row?"
```

For your CS50 database practice, a very good exercise is:

```sql
CREATE TABLE collections (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    accession_number TEXT NOT NULL,
    acquired TEXT,
    deleted INTEGER DEFAULT 0
        CHECK (deleted IN (0, 1))
);
```

Then deliberately try:

```sql
INSERT INTO collections
(title, accession_number, deleted)
VALUES ('Test', 'ACC-9999', 2);
```

and observe the constraint failure.



[[Data-base]]
[[SQlite]]