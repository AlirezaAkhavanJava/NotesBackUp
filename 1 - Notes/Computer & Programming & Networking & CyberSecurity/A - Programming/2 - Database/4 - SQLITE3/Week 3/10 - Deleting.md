


In SQLite, "deleting" can mean three different things: deleting specific rows, deleting all data in a table, or deleting the entire table/database. Here is how to do all of them, both in the DataGrip console and the SQLite CLI.

### 1. Deleting Specific Rows (`DELETE`)
To delete specific rows from a table, you use the `DELETE` statement with a `WHERE` clause. 

**Syntax:**
```sql
DELETE FROM table_name WHERE condition;
```

**Example (using your CS50 database):**
If you want to delete a specific book from the `collections` table:
```sql
DELETE FROM collections WHERE title = 'The Great Gatsby';
```

⚠️ **CRITICAL WARNING:** If you forget the `WHERE` clause, it will delete **every single row** in the table!
```sql
-- THIS DELETES ALL DATA IN THE TABLE:
DELETE FROM collections;
```

### 2. Deleting an Entire Table (`DROP TABLE`)
If you made a mistake creating a table (e.g., you imported `impofile.csv` wrong) and want to completely remove the table structure and all its data:

**Syntax:**
```sql
DROP TABLE table_name;
```

**Example:**
```sql
DROP TABLE collections;
```

*(Note: SQLite does not have a `TRUNCATE` command like MySQL or PostgreSQL. If you want to empty a table but keep the structure, you just use `DELETE FROM table_name;` without a `WHERE` clause).*

### 3. Deleting the Entire Database
Because SQLite is just a single file (like your `mfa.db`), you don't use SQL to delete the database. You just delete the file!

**In your Debian Terminal:**
```bash
rm "/mnt/hdd/Home/Programming Files/HarvardDatabase/week3/mfa.db"
```

---

### How to run these in DataGrip (No CLI needed):
Since you have your `console` tab open in DataGrip, you can run these commands right there:

1. Type your `DELETE` or `DROP` command into the console.
2. Highlight the text you want to run.
3. Press `Ctrl + Enter` (or click the green Play button).

**Alternative GUI method in DataGrip:**
If you want to delete a table without writing SQL, look at the **Database Explorer** on the left. Right-click the table (e.g., `collections`) and select **Drop** (to delete the whole table). 

**💡 Pro-Tip when deleting:**
Before you run a `DELETE` command, it's always a good idea to run a `SELECT` first to make sure you are targeting the exact rows you want to get rid of. 

Example:
```sql
-- Step 1: Check what you are about to delete
SELECT * FROM collections WHERE title = 'The Great Gatsby';

-- Step 2: If it looks right, change SELECT * to DELETE
DELETE FROM collections WHERE title = 'The Great Gatsby';
```

[[1 - WHAT IS SQLITE3 🍕]]