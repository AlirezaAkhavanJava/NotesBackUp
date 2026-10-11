

# Part 1: What concurrency means

**Concurrency** is the situation where more than one piece of code uses the same resource at overlapping times. In a database, that means several _connections_ (each one a session with the database, typically one per thread or request) reading or writing data at once.

Concurrency matters because real applications never have just one user. A web server handles many requests simultaneously, and each request may read or write the database. The database must decide what happens when two of those operations touch the same data at the same moment. If it decides badly, you get corrupted data, lost updates, or errors.

# Part 2: Why SQLite behaves differently

Most databases you may have heard of, like PostgreSQL and MySQL, run as a **server process**. Your application connects to it over a network socket, and the server coordinates everything.

SQLite has **no server**. The entire database is a single file on disk, and every application that opens it talks directly to that file through the SQLite library. There is no central coordinator. Coordination happens through **file locks** that the operating system enforces.

This design is why SQLite is so simple to deploy. It is also the source of its concurrency limits. Because coordination is done with file locks, SQLite has a much coarser concurrency model than a server database.

# Part 3: The core rule

SQLite's fundamental rule is:

**At any moment, the database file allows either many readers or exactly one writer.** Under the default configuration, these two states cannot overlap.

Here is what that means in practice:

- Many connections can read at the same time.
- Only one connection can write at a time, and while it writes, other connections attempting to write must wait or fail.
- In the default rollback-journal mode, a writer that is committing also blocks readers, and readers can block a writer from committing.

SQLite implements this with a sequence of lock levels: UNLOCKED, SHARED (for reading), RESERVED (a writer has announced its intent to write), PENDING, and EXCLUSIVE (the writer is committing and nobody else can touch the file). You rarely manage these directly, but understanding that they exist explains most of the error messages you'll see.

# Part 4: The error you will meet

When a connection needs a lock that another connection holds, SQLite does not block forever by default. It returns an error with the code **SQLITE_BUSY**, which Java reports as an exception whose message is typically "database is locked."

This is the single most common SQLite concurrency problem. The fix comes in three parts: enabling WAL mode, setting a busy timeout, and structuring your write transactions carefully.

# Part 5: WAL mode, the most important setting

**WAL** stands for Write-Ahead Log. Instead of modifying the main database file directly and using a rollback journal for safety, SQLite appends changes to a separate `-wal` file. Readers continue reading the main file (and the WAL), while a writer appends to the WAL.

The result is that **readers no longer block the writer and the writer no longer blocks readers.** You still have only one writer at a time, but reads and writes can overlap, which removes most of the busy errors in typical applications.

WAL is a property stored in the database file, so you enable it once. The commands are:

```sql
PRAGMA journal_mode=WAL;
```

When you open the database later, the mode stays WAL. You will see two extra files beside your database, `app.db-wal` and `app.db-shm`. Do not delete them while the application is running. On Debian, these files live in the same directory as the database, so keep the database in a directory your application user can write to.

# Part 6: The busy timeout

By default, a connection that hits a lock fails immediately. A **busy timeout** tells SQLite to keep retrying for a set number of milliseconds before giving up.

```sql
PRAGMA busy_timeout = 5000;
```

Unlike `journal_mode`, the busy timeout is **per connection**. It is forgotten when the connection closes, so you must set it every time you open a connection. This is a common source of confusion: people set it once in one connection and wonder why another connection still fails.

# Part 7: A Java connection factory

Here is a small, complete example that opens a connection and configures it correctly. It uses the `sqlite-jdbc` driver from xerial, which you would add to your Maven or Gradle build.

```java
import org.sqlite.SQLiteConfig;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

public final class SqliteConnections {

    private SqliteConnections() {}

    public static Connection open(String path) throws SQLException {
        SQLiteConfig config = new SQLiteConfig();

        // Per-connection: how long to wait for a lock before failing.
        config.setBusyTimeout(5000);

        // Per-connection: start write transactions with BEGIN IMMEDIATE,
        // which grabs the write lock up front (explained in Part 8).
        config.setTransactionMode(SQLiteConfig.TransactionMode.IMMEDIATE);

        Properties props = config.toProperties();
        Connection conn = DriverManager.getConnection("jdbc:sqlite:" + path, props);

        // Per-file: stored in the database, so setting it again is harmless.
        try (Statement st = conn.createStatement()) {
            st.execute("PRAGMA journal_mode=WAL");
        }
        return conn;
    }
}
```

What each part does:

The `SQLiteConfig` object collects connection settings. `setBusyTimeout` applies the timeout from Part 6 without you writing the PRAGMA yourself. `setTransactionMode` controls how transactions begin, which matters in Part 8. `toProperties()` converts those settings into the form the JDBC driver accepts. The `PRAGMA journal_mode=WAL` statement runs once per connection, which is harmless because it is idempotent: setting WAL when it is already WAL does nothing.

A usage example shows the pattern:

```java
try (Connection conn = SqliteConnections.open("family-inbox.db")) {
    try (var ps = conn.prepareStatement(
            "INSERT INTO messages(sender, body) VALUES (?, ?)")) {
        ps.setString(1, "Ms. Carter");
        ps.setString(2, "Field trip on Friday");
        ps.executeUpdate();
    }
}
```

With `autoCommit` left on, each statement is its own transaction. The `try-with-resources` blocks guarantee that the statement and connection close even if an exception occurs, which prevents leaked locks. Leaked connections are dangerous in SQLite because an unclosed connection can keep a lock held and block everyone else.

