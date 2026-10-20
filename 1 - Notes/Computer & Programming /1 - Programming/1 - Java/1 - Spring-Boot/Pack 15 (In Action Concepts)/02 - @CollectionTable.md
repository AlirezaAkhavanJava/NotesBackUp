

A movie has many actors. But one cell in a table can hold only one value. You can't put a whole list in one cell.

So we make a **second table** just for the actors. `@CollectionTable` is how you describe that second table.

## What the tables look like

This is the `movies` table:

|id|title|
|---|---|
|1|Oppenheimer|
|2|Barbie|

This is the second table, `movie_cast`:

|movie_id|position|actor_name|
|---|---|---|
|1|0|Cillian Murphy|
|1|1|Emily Blunt|
|2|0|Margot Robbie|

Look at the `movie_id` column. It says which movie each actor belongs to. Rows 1 and 2 belong to movie 1 (Oppenheimer). The last row belongs to movie 2 (Barbie).

## The code, line by line

```java
@ElementCollection
@CollectionTable(name = "movie_cast", joinColumns = @JoinColumn(name = "movie_id"))
@OrderColumn(name = "position")
@Column(name = "actor_name")
private List<String> cast = new ArrayList<>();
```

**`@ElementCollection`** means "this field is a list of simple values", like text or numbers. It starts the whole idea.

**`@CollectionTable`** describes the second table. It has two parts:

- `name = "movie_cast"` is the name of the second table.
- `joinColumns = @JoinColumn(name = "movie_id")` is the column that points back to the movie. It stores the movie's id. A column that points to a row in another table is called a **foreign key**.

**`@OrderColumn`** adds the `position` column. It remembers the order, so the lead actor stays first.

**`@Column(name = "actor_name")`** is the name of the column that holds each actor's name.

## Why write it at all?

If you skip `@CollectionTable`, Hibernate still works. It just picks its own names for the table and column. We choose the names ourselves so the database is easy to read.

## What happens when the app runs

- **Saving:** you add names to the `cast` list and save the movie. Hibernate adds the rows to `movie_cast` for you.
- **Reading:** you call `movie.getCast()`. Hibernate finds the rows in `movie_cast` where `movie_id` equals this movie's id, and gives you a normal Java list.

You never write SQL for this.



---
## 1. The big picture

A database table is a grid. Each cell holds **one** value. A Java `List<String>` holds **many** values. These two don't fit together.

The fix is to move the list into its own small table. Each item in the list becomes one row. Each row has a number that says which parent it belongs to.

`@CollectionTable` is the annotation that describes that small table: its name, and how it connects back to the parent.

## 2. The team of annotations

`@CollectionTable` never works alone. Here is the whole team from your `Movie` class:

|Annotation|Its job|
|---|---|
|`@ElementCollection`|Says "this field is a list of simple values". It starts everything.|
|`@CollectionTable`|Names the second table and says how it links to the parent.|
|`@JoinColumn`|Names the column that stores the parent's id (the link).|
|`@OrderColumn`|Adds a column that remembers the order of the items.|
|`@Column`|Names the column that holds each value.|

Think of it like this: `@ElementCollection` says _what_, `@CollectionTable` says _where_, and the others fill in the details.

## 3. What Hibernate builds

For `cast`, Hibernate creates something like this:

```sql
create table movie_cast (
    movie_id   bigint       not null,   -- link to movies.id
    position   integer      not null,   -- order in the list
    actor_name varchar(200) not null,   -- the value itself
    primary key (movie_id, position)
);
-- plus a foreign key: movie_id -> movies.id
```

Three things to notice:

- **`movie_id` is a foreign key.** A foreign key is a column that points to a row in another table. The database will refuse a row with a `movie_id` that doesn't exist in `movies`.
- **The primary key is two columns together** (`movie_id` + `position`). That means "movie 1, position 0" can only exist once.
- **That primary key only exists because of `@OrderColumn`.** Without it, the table has no primary key at all.

## 4. All the settings of `@CollectionTable`

You used two. Here are all of them:

|Setting|What it does|Example|
|---|---|---|
|`name`|The table name.|`"movie_cast"`|
|`joinColumns`|The column(s) that link back to the parent.|`@JoinColumn(name = "movie_id")`|
|`schema`|Puts the table in a certain PostgreSQL schema.|`"public"`|
|`catalog`|Same idea for databases that use catalogs. You won't need it with PostgreSQL.||
|`uniqueConstraints`|Rules like "no repeated value for the same movie".|see below|
|`indexes`|Makes searches on certain columns faster.|see below|
|`foreignKey`|Lets you name or change the foreign key.|rarely needed|

Two useful examples:

```java
// An actor can only appear once per movie
@CollectionTable(
    name = "movie_cast",
    joinColumns = @JoinColumn(name = "movie_id"),
    uniqueConstraints = @UniqueConstraint(columnNames = {"movie_id", "actor_name"})
)

// Faster searches by actor name
@CollectionTable(
    name = "movie_cast",
    joinColumns = @JoinColumn(name = "movie_id"),
    indexes = @Index(columnList = "actor_name")
)
```

