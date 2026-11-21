

A database transaction is a sequence of one or more operations (reads, inserts, updates, deletes) that the database treats as a single, indivisible unit of work. Either every operation in that unit succeeds and its effects become permanent, or none of them do — there's no in-between state where half the operations happened and the other half didn't. The classic example: transferring money between two accounts requires a debit from one row and a credit to another; if the debit succeeds but the credit fails (crash, constraint violation, network drop), you cannot leave the database in a state where money vanished. A transaction is the mechanism that prevents that.

At the SQL level, this looks like:

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

COMMIT;
```

If anything goes wrong between `BEGIN` and `COMMIT`, you issue `ROLLBACK` instead, and the database undoes every change made since `BEGIN` as if none of it happened. Without wrapping these two statements in a transaction, each `UPDATE` would commit independently the instant it ran, so a crash after the first statement would leave account 1 debited with no corresponding credit to account 2.

## The ACID Properties

Every relational database (PostgreSQL included) guarantees transactions behave according to four properties, commonly abbreviated ACID:

**Atomicity** — the "all or nothing" guarantee described above. A transaction is treated as one atomic operation; it cannot partially apply.

**Consistency** — a transaction takes the database from one valid state to another valid state, meaning all constraints (foreign keys, unique constraints, check constraints) are honored. If a transaction's effects would violate a constraint, the whole transaction is rejected, not just the offending statement.

**Isolation** — concurrent transactions don't see each other's uncommitted changes. If two transactions run at the same time, each one behaves, in principle, as if it were running alone. (This property has a lot of nuance — see isolation levels below, because "as if alone" is actually configurable and usually relaxed for performance.)

**Durability** — once a transaction commits, its effects survive even if the database crashes immediately afterward. This is achieved through write-ahead logging (PostgreSQL's WAL): before a change is applied to the actual data files, it's first written to a log on disk, so recovery after a crash can replay committed transactions that hadn't yet been flushed to the main storage.

## What "Isolation" Actually Protects Against

If two transactions run concurrently with no isolation at all, several specific problems can occur. These have standard names because the SQL standard defines isolation levels in terms of which of these problems each level prevents:

**Dirty read** — Transaction A reads a row that Transaction B has modified but not yet committed. If B then rolls back, A has read data that never actually existed in the database.

```sql
-- Transaction B
BEGIN;
UPDATE accounts SET balance = 1000 WHERE id = 1; -- not committed yet

-- Transaction A (concurrently)
SELECT balance FROM accounts WHERE id = 1; -- sees 1000?? if dirty reads allowed

-- Transaction B
ROLLBACK; -- the 1000 never really existed
```

**Non-repeatable read** — Transaction A reads the same row twice within its own transaction and gets different values, because Transaction B committed an update to that row in between A's two reads.

**Phantom read** — Transaction A runs the same query twice (e.g. `SELECT * FROM accounts WHERE balance > 500`) and gets a different _set of rows_ the second time, because Transaction B inserted or deleted a row matching that condition in between. This is distinct from non-repeatable read because it's about rows appearing/disappearing from a result set, not an existing row's value changing.

## Isolation Levels

The SQL standard defines four isolation levels, each permitting fewer of the above anomalies as you go up:

|Level|Dirty read|Non-repeatable read|Phantom read|
|---|---|---|---|
|Read Uncommitted|possible|possible|possible|
|Read Committed|prevented|possible|possible|
|Repeatable Read|prevented|prevented|possible (standard allows it, PostgreSQL actually prevents it)|
|Serializable|prevented|prevented|prevented|

PostgreSQL's default is **Read Committed**: each statement within a transaction sees a snapshot of the data as of when that statement began, but a later statement in the same transaction can see changes committed by other transactions in the meantime. This is why PostgreSQL's actual behavior at "Repeatable Read" is stricter than the SQL standard requires — PostgreSQL implements it using a snapshot taken once at the start of the transaction (not per statement), which incidentally also blocks phantom reads, something the standard doesn't require at that level.

You set the isolation level per transaction:

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- statements
COMMIT;
```

Higher isolation levels cost more: Serializable in PostgreSQL is implemented by detecting conflicts between concurrent transactions and aborting one of them with a serialization failure if a true conflict is detected, rather than locking everything up front. That means code running at Serializable isolation must be written to catch that failure and retry the transaction — it's not free correctness, it's correctness in exchange for occasional forced retries.

## Transactions and Locking

Isolation is enforced partly through locking. When a transaction modifies a row, PostgreSQL takes a row-level lock on it, which blocks other transactions from modifying (not necessarily reading, depending on isolation level and PostgreSQL's MVCC model) that same row until the first transaction commits or rolls back. PostgreSQL uses **MVCC** (Multi-Version Concurrency Control): rather than making readers wait for writers, each transaction sees a consistent snapshot of the database as of some point in time, and writers create new row versions rather than overwriting in place. This is why, in PostgreSQL, readers essentially never block writers and writers never block readers — only writer-vs-writer conflicts on the same row cause blocking.

This matters practically because long-running transactions holding locks on frequently-updated rows are a common source of application slowdowns — a transaction that opens, does some slow unrelated work, and only then updates a row, holds that row's lock for the entire duration, not just the instant of the update.

## The Transaction Boundary

A transaction has a clear start and a clear end, and everything about ACID and isolation only applies _within_ that boundary:

```sql
BEGIN;        -- boundary starts
-- statement 1
-- statement 2
-- statement 3
COMMIT;       -- boundary ends, changes are now permanent and visible to others
```

Without an explicit `BEGIN`, PostgreSQL runs in **autocommit mode**: every individual statement is wrapped in its own implicit transaction and committed immediately after it runs. This is why a single `UPDATE` with no `BEGIN`/`COMMIT` around it still behaves safely (it's atomic on its own) but gives you no way to group it with other statements as one unit.

This is the concept your `@Transactional` work builds directly on top of: Spring's proxy, which you've already learned, exists to automatically issue the equivalent of `BEGIN` when a `@Transactional` method starts and `COMMIT` (or `ROLLBACK` on an exception) when it ends, so you don't write `BEGIN`/`COMMIT` by hand in Java — the database-level concept here is what that proxy is actually managing underneath.


[[Spring Framework]]
