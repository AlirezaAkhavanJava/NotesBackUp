


## 1. The Main Idea

When two entities are related, we have two choices:

- **Unidirectional:** One entity knows about the other.
    
- **Bidirectional:** Both entities know about each other through Java fields.
    

The important thing is that **you don't have to map a relationship in both directions**. You only add the reverse side when your application needs it.

## 2. Unidirectional Relationship

Imagine an `AppUser` has one `Watchlist`.

```java
// AppUser.java

@OneToOne
@JoinColumn(name = "watchlist_id")
private Watchlist watchlist;
```

That's enough to navigate from a user to their watchlist:

```
user.getWatchlist();
```

But you cannot do this:

```
watchlist.getUser();
```

unless `Watchlist` also has a mapped `user` field.

That's what unidirectional means: **one direction of navigation**.

## 3. Bidirectional Relationship

Now imagine you also need to access the user from the watchlist.

In `AppUser`:

```
@OneToOne
@JoinColumn(name = "watchlist_id")
private Watchlist watchlist;
```

In `Watchlist`:

```
@OneToOne(mappedBy = "watchlist")
private AppUser user;
```

Now you can navigate in both directions:

```
user.getWatchlist();

watchlist.getUser();
```

Notice that `mappedBy = "watchlist"` refers to the Java field named `watchlist` inside `AppUser`.

It does not refer to the database column name.

## 4. What About `@ManyToOne` and `@OneToMany`?

The same principle applies.

Imagine many `WatchlistItem` objects belong to one `Watchlist`.

In `WatchlistItem`:

```
@ManyToOne
@JoinColumn(name = "watchlist_id")
private Watchlist watchlist;
```

This already works. You do not need to add anything to `Watchlist`.

But if you want to retrieve all items through the watchlist, add this to `Watchlist`:

```
@OneToMany(mappedBy = "watchlist")
private List<WatchlistItem> items = new ArrayList<>();
```

Now you can navigate in both directions:

```
item.getWatchlist();

watchlist.getItems();
```

## 5. How Do I Decide?

Whenever you create a relationship, ask yourself:

**"Do I need to access the related entity from this direction?"**

- If no, keep the relationship unidirectional.
    
- If yes, consider adding the reverse mapping.
    

For example, if your service only needs to retrieve a watchlist from a user, you may not need `Watchlist.user`.

But if you frequently retrieve the owner from a watchlist, having that reverse mapping may be useful.

Don't add relationships just because you can. Every additional mapping introduces more complexity to maintain.

## 6. One Important Detail: Ownership

Bidirectional does not mean both sides own the database relationship.

For example:

```
// WatchlistItem.java — owning side
@ManyToOne
@JoinColumn(name = "watchlist_id")
private Watchlist watchlist;
```

```
// Watchlist.java — inverse side
@OneToMany(mappedBy = "watchlist")
private List<WatchlistItem> items = new ArrayList<>();
```

`WatchlistItem` owns the relationship because it maps the foreign key. `Watchlist` is the inverse side because it uses `mappedBy`.

Also, when changing a bidirectional relationship in Java, keep both sides synchronized if both are represented in memory.

## Final Mental Model

- **Unidirectional:** One entity has a reference to the other.
    
- **Bidirectional:** Both entities have references to each other.
    
- **Owning side:** Maps the database relationship.
    
- **Inverse side:** Uses `mappedBy` to refer to the owning side.
    

Remember: **Choose the direction based on how your application needs to navigate between entities, not because a particular annotation requires a reverse mapping.**


[[Spring Framework]]