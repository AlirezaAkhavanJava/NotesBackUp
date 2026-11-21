- Fetch Type: Defines when the related entity should be loaded from the database. `LAZY` loads it when needed; `EAGER` requires it to be fetched with the entity.

- Cascade: Defines which operations on one entity should also be applied to its related entities, such as saving, updating, or deleting.

## 1. The Core Mental Model

When two entities are related, there are two separate concerns:

1. **Loading data:** When should the related entity be retrieved from the database?
    
2. **Propagating operations:** Should an operation on one entity also be applied to the related entity?
    

These concerns are controlled by different annotations' attributes.

|Concern|Configuration|Main question|
|---|---|---|
|Loading related entities|`FetchType`|When should related data be loaded?|
|Propagating persistence operations|`CascadeType`|Which operations should propagate to related entities?|

**Remember:**

> Fetch controls loading. Cascade controls operation propagation.

Neither determines the cardinality or ownership of the relationship. Those are separate parts of JPA mapping.

---

# Part 1 — Fetch Type

## 2. What Is Fetch Type?

Fetch type determines when Hibernate retrieves an associated entity or collection relative to loading the entity that references it.

Consider a cinema application:

- A `Movie` has many `Showtime` objects.
    
- Each `Showtime` belongs to one `Movie`.
    

```
@Entity
public class Showtime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "movie_id")
    private Movie movie;
}
```

Suppose you execute:

```
Showtime showtime = entityManager.find(Showtime.class, 1L);
```

You want the showtime, but do you always need the complete movie data immediately?

Perhaps you only need the showtime's ID and start time.

Fetch type lets you control this loading behavior.

JPA defines two fetch types:

- `FetchType.EAGER`
    
- `FetchType.LAZY`
    

## 3. `FetchType.EAGER`

**Definition:** The associated entity or collection must be fetched as part of the eager-fetching requirement when the owner is loaded. The provider may retrieve it using a join or separate SQL queries.

Example:

```
@ManyToOne(fetch = FetchType.EAGER)
@JoinColumn(name = "movie_id")
private Movie movie;
```

Conceptually, when loading a showtime, Hibernate must also make its associated movie available.

Possible SQL strategy:

```
SELECT
    s.id,
    s.movie_id,
    m.id,
    m.title
FROM showtime s
JOIN movie m ON m.id = s.movie_id
WHERE s.id = 1;
```

Hibernate may instead issue multiple queries. `EAGER` does not guarantee that Hibernate will use a SQL join.

### When should I use EAGER?

Use eager fetching when the association genuinely needs to be available whenever the entity is loaded and that loading behavior is appropriate for your application's access patterns.

However, avoid making every relationship eager by default.

Eager loading can retrieve data that a particular operation does not need. It can also cause additional queries and inefficient data retrieval.

## 4. `FetchType.LAZY`

**Definition:** The provider is allowed to defer loading the associated entity or collection until it is accessed.

Example:

```
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "movie_id")
private Movie movie;
```

Now consider:

```
Showtime showtime = entityManager.find(Showtime.class, 1L);

System.out.println(showtime.getId());
```

If the movie association has not been initialized, Hibernate may load only the showtime initially.

When you later execute:

```
System.out.println(showtime.getMovie().getTitle());
```

Hibernate may issue another query to retrieve the movie.

Conceptually:

```
-- Initial load
SELECT id, movie_id
FROM showtime
WHERE id = 1;

-- Later, when the movie is accessed
SELECT id, title
FROM movie
WHERE id = ?;
```

The exact SQL depends on the mapping, provider, and query.

### How to think about LAZY

Ask yourself:

"Does every operation that loads this entity need its related data immediately?"

If the answer is no, lazy fetching is often a good starting point.

For example, a page showing only showtime IDs and start times may not need complete movie details.

### Important limitation

Lazy fetching does not mean that related data is never loaded. It means loading can be deferred.

If you access an uninitialized lazy association after the persistence context has closed, Hibernate may throw a `LazyInitializationException`.

Fetch the required associations while the persistence context is active, or explicitly retrieve the data needed by your query or service.

---

## 5. The Default Fetch Types

JPA specifies different defaults for different relationship annotations.

|Relationship|Default fetch type|
|---|---|
|`@ManyToOne`|`EAGER`|
|`@OneToOne`|`EAGER`|
|`@OneToMany`|`LAZY`|
|`@ManyToMany`|`LAZY`|

These are JPA defaults, not a guarantee that every association will use one SQL statement.

For example:

```
@ManyToOne
private Movie movie;
```

defaults to eager fetching.

But:

```
@OneToMany(mappedBy = "movie")
private List<Showtime> showtimes;
```

defaults to lazy fetching.

You can explicitly specify a fetch type when it improves readability or establishes the intended mapping behavior.

