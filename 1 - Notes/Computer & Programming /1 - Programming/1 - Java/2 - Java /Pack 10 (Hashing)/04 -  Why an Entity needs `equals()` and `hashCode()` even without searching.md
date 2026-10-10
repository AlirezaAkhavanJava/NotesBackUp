


## First, a correction to the mental model

Hashing is how `HashMap` **uses** these methods for searching, but the methods themselves answer a more basic question:

- **`equals()`**: "Are these two Java objects the _same thing_?"
- **`hashCode()`**: "Give me a number that is the same for things that are the same."

Searching is just one consumer. Anything that ever asks "is this the same thing?" needs them, even if you never write a search.

And honestly, **you don't _need_ to override them** if nothing ever asks that question. The default (`Object`) says "same thing" only if it's literally the same object in memory. The real question is: does your code ever compare entities?

## Why entities specifically

A database row with `id = 5` is _one_ thing. But in Java you can end up with **two different objects** representing it:

1. In one request you load `User` #5, which is object A.
2. In another request or transaction, you load `User` #5 again, which is object B.
3. `A == B` is `false`, and the default `A.equals(B)` is also `false`.
4. But both are the same database row, so logically they _should_ be equal.

Overriding `equals()` lets you say: "two entities are the same if they represent the same row."

## Where this bites you with no "searching" at all

```java
// 1. Sets: dedupe is equality, not searching
Set<Role> roles = user.getRoles();   // @ManyToMany Set<Role>
roles.add(adminRole);
roles.add(adminRole2);               // same row, different object -> duplicate!

// 2. List methods use equals() only (no hash involved)
orders.contains(order);
orders.remove(order);                // silently removes nothing if equals is wrong

// 3. Tests
assertEquals(expectedUser, actualUser);   // fails with the default equals
```

Case 1 matters most in Spring Boot: JPA relationships like `@OneToMany` and `@ManyToMany` are commonly declared as `Set<...>`, and a `HashSet` uses both methods internally, so a bad implementation causes duplicates or lost elements.

Note that Hibernate itself tracks entities by **type + id** internally, not by your `equals()`. So you aren't overriding these methods to make Hibernate work. You're doing it for **your code** and for collections.

## The JPA trap (the part that surprises everyone)

The obvious implementation is based on `id`. The problem:

1. You create `new User()`, and its `id` is `null`.
2. You add it to a `HashSet`. `hashCode()` is computed from `id = null`, so it goes into bucket X.
3. You save it, and the database generates `id = 5`.
4. Now `hashCode()` returns a different number, so the object sits in bucket X but looks for itself in bucket Y. It's **lost**, which is exactly the "mutated key" bug from before.

So the common safe pattern is:

```java
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof User other)) return false;
        return id != null && id.equals(other.id);   // unsaved entities are never equal to each other
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();   // constant: stable before and after save
    }
}
```

Why this works:

- `equals()` compares by `id`, so two objects for row 5 are equal. An unsaved entity (`id == null`) equals only itself.
- `hashCode()` is a **constant**, so it never changes when the id gets assigned. The cost is that all entities of one type land in the same bucket. That's acceptable because entity collections are usually small, and correctness beats speed here.

The alternative is a **business key** (an immutable natural identifier like `email` or `isbn`), used in both methods. That gives a good hash distribution, but only works if such a field really is unique and never changes.

## Gotchas

- **Don't use Lombok's `@Data` or `@EqualsAndHashCode` on entities.** They include all fields, including lazy relationships, which can trigger extra queries or infinite recursion, and mutable fields break hashing.
- **Use `instanceof`, not `getClass() ==`,** because Hibernate wraps lazy-loaded entities in proxy subclasses, so `getClass()` comparisons fail.
- **Records are fine for DTOs, not entities.** JPA needs mutable, non-final classes with a no-arg constructor.

## Quick recap

- `equals()`/`hashCode()` define "same thing", not just "searching".
- Entities need them when you use `Set`s, `contains`/`remove`, or equality assertions.
- Default identity equality fails when the same row exists as two Java objects.
- Safe JPA pattern: compare by non-null `id` (or a natural key), and keep `hashCode()` stable.




[[Hashing]]