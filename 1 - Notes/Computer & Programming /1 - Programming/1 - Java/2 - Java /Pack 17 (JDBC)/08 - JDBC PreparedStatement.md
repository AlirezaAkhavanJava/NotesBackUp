


A `PreparedStatement` is a `Statement` that takes its SQL **up front, with blanks in it**. You write the SQL once, put a `?` wherever a value will go, and then fill each blank with a separate method call before you run it. The SQL text and the values travel to the database as two different things, and the database never mixes them up.

This one idea gives you three benefits at once: safety from SQL injection, no more fiddly string gluing and quote escaping, and a query the database can reuse. It's the version of `Statement` you'll use in nearly all real code, so this lesson is worth going through slowly.

## Meeting it

Here's the `Statement` code from before, which was dangerous when the value came from a user:

```java
// Dangerous: value glued into the SQL
stmt.executeQuery("SELECT * FROM users WHERE name = '" + name + "'");
```

And here's the `PreparedStatement` version:

```java
String sql = "SELECT id, name, age FROM users WHERE name = ?";

try (Connection conn = dataSource.getConnection();
     PreparedStatement ps = conn.prepareStatement(sql)) {

    ps.setString(1, name);

    try (ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            System.out.println(rs.getInt("id") + " " + rs.getString("name"));
        }
    }
}
```

Line by line:

- `String sql = "... WHERE name = ?"` is the SQL with a placeholder. The `?` is not text replacement. It is a slot the database knows about.
- `conn.prepareStatement(sql)` hands the SQL to the database *now*, before any value exists. The database parses it and gets ready.
- `ps.setString(1, name)` fills slot number **1** with a string. Placeholders are numbered from 1, left to right, not from 0. This trips up almost everyone once.
- `ps.executeQuery()` runs it. Notice there is **no SQL argument** this time, because the SQL is already inside the object.
- The inner try-with-resources is there because the `ResultSet` also needs closing, and it keeps the `ResultSet` scoped to where it's used.

## Why injection stops working

Say a user types `' OR '1'='1` as their name. With a plain `Statement`, those characters became part of the SQL and changed its meaning. With `PreparedStatement`, the database already knows the shape of the query, which is "find rows where name equals *some value*." Your input is delivered purely as that value. The database goes looking for a user literally named `' OR '1'='1`, finds nobody, and returns zero rows.

| | `Statement` | `PreparedStatement` |
|---|---|---|
| What the database receives | One finished string | SQL shape + values, separately |
| Input `' OR '1'='1` | Rewrites your query | Treated as an ordinary name |
| Quote handling | You must escape by hand | Done for you |

That separation is the whole security story. It's not that special characters get cleaned. They simply never get a chance to be read as SQL.

## Placeholder rules

Placeholders make a few things easy and a few things impossible. Here is where they work:

| Where | Works with `?` |
|---|---|
| Values in `WHERE` | Yes: `WHERE age > ?` |
| Values in `INSERT ... VALUES` | Yes: `VALUES (?, ?)` |
| Values in `UPDATE ... SET` | Yes: `SET age = ?` |
| `LIMIT` / `OFFSET` numbers | Yes in PostgreSQL and SQLite |
| Table names or column names | **No** |
| SQL keywords like `ASC` / `DESC` | **No** |
| The list inside `IN (...)` | One `?` per value, not one `?` for a list |

The reason for the "No" rows: a placeholder stands for a *value*, and the database must know the structure of the query (which table, which columns) before it can prepare it. So if you need a dynamic column for sorting, pick it from a fixed list in Java:

```java
String orderBy = switch (sortChoice) {
    case "name" -> "name";
    case "age"  -> "age";
    default     -> "id";
};
String sql = "SELECT * FROM users ORDER BY " + orderBy;
```

You choose from words *you* wrote, so nothing from the user ends up inside the SQL.

For `IN`, build the right number of question marks:

```java
List<Integer> ids = List.of(1, 5, 9);
String marks = String.join(",", Collections.nCopies(ids.size(), "?"));
String sql = "SELECT * FROM users WHERE id IN (" + marks + ")";

try (PreparedStatement ps = conn.prepareStatement(sql)) {
    for (int i = 0; i < ids.size(); i++) {
        ps.setInt(i + 1, ids.get(i));
    }
    // execute...
}
```

