


**JDBC configuration** is the process of defining how a Java application connects to a database and how that connection behaves. This includes selecting a JDBC driver, specifying the database location through a JDBC URL, providing authentication credentials when necessary, and configuring properties such as timeouts, transaction management, and read-only access.

When working with JDBC, we generally configure two things: **how to establish the connection** and **how that connection should behave after it has been established**. JDBC provides standard configuration methods, while individual database drivers, such as SQLite JDBC or PostgreSQL JDBC, may provide additional database-specific settings.

---

## 1. What Do We Configure in JDBC?

Let's divide JDBC configuration into four categories.

|Category|What we configure|
|---|---|
|Driver configuration|Which JDBC driver is available|
|Connection configuration|Database URL, username, password, and connection properties|
|Connection behavior|Auto-commit, transactions, read-only mode, isolation|
|Database-specific configuration|SQLite foreign keys, busy timeout, journal mode, etc.|

For example:

```
String url = "jdbc:sqlite:students.db";

Connection connection = DriverManager.getConnection(url);
```

Here, we've only configured the database URL.

But JDBC supports much more.

---

## 2. JDBC Driver Configuration

Before Java can communicate with a database, an appropriate JDBC driver must be available.

For SQLite, we need the SQLite JDBC driver.

### Maven dependency

Inside `pom.xml`:

```
<dependencies>
    <dependency>
        <groupId>org.xerial</groupId>
        <artifactId>sqlite-jdbc</artifactId>
        <version>3.53.4.0</version>
    </dependency>
</dependencies>
```

When Maven downloads this dependency, the SQLite JDBC driver becomes available to our application.

Modern JDBC drivers generally register themselves automatically.

Therefore, we usually don't need to write:

```
Class.forName("org.sqlite.JDBC");
```

That's an older approach that explicitly loads the driver class.

The modern approach is simply:

```
Connection connection =
        DriverManager.getConnection("jdbc:sqlite:students.db");
```

`DriverManager` discovers an appropriate registered driver.

---

## 3. JDBC URL Configuration

The JDBC URL tells the driver which database we want to access.

The general syntax is:

```
jdbc:<subprotocol>:<subname>
```

For example:

```
String url = "jdbc:sqlite:students.db";
```

Let's examine the parts:

|Part|Meaning|
|---|---|
|`jdbc`|Use the JDBC API|
|`sqlite`|Use the SQLite JDBC subprotocol|
|`students.db`|SQLite database file|

### Different database URLs

**SQLite:**

```
String url = "jdbc:sqlite:students.db";
```

**PostgreSQL:**

```
String url = "jdbc:postgresql://localhost:5432/mydb";
```

**MySQL:**

```
String url = "jdbc:mysql://localhost:3306/mydb";
```

Notice that PostgreSQL and MySQL use a server address and port.

SQLite usually uses a file path because the database runs embedded in the application process.

### SQLite URL examples

|URL|Description|
|---|---|
|`jdbc:sqlite:students.db`|Relative file path|
|`jdbc:sqlite:/home/user/data/students.db`|Absolute file path|
|`jdbc:sqlite::memory:`|In-memory database|

With a relative path, SQLite looks for the file relative to the application's working directory, not necessarily the location of your `.java` file.

---

## 4. Username and Password Configuration

For databases such as PostgreSQL, authentication credentials are commonly required.

```
String url = "jdbc:postgresql://localhost:5432/mydb";

String username = "postgres";
String password = "password";

Connection connection =
        DriverManager.getConnection(
                url,
                username,
                password
        );
```

The `DriverManager` class provides multiple overloaded `getConnection()` methods.

|Method|Purpose|
|---|---|
|`getConnection(url)`|Connect using URL and driver defaults|
|`getConnection(url, user, password)`|Connect with credentials|
|`getConnection(url, properties)`|Connect using a `Properties` object|

### What about SQLite?

SQLite doesn't normally require database usernames and passwords.

```
Connection connection =
        DriverManager.getConnection("jdbc:sqlite:students.db");
```

