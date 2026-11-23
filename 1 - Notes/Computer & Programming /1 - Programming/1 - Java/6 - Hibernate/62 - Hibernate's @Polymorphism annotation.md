

This one is a genuine Hibernate-specific annotation, and it has nothing to do with the OOP concept of polymorphism you already know from Java. It controls a completely different question: when you run a JPQL/HQL query against a parent entity in an inheritance hierarchy, should Hibernate also hand back rows belonging to the child entities, or should it pretend those children don't exist and return only the parent type? It lives in `org.hibernate.annotations.Polymorphism`, takes a `PolymorphismType`, and only affects query results — not your object model, not `find()` by ID, not `@DiscriminatorColumn`.

## Why this question even needs an answer

JPA's baseline assumption is that inheritance and querying go hand in hand: if `Dog` and `Cat` both extend `Animal`, then

```java
List<Animal> animals = entityManager
    .createQuery("from Animal", Animal.class)
    .getResultList();
```

is expected to return every `Animal`, every `Dog`, and every `Cat` — Hibernate resolves each row to its concrete subclass automatically. That's useful almost all the time, which is why it's the default. But it has a cost: Hibernate has to go find all the subclass data too, which, depending on your inheritance strategy, can mean extra joins or an outright `UNION` across several tables. `@Polymorphism` exists so you can say "no, I specifically do not want that automatic subclass inclusion" when the cost isn't worth it, or when a hierarchy is structured in a way where mixing parent and child results would actually be wrong for your use case.

## The two modes

```java
@Entity
@Polymorphism(type = PolymorphismType.IMPLICIT) // default
public class Animal { }
```

**`IMPLICIT`** is the behavior you'd get even without this annotation — it's just making the default explicit. A query on the parent type returns the parent and every subclass, and Hibernate figures out which concrete class each row belongs to. This works the same way under all three inheritance strategies (`SINGLE_TABLE`, `JOINED`, `TABLE_PER_CLASS`); only the SQL generated to achieve it differs.

```java
@Entity
@Polymorphism(type = PolymorphismType.EXPLICIT)
public class Animal { }
```

**`EXPLICIT`** switches that off. `from Animal` now returns _only_ rows that are genuinely `Animal` — no `Dog`, no `Cat`. If you want the subclasses, you ask for them by name: `from Dog`, `from Cat`. The parent query becomes narrower and, depending on strategy, cheaper.

## What changes under the hood, per strategy

This is where `EXPLICIT` actually earns its keep — the savings aren't abstract, they're concrete SQL differences:

- **`SINGLE_TABLE`** — `IMPLICIT` lets the discriminator column select every row regardless of type; `EXPLICIT` filters the discriminator down to just the parent's value.
- **`JOINED`** — `IMPLICIT` joins the parent table to every child table to assemble full subclass rows; `EXPLICIT` queries the parent table alone, no joins.
- **`TABLE_PER_CLASS`** — `IMPLICIT` has to `UNION` across the parent table and every child table, since each maps to its own table entirely; `EXPLICIT` skips the union and hits only the parent's table.

That last one is the case people usually reach for `EXPLICIT` because of: `TABLE_PER_CLASS` with `IMPLICIT` polymorphism on a parent query with many subclasses can generate a surprisingly expensive `UNION` across every single one, even when all you wanted was the parent rows.

## Where the limits are

A few things this annotation does _not_ do, worth being precise about:

- It's Hibernate-only — not part of the JPA spec, so it's silently ignored if you ever switch persistence providers.
- It has no effect on `entityManager.find(Animal.class, id)` — that always fetches exactly the entity you asked for by its id and type, polymorphic query behavior doesn't enter into it.
- It has no effect on a query that already names the subclass directly (`from Dog`) — there's nothing implicit or explicit to resolve there.
- It only governs HQL/JPQL queries run against the parent type specifically.

## When to actually flip it to `EXPLICIT`

The honest default advice is: don't, unless you have a specific reason. `IMPLICIT` matches what JPA developers expect and is correct for the overwhelming majority of hierarchies. Reach for `EXPLICIT` when you have a large or deep hierarchy, parent-level queries sit on a hot path and the extra joins/unions show up in profiling, or the subclasses represent data different enough in meaning that mixing them into one result set would be a modeling mistake rather than a convenience.

**Related, briefly:** don't confuse this with `@DiscriminatorColumn` — that annotation defines _how_ Hibernate tells subclasses apart in `SINGLE_TABLE` (which column, which value per subclass); `@Polymorphism` is a layer above that, deciding whether a query is even allowed to return more than one of those discriminated types at once.


[[Hibernate & JDBC]]