

**TCL** (Transaction Control Language) is the small set of commands that decide **when your changes become permanent**. A transaction is a group of statements that PostgreSQL treats as one unit: either all of them take effect, or none of them do. TCL commands open that group, close it, and let you step back inside it.

Without transactions, a failure between two related `UPDATE`s leaves your data half-changed. With them, you get **atomicity** (all or nothing) and **isolation** (other sessions don't see your half-finished work). You already used `BEGIN` and `ROLLBACK` in the DDL and DML lessons. Here we look at every TCL command and what it really does.

| Command | What it does |
|---|---|
| `BEGIN` (or `START TRANSACTION`) | opens a transaction |
| `COMMIT` (or `END`) | saves all changes permanently |
| `ROLLBACK` (or `ABORT`) | undoes all changes since `BEGIN` |
| `SAVEPOINT name` | marks a point inside the transaction |
| `ROLLBACK TO SAVEPOINT name` | undoes back to that mark and keeps the transaction open |
| `RELEASE SAVEPOINT name` | forgets the mark (changes stay) |
| `SET TRANSACTION ...` | sets the isolation level or read-only mode |

## Autocommit: the default

Outside a `BEGIN`, every statement is its own tiny transaction, committed immediately. In `psql`, that is how it works by default. `BEGIN` switches that off until you end the transaction.

Sample table for this lesson:

```sql
CREATE TABLE accounts (
    id      serial PRIMARY KEY,
    owner   text NOT NULL,
    balance numeric(10,2) NOT NULL CHECK (balance >= 0)
);
```

| id | owner | balance |
|----|-------|---------|
| 1 | Ana | 500 |
| 2 | Omar | 200 |

## BEGIN, COMMIT, ROLLBACK

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

- `BEGIN` opens the transaction.
- Both `UPDATE`s run, but only **your session** sees the new balances. Other sessions still see 500 and 200.
- `COMMIT` makes both changes permanent and visible to everyone at the same moment.
- If you type `ROLLBACK;` instead of `COMMIT;`, both changes disappear as if they never ran.

Two details to know:
- `UPDATE ... WHERE id = 99` matching **zero rows is not an error**. The transfer would silently take 100 from Ana and give it to nobody. Always check the affected-row count (`UPDATE 1`) in your code.
- `now()` returns the time the transaction **started**, so it is the same in every statement. Use `clock_timestamp()` for the real current time.

## When a statement fails: the aborted state

```sql
BEGIN;
UPDATE accounts SET balance = balance - 900 WHERE id = 1;   -- breaks CHECK (balance >= 0)
```

```
ERROR:  new row for relation "accounts" violates check constraint "accounts_balance_check"
```

In PostgreSQL, one error **poisons the whole transaction**. Every command after it fails with:

```
ERROR:  current transaction is aborted, commands ignored until end of transaction block
```

Only `ROLLBACK` helps. Even `COMMIT` just performs a rollback at this point. Savepoints are the way out.

## Savepoints: undo only part of a transaction

```sql
BEGIN;
UPDATE accounts SET balance = balance + 50 WHERE id = 2;     -- keep this

SAVEPOINT before_withdrawal;
UPDATE accounts SET balance = balance - 900 WHERE id = 1;    -- ERROR: check violated
ROLLBACK TO SAVEPOINT before_withdrawal;                     -- back to the mark, transaction is usable again

UPDATE accounts SET balance = balance - 100 WHERE id = 1;    -- try something else
COMMIT;
```

Line by line:
- `SAVEPOINT before_withdrawal` marks the current position.
- The failing `UPDATE` would normally abort everything.
- `ROLLBACK TO SAVEPOINT` undoes only the work **after** the mark and clears the error state. The first `UPDATE` (+50 for Omar) is still there.
- `COMMIT` saves what remains.

Rules:
- `ROLLBACK TO` keeps the savepoint, so you can roll back to it again. Savepoints created **after** it are discarded.
- `RELEASE SAVEPOINT name` removes the mark when you no longer need it. It does not undo or commit anything.
- Names can be reused. The newest one with that name wins.

## SET TRANSACTION: isolation and mode

Isolation decides what your transaction sees while others commit changes at the same time.

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
-- or, as the first command inside the transaction:
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

`SET TRANSACTION` must come **before the first query** of the transaction.

| Level | What your transaction sees | Extra cost |
|---|---|---|
| `READ COMMITTED` (default) | each statement sees data committed before **that statement** started | none |
| `REPEATABLE READ` | a snapshot taken at your **first statement**; repeated reads return the same rows | may fail with `could not serialize access due to concurrent update` |
| `SERIALIZABLE` | results as if transactions ran one after another | may fail with `could not serialize access due to read/write dependencies` |

- `READ UNCOMMITTED` is accepted but behaves like `READ COMMITTED`. PostgreSQL never shows uncommitted data (no dirty reads).
- When you get a serialization failure (SQLSTATE `40001`), the correct reaction is to **roll back and run the whole transaction again**.

You can also set the mode: `BEGIN READ ONLY;` makes any write fail, which is handy for reporting queries.

## What a rollback does not undo

| Thing | Behavior |
|---|---|
| Sequence values (`nextval`, `serial` ids) | **not rolled back**, so rolled-back inserts leave gaps in ids |
| `CREATE INDEX CONCURRENTLY`, `VACUUM`, `CREATE DATABASE`, `DROP DATABASE` | cannot run inside a transaction block at all |
| Anything outside PostgreSQL (emails sent, files written) | not part of the transaction |

Everything else, including `CREATE TABLE`, `ALTER TABLE` and `DROP TABLE`, **is** transactional in PostgreSQL.

## TCL from Java and Spring Boot

In plain JDBC, the TCL commands become methods on the `Connection`:

```java
try (Connection c = dataSource.getConnection()) {
    c.setAutoCommit(false);                 // BEGIN
    try {
        // run your PreparedStatements here
        c.commit();                         // COMMIT
    } catch (SQLException e) {
        c.rollback();                       // ROLLBACK
        throw e;
    }
}
```

`setSavepoint()` and `rollback(savepoint)` map to `SAVEPOINT` and `ROLLBACK TO SAVEPOINT`.

In Spring, `@Transactional` does this for you (through the proxy you learned about):

```java
@Transactional(isolation = Isolation.REPEATABLE_READ)
public void transfer(long from, long to, BigDecimal amount) { ... }
```

- The method start is `BEGIN`, a normal return is `COMMIT`.
- By default it rolls back only on **unchecked** exceptions (`RuntimeException`, `Error`). A checked exception **commits**, unless you add `rollbackFor = Exception.class`.
- `Propagation.NESTED` is built on savepoints.
- Calling a `@Transactional` method from another method in the same class bypasses the proxy, so no transaction starts (the self-invocation gotcha from your AOP lesson).

## Related concept, in short

**Row locks.** Isolation levels decide what you *see*. Locks decide what you can *change*. `SELECT * FROM accounts WHERE id = 1 FOR UPDATE;` locks the selected rows until your transaction ends, so another transaction trying to update them waits. If two transactions wait on each other's locks, PostgreSQL detects the cycle and aborts one with `deadlock detected`. The fix is to retry, and to always lock rows in the same order.



[[PostgreSQL]]