The N+1 problem is the most common real-world JPA performance bug, and it sits right at the intersection of relationships (your bidirectional/unidirectional lesson), lazy loading, and the persistence context machinery you now understand from the last few lessons. Let's see exactly how it happens and the real fixes.

## What "N+1" literally means

Say you have this relationship:

```java
@Entity
public class Author {
    @Id
    private Long id;
    private String name;

    @OneToMany(mappedBy = "author")
    private List<Book> books;
}
```

And you run:

```java
List<Author> authors = authorRepository.findAll(); // query #1: SELECT * FROM author

for (Author author : authors) {
    System.out.println(author.getBooks().size()); // triggers one query PER author
}
```

If `findAll()` returns 50 authors, you get: **1** query to fetch the authors, plus **N** (50) additional queries — one per author — to fetch each author's `books` collection when it's first accessed in the loop. Total: 51 queries, where a well-written version needs exactly 1 or 2. That's the "N+1" name — one query for the parent rows, N more for the children, where a single join could have gotten everything at once.

## Why it happens: lazy loading, by default, for collections

`@OneToMany` and `@ManyToMany` default to `FetchType.LAZY`. When Hibernate loads an `Author`, it doesn't load `books` at all — it installs a **proxy** collection (one of those `PersistentBag`/`PersistentSet` wrappers from your dirty-checking lesson) that knows how to fetch the real data, but hasn't yet. The moment you call `.size()`, `.iterator()`, or anything else that actually needs the data, that proxy fires off a fresh `SELECT ... WHERE author_id = ?` for that one author, right then and there.

This is entirely correct behavior in isolation — lazy loading one relationship, on demand, is usually what you want. The problem is purely about doing it **inside a loop over many parents**, where "on demand" becomes "once per iteration."

`@ManyToOne` and `@OneToOne`, by contrast, default to `FetchType.EAGER` — so the N+1 pattern most commonly shows up specifically on collection-valued relationships, not single-reference ones. (Though eager fetching has its own version of this problem, covered below.)

## Fix 1: `JOIN FETCH` — the standard, explicit fix

The most direct fix is writing the query yourself to explicitly pull the association in the same `SELECT`, using JPQL's `JOIN FETCH`:

```java
public interface AuthorRepository extends JpaRepository<Author, Long> {

    @Query("SELECT DISTINCT a FROM Author a LEFT JOIN FETCH a.books")
    List<Author> findAllWithBooks();
}
```

This produces one `SELECT` with a SQL `JOIN`, and Hibernate populates each `Author`'s `books` collection directly from the joined result set — no proxy, no follow-up query. The `DISTINCT` matters here: a SQL join against a one-to-many naturally produces one result row _per matching book_, so an author with 3 books appears 3 times in the raw JDBC result set; `DISTINCT` (applied at the JPQL/object level by Hibernate, not just the SQL level) collapses those duplicate `Author` objects back down to one per author in the returned `List`.

## Fix 2: `@EntityGraph` — declarative, reusable

`JOIN FETCH` requires writing a custom JPQL query for every access pattern you need. `@EntityGraph` lets you declare "when you fetch this entity, also eagerly pull these associations" without writing JPQL at all:

```java
public interface AuthorRepository extends JpaRepository<Author, Long> {

    @EntityGraph(attributePaths = {"books"})
    List<Author> findAll(); // overrides the inherited findAll() with the graph applied
}
```

Spring Data JPA translates this into the equivalent fetch-join query automatically. `@EntityGraph` is generally preferred over hand-written `JOIN FETCH` when the only goal is "eagerly load this relationship for this one query method" — it's less code and doesn't require you to write JPQL just to add a join.

## Fix 3: `@BatchSize` — reduce N to N/k, without eliminating it

Sometimes a full join isn't appropriate (e.g., you genuinely don't always need the collection, and eagerly joining it on every single-entity load would be wasteful). `@BatchSize` offers a middle ground: instead of one query per parent, Hibernate batches the lazy-loading into groups.

```java
@Entity
public class Author {
    @OneToMany(mappedBy = "author")
    @org.hibernate.annotations.BatchSize(size = 10)
    private List<Book> books;
}
```

With this, accessing the first author's `books` still triggers a query — but that query uses `WHERE author_id IN (?, ?, ?, ...)` for up to 10 authors' worth of ids at once (typically the ones already loaded into the persistence context), rather than one `author_id = ?` per author. For 50 authors, this turns 50 follow-up queries into 5. It doesn't eliminate the extra round-trips the way a join does, but it's a meaningful reduction with minimal code change, and it's useful specifically when eager-joining would pull in too much data for cases where the collection isn't actually accessed.

## Eager fetching isn't automatically safe either

It's tempting to think "just make it `FetchType.EAGER` and the problem goes away" — but eager fetching doesn't prevent N+1, it just moves _when_ the extra queries happen, and sometimes makes it worse:

```java
@OneToMany(mappedBy = "author", fetch = FetchType.EAGER)
private List<Book> books;
```

Without an explicit join, Hibernate still has to issue a separate `SELECT` for each author's books — it just does it immediately upon loading the author instead of on first access. The `findAll()` loop from the very first example still produces 51 queries; they just all fire during `findAll()` itself instead of spread across your `for` loop. `FetchType` controls _timing_ (now vs. later), not _strategy_ (separate query vs. join) — only `JOIN FETCH`/`@EntityGraph` actually change the strategy to a single combined query.

## Detecting it: don't guess, measure

The practical way to catch N+1 before it reaches production is turning on SQL logging and literally counting statements for a given code path:

```properties
spring.jpa.show-sql=true
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE
```

A cleaner option for automated detection in tests is the `datasource-proxy` or `p6spy` libraries, or Hibernate's own statistics interface:

```java
Statistics stats = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
stats.setStatisticsEnabled(true);
// ... run the code path ...
System.out.println(stats.getPrepareStatementCount()); // should match expectations, not silently balloon
```

A query count that scales linearly with the size of a result set, rather than staying constant, is the signature to look for — whether you spot it by eyeballing logs or asserting a fixed statement count in a test.

[[Spring Framework]]
