
### The Mental Model: Triggers as "Event-Driven Bouncers"

Before we look at the syntax, let’s build a mental model. 

Imagine a high-end nightclub. The club has a standard rule: anyone can walk in. But the club also has a **Bouncer (The Trigger)**. 
1. **The Event:** A person approaches the door (`INSERT`, `UPDATE`, or `DELETE`).
2. **The Timing:** The bouncer checks them *before* they enter, *after* they enter, or *instead of* letting them in.
3. **The Condition:** The bouncer checks a rule (`WHEN` clause). E.g., "Is the person under 21?"
4. **The Action:** If the condition is met, the bouncer does something: checks their ID, logs their name in a VIP book, or physically blocks them.

In a database, a **Trigger** is an automated, event-driven procedure that lives *inside* the database engine. It is not called by your Java code; it is fired invisibly by the database itself when a specific data modification occurs.

***

### The Mechanics: SQLite3 Trigger Syntax

SQLite’s implementation of triggers is powerful but has a few strict quirks compared to heavier databases like PostgreSQL. 

Here is the formal anatomy of a SQLite trigger:

```sql
CREATE TRIGGER [IF NOT EXISTS] trigger_name
    [BEFORE | AFTER | INSTEAD OF] 
    [INSERT | UPDATE | DELETE] 
    ON table_name
    [FOR EACH ROW] -- SQLite ONLY supports FOR EACH ROW
    [WHEN condition]
BEGIN
    -- One or more SQL statements (INSERT, UPDATE, DELETE, SELECT)
    -- You can reference OLD and NEW pseudo-records here
END;
```

#### The Core Concepts:
*   **Timing (`BEFORE`, `AFTER`, `INSTEAD OF`):** 
    *   `BEFORE`: Fires before the row is changed. *Crucial SQLite feature:* You can actually modify the `NEW` data before it gets written!
    *   `AFTER`: Fires after the row is successfully changed. Used for logging or cascading changes to other tables.
    *   `INSTEAD OF`: Used **only on Views**. Since views are virtual and can't be updated directly, this tells SQLite how to translate the view update into base table updates.
*   **`OLD` and `NEW` Pseudo-records:** These are temporary, in-memory representations of the row.
    *   `INSERT`: Only `NEW` exists.
    *   `DELETE`: Only `OLD` exists.
    *   `UPDATE`: Both exist (`OLD` is the row before the change, `NEW` is the row after).
*   **`FOR EACH ROW`:** If your `UPDATE` statement modifies 1,000 rows, the trigger fires 1,000 times. (Note: SQLite *does not* support `FOR EACH STATEMENT`, which is a major distinction from PostgreSQL).

#### Concrete Example: The Audit Log & Auto-Timestamp
Let's say we have an `artworks` table. We want to automatically update an `updated_at` timestamp, and if someone tries to change the `collection`, we want to log the old and new values in an `audit_log` table.

```sql
-- 1. The Audit Table
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    artwork_title TEXT,
    old_collection TEXT,
    new_collection TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. The BEFORE Trigger (Auto-updating a field)
-- Notice how we modify NEW.updated_at. SQLite will apply this to the actual row!
CREATE TRIGGER trg_artworks_before_update
BEFORE UPDATE ON artworks
FOR EACH ROW
BEGIN
    UPDATE artworks SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- 3. The AFTER Trigger (Logging the change)
CREATE TRIGGER trg_artworks_after_update
AFTER UPDATE OF collection ON artworks -- Only fires if 'collection' specifically is updated
FOR EACH ROW
WHEN OLD.collection IS NOT NEW.collection -- Only fires if the value actually changed
BEGIN
    INSERT INTO audit_log (artwork_title, old_collection, new_collection)
    VALUES (NEW.title, OLD.collection, NEW.collection);
END;
```

***

### Nuances, Gotchas, and Advanced Use

This is where database theory meets the harsh reality of production systems, especially when bridging SQLite with Java/Spring Boot.

#### 1. The SQLite Quirk: Modifying `NEW` in a `BEFORE` Trigger
In many databases, a `BEFORE` trigger can only *observe* or *reject* (via `RAISE(ABORT)`). In SQLite, if you execute an `UPDATE` on the `NEW` record inside a `BEFORE` trigger, **SQLite actually applies those changes to the row being inserted/updated**. 
*Why it matters:* You can use this to enforce data sanitization (e.g., forcing all titles to uppercase) directly at the database level, guaranteeing data integrity even if your Java code forgets to sanitize it.

