

Raw JDBC gives you nothing but the pieces — `DataSource`, `Connection`, `Statement`/`PreparedStatement`, `ResultSet`. Nobody stops you from acquiring a connection and forgetting to close it, concatenating SQL strings, or handling a `SQLException` by printing a stack trace. "Designing the JDBC API properly" means wrapping those raw pieces in a layer that is safe by construction — leaks are structurally impossible, SQL injection is structurally impossible, and errors are handled consistently instead of ad hoc. That layer usually has five concerns: resource lifetime, SQL parameterization, result mapping, exception translation, and transaction boundaries. Get those five right and everything built on top of them is solid.

### 1. Resource lifetime — never manage it by hand

Every JDBC resource (`Connection`, `Statement`, `ResultSet`) implements `AutoCloseable`. The rule is absolute: acquire them in a `try-with-resources`, never in a field, never passed around and closed "later."

```java
public Optional<User> findById(long id) {
    String sql = "SELECT id, username, email FROM users WHERE id = ?";

    try (Connection conn = dataSource.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setLong(1, id);

        try (ResultSet rs = ps.executeQuery()) {
            return rs.next() ? Optional.of(mapRow(rs)) : Optional.empty();
        }
    } catch (SQLException e) {
        throw translate(e, "findById failed for id=" + id);
    }
}
```

`dataSource.getConnection()` returns a connection _borrowed from the pool_ (you already know HikariCP does this) — closing it here doesn't destroy a socket, it just returns the connection to the pool. That's why this pattern is cheap to repeat on every method: one connection per unit of work, closed the moment that unit of work is done.

### 2. SQL parameterization — `PreparedStatement` is not optional

You've already learned `PreparedStatement`, so the point here is the _design rule_, not the mechanics: no method in a production DAO is allowed to build SQL by concatenating a variable into the string, ever — not even for an `ORDER BY` column name picked from a fixed whitelist (use a `switch` to map an enum to a literal column instead). If a value changes per call, it is a `?` placeholder. No exceptions.

### 3. Result mapping — a `RowMapper`, not inline parsing

Inlining `rs.getString(...)` calls inside every query method duplicates the mapping logic and makes it easy to drift out of sync with the entity. The production pattern is a small functional interface:

```java
@FunctionalInterface
public interface RowMapper<T> {
    T map(ResultSet rs) throws SQLException;
}

private static final RowMapper<User> USER_MAPPER = rs -> new User(
    rs.getLong("id"),
    rs.getString("username"),
    rs.getString("email")
);
```

Then a generic query helper takes the SQL, the parameters, and a `RowMapper<T>`, and every DAO method becomes a one-liner that just supplies those three things. This is precisely the gap that Spring's `JdbcTemplate` fills for you — once you've built this helper by hand once, you'll recognize `JdbcTemplate.query(sql, mapper, args)` as the same idea, productionized.

### 4. Exception translation — don't leak `SQLException`

`SQLException` is checked, and it's a terrible abstraction to expose to callers: a unique-constraint violation, a connection timeout, and a syntax error all come back as the same type with nothing but a vendor-specific `SQLState` string to tell them apart. A production DAO catches `SQLException` at the boundary and translates it into an unchecked, meaningful exception hierarchy:

```java
public class DataAccessException extends RuntimeException {
    public DataAccessException(String message, Throwable cause) { super(message, cause); }
}
public class DuplicateKeyException extends DataAccessException {
    public DuplicateKeyException(String message, Throwable cause) { super(message, cause); }
}

private DataAccessException translate(SQLException e, String context) {
    String sqlState = e.getSQLState();
    if (sqlState != null && sqlState.startsWith("23")) {   // integrity constraint class
        return new DuplicateKeyException(context, e);
    }
    return new DataAccessException(context, e);
}
```

Callers above the DAO never see `SQLException` or think about SQL states — they catch `DuplicateKeyException` if they care, or let `DataAccessException` propagate. (This is also exactly what Spring's `DataAccessException` hierarchy does for you automatically if you use `JdbcTemplate` — same idea, built in.)

### 5. Transaction boundaries — explicit, and owned by one layer

A transaction should never span more than the DAO/service method that opens it, and it must never be implicit. If a unit of work touches more than one statement and both must succeed or both must fail, you turn off autocommit, do the work, and commit or roll back in a `finally`-free, try/catch-driven flow:

```java
public void transferCredits(long fromId, long toId, int amount) {
    try (Connection conn = dataSource.getConnection()) {
        conn.setAutoCommit(false);
        try {
            debit(conn, fromId, amount);
            credit(conn, toId, amount);
            conn.commit();
        } catch (SQLException e) {
            conn.rollback();
            throw translate(e, "transferCredits failed");
        }
    } catch (SQLException e) {
        throw translate(e, "could not open connection");
    }
}
```

Notice `debit` and `credit` take the _same_ `Connection` as a parameter instead of pulling their own from the pool — that's the rule that makes multi-statement transactions work: one connection per transaction, passed explicitly down to every statement inside it, never re-borrowed from the pool mid-transaction.

### Putting it together: the shape of a production DAO

- **Interface** (`UserRepository`) — defines _what_ operations exist, no SQL visible.
- **Implementation** (`JdbcUserRepository`) — the only class that imports `java.sql.*`; every method follows the shape in §1, uses `PreparedStatement` per §2, a shared `RowMapper` per §3, catches and translates per §4, and opens a transaction explicitly per §5 only when the operation needs more than one statement.
- **Caller** (service layer) — depends only on the interface, never sees `Connection`, `SQLException`, or SQL strings.

That separation is what makes the DAO swappable (you could put `JdbcTemplate` or MyBatis behind the same interface later without touching the service layer) and testable (mock the interface, never the JDBC internals).


[[Java]]