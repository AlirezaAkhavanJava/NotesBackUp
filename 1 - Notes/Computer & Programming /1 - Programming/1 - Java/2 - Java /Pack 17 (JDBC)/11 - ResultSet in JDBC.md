


A `ResultSet` is the object JDBC hands you back after you run a `SELECT`. It isn't a snapshot of data sitting in memory all at once — think of it as a cursor pointing at a position in a stream of rows coming from the database. You move that cursor forward row by row, and at each position you pull out the column values for that row. This is why nearly every `ResultSet` loop looks the same: move the cursor, check if there's a row there, read values, repeat.

The cursor starts in a special position **before** the first row. That detail trips people up constantly: you can't call a getter immediately after getting a `ResultSet` back — you have to move the cursor onto a row first.

### Moving the cursor: `next()`

```java
ResultSet rs = stmt.executeQuery("SELECT id, username, email FROM account_owner");

while (rs.next()) {
    int id = rs.getInt("id");
    String username = rs.getString("username");
    String email = rs.getString("email");
    System.out.println(id + " - " + username + " - " + email);
}
```

`next()` does two jobs at once: it advances the cursor to the next row, _and_ it returns `true`/`false` to tell you whether a row was actually there. That's why it's the loop condition, not just a step inside the loop. When it returns `false`, the cursor has moved past the last row — there's nothing left to read, and the loop ends naturally.

If you forget the `while` and just call `rs.getInt(...)` right after `executeQuery`, you'll get a `SQLException` — the cursor is still sitting before row one.

### Reading columns: index vs. label

Every `getXxx` method comes in two flavors:

```java
rs.getString(2);          // by column position (1-based, not 0-based)
rs.getString("username"); // by column label
```

The index version is marginally faster since there's no name lookup, but it's fragile — reorder your `SELECT` columns and your code reads the wrong thing with no compile error. The label version is slightly slower but self-documenting and survives column reordering. Default to labels unless you're doing something performance-critical with a very wide result set.

`getXxx` methods return Java's boxed/primitive types depending on the SQL type — `getInt`, `getLong`, `getDouble`, `getString`, `getBoolean`, `getTimestamp`, `getDate`, `getBigDecimal`, and so on. Pick the method that matches the column's SQL type; JDBC will attempt a conversion if you mismatch, but it can throw or silently lose precision, so match them deliberately.

### Nulls are a trap with primitives

```java
int age = rs.getInt("age");       // if age is SQL NULL, this returns 0
boolean wasNull = rs.wasNull();   // tells you if that 0 was a real 0 or a NULL
```

Primitive `getXxx` methods (`getInt`, `getDouble`, `getBoolean`...) have no way to represent `NULL` — Java primitives can't be null — so JDBC silently returns the "zero value" of that type and leaves you to check `wasNull()` immediately after, if it matters. The non-primitive getters (`getString`, `getTimestamp`, `getBigDecimal`, object types generally) return actual Java `null`, so this gotcha only applies to primitive-returning getters.

### Scrollability, concurrency, and holdability

By default, a `ResultSet` is **forward-only** and **read-only** — you call `next()` and that's the only direction you can go, and you can't modify rows through it. You control this when you create the `Statement`/`PreparedStatement`, not the `ResultSet` itself:

```java
Statement stmt = conn.createStatement(
    ResultSet.TYPE_SCROLL_INSENSITIVE,
    ResultSet.CONCUR_UPDATABLE
);
ResultSet rs = stmt.executeQuery("SELECT id, email FROM account_owner");

rs.last();                 // jump to the last row
int totalRows = rs.getRow();
rs.first();                // jump back to the first row
rs.absolute(5);            // jump straight to row 5
```

**Type** (scrollability) options:

- `TYPE_FORWARD_ONLY` — default, cursor only moves forward
- `TYPE_SCROLL_INSENSITIVE` — can move any direction, but a static snapshot: changes made to the underlying data by others after the query ran won't show up
- `TYPE_SCROLL_SENSITIVE` — can move any direction, and reflects some underlying changes live (support for this varies a lot by driver — PostgreSQL's support is partial)

**Concurrency** options:

- `CONCUR_READ_ONLY` — default, can't write back through the `ResultSet`
- `CONCUR_UPDATABLE` — lets you call `rs.updateString(...)` then `rs.updateRow()` to push changes back to the database through the cursor itself, instead of writing a separate `UPDATE` statement

In practice, most production code sticks with the defaults (forward-only, read-only) and does writes through explicit `UPDATE`/`INSERT` statements instead of updatable result sets — it's more predictable and portable across drivers. Scrollable/updatable result sets show up more in tooling or UI-grid style code where you genuinely need to jump around.

**Holdability** controls whether the `ResultSet` stays open after you commit the transaction it was created in (`HOLD_CURSORS_OVER_COMMIT` vs `CLOSE_CURSORS_AT_COMMIT`). This one matters less day-to-day — it's mostly relevant if you're keeping a cursor open across transaction boundaries, which is uncommon in typical Spring Boot/JPA-style code since the persistence layer manages that for you.

### Resource management

A `ResultSet` holds onto a database-side cursor resource — it needs closing just like `Connection` and `Statement`. Closing a `Statement` automatically closes any `ResultSet` it produced, and closing a `Connection` cascades down through both. That's why try-with-resources, closing in reverse order of creation, is the standard pattern:

```java
try (Connection conn = dataSource.getConnection();
     PreparedStatement ps = conn.prepareStatement("SELECT id, username FROM account_owner WHERE id = ?");
     ) {
    ps.setLong(1, 42L);
    try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
            System.out.println(rs.getString("username"));
        }
    }
}
```

Nesting the `ResultSet` in its own try-with-resources inside the outer one is the cleanest way to be explicit about it, though in practice the outer `Statement`'s close would have taken care of it anyway.

### A related concept, briefly: `ResultSetMetaData`

If you ever need to inspect a `ResultSet`'s _shape_ without knowing the query in advance — column count, column names, SQL types — call `rs.getMetaData()`, which returns a `ResultSetMetaData` object with methods like `getColumnCount()`, `getColumnName(int)`, and `getColumnTypeName(int)`. This is how generic tools (database browsers, dynamic report generators) can print any query's results without hardcoding column names — not something you'll reach for in typical application code where you already know your schema.


[[Java]]