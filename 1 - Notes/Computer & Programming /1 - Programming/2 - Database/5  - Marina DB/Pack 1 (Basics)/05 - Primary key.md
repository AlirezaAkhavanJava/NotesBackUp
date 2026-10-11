
Think of a primary key and a foreign key as a pair: one says "this is who I am," the other says "this is who I belong to." Together they are how separate tables become a connected, trustworthy set of data.

## Primary key: a row's identity

A primary key is the column (or columns) that identifies exactly one row in a table. It enforces three rules at once:

- Every value must be **unique**.
- It can **never be NULL**.
- A table can have **only one** primary key.

```sql
CREATE TABLE users (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE
);
```

You can think of it like a Java object's identity, which is what lets you say "that exact user" even if two users share a name. The analogy bends a little: in Java, identity is tied to a spot in memory, while in a database it's an ordinary value you choose, and it has to stay meaningful forever, even after the program restarts.

### Which column should be the key?

You'll meet two schools of thought:

- **Natural key**: real data that's already unique, like an email or national ID. The danger is that real-world data changes. People change emails, and then every row pointing at the old value has to change too.
- **Surrogate key**: a meaningless number the database hands out, like `id`. It never needs to change, because it carries no real-world meaning.

Most developers use surrogate keys (`id INT AUTO_INCREMENT`) and put a separate `UNIQUE` constraint on the natural value, exactly as `email` is above. For tables that will grow huge, use `BIGINT UNSIGNED`.

### Other ways to write it

```sql
-- as a separate line (same result)
CREATE TABLE users (
  id INT AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

-- add one to an existing table
ALTER TABLE users ADD PRIMARY KEY (id);

-- remove it
ALTER TABLE users DROP PRIMARY KEY;
```

### Composite primary keys

When no single column identifies a row, a combination can:

```sql
CREATE TABLE enrollments (
  student_id INT,
  course_id  INT,
  enrolled_on DATE,
  PRIMARY KEY (student_id, course_id)
);
```

A student can appear many times, and so can a course, but the _pair_ can appear only once. That stops you from enrolling the same student in the same course twice.

---
## Foreign key: a link with a guarantee

A foreign key is a column whose values must match a primary key in another table. Here is the pattern:

```sql
CREATE TABLE orders (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  total   DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Read the last part aloud: "`user_id` in this table must match an `id` in `users`." The table with the foreign key (`orders`) is the **child**, and the table it points to (`users`) is the **parent**.

This is similar to an object reference in Java, where an `Order` holds a `User`. The difference is important, though. A database doesn't store a pointer you can follow. It stores just a number, and you follow it yourself by asking MariaDB to join the tables:

```sql
SELECT users.name, orders.total
FROM orders
JOIN users ON orders.user_id = users.id;
```

What you get in return for this extra work is the guarantee that the number always points at something real.

### The guarantee in action

```sql
INSERT INTO users (name, email) VALUES ('Sara', 'sara@example.com');   -- gets id 1

INSERT INTO orders (user_id, total) VALUES (1, 49.90);   -- works
INSERT INTO orders (user_id, total) VALUES (99, 10.00);
-- ERROR 1452: Cannot add or update a child row: a foreign key constraint fails
```

The same protection works in the other direction:

```sql
DELETE FROM users WHERE id = 1;
-- ERROR 1451: Cannot delete or update a parent row: a foreign key constraint fails
```

MariaDB won't let you leave an order orphaned, pointing at a user who no longer exists. In Spring Boot, both errors show up as a `DataIntegrityViolationException`.

### Rules that must line up

- **The parent must exist first.** Create `users` before `orders`, or the `REFERENCES` has nothing to point at.
- **The types must match exactly.** If `users.id` is `INT UNSIGNED`, then `orders.user_id` must be `INT UNSIGNED` too. A mismatch is the most common reason a foreign key fails to create, and the error message is vague (`errno: 150`).
- **The parent column must be a key** (a primary key or a unique column).
- **Both tables must use InnoDB**, which is the default in current MariaDB.

## What happens when the parent changes

You decide what the database does to child rows when a parent row is deleted or its key changes:

```sql
FOREIGN KEY (user_id) REFERENCES users(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE
```

|Action|Meaning|
|---|---|
|`RESTRICT` / `NO ACTION`|Refuse the change while children exist (the default)|
|`CASCADE`|Apply the change to the children too (delete the parent, children vanish)|
|`SET NULL`|Keep the children, but blank their link (column must allow `NULL`)|

Choose these deliberately. `CASCADE` is perfect for things that can't live without their parent, like the items inside an order. But for something valuable, like orders belonging to a user, a cascade means one careless `DELETE` quietly destroys a lot of data. Many developers keep `RESTRICT` as the default and cascade only where it's clearly right.

## Optional links

A foreign key column can allow `NULL`, which means "no parent". That's how you model an optional relationship:

```sql
CREATE TABLE tasks (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(100) NOT NULL,
  assigned_to INT NULL,
  FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);
```

A task may be unassigned, and if the assigned user is deleted, the task simply becomes unassigned. A `NULL` foreign key skips the check entirely, because "no value" has nothing to match.

## Common relationship shapes

**One-to-many** is the `users` and `orders` pattern above: the foreign key lives on the "many" side.

**Many-to-many** needs a middle table, because a single column can't hold a list. A junction table holds two foreign keys, and together they form its composite primary key:

```sql
CREATE TABLE enrollments (
  student_id INT NOT NULL,
  course_id  INT NOT NULL,
  PRIMARY KEY (student_id, course_id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (course_id)  REFERENCES courses(id)
);
```

**Self-referencing** is when a table points at itself, as with a comment and its reply:

```sql
CREATE TABLE comments (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  body      TEXT NOT NULL,
  parent_id INT NULL,
  FOREIGN KEY (parent_id) REFERENCES comments(id)
);
```

## Managing keys after the fact

```sql
-- add a foreign key to an existing table
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_user
  FOREIGN KEY (user_id) REFERENCES users(id);

-- remove one (use the constraint's name)
ALTER TABLE orders DROP FOREIGN KEY fk_orders_user;

-- see them all
SHOW CREATE TABLE orders;
```

Adding a foreign key fails if existing rows already break it, so clean up orphaned data first. And giving constraints your own names, like `fk_orders_user`, makes errors and drops much easier than the auto-generated `orders_ibfk_1`.

Two small bonuses: MariaDB automatically creates an index on a foreign key column, which makes joins faster. And while bulk-loading messy data, you can pause the checks with `SET FOREIGN_KEY_CHECKS = 0;` and turn them back on with `= 1;` afterward. Treat that as a last resort, since you've switched off the very guarantee that protects you.

## How this maps to Spring Boot

When you write JPA entities later, these two ideas show up as annotations:

```java
@Entity
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;            // the primary key (AUTO_INCREMENT)

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;          // the foreign key column
}
```

`@Id` is the primary key, and `@ManyToOne` with `@JoinColumn` is the foreign key. Notice that in Java you hold a whole `User` object, while the table stores only its `id`. JPA does the translating between the two.

## A quick way to decide

Ask these questions when you design a table. What uniquely identifies a row? That's your primary key. Does this row belong to something in another table? That's a foreign key on this side. And if the parent disappears, should this row disappear too, stay and go blank, or block the deletion? That's your `ON DELETE` choice.


[[MySQL]]