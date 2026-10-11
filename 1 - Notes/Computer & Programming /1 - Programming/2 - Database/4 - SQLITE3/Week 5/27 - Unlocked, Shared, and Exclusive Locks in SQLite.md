

These terms describe how a database controls access when multiple connections interact with the same data.

## 1. Unlocked

Unlocked means a connection does not currently hold a lock on the database file.

- Other connections may be able to read or write, depending on their own locks and transaction states.
    
- The connection has no locking privilege merely because it opened the database.
    
- SQLite manages lock acquisition and release automatically.
    

## 2. Shared lock

A shared lock allows a connection to read the database while preventing incompatible operations from modifying the database file during the protected period.

Multiple connections can hold shared locks simultaneously.

Example: two readers

Connection A

Reads data

Connection B

Reads data

Both readers can coexist.

For example, when two SQLite connections execute `SELECT` statements, they can generally read concurrently.

## 3. Exclusive lock

An exclusive lock gives a connection exclusive access to the database file for the relevant operation.

In SQLite's traditional rollback-journal mode, an exclusive lock is needed to finish writing changes to the main database file.

Example: a writer needs exclusive access

Connection A

Writes and commits changes

Connection B

May have to wait before reading or writing

An exclusive lock conflicts with other connections' locks on the same database file. SQLite waits or returns `SQLITE_BUSY`, depending on the circumstances and timeout configuration.

## 4. Comparison

|Property|Unlocked|Shared|Exclusive|
|---|---|---|---|
|Read access|No lock held|Yes|Yes|
|Multiple readers coexist|Possible|Yes|No|
|Other connections can write|Depends on other locks|Not while the shared lock conflicts with the write|No|
|Typical purpose|No current lock|Reading|Finishing a write in rollback-journal mode|

## 5. How they relate to SQLite transactions

In rollback-journal mode, a simplified locking progression is:

`UNLOCKED → SHARED → RESERVED → PENDING → EXCLUSIVE`

- `SHARED`: reading is permitted.
    
- `RESERVED`: a writer intends to write, while readers may continue.
    
- `PENDING`: the writer is waiting for existing readers to finish.
    
- `EXCLUSIVE`: the writer has exclusive access to finish the operation.
    
- `UNLOCKED`: no lock is held.
    

These are SQLite's internal file-locking states, not SQL commands you execute directly.

Important: In WAL mode, the locking mechanism differs. Readers can often continue reading while a writer commits to the WAL, and SQLite still permits only one writer at a time.

The key distinction to remember is that a shared lock permits concurrent reading, while an exclusive lock prevents conflicting access.

---
In SQLite, `UNLOCKED`, `SHARED`, and `EXCLUSIVE` are internal locking states, not SQL commands. You work with them indirectly through transactions and SQLite settings.

## SQLite locking syntax cheat sheet

### 1. Transactions

```
-- Start a deferred transaction
BEGIN;
-- or
BEGIN DEFERRED TRANSACTION;

-- Start a write transaction immediately
BEGIN IMMEDIATE;

-- Start an exclusive transaction
BEGIN EXCLUSIVE;

-- Save changes
COMMIT;
-- or
END;

-- Undo uncommitted changes
ROLLBACK;
```

`BEGIN EXCLUSIVE` behaves differently in WAL mode: it is equivalent to `BEGIN IMMEDIATE` regarding writer acquisition.

### 2. SQLite CLI locking configuration

```
-- Wait up to 5 seconds for a lock
.timeout 5000
```

Or use SQL:

```
PRAGMA busy_timeout = 5000;
```

### 3. Check and configure journal mode

```
-- Check current mode
PRAGMA journal_mode;

-- Enable Write-Ahead Logging
PRAGMA journal_mode = WAL;

-- Switch back to rollback-journal mode
PRAGMA journal_mode = DELETE;
```

### 4. Savepoints inside transactions

```
BEGIN;

SAVEPOINT my_savepoint;

UPDATE accounts
SET balance = balance - 10
WHERE id = 1;

-- Undo changes since the savepoint
ROLLBACK TO my_savepoint;

-- Finish the savepoint
RELEASE my_savepoint;

COMMIT;
```

### 5. What you cannot execute directly

These are not valid SQLite SQL statements:

```
LOCK SHARED;
LOCK EXCLUSIVE;
UNLOCK;
```

SQLite manages its database-file locks automatically.

|Concept|How you work with it|
|---|---|
|Unlocked|SQLite releases locks automatically|
|Shared|Usually acquired automatically for reading|
|Exclusive|Acquired internally when required for writing|
|Immediate write transaction|`BEGIN IMMEDIATE;`|
|Exclusive transaction|`BEGIN EXCLUSIVE;`|
|Wait for lock availability|`.timeout 5000` or `PRAGMA busy_timeout = 5000;`|

Remember: `BEGIN IMMEDIATE` and `BEGIN EXCLUSIVE` are transaction commands, not direct requests for a specific internal lock state.

[[SQlite]]