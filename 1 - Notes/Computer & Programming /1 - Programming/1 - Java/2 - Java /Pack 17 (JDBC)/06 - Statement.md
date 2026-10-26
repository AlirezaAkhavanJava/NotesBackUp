

A `Statement` is the object you use in JDBC to send a plain SQL string to the database and get a result back. You get one from a `Connection`, hand it a SQL command like `SELECT * FROM users`, and it carries that command to the database, waits, and gives you either rows (for queries) or a count (for changes). It is the simplest and oldest way to run SQL in Java, and every other JDBC execution tool builds on the same idea.

It's worth learning properly, even though in real projects you'll mostly use its safer sibling, `PreparedStatement`. `Statement` shows you the raw mechanics: how SQL leaves Java, how results come back, and what needs closing. It also shows you exactly where the dangers are, so you'll understand why `PreparedStatement` exists.

## Where it sits in the flow

```
DataSource ──► Connection ──► Statement ──► ResultSet
 (gives you)   (a session)    (sends SQL)   (holds rows)
```

Since you've already looked at `DataSource`, this is the next link in the chain. The `DataSource` hands you a `Connection`, the `Connection` creates a `Statement`, and the `Statement` produces a `ResultSet`.

## The three execute methods

This is the most important part of `Statement`. You pick the method based on what kind of SQL you're sending:

|Method|Use it for|Returns|
|---|---|---|
|`executeQuery(sql)`|`SELECT`|a `ResultSet` (the rows)|
|`executeUpdate(sql)`|`INSERT`, `UPDATE`, `DELETE`, and DDL like `CREATE TABLE`|an `int` (rows affected; `0` for DDL)|
|`execute(sql)`|Anything, especially when you don't know the type|a `boolean` (`true` = a `ResultSet` is available)|

A rule of thumb: use `executeQuery` for reading and `executeUpdate` for writing. Reach for `execute` only for unusual cases.

## Example 1: Reading data

Imagine a `users` table:

|id|name|age|
|---|---|---|
|1|Alice|30|
|2|Bob|25|

```java
try (Connection conn = dataSource.getConnection();
     Statement stmt = conn.createStatement();
     ResultSet rs = stmt.executeQuery("SELECT id, name, age FROM users")) {

    while (rs.next()) {
        int id = rs.getInt("id");
        String name = rs.getString("name");
        int age = rs.getInt("age");
        System.out.println(id + " " + name + " " + age);
    }
} catch (SQLException e) {
    e.printStackTrace();
}
```

Line by line:

- `try (...)` is try-with-resources. Everything declared inside the parentheses is closed automatically, in reverse order, even if an exception is thrown. This matters a lot (see "Closing things" below).
- `dataSource.getConnection()` borrows a connection. With a pool, "closing" it later just returns it to the pool.
- `conn.createStatement()` creates the `Statement`. Nothing is sent to the database yet.
- `stmt.executeQuery(...)` sends the SQL now and returns a `ResultSet`.
- `rs.next()` moves the cursor to the next row. It returns `false` when there are no more rows. The cursor starts before the first row, which is why you must call `next()` before reading anything.
- `rs.getInt("id")` and the other getters read a column from the current row, by name (or by position, starting at 1).

## Example 2: Changing data

```java
try (Connection conn = dataSource.getConnection();
     Statement stmt = conn.createStatement()) {

    int rows = stmt.executeUpdate("UPDATE users SET age = 31 WHERE name = 'Alice'");
    System.out.println(rows + " row(s) updated");
}
```

Here there's no `ResultSet`. The `int` tells you how many rows the database changed. If it prints `0`, your `WHERE` matched nothing, which is a handy sanity check.

## Example 3: DDL

```java
stmt.executeUpdate("CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, body TEXT)");
```

`SERIAL` is PostgreSQL syntax. In SQLite you'd write `INTEGER PRIMARY KEY AUTOINCREMENT` instead. This is a good reminder that the SQL string is passed to the database untouched: JDBC doesn't translate it, so dialect differences are your responsibility.