**Practical starting point:** Prefer lazy associations where the mapping allows it, then explicitly fetch the relationships required by each use case. `@ManyToOne` and `@OneToOne` default to eager, so consider explicitly setting them to `LAZY` when appropriate.

Note that JPA defines `LAZY` as a hint for to-one associations, whereas `EAGER` is a requirement.

---

# Part 2 — Cascade Type

## 6. What Is Cascade?

Cascade determines whether certain persistence operations performed on one entity should propagate to its associated entities.

Imagine a user and a watchlist:

- Each `AppUser` has one `Watchlist`.
    
- Each `Watchlist` belongs to one `AppUser`.
    

Suppose you create a new user and a new watchlist together.

You want to save the user. Should you also have to explicitly persist the watchlist?

Cascade lets you define whether that operation propagates.

Example:

```
@OneToOne(
    mappedBy = "user",
    cascade = CascadeType.PERSIST
)
private Watchlist watchlist;
```

This mapping means that persisting the `AppUser` also propagates the persist operation to its associated watchlist.

Notice that cascade is independent of fetching.

You can fetch an association lazily and still cascade persistence operations to it.

## 7. The Six Cascade Types

JPA provides these cascade operations:

|Cascade type|Meaning|
|---|---|
|`PERSIST`|Propagate a persist operation|
|`MERGE`|Propagate a merge operation|
|`REMOVE`|Propagate a remove operation|
|`REFRESH`|Propagate a refresh operation|
|`DETACH`|Propagate a detach operation|
|`ALL`|Propagate all the operations above|

Let's understand each one.

### 7.1. `CascadeType.PERSIST`

**Question:** If I persist this entity, should the associated new entity also be persisted?

```
@OneToOne(
    mappedBy = "user",
    cascade = CascadeType.PERSIST
)
private Watchlist watchlist;
```

Example:

```
AppUser user = new AppUser();
Watchlist watchlist = new Watchlist();

user.setWatchlist(watchlist);
watchlist.setUser(user);

entityManager.persist(user);
```

With the cascade configured on `AppUser.watchlist`, persisting the user propagates the persist operation to the watchlist.

Without this cascade, you generally need to persist the new watchlist separately, unless another configured mechanism handles it.

The relationship must also be mapped and maintained correctly.

### 7.2. `CascadeType.MERGE`

**Question:** If I merge this entity, should the merge operation also propagate to its associated entities?

```
@OneToOne(
    mappedBy = "user",
    cascade = CascadeType.MERGE
)
private Watchlist watchlist;
```

Merge is relevant when working with detached entity state that needs to be copied into a managed entity.

It is not simply another name for updating a database row. The entity returned by `merge()` is the managed instance.

Use this cascade when merging the parent should also merge the associated entity.

### 7.3. `CascadeType.REMOVE`

**Question:** If I remove this entity, should its associated entity also be removed?

```
@OneToOne(
    mappedBy = "user",
    cascade = CascadeType.REMOVE
)
private Watchlist watchlist;
```

When the user is removed, the remove operation propagates to the associated watchlist.

This does not mean that every foreign key is automatically deleted by cascade. The behavior depends on the JPA relationship mapping and database constraints.

**Warning:** Use remove cascading only when the associated entity should genuinely be deleted along with the parent.

For example, deleting an employee should not normally delete the department shared by many employees.

### 7.4. `CascadeType.REFRESH`

**Question:** If I refresh this entity from the database, should the refresh operation also propagate to its associations?

```
@OneToOne(cascade = CascadeType.REFRESH)
private Watchlist watchlist;
```

Refresh reloads the state of a managed entity from the database. Cascading refresh propagates that operation to the associated entity.

This is useful in specialized persistence workflows, but many applications rarely need to configure it explicitly.

### 7.5. `CascadeType.DETACH`

**Question:** If I detach this entity from the persistence context, should its associated entities also be detached?

```
@OneToOne(cascade = CascadeType.DETACH)
private Watchlist watchlist;
```

A detached entity is no longer managed by the current persistence context.

Cascading detach propagates that operation to the associated entity.

Like refresh, this is less commonly configured explicitly in typical Spring Boot CRUD applications.

### 7.6. `CascadeType.ALL`

**Question:** Should all the standard cascade operations propagate to this association?

```
@OneToOne(
    mappedBy = "user",
    cascade = CascadeType.ALL
)
private Watchlist watchlist;
```

`ALL` includes:

- `PERSIST`
    
- `MERGE`
    
- `REMOVE`
    
- `REFRESH`
    
- `DETACH`
    

It is convenient when the associated entity's lifecycle is tightly coupled to the parent.

But it is not a universal best practice. In particular, it includes `REMOVE`, which can have serious consequences if the relationship is not truly dependent.

---

## 8. Cascade Is About Lifecycle, Not Cardinality

Consider two relationships.

