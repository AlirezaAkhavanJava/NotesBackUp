

SQLite security works differently from PostgreSQL. The key thing to understand is:

> **SQLite has no built-in user/role/permission system.**  
> You cannot natively say `user A can read this column` or `user B can update this row`.

SQLite is an **embedded database**. Usually, the operating system protects the entire `.db` file.

So security happens at several layers:

```text
Application
    ↓
Application authorization
    ↓
SQLite connection
    ↓
SQLite database file
    ↓
Operating-system permissions
```

Let's break down **database → table → column → row**.

---

# 1. Securing the entire SQLite database

Suppose you have:

```text
app.db
```

SQLite itself doesn't have:

```sql
CREATE USER alice;
GRANT SELECT ON app.db TO alice;
```

That doesn't exist.

Instead, you protect the **database file**.

For example:

```bash
chmod 600 app.db
```

Now only the file owner can read/write it.

```bash
ls -l app.db
```

You might get:

```text
-rw------- 1 ethan ethan 40960 app.db
```

This is the first security boundary.

### Better mental model

With PostgreSQL:

```text
PostgreSQL Server
    ├── users
    ├── roles
    ├── privileges
    └── database
```

With SQLite:

```text
Operating System
       │
       └── app.db
```

The OS protects the database file.

---

# 2. Securing a table

SQLite also doesn't have table-level `GRANT`/`REVOKE`.

You cannot natively do:

```sql
GRANT SELECT ON users TO alice;
```

Instead, you control what your **application exposes**.

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT,
    password_hash TEXT,
    email TEXT
);
```

Your application might expose:

```sql
SELECT id, username, email
FROM users;
```

but never expose:

```sql
SELECT password_hash
FROM users;
```

The authorization happens in your application.

---

# 3. Securing a column

This is where things become interesting.

Suppose:

```sql
CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    salary INTEGER,
    ssn TEXT
);
```

You may want:

```text
Normal employee:
    name
    email

Manager:
    name
    email
    salary

HR:
    name
    email
    salary
    ssn
```

SQLite doesn't provide column permissions.

Instead, you can create **views**.

For example:

```sql
CREATE VIEW employee_public AS
SELECT
    id,
    name,
    email
FROM employees;
```

Now the application can query:

```sql
SELECT * FROM employee_public;
```

instead of giving ordinary users access to:

```sql
SELECT * FROM employees;
```

You have effectively created a **security projection**.

---

# 4. Column hiding with views

Imagine:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT,
    email TEXT,
    password_hash TEXT
);
```

Create:

```sql
CREATE VIEW public_users AS
SELECT
    id,
    username,
    email
FROM users;
```

Now:

```sql
SELECT * FROM public_users;
```

returns:

```text
id | username | email
---+----------+----------------
1  | alice    | alice@example
2  | bob      | bob@example
```

The password hash isn't part of the view.

This is useful for **reducing accidental exposure**, but remember:

> A SQLite view is not a true permission boundary if the attacker can directly open the `.db` file.

If someone has filesystem access to `app.db`, they can query the underlying table directly.

---

# 5. Securing rows

This is the concept of **row-level security (RLS)**.

For example:

```text
users

id | username | department
---+----------+-----------
1  | Alice    | IT
2  | Bob      | HR
3  | John     | IT
```

Suppose Alice should only see IT employees.

PostgreSQL has native:

```sql
CREATE POLICY ...
```

SQLite does **not**.

So you implement the restriction in the query:

```sql
SELECT *
FROM users
WHERE department = ?;
```

For example:

```sql
SELECT *
FROM users
WHERE department = 'IT';
```

But in a real application, don't trust the client to supply:

```text
department=IT
```

The server determines the user's department from its authenticated identity.

---

# 6. A more realistic example

Suppose your Spring Boot application has:

```text
User
 ├── id
 ├── username
 └── role

Task
 ├── id
 ├── title
 └── owner_id
```

You want:

> A user can only access their own tasks.

Database:

```sql
CREATE TABLE task (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    owner_id INTEGER NOT NULL
);
```

Instead of:

```sql
SELECT *
FROM task;
```

your application executes:

```sql
SELECT *
FROM task
WHERE owner_id = ?;
```

And Java supplies the authenticated user's ID:

```java
long userId = authenticatedUser.getId();
```

Then:

```sql
SELECT *
FROM task
WHERE owner_id = 42;
```

This is effectively **application-level row-level security**.

---

# 7. Don't construct this dynamically

Bad:

```java
String sql =
    "SELECT * FROM task WHERE owner_id = " + userId;
```

Use a parameter:

```java
PreparedStatement statement =
    connection.prepareStatement(
        "SELECT * FROM task WHERE owner_id = ?"
    );

statement.setLong(1, userId);
```

Or with Spring Data:

```java
List<Task> findByOwnerId(Long ownerId);
```

The database query becomes conceptually:

```sql
SELECT *
FROM task
WHERE owner_id = ?;
```

This protects against SQL injection.

---

# 8. Securing writes is even more important

Suppose:

```text
Task #10 belongs to Alice
Task #20 belongs to Bob
```

Bob sends:

```http
PUT /tasks/10
```

Your backend must **not** simply do:

```sql
UPDATE task
SET title = ?
WHERE id = 10;
```

