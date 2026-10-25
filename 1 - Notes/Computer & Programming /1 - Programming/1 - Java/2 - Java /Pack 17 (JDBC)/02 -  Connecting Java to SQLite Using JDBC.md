

## 1. What Are We Doing?

**JDBC (Java Database Connectivity)** is a standard Java API that allows Java applications to communicate with relational databases. To connect Java to SQLite, we use JDBC together with an SQLite JDBC driver, which implements the database-specific communication.

Unlike PostgreSQL or MySQL, **SQLite is an embedded database**, meaning it doesn't require a separate database server. The database is usually stored in a single file (`.db`), and your Java application can access that file directly through the SQLite JDBC driver.

## 2. The Problem It Solves

Imagine we have a Java application that needs to store information about students.

We want to:

- Connect to an SQLite database.
    
- Create a table.
    
- Insert students.
    
- Retrieve students.
    
- Update and delete students.
    

JDBC provides the Java interfaces necessary to perform these operations.

### How the connection works

```
           Java Application
                  |
                  v
       DriverManager.getConnection()
                  |
                  v
              JDBC API
                  |
                  v
          SQLite JDBC Driver
                  |
                  v
              SQLite Engine
                  |
                  v
            students.db
```

Notice that no separate database server is involved.

The SQLite JDBC driver uses the SQLite database engine to access the database file.

---

## 3. Step 1: Add the SQLite JDBC Driver

Java already includes the JDBC API, but we must add an SQLite JDBC driver.

For our project, we'll use the Xerial SQLite JDBC driver.

### Maven

Add this dependency inside `pom.xml`:

```
<dependency>
    <groupId>org.xerial</groupId>
    <artifactId>sqlite-jdbc</artifactId>
    <version>3.53.4.0</version>
</dependency>
```

### Gradle

If you're using Gradle:

```
dependencies {
    implementation 'org.xerial:sqlite-jdbc:3.53.4.0'
}
```

**What does this dependency do?**

It provides the implementation that allows JDBC to communicate with SQLite.

You do not need to install or start an SQLite server.

---

## 4. Step 2: Create a Connection

Let's create a simple Java class.

```
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Main {

    public static void main(String[] args) {

        String url = "jdbc:sqlite:students.db";

        try (Connection connection =
                     DriverManager.getConnection(url)) {

            System.out.println("Connected successfully!");

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

### Understanding the code

**1. Define the connection URL**

```
String url = "jdbc:sqlite:students.db";
```

The JDBC URL tells the driver which database to access.

Let's break it down:

|Part|Meaning|
|---|---|
|`jdbc:`|We are using JDBC|
|`sqlite:`|We want to use the SQLite JDBC driver|
|`students.db`|The database file|

If `students.db` doesn't exist, SQLite will normally create it automatically, provided the parent directory exists and is writable.

If it exists, SQLite opens the existing database.

A relative path is resolved against the application's current working directory.

**2. Establish the connection**

```
Connection connection =
        DriverManager.getConnection(url);
```

Here, `DriverManager` finds the registered SQLite JDBC driver and asks it to establish the connection.

The returned `Connection` object is our entry point for interacting with the database.

**3. Close the connection**

```
try (Connection connection =
             DriverManager.getConnection(url)) {
}
```

We use Java's try-with-resources feature.

When the block finishes, Java automatically closes the connection, including when an exception occurs.

### Do we need a username and password?

No, not for a normal SQLite database.

Unlike PostgreSQL, SQLite doesn't have a built-in database server authentication system with users and passwords.

For PostgreSQL, you might write:

```
DriverManager.getConnection(url, username, password);
```

For SQLite:

```
DriverManager.getConnection(url);
```

The operating system's file permissions are important for controlling access to a normal SQLite database file.

---

## 5. Step 3: Create a Table

Now that we have a connection, let's create a table.

```
String sql = """
        CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL
        )
        """;