### Example A: User and Watchlist

A watchlist is private to one user and has no independent purpose in the application.

It may make sense for creating a user to create the watchlist, and for deleting the user to delete the watchlist.

Depending on your domain rules, `CascadeType.ALL` might be appropriate.

### Example B: Showtime and Movie

Many showtimes belong to one movie.

If you delete a showtime, should the movie be deleted?

No. The movie may have many other showtimes.

Therefore, you would normally avoid `CascadeType.REMOVE` from `Showtime` to `Movie`.

The general rule is:

> Cascade operations when the associated entity should participate in the parent's persistence lifecycle. Do not cascade merely because two entities are related.

---

## 9. Cascade and Fetch Type Are Independent

Consider:

```
@OneToOne(
    fetch = FetchType.LAZY,
    cascade = CascadeType.ALL
)
@JoinColumn(name = "watchlist_id")
private Watchlist watchlist;
```

The two settings have different jobs:

- `fetch = FetchType.LAZY`: the watchlist may be loaded when it is accessed.
    
- `cascade = CascadeType.ALL`: persistence operations on the owning entity may propagate to the watchlist.
    

Lazy fetching does not disable cascading.

Eager fetching does not imply cascading.

Neither setting determines which side owns the relationship.

Also, `CascadeType.ALL` does not mean that every database operation is automatically propagated. It refers to the six JPA cascade operations listed above.

---

## 10. Orphan Removal Is Different From Cascade REMOVE

This distinction matters for parent-child relationships.

Suppose a user owns a watchlist, and the watchlist contains items.

```
@OneToMany(
    mappedBy = "watchlist",
    cascade = CascadeType.ALL,
    orphanRemoval = true
)
private List<WatchlistItem> items = new ArrayList<>();
```

Here:

- `cascade = CascadeType.ALL` propagates the configured entity operations.
    
- `orphanRemoval = true` tells JPA to remove a privately owned child when it is removed from the relationship, subject to the JPA orphan-removal rules.
    

For example, removing a watchlist item from the collection can cause that item to be deleted when the change is synchronized with the database.

Use orphan removal only when a child should not survive independently after being disassociated from its parent.

It is especially useful for privately owned child entities such as order lines or watchlist items.

---

## 11. A Practical Decision Workflow

Whenever you map a relationship, ask these questions in order.

### Fetching

1. When I load this entity, do I need the related entity immediately?
    
2. If not, can I use lazy fetching?
    
3. Which associations does each repository query or service operation actually need?
    
4. Can I fetch those associations explicitly rather than loading everything by default?
    

### Cascading

1. If I persist the parent, should the child also be persisted?
    
2. If I merge the parent, should the child also be merged?
    
3. If I delete the parent, should the child also be deleted?
    
4. Is the child privately owned, or does it have an independent lifecycle?
    
5. Would `ALL` perform any operations that should not propagate?
    

Choose only the cascade operations your domain requires.

---

## 12. Quick Reference

|Scenario|Typical choice|
|---|---|
|A showtime references a movie|Consider `LAZY`; avoid remove cascade to the movie|
|A user owns a private watchlist|Consider `LAZY`; cascade based on lifecycle requirements|
|An order owns its order lines|Often `ALL` with orphan removal, if the lines are privately owned|
|Many employees reference one department|Usually no cascade remove to the department|
|A post has privately owned comments|Cascade decisions depend on whether comments should be deleted with the post|
|A many-to-many association connects shared entities|Avoid cascading remove to shared entities|

These are starting points. Your domain rules, query patterns, and database constraints determine the final configuration.

---

## 13. Final Mental Model

When you see a relationship between two entities, think in three separate dimensions:

1. **Mapping:** Which entity owns the database relationship? (`@JoinColumn` and `mappedBy`)
    
2. **Fetching:** When should the related data be loaded? (`FetchType`)
    
3. **Lifecycle:** Which persistence operations should propagate? (`CascadeType` and, when appropriate, `orphanRemoval`)
    

For example:

```
@OneToMany(
    mappedBy = "watchlist",
    fetch = FetchType.LAZY,
    cascade = CascadeType.ALL,
    orphanRemoval = true
)
private List<WatchlistItem> items = new ArrayList<>();
```

Read this as:

- `mappedBy = "watchlist"`: the `WatchlistItem.watchlist` field maps the relationship.
    
- `fetch = LAZY`: defer loading the collection when possible.
    
- `cascade = ALL`: propagate the standard JPA lifecycle operations.
    
- `orphanRemoval = true`: remove items that are orphaned from this privately owned collection.
    

**The rule to remember:**

> Fetch controls when related data is loaded. Cascade controls which persistence operations propagate. Ownership controls which side maps the database relationship.

Keep these concepts separate, and JPA entity mapping becomes much easier to reason about.


[[Spring Framework]]