Date : 2025-09-13


HikariCP is basically the **speed demon of JDBC connection pools**. Here’s the full breakdown:

---

### **1. What is HikariCP?**

HikariCP is a **lightweight, high-performance JDBC connection pool**.

- It manages database connections efficiently so your application **doesn’t waste time creating new connections** every time you query the database.
    
- Think of it as a **supercharged connection manager**: it keeps a pool of ready-to-use connections, hands them out fast, and takes them back efficiently.
    

---

### **2. Why HikariCP?**

Compared to other pools like `C3P0` or `DBCP`, HikariCP is:

- **Extremely fast** – minimal overhead.
    
- **Reliable** – fewer bugs, low memory footprint.
    
- **Simple to configure** – works out-of-the-box with sensible defaults.
    

---

### **3. How it Works**

1. When your app starts, HikariCP creates a **pool of database connections**.
    
2. When your code asks for a connection (`DataSource.getConnection()`), HikariCP **gives an idle connection** from the pool instead of opening a new one.
    
3. When done, you call `connection.close()`, but HikariCP **doesn’t actually close it**; it **returns it to the pool**.
    
4. It manages **timeouts, leaks, and idle connections** efficiently under the hood.
    

---

### **4. Basic Components**

- **HikariDataSource** – The main class. Acts like a DataSource and manages the pool.
    
- **HikariConfig** – Optional: configure pool size, timeouts, leak detection, etc.
    

**Example:**

```java
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;

public class HikariExample {
    public static void main(String[] args) throws SQLException {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:h2:./myDB");  // DB URL
        config.setUsername("sa");
        config.setPassword("");
        config.setMaximumPoolSize(10);        // max 10 connections
        config.setConnectionTimeout(30000);   // 30 seconds timeout

        HikariDataSource ds = new HikariDataSource(config);

        // Get a connection
        try (Connection conn = ds.getConnection()) {
            System.out.println("Connection is valid: " + conn.isValid(2));
        }

        ds.close(); // close pool when app shuts down
    }
}
```

---

### **5. Key Config Options**

|Option|Meaning|
|---|---|
|`maximumPoolSize`|Max number of connections in the pool|
|`minimumIdle`|Minimum idle connections to maintain|
|`connectionTimeout`|Max time to wait for a connection|
|`idleTimeout`|Max time an idle connection can sit in the pool|
|`leakDetectionThreshold`|Warn if a connection is not returned in time|
|`validationTimeout`|Max time to check if a connection is valid|

---

### **6. Best Practices**

- Don’t set `maximumPoolSize` too high; match your DB capacity.
    
- Always **use try-with-resources** to release connections.
    
- Enable **leak detection** in dev mode if you suspect connections aren’t closed properly.
    

---
![[ChatGPT Image Sep 13, 2025, 02_13_00 AM.png]]

# HikariCP Overview

HikariCP is a high-performance, lightweight JDBC connection pooling library for Java applications. It is designed to be fast, reliable, and simple to configure, making it a popular choice for managing database connections in enterprise applications. Below is an overview of HikariCP, its key classes, and their important methods.

## What is HikariCP?

HikariCP (meaning "light" in Japanese) is a JDBC connection pool that optimizes database connection management. It provides low-latency, high-throughput connection pooling with minimal overhead, outperforming many other connection pooling libraries like Apache DBCP or Tomcat JDBC. Its key features include:

- **High Performance**: Optimized for low-latency and high concurrency.
- **Small Footprint**: Minimal codebase for better reliability and maintenance.
- **Robust Configuration**: Extensive configuration options for tuning connection pool behavior.
- **Leak Detection**: Built-in support for detecting connection leaks.

HikariCP is commonly used in frameworks like Spring Boot, Hibernate, and other Java-based applications requiring efficient database connectivity.

## Key Classes in HikariCP

HikariCP's core functionality revolves around a few key classes. Below are the primary classes and their roles:

### 1. `HikariDataSource`

The main entry point for HikariCP, `HikariDataSource` extends `javax.sql.DataSource` and is responsible for managing the connection pool and providing connections to the application.

- **Key Methods**:
    
    - `getConnection()`: Retrieves a database connection from the pool. Returns a `java.sql.Connection` object.
        
        ```java
        Connection conn = dataSource.getConnection();
        ```
        
    - `close()`: Shuts down the connection pool, closing all connections and releasing resources.
        
        ```java
        dataSource.close();
        ```
        
    - `setMaximumPoolSize(int)`: Sets the maximum number of connections in the pool.
        
        ```java
        dataSource.setMaximumPoolSize(20);
        ```
        
    - `setMinimumIdle(int)`: Sets the minimum number of idle connections in the pool.
        
        ```java
        dataSource.setMinimumIdle(5);
        ```
        
    - `setConnectionTimeout(long)`: Sets the maximum time (in milliseconds) to wait for a connection from the pool.
        
        ```java
        dataSource.setConnectionTimeout(30000); // 30 seconds
        ```
        
    - `setDataSourceProperties(Properties)`: Configures additional properties for the underlying database driver.
        
        ```java
        Properties props = new Properties();
        props.setProperty("useSSL", "false");
        dataSource.setDataSourceProperties(props);
        ```
        
