


## 1. The Problem JDBC Solves

Imagine you're developing a Java application that needs to communicate with a PostgreSQL database.

Your Java application needs to perform operations such as:

- Insert a new user into a database.
    
- Retrieve users from a database.
    
- Update an existing user's information.
    
- Delete records.
    
- Execute SQL queries.
    

But there is a problem.

**Java and PostgreSQL are two different systems.**

Java doesn't naturally understand how to communicate with a PostgreSQL server, send SQL commands through PostgreSQL's network protocol, or receive database results.

We need a standard way for Java applications to communicate with relational databases.

**That's why JDBC exists.**

---

## 2. What Is JDBC?

**JDBC (Java Database Connectivity)** is a standard Java API that allows Java applications to communicate with relational databases using SQL.

It provides interfaces and classes for:

1. Establishing database connections.
    
2. Sending SQL queries.
    
3. Receiving and processing results.
    
4. Managing database transactions.
    
5. Handling database errors.
    

One important thing to understand:

**JDBC is an API, not a database, ORM, or framework.**

It defines a standard way to work with databases, but the database-specific communication is handled by a **JDBC driver**.

---

## 3. JDBC Architecture

Let's understand the architecture before writing code.

```
         Java Application
                |
                v
            JDBC API
                |
                v
           JDBC Driver
                |
                v
       PostgreSQL Database
```

### Step-by-step explanation

**Step 1: Java Application**

Your application wants to retrieve information from the database.

For example:

```
SELECT * FROM users;
```

**Step 2: JDBC API**

Your application uses JDBC interfaces such as `Connection`, `PreparedStatement`, and `ResultSet`.

These provide a standard programming model for database communication.

**Step 3: JDBC Driver**

The JDBC driver is responsible for communicating with the actual database.

Different databases have different drivers:

|Database|JDBC Driver|
|---|---|
|PostgreSQL|PostgreSQL JDBC Driver|
|MySQL|MySQL Connector/J|
|MariaDB|MariaDB Connector/J|
|SQLite|SQLite JDBC|
|Oracle Database|Oracle JDBC Driver|

**Step 4: Database**

The database receives the SQL command, executes it, and returns the results through the driver.

### Why is this architecture useful?

Because your Java code can use the same JDBC interfaces regardless of the database.

For example:

```
Connection connection;
PreparedStatement statement;
ResultSet resultSet;
```

These interfaces work with PostgreSQL, MySQL, MariaDB, and other JDBC-compatible databases.

You generally change the driver, connection configuration, and potentially database-specific SQL rather than rewriting the entire database communication layer.

---

## 4. JDBC vs JDBC Driver vs SQL Dialect

These three concepts are related, but they solve different problems.

|Concept|Responsibility|
|---|---|
|JDBC API|Defines how Java applications interact with databases|
|JDBC Driver|Implements JDBC and communicates with a specific database|
|SQL Dialect|Describes the SQL syntax and database-specific features supported by a database|

For example, when Hibernate communicates with PostgreSQL:

- **JDBC** provides the Java database-access API.
    
- **PostgreSQL JDBC Driver** handles communication with PostgreSQL.
    
- **PostgreSQL Dialect** helps Hibernate generate SQL appropriate for PostgreSQL.
    

Remember:

**JDBC defines the communication interface, the driver implements it, and a dialect helps frameworks generate compatible SQL.**

---

## 5. Important JDBC Interfaces

JDBC provides several important interfaces.

Let's learn the four you'll encounter most often.

### 5.1. Connection

`Connection` represents an active connection to a database.

```
Connection connection = DriverManager.getConnection(
    "jdbc:postgresql://localhost:5432/mydb",
    "postgres",
    "password"
);
```

Here:

- `DriverManager` finds a suitable registered JDBC driver.
    
- `getConnection()` requests a database connection.
    
- `Connection` represents the connection established by the driver.
    

Once we have a connection, we can execute SQL commands.