This is enough to establish a connection to an accessible SQLite database file.

---

## 5. Connection Properties

Java provides a class called `Properties` in the `java.util` package.

A `Properties` object stores configuration values as string key-value pairs.

For example:

```
import java.util.Properties;

Properties properties = new Properties();

properties.setProperty("user", "postgres");
properties.setProperty("password", "password");
```

We can provide this object to `DriverManager`:

```
Connection connection =
        DriverManager.getConnection(url, properties);
```

### Why use Properties?

Because instead of passing individual arguments, we can group connection settings into one object.

For example:

```
Properties properties = new Properties();

properties.setProperty("user", "postgres");
properties.setProperty("password", "password");
properties.setProperty("ApplicationName", "MyJavaApp");

Connection connection =
        DriverManager.getConnection(url, properties);
```

`ApplicationName` is a PostgreSQL JDBC driver-specific property, not a universal JDBC property.

**Important:** Supported connection properties depend on the JDBC driver. `Properties` itself doesn't validate whether a property is supported.

---

## 6. Configuring the Connection Object

After establishing a connection, we can configure its behavior.

```
Connection connection =
        DriverManager.getConnection(url);
```

The `Connection` interface provides several configuration methods.

|Method|Responsibility|
|---|---|
|`setAutoCommit(boolean)`|Enable or disable automatic commits|
|`setReadOnly(boolean)`|Request read-only connection behavior|
|`setTransactionIsolation(int)`|Configure transaction isolation|
|`setCatalog(String)`|Select a catalog, if supported|
|`setSchema(String)`|Select a schema, if supported|

Some options are not supported by every database driver.

### 6.1. Auto-Commit Configuration

By default, JDBC connections use auto-commit mode.

```
connection.setAutoCommit(true);
```

This means individual SQL statements are committed when they complete.

We can disable it:

```
connection.setAutoCommit(false);
```

Now, we explicitly control transaction completion:

```
connection.commit();
```

Or undo uncommitted changes:

```
connection.rollback();
```

For example:

```
connection.setAutoCommit(false);

try {
    // Execute database operations

    connection.commit();

} catch (SQLException e) {

    connection.rollback();
    throw e;
}
```

This is useful when several database operations must succeed or fail together.

### 6.2. Read-Only Configuration

JDBC defines:

```
connection.setReadOnly(true);
```

This communicates that the connection is intended for read-only work.

However, **read-only behavior is database- and driver-dependent**.

It is not a universal security mechanism and should not replace actual database or file permissions.

Some drivers require read-only configuration before executing statements, and SQLite offers its own database opening modes.

### 6.3. Transaction Isolation Configuration

JDBC defines transaction isolation constants.

For example:

```
connection.setTransactionIsolation(
        Connection.TRANSACTION_SERIALIZABLE
);
```

Transaction isolation determines how concurrent database transactions can interact.

JDBC defines standard levels:

|Isolation Level|Description|
|---|---|
|`READ_UNCOMMITTED`|Allows the weakest isolation|
|`READ_COMMITTED`|Prevents dirty reads|
|`REPEATABLE_READ`|Prevents dirty and non-repeatable reads|
|`SERIALIZABLE`|Strongest standard isolation level|

Not every database supports every level.

For SQLite specifically, transaction isolation and locking behavior differ from PostgreSQL, so you should not assume that changing this setting will produce identical behavior across databases.

---

## 7. SQLite-Specific JDBC Configuration

Now let's focus on SQLite.

The Xerial SQLite JDBC driver provides a class called:

```
org.sqlite.SQLiteConfig
```

`SQLiteConfig` helps us configure SQLite-specific behavior without manually executing every configuration SQL command.

For example:

```
import org.sqlite.SQLiteConfig;

SQLiteConfig config = new SQLiteConfig();
```

We can now configure several important settings.

### 7.1. Foreign Key Enforcement

SQLite supports foreign key constraints, but their enforcement should be enabled explicitly rather than relying on defaults.