- **Usage Example**:
    
    ```java
    HikariDataSource dataSource = new HikariDataSource();
    dataSource.setJdbcUrl("jdbc:mysql://localhost:3306/mydb");
    dataSource.setUsername("user");
    dataSource.setPassword("password");
    dataSource.setMaximumPoolSize(10);
    Connection conn = dataSource.getConnection();
    // Use connection
    conn.close();
    ```
    

### 2. `HikariConfig`

The `HikariConfig` class is used to configure the connection pool before creating a `HikariDataSource`. It provides a programmatic way to set up pool properties.

- **Key Methods**:
    
    - `setJdbcUrl(String)`: Sets the JDBC URL for the database.
        
        ```java
        config.setJdbcUrl("jdbc:postgresql://localhost:5432/mydb");
        ```
        
    - `setUsername(String)`: Sets the database username.
        
        ```java
        config.setUsername("user");
        ```
        
    - `setPassword(String)`: Sets the database password.
        
        ```java
        config.setPassword("password");
        ```
        
    - `setPoolName(String)`: Sets a name for the connection pool (useful for monitoring).
        
        ```java
        config.setPoolName("MyHikariPool");
        ```
        
    - `setLeakDetectionThreshold(long)`: Sets the threshold (in milliseconds) for detecting connection leaks.
        
        ```java
        config.setLeakDetectionThresholdburgo
        ```
        
    - `addDataSourceProperty(String, String)`: Adds a custom property for the JDBC driver.
        
        ```java
        config.addDataSourceProperty("cachePrepStmts", "true");
        ```
        
- **Usage Example**:
    
    ```java
    HikariConfig config = new HikariConfig();
    config.setJdbcUrl("jdbc:mysql://localhost:3306/mydb");
    config.setUsername("user");
    config.setPassword("password");
    config.setMaximumPoolSize(10);
    HikariDataSource dataSource = new HikariDataSource(config);
    ```
    

### 3. `HikariPoolMXBean`

This is a JMX (Java Management Extensions) interface for monitoring and managing the HikariCP connection pool at runtime. It provides insights into pool statistics and performance.

- **Key Methods**:
    
    - `getActiveConnections()`: Returns the number of active connections in use.
        
        ```java
        int active = poolMXBean.getActiveConnections();
        ```
        
    - `getIdleConnections()`: Returns the number of idle connections in the pool.
        
        ```java
        int idle = poolMXBean.getIdleConnections();
        ```
        
    - `getTotalConnections()`: Returns the total number of connections (active + idle).
        
        ```java
        int total = poolMXBean.getTotalConnections();
        ```
        
    - `softEvictConnections()`: Evicts idle connections from the pool gracefully.
        
        ```java
        poolMXBean.softEvictConnections();
        ```
        
- **Usage Example**:
    
    ```java
    HikariPoolMXBean poolMXBean = dataSource.getHikariPoolMXBean();
    System.out.println("Active Connections: " + poolMXBean.getActiveConnections());
    ```
    

## Common Configuration Properties

HikariCP supports a wide range of configuration properties that can be set via `HikariConfig` or a properties file (`hikari.properties`). Some commonly used properties include:

- `jdbcUrl`: The database URL (e.g., `jdbc:mysql://localhost:3306/mydb`).
- `username` and `password`: Database credentials.
- `maximumPoolSize`: Maximum number of connections in the pool (default: 10).
- `minimumIdle`: Minimum number of idle connections (default: same as `maximumPoolSize`).
- `connectionTimeout`: Maximum wait time for a connection (default: 30 seconds).
- `idleTimeout`: Time a connection can remain idle before being closed (default: 10 minutes).
- `maxLifetime`: Maximum lifetime of a connection in the pool (default: 30 minutes).
- `leakDetectionThreshold`: Time threshold for detecting connection leaks (default: 0, disabled).

## Example Configuration File (`hikari.properties`)

```java
dataSourceClassName=com.mysql.cj.jdbc.MysqlDataSource  
dataSource.user=user  
dataSource.password=password  
dataSource.databaseName=mydb  
dataSource.serverName=localhost  
poolName=MyHikariPool  
maximumPoolSize=10  
minimumIdle=5  
connectionTimeout=30000  
idleTimeout=600000  
maxLifetime=1800000  
leakDetectionThreshold=60000
```



##### *Tags : [[18 - JDBC 🍩]]