### 5.2. Statement

`Statement` allows Java to execute SQL commands.

```
Statement statement = connection.createStatement();

ResultSet result = statement.executeQuery(
    "SELECT * FROM users"
);
```

It works, but concatenating untrusted input into a `Statement` can lead to SQL injection.

For SQL containing user-provided values, prefer `PreparedStatement`.

### 5.3. PreparedStatement

`PreparedStatement` represents a parameterized SQL statement.

```
PreparedStatement statement =
    connection.prepareStatement(
        "SELECT * FROM users WHERE username = ?"
    );

statement.setString(1, "alireza");
```

The `?` represents a parameter placeholder.

`setString(1, "alireza")` supplies the value for the first parameter.

This is particularly important because parameter binding separates user-supplied values from SQL syntax and protects against SQL injection through those values.

### 5.4. ResultSet

`ResultSet` represents the tabular results returned by a SQL query.

```
ResultSet result = statement.executeQuery();

while (result.next()) {
    System.out.println(result.getString("username"));
}
```

Let's understand what happens:

- `executeQuery()` executes a query that returns a `ResultSet`.
    
- `next()` moves the cursor to the next row.
    
- `getString("username")` reads the `username` column from the current row.
    

Initially, the cursor is positioned before the first row.

Each call to `next()` advances it. The method returns `false` when there are no more rows.

---

## 6. Practical Example: Java + PostgreSQL

Let's write a simple application that retrieves a user from PostgreSQL.

Assume we have this table:

```
CREATE TABLE app_users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE
);
```

Insert some data:

```
INSERT INTO app_users (username)
VALUES ('alireza'), ('john'), ('sara');
```

### Step 1: Add the JDBC Driver

In a Spring Boot Gradle project, add:

```
dependencies {
    runtimeOnly 'org.postgresql:postgresql'
}
```

Spring Boot's dependency management supplies the compatible driver version.

For a standalone Java project, you also need to provide a compatible PostgreSQL JDBC driver dependency and its version.

The JDBC API itself is already included in the Java platform.

### Step 2: Configure the Database Connection

For this example, we'll use environment variables instead of hardcoding database credentials.

In Linux:

```
export DB_URL="jdbc:postgresql://localhost:5432/mydb"
export DB_USER="postgres"
export DB_PASSWORD="your_password"
```

Replace the values with your actual database configuration.

### Step 3: Write the Java Code

```
import java.sql.*;

public class Main {

    public static void main(String[] args) {

        String url = System.getenv("DB_URL");
        String user = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");

        String sql =
            "SELECT id, username FROM app_users WHERE username = ?";

        try (
            Connection connection =
                DriverManager.getConnection(url, user, password);

            PreparedStatement statement =
                connection.prepareStatement(sql)
        ) {

            statement.setString(1, "alireza");

            try (ResultSet result = statement.executeQuery()) {

                while (result.next()) {

                    long id = result.getLong("id");
                    String username = result.getString("username");

                    System.out.println(id + " : " + username);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

### What Happens Internally?

Let's follow the execution.

**1. DriverManager establishes a connection**

```
DriverManager.getConnection(url, user, password);
```

It uses the appropriate JDBC driver to establish a connection with PostgreSQL.

**2. Java creates a PreparedStatement**

```
connection.prepareStatement(sql);
```

We create a statement representing the SQL command.

**3. Java supplies the SQL parameter**

```
statement.setString(1, "alireza");
```

We bind the username value to the SQL statement.

**4. The driver executes the query**

```
statement.executeQuery();
```

The driver communicates with PostgreSQL and obtains the query results.

**5. Java processes the results**

```
result.next();
result.getString("username");
```

We read the returned rows.

**6. Resources are closed**

We used Java's `try-with-resources`.

This automatically closes the `ResultSet`, `PreparedStatement`, and `Connection`, even when an exception occurs.

Closing connections is especially important because database connections consume limited server and application resources.

---

## 7. How Do We Insert, Update, and Delete?

JDBC provides different execution methods.

|Method|Purpose|Return value|
|---|---|---|
|`executeQuery()`|Execute SQL returning a result set, commonly SELECT|`ResultSet`|
|`executeUpdate()`|Execute INSERT, UPDATE, DELETE, or SQL statements such as DDL|`int`|
|`execute()`|Execute SQL when the kind of result may vary|`boolean`|

For example:

```
String sql =
    "INSERT INTO app_users (username) VALUES (?)";