An **index** is like the index at the back of a book. It lets the database jump straight to a value instead of reading every row. You only need it if you search by that column a lot, for example "find movies with this actor".

## 5. What if you skip it?

Hibernate still works. It makes up names for you. They would be roughly `movie_cast` for the table, `movie_id` for the link, and `cast` for the value column.

We set the names ourselves for three reasons:

- You can read the database and know what everything is.
- `cast` is also an SQL word (a function), which can cause confusion. `actor_name` is clearer.
- If you add Flyway later, your SQL files must match these names exactly. Names you chose yourself won't change unexpectedly.

## 6. How saving, reading, and deleting work

The small table belongs completely to the movie. It has no life of its own.

|You do this|Hibernate does this|
|---|---|
|Save a new movie with a cast list|Inserts the movie row, then one row per actor.|
|Read `movie.getCast()`|Runs a query on `movie_cast` where `movie_id` equals this movie.|
|Add an actor to the list|Inserts one new row.|
|Remove an actor from the list|Deletes that row (and may update the positions after it).|
|Delete the movie|Deletes all its `movie_cast` rows first, then the movie.|

You don't need `cascade` settings. For element collections, this happens automatically.

**About `@OrderColumn`:** without it, Hibernate treats the list as an unordered "bag". Any change to a bag can make Hibernate delete **all** the rows for that movie and insert them again. With `@OrderColumn`, it can change only the rows that moved. It also keeps your actor order safe.

## 7. Lazy loading, and the error you might see

By default, the list is loaded **lazily**. That means Hibernate does not load the actors when it loads the movie. It waits until you actually call `getCast()`.

This is good for speed. But there is a catch. Lazy loading only works while the database session is still open. If you touch the list too late, you get this error:

```
LazyInitializationException: could not initialize proxy - no Session
```

In the last message, I told you to set `spring.jpa.open-in-view=false`. That makes this rule strict. So the fix is simple:

- Do the conversion from `Movie` to `MovieResponse` **inside a service method** marked `@Transactional(readOnly = true)`.
- Never return a `Movie` entity straight from the controller.

That is exactly the plan we already have, so you are on the right track.

## 8. The N+1 problem

Imagine you load 50 movies, and then read `getCast()` and `getAwards()` for each one:

- 1 query for the movies
- 50 queries for the casts
- 50 queries for the awards

That's 101 queries for one page. This is called the **N+1 problem**, and it's the most common speed problem with collections.

The easiest fix is `@BatchSize`:

```java
@ElementCollection
@CollectionTable(name = "movie_cast", joinColumns = @JoinColumn(name = "movie_id"))
@OrderColumn(name = "position")
@Column(name = "actor_name", nullable = false, length = 200)
@BatchSize(size = 50)
private List<String> cast = new ArrayList<>();
```

Now Hibernate loads the casts for up to 50 movies in **one** query. You don't need this today with a small catalog, but it's good to know it exists.

A trap to avoid: don't make both lists `EAGER` (loaded immediately). Hibernate will throw `MultipleBagFetchException`. Stay with the lazy default.

## 9. What element collections cannot do

A collection table holds simple values only. So:

- Items have **no id** of their own.
- You can't load an actor by itself (no `findById` for an actor name).
- Other entities can't point to one item.
- Two movies don't share the same actor row. Each movie has its own copy of the name.

This is fine for cast names and awards. It stops being fine if you want an **Actor page** with a photo, a birth date, and a list of all their movies. Then actors need to be real entities.

## 10. How to look at the data yourself

After the app runs and you've added some movies, try this in the IntelliJ database console:

```sql
SELECT m.title, c.position, c.actor_name
FROM movies m
JOIN movie_cast c ON c.movie_id = m.id
ORDER BY m.id, c.position;
```

You'll see one row per actor, in order. To watch Hibernate's SQL while the app runs, add this to `application.properties`:

```properties
spring.jpa.show-sql=true
```

## 11. Common mistakes

- **Forgetting `= new ArrayList<>()`.** Without it, the list can be `null` and `getCast().add(...)` crashes.
- **Touching the list outside a transaction.** This causes the lazy error from section 7.
- **Making a list longer than the column.** `length = 200` means a name over 200 characters fails.
- **Changing the table name later** without updating your SQL files, if you use Flyway.

## 12. Quick recap

- `@ElementCollection` marks the list. `@CollectionTable` names the second table and its link column.
- Each item becomes a row. `movie_id` says which movie it belongs to.
- `@OrderColumn` keeps the order and makes updates smarter.
- The list is lazy. Convert to a DTO inside a `@Transactional(readOnly = true)` service method.
- Use `@BatchSize` if you ever see too many queries.





[[Spring Framework]]