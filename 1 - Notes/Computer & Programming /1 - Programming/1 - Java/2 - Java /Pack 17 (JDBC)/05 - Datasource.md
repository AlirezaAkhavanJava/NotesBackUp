

# JDBC `DataSource`

A `DataSource` is how your Java code asks for a database connection. You configure it once, in one place: the URL, the user, the password, and the pool settings. After that, the rest of your code only says "give me a connection" and never needs to know which database it is talking to.

The main benefit is that you stop hard-coding connection details across your code. A `DataSource` also lets you add connection pooling, which makes your app much faster under load. Spring Boot, Hibernate, and almost every Java framework expect a `DataSource`, so this is the piece everything else plugs into.

---

## The problem it solves

The old way to connect is `DriverManager`:

```java
Connection c = DriverManager.getConnection(
    "jdbc:postgresql://localhost:5432/shop", "app", "secret");
```

It works, but it has problems:

- **The URL and password end up in your code.** Change the database and you edit code.
- **Every call opens a brand-new connection.** For PostgreSQL that means a TCP handshake, authentication, and a new server process. That can take tens of milliseconds, and it happens on every request.
- **There is no place to add pooling, monitoring, or timeouts.**

A `DataSource` fixes all three, because it is an object you configure once and pass around.

||`DriverManager`|`DataSource`|
|---|---|---|
|Config location|Scattered in code|One place|
|Connection reuse|No, new each time|Yes, if pooled|
|Swap database|Edit code|Change config|
|Framework support|Poor|Standard|

---

## What it actually is

`javax.sql.DataSource` is a small **interface**. A vendor or library implements it. The two methods you use are:

```java
Connection getConnection() throws SQLException;
Connection getConnection(String user, String password) throws SQLException;
```

That is almost the whole API. Your code depends on the interface, and the implementation behind it can change without touching your code.

There are two kinds of implementation:

1. **Basic**: each `getConnection()` opens a real new connection. This is the driver's own `DataSource`.
2. **Pooled**: it keeps a set of open connections and hands them out. This comes from a library such as HikariCP.

---

## PostgreSQL: the basic DataSource

Dependency (use the latest versions):

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
</dependency>
```

```java
import org.postgresql.ds.PGSimpleDataSource;
import javax.sql.DataSource;
import java.sql.*;

public class PgDemo {
    public static void main(String[] args) throws SQLException {
        PGSimpleDataSource pg = new PGSimpleDataSource();
        pg.setURL("jdbc:postgresql://localhost:5432/shop");
        pg.setUser("app");
        pg.setPassword(System.getenv("DB_PASSWORD"));

        DataSource ds = pg;

        try (Connection con = ds.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT id, name FROM products WHERE price > ?")) {
            ps.setInt(1, 10);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    System.out.println(rs.getInt("id") + " " + rs.getString("name"));
                }
            }
        }
    }
}
```

Line by line:

- `new PGSimpleDataSource()` creates the PostgreSQL driver's own implementation. "Simple" means no pooling.
- `setURL(...)` sets the full JDBC URL: host, port, and database name.
- `setUser` and `setPassword` set the credentials. Read the password from an environment variable, not from source code.
- `DataSource ds = pg;` is the important line. From here on, your code only knows it has a `DataSource`.
- `try (Connection con = ds.getConnection(); ...)` is a try-with-resources block. It guarantees the connection closes, even when an exception is thrown.
- `PreparedStatement` with a `?` placeholder protects you from SQL injection. Never build SQL by joining strings.

---

## SQLite: the basic DataSource

```xml
<dependency>
  <groupId>org.xerial</groupId>
  <artifactId>sqlite-jdbc</artifactId>
</dependency>
```

```java
import org.sqlite.SQLiteConfig;
import org.sqlite.SQLiteDataSource;

SQLiteConfig config = new SQLiteConfig();
config.enforceForeignKeys(true);                        // SQLite ignores FKs by default
config.setJournalMode(SQLiteConfig.JournalMode.WAL);    // better read/write concurrency
config.setBusyTimeout(5000);                            // wait up to 5s if the db is locked

SQLiteDataSource ds = new SQLiteDataSource(config);
ds.setUrl("jdbc:sqlite:app.db");
```

Line by line:

- `SQLiteConfig` holds **PRAGMA settings**. A PRAGMA is a SQLite command that changes how the database behaves.
- `enforceForeignKeys(true)` matters because SQLite does **not** check foreign keys unless you turn this on, and the setting is per connection. Putting it in the `DataSource` config applies it to every connection.
- **WAL** (write-ahead logging) lets readers keep reading while one writer writes.
- `setBusyTimeout(5000)` makes a connection wait instead of failing instantly when another connection holds the write lock. Without it you will see `SQLITE_BUSY` errors.
- `jdbc:sqlite:app.db` is a file path, so there is no server, host, or password.

Usage is identical to the PostgreSQL example: `ds.getConnection()`. This is the benefit of `DataSource`.

---

## Connection pooling

Opening a connection is slow, so a **pool** opens a few connections once and lends them out.

|Step|Without pool|With pool|
|---|---|---|
|Request arrives|Open new connection (slow)|Borrow an open one (fast)|
|Query runs|Same|Same|
|`close()` called|Real connection closed|Connection returned to pool|

The last row is the one that surprises people. With a pool, `con.close()` does not close the connection. It gives it back, which is why you still close in a try-with-resources block.

The standard pool is **HikariCP**:

```xml
<dependency>
  <groupId>com.zaxxer</groupId>
  <artifactId>HikariCP</artifactId>
