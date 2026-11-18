

JDBC (Java Database Connectivity) is the API that lets a Java program talk to a database without knowing the database's internal wire protocol. To actually do anything with a database — a query, an update — you first need a `Connection` object, which represents one live session to the database. Getting that `Connection` is step one of all JDBC work, and there are two standard ways to do it.

### Way 1 — `DriverManager`

This is the original, bare-bones way JDBC gives you a connection. You hand it a JDBC URL, a username, and a password, and it hands back a `Connection`.

```java
String url = "jdbc:postgresql://localhost:5432/trash";
Connection conn = DriverManager.getConnection(url, "ethan", "mypassword");
```

Here's what actually happens underneath that one line. At startup, every JDBC driver you have on your classpath (e.g. the PostgreSQL driver, the SQLite driver) registers itself with `DriverManager` by calling `DriverManager.registerDriver(...)`. This usually happens automatically via a file inside the driver's jar (`META-INF/services/java.sql.Driver`), so you never call `registerDriver` yourself.

When you call `DriverManager.getConnection(url, ...)`, `DriverManager` loops through every registered `Driver` and asks each one, "can you handle this URL?" The driver checks the URL's prefix (`jdbc:postgresql:` vs `jdbc:sqlite:`) and says yes or no. The first driver that says yes creates and returns the actual `Connection`.

That's the whole trick: your code never says `new PostgresConnection(...)`. It just says "give me a connection for this URL," and the right driver is found and used for you, without your code knowing which driver class exists.

**Why this way is limited:** every call to `DriverManager.getConnection(...)` opens a brand-new physical connection to the database and that connection's lifecycle is entirely in your hands — you must close it, there's no reuse, and opening a connection is a genuinely expensive operation (TCP handshake, auth, etc). Fine for a quick script, bad for a real app.

### Way 2 — `DataSource`

You already know this one — a `DataSource` (like HikariCP, which you'll meet again in Spring Boot) gives you connections too, via `getConnection()`, but it wraps a _pool_ of already-open connections, so nothing in your code changes except where the connection comes from: a pool instead of a fresh socket every time. I won't re-explain the pooling mechanics since you've already covered `DataSource` — just know that in production code, `DataSource` is what replaces `DriverManager` almost everywhere.

## The Design Pattern Behind It

What you just saw in `DriverManager.getConnection(...)` is the **Factory Method pattern** (specifically, here it behaves like a _Service Locator_ backed by factories).

The core idea of a Factory is: instead of your code deciding exactly which concrete class to instantiate (`new SomeSpecificConnectionClass()`), you ask a middleman for "a thing that satisfies this interface," and the middleman decides which concrete class to actually build, based on some input you gave it.

In JDBC's case:

- The **interface** is `java.sql.Connection` (and `java.sql.Driver`) — part of the JDK itself.
- The **concrete classes** are vendor-specific — `org.postgresql.jdbc.PgConnection`, `org.sqlite.SQLiteConnection` — and you never type those class names in your own code.
- The **factory/middleman** is `DriverManager`, which picks the right concrete `Driver` based on the URL prefix, and that `Driver` is itself a factory that produces the concrete `Connection`.

This is also commonly described as the **Bridge pattern** at the architecture level: JDBC defines a stable abstraction (`Connection`, `Statement`, `ResultSet` interfaces) that is completely decoupled from its implementation (the vendor driver). You can swap PostgreSQL for SQLite by changing one URL string and one jar on your classpath — none of your query code changes, because your code only ever depends on the JDK's interfaces, never on a vendor's class.

```java
Connection conn = DriverManager.getConnection(url, user, pass);
// conn's compile-time type is java.sql.Connection,
// but its runtime type is PgConnection or SQLiteConnection
// — your code never needs to know or care which
```

That's really the entire point of JDBC as an API: it is a factory-driven abstraction layer, so your business logic is written once against interfaces, and the actual database underneath is swappable.



[[Java]]