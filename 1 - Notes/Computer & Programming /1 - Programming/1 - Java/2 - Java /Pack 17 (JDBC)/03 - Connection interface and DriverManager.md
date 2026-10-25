`DriverManager` is a built-in Java class (`java.sql.DriverManager`) responsible for managing registered JDBC drivers and obtaining database connections. When we call `DriverManager.getConnection()`, it finds a suitable JDBC driver based on the database URL, asks that driver to establish a connection, and returns a `Connection` object.

`Connection` is a JDBC interface (`java.sql.Connection`) that represents an active connection to a database. Once a connection is established, we use it to create SQL statements, execute database operations, manage transactions, and eventually close the connection. The actual object is implemented by the JDBC driver, while Java provides the common `Connection` interface.

## 1. The Problem They Solve

We need two separate responsibilities when connecting Java to a database:

|Component|Responsibility|
|---|---|
|`DriverManager`|Find a suitable driver and obtain a connection|
|`Connection`|Represent and manage the established database connection|

Think of their relationship like this:

```
          Java Application
                  |
                  v
   DriverManager.getConnection()
                  |
                  v
        SQLite JDBC Driver
                  |
                  v
      Creates Connection Object
                  |
                  v
         Connection Interface
                  |
          +-------+-------+
          |       |       |
          v       v       v
       SQL     Transactions Close
```

## 2. DriverManager Class

`DriverManager` belongs to the `java.sql` package.

```
import java.sql.DriverManager;
```

The most important method is:

```
DriverManager.getConnection(url);
```

For example, with SQLite:

```
String url = "jdbc:sqlite:students.db";

Connection connection = DriverManager.getConnection(url);
```

Internally, Java follows this process:

1. `DriverManager` receives the JDBC URL.
    
2. It searches its registered drivers for a suitable one.
    
3. The SQLite JDBC driver recognizes the `jdbc:sqlite:` URL.
    
4. The driver establishes the connection.
    
5. A `Connection` implementation is returned.
    

Important: `DriverManager` is not itself a JDBC driver. It delegates connection creation to a registered driver.

## 3. Connection Interface

`Connection` also belongs to the `java.sql` package.

```
import java.sql.Connection;
```

Because it's an interface, we cannot instantiate it directly:

```
Connection connection = new Connection(); // Invalid!
```

Instead:

```
Connection connection =
        DriverManager.getConnection("jdbc:sqlite:students.db");
```

Here, something important happens:

- The variable `connection` has the interface type `Connection`.
    
- The actual object is created by the SQLite JDBC driver.
    
- The object implements the methods defined by the `Connection` interface.
    

This is a practical example of polymorphism in Java.

### Important Connection methods

|Method|Purpose|
|---|---|
|`createStatement()`|Create a SQL statement|
|`prepareStatement(sql)`|Create a parameterized SQL statement|
|`setAutoCommit(false)`|Disable automatic transaction commits|
|`commit()`|Commit a transaction|
|`rollback()`|Roll back a transaction|
|`getMetaData()`|Retrieve database and driver metadata|
|`isClosed()`|Check whether the connection is closed|
|`close()`|Close the logical connection and release associated resources|

## 4. Practical Example With SQLite

```
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Main {

    public static void main(String[] args) {

        String url = "jdbc:sqlite:students.db";

        try (Connection connection =
                     DriverManager.getConnection(url)) {

            // Create a table
            try (Statement statement = connection.createStatement()) {
                statement.executeUpdate("""
                    CREATE TABLE IF NOT EXISTS students (
                        id INTEGER PRIMARY KEY,
                        name TEXT NOT NULL
                    )
                    """);
            }

            // Insert a student
            String sql = "INSERT INTO students (name) VALUES (?)";

            try (PreparedStatement statement =
                         connection.prepareStatement(sql)) {

                statement.setString(1, "Alireza");
                statement.executeUpdate();
            }

            // Retrieve students
            try (Statement statement = connection.createStatement();
                 ResultSet results = statement.executeQuery(
                         "SELECT id, name FROM students")) {

                while (results.next()) {
                    System.out.println(results.getString("name"));
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

Notice the separation of responsibilities.

`DriverManager.getConnection()` is responsible for obtaining the connection. Once we have the `Connection` object, we use its methods to create statements and interact with the database. The try-with-resources blocks automatically close the JDBC resources.

## 5. Why Do We Need a Connection Interface?

Imagine having three databases:

- PostgreSQL
    
- SQLite
    
- MySQL
    

Each has its own JDBC driver and database-specific implementation.

However, all three can provide objects implementing the same JDBC `Connection` interface.

```
Connection sqliteConnection =
        DriverManager.getConnection(
                "jdbc:sqlite:students.db"
        );

Connection postgresConnection =
        DriverManager.getConnection(
                "jdbc:postgresql://localhost:5432/mydb",
                "postgres",
                "password"
        );
```

Both variables have the type `Connection`, even though their implementations come from different JDBC drivers.

This is possible because JDBC defines a common contract that database drivers must implement.

## 6. The Whole Picture

|Question|Answer|
|---|---|
|Is `DriverManager` a class or interface?|Class|
|Is `Connection` a class or interface?|Interface|
|Who creates the actual connection implementation?|JDBC driver|
|Who finds the appropriate driver?|DriverManager|
|Who defines the database connection operations?|Connection interface|
|Who executes SQL using the connection?|Statement and PreparedStatement|
|Can we create a Connection with `new Connection()`?|No|
|Can one application have multiple connections?|Yes|

Final understanding: `DriverManager` helps your application obtain a database connection, while `Connection` defines what you can do with that established connection. The JDBC driver sits behind both concepts, providing the database-specific implementation. This is a real-world example of Java interfaces, abstraction, and polymorphism working together.




[[Java]]