

A `Statement` has a lot of methods, but they fall into a handful of families: methods that **run SQL**, methods that **collect the answer**, methods that **batch work**, methods that **tune and protect** your query, methods that **manage the object's life**, and a few that **report information**. Once you see the families, the long list stops feeling like a wall of names. Each family answers one question you'll actually have while writing JDBC code.

You'll use about six of these methods daily and meet the rest only occasionally. I'll tell you which is which as we go, so you know where to spend your attention.

## Family 1: Running SQL

These are the core of `Statement`. You met the first three earlier, and now we'll see all the variations.

|Method|What it does|Returns|
|---|---|---|
|`executeQuery(sql)`|Runs a `SELECT`|`ResultSet`|
|`executeUpdate(sql)`|Runs `INSERT`, `UPDATE`, `DELETE`, or DDL|`int` (rows affected)|
|`execute(sql)`|Runs any SQL, when you don't know what kind it is|`boolean` (`true` = there is a `ResultSet`)|
|`executeLargeUpdate(sql)`|Same as `executeUpdate`, for counts above 2 billion|`long`|

**Good use of each:**

- `executeQuery` is your everyday reading tool. If you're selecting, use it. It will throw an exception if you accidentally send an `UPDATE`, which is a helpful safety net.
- `executeUpdate` is your everyday writing tool. The returned count is a free sanity check: if you expected one row and got `0`, your `WHERE` clause missed.
- `execute` is for situations where the SQL comes from outside and you can't know its type, such as a small SQL console tool or a script runner. It's also the way to handle stored procedures or SQL that returns multiple results.
- `executeLargeUpdate` is rare. Only a table with billions of affected rows would need it.

**Which to use?** `executeQuery` for reads, `executeUpdate` for writes. Reach for `execute` only when you truly don't know.

### The `execute` flow, step by step

Because `execute` doesn't hand you the answer directly, it's the one people find confusing. Here is how it works:

```java
boolean hasResultSet = stmt.execute(sql);

if (hasResultSet) {
    try (ResultSet rs = stmt.getResultSet()) {
        while (rs.next()) {
            // read rows
        }
    }
} else {
    int count = stmt.getUpdateCount();
    System.out.println(count + " rows affected");
}
```

- `execute(sql)` runs the SQL and returns a boolean telling you what came back.
- If it's `true`, you fetch the rows with `getResultSet()`.
- If it's `false`, you fetch the count with `getUpdateCount()`.

Think of it as the database handing you a sealed envelope, and you check the flag to learn whether it contains a table or a number.

## Family 2: Collecting the answer

These methods retrieve results after you've run something, mostly with `execute`.

|Method|What it does|
|---|---|
|`getResultSet()`|Gets the current `ResultSet` (after `execute` returned `true`)|
|`getUpdateCount()`|Gets the rows-affected count (after `execute` returned `false`). Returns `-1` if the current result is a `ResultSet` or there are no more results|
|`getLargeUpdateCount()`|Same, as a `long`|
|`getMoreResults()`|Moves to the next result when the SQL produced several|
|`getGeneratedKeys()`|Gets auto-generated values, like new ids, after an `INSERT`|

**Good use:** `getGeneratedKeys()` is the one you'll use most. After inserting a row, you almost always want its new id. The others matter mainly when you use `execute` or stored procedures that return multiple results.

Here's the multiple-results loop, which looks odd but is the standard pattern:

```java
boolean isResultSet = stmt.execute(sql);
while (true) {
    if (isResultSet) {
        try (ResultSet rs = stmt.getResultSet()) {
            // read rows
        }
    } else {
        int count = stmt.getUpdateCount();
        if (count == -1) break;      // no more results at all
        System.out.println(count + " rows affected");
    }
    isResultSet = stmt.getMoreResults();
}
```

The loop ends when there is no result left: `getMoreResults()` returned `false` and `getUpdateCount()` is `-1`. You'll rarely need this, but now you'll recognize it when you see it.

### Getting generated keys: the three ways to ask

You can tell the `Statement` which generated values you want. Each is an overload of `executeUpdate`:

```java
// 1. Ask for all generated keys
stmt.executeUpdate("INSERT INTO users (name) VALUES ('Carol')",
                   Statement.RETURN_GENERATED_KEYS);

// 2. Ask by column position
stmt.executeUpdate("INSERT INTO users (name) VALUES ('Carol')",
                   new int[] {1});

// 3. Ask by column name
stmt.executeUpdate("INSERT INTO users (name) VALUES ('Carol')",
                   new String[] {"id"});

try (ResultSet keys = stmt.getGeneratedKeys()) {
    if (keys.next()) {
        long id = keys.getLong(1);
    }
}
```

