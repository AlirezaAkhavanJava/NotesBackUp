

A lock is a mechanism that controls when a connection can access or modify a shared resource, preventing incompatible operations from interfering with one another.

In SQLite, locks coordinate access to the same database file when multiple connections or processes try to read and write data concurrently.

The central problem is this: how can multiple connections safely use the same database without corrupting data or producing incorrect results?

## 1. What problems do locks solve?

Imagine two applications accessing `bank.db` at the same time.

- Connection A is updating Alice's balance.
    
- Connection B is trying to update Bob's balance.
    
- Connection C is reading account balances.
    

Without concurrency control, conflicting operations could interfere with one another.

Locks help SQLite coordinate these operations by controlling access to the database.

They help prevent:

- Conflicting writes: Multiple writers modifying the database simultaneously.
    
- Inconsistent reads: Readers observing data in states that the selected isolation model does not permit.
    
- Database corruption: Conflicting file operations damaging database structures.
    
- Lost updates: Concurrent application operations overwriting each other's intended changes, although correct SQL and transaction design are also necessary to prevent these.
    

Locks do not automatically fix every race condition. For example, an application can still make an incorrect decision based on a value it read earlier, even if SQLite's locking works perfectly.

## 2. How SQLite locking works

SQLite's locking behavior depends on its journal mode. The two major modes are:

### Rollback journal mode

Traditional mode

SQLite uses locks on the database file to coordinate readers and writers. A writer can prepare changes while readers are active, but it needs exclusive access to finish committing changes to the database file.

### WAL mode

Write-Ahead Logging

Changes are written to a separate WAL file first. Readers can generally continue reading an earlier consistent snapshot while a writer appends changes to the WAL. SQLite still permits only one writer at a time.

Check your current journal mode:

```
PRAGMA journal_mode;
```

Switch to WAL mode if appropriate for your application:

```
PRAGMA journal_mode = WAL;
```

Run that command outside an active transaction. The mode is persistent for the database, and WAL has operational considerations, including its shared-memory requirements for participating connections.

## 3. The locking states in SQLite

In rollback-journal mode, SQLite uses several locking states to coordinate readers and writers.

|Lock state|What it means|
|---|---|
|`SHARED`|A connection can read the database. Multiple readers can hold this lock.|
|`RESERVED`|A connection intends to write. Existing readers can generally continue reading.|
|`PENDING`|A writer is waiting for existing readers to finish before obtaining exclusive access. New readers are blocked.|
|`EXCLUSIVE`|A connection has exclusive access to the database file for the relevant operation.|

The typical progression for a writer is:

SHARED

Read the database

RESERVED

Prepare to write

PENDING

Wait for existing readers

EXCLUSIVE

Finish committing database changes

Conceptual progression for a writer in rollback-journal mode; SQLite may skip states or acquire locks differently depending on the operation.

These are internal SQLite locking states, not commands you normally issue yourself.

## 4. How to work with locks

You usually don't acquire or release SQLite file locks manually. SQLite manages them through SQL statements, transactions, and connection settings.

### A. Set a busy timeout

Suppose one connection is writing and another tries to write. The second connection may receive:

```
database is locked
```

You can ask SQLite to wait for a limited period instead of immediately failing:

```
.timeout 5000
```

This is a SQLite CLI command that configures a five-second busy timeout for that connection.

You can also configure it with SQL:

```
PRAGMA busy_timeout = 5000;
```

The timeout gives a conflicting operation time to proceed after a lock is released. It does not guarantee success if the conflict persists.

### B. Use `BEGIN IMMEDIATE` for read-modify-write operations

Consider this sequence:

1. Read an account balance.
    
2. Check whether the balance is sufficient.
    
3. Update the balance.
    

If you begin with a deferred transaction (`BEGIN;`), the connection may read first and only later attempt to become a writer. Another connection could write in between, causing a lock conflict.

Instead:

```
BEGIN IMMEDIATE;

SELECT balance
FROM race_accounts
WHERE id = 1;

UPDATE race_accounts
SET balance = balance - 80
WHERE id = 1
  AND balance >= 80;

COMMIT;
```

`BEGIN IMMEDIATE` attempts to acquire the write transaction at the beginning. This avoids a later read-to-write upgrade conflict, although another writer can cause `BEGIN IMMEDIATE` itself to fail with `SQLITE_BUSY`.

In production code, check that the update changed exactly one row before treating the withdrawal as successful. Otherwise, roll back when appropriate.

### C. Keep transactions short

Avoid this pattern:

```
BEGIN IMMEDIATE;

-- Perform a database update.
-- Wait for a user to respond.
-- Make an HTTP request.
-- Wait several seconds.

COMMIT;
```

While the write transaction remains active, other connections cannot start their own write transactions.

Prefer:

1. Perform slow external work before the transaction when possible.
    
2. Open the transaction.
    
3. Execute the required SQL statements.
    
4. Commit immediately.
    

This reduces contention and improves throughput.

## 5. Hands-on experiment: two connections

Use your `bank.db` in two separate terminal windows.

Terminal 1 — hold a write transaction

```
sqlite3 bank.db
```

Then execute:

```
.timeout 5000

BEGIN IMMEDIATE;

UPDATE accounts
SET balance = balance + 1
WHERE id = 1;

-- Do not commit yet.
```

Terminal 2 — attempt another write

```
sqlite3 bank.db
```

Then execute:

```
.timeout 5000

BEGIN IMMEDIATE;
```

Terminal 2 will wait while terminal 1 holds the write transaction. If terminal 1 commits before the timeout expires, terminal 2 can acquire its transaction. Otherwise, terminal 2 can report `database is locked`.

Return to terminal 1:

```
COMMIT;
```

Then observe terminal 2. If its `BEGIN IMMEDIATE` succeeded, finish with:

```
ROLLBACK;
```

You have just observed SQLite's single-writer rule in practice.

## 6. Which approach should you use?

|Situation|Recommended approach|
|---|---|
|A single conditional update|One atomic `UPDATE` statement|
|Several related database changes|`BEGIN` and `COMMIT`|
|Read first, then modify in the same transaction|Consider `BEGIN IMMEDIATE`|
|Occasional transient lock conflicts|Configure a busy timeout and handle errors|
|Many readers and occasional writes|Consider WAL mode|
|Long-running application operations|Keep database transactions short|

One final distinction: SQLite file locks are different from Java's `synchronized`, `ReentrantLock`, or `ReadWriteLock`. Java locks coordinate threads in your application; SQLite locks coordinate database access across connections and processes. You may need both, but Java locks alone cannot coordinate independent processes accessing the same database.

Mental model: Transactions define which operations belong together. Locks coordinate competing access. Isolation rules determine which concurrent changes a transaction can observe. All three work together to maintain database correctness.

[[SQlite]]