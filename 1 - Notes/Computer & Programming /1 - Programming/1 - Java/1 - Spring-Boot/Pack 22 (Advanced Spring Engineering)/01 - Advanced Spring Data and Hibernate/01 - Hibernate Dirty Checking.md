You got the basic mechanics in the last lesson — Hibernate compares current state to a snapshot at flush time. This time let's go deeper into _how_ that comparison actually happens internally, when exactly it runs, and the performance knobs around it — this is Hibernate-specific internals, one level below plain JPA.

## The actual data structure: `EntityEntry`

When an entity becomes managed, Hibernate doesn't just remember "this object exists." Inside the persistence context (Hibernate's internal name for it is the `PersistenceContext` implementation, backing the `EntityManager`/`Session`), every managed entity gets an associated `EntityEntry` object, which holds:

- The entity's current **status** (`MANAGED`, `READ_ONLY`, `DELETED`, etc. — the Hibernate-internal version of the states from your last lesson)
- A **loaded state snapshot** — an array of the entity's field values as they were at load time (or last flush)
- The entity's id, lock mode, and version (if using `@Version` optimistic locking)

This snapshot array is the actual thing dirty checking compares against — not some live diff-tracking as you call setters, but a stored copy taken at one point in time.

## When the comparison actually runs: flush, not setter calls

This is the detail worth being precise about: calling `user.setEmail(...)` does nothing but set a Java field. No Hibernate code runs at that moment. The comparison happens later, at **flush time**, inside a process Hibernate calls the **dirty checking phase of flush**:

```
flush() is triggered (auto, before query, or explicit)
 └─ for each managed entity in the persistence context:
      └─ compare current field values[] against EntityEntry's loaded snapshot[]
           ├─ any field differs? → entity is "dirty"
           │    └─ queue an UPDATE action (just the changed columns, by default)
           └─ no difference? → skip, nothing queued
 └─ execute all queued INSERT/UPDATE/DELETE actions, in a fixed dependency order
```

This is why you can call five setters on an entity across a transaction and Hibernate still issues exactly one `UPDATE` — it's not tracking five separate writes, it's taking one final snapshot comparison right before the SQL actually needs to go out.

## What triggers a flush

You already know flush happens "at commit," but it also happens automatically in other situations, governed by `FlushMode`:

- **`AUTO`** (the default) — flush happens before transaction commit, _and_ before any query execution that could be affected by pending changes (so a JPQL query doesn't return stale results relative to changes you've already made in the same transaction).
- **`COMMIT`** — only flushes at commit time, never before a query. Slightly faster for query-heavy transactions, but risks a query returning data that doesn't reflect your own pending in-memory changes.
- **`MANUAL`** (in native Hibernate; not exposed the same way in plain JPA) — flush only happens when you call it explicitly.

```java
entityManager.unwrap(Session.class).setHibernateFlushMode(FlushMode.COMMIT);
```

## Column-level precision: only changed columns are updated

Hibernate's default generated `UPDATE` includes **every column**, not just changed ones — unless you opt into finer granularity:

```java
@Entity
@DynamicUpdate
public class User {
    @Id
    private Long id;
    private String email;
    private String bio; // a large text field, rarely changed
}
```

Without `@DynamicUpdate`, changing just `email` still produces:

```sql
UPDATE users SET email = ?, bio = ?, ... WHERE id = ?
```

With `@DynamicUpdate`, Hibernate consults the dirty-checking result itself to build the `UPDATE`, producing:

```sql
UPDATE users SET email = ? WHERE id = ?
```

The tradeoff: `@DynamicUpdate` requires Hibernate to build the SQL string dynamically per-update rather than reusing one cached, pre-built statement string for every instance of that entity type — a small CPU cost per update in exchange for smaller SQL and fewer columns touched (useful for very wide tables, columns with expensive triggers, or optimistic-locking scenarios where touching unrelated columns risks false version conflicts).

## Bytecode enhancement: dirty checking without a snapshot at all

Snapshot comparison has a cost: for an entity with many fields, comparing an entire array on every flush, for every managed entity, adds up. Hibernate offers an alternative that avoids the comparison step entirely — **bytecode enhancement**. When enabled (via a build-time Gradle/Maven plugin), Hibernate rewrites your entity's compiled setters to self-report changes directly:

```java
// conceptually, what the enhanced bytecode does —
// you still write a normal setter:
public void setEmail(String email) {
    this.email = email;
}
// the enhancer injects tracking into the compiled version, roughly:
public void setEmail(String email) {
    if (!Objects.equals(this.email, email)) {
        $$_hibernate_trackChange("email");
    }
    this.email = email;
}
```

With this in place, Hibernate knows exactly which fields were touched the instant the setter runs, with no snapshot comparison needed at flush time at all — it just asks the entity "what changed?" directly. This is a genuine performance optimization for entities with many fields or large collections, but it requires an explicit build step (the `hibernate-enhance-maven-plugin` or Gradle equivalent) and is not on by default — snapshot-based dirty checking is what you get out of the box.

## Collections are dirty-checked too, separately

Everything above covers scalar fields. Collections (`@OneToMany`, `@ManyToMany`) get their own tracking via `CollectionEntry`, parallel to `EntityEntry` for entities. Hibernate wraps your collection fields in its own implementations (`PersistentBag`, `PersistentSet`, `PersistentList`) the moment an entity becomes managed — this is why you'll sometimes see `org.hibernate.collection.internal.PersistentBag` in a debugger instead of the plain `ArrayList` you declared. These wrapper types track additions/removals themselves, separately from the snapshot-comparison mechanism used for scalar fields — which is also _why_ an uninitialized lazy collection can be dirty-checked without triggering its own lazy load: Hibernate can ask the wrapper "were you ever touched?" without needing to compare its full contents.

## `StatelessSession`: opting out of all of this

For bulk operations (importing thousands of rows) where dirty checking's bookkeeping overhead and first-level caching are pure waste, Hibernate offers `StatelessSession` — a separate API that skips the persistence context entirely:

```java
try (StatelessSession session = sessionFactory.openStatelessSession()) {
    session.insert(someEntity); // direct INSERT, no snapshot, no dirty checking, no cascading
}
```

No managed state, no dirty checking, no automatic cascading of related entities, no first-level cache. Every operation is an explicit, immediate SQL statement — closer to plain JDBC with entity mapping convenience on top. This is a deliberate trade: you lose all the "just call a setter" convenience in exchange for predictable, minimal-overhead bulk operations.

[[Spring Framework]]
