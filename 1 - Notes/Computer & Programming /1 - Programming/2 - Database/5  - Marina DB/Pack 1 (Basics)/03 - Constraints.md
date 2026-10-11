Think of constraints as rules the database enforces on every row, no matter which program is doing the writing. In Java terms, they're like validation annotations such as `@NotNull` or `@Size`, but they live inside the database itself. That's the whole point: your Spring Boot app, a script, and you typing in the shell all have to obey the same rules. The analogy breaks down in one place: Java validation can give friendly messages, while a database constraint just rejects the row with a blunt error. Your application has to catch that and translate it.

Let's build one table that uses all of them, then take the rules one at a time.

```sql
CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  username   VARCHAR(50)  NOT NULL UNIQUE,
  email      VARCHAR(150) NOT NULL,
  age        INT,
  role       VARCHAR(20)  NOT NULL DEFAULT 'member',
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_age CHECK (age IS NULL OR age >= 0),
  CONSTRAINT uq_email UNIQUE (email)
);
```

## NOT NULL and DEFAULT

`NOT NULL` says the column must always have a value. If an `INSERT` leaves it out and there's no default, MariaDB refuses the row. `DEFAULT` is the fallback used when you don't supply a value:

```sql
INSERT INTO users (username, email) VALUES ('sara', 'sara@example.com');
-- role becomes 'member', created_at becomes the current time
```

Remember that `NULL` means "unknown or missing", not zero and not an empty string. A column can be `NOT NULL` and still hold `''`, so if empty text is also unacceptable, add a `CHECK` for it.

## PRIMARY KEY

A primary key identifies exactly one row. It's automatically `NOT NULL` and `UNIQUE`, and a table can have only one. It can also span several columns, which is common in tables that link two other tables:

```sql
CREATE TABLE enrollments (
  student_id INT,
  course_id  INT,
  PRIMARY KEY (student_id, course_id)
);
```

Here a single student or course can appear many times, but the _pair_ can appear only once.

## UNIQUE

`UNIQUE` forbids duplicates in a column, or in a combination of columns. A table can have many unique constraints, unlike primary keys. One quirk catches people out: `NULL` isn't considered equal to anything, so a unique column usually allows several `NULL` rows.

```sql
ALTER TABLE users ADD CONSTRAINT uq_user_phone UNIQUE (phone);
```

## CHECK

`CHECK` rejects any row where a condition isn't true:

```sql
CONSTRAINT chk_age CHECK (age IS NULL OR age >= 0)
```

Notice the `age IS NULL OR` part. When a value is `NULL`, the comparison `age >= 0` evaluates to "unknown", and a `CHECK` treats unknown as passing, so it's technically optional here. Still, writing out the `NULL` case makes your intent explicit. `CHECK` has been properly enforced since MariaDB 10.2.1. Older tutorials claim MySQL ignores it, which was true of old MySQL versions but not of your MariaDB.

## FOREIGN KEY

A foreign key says "this column must match a value that exists in another table". It stops you from creating an order for a user who doesn't exist:

```sql
CREATE TABLE orders (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  total   DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
```

The `ON DELETE` part decides what happens to child rows when the parent is deleted:

- `RESTRICT` (the default behavior) blocks the delete while child rows exist.
- `CASCADE` deletes the children too.
- `SET NULL` keeps the children but blanks the link (the column must allow `NULL`).

`CASCADE` is convenient, but it's also how one careless `DELETE` quietly wipes out half your data. Choose it deliberately. Also, foreign keys need the InnoDB storage engine, which is the default in modern MariaDB, so you rarely have to think about it.

## AUTO_INCREMENT

It hands out the next number automatically. One thing to know: the counter never goes backwards. If you insert rows 1 to 5 and delete row 5, the next row gets 6. The numbers are identifiers, not a count, so gaps are normal and nothing to worry about.

## Managing constraints after the table exists

You can add, name, and remove constraints later:

```sql
ALTER TABLE users ADD CONSTRAINT chk_role CHECK (role IN ('member', 'admin'));
ALTER TABLE users DROP CONSTRAINT chk_role;
ALTER TABLE orders DROP FOREIGN KEY orders_ibfk_1;
ALTER TABLE users DROP INDEX uq_email;   -- unique constraints are removed as indexes
```

Giving constraints names with `CONSTRAINT some_name ...` is a good habit. If you don't, MariaDB invents names like `orders_ibfk_1`, and error messages become harder to read. To see what a table currently enforces:

```sql
SHOW CREATE TABLE users;
```

## What a violation looks like

```sql
INSERT INTO users (username, email, age) VALUES ('sara', 'x@example.com', 20);
-- ERROR 1062 (23000): Duplicate entry 'sara' for key 'username'

INSERT INTO users (username, email, age) VALUES ('omid', 'o@example.com', -5);
-- ERROR 4025 (23000): CONSTRAINT `chk_age` failed for `my_database`.`users`
```

When this happens inside a Spring Boot app, the error surfaces as a `DataIntegrityViolationException`. Catching that and returning a clear message ("that username is taken") is how the two layers cooperate. A good pattern is to validate in Java for friendly feedback _and_ keep the constraints in the database as the safety net. The database copy is the one that can't be bypassed.

## One more safeguard: strict mode

Rules only help if MariaDB enforces them strictly. With `STRICT_TRANS_TABLES` in `sql_mode`, inserting too-long text or an out-of-range number gives an error. Without it, MariaDB may silently chop the value and just warn you. Check yours with:

```sql
SELECT @@sql_mode;
```

Recent MariaDB versions include strict mode by default, so you're most likely fine, but it's worth knowing the setting exists.

## Beyond constraints

Constraints can only express simple rules about the row in front of them. For anything cross-row or procedural, such as "log every change to this table", MariaDB offers **triggers**. That's a later topic, and most of the time constraints plus application code are enough.

A good rule of thumb for choosing: if breaking the rule would mean _corrupt data_ (a duplicate email, an order with no user, a negative price), make it a constraint. If it's a business policy that might change often, keep it in your Java code.


[[MySQL]]