try (Statement statement = connection.createStatement()) {

    statement.executeUpdate(sql);

    System.out.println("Table created successfully!");
}
```

### What's happening?

First, we create a `Statement` object:

```
Statement statement = connection.createStatement();
```

A `Statement` allows us to execute SQL commands through an established JDBC connection.

Then we execute:

```
statement.executeUpdate(sql);
```

The SQLite JDBC driver passes the SQL statement to the SQLite engine for execution.

`executeUpdate()` is used for statements such as INSERT, UPDATE, DELETE, and DDL statements such as CREATE TABLE.

---

## 6. Step 4: Insert Data Using PreparedStatement

Let's insert a student.

```
String sql = """
        INSERT INTO students (name, age)
        VALUES (?, ?)
        """;

try (PreparedStatement statement =
             connection.prepareStatement(sql)) {

    statement.setString(1, "Alireza");
    statement.setInt(2, 25);

    statement.executeUpdate();

    System.out.println("Student inserted!");
}
```

### Understanding PreparedStatement

```
PreparedStatement statement =
        connection.prepareStatement(sql);
```

A `PreparedStatement` represents a parameterized SQL statement.

Notice our placeholders:

```
INSERT INTO students (name, age)
VALUES (?, ?);
```

The `?` characters represent SQL parameters.

We provide their values using:

```
statement.setString(1, "Alireza");
statement.setInt(2, 25);
```

- `setString()` binds a String value.
    
- `setInt()` binds an integer value.
    
- The first argument identifies the parameter position, starting at 1.
    

**Why use PreparedStatement instead of Statement?**

Because parameter binding separates supplied values from SQL syntax, protecting against SQL injection through those values.

It also makes SQL operations easier to reuse with different values.

---

## 7. Step 5: Retrieve Data Using ResultSet

Now let's retrieve our students.

```
String sql = "SELECT id, name, age FROM students";

try (
    Statement statement = connection.createStatement();
    ResultSet resultSet = statement.executeQuery(sql)
) {

    while (resultSet.next()) {

        int id = resultSet.getInt("id");
        String name = resultSet.getString("name");
        int age = resultSet.getInt("age");

        System.out.println(id + " - " + name + " - " + age);
    }
}
```

### Understanding ResultSet

```
ResultSet resultSet = statement.executeQuery(sql);
```

When we execute a SELECT query, JDBC returns a `ResultSet`.

A `ResultSet` provides access to the rows returned by the database.

Initially, its cursor is positioned before the first row.

```
while (resultSet.next())
```

Each call to `next()` moves the cursor to the next row.

If another row exists, it returns `true`.

Otherwise, it returns `false`.

We can retrieve individual column values using methods such as:

```
resultSet.getInt("id");
resultSet.getString("name");
resultSet.getInt("age");
```

---

## 8. Complete Runnable Example

Let's combine everything into one Java application.

This application will:

1. Connect to SQLite.
    
2. Create a table if it doesn't exist.
    
3. Insert a student.
    
4. Retrieve all students.
    
5. Close the resources automatically.
    

```
import java.sql.*;

public class Main {

