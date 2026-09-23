
# JDBC and the Java SQL Package

## 1. Definition

**JDBC (Java Database Connectivity)** is Java's standard API for communicating with relational databases.

It allows Java applications to:

```text
Java application
      ↓
     JDBC
      ↓
JDBC Driver
      ↓
Database
(PostgreSQL, MySQL, SQLite, ...)
```

JDBC is part of the Java SE platform and is primarily provided by:

```java
java.sql
javax.sql
```

For modern Java applications, the important package is:

```java
java.sql
```

Spring Data JPA does not communicate with PostgreSQL "directly" from your entity classes. The lower-level stack ultimately looks roughly like:

```text
Your application
       ↓
Spring Data JPA
       ↓
JPA
       ↓
Hibernate
       ↓
JDBC
       ↓
PostgreSQL JDBC Driver
       ↓
PostgreSQL
```

So understanding JDBC helps you understand what happens underneath JPA.

---

# 2. What JDBC Actually Does

Suppose you want:

```sql
SELECT id, name FROM users WHERE id = 10;
```

Without JDBC, Java has no standard relational-database API.

With JDBC:

```java
Connection connection = ...;

PreparedStatement statement =
        connection.prepareStatement(
            "SELECT id, name FROM users WHERE id = ?"
        );

statement.setInt(1, 10);

ResultSet resultSet =
        statement.executeQuery();
```

JDBC handles the Java-side communication with the database driver.

---

# 3. The `java.sql` Package

The core JDBC API is centered around these interfaces/classes:

|Type|Purpose|
|---|---|
|`Driver`|Database-driver interface|
|`DriverManager`|Obtains database connections|
|`Connection`|Connection/session with database|
|`Statement`|Executes SQL|
|`PreparedStatement`|Executes parameterized SQL|
|`CallableStatement`|Calls stored procedures|
|`ResultSet`|Represents query results|
|`SQLException`|Database-related exception|
|`SQLWarning`|Database warning|
|`DatabaseMetaData`|Database information|
|`ResultSetMetaData`|Result-column information|
|`Savepoint`|Transaction savepoints|
|`Types`|JDBC SQL type constants|

You should know these particularly well:

```text
Connection
PreparedStatement
ResultSet
SQLException
DriverManager
```

---

# 4. JDBC Driver

Java itself doesn't know how to speak PostgreSQL's wire protocol.

You install a **JDBC driver**.

For PostgreSQL:

```text
PostgreSQL JDBC Driver
```

The application uses the standard JDBC interfaces, while the driver implements the database-specific communication.

Conceptually:

```text
Your code
   │
   │ java.sql.Connection
   ▼
PostgreSQL JDBC Driver
   │
   │ PostgreSQL protocol
   ▼
PostgreSQL server
```

This is one of JDBC's major abstractions:

> Your code uses a common API while the driver handles database-specific details.

---

# 5. `DriverManager`

`DriverManager` can obtain a database connection.

Example:

```java
Connection connection =
        DriverManager.getConnection(
            "jdbc:postgresql://localhost:5432/mydb",
            "postgres",
            "password"
        );
```

The JDBC URL:

```text
jdbc:postgresql://localhost:5432/mydb
```

can be broken down into:

```text
jdbc:
  ↓
JDBC
postgresql:
  ↓
database/driver
localhost
  ↓
host
5432
  ↓
port
mydb
  ↓
database
```

---

# 6. `Connection`

A `Connection` represents a session between your Java application and the database.

```java
Connection connection =
        DriverManager.getConnection(url, username, password);
```

It is used to:

- execute SQL
    
- create statements
    
- manage transactions
    
- commit
    
- rollback
    
- create savepoints
    
- inspect connection state
    

Example:

```java
connection.setAutoCommit(false);

try {
    // SQL operations

    connection.commit();
} catch (SQLException e) {
    connection.rollback();
}
```

---

# 7. `Statement`

A `Statement` executes static SQL.

```java
Statement statement =
        connection.createStatement();

ResultSet resultSet =
        statement.executeQuery(
            "SELECT * FROM users"
        );
```

However, don't use it for user-provided values like:

```java
String username = userInput;

statement.executeQuery(
    "SELECT * FROM users WHERE name = '" +
    username +
    "'"
);
```

This creates an SQL injection risk.

Use `PreparedStatement`.

---

# 8. `PreparedStatement`

`PreparedStatement` is one of the most important JDBC APIs.

