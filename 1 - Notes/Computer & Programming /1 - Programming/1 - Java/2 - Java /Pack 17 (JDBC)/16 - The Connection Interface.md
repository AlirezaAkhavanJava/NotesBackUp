


A `Connection` represents a single, live session between your Java application and the database — everything happens through it. You've already been creating these in the Hikari examples (`dataSource.getConnection()`), but up to now you've only used it as a pass-through to get a `PreparedStatement`. It actually does a lot more than that.

A `Connection` is responsible for:

- Creating `Statement`, `PreparedStatement`, and `CallableStatement` objects — these don't exist without a `Connection` to create them from.
- Controlling **transactions** — whether changes commit automatically or wait for your explicit say-so.
- Holding session-level settings, like which catalog/schema you're working in, or how strict the isolation level is.
- Giving you metadata about the database itself (driver version, supported features, table structure).

### Getting a Connection

Without a pool, you get one from the `DriverManager`:

```java
Connection conn = DriverManager.getConnection(
    "jdbc:postgresql://localhost:5432/trash", "ethan", "yourpassword");
```

With Hikari (what you're actually using), it's:

```java
Connection conn = dataSource.getConnection();
```

Same type, same interface — Hikari just hands you a connection it already opened instead of opening a fresh one.

### Key Methods on `Connection`

**Creating statements** — the main reason you reach for a `Connection` at all:

```java
Statement stmt = conn.createStatement();
PreparedStatement pstmt = conn.prepareStatement(sql);
CallableStatement cstmt = conn.prepareCall("{call some_procedure(?)}");
```

**Transaction control** — by default, every single statement you run auto-commits immediately. You can turn that off to group several statements into one atomic unit:

```java
conn.setAutoCommit(false);

try {
    // multiple statements here, none of them committed yet
    stmt.executeUpdate("UPDATE accounts SET balance = balance - 100 WHERE id = 1");
    stmt.executeUpdate("UPDATE accounts SET balance = balance + 100 WHERE id = 2");

    conn.commit();   // both succeed together
} catch (SQLException e) {
    conn.rollback(); // both are undone together
}
```

This is the exact mechanism Spring's `@Transactional` is built on top of — when you annotate a service method `@Transactional`, Spring is doing this `setAutoCommit(false)` / `commit()` / `rollback()` dance for you behind the scenes, on the connection tied to that method call.

**Isolation level** — controls how much one transaction can see of another transaction's uncommitted changes:

```java
conn.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
```

Common values: `TRANSACTION_READ_UNCOMMITTED`, `TRANSACTION_READ_COMMITTED` (Postgres's default), `TRANSACTION_REPEATABLE_READ`, `TRANSACTION_SERIALIZABLE` — each one trading off consistency guarantees against concurrency.

**Metadata** — asking the driver/database about itself:

```java
DatabaseMetaData meta = conn.getMetaData();
System.out.println(meta.getDatabaseProductName());   // "PostgreSQL"
System.out.println(meta.getDatabaseProductVersion()); // e.g. "18.0"
```

**Closing** — returns the connection (to the pool, if pooled; or actually closes the socket, if not):

```java
conn.close();
```

**Checking state:**

```java
conn.isClosed();  // has this connection already been closed/returned?
conn.isValid(5);  // is it still alive, with a 5-second timeout to check
```

## The `Statement` Interface

A `Statement` is what actually sends SQL to the database and gets results back. You get one from a `Connection`, use it to run SQL, and then close it (or let try-with-resources do it).

There are three flavors, in increasing order of capability: `Statement` (plain SQL, no parameters), `PreparedStatement` (precompiled, parameterized — you've used this already), and `CallableStatement` (for calling stored procedures). This section covers plain `Statement`.

### Creating and Using One

```java
try (Statement stmt = conn.createStatement()) {
    ResultSet rs = stmt.executeQuery("SELECT id, username FROM users");
    while (rs.next()) {
        System.out.println(rs.getInt("id") + ": " + rs.getString("username"));
    }
}
```

The SQL string here is handed over exactly as written, every time — nothing is precompiled or parameterized, which is exactly why `Statement` is dangerous for any query built from user input (classic SQL injection surface). It's really only appropriate for static, hardcoded SQL with no variable parts — DDL statements (`CREATE TABLE`, `ALTER TABLE`) are a legitimate use case, since there's rarely untrusted input to inject there.

### Key Methods on `Statement`

**`executeQuery(String sql)`** — for `SELECT` statements. Returns a `ResultSet`:

```java
ResultSet rs = stmt.executeQuery("SELECT * FROM users");
```

**`executeUpdate(String sql)`** — for `INSERT`, `UPDATE`, `DELETE`, or DDL. Returns an `int`: the number of rows affected (0 for DDL):

```java
int rowsAffected = stmt.executeUpdate("DELETE FROM users WHERE id = 5");
```

**`execute(String sql)`** — for when you don't know ahead of time whether the SQL returns a `ResultSet` or an update count (e.g. dynamically built SQL). Returns `boolean`: `true` if the result is a `ResultSet`, `false` if it's an update count:

```java
boolean isResultSet = stmt.execute(someDynamicSql);
if (isResultSet) {
    ResultSet rs = stmt.getResultSet();
} else {
    int count = stmt.getUpdateCount();
}
```

**Batching** — running many statements in one round trip to the database instead of one network call per statement:

```java
stmt.addBatch("INSERT INTO users (username) VALUES ('alice')");
stmt.addBatch("INSERT INTO users (username) VALUES ('bob')");
int[] results = stmt.executeBatch(); // one array entry per statement, each = rows affected
```

This matters for performance — without batching, inserting 1,000 rows means 1,000 separate round trips to the database; batching bundles them into far fewer.

**Controlling how much comes back:**

```java
stmt.setMaxRows(100);          // cap the number of rows a query can return
stmt.setQueryTimeout(30);      // cancel the query if it runs longer than 30 seconds
stmt.setFetchSize(50);         // hint: fetch rows from the server in chunks of 50
```

**Closing:**

```java
stmt.close();
```

Closing a `Statement` also closes any `ResultSet` it produced — you don't need to close both separately, though doing so explicitly (or via try-with-resources on each) is still good practice for clarity.

## How They Fit Together

The relationship is a strict hierarchy: `Connection` → `Statement` → `ResultSet`. A `Connection` is the session; a `Statement` is one SQL operation run on that session; a `ResultSet` is the data that operation produced. You can create multiple `Statement`s from the same `Connection` and run them independently, but every `Statement` needs exactly one `Connection` to come from.

```java
try (Connection conn = dataSource.getConnection();
     Statement stmt = conn.createStatement();
     ResultSet rs = stmt.executeQuery("SELECT username FROM users")) {

    while (rs.next()) {
        System.out.println(rs.getString("username"));
    }
}
```

The nesting in that `try-with-resources` is deliberate and matches the dependency order: `conn` must stay open for `stmt` to exist, and `stmt` must stay open for `rs` to exist. Java closes them in reverse order automatically — `rs` first, then `stmt`, then `conn` — which is exactly the order they need to be torn down in.


[[Java]]