

**Date**: 2025-08-24  
**Tags**: [[Java]] 

## What is JDBC?

JDBC (Java Database Connectivity) is a Java API for connecting and interacting with relational databases (e.g., MySQL, PostgreSQL, Oracle). It allows Java applications to execute SQL queries, retrieve data, and update databases in a standard way, regardless of the database vendor.

## Key Concepts

- **Driver**: A vendor-specific library (e.g., `mysql-connector-java`) that enables JDBC to communicate with a database.
- **Connection**: A session between your Java application and the database.
- **Statement**: Sends SQL commands to the database (e.g., `SELECT`, `INSERT`).
- **PreparedStatement**: A precompiled SQL statement for better performance and security (prevents SQL injection).
- **ResultSet**: A table of data returned from a query, allowing you to read results row by row.
- **SQLException**: An exception thrown when database operations fail.

## Main Operations

- **Connect to Database**: Establish a connection using a URL, username, and password.
- **Execute Queries**:
    - Read data with `SELECT` (returns `ResultSet`).
    - Modify data with `INSERT`, `UPDATE`, or `DELETE` (returns affected rows).
- **Process Results**: Iterate over `ResultSet` to retrieve data.
- **Close Resources**: Close `Connection`, `Statement`, and `ResultSet` to free resources.

## Key JDBC Classes and Interfaces

- **DriverManager**: Manages database drivers and creates connections.
- **Connection**: Represents a database session (`DriverManager.getConnection()`).
- **Statement**: Executes static SQL queries (`Connection.createStatement()`).
- **PreparedStatement**: Executes parameterized SQL queries (`Connection.prepareStatement()`).
- **ResultSet**: Holds query results (`Statement.executeQuery()`).
- **SQLException**: Handles database errors.

## Common Issues

- **Driver Not Found**: Missing database driver causes `ClassNotFoundException`.
    - **Fix**: Add the driver dependency (e.g., MySQL Connector/J via Maven).
- **SQL Injection**: Using `Statement` with user input can allow malicious SQL.
    - **Fix**: Use `PreparedStatement` with parameterized queries.
- **Resource Leaks**: Not closing `Connection`, `Statement`, or `ResultSet` can exhaust resources.
    - **Fix**: Use try-with-resources to auto-close.
- **Connection Errors**: Wrong URL, credentials, or database downtime cause `SQLException`.
    - **Fix**: Verify connection details and handle exceptions.

## Best Practices

1. Use `PreparedStatement` for queries with user input to prevent SQL injection.
2. Close resources using try-with-resources to avoid leaks.
3. Handle `SQLException` to manage database errors gracefully.
4. Use connection pooling (e.g., HikariCP) in production for better performance.
5. Add the database driver dependency (e.g., `mysql-connector-java`) to your project.
6. Test queries in a database tool (e.g., MySQL Workbench) before coding.

## Example Code

```java
import java.sql.*;

public class JDBCExample {
    // Database URL, username, and password
    private static final String URL = "jdbc:mysql://localhost:3306/mydb";
    private static final String USER = "root";
    private static final String PASS = "password";

    public static void main(String[] args) {
        // Load driver (optional in modern JDBC)
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver not found: " + e.getMessage());
            return;
        }

        // Connect and query database
        try (Connection conn = DriverManager.getConnection(URL, USER, PASS);
             PreparedStatement stmt = conn.prepareStatement("SELECT id, name FROM users WHERE age > ?");
        ) {
            // Set parameter to prevent SQL injection
            stmt.setInt(1, 25);

            // Execute query and process results
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    int id = rs.getInt("id");
                    String name = rs.getString("name");
                    System.out.println("ID: " + id + ", Name: " + name);
                }
            }
        } catch (SQLException e) {
            System.out.println("Database error: " + e.getMessage());
        }
    }
}
```

**Note**: Add the MySQL driver dependency to your project (e.g., `mysql:mysql-connector-java` for Maven). Replace `mydb`, `root`, and `password` with your database details. Ensure the database is running and the `users` table exists.

## Summary

JDBC is Java’s standard API for working with relational databases, enabling SQL queries and data manipulation. Key components include `Connection`, `PreparedStatement`, and `ResultSet`. Use `PreparedStatement` for secure queries, try-with-resources to manage resources, and connection pooling for performance. By handling errors and following best practices, developers can build reliable database-driven Java applications.