```java
PreparedStatement statement =
        connection.prepareStatement(
            "SELECT * FROM users WHERE name = ?"
        );

statement.setString(1, "Alireza");

ResultSet resultSet =
        statement.executeQuery();
```

The `?` is a **parameter placeholder**.

Then:

```java
statement.setString(1, "Alireza");
```

sets parameter number `1`.

Parameters are **1-based**, not 0-based.

```text
? ? ?
│ │ │
1 2 3
```

---

# 9. Why `PreparedStatement` Matters

It separates:

```text
SQL structure
```

from:

```text
data
```

Instead of constructing:

```sql
SELECT * FROM users WHERE name = '...'
```

with string concatenation, you send:

```sql
SELECT * FROM users WHERE name = ?
```

and bind the value separately.

This is both safer and generally the correct JDBC practice for dynamic values.

---

# 10. Setting Parameters

Common methods include:

```java
statement.setString(1, "Alireza");
statement.setInt(2, 25);
statement.setLong(3, 100L);
statement.setBoolean(4, true);
statement.setDouble(5, 19.99);
statement.setDate(6, date);
statement.setTimestamp(7, timestamp);
```

There is also:

```java
statement.setObject(...)
```

for more generic handling.

---

# 11. `ResultSet`

`ResultSet` represents rows returned by a query.

```java
ResultSet resultSet =
        statement.executeQuery();
```

You move through rows using:

```java
resultSet.next();
```

Example:

```java
while (resultSet.next()) {

    int id =
        resultSet.getInt("id");

    String name =
        resultSet.getString("name");

    System.out.println(id + " " + name);
}
```

Think of it as:

```text
ResultSet
────────────────────
| id | name        |
|----|-------------|
|  1 | Alice       |
|  2 | Bob         |
|  3 | Charlie     |
────────────────────
        ↑
      cursor
```

`next()` advances the cursor to the next row.

---

# 12. Reading Columns

You can read by column name:

```java
resultSet.getString("name");
resultSet.getInt("age");
resultSet.getBoolean("active");
```

or by column index:

```java
resultSet.getString(2);
resultSet.getInt(1);
```

Column indexes are also **1-based**.

Usually, column names are easier to maintain.

---

# 13. `executeQuery()`

Use:

```java
executeQuery()
```

for SQL that returns a result set, typically:

```sql
SELECT
```

Example:

```java
ResultSet result =
    statement.executeQuery(
        "SELECT * FROM users"
    );
```

---

# 14. `executeUpdate()`

Use:

```java
executeUpdate()
```

for operations such as:

```sql
INSERT
UPDATE
DELETE
```

Example:

```java
PreparedStatement statement =
    connection.prepareStatement(
        "UPDATE users SET name = ? WHERE id = ?"
    );

statement.setString(1, "Ali");
statement.setInt(2, 10);

int affectedRows =
    statement.executeUpdate();
```

`affectedRows` tells you how many rows were modified.

---

# 15. `execute()`

There is also:

```java
statement.execute();
```

It is more general and can handle statements whose result type may vary.

Most application code normally uses:

```text
SELECT → executeQuery()
INSERT/UPDATE/DELETE → executeUpdate()
```

---

# 16. INSERT Example

```java
String sql =
    "INSERT INTO users (name, age) VALUES (?, ?)";

try (PreparedStatement statement =
         connection.prepareStatement(sql)) {

    statement.setString(1, "Alireza");
    statement.setInt(2, 25);

    int rows =
        statement.executeUpdate();

    System.out.println(rows);
}
```

---

# 17. `try-with-resources`

JDBC resources need to be closed.

The preferred modern pattern is:

```java
try (Connection connection =
         DriverManager.getConnection(url, user, password);
     PreparedStatement statement =
         connection.prepareStatement(sql);
     ResultSet resultSet =
         statement.executeQuery()) {

    while (resultSet.next()) {
        // process
    }
}
```

Java automatically closes:

```text
ResultSet
    ↓
PreparedStatement
    ↓
Connection
```

when the block finishes.

This is much safer than manually calling `close()` everywhere.

---

# 18. `SQLException`

Most JDBC operations can throw:

```java
SQLException
```

Example:

```java
try {
    Connection connection =
        DriverManager.getConnection(url);
} catch (SQLException e) {
    e.printStackTrace();
}
```

`SQLException` gives information such as:

```java
e.getMessage();
e.getSQLState();
e.getErrorCode();
```

