

A race condition occurs when the outcome of a program depends on the timing or order of operations performed by concurrent transactions or processes.

In SQLite, race conditions matter when multiple connections access and modify the same database. Understanding them requires distinguishing two things:

- Concurrency: Multiple connections operate on the database during overlapping periods.
    
- Race condition: The order of those operations causes an incorrect or unexpected result.
    

SQLite supports concurrent readers, but it serializes writes: only one write transaction can be active at a time for a given database. This prevents simultaneous writes from freely overwriting each other, but it does not automatically make every multi-step application operation safe.

## 1. A banking example

Suppose Alice has a balance of `$100`. Two transactions attempt to withdraw `$80` at nearly the same time.

T1

Transaction 1

Reads Alice's balance: `$100`

Checks whether `$100 >= $80`: true

T2

Transaction 2

Also reads Alice's balance: `$100`

Checks whether `$100 >= $80`: true

T1 + T2

Both attempts passed the check, but only `$100` existed. If the application does not coordinate the check and update correctly, it risks allowing an invalid withdrawal or reporting a misleading result.

This is a classic check-then-act race: the application checks a condition and later acts on it, but the underlying state might have changed in between.

## 2. Reproduce a race condition using SQLite

First, create a practice table in `bank.db`:

```
CREATE TABLE IF NOT EXISTS race_accounts (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    balance INTEGER NOT NULL CHECK (balance >= 0)
);

INSERT OR IGNORE INTO race_accounts
VALUES (1, 'Alice', 100);
```

Open two terminal windows and connect to the same database in both:

```
sqlite3 bank.db
```

In terminal 1, start a transaction and read Alice's balance:

```
BEGIN;

SELECT balance
FROM race_accounts
WHERE id = 1;
```

In terminal 2, execute:

```
BEGIN;

SELECT balance
FROM race_accounts
WHERE id = 1;
```

Both connections may read `100`, because SQLite allows concurrent readers.

Now, in terminal 1:

```
UPDATE race_accounts
SET balance = balance - 80
WHERE id = 1;

COMMIT;
```

Try the same update and commit in terminal 2. Depending on its transaction state and journal mode, the second connection may receive `SQLITE_BUSY` or `SQLITE_BUSY_SNAPSHOT` instead of successfully committing its stale transaction.

That is important: SQLite's locking and transaction rules prevent many unsafe interleavings, but your application must still handle transaction conflicts and retries correctly.

## 3. The safest solution: make the condition part of the update

Instead of reading the balance into your application, checking it, and then updating it in a separate statement, perform the check and modification in one SQL statement:

```
UPDATE race_accounts
SET balance = balance - 80
WHERE id = 1
  AND balance >= 80;
```

Then check how many rows were changed:

```
SELECT changes();
```

- `1` means the withdrawal succeeded.
    
- `0` means the account did not exist or the balance was insufficient.
    

SQLite serializes writes, so concurrent executions of this conditional update cannot both successfully withdraw `$80` from an initial balance of `$100`. After one withdrawal succeeds, the other will find that the condition is no longer true.

This is a practical example of an atomic conditional update.

## 4. What does `BEGIN IMMEDIATE` do?

For operations that genuinely require multiple SQL statements, you can acquire the write transaction before reading the data:

```
BEGIN IMMEDIATE;

SELECT balance
FROM race_accounts
WHERE id = 1;

-- Validate the balance in your application.

UPDATE race_accounts
SET balance = balance - 80
WHERE id = 1
  AND balance >= 80;

COMMIT;
```

`BEGIN IMMEDIATE` attempts to acquire the write transaction at the beginning. If another connection already holds a conflicting write transaction, SQLite may return `SQLITE_BUSY`.

Your application must handle that failure, and it should verify that the `UPDATE` changed one row before treating the withdrawal as successful. If the transaction needs to be abandoned, issue `ROLLBACK`.

## 5. Three concepts to remember

|Concept|Meaning|
|---|---|
|Race condition|The correctness of an operation depends on concurrent execution order.|
|Database locking|Coordinates access to shared database state.|
|Atomic operation|A single indivisible database operation, such as a conditional `UPDATE`.|

Professional rule: Prefer a single conditional SQL statement when it can express the business rule. When multiple statements must work together, use a transaction, choose the appropriate transaction mode, and handle lock errors explicitly.

SQLite's single-writer model simplifies concurrency considerably, but correct transaction design is still your responsibility.



[[SQlite]]