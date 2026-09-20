
In **PostgreSQL (and databases in general)**, a **session** means a **connection** between your application (or client) and the database server.

---

### 🧱 **1. What is a Session**

- A **session starts** when a client connects to the DB.
    
- It **ends** when the client disconnects.
    
- Every session has its own **state**, **temporary data**, and **locks**.
    

Example:

```bash
psql -U postgres
```

⬆️ This opens one session.  
If you open another terminal and connect again → new session.

---

### ⚙️ **2. Session Lifetime**

|Action|What Happens|
|---|---|
|Connect to DB|Session starts|
|Run queries|All queries share same session context|
|Commit / Rollback|Affects only your session’s transaction|
|Disconnect|Session ends and temporary data is deleted|

---

### 🧩 **3. In PostgreSQL**

Each session:

- Has its own **temporary tables**
    
- Holds its own **session-level locks**
    
- Keeps its own **variables** (using `SET` commands)
    

Example:

```sql
CREATE TEMP TABLE temp_users (id INT);
```

Only **your session** can see `temp_users`.  
When you disconnect → table disappears.

---

### 🔐 **4. Sessions and Advisory Locks**

Advisory locks (like `pg_advisory_lock()`) are **session-level by default** —  
they stay active until:

- You manually unlock, or
    
- The session closes.
    

So if your app’s DB connection closes, PostgreSQL automatically **releases** those locks.

---

### 💻 **5. In Spring Boot**

Each JDBC connection = one database **session**.  
Spring’s **connection pool** (like HikariCP) keeps sessions open and reuses them.

You can think of it like:

```text
Spring Boot App  →  HikariCP Connection  →  PostgreSQL Session
```

---

### ⚡ **In short**

|Concept|Meaning|
|---|---|
|Session|One active DB connection|
|Scope|Lives until disconnect|
|Used by|Temporary tables, advisory locks, settings|
|In Spring Boot|Managed automatically by connection pool|



##### Tags : [[1 - SQL 🥞]]