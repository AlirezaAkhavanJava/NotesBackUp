

You've already seen the pieces of this in parts, so here it is pulled together as one straight-through guide: from an empty Maven project to actually running queries against a pooled connection.

## 1. Add the Dependency

```xml
<dependency>
    <groupId>com.zaxxer</groupId>
    <artifactId>HikariCP</artifactId>
    <version>5.1.0</version>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.7.3</version>
</dependency>
```

Hikari itself doesn't know how to talk to PostgreSQL — it just manages a pool of `Connection` objects. The actual driver that knows the PostgreSQL wire protocol is `org.postgresql:postgresql`. Hikari discovers it automatically via JDBC's `ServiceLoader` mechanism, so you never write `Class.forName(...)` yourself — just having the driver on the classpath is enough.

## 2. Configure and Create the Pool

Everything about a Hikari pool starts from a `HikariConfig` object. You can fill it in two ways.

**Directly in code:**

```java
HikariConfig config = new HikariConfig();
config.setJdbcUrl("jdbc:postgresql://localhost:5432/trash");
config.setUsername("ethan");
config.setPassword("yourpassword");
config.setMaximumPoolSize(10);
```

**From a `.properties` file**, if you don't want connection details hardcoded:

```properties
# hikari.properties
jdbcUrl=jdbc:postgresql://localhost:5432/trash
username=ethan
password=yourpassword
maximumPoolSize=10
```

```java
Properties props = new Properties();
try (InputStream input = DataSourceProvider.class.getClassLoader()
        .getResourceAsStream("hikari.properties")) {
    props.load(input);
}
HikariConfig config = new HikariConfig(props);
```

This second form is useful because `HikariConfig`'s constructor will read any key matching a setter name (`maximumPoolSize` → `setMaximumPoolSize`), so the properties file and the code-based config aren't really two different systems — the file is just populating the same object.

Either way, you then wrap the config in a `HikariDataSource` — this is the object that _is_ the pool, and the one you'll keep around for the life of your app:

```java
HikariDataSource dataSource = new HikariDataSource(config);
```

Constructing it does real work immediately: Hikari opens connections up front (according to `minimumIdle`) before this line even returns. Because of that cost, you create exactly one `HikariDataSource` and reuse it everywhere — never construct a new one per request or per query.

## 3. Get a Connection, Run a Query, Give It Back

Once you have the pool, using it looks exactly like ordinary JDBC — because it is ordinary JDBC. The only difference from a non-pooled setup is where the `Connection` came from.

```java
String sql = "SELECT username FROM users WHERE id = ?";

try (Connection conn = dataSource.getConnection();
     PreparedStatement stmt = conn.prepareStatement(sql)) {

    stmt.setInt(1, 42);

    try (ResultSet rs = stmt.executeQuery()) {
        if (rs.next()) {
            System.out.println(rs.getString("username"));
        }
    }
}
```

`dataSource.getConnection()` doesn't open a new physical connection — it hands you one that's already sitting open in the pool. When the `try-with-resources` block ends and `conn.close()` runs, Hikari intercepts that call: instead of tearing the connection down, it just marks it idle and returns it to the pool for the next caller. This is the core trick of how pooling stays invisible to normal JDBC code — you write `close()` exactly as you always would.

For an `INSERT`/`UPDATE`, the pattern is identical, you just call `executeUpdate()` instead:

```java
String sql = "INSERT INTO users (username) VALUES (?)";

try (Connection conn = dataSource.getConnection();
     PreparedStatement stmt = conn.prepareStatement(sql)) {

    stmt.setString(1, "newUser");
    stmt.executeUpdate();
}
```

## 4. Handling Failures

If every connection is checked out and none frees up in time, `getConnection()` throws `SQLException` (specifically a `SQLTransientConnectionException` at runtime) once `connectionTimeout` elapses — so this call always needs to be inside a `try` or declared `throws SQLException`, same as any other JDBC call. There's nothing Hikari-specific to catch differently; it surfaces through the same `SQLException` hierarchy the rest of JDBC uses.

## 5. Shutting the Pool Down

Since there's no framework managing the `HikariDataSource`'s lifecycle for you, you close it yourself when the application is done — typically via a shutdown hook so it still runs even if the app exits unexpectedly:

```java
Runtime.getRuntime().addShutdownHook(new Thread(dataSource::close));
```

Closing it closes every physical connection it's holding and stops Hikari's background housekeeping threads (the ones enforcing `maxLifetime` and `idleTimeout`). Skipping this just leaves those threads and sockets running until the JVM itself dies.

## Putting It Together

A minimal, complete program:

```java
public class Main {
    public static void main(String[] args) throws SQLException {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://localhost:5432/trash");
        config.setUsername("ethan");
        config.setPassword("yourpassword");
        config.setMaximumPoolSize(10);

        try (HikariDataSource dataSource = new HikariDataSource(config)) {
            String sql = "SELECT username FROM users WHERE id = ?";
            try (Connection conn = dataSource.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {

                stmt.setInt(1, 1);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        System.out.println(rs.getString("username"));
                    }
                }
            }
        }
    }
}
```

Notice `HikariDataSource` itself is also wrapped in `try-with-resources` here — it implements `Closeable`, so for a short-lived program this is a cleaner way to guarantee shutdown than a manual shutdown hook. For a long-running server-style app, the shutdown hook from step 5 is the right tool instead, since you don't want the pool closing the moment one method returns.


[[Java]]