try (PreparedStatement statement =
         connection.prepareStatement(sql)) {

    statement.setString(1, "michael");

    int affectedRows = statement.executeUpdate();

    System.out.println("Inserted rows: " + affectedRows);
}
```

Notice that `executeUpdate()` returns the number of affected rows for an INSERT, UPDATE, or DELETE.

---

## 8. What About Transactions?

JDBC also gives us direct control over database transactions.

By default, JDBC connections commonly use **auto-commit mode**, meaning each individual SQL statement is committed when it completes successfully.

We can disable auto-commit:

```
connection.setAutoCommit(false);

try {
    // Execute SQL statements here.

    connection.commit();

} catch (SQLException e) {

    connection.rollback();
    throw e;
}
```

This allows several SQL statements to participate in a single transaction.

For example, when transferring money between bank accounts, both the withdrawal and deposit should succeed together.

If one operation fails, the transaction can roll back.

In Spring Boot, we usually prefer Spring's declarative transaction management:

```
@Transactional
public void transferMoney() {
    // Database operations
}
```

Spring manages transaction boundaries using its transaction infrastructure and, for JDBC-backed relational transactions, the underlying database connections.

---

## 9. How JDBC Works in Spring Boot

Here's where JDBC becomes particularly important for you as a Spring Boot developer.

When you write:

```
public interface AppUserRepository
        extends JpaRepository<AppUser, Long> {
}
```

You are using **Spring Data JPA**, not JDBC directly.

However, your application will typically still use JDBC internally when communicating with a relational database.

Consider this architecture:

```
             Controller
                 |
                 v
               Service
                 |
                 v
          JPA Repository
                 |
                 v
             Hibernate
                 |
                 v
              JDBC API
                 |
                 v
        PostgreSQL JDBC Driver
                 |
                 v
          PostgreSQL Server
```

Let's understand it:

1. Your controller receives a request.
    
2. Your service performs business logic.
    
3. Your repository executes a persistence operation.
    
4. Hibernate translates entity operations into SQL.
    
5. Hibernate uses JDBC to execute SQL through the database driver.
    
6. PostgreSQL executes the SQL and returns results.
    
7. Hibernate maps the results into Java entities.
    

That's why you rarely write JDBC code manually when working with Spring Data JPA.

**Hibernate uses JDBC for database access, while providing a much higher-level persistence abstraction.**

---

## 10. JDBC vs JdbcTemplate vs JPA

Spring Boot supports multiple approaches to relational database access.

|Feature|JDBC|Spring JdbcTemplate|JPA / Hibernate|
|---|---|---|---|
|Abstraction level|Low|Medium|High|
|Write SQL manually|Yes|Usually yes|Often optional|
|Map rows to Java objects|Manually|Manually or with helpers|Automatically through entity mapping|
|Manage JDBC resources|Manually|Handled by template|Handled by provider/framework|
|ORM support|No|No|Yes|
|Control over SQL|High|High|High with native queries, otherwise abstracted|

### JDBC

You manage connections, statements, SQL, and result processing yourself.

### JdbcTemplate

Spring simplifies JDBC by managing much of the repetitive work.

Example:

```
@Repository
public class AppUserRepository {

    private final JdbcTemplate jdbcTemplate;