You generate only `?` characters in the text, and the real values still go through `setInt`.

## The `setXxx` family

This is the new vocabulary `PreparedStatement` adds. Each method takes the placeholder position, then the value.

| Java value | Method | Database type it suits |
|---|---|---|
| `String` | `setString(i, v)` | `VARCHAR`, `TEXT` |
| `int` | `setInt(i, v)` | `INTEGER` |
| `long` | `setLong(i, v)` | `BIGINT` |
| `double` | `setDouble(i, v)` | `DOUBLE PRECISION` |
| `BigDecimal` | `setBigDecimal(i, v)` | `NUMERIC` / `DECIMAL` (money) |
| `boolean` | `setBoolean(i, v)` | `BOOLEAN` |
| `byte[]` | `setBytes(i, v)` | `BYTEA` / `BLOB` |
| `java.sql.Date` | `setDate(i, v)` | `DATE` |
| `java.sql.Time` | `setTime(i, v)` | `TIME` |
| `java.sql.Timestamp` | `setTimestamp(i, v)` | `TIMESTAMP` |
| `InputStream` | `setBinaryStream(i, in)` | large binary data |
| `Reader` | `setCharacterStream(i, r)` | large text |
| anything | `setObject(i, v)` | lets the driver pick the type |
| nothing / null | `setNull(i, sqlType)` | `NULL` |

A few notes on the ones that need care:

**Money: use `BigDecimal`, not `double`.** A `double` can't represent amounts like `0.10` exactly, and tiny errors add up. `setBigDecimal` with a `NUMERIC` column keeps prices exact.

**Dates and times: prefer `setObject` with `java.time`.** The old `java.sql.Date` and `Timestamp` classes are awkward. Modern drivers, including PostgreSQL's, accept `java.time` types directly:

```java
ps.setObject(1, LocalDate.of(2026, 10, 26));
ps.setObject(2, LocalDateTime.now());
ps.setObject(3, OffsetDateTime.now());
```

SQLite deserves a warning here: it has no real date type and stores dates as text or numbers, so be consistent in how you write and read them.

**Nulls need thought.** Primitives can't be `null`, so calling `setInt` can't express "no value." Use `setNull` and tell it the SQL type:

```java
if (age == null) {
    ps.setNull(3, Types.INTEGER);
} else {
    ps.setInt(3, age);
}
```

`setObject(3, age, Types.INTEGER)` also handles an `Integer` that may be null, and it's shorter.

**Why not always `setObject`?** It works almost everywhere, but the specific setters make your intent clear and avoid the driver guessing the wrong type. Use specific setters for common types, and `setObject` for `java.time`, UUIDs, and other special types.

## A full insert, with the generated key

```java
String sql = "INSERT INTO users (name, age) VALUES (?, ?)";

try (PreparedStatement ps =
         conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

    ps.setString(1, "Carol");
    ps.setInt(2, 28);

    int rows = ps.executeUpdate();

    try (ResultSet keys = ps.getGeneratedKeys()) {
        if (keys.next()) {
            long newId = keys.getLong(1);
        }
    }
}
```

The second argument to `prepareStatement` tells the driver to hold on to the generated id, exactly like with `Statement`. Notice the flag goes in at **creation time** here, because the SQL is supplied then, not at execution time.

## Reusing it: the second benefit

Once prepared, you can change the values and run it again. The SQL doesn't need to be re-sent or re-parsed from scratch each time.

```java
try (PreparedStatement ps = conn.prepareStatement(
        "UPDATE users SET age = ? WHERE id = ?")) {

    ps.setInt(1, 31);
    ps.setInt(2, 1);
    ps.executeUpdate();

    ps.setInt(1, 26);
    ps.setInt(2, 2);
    ps.executeUpdate();
}
```

Values stay set until you change them. If you want a clean slate, call `ps.clearParameters()`, which empties all placeholders so you can't accidentally reuse an old value.

A realistic caveat: the speed benefit varies by database. PostgreSQL's driver, for example, only switches to a server-side prepared plan after a statement has run several times (the default threshold is 5). The injection protection, on the other hand, applies from the very first run.

## Batching: where it really shines

With a `Statement`, a batch holds different SQL strings. With a `PreparedStatement`, it holds **one SQL shape with many sets of values**, which is exactly what you want for bulk inserts.