#### 2. The Infinite Loop Gotcha (Recursive Triggers)
What if Trigger A updates Table B, and Table B has a trigger that updates Table A? You get an infinite loop. 
By default, **SQLite disables recursive triggers**. If Trigger A fires, it won't trigger Trigger B. 
*Advanced Use:* If you actually *want* cascading triggers, you must enable it per connection: `PRAGMA recursive_triggers = ON;`. If you do this, you **must** use `WHEN` clauses to break the loop, or your database will lock up and crash.

#### 3. The Spring Boot / JPA Trap (The "Stale State" Problem)
This is the most critical gotcha for your Java/Spring Boot learning journey. 

JPA/Hibernate (the ORM in Spring Boot) maintains a **First-Level Cache** (the Persistence Context). It assumes it is the *only* thing modifying the database. 

If your SQLite trigger automatically changes a column (e.g., the `BEFORE` trigger updating `updated_at`, or changing a status to `APPROVED`), **JPA does not know this happened**. 
1. You save an `Artwork` entity via `repository.save()`.
2. The DB trigger fires and changes a column.
3. You immediately call `repository.findById()` in the same transaction.
4. JPA returns the **cached, stale Java object**, completely ignoring the changes the trigger just made in the database!

**How to handle this in Spring Boot:**
*   **Avoid DB triggers for business logic.** Use JPA `@PrePersist` and `@PreUpdate` annotations in your Java Entity instead. This keeps the logic in Java, where JPA can track it.
*   **Use DB triggers only for deep infrastructure:** Things like strict audit logging, complex geometric calculations, or legacy data migrations where you can't touch the Java code.
*   If you *must* use a DB trigger that alters data, you have to force JPA to refresh its cache: `entityManager.refresh(artworkEntity);`.

#### 4. Defining Triggers in Spring Boot
Since SQLite is often used as an embedded database in Spring Boot (via `spring.datasource.url=jdbc:sqlite:mydb.db`), you don't create triggers via Java code. You define them in your initialization scripts.

In your `src/main/resources/schema.sql`:
```sql
-- Spring Boot will automatically run this on startup if spring.sql.init.mode=always
CREATE TABLE IF NOT EXISTS artworks (...);
CREATE TABLE IF NOT EXISTS audit_log (...);

-- Drop and recreate to avoid "trigger already exists" errors on restart
DROP TRIGGER IF EXISTS trg_artworks_after_update;
CREATE TRIGGER trg_artworks_after_update
AFTER UPDATE OF collection ON artworks
FOR EACH ROW
WHEN OLD.collection IS NOT NEW.collection
BEGIN
    INSERT INTO audit_log (artwork_title, old_collection, new_collection)
    VALUES (NEW.title, OLD.collection, NEW.collection);
END;
```

***

### Knowledge Check

To ensure you've internalized the mechanics and the Spring Boot integration, answer these two questions:

**Question 1 (SQLite Mechanics):**
You have a `BEFORE INSERT` trigger on a `users` table. The trigger contains the following logic:
```sql
BEGIN
    UPDATE users SET email = LOWER(NEW.email) WHERE id = NEW.id;
    SELECT RAISE(ABORT, 'Email domain not allowed') WHERE NEW.email NOT LIKE '%@company.com';
END;
```
If you attempt to insert a user with the email `"Alice@COMPANY.com"`, what exactly happens to the data in the database, and what happens to the Java application executing the insert? Explain the sequence of events.

**Question 2 (Spring Boot / Architecture):**
You are building a Spring Boot app with SQLite. You decide to use an `AFTER UPDATE` trigger to automatically set an artwork's `status` to `'ARCHIVED'` if its `view_count` drops below 10. 
In your Java service, you write this code:
```java
Artwork art = artworkRepository.findById(1L).get();
art.setViewCount(5);
artworkRepository.save(art);

// Immediately check the status
Artwork updatedArt = artworkRepository.findById(1L).get();
System.out.println(updatedArt.getStatus()); 
```
The database definitely shows the status as `'ARCHIVED'`, but the Java console prints `'ACTIVE'`. Why did this happen, and what are two different ways you could fix this architectural mismatch?


[[SQlite]]