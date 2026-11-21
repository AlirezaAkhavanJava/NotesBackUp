

You already know the database-level meaning of ACID and you already know the proxy mechanics behind `@Transactional`. What's left is the part in between: which pieces of ACID Spring Boot lets you _configure_ from the annotation, and which pieces it just inherits from the database with no say in the matter. `@Transactional` has exactly four attributes relevant here — `isolation`, `propagation`, `rollbackFor`/`noRollbackFor`, and `timeout` — and each one maps onto a specific ACID letter.

## Atomicity → `rollbackFor` / `noRollbackFor`

Atomicity means all-or-nothing, but Spring's default rule for _what counts as "nothing happened"_ is narrower than people expect: **by default, Spring only rolls back on unchecked exceptions** (`RuntimeException` and its subclasses, plus `Error`). A checked exception thrown inside a `@Transactional` method does **not** trigger a rollback unless you tell it to.

```java
@Transactional
public void createAccount(AccountOwner owner) throws IOException {
    accountRepository.save(owner);
    auditLogWriter.writeToFile(owner); // throws IOException
    // if IOException is thrown here, the save() above is still COMMITTED
    // because IOException is checked and Spring's default rollback rule ignores it
}
```

This surprises people because it looks like the whole method failed, but atomicity in Spring's sense is scoped to what Spring was told to treat as a failure:

```java
@Transactional(rollbackFor = IOException.class)
public void createAccount(AccountOwner owner) throws IOException {
    accountRepository.save(owner);
    auditLogWriter.writeToFile(owner); // now a thrown IOException DOES roll back the save
}
```

`noRollbackFor` does the inverse — mark a specific `RuntimeException` subtype as _not_ triggering rollback, for cases where you intentionally want a save to persist even if something downstream throws:

```java
@Transactional(noRollbackFor = NotificationFailedException.class)
public void placeOrder(Order order) {
    orderRepository.save(order);
    notificationService.notify(order); // if this throws, the order save still commits
}
```

The underlying mechanism is the proxy you already know: on method exit, the interceptor checks the thrown exception against this rule set, and only then decides `COMMIT` vs `ROLLBACK`. Atomicity itself — the actual undo — is the database's job (via its transaction log); Spring's only contribution is _deciding when to ask for it_.

## Consistency → mostly out of Spring's hands, with one exception

Consistency (constraints staying valid) is enforced by the database engine — foreign keys, unique constraints, check constraints all live in PostgreSQL, not in Spring. Spring Boot's contribution here is indirect: Bean Validation (`@Valid`, which you already know) catches invalid data _before_ it ever reaches a SQL statement, so you fail fast in Java rather than relying on the database to reject a constraint violation after a round trip. But if a `ConstraintViolationException` comes from Hibernate (e.g. a unique index violation that validation didn't catch — a race between two concurrent requests, for instance), that's the database enforcing consistency, and Spring's only role is making sure that exception is an unchecked one so the default rollback rule catches it.

## Isolation → the `isolation` attribute, and Hibernate's first-level cache

```java
@Transactional(isolation = Isolation.READ_COMMITTED)
public AccountOwner findForUpdate(Long id) {
    return accountRepository.findById(id).orElseThrow();
}
```

The `Isolation` enum (`DEFAULT`, `READ_UNCOMMITTED`, `READ_COMMITTED`, `REPEATABLE_READ`, `SERIALIZABLE`) maps directly onto the SQL-standard levels you already learned. `Isolation.DEFAULT` means "use whatever the underlying database's default is" — for PostgreSQL, that's Read Committed. **This attribute only has an effect when a new physical transaction actually starts** — if you set `isolation` on a method that's running inside an already-open outer transaction (see propagation below), Spring Boot's default behavior is to throw an exception at runtime, because you can't change the isolation level of a transaction that's already underway. This is a real gotcha: the annotation compiles fine either way, but whether it does anything (or throws) depends entirely on the call chain at runtime.

There's a second, Spring-specific layer of "isolation" worth knowing about: Hibernate's **first-level cache** (the persistence context, scoped to one `EntityManager`/one transaction). Within a single transaction, if you load the same entity twice, Hibernate returns the _same Java object_ from its session cache rather than re-querying — so within one transaction you always see a consistent view of an entity you've already loaded, regardless of what the database's isolation level technically permits. This is a Hibernate behavior layered on top of, not a replacement for, the database's isolation guarantees.

## Durability → entirely the database's job, Spring has zero say

There is no `@Transactional` attribute for durability. Once `COMMIT` is issued (whether by the proxy or by you manually), durability is guaranteed by PostgreSQL's write-ahead log, full stop — Spring Boot has no configuration surface here at all. The one place this _looks_ like it's Spring's concern is connection pooling (HikariCP, which you've already learned): if the pool is misconfigured and a connection silently dies mid-transaction, you can lose a transaction's effects before `COMMIT` ever reaches the database — but that's a failure to _reach_ durability, not Spring overriding it.

## Propagation — not one of the four letters, but the thing that decides which transaction you're even in

This isn't ACID itself, but it has to be mentioned here because it decides what atomicity and isolation actually apply _to_ when `@Transactional` methods call each other:

```java
@Transactional(propagation = Propagation.REQUIRED) // default
public void outer() {
    inner(); // joins outer's existing transaction — one atomic unit, one isolation level
}

@Transactional(propagation = Propagation.REQUIRES_NEW)
public void inner() {
    // suspends outer's transaction, starts a completely separate one
    // commits/rolls back independently of outer
}
```

With `REQUIRED` (the default), `inner()` joins whatever transaction is already open — there's only one `BEGIN`/`COMMIT` pair for the whole call chain, so atomicity applies to everything together: if `outer()` throws after `inner()` returns, `inner()`'s work rolls back too, even though `inner()` itself returned successfully. With `REQUIRES_NEW`, `inner()` gets its own independent transaction boundary — its own `BEGIN`/`COMMIT`, its own isolation level, and critically, if `outer()` later fails and rolls back, `inner()`'s already-committed work is **not** undone, because it was a separate atomic unit entirely. This is the mechanism people reach for when they want an audit log entry to survive even if the surrounding business operation fails.

## Putting the Four Together on One Method

```java
@Transactional(
    propagation = Propagation.REQUIRED,
    isolation   = Isolation.READ_COMMITTED,
    rollbackFor = { InsufficientFundsException.class },
    timeout     = 5
)
public void transfer(Long fromId, Long toId, BigDecimal amount) {
    Account from = accountRepository.findById(fromId).orElseThrow();
    if (from.getBalance().compareTo(amount) < 0) {
        throw new InsufficientFundsException(fromId);
    }
    from.setBalance(from.getBalance().subtract(amount));
    Account to = accountRepository.findById(toId).orElseThrow();
    to.setBalance(to.getBalance().add(amount));
    // Atomicity: both updates commit together, or InsufficientFundsException rolls both back
    // Consistency: balance constraints (e.g. CHECK balance >= 0) enforced by Postgres on commit
    // Isolation: READ_COMMITTED — another transfer reading these rows won't see uncommitted balances
    // Durability: once this method returns normally, Postgres's WAL guarantees it survives a crash
}
```

`timeout = 5` is one more attribute worth flagging since it touches atomicity indirectly: if the transaction doesn't commit within 5 seconds, Spring forces a rollback — this exists so a stuck transaction doesn't hold row locks indefinitely, which ties back to the locking behavior you already learned.

[[Spring Framework]]