**Which to use?** Option 1 is the simplest and works for most cases. Use option 3 when your table has several generated columns and you want a specific one. PostgreSQL returns all columns with option 1, which is fine but can be wasteful, so naming the column is a tidy habit there. Note that `execute` has these same three overloads too.

## Family 3: Batching

Sending commands one by one costs a network round trip each time. Batching collects commands and sends them together.

|Method|What it does|
|---|---|
|`addBatch(sql)`|Adds a command to the batch (nothing is sent yet)|
|`executeBatch()`|Sends the whole batch; returns an `int[]` of results|
|`executeLargeBatch()`|Same, returns a `long[]`|
|`clearBatch()`|Empties the batch without sending it|

```java
conn.setAutoCommit(false);
try (Statement stmt = conn.createStatement()) {
    stmt.addBatch("INSERT INTO logs (msg) VALUES ('start')");
    stmt.addBatch("INSERT INTO logs (msg) VALUES ('working')");
    stmt.addBatch("INSERT INTO logs (msg) VALUES ('done')");

    int[] results = stmt.executeBatch();
    conn.commit();
}
```

Walking through it:

- `setAutoCommit(false)` makes all three inserts one transaction, so they succeed or fail together.
- Each `addBatch` just queues text. No database contact yet.
- `executeBatch()` sends everything at once. The array holds one result per command, in order.
- `conn.commit()` makes it permanent.

**Good use:** loading many rows, or running a series of setup scripts. `clearBatch()` helps when you've queued commands and then decide to abandon them.

**Which to use?** `executeBatch()` is the normal one. One caution: `Statement` batching works with fixed SQL strings. If you're batching inserts with different values, `PreparedStatement` is much better, because you reuse one SQL shape and just change the values. That's where batching really shines.

A result value of `Statement.SUCCESS_NO_INFO` (`-2`) means the command worked but the driver didn't count rows, and `Statement.EXECUTE_FAILED` (`-3`) means that command failed.

## Family 4: Tuning and protecting your query

These methods don't change _what_ you ask. They change _how_ the query behaves, which keeps your app safe and fast.

|Method|What it does|Typical use|
|---|---|---|
|`setQueryTimeout(seconds)` / `getQueryTimeout()`|Aborts a query that runs too long (`0` = no limit)|Protecting your app from a slow query hanging forever|
|`setMaxRows(n)` / `getMaxRows()`|Caps how many rows you receive (`0` = no limit)|Previews, "top 100" screens, safety limit|
|`setLargeMaxRows(n)` / `getLargeMaxRows()`|Same, as `long`|Rare|
|`setFetchSize(n)` / `getFetchSize()`|A hint for how many rows to pull from the database per round trip|Reading huge results without loading everything at once|
|`setFetchDirection(dir)` / `getFetchDirection()`|A hint for which way you'll read rows|Rare; mostly with scrollable result sets|
|`setMaxFieldSize(bytes)` / `getMaxFieldSize()`|Caps the size of large columns (binary/text) you read|Rare|
|`cancel()`|Stops a running statement from another thread|Letting a user cancel a long report|
|`setEscapeProcessing(boolean)`|Turns JDBC's `{...}` escape syntax handling on or off|Rare|
|`setPoolable(boolean)` / `isPoolable()`|Hints whether the statement may be cached by a pool|Rare|

**Good uses, with detail:**

- **`setQueryTimeout`** is the one I'd encourage you to get in the habit of using. Without it, one bad query can hold a connection forever, and with a pool that can starve your whole app.
- **`setMaxRows`** is a blunt but safe tool. Note that it silently drops extra rows, so it's best for limits you intend. For real pagination, put `LIMIT` and `OFFSET` in your SQL instead, so the database does the work.
- **`setFetchSize`** helps with big reads. In PostgreSQL there is an important catch: the driver only streams rows in chunks if **auto-commit is off**, and the result set type is forward-only. Otherwise it loads everything into memory anyway.

```java
conn.setAutoCommit(false);              // required for PostgreSQL streaming
try (Statement stmt = conn.createStatement()) {
    stmt.setFetchSize(500);             // pull 500 rows at a time
    try (ResultSet rs = stmt.executeQuery("SELECT * FROM huge_table")) {
        while (rs.next()) {
            // process one row, memory stays small
        }
    }
}
```

- **`cancel()`** is the odd one because it's meant to be called from a _different thread_ than the one running the query. A "Stop" button in a UI would call it. Driver support varies, and SQLite's driver has limited support, so test it with your database.

**A driver note:** these are requests to the driver, and some drivers treat a few as hints or ignore them. PostgreSQL and SQLite each have their own quirks, so if a setting seems to do nothing, check that driver's documentation.