Because Bob could modify Alice's task.

Instead:

```sql
UPDATE task
SET title = ?
WHERE id = ?
AND owner_id = ?;
```

For example:

```sql
UPDATE task
SET title = 'Changed'
WHERE id = 10
AND owner_id = 42;
```

If Bob's ID is `42` and task 10 belongs to Alice:

```text
Rows affected = 0
```

That's an extremely useful security pattern.

---

# 9. Delete the same way

Don't do:

```sql
DELETE FROM task
WHERE id = ?;
```

Do:

```sql
DELETE FROM task
WHERE id = ?
AND owner_id = ?;
```

Now ownership is enforced **inside the mutation query**.

This is much safer than:

```java
Task task = repository.findById(id);

// maybe check ownership here...

repository.delete(task);
```

because you want the database operation itself to contain the ownership constraint.

---

# 10. Protecting sensitive column data

Sometimes you don't merely want to hide a column—you want to protect the actual data.

For example:

```text
credit_card_number
API keys
private documents
medical information
```

SQLite doesn't provide native column-level encryption.

You can encrypt the value **before storing it**.

Conceptually:

```text
Application
    ↓
encrypt("4111...")
    ↓
SQLite
    ↓
"8F31A92...."
```

For example:

```text
credit_card = encrypted ciphertext
```

The encryption key should **not** be stored in the SQLite database.

Otherwise:

```text
database + encryption key
        ↓
      useless
```

You want:

```text
SQLite database → ciphertext
Application secret → encryption key
```

---

# 11. Database encryption

Plain SQLite:

```text
app.db
```

contains readable SQLite structures.

If somebody copies the file:

```bash
cp app.db stolen.db
```

they may be able to open it with:

```bash
sqlite3 stolen.db
```

SQLite itself doesn't provide full database-file encryption in the standard SQLite distribution.

For encrypted SQLite databases, you need something such as **SQLCipher** or application-level encryption.

The architectural difference is:

```text
Normal SQLite

app
 ↓
SQLite
 ↓
app.db
```

versus:

```text
Encrypted SQLite

app
 ↓
SQLite + encryption layer
 ↓
encrypted.db
```

---

# 12. Triggers can enforce some rules

SQLite triggers can be useful for **integrity enforcement**, although they aren't an authorization system.

For example:

```sql
CREATE TRIGGER prevent_invalid_owner
BEFORE INSERT ON task
WHEN NEW.owner_id IS NULL
BEGIN
    SELECT RAISE(ABORT, 'owner required');
END;
```

Now:

```sql
INSERT INTO task(title, owner_id)
VALUES ('Learn SQLite', NULL);
```

fails.

You can use triggers to enforce rules such as:

```text
audit logging
prevent certain updates
prevent deletion
validate relationships
maintain derived data
```

But don't mistake triggers for user permissions.

---

# 13. Foreign keys are also security-adjacent

For ownership:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY
);

CREATE TABLE task (
    id INTEGER PRIMARY KEY,
    owner_id INTEGER NOT NULL,

    FOREIGN KEY (owner_id)
        REFERENCES users(id)
);
```

And enable them:

```sql
PRAGMA foreign_keys = ON;
```

Now:

```text
task.owner_id
      │
      ▼
users.id
```

SQLite prevents references to nonexistent users.

That's **data integrity**, not authorization.

---

# 14. The important distinction

You should separate these concepts:

|Mechanism|Protects|
|---|---|
|OS file permissions|Entire DB file|
|Database encryption|DB contents at rest|
|Views|Exposed columns/rows|
|Application authorization|Users' access|
|`WHERE owner_id = ?`|Row ownership|
|Prepared statements|SQL injection|
|Foreign keys|Referential integrity|
|Constraints|Invalid data|
|Triggers|Database-side rules/auditing|

---

# 15. The architecture I'd use in a Spring Boot + SQLite application

For something like your `DoItLater` application:

```text
             HTTP Request
                  │
                  ▼
          Spring Security
                  │
            Authentication
                  │
                  ▼
              Controller
                  │
                  ▼
               Service
                  │
          ┌───────┴────────┐
          │ authorization  │
          └───────┬────────┘
                  │
                  ▼
             Repository
                  │
                  ▼
               SQLite
                  │
        ┌─────────┴─────────┐
        │                   │
    constraints          indexes
        │
        ▼
     SQLite file
        │
        ▼
    OS permissions
```

For example:

```java
taskRepository.findByIdAndOwnerId(taskId, userId);
```

with:

```sql
SELECT *
FROM task
WHERE id = ?
AND owner_id = ?;
```

That's the SQLite equivalent of implementing a basic **row-level authorization model** at the application layer.

### The mental model

Think of SQLite security as:

```text
DATABASE
   │
   ├── File permissions
   │
   ├── Encryption
   │
   └── SQLite integrity
          │
          ├── constraints
          ├── foreign keys
          └── triggers

APPLICATION
   │
   ├── Authentication
   │
   ├── Authorization
   │
   ├── Column exposure
   │
   └── Row ownership
```

The crucial point is: **SQLite is not a multi-user database server like PostgreSQL.** If you need database-native users, roles, `GRANT`, `REVOKE`, row-level security, and column privileges, PostgreSQL is the appropriate tool.


[[SQlite]]