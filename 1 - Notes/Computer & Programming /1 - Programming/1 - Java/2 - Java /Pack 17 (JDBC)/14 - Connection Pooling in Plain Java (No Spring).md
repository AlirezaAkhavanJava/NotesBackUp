


The connection pool itself is the same concept from before — a set of ready-to-reuse database connections, now set up by hand since Spring Boot isn't around to auto-configure it from `application.properties` for you. In a plain Maven project, you add Hikari as a dependency, build the `HikariConfig`/`HikariDataSource` yourself in code, and manage its whole lifecycle yourself — including shutting it down when your app exits.

## 1. The Maven Dependency

You need Hikari itself, plus your JDBC driver (PostgreSQL in your case):

```xml
<dependencies>
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
</dependencies>
```

There's no Spring Boot starter doing this resolution for you — these are the only two JARs you need for pooling + PostgreSQL connectivity.

## 2. Building the Pool Yourself

Without Spring, there's no `@ConfigurationProperties` binding `spring.datasource.hikari.*` keys into an object for you. You build a `HikariConfig` object directly in code and set each property with its setter method:

```java
public class DataSourceProvider {

    private static final HikariDataSource dataSource;

    static {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://localhost:5432/trash");
        config.setUsername("ethan");
        config.setPassword("yourpassword");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(10);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setConnectionTimeout(30000);

        dataSource = new HikariDataSource(config);
    }

    public static DataSource getDataSource() {
        return dataSource;
    }
}
```

Each setter here maps 1:1 to the properties-file keys you already know (`setMaximumPoolSize` ↔ `maximum-pool-size`, and so on) — only the mechanism of setting them has changed, not their meaning.

Hikari is built so that a single `HikariDataSource` instance _is_ the pool — constructing it immediately starts opening and holding connections according to `minimum-idle`. You typically build it once, as a singleton, and share that one instance across your whole application, rather than constructing a new pool per use.

## 3. Borrowing and Returning a Connection

With Spring, you never call `getConnection()` yourself — a repository or `JdbcTemplate` does it for you behind the scenes. In plain Java, you call it directly, and you're responsible for returning it:

```java
public class UserRepository {

    public String findUsernameById(int id) throws SQLException {
        String sql = "SELECT username FROM users WHERE id = ?";

        try (Connection conn = DataSourceProvider.getDataSource().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getString("username") : null;
            }
        }
    }
}
```

The `try-with-resources` on `Connection` is what "returns" the connection to the pool. Calling `close()` on a pooled connection doesn't actually close the physical socket to the database — Hikari intercepts it and puts the connection back into the idle set instead. This is the whole trick that makes pooling transparent to ordinary JDBC code: you write `close()` like you always would, and Hikari quietly redefines what that means.

## 4. Shutting the Pool Down

Spring Boot closes the pool for you when the application context shuts down. In plain Java, nothing does that automatically — you have to call `close()` on the `HikariDataSource` yourself, usually from a shutdown hook, or Hikari's connections (and the background threads it runs to manage them) will just keep running until the JVM is killed:

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    ((HikariDataSource) DataSourceProvider.getDataSource()).close();
}));
```

That's the full lifecycle in plain Java: dependency → build the pool once as a singleton → borrow/return connections through ordinary JDBC `try-with-resources` → close the pool explicitly on shutdown. Everything about _why_ pool size matters relative to how many threads are hitting the database at once — which you already have from the Tomcat/Hikari sizing discussion — applies exactly the same here; the only difference is that in plain Java, you're also the one deciding how many threads are making those concurrent calls in the first place, since there's no servlet container assigning that for you.


[[Java]]