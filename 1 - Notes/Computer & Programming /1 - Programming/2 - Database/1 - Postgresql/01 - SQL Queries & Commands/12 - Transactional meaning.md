
# What Does "Transactional" Mean?

Imagine you're transferring $100 from your savings account to your checking account. Behind the scenes that takes two steps: subtract $100 from savings, then add $100 to checking. What if the system crashes between those two steps? The money has left savings but never arrived in checking, and $100 has vanished.

"Transactional" describes an operation that groups several steps into one **all-or-nothing unit of work**. Either every step succeeds and the changes become permanent, or something goes wrong and everything is undone as if nothing had happened. Here's how that works in PostgreSQL.

## The problem transactions solve

Without transactions, you run into three kinds of trouble:

- **Partial failure:** a crash, network drop, or error halfway through leaves your data half-updated.
- **Interference:** while you're mid-update, someone else reads or changes the same rows and sees a confusing in-between state.
- **Lost durability:** the database says "done," then the server loses power and the change disappears.

A transaction fixes all three with a set of guarantees called **ACID**.

## ACID, one letter at a time

**Atomicity** means all or nothing. If any step fails, PostgreSQL rolls back every step in the transaction.

**Consistency** means the database moves from one valid state to another. Your rules (constraints, foreign keys, `CHECK` conditions) are never left violated by a committed transaction.

**Isolation** means concurrent transactions don't trip over each other. Each one behaves as if it's running alone (to a degree you can control, covered below).

**Durability** means once PostgreSQL confirms a commit, the data survives crashes. It does this by writing changes to the **write-ahead log (WAL)** on disk before confirming.

## Seeing it in action

Here is the bank transfer as a PostgreSQL transaction:

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;  -- savings
UPDATE accounts SET balance = balance + 100 WHERE id = 2;  -- checking

COMMIT;
```

`BEGIN` opens the transaction. Nothing is permanent until `COMMIT`. If something goes wrong, you undo everything:

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- oops, something looks wrong
ROLLBACK;  -- savings is back to its original balance
```

If a statement errors out mid-transaction, PostgreSQL marks the whole transaction as failed. Every later command is refused until you `ROLLBACK`.

**A useful detail:** even a single statement is transactional. If you don't write `BEGIN`, PostgreSQL wraps each statement in its own tiny transaction automatically (this is called _autocommit_). An `UPDATE` touching a million rows either changes all of them or none.

## How PostgreSQL pulls this off: MVCC

You might wonder how PostgreSQL lets many people read and write at once without everything grinding to a halt. The answer is **MVCC (Multi-Version Concurrency Control)**. Instead of overwriting a row in place, PostgreSQL keeps multiple versions of it. Each transaction sees a consistent snapshot based on when it started. The practical result is that **readers don't block writers, and writers don't block readers**.

## Isolation levels: how much interference is allowed

Perfect isolation is expensive, so SQL defines levels that trade strictness for speed. Each level prevents certain odd behaviors:

- **Dirty read:** seeing another transaction's _uncommitted_ changes. PostgreSQL never allows this.
- **Non-repeatable read:** reading the same row twice and getting different values because someone committed in between.
- **Phantom read:** running the same query twice and getting different _sets_ of rows.

PostgreSQL offers three effective levels:

|Level|What it means|
|---|---|
|**Read Committed** (default)|Each statement sees data committed before _that statement_ began.|
|**Repeatable Read**|The whole transaction sees one snapshot from its first query.|
|**Serializable**|Strictest: results are as if transactions ran one after another. Some may fail and need a retry.|

You choose one like this:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
-- ... your queries ...
COMMIT;
```

## Locks and deadlocks

When two transactions want to change the same row, the second one **waits** for the first to finish. You can also lock rows deliberately when you read them, to make sure nobody changes them before you do:

```sql
BEGIN;
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;  -- locks this row
-- decide something based on the balance...
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

Waiting can cause a **deadlock**: transaction A holds row 1 and wants row 2, while transaction B holds row 2 and wants row 1. Neither can move. PostgreSQL detects this and aborts one of them with an error. The usual defense is to always touch rows in a consistent order and keep transactions short.

## Savepoints: undoing only part of a transaction

Sometimes you want to roll back _part_ of the work without throwing away the whole transaction:

```sql
BEGIN;

INSERT INTO orders (id, customer_id) VALUES (10, 5);

SAVEPOINT before_items;
INSERT INTO order_items (order_id, product_id) VALUES (10, 999);  -- suppose this fails
ROLLBACK TO before_items;  -- undo only the items insert

COMMIT;  -- the order itself is still saved
```

## Good habits

- **Keep transactions short.** Long-running ones hold locks and prevent PostgreSQL from cleaning up old row versions.
- **Don't wait for humans inside a transaction.** Never leave one open while waiting for user input.
- **Group only what must succeed together.** A transaction should wrap one logical unit of work, not a whole workday.
- **Be ready to retry.** Under Repeatable Read or Serializable, and after deadlocks, PostgreSQL may abort a transaction, and the correct response is usually to run it again.

## Quick recap

"Transactional" means a group of operations is treated as a single indivisible unit, with ACID guarantees keeping your data correct even through crashes and heavy concurrent use. Master `BEGIN`, `COMMIT`, `ROLLBACK`, and the isolation levels, and you've got the core of it.




[[PostgreSQL]]