Using `SQLiteConfig`:

```
config.enforceForeignKeys(true);
```

This is equivalent in intent to enabling:

```
PRAGMA foreign_keys = ON;
```

Foreign key enforcement prevents invalid references between related tables.

For example, it prevents inserting an order referencing a nonexistent customer when an appropriate foreign key constraint exists.

### 7.2. Busy Timeout

SQLite normally permits only one writer at a time.

If another connection is holding a conflicting lock, our operation may encounter a database-busy condition.

We can configure how long SQLite should wait for the lock to become available:

```
config.setBusyTimeout(5000);
```

This sets the busy timeout to 5,000 milliseconds, or five seconds.

It doesn't guarantee that the operation will succeed, but it gives SQLite time to retry when the database is busy.

The equivalent SQLite command is:

```
PRAGMA busy_timeout = 5000;
```

### 7.3. Journal Mode

SQLite uses journaling to support transactional database operations.

We can configure the journal mode:

```
config.setJournalMode(SQLiteConfig.JournalMode.WAL);
```

`WAL` stands for **Write-Ahead Logging**.

WAL mode can improve concurrency by allowing readers and a writer to operate concurrently in many situations.

However, SQLite still allows only one writer at a time.

WAL mode persists for a file-based database once successfully enabled, unlike many per-connection settings.

It is useful in appropriate workloads but isn't mandatory for every SQLite application.

---

## 8. Complete SQLite Configuration Example

Now let's combine our settings.

```
import org.sqlite.SQLiteConfig;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Main {

    public static void main(String[] args) {

        String url = "jdbc:sqlite:students.db";

        // SQLite-specific configuration
        SQLiteConfig config = new SQLiteConfig();

        config.enforceForeignKeys(true);
        config.setBusyTimeout(5000);
        config.setJournalMode(SQLiteConfig.JournalMode.WAL);

        try (Connection connection =
                     DriverManager.getConnection(
                             url,
                             config.toProperties()
                     )) {

            System.out.println("Connected!");

            System.out.println(
                    "Auto Commit: " + connection.getAutoCommit()
            );

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

### Understanding the code

First, we configure the database location:

```
String url = "jdbc:sqlite:students.db";
```

Then we create our SQLite configuration:

```
SQLiteConfig config = new SQLiteConfig();
```

Next, we configure the database behavior:

```
config.enforceForeignKeys(true);
config.setBusyTimeout(5000);
config.setJournalMode(SQLiteConfig.JournalMode.WAL);
```

Finally, we create the connection:

```
Connection connection =
        DriverManager.getConnection(
                url,
                config.toProperties()
        );
```

Notice `config.toProperties()`.

This converts the SQLite configuration into a standard Java `Properties` object.

`DriverManager` then passes those properties to the SQLite JDBC driver when establishing the connection.

---

## 9. Separating JDBC Configuration from Java Code

In a real application, we don't want to scatter database configuration throughout our source code.

We can separate it into a configuration file.

For example, our Maven project might look like this:

```
MyProject/
├── pom.xml
├── src/
│   └── main/
│       ├── java/
│       │   └── com/example/
│       │       └── Main.java
│       └── resources/
│           └── database.properties
└── students.db
```

### Step 1: Create database.properties

Inside `src/main/resources/database.properties`:

```
jdbc.url=jdbc:sqlite:students.db

jdbc.foreignKeys=true
jdbc.busyTimeout=5000
```

This file stores our configuration values.

For this example, we are not including WAL mode in the external configuration; the application can enable it separately when needed.

### Step 2: Load Properties in Java

Plain Java doesn't automatically load configuration files as Spring Boot does.

We must load them ourselves.

```
import org.sqlite.SQLiteConfig;