    public static void main(String[] args) {

        String url = "jdbc:sqlite:students.db";

        try (Connection connection =
                     DriverManager.getConnection(url)) {

            // 1. Create the table
            String createTable = """
                    CREATE TABLE IF NOT EXISTS students (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        age INTEGER NOT NULL
                    )
                    """;

            try (Statement statement =
                         connection.createStatement()) {

                statement.executeUpdate(createTable);
            }

            // 2. Insert a student
            String insertSql = """
                    INSERT INTO students (name, age)
                    VALUES (?, ?)
                    """;

            try (PreparedStatement statement =
                         connection.prepareStatement(insertSql)) {

                statement.setString(1, "Alireza");
                statement.setInt(2, 25);

                statement.executeUpdate();
            }

            // 3. Retrieve students
            String selectSql =
                    "SELECT id, name, age FROM students";

            try (
                Statement statement = connection.createStatement();
                ResultSet resultSet =
                        statement.executeQuery(selectSql)
            ) {

                while (resultSet.next()) {

                    int id = resultSet.getInt("id");
                    String name = resultSet.getString("name");
                    int age = resultSet.getInt("age");

                    System.out.println(
                            id + " | " + name + " | " + age
                    );
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

### Example output

On the first run:

```
1 | Alireza | 25
```

Each time you run the application, it inserts another student because the database persists between runs.

---

## 9. Verify the Database from the Linux Terminal

Since you're using Linux, you can inspect the database using the SQLite CLI.

Navigate to the directory containing `students.db` and run:

```
sqlite3 students.db
```

Inside the SQLite shell:

**Show tables:**

```
.tables
```

**Show table structure:**

```
.schema students
```

**Retrieve students:**

```
SELECT * FROM students;
```

**Exit SQLite:**

```
.quit
```

You can also execute queries directly from the terminal:

```
sqlite3 students.db "SELECT * FROM students;"
```

The `sqlite3` CLI is useful for inspection, but the Java JDBC driver doesn't require that CLI application to be installed.

---

## 10. Different SQLite JDBC URLs

SQLite JDBC supports different ways to locate a database.

|JDBC URL|Purpose|
|---|---|
|`jdbc:sqlite:students.db`|Relative database file|
|`jdbc:sqlite:/home/user/data/students.db`|Absolute path|
|`jdbc:sqlite::memory:`|In-memory database|

### File-based database

```
String url = "jdbc:sqlite:students.db";
```

SQLite stores the database in a persistent file.

Data remains available after the application exits.

### In-memory database

```
String url = "jdbc:sqlite::memory:";
```

SQLite creates a temporary database in memory.

For a normal private in-memory SQLite database, its contents disappear when the connection closes.

This is particularly useful for testing and experiments.

---

## 11. JDBC vs SQLite JDBC Driver

It's important to understand the distinction.

|JDBC|SQLite JDBC Driver|
|---|---|
|Standard Java API|Database-specific implementation|
|Provides `Connection`|Implements database connections|
|Provides `Statement`|Executes SQL using SQLite|
|Provides `PreparedStatement`|Supports SQLite parameter binding|
|Provides `ResultSet`|Exposes SQLite query results|
|Included in the JDK|Added as a project dependency|

This separation is the reason that most of our Java JDBC code looks similar whether we're working with PostgreSQL, SQLite, or MySQL.

---

## 12. Common Errors

### No suitable driver found

```
java.sql.SQLException:
No suitable driver found for jdbc:sqlite:students.db
```

This usually means the SQLite JDBC driver isn't available on the runtime classpath or wasn't registered correctly.

Make sure Maven or Gradle has downloaded the dependency and your application includes it at runtime.

With modern SQLite JDBC drivers, you ordinarily don't need to write:

```
Class.forName("org.sqlite.JDBC");
```

JDBC supports automatic driver discovery.

### Unable to open database file

```
[SQLITE_CANTOPEN] Unable to open the database file
```

Possible causes:

- The parent directory doesn't exist.
    
- The application lacks file permissions.
    
- The database path is incorrect.
    

### Database is locked

```
[SQLITE_BUSY] The database file is locked
```

SQLite supports concurrent readers, but typically only one writer at a time.

This error can happen when multiple connections or processes contend for a write lock.

Keep transactions reasonably short and use appropriate busy-timeout settings when necessary.

---

## 13. The Whole Picture

|Component|Responsibility|
|---|---|
|`DriverManager`|Finds a JDBC driver and requests a connection|
|SQLite JDBC Driver|Connects Java's JDBC API to SQLite|
|`Connection`|Represents a connection to the database|
|`Statement`|Executes SQL|
|`PreparedStatement`|Executes SQL with bound parameters|
|`ResultSet`|Provides access to query results|
|`SQLException`|Represents database-related errors|
|`students.db`|Stores the SQLite database|

### Final Understanding

When we use JDBC with SQLite, our Java application uses `DriverManager` to obtain a `Connection` through the SQLite JDBC driver. We then create SQL statements using that connection, execute them, and process the results.

The most important concept is that **JDBC provides the standard Java interfaces, while the SQLite JDBC driver provides the implementation that works with SQLite**.

Once you understand this process, you can build applications using JDBC directly or move to higher-level tools such as Spring's `JdbcTemplate` and Hibernate.




[[Java]]
[[SQlite]]