```java
String sql = "INSERT INTO users (name, age) VALUES (?, ?)";

conn.setAutoCommit(false);
try (PreparedStatement ps = conn.prepareStatement(sql)) {

    for (User u : users) {
        ps.setString(1, u.getName());
        ps.setInt(2, u.getAge());
        ps.addBatch();                 // saves this set of values
    }

    int[] results = ps.executeBatch(); // sends them all
    conn.commit();
}
```

Walking through it:

- Inside the loop, you fill the two placeholders, then call `addBatch()` with **no arguments**. That snapshots the current values as one row.
- `executeBatch()` sends all rows together.
- For very large loads, flush every few hundred or thousand rows rather than holding millions in memory:

```java
if (++count % 1000 == 0) ps.executeBatch();
```

- In PostgreSQL, adding `reWriteBatchedInserts=true` to the JDBC URL can speed up batched inserts a lot by merging them into multi-row inserts.

## Method reference

Everything from the `Statement` lesson still works: `setQueryTimeout`, `setFetchSize`, `getGeneratedKeys`, `cancel`, and so on. Here is what `PreparedStatement` changes or adds:

| Method | What it does |
|---|---|
| `executeQuery()` | Runs a `SELECT` using the stored SQL (no argument) |
| `executeUpdate()` | Runs `INSERT`/`UPDATE`/`DELETE`/DDL (no argument) |
| `execute()` | Runs anything; check the boolean as before |
| `addBatch()` | Saves the current parameter values as one batch entry |
| `clearParameters()` | Wipes all placeholder values |
| `getParameterMetaData()` | Describes the placeholders (count, types) |
| `getMetaData()` | Describes the result columns *before* you run it (not all drivers support this) |
| `setXxx(index, value)` | Fills one placeholder |

**A trap to avoid:** the inherited methods that take a SQL string, like `executeQuery(String)`, **throw an exception** on a `PreparedStatement`. If you see an error about that, you accidentally passed SQL to a statement that already has its SQL. Call the no-argument version.

## Mistakes people make

- **Counting from 0.** `ps.setString(0, ...)` throws an error. The first `?` is index 1.
- **Quotes around the placeholder.** Write `WHERE name = ?`, not `WHERE name = '?'`. With quotes, the `?` is just a literal question mark in a string, and you'll get an error about parameters.
- **Forgetting to set a value.** Running with an unset placeholder throws an exception.
- **Creating the statement inside a loop.** Prepare once outside the loop, then set and execute inside it.
- **Trusting it for everything.** It protects *values*. A table name or `ORDER BY` word glued in from user input is still injectable.
- **Using `LIKE` wrongly.** The wildcards belong in the value, not the SQL:

```java
ps = conn.prepareStatement("SELECT * FROM users WHERE name LIKE ?");
ps.setString(1, "%" + searchText + "%");
```

If `searchText` itself might contain `%` or `_`, escape them yourself, since the database will treat them as wildcards.

## Which to use?

| Situation | Choose |
|---|---|
| Any SQL that includes a value from outside your code | `PreparedStatement` |
| The same SQL run many times | `PreparedStatement` |
| Bulk inserts or updates | `PreparedStatement` with batching |
| Fixed SQL with no values, run once (like `CREATE TABLE`) | `Statement` is fine |
| A dynamic table or column name | Whitelist in Java, then build the string |

As a simple habit: if there's any value at all, reach for `PreparedStatement`.

## A related concept, in short

**`CallableStatement`** extends `PreparedStatement` and is for calling stored procedures and functions, using the `{call procedure_name(?, ?)}` syntax. It adds ways to register output parameters and read them back. In PostgreSQL, functions are more common than procedures, and you'll often just call them with a normal `SELECT my_function(?)` through a plain `PreparedStatement`.

## Quick recap

| Idea | Remember |
|---|---|
| What it is | SQL with `?` slots, values supplied separately |
| Numbering | Placeholders start at 1 |
| Safety | Values can't be read as SQL |
| Limits | Works for values only, not names or keywords |
| Reuse | Prepare once, change values, run again |
| Batching | `addBatch()` after each set of values, then `executeBatch()` |
| Nulls | `setNull(i, Types.X)` or `setObject` with a type |
| Execute methods | No SQL argument |




[[Java]]