**Which to use?** For most code: `setQueryTimeout` (always worth it) and `setFetchSize` (for big reads). The rest are situational.

## Family 5: Managing the statement's life

|Method|What it does|
|---|---|
|`close()`|Releases the statement and its `ResultSet`|
|`isClosed()`|Tells you if it's already closed|
|`closeOnCompletion()`|Closes the statement automatically once all its result sets are closed|
|`isCloseOnCompletion()`|Checks whether that behavior is on|

**Good use:** `close()` is essential, but try-with-resources calls it for you, so you rarely write it yourself. `isClosed()` is handy for defensive checks. `closeOnCompletion()` is useful when a method creates a `Statement` and returns only the `ResultSet`. In that case the caller can close the `ResultSet` and the statement cleans itself up:

```java
Statement stmt = conn.createStatement();
stmt.closeOnCompletion();
return stmt.executeQuery("SELECT * FROM users");   // closing this closes stmt too
```

That said, returning raw `ResultSet`s from methods is usually a design smell. It's cleaner to read the rows into a list of objects inside the method and return those.

## Family 6: Reporting information

|Method|What it tells you|
|---|---|
|`getConnection()`|The `Connection` that created this statement|
|`getResultSetType()`|Whether result sets are forward-only or scrollable|
|`getResultSetConcurrency()`|Whether result sets are read-only or updatable|
|`getResultSetHoldability()`|Whether result sets stay open after a commit|
|`getWarnings()` / `clearWarnings()`|Non-fatal warnings from the database|

**Good use:** `getWarnings()` is the most practical. A statement can succeed and still carry a warning, such as data being truncated. Checking it occasionally can reveal issues that exceptions don't. The others are for inspecting how the statement was configured, which matters mainly if you create statements with custom options:

```java
Statement stmt = conn.createStatement(
    ResultSet.TYPE_SCROLL_INSENSITIVE,   // you can move backward and forward
    ResultSet.CONCUR_READ_ONLY);         // you can't edit rows through it
```

That `createStatement(type, concurrency)` call lives on `Connection`, not `Statement`, but it's what the "type" and "concurrency" getters report on.

## Family 7: Safer text building (Java 9+)

Newer JDBC versions added helpers for the one thing you must sometimes do with a `Statement`: put names or text into SQL.

|Method|What it does|
|---|---|
|`enquoteLiteral(String)`|Wraps text as a safe SQL string literal, escaping quotes|
|`enquoteIdentifier(String, boolean)`|Safely quotes a table or column name|
|`isSimpleIdentifier(String)`|Checks whether a name is a plain, safe identifier|
|`enquoteNCharLiteral(String)`|Same as `enquoteLiteral`, for national character literals|

```java
String table = stmt.enquoteIdentifier(userChosenTable, false);
ResultSet rs = stmt.executeQuery("SELECT * FROM " + table);
```

**When it matters:** you can't use `?` placeholders for table or column names, only for values. So if a table name genuinely varies, `enquoteIdentifier` is the correct tool. Still, a fixed whitelist of allowed names is safer than trusting any input. And for ordinary values, don't use `enquoteLiteral`. Use `PreparedStatement` and `?`.

## One more pair: the wrapper methods

`unwrap(Class)` and `isWrapperFor(Class)` let you reach the driver's own statement class underneath a pool's wrapper, so you can call driver-specific features. You'll only need these when a connection pool such as HikariCP wraps your statement and you want a PostgreSQL-specific method.

## So which ones should you actually learn?

Here is the short list, ranked by how often you'll meet them:

|Tier|Methods|
|---|---|
|**Daily**|`executeQuery`, `executeUpdate`, `close` (via try-with-resources)|
|**Often**|`getGeneratedKeys`, `addBatch` / `executeBatch`, `setQueryTimeout`, `setFetchSize`|
|**Sometimes**|`execute` with `getResultSet` / `getUpdateCount`, `setMaxRows`, `cancel`, `getWarnings`, `enquoteIdentifier`|
|**Rarely**|everything else (large variants, fetch direction, field size, escape processing, poolable, cursor name, holdability, `unwrap`)|

## A quick look at the related concept

**`PreparedStatement`** inherits every method above and adds the `setXxx(index, value)` family (`setString`, `setInt`, `setObject`, and so on) for filling `?` placeholders. It also changes the execute methods: you call `executeQuery()` and `executeUpdate()` with **no SQL argument**, because the SQL was supplied when you created it. That's the main reason the plain-`Statement` methods that take a SQL string matter less in real projects: the safe version replaces them.





[[Java]]