For serious database debugging, `SQLState` and vendor error codes can be useful.

---

# 19. Transactions

A transaction groups database operations into an atomic unit.

By default, JDBC connections usually operate with:

```java
connection.setAutoCommit(true);
```

meaning each SQL operation is committed automatically.

For explicit transaction management:

```java
connection.setAutoCommit(false);

try {

    // operation 1
    // operation 2
    // operation 3

    connection.commit();

} catch (SQLException e) {

    connection.rollback();
}
```

Conceptually:

```text
BEGIN
  ↓
INSERT
  ↓
UPDATE
  ↓
DELETE
  ↓
COMMIT
```

or on failure:

```text
BEGIN
  ↓
INSERT
  ↓
UPDATE ❌
  ↓
ROLLBACK
```

This becomes very important when learning Spring's:

```java
@Transactional
```

because Spring manages transaction boundaries for you at a higher level.

---

# 20. Savepoints

A transaction can contain savepoints.

```java
Savepoint savepoint =
    connection.setSavepoint();
```

Then:

```java
connection.rollback(savepoint);
```

This rolls back to that point rather than rolling back the entire transaction.

Conceptually:

```text
BEGIN
 ↓
INSERT
 ↓
SAVEPOINT A
 ↓
UPDATE
 ↓
ROLLBACK TO A
 ↓
COMMIT
```

---

# 21. JDBC Batch Operations

If you need many similar operations, batching can reduce network round trips.

```java
PreparedStatement statement =
    connection.prepareStatement(
        "INSERT INTO users (name) VALUES (?)"
    );

statement.setString(1, "Alice");
statement.addBatch();

statement.setString(1, "Bob");
statement.addBatch();

statement.setString(1, "Charlie");
statement.addBatch();

int[] results =
    statement.executeBatch();
```

Conceptually:

```text
Without batching:

Java → DB
Java → DB
Java → DB

With batching:

Java ─────→ DB
       batch
```

This can significantly improve bulk operations.

---

# 22. Generated Keys

Suppose PostgreSQL generates an ID:

```sql
INSERT INTO users(name)
VALUES ('Alireza')
```

You may want the generated ID.

Prepare the statement to request generated keys:

```java
PreparedStatement statement =
    connection.prepareStatement(
        "INSERT INTO users(name) VALUES (?)",
        Statement.RETURN_GENERATED_KEYS
    );
```

Then:

```java
statement.setString(1, "Alireza");

statement.executeUpdate();

try (ResultSet keys =
         statement.getGeneratedKeys()) {

    if (keys.next()) {
        long id = keys.getLong(1);
        System.out.println(id);
    }
}
```

This pattern is very important when working with relational databases.

---

# 23. JDBC and Connection Pooling

Creating database connections is relatively expensive.

Production applications therefore usually don't create one new physical connection for every query.

Instead:

```text
Application
     ↓
Connection Pool
 ┌───┼───┬───┐
 C1  C2  C3  C4
 └───┼───┴───┘
     ↓
 Database
```

A connection pool keeps reusable connections.

In Spring Boot applications, this is commonly handled through a connection pool such as **HikariCP**.

So this:

```java
DriverManager.getConnection(...)
```

is useful for learning JDBC, but typical Spring applications obtain connections through a `DataSource`.

---

# 24. `DataSource`

`DataSource` belongs to:

```java
javax.sql.DataSource
```

It provides database connections:

```java
Connection connection =
    dataSource.getConnection();
```

This is the more flexible abstraction commonly used in enterprise applications.

Why?

Because the `DataSource` can represent:

- a connection pool
    
- configured database access
    
- JNDI-managed connections
    
- framework-managed resources
    

The architecture becomes:

```text
Application
    ↓
DataSource
    ↓
Connection Pool
    ↓
JDBC Driver
    ↓
Database
```

---

# 25. JDBC Metadata

JDBC can inspect the database itself.

### Database metadata

```java
DatabaseMetaData metaData =
    connection.getMetaData();
```

You can inspect things such as:

```java
metaData.getDatabaseProductName();
metaData.getDatabaseProductVersion();
metaData.getDriverName();
metaData.getDriverVersion();
```

---

### Result-set metadata

```java
ResultSetMetaData metaData =
    resultSet.getMetaData();
```

You can discover:

```java
metaData.getColumnCount();
metaData.getColumnName(1);
metaData.getColumnType(1);
```