</dependency>
```

### PostgreSQL with Hikari

```java
HikariConfig cfg = new HikariConfig();
cfg.setJdbcUrl("jdbc:postgresql://localhost:5432/shop");
cfg.setUsername("app");
cfg.setPassword(System.getenv("DB_PASSWORD"));
cfg.setMaximumPoolSize(10);
cfg.setMinimumIdle(2);
cfg.setConnectionTimeout(30_000);

HikariDataSource ds = new HikariDataSource(cfg);
```

- `setMaximumPoolSize(10)` means at most 10 connections exist. If an 11th thread asks, it waits.
- `setMinimumIdle(2)` keeps at least 2 spare connections ready.
- `setConnectionTimeout(30_000)` means a thread waits up to 30 seconds for a free connection, then gets an exception.

Keep the pool small. PostgreSQL has a limit on connections, and more connections do not mean more speed. A common starting point is a few times your CPU core count.

### SQLite with Hikari

SQLite allows **only one writer at a time**, so a big pool does not help. Reuse the `SQLiteDataSource` from above:

```java
HikariConfig cfg = new HikariConfig();
cfg.setDataSource(ds);          // the SQLiteDataSource with your PRAGMAs
cfg.setMaximumPoolSize(1);      // simplest and safest for writes

HikariDataSource pool = new HikariDataSource(cfg);
```

`setDataSource(ds)` wraps your existing `DataSource` inside the pool, so your PRAGMAs still apply to every connection. With WAL you can try 3 to 5 connections for read-heavy apps, but start with 1. Also remember that `jdbc:sqlite::memory:` gives **each connection its own separate empty database**, which is a classic trap with pools.

---

## Transactions

A connection starts in **auto-commit** mode, so every statement commits immediately. For several statements that must succeed together, turn it off:

```java
try (Connection con = ds.getConnection()) {
    con.setAutoCommit(false);
    try {
        // debit one account, credit another
        con.commit();
    } catch (SQLException e) {
        con.rollback();
        throw e;
    }
}
```

`commit()` makes the changes permanent, and `rollback()` undoes everything since the last commit. Hikari resets the auto-commit setting when the connection returns to the pool.

---

## Spring Boot

You rarely build the `DataSource` by hand. Spring Boot reads your properties and creates a Hikari-backed `DataSource` for you.

PostgreSQL:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/shop
spring.datasource.username=app
spring.datasource.password=${DB_PASSWORD}
spring.datasource.hikari.maximum-pool-size=10
```

SQLite:

```properties
spring.datasource.url=jdbc:sqlite:app.db
spring.datasource.driver-class-name=org.sqlite.JDBC
spring.datasource.hikari.maximum-pool-size=1
```

Then inject it:

```java
@Repository
public class ProductRepo {
    private final JdbcTemplate jdbc;
    public ProductRepo(DataSource ds) { this.jdbc = new JdbcTemplate(ds); }
}
```

Spring manages opening and closing connections for you. If you use JPA or Hibernate with SQLite, you also need a SQLite dialect from the `hibernate-community-dialects` library.

---

## Common mistakes

- **Creating a new `DataSource` per request.** Build it **once**, at startup, and share it. A pool created per request defeats the point.
- **Not closing connections.** In a pool this causes a _leak_: the pool runs out and every thread waits. Always use try-with-resources.
- **Pool too big.** More connections can make PostgreSQL slower, not faster.
- **Forgetting SQLite's foreign key PRAGMA.**
- **Hard-coding passwords.** Use environment variables or a secrets manager.

---

## Related concepts, briefly

- **`DriverManager`**: the older way to get a connection. It is fine for tiny scripts, and `DataSource` is preferred for everything else.
- **JNDI**: in application servers like Tomcat, the server creates the `DataSource` and your code looks it up by name (`java:comp/env/jdbc/shop`). Spring Boot apps mostly skip this.
- **`ConnectionPoolDataSource` / `XADataSource`**: special `DataSource` variants for driver-level pooling and distributed transactions. You will rarely touch them directly.

---

## Quick recap

1. `DataSource` is an interface that gives you `Connection` objects.
2. Configure it once, share it everywhere, and use a pool in real apps.
3. PostgreSQL uses `PGSimpleDataSource` and a bigger pool. SQLite uses `SQLiteDataSource`, PRAGMAs, and a tiny pool.
4. Always close what you open.




[[Java]]