This one's a genuine shift in topic — not Spring internals, but JPA/Hibernate internals. You've learned the pieces of an entity (fields, constructors, `@GeneratedValue`, auditing annotations) but not the **state machine** an entity instance actually moves through once it exists in memory. This lesson is that state machine, plus the callback hooks that fire as an entity crosses between states — which is also what's really running underneath `@CreatedDate`/`@LastModifiedDate` from your auditing lesson.

## The four states

Every JPA entity instance is, at any given moment, in exactly one of four states, tracked by the **persistence context** (the first-level cache an `EntityManager` owns internally):

![[61f02502-5aed-4d1a-b8de-22421e1661f0.png]]

- **Transient** — a plain Java object, created with `new`, that the persistence context has never heard of. No row exists, nothing is tracked.
- **Managed** (also called _persistent_) — the entity is attached to an active persistence context. Any field change you make to it is automatically tracked and will be written to the database at flush time — you never call an explicit "update" method.
- **Detached** — was managed at some point, but the persistence context that tracked it is now closed (the `EntityManager` closed, or it was explicitly evicted). The Java object still exists and still has its data, but changes to it are no longer tracked or persisted.
- **Removed** — scheduled for deletion. Still an object in memory, still technically "managed" in the sense that it's in the persistence context, but marked for a `DELETE` on next flush.

```java
User user = new User("alice"); // TRANSIENT — just a Java object

entityManager.persist(user);   // now MANAGED — tracked, INSERT scheduled

user.setEmail("a@example.com"); // no explicit save call needed —
                                 // the persistence context notices this change

entityManager.remove(user);    // now REMOVED — DELETE scheduled

// after the transaction commits and the EntityManager closes:
// user is now DETACHED
```

## Dirty checking: why you never call `update()`

This is the behavior that surprises people coming from plain JDBC: for a **managed** entity, you don't call any method to save a field change. At flush time (end of transaction, or an explicit `entityManager.flush()`), Hibernate compares the entity's current field values against a snapshot it took when the entity became managed, and generates `UPDATE` statements only for the fields that actually changed. This comparison process is called **dirty checking**, and it's the mechanism that makes this pattern work in a `@Service` method:

```java
@Transactional
public void changeEmail(Long userId, String newEmail) {
    User user = userRepository.findById(userId).orElseThrow(); // now MANAGED
    user.setEmail(newEmail); // just a setter call — no save()
    // transaction commits at method exit → dirty checking fires → UPDATE generated
}
```

`findById` returns a managed entity (as long as you're inside a transaction, tying back to your `@Transactional`/proxy lesson). The setter mutates a plain Java field. Nothing about that setter call talks to the database — it's only at commit time that Hibernate asks "did anything change?" and issues SQL accordingly.

## `merge()`: reattaching a detached entity

A common real-world case: an entity gets loaded, sent out as a DTO or serialized somewhere, time passes, and you get data back representing changes to make — but the original managed object and persistence context are long gone. You can't just call a setter on a detached object and expect dirty checking to notice; there's no active persistence context watching it. `merge()` handles this:

```java
User detachedUser = ...; // has id=5, came from somewhere outside the current persistence context

User managedCopy = entityManager.merge(detachedUser);
// managedCopy is a DIFFERENT object reference, now MANAGED
// detachedUser itself remains DETACHED, untouched
```

Important detail: `merge()` does **not** make your original object managed. It copies the state from your detached object onto either an existing managed instance (if one for that id is already in the persistence context) or a freshly loaded one, and returns _that_ — a new reference. Continuing to use the original `detachedUser` variable afterward is a common bug, since it's still detached and still untracked.

## Lifecycle callback annotations

JPA defines callback methods you can place directly on the entity, each tied to a specific state transition:

```java
@Entity
public class User {

    @PrePersist
    public void prePersist() {
        this.createdAt = Instant.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = Instant.now();
    }

    @PreRemove
    public void preRemove() {
        // e.g. clean up related resources before deletion
    }

    @PostLoad
    public void postLoad() {
        // runs after the entity is loaded from the database
    }

    @PostPersist
    public void postPersist() {
        // runs after the INSERT actually happens
    }

    @PostRemove
    public void postRemove() {
        // runs after the DELETE actually happens
    }
}
```

The order relative to the SQL statement is in the names: `@PrePersist`/`@PreUpdate`/`@PreRemove` fire _before_ the corresponding SQL runs (so they're the right place to set a field that needs to be in the `INSERT`/`UPDATE`), while the `@Post*` variants fire _after_.

## External listeners: `@EntityListeners`

Instead of writing callback methods directly inside the entity class (which can bloat it, especially across many entities needing the same behavior), you can extract them into a separate listener class:

```java
public class TimestampListener {
    @PrePersist
    public void setCreatedAt(Object entity) {
        if (entity instanceof Auditable a) {
            a.setCreatedAt(Instant.now());
        }
    }
}
```

```java
@Entity
@EntityListeners(TimestampListener.class)
public class User { ... }
```

This is exactly the shape Spring Data auditing uses internally: `@EnableJpaAuditing` registers `AuditingEntityListener` as an `@EntityListener` behind the scenes, and that listener's `@PrePersist`/`@PreUpdate` methods are what actually populate your `@CreatedDate`/`@LastModifiedDate` fields. Your auditing lesson covered the annotations you put on fields; this is the mechanism that makes those annotations work — a listener class hooking the exact same `@PrePersist`/`@PreUpdate` callbacks you could write yourself.

## `detach()`, `clear()`, and `refresh()`

Three more `EntityManager` operations worth knowing precisely:

- **`detach(entity)`** — removes one specific entity from the persistence context. It becomes detached; further changes to it are untracked. Useful when you've loaded something just to read it and don't want it accidentally flushed if mutated later.
- **`clear()`** — detaches _everything_ the persistence context is currently tracking, in one call. Common in batch-processing loops to avoid memory buildup from an ever-growing first-level cache.
- **`refresh(entity)`** — the opposite direction: discards any in-memory changes on a managed entity and reloads its state fresh from the database, overwriting whatever local modifications were made. Used when you suspect another transaction changed the row and you need the current truth rather than your possibly-stale local copy.

## How this connects to your repository methods

Spring Data JPA's `save()` method (from `SimpleJpaRepository`, which you've already seen is a JDK dynamic proxy) isn't a separate operation — it's a thin wrapper that checks whether the entity's id is null (or matches `@Version`/new-entity detection rules) and calls either `persist()` or `merge()` underneath:

```java
// roughly what SimpleJpaRepository.save() does
public <S extends T> S save(S entity) {
    if (isNew(entity)) {
        entityManager.persist(entity);
        return entity;
    } else {
        return entityManager.merge(entity);
    }
}
```

This is why calling `save()` on an entity you just loaded from `findById()` (already managed) is often redundant — dirty checking would have persisted your setter changes at commit time regardless, `save()` or not. It's not wrong to call it, just unnecessary for already-managed entities; it earns its keep mainly for transient entities (first save) or detached ones (needing the `merge()` path).

[[Spring Framework]]
