Date : 2025-09-13




---

# **Ultimate JDBC Goat-Mode Tutorial**

JDBC (Java Database Connectivity) is how your Java 🐐 code talks to a database. Everything flows like this:

```
DriverManager → Connection → Statement/PreparedStatement → ResultSet
```

Every class has a role. Let’s dissect them.

---

## **1️⃣ DriverManager – The Matchmaker**

**Purpose:** Finds the JDBC driver and connects you to a database. It’s like Tinder, but for DBs.

**Key Methods:**

|Method|What it Does|
|---|---|
|`getConnection(String url)`|Connects to DB without credentials (rarely used).|
|`getConnection(String url, String user, String password)`|Most common; returns a `Connection` object.|
|`registerDriver(Driver driver)`|Manually register a JDBC driver (usually automatic).|

**Example:**

```java
Connection conn = DriverManager.getConnection("jdbc:h2:./myDB", "sa", "");
```

---

## **2️⃣ Connection – Your Lifeline**

**Purpose:** Represents a connection to the database. All DB operations go through it.

**Key Methods:**

|Method|Purpose|
|---|---|
|`createStatement()`|Create a simple `Statement` for SQL queries.|
|`prepareStatement(String sql)`|Create a `PreparedStatement` with parameters.|
|`setAutoCommit(boolean autoCommit)`|Manage transactions manually.|
|`commit()`|Commit a transaction (only if auto-commit is off).|
|`rollback()`|Undo changes if something went wrong.|
|`close()`|Close the connection. Mandatory to free resources.|

**Example:**

```java
Connection conn = DriverManager.getConnection("jdbc:h2:./myDB", "sa", "");
conn.setAutoCommit(false);  // manual transaction
// ... do stuff
conn.commit();
conn.close();
```

---

## **3️⃣ Statement vs PreparedStatement – The Warriors**

### **A. Statement – Basic Fighter**

**Purpose:** Executes SQL directly. Vulnerable to SQL injection, slower for repeated queries.

**Key Methods:**

|Method|Purpose|
|---|---|
|`executeQuery(String sql)`|Executes SELECT; returns `ResultSet`.|
|`executeUpdate(String sql)`|Executes INSERT/UPDATE/DELETE; returns row count.|
|`close()`|Close to free resources.|

**Example:**

```java
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("SELECT * FROM users");
stmt.close();
```

---

### **B. PreparedStatement – Elite Assassin**

**Purpose:** Precompiled SQL with placeholders (`?`). Prevents SQL injection, faster for repeated queries.

**Key Methods:**

|Method|Purpose|
|---|---|
|`setInt(int index, int value)`|Set integer parameter at placeholder `?`.|
|`setString(int index, String value)`|Set string parameter.|
|`setDouble(int index, double value)`|Set double parameter.|
|`executeQuery()`|Execute SELECT; returns `ResultSet`.|
|`executeUpdate()`|Execute INSERT/UPDATE/DELETE; returns affected rows.|
|`close()`|Close the statement.|

**Example:**

```java
PreparedStatement ps = conn.prepareStatement("INSERT INTO users(name, age) VALUES(?, ?)");
ps.setString(1, "Ethan");
ps.setInt(2, 25);
ps.executeUpdate();
ps.close();
```

---

## **4️⃣ ResultSet – The Treasure Chest**

**Purpose:** Holds results of SELECT queries. You can move row by row and fetch column values.

**Key Methods:**

|Method|Purpose|
|---|---|
|`next()`|Move cursor to next row; returns false if no more rows.|
|`getInt(String column)`|Fetch int from a column.|
|`getString(String column)`|Fetch string.|
|`getDouble(String column)`|Fetch double.|
|`close()`|Close ResultSet to free resources.|

**Example:**

```java
ResultSet rs = ps.executeQuery();
while(rs.next()) {
    String name = rs.getString("name");
    int age = rs.getInt("age");
    System.out.println(name + " : " + age);
}
rs.close();
```

---

## **5️⃣ Complete Flow Example – CRUD Full Stack**

```java
Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    // 1. Connect to DB
    conn = DriverManager.getConnection("jdbc:h2:./myDB", "sa", "");
    conn.setAutoCommit(false); // Manual transaction control

    // 2. CREATE
    ps = conn.prepareStatement("INSERT INTO users(name, age) VALUES(?, ?)");
    ps.setString(1, "Ethan");
    ps.setInt(2, 25);
    ps.executeUpdate();
    ps.close();

    // 3. READ
    ps = conn.prepareStatement("SELECT * FROM users");
    rs = ps.executeQuery();
    while(rs.next()) {
        System.out.println(rs.getString("name") + " : " + rs.getInt("age"));
    }
    rs.close();
    ps.close();

    // 4. UPDATE
    ps = conn.prepareStatement("UPDATE users SET age=? WHERE name=?");
    ps.setInt(1, 26);
    ps.setString(2, "Ethan");
    ps.executeUpdate();
    ps.close();

    // 5. DELETE
    ps = conn.prepareStatement("DELETE FROM users WHERE name=?");
    ps.setString(1, "Ethan");
    ps.executeUpdate();
    ps.close();

    conn.commit(); // commit all changes

} catch(SQLException e) {
    if(conn != null) conn.rollback(); // undo changes on error
    e.printStackTrace();
} finally {
    if(conn != null) conn.close(); // free resources
}
```

---

## **6️⃣ Goat-Level Tips 🐐**

1. **Always close `ResultSet`, `PreparedStatement`, and `Connection`** to prevent memory leaks.
    
2. **Use `PreparedStatement` over `Statement`**: safer and faster.
    
3. **Transactions**: wrap multiple operations with `setAutoCommit(false)` + `commit()` for consistency.
    
4. **Column names vs indices**: `rs.getInt(1)` vs `rs.getInt("age")`. Names are safer if DB schema changes.
    
5. **Exceptions**: `SQLException` tells you exactly what’s wrong; always catch it.
    

---
![[ChatGPT Image Sep 13, 2025, 02_04_29 AM 1.png]]






##### *Tags : [[0 - Spring Framework]]