## The big danger: SQL injection

Because a `Statement` takes a finished string, it's tempting to build that string by gluing in user input:

```java
String name = userInput;   // imagine this comes from a web form
ResultSet rs = stmt.executeQuery("SELECT * FROM users WHERE name = '" + name + "'");
```

If a user types `' OR '1'='1`, the SQL becomes:

```sql
SELECT * FROM users WHERE name = '' OR '1'='1'
```

That condition is always true, so every row comes back. A worse input could end the statement and start a `DROP TABLE`. The database can't tell your SQL from the attacker's, because by the time it sees the text, it's all one string.

So the rule is simple: **never build SQL with user input using `Statement`.** Use `Statement` only for fixed SQL that contains no outside values. For anything with parameters, use `PreparedStatement`.

## Closing things

`Statement`, `ResultSet`, and `Connection` all hold real resources (cursors, memory, sockets). If you forget to close them, you get leaks, and with a connection pool you can eventually run out of connections and your app freezes.

Two facts help here:

- Closing a `Statement` also closes its `ResultSet`. Closing a `Connection` closes its `Statement`s. But relying on that is sloppy, so declare each one in try-with-resources.
- A `Statement` has only **one active `ResultSet` at a time**. If you run a second query on the same `Statement` while still reading the first, the first `ResultSet` is closed. If you need two at once, create two `Statement`s.

## Useful extras

**Fetching generated keys.** After an `INSERT`, you often want the auto-generated id:

```java
int rows = stmt.executeUpdate(
    "INSERT INTO users (name, age) VALUES ('Carol', 28)",
    Statement.RETURN_GENERATED_KEYS);

try (ResultSet keys = stmt.getGeneratedKeys()) {
    if (keys.next()) {
        System.out.println("New id: " + keys.getLong(1));
    }
}
```

**Batching.** Sending many commands one by one means many network round trips. A batch groups them:

```java
stmt.addBatch("INSERT INTO users (name, age) VALUES ('Dan', 40)");
stmt.addBatch("INSERT INTO users (name, age) VALUES ('Eve', 22)");
int[] results = stmt.executeBatch();
```

You get back an array with one result per command.

**Timeouts and limits.**

- `stmt.setQueryTimeout(5)` stops a query that runs longer than 5 seconds.
- `stmt.setMaxRows(100)` caps how many rows you receive.
- `stmt.setFetchSize(50)` hints how many rows to pull from the database at a time. For very large results in PostgreSQL, this works together with turning auto-commit off.

**Transactions.** A `Statement` runs inside its `Connection`'s transaction. By default a connection is in auto-commit mode, meaning every statement is committed immediately. To group several statements into one all-or-nothing unit:

```java
conn.setAutoCommit(false);
try {
    stmt.executeUpdate("UPDATE accounts SET balance = balance - 100 WHERE id = 1");
    stmt.executeUpdate("UPDATE accounts SET balance = balance + 100 WHERE id = 2");
    conn.commit();
} catch (SQLException e) {
    conn.rollback();
    throw e;
}
```

The transaction belongs to the `Connection`, not the `Statement`.

## Related concept, in short

**`PreparedStatement`** extends `Statement`. You write the SQL once with `?` placeholders (`WHERE name = ?`), then fill the values in separately. The values are sent as data, never as SQL, which blocks injection, and the database can reuse the compiled query. It's the default choice for almost everything you'll write.

Two other relatives: **`CallableStatement`** is for calling stored procedures, and **`ResultSet`** is the cursor over the rows a query returns (we used it above).

## Quick recap

|Idea|Remember|
|---|---|
|What it is|Sends a finished SQL string through a `Connection`|
|Reading|`executeQuery` → `ResultSet`|
|Writing|`executeUpdate` → rows affected|
|Unknown type|`execute` → boolean|
|Biggest risk|SQL injection from string concatenation|
|Always|Close with try-with-resources|
|Real-world default|`PreparedStatement` for anything with parameters|




[[Java]]