    public AppUserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public String findUsername(long id) {

        String sql =
            "SELECT username FROM app_users WHERE id = ?";

        return jdbcTemplate.queryForObject(
            sql,
            String.class,
            id
        );
    }
}
```

Here, `JdbcTemplate` internally uses JDBC.

You don't have to manually create or close statements and connections.

Unlike JPA, `JdbcTemplate` doesn't provide ORM entity lifecycle management.

### JPA / Hibernate

With Spring Data JPA:

```
public interface AppUserRepository
        extends JpaRepository<AppUser, Long> {
}
```

You can perform many database operations without writing SQL manually.

Hibernate manages entity persistence and maps entity state to relational database operations.

**Important:** Spring Data JDBC is another persistence technology. Despite the similar name, it is not the same as Spring Data JPA or `JdbcTemplate`.

---

## 11. Connection Pooling

There's one more concept worth understanding.

Opening a new database connection for every request can be expensive.

A database connection may require:

- Network communication.
    
- Authentication.
    
- Database server resources.
    
- Connection initialization.
    

Instead of repeatedly creating physical connections, applications commonly use a **connection pool**.

A connection pool maintains a collection of reusable database connections.

```
              Spring Boot
                  |
                  v
          Connection Pool
           (e.g. HikariCP)
                  |
         +--------+--------+
         |        |        |
         v        v        v
       Conn 1   Conn 2   Conn 3
         |        |        |
         +--------+--------+
                  |
                  v
              Database
```

In typical Spring Boot JDBC and JPA applications, **HikariCP** is the default connection pool when available.

Spring commonly obtains connections from a `DataSource`.

When application code closes a pooled connection handle, the underlying physical connection is normally returned to the pool rather than actually disconnected.

This makes connection reuse possible.

---

## 12. Common Mistakes

|Mistake|Why it's a problem|Better approach|
|---|---|---|
|Forgetting to close connections|Connection/resource leaks|Use try-with-resources|
|Concatenating user input into SQL|SQL injection|Use PreparedStatement parameters|
|Creating a physical connection for every request|Unnecessary overhead|Use a DataSource with pooling|
|Hardcoding database passwords|Security and deployment risks|Use environment variables or a secrets manager|
|Assuming JDBC is Hibernate|Confuses abstraction layers|Understand that Hibernate uses JDBC|
|Forgetting transaction boundaries|Partial database updates|Use transactions when operations must be atomic|

---

## 13. Try It Yourself

To make sure you understand JDBC, try the following exercise:

1. Create a PostgreSQL database called `jdbc_practice`.
    
2. Create a table named `students` with `id`, `name`, and `age`.
    
3. Write Java code to connect to the database using JDBC.
    
4. Insert three students using `PreparedStatement`.
    
5. Retrieve all students using `ResultSet`.
    
6. Update one student's age.
    
7. Delete one student.
    
8. Wrap the database operations in appropriate try-with-resources blocks.
    

This exercise teaches the core JDBC workflow without relying on Spring Data JPA.

---

## 14. The Whole Picture

|Component|What it does|
|---|---|
|JDBC|Standard Java API for relational database access|
|JDBC Driver|Implements JDBC to communicate with a particular database|
|DriverManager|Obtains connections through registered drivers|
|DataSource|Standard abstraction for obtaining connections, often from a pool|
|Connection|Represents a database connection|
|Statement|Executes SQL commands|
|PreparedStatement|Executes parameterized SQL commands|
|ResultSet|Provides access to returned query rows|
|SQLException|Represents database access and JDBC-related errors|
|JdbcTemplate|Spring abstraction that simplifies direct JDBC usage|
|Hibernate|ORM implementation that typically uses JDBC underneath|
|Spring Data JPA|Repository abstraction built on JPA|
|HikariCP|Database connection pool|

### Final Understanding

**JDBC is the foundation of relational database communication in Java.**

Before frameworks such as Hibernate and Spring Data JPA, Java developers commonly used JDBC directly to connect to databases, execute SQL, and map results into Java objects.

Modern frameworks haven't replace



[[Java]]