# Part 8: Transactions and why BEGIN IMMEDIATE matters

A transaction groups several statements so they succeed or fail together. SQLite offers three ways to begin one:

- **DEFERRED** (the default): the transaction takes no lock until it first reads or writes. If it reads first, it holds a SHARED lock, and later tries to upgrade to a write lock.
- **IMMEDIATE**: the transaction takes the write lock right away.
- **EXCLUSIVE**: the transaction blocks all other access, including reads (in rollback mode).

The problem with DEFERRED is the upgrade step. Suppose two transactions both read a row, then both try to write. Each holds a SHARED lock, and each needs an upgrade to RESERVED. Only one can get it, and the other must fail. Because the failing transaction already did some work, SQLite can return SQLITE_BUSY immediately, without honoring the busy timeout, to avoid a deadlock.

IMMEDIATE avoids this. The transaction claims the write lock at its start, so it either gets it (and proceeds) or waits politely using the busy timeout. Your code then never gets a surprise failure in the middle of a transaction. This is why the factory in Part 7 chooses IMMEDIATE for transactions.

Here is a transaction that moves a value between two rows safely:

```java
public static void transferCredits(Connection conn, long from, long to, int amount)
        throws SQLException {
    conn.setAutoCommit(false);
    try {
        try (var debit = conn.prepareStatement(
                "UPDATE accounts SET balance = balance - ? WHERE id = ?")) {
            debit.setInt(1, amount);
            debit.setLong(2, from);
            debit.executeUpdate();
        }
        try (var credit = conn.prepareStatement(
                "UPDATE accounts SET balance = balance + ? WHERE id = ?")) {
            credit.setInt(1, amount);
            credit.setLong(2, to);
            credit.executeUpdate();
        }
        conn.commit();
    } catch (SQLException e) {
        conn.rollback();
        throw e;
    } finally {
        conn.setAutoCommit(true);
    }
}
```

What this does: it turns off auto-commit so both updates belong to one transaction. If either update fails, the `catch` block rolls back, so the money is never half-moved. The `finally` restores auto-commit so the connection behaves normally afterward. Because the connection was opened in IMMEDIATE mode, the write lock is acquired when the first `UPDATE` runs, and a competing writer waits for up to the busy timeout instead of failing halfway through.

# Part 9: Retrying when the timeout runs out

Even with a busy timeout, a very long write can exhaust it. For that case you may want a retry loop that catches the busy error specifically:

```java
import org.sqlite.SQLiteException;
import org.sqlite.SQLiteErrorCode;

public static <T> T withRetry(int attempts, SqlAction<T> action) throws SQLException {
    for (int i = 1; ; i++) {
        try {
            return action.run();
        } catch (SQLiteException e) {
            boolean busy = e.getResultCode() == SQLiteErrorCode.SQLITE_BUSY;
            if (!busy || i >= attempts) {
                throw e;
            }
            try {
                Thread.sleep(50L * i); // back off a little longer each time
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw e;
            }
        }
    }
}

@FunctionalInterface
public interface SqlAction<T> {
    T run() throws SQLException;
}
```

This retries only on SQLITE_BUSY, which is the one error that a retry can fix. Other errors, such as a syntax mistake or a constraint violation, are rethrown immediately, because retrying them would only repeat the failure. The sleep grows with each attempt, which gives the competing writer time to finish. This code requires Java 17 or later for the pattern-free `catch` style shown; the logic works on any recent version.

# Part 10: Spring Boot

In Spring Boot, you usually don't open connections yourself. The framework uses a **connection pool**, by default HikariCP, which keeps a set of open connections and hands them out to requests.

Pools and SQLite interact in an important way. Each pooled connection is a separate connection to the same file, so the pool creates exactly the concurrency situation described above. Here is a configuration in `application.properties`:

```properties
spring.datasource.url=jdbc:sqlite:family-inbox.db
spring.datasource.hikari.maximum-pool-size=4
spring.datasource.hikari.connection-init-sql=PRAGMA busy_timeout = 5000
```

What each line does: the URL points Spring at the database file. `maximum-pool-size` caps the number of simultaneous connections. `connection-init-sql` runs on every new connection, which is the right place for the per-connection busy timeout from Part 6, since Hikari creates connections on demand and each one needs it.

Choosing the pool size is a real tradeoff. Readers benefit from several connections under WAL mode. Writers do not benefit at all, since only one can write at a time, so extra connections just wait. A pool size of 1 removes all lock contention because requests queue for the single connection, but it also serializes reads, which limits throughput. For a small app, something between 2 and 4 is a sensible starting point, and you should measure before tuning further.

Remember that `journal_mode=WAL` must still be applied. You can run it once with the `sqlite3` command-line tool on Debian, or add it through a Flyway or Liquibase migration, which is the cleaner option in a Spring project:

```bash
sqlite3 family-inbox.db "PRAGMA journal_mode=WAL;"
```

The command prints `wal`, confirming the mode changed.

# Part 11: Summary of the model

Concurrency in SQLite comes down to a few decisions you make deliberately. Enable WAL so reads and writes can overlap. Set a busy timeout on every connection so brief contention waits instead of failing. Open write transactions with IMMEDIATE so they claim the write lock early and fail predictably. Keep writes short, and close connections reliably. Size your pool with the knowledge that writes are always serialized.

When you reach the limits of one writer, that is the signal that the application needs a server database such as PostgreSQL.




[[SQlite]]