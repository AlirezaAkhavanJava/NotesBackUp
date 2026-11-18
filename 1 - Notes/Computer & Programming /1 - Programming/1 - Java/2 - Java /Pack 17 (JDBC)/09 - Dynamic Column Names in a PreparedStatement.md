

A `PreparedStatement` placeholder (`?`) can only stand in for a **value**, like `'Ali'` or `42`. It can never stand in for an **identifier**, like a table or column name. The database parses and plans the SQL before any value is bound, and at that point it must already know which columns the statement touches. So `SET ? = ?` fails or does something useless.

To make the column dynamic, you have to build that part of the SQL text yourself. This is dangerous if the column name comes from user input, because it opens the door to SQL injection (the thing `PreparedStatement` normally protects you from, as in your earlier lesson). The safe pattern is: **values go through `?`, column names go through a whitelist.**

---

## 1. What's wrong with the current line

```java
String sql = "UPDATE task SET 'name' = ? WHERE 'NAME' = ";
```

1. **Single quotes make a string, not a column.** `'name'` is the text "name". Identifiers take no quotes (or double quotes `"name"` if you really need them).
2. **The `WHERE` has no value.** It ends with `=` and nothing after it, so it needs a second `?`.
3. **Two different spellings** (`'name'` and `'NAME'`). Pick one.
4. **`throws NullPointerException`** is unnecessary. It's unchecked, so you never need to declare it.

The fixed, non-dynamic version would be:

```java
String sql = "UPDATE task SET name = ? WHERE name = ?";
```

---

## 2. Step one: a whitelist of allowed columns

An `enum` is the cleanest whitelist. Each constant carries the exact SQL text, so nothing from outside can ever reach the query string:

```java
package com.me.JDBC;

public enum TaskColumn {
    ID("id"),
    NAME("name"),
    STATUS("status");   // use your real column names here

    private final String sql;

    TaskColumn(String sql) {
        this.sql = sql;
    }

    public String sql() {
        return sql;
    }
}
```

- The caller can only pass `TaskColumn.NAME`, `TaskColumn.STATUS`, and so on. There is no way to pass `"name; DROP TABLE task"`, because it isn't a constant of the enum.
- If a column is renamed in the database, you change it in one place.

---

## 3. Step two: the dynamic `updateValue`

```java
public void updateValue(TaskColumn setColumn, String newValue,
                        TaskColumn whereColumn, String whereValue)
        throws SQLException {

    String sql = "UPDATE task SET " + setColumn.sql() + " = ? "
               + "WHERE " + whereColumn.sql() + " = ?";

    try (Connection c = getConnection();
         PreparedStatement ps = c.prepareStatement(sql)) {

        ps.setString(1, newValue);    // first ?  -> the new value
        ps.setString(2, whereValue);  // second ? -> the value to match

        int rows = ps.executeUpdate();
        System.out.println(rows + " row(s) updated");
    }
}
```

Line by line:

- The string concatenation only joins **enum text** (`setColumn.sql()`), never user input.
- `?` number 1 and number 2 are bound **by position**, in the order they appear in the SQL.
- `executeUpdate()` returns how many rows changed. `0` means nothing matched your `WHERE`.
- `try (...)` closes the connection and statement even if an exception happens.
- `getConnection()` is a placeholder for however your `JDBCConnection` gets its connection from the `DataSource`.
- I removed `InterruptedException` from `throws`. Nothing in this method sleeps or waits, so nothing can throw it. If your original had a `Thread.sleep(...)` inside, keep it.

Calling it with `setColumn = NAME`, `newValue = "Report"`, `whereColumn = ID`, `whereValue = "7"` builds:

```sql
UPDATE task SET name = ? WHERE id = ?
```

If `id` is an integer column, bind it with `ps.setInt(...)` instead of `setString`. The enum fixes the column name, but the **type** of the value still has to match.

---

## 4. Step three: use it in your executor

Because the `@Override` means the method comes from an interface, add the new signature there too:

```java
void updateValue(TaskColumn setColumn, String newValue,
                 TaskColumn whereColumn, String whereValue) throws SQLException;
```

Then in `ConnectionExecutor`, it's one more one-liner using your `execute` wrapper:

```java
public void updateValue(TaskColumn setColumn, String newValue,
                        TaskColumn whereColumn, String whereValue) {
    execute("update " + setColumn.sql() + " where " + whereColumn.sql() + " = " + whereValue,
            () -> connection.updateValue(setColumn, newValue, whereColumn, whereValue));
}
```

And `main` stays a pure caller:

```java
executor.updateValue(TaskColumn.NAME, "Report", TaskColumn.ID, "7");
```

Any `SQLException` goes through `JdbcExceptionHandler.translate(...)` and prints through `exceptionMessage`, exactly like your other methods.

---

## 5. When you can't use an enum

Sometimes the column list isn't known at compile time (for example, it's read from the database). Then validate against a set instead:

```java
private static final Set<String> ALLOWED = Set.of("id", "name", "status");

private String checkColumn(String column) {
    if (!ALLOWED.contains(column)) {
        throw new IllegalArgumentException("Unknown column: " + column);
    }
    return column;
}
```

Use `checkColumn(userInput)` when building the SQL. The idea is the same: the text that reaches the query must come from **your** list, never straight from the caller. The enum version is better when you can use it, because the compiler enforces it for you.

---

## 6. Related concept: quoting identifiers

When a column name has uppercase letters, spaces, or is a reserved word, you quote it with **double quotes**: `"Name"`. In PostgreSQL, unquoted names are folded to lowercase, so `NAME` and `name` are the same column, but `"NAME"` is a different one. Single quotes are always for string values. If you put a quote-wrapped name in the enum (`"\"Name\""`), that's still safe, because it's your fixed text.


[[Java]]