import java.io.InputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class Main {

    public static void main(String[] args) {

        Properties properties = new Properties();

        try (InputStream input =
                     Main.class.getResourceAsStream(
                             "/database.properties"
                     )) {

            if (input == null) {
                throw new IOException("Configuration file not found");
            }

            properties.load(input);

        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        String url = properties.getProperty("jdbc.url");

        SQLiteConfig config = new SQLiteConfig();

        config.enforceForeignKeys(
                Boolean.parseBoolean(
                        properties.getProperty("jdbc.foreignKeys")
                )
        );

        config.setBusyTimeout(
                Integer.parseInt(
                        properties.getProperty("jdbc.busyTimeout")
                )
        );

        try (Connection connection =
                     DriverManager.getConnection(
                             url,
                             config.toProperties()
                     )) {

            System.out.println("Database connection established.");

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

### How This Works

1. Java loads `database.properties` from the classpath.
    
2. The `Properties` class stores the configuration values.
    
3. We retrieve the JDBC URL.
    
4. We convert our application settings into SQLite driver configuration.
    
5. `DriverManager` establishes the connection.
    
6. The SQLite driver applies the supported settings.
    

For PostgreSQL, passwords and other secrets should normally come from environment variables or a secrets manager rather than a configuration file committed to Git.

---

## 10. What Happens in Spring Boot?

Spring Boot simplifies much of this configuration.

Instead of manually creating a connection using `DriverManager`, we usually configure a `DataSource`.

For PostgreSQL:

```
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
```

Spring Boot reads these properties and configures the connection infrastructure.

In a typical application, the flow becomes:

```
application.properties
        |
        v
Spring Boot Configuration
        |
        v
DataSource / Connection Pool
        |
        v
JDBC Driver
        |
        v
Database
```

One important distinction:

`**spring.datasource.***` **properties are Spring Boot configuration conventions, not properties defined by the JDBC API itself.**

A plain JDBC application does not automatically understand these properties.

Also, SQLite-specific settings typically need additional driver or `DataSource` configuration.

---

## 11. Common Configuration Mistakes

|Mistake|Explanation|
|---|---|
|Incorrect JDBC URL|Driver cannot locate or open the database|
|JDBC driver missing|`No suitable driver` error|
|Wrong relative database path|SQLite creates or opens a different database file|
|Forgetting foreign key configuration|Foreign key constraints may not be enforced|
|Disabling auto-commit without committing|Transaction changes may be rolled back when the connection closes|
|Assuming all JDBC drivers support the same options|Some settings are database-specific|
|Hardcoding production credentials|Creates security and maintenance risks|
|Reusing one connection indefinitely|Can cause resource management and concurrency problems|

---

## 12. The Whole Picture

|Configuration|Java / SQLite Mechanism|Purpose|
|---|---|---|
|JDBC Driver|Maven / Gradle dependency|Provide database-specific JDBC implementation|
|JDBC URL|`jdbc:sqlite:students.db`|Locate the database|
|Credentials|`getConnection(url, user, password)`|Authenticate where required|
|Driver properties|`Properties`|Supply connection options|
|SQLite configuration|`SQLiteConfig`|Configure SQLite-specific settings|
|Auto-commit|`setAutoCommit()`|Control automatic transaction commits|
|Read-only|`setReadOnly()`|Request read-only behavior|
|Transaction isolation|`setTransactionIsolation()`|Configure supported isolation behavior|
|Foreign keys|`enforceForeignKeys()`|Enforce relational constraints|
|Busy timeout|`setBusyTimeout()`|Wait for SQLite locks|
|Journal mode|`setJournalMode()`|Configure SQLite journaling|
|External configuration|`.properties` file|Separate application settings from code|

### Final Understanding

When configuring JDBC, we first determine **how Java reaches the database**, through the JDBC driver, JDBC URL, and connection properties.

After obtaining a `Connection`, we configure **how database operations behave**, such as transaction management and isolation. Database-specific drivers can also expose additional options; in SQLite, these include foreign key enforcement, busy timeouts, and journal mode.

The key distinction is that **JDBC defines the standard configuration interfaces, while the JDBC driver implements database-specific behavior**.





[[SQlite]]
[[Java]]