This is useful in generic database tools.

---

# 26. JDBC Data Types

JDBC maps Java types to SQL types.

For example:

|Java|SQL|
|---|---|
|`String`|`VARCHAR`, `TEXT`|
|`int`|`INTEGER`|
|`long`|`BIGINT`|
|`boolean`|`BOOLEAN`|
|`BigDecimal`|`DECIMAL`, `NUMERIC`|
|`LocalDate`|`DATE`|
|`LocalDateTime`|`TIMESTAMP`|
|`Instant`|commonly mapped depending on driver/schema|
|`byte[]`|binary types|

For modern Java, the `java.time` API is generally preferable to the old `java.sql.Date`/`Timestamp` types in application code, while JDBC still provides JDBC-specific types where needed.

---

# 27. The Main JDBC Workflow

Memorize this:

```text
1. Get Connection
       ↓
2. Create PreparedStatement
       ↓
3. Bind parameters
       ↓
4. Execute SQL
       ↓
5. Process ResultSet
       ↓
6. Commit / rollback if needed
       ↓
7. Close resources
```

Typical code:

```java
String sql =
    "SELECT id, name FROM users WHERE age > ?";

try (Connection connection =
         dataSource.getConnection();
     PreparedStatement statement =
         connection.prepareStatement(sql)) {

    statement.setInt(1, 18);

    try (ResultSet resultSet =
             statement.executeQuery()) {

        while (resultSet.next()) {

            long id =
                resultSet.getLong("id");

            String name =
                resultSet.getString("name");

            System.out.println(id + ": " + name);
        }
    }
}
```

---

# 28. JDBC CRUD

CRUD means:

```text
Create
Read
Update
Delete
```

### Create

```java
INSERT INTO users (name) VALUES (?)
```

→ `executeUpdate()`

### Read

```java
SELECT * FROM users
```

→ `executeQuery()`

### Update

```java
UPDATE users SET name = ? WHERE id = ?
```

→ `executeUpdate()`

### Delete

```java
DELETE FROM users WHERE id = ?
```

→ `executeUpdate()`

---

# 29. JDBC vs JPA

This is particularly important for your Spring learning.

|JDBC|JPA|
|---|---|
|Low-level database API|ORM specification|
|SQL is explicit|SQL often generated|
|You manage `ResultSet`|Entity objects|
|Manual row mapping|ORM mapping|
|Manual JDBC resource handling|Framework handles much of it|
|Database-oriented|Object-oriented abstraction|
|Fine-grained SQL control|Higher abstraction|
|`PreparedStatement`|Repository/query methods|

JDBC:

```java
ResultSet resultSet = statement.executeQuery();

while (resultSet.next()) {
    User user = new User();
    user.setId(resultSet.getLong("id"));
    user.setName(resultSet.getString("name"));
}
```

JPA:

```java
User user = userRepository.findById(id)
                          .orElseThrow();
```

JPA hides a lot of the JDBC work.

---

# 30. JDBC → Hibernate → Spring Data JPA

The stack is worth understanding:

```text
┌─────────────────────────────┐
│ Your Spring application     │
├─────────────────────────────┤
│ Spring Data JPA             │
├─────────────────────────────┤
│ JPA API                     │
├─────────────────────────────┤
│ Hibernate                   │
├─────────────────────────────┤
│ JDBC API                    │
├─────────────────────────────┤
│ PostgreSQL JDBC Driver      │
├─────────────────────────────┤
│ PostgreSQL                  │
└─────────────────────────────┘
```

So when you write:

```java
userRepository.findById(10L);
```

you are far above JDBC.

But eventually the database interaction reaches JDBC.

---

# 31. What You Should Actually Learn

You don't need to memorize every obscure JDBC class before learning Spring Data JPA.

For backend development, focus on this core:

```text
java.sql
│
├── Connection
├── PreparedStatement
├── ResultSet
├── SQLException
├── DriverManager
└── Types
```

And:

```text
javax.sql
└── DataSource
```

Then master these concepts:

```text
SQL
 ↓
Connection
 ↓
PreparedStatement
 ↓
parameters
 ↓
executeQuery / executeUpdate
 ↓
ResultSet
 ↓
mapping rows → Java objects
 ↓
transactions
 ↓
connection pooling
```

That foundation makes Spring Data JPA much easier to understand because you can see **what the abstraction is hiding instead of treating JPA as magic**.


[[Java]]