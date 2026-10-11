

A transaction in SQLite is a group of SQL operations that are treated as a single logical unit. Either all operations succeed and are committed, or you can roll them all back.

Transactions are essential when multiple database changes must remain consistent.

## 1. Why do transactions exist?

Imagine transferring $100 from Alice to Bob.

```
UPDATE accounts
SET balance = balance - 100
WHERE name = 'Alice';

UPDATE accounts
SET balance = balance + 100
WHERE name = 'Bob';
```

Suppose the first statement succeeds, but the application crashes before the second statement executes. Alice loses $100, but Bob receives nothing.

A transaction prevents this partial update.

## 2. The four transaction commands

|Command|Purpose|
|---|---|
|`BEGIN;`|Starts a transaction.|
|`COMMIT;`|Permanently saves the transaction's changes.|
|`ROLLBACK;`|Undoes uncommitted changes.|
|`SAVEPOINT`|Creates a point you can roll back to within a transaction.|

## 3. Practical example in SQLite3

Open your database:

```
sqlite3 bank.db
```

Start a transaction:

```
BEGIN TRANSACTION;

UPDATE accounts
SET balance = balance - 100
WHERE name = 'Alice';

UPDATE accounts
SET balance = balance + 100
WHERE name = 'Bob';

COMMIT;
```

Both updates are committed together.

If something goes wrong before `COMMIT`, execute:

```
ROLLBACK;
```

SQLite undoes the changes made within the current transaction.

Important: Once you execute `COMMIT`, you cannot use `ROLLBACK` to undo that committed transaction.

## 4. Test `ROLLBACK` yourself

Try this experiment in SQLite:

```
CREATE TABLE IF NOT EXISTS test_accounts (
    name TEXT PRIMARY KEY,
    balance INTEGER NOT NULL
);

INSERT OR IGNORE INTO test_accounts VALUES ('Alice', 500);
```

Now start a transaction:

```
BEGIN;

UPDATE test_accounts
SET balance = balance - 100
WHERE name = 'Alice';

SELECT * FROM test_accounts;
```

Alice's balance should be `400` inside your current database connection.

Now roll back:

```
ROLLBACK;

SELECT * FROM test_accounts;
```

Alice's balance returns to `500`.

The update occurred, but it was never committed.

## 5. Transactions and ACID

Transactions are commonly explained through the ACID properties.

- Atomicity: All operations succeed together, or their uncommitted changes are rolled back.
    
- Consistency: Transactions should preserve database constraints and application-defined invariants.
    
- Isolation: Concurrent transactions are isolated according to the database's concurrency rules.
    
- Durability: Committed changes survive failures according to the database configuration and storage guarantees.
    

SQLite provides transactional behavior, including atomic commits, even when multiple SQL statements are involved.

## 6. What is a `SAVEPOINT`?

A savepoint lets you undo part of a transaction without discarding all of it.

```
BEGIN;

UPDATE test_accounts
SET balance = balance - 50
WHERE name = 'Alice';

SAVEPOINT after_withdrawal;

UPDATE test_accounts
SET balance = balance + 50
WHERE name = 'Bob';

ROLLBACK TO after_withdrawal;

COMMIT;
```

The withdrawal remains committed, but the deposit is undone. This example assumes Bob exists in `test_accounts`.

To finish a savepoint explicitly, use `RELEASE SAVEPOINT savepoint_name;`. Releasing a savepoint does not independently commit the outer transaction.

## 7. One important SQLite detail

SQLite automatically starts transactions for individual database operations when no explicit transaction is active. You do not need to write `BEGIN` for every `INSERT`, `UPDATE`, or `DELETE`.

Use an explicit transaction when multiple operations must succeed or fail as one unit.

For your database studies, remember this mental model:

`BEGIN` → perform changes → `COMMIT` to keep them, or `ROLLBACK` to undo them.



[[SQlite]]