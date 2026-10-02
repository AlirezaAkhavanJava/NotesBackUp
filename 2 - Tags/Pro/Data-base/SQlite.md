
**SQLite** is a lightweight relational database that lives entirely in a **single file** on disk. There is no server to install, start, or connect to over a network. Your program reads and writes the file directly.

**Analogy:** Most databases (PostgreSQL, MySQL) are like a bank: a separate building with staff, and you send requests to it. SQLite is like a notebook on your desk: you open it, write in it, and close it. Same organized tables, no building.

**Core idea:** SQLite is an _embedded_ database. It runs inside your application's process as a library, rather than as a separate program. That means:

- No networking, no ports, no users or passwords to configure (this connects back to what you just learned: a client/server database uses TCP, SQLite doesn't need it).
- The whole database is one file, such as `app.db`, which you can copy, back up, or delete like any file.

**What it still gives you:** real SQL, tables, primary and foreign keys, indexes, and ACID transactions (changes either fully happen or don't happen at all, even if the power dies mid-write).

**Quick taste on Debian 13:**

```bash
sudo apt install sqlite3
sqlite3 library.db
```

```sql
CREATE TABLE books (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    year  INTEGER
);

INSERT INTO books (title, year) VALUES ('Clean Code', 2008);

SELECT * FROM books;
```

Useful shell commands: `.tables` (list tables), `.schema books` (show structure), `.quit` (exit).

**Using it from Java (with Maven):** add the JDBC driver to `pom.xml`:

```xml
<dependency>
    <groupId>org.xerial</groupId>
    <artifactId>sqlite-jdbc</artifactId>
    <version>3.46.1.0</version>
</dependency>
```

```java
import java.sql.*;

public class Demo {
    public static void main(String[] args) throws Exception {
        try (Connection conn = DriverManager.getConnection("jdbc:sqlite:library.db");
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT id, title FROM books")) {

            while (rs.next()) {
                System.out.println(rs.getLong("id") + " " + rs.getString("title"));
            }
        }
    }
}
```

The URL `jdbc:sqlite:library.db` just points at a file; compare that to a server database, where the URL would contain a host and port.

**Where it fits:**

- Great for: learning SQL, prototypes, mobile apps, desktop apps, small tools, tests.
- Poor for: many users writing at the same time, or apps spread over multiple servers.

**Gotchas:**

- **Writes are serialized:** many readers are fine, but only one writer at a time, which is why it doesn't scale to heavy concurrent writes.
- **Flexible typing:** SQLite treats column types as suggestions, so it may accept text in an `INTEGER` column unless you add constraints or use `STRICT` tables.
- **Foreign keys are off by default:** you must run `PRAGMA foreign_keys = ON;` per connection for them to be enforced.
- **In Spring Boot,** SQLite works but needs a community Hibernate dialect, so people usually switch to PostgreSQL for real projects. It's perfect for learning, though, and the SQL you learn transfers directly.


[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]