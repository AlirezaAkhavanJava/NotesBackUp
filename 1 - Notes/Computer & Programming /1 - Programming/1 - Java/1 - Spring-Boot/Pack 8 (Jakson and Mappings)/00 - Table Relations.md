


## 1. Mental model

A database knows only one way to connect tables: a **foreign key column**. Java connects objects with **references** (`book.getAuthor()`). JPA translates between the two.

Think of a **school roster**:

- A **student card** carries a sticker with the class number (the foreign key). The class itself carries nothing.
- To find a student's class, read the sticker. To find a class's students, search all cards for that sticker.

The side holding the sticker is the **owning side** (it has the FK column). The other side is the **inverse side**: it's a convenience view that is not stored anywhere.

> **Core rule:** Hibernate writes the foreign key **only from the owning side**. The inverse side (`mappedBy`) is ignored when saving.

## 2. The four relation types

|Annotation|Real-world example|Where the FK lives|
|---|---|---|
|`@ManyToOne`|many Books → one Author|`books.author_id`|
|`@OneToMany`|one Author → many Books|same FK, seen from the other side|
|`@OneToOne`|one User → one Profile|on one of the two tables|
|`@ManyToMany`|Students ↔ Courses|a separate **join table**|

## 3. ManyToOne / OneToMany (the one you use 80% of the time)

This is our `Author`/`Book` model from before, now with the details explained:

```java
@Entity
public class Book {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "author_id", nullable = false)   // OWNING side: has the FK
    private Author author;
}

@Entity
public class Author {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Book> books = new ArrayList<>();      // INVERSE side: no column

    // keep both sides in sync
    public void addBook(Book book) {
        books.add(book);
        book.setAuthor(this);
    }

    public void removeBook(Book book) {
        books.remove(book);
        book.setAuthor(null);
    }
}
```

`mappedBy = "author"` means "the foreign key is managed by the field named `author` in `Book`".

### Why the helper methods matter

1. You create `Author a` and `Book b`.
2. You call `a.getBooks().add(b)` only.
3. You save `a`.
4. `b.author` is still `null`, and the owning side is what Hibernate reads.
5. Result: `books.author_id` is saved as `NULL`. No exception, just silently wrong data.

With `a.addBook(b)` both sides are set, so the object graph in memory matches the database.

### Usage

```java
@Transactional
public void create() {
    Author a = new Author("Tolkien", "UK");
    a.addBook(new Book("The Hobbit", Genre.FANTASY));
    a.addBook(new Book("The Silmarillion", Genre.FANTASY));
    authorRepository.save(a);   // cascades: saves author + 2 books
}
```

Because of `cascade = ALL`, you don't call `bookRepository.save()` for each book.

## 4. Cascade and orphanRemoval

**Cascade** means "when I do X to the parent, do X to the children too."

|CascadeType|Propagates|
|---|---|
|`PERSIST`|`save` of a new parent also saves new children|
|`MERGE`|`save` of a detached parent also merges its children|
|`REMOVE`|deleting the parent deletes the children|
|`REFRESH`, `DETACH`|rarely used|
|`ALL`|all of the above|

**`orphanRemoval = true`** covers a case cascade can't: removing a child **from the collection**.

```java
author.removeBook(book);   // book is no longer in the list
// with orphanRemoval=true → DELETE FROM books WHERE id = ...
// without it             → book stays in DB, just with author_id = NULL (or fails if NOT NULL)
```

**When to use them:** only where the child cannot live without the parent (Order → OrderLine, Author → Book _if_ you consider books owned by authors). **Never** use `REMOVE`/`ALL` on `@ManyToOne` (deleting one book must not delete its author, who has other books) or on `@ManyToMany` (see section 6).

Cascade is a **JPA-level** feature (Hibernate issues the DELETEs). It is different from the database's own `ON DELETE CASCADE`, which acts inside the DB.

## 5. OneToOne

```java
@Entity
public class UserAccount {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "profile_id")                  // OWNING: FK in user_accounts
    private Profile profile;
}

@Entity
public class Profile {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(mappedBy = "profile", fetch = FetchType.LAZY)   // INVERSE
    private UserAccount user;
}
```

**Better variant: shared primary key with `@MapsId`.** The child's PK **is** the parent's PK, so no extra FK column or index is needed:

```java
@Entity
public class Profile {
    @Id
    private Long id;                       // same value as the user's id

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "id")
    private UserAccount user;
}
```

**Gotcha:** on the **inverse** side of a `@OneToOne`, `LAZY` often doesn't work. Hibernate must query to learn whether the related row exists (it can't put `null` or a proxy without asking), so it loads it eagerly anyway. `@MapsId` avoids that problem.

## 6. ManyToMany

A student takes many courses, and a course has many students. SQL needs a **join table**:

```
students            student_course            courses
id | name           student_id | course_id    id | title
```

```java
@Entity
public class Student {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;

    @ManyToMany
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(name = "student_id"),          // FK to THIS entity
        inverseJoinColumns = @JoinColumn(name = "course_id")     // FK to the OTHER entity
    )
    private Set<Course> courses = new HashSet<>();               // OWNING side

    public void enroll(Course c) {
        courses.add(c);
        c.getStudents().add(this);
    }
}

@Entity
public class Course {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;

    @ManyToMany(mappedBy = "courses")
    private Set<Student> students = new HashSet<>();             // INVERSE side
}
```

**Rules for ManyToMany:**

1. **Use `Set`, not `List`.** With a `List`, removing one element makes Hibernate delete **all** join rows for that owner and re-insert the remaining ones. A `Set` deletes only the removed row.
2. **Never cascade `REMOVE`/`ALL`.** Deleting one student would delete the courses they took, and those courses belong to other students too. Use `PERSIST`/`MERGE` at most.

### When ManyToMany isn't enough: the link entity

The moment the relationship needs **its own data** (enrollment date, grade), `@ManyToMany` can't hold it. Break it into two `@ManyToOne` relations:

```java
@Entity
public class Enrollment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) private Student student;
    @ManyToOne(fetch = FetchType.LAZY) private Course course;

    private LocalDate enrolledOn;
    private Integer grade;
}
```

Then `Student` has `@OneToMany(mappedBy = "student") List<Enrollment>` and the same for `Course`. Most real projects end up here, so treat the pure `@ManyToMany` as the simple case only.

## 7. Fetch types and the defaults

|Relation|Default fetch|
|---|---|
|`@ManyToOne`, `@OneToOne`|**EAGER** (loaded immediately with a join)|
|`@OneToMany`, `@ManyToMany`|**LAZY** (loaded on first access)|

The "to-one" EAGER default is a trap, because loading 100 books also loads 100 authors, and chains of eager relations multiply. **Always write `fetch = FetchType.LAZY` on to-one relations** and pull data in explicitly when needed:

```java
@Query("SELECT b FROM Book b JOIN FETCH b.author WHERE b.genre = :genre")
List<Book> findWithAuthor(@Param("genre") Genre genre);

@EntityGraph(attributePaths = {"author"})
List<Book> findByPublishedYearGreaterThan(int year);
```

(This is the N+1 fix from the first lesson, now in its proper context.)

## 8. Querying across relations in repositories

```java
// Derived: Spring walks book.author.country by itself
List<Book> findByAuthorCountry(String country);

// Derived, from the one-to-many side
List<Author> findByBooksGenre(Genre genre);              // JOINs automatically, may return duplicates → use Distinct
List<Author> findDistinctByBooksGenre(Genre genre);

// JPQL with explicit joins
@Query("SELECT a FROM Author a LEFT JOIN FETCH a.books WHERE a.id = :id")
Optional<Author> findWithBooks(@Param("id") Long id);

// Authors with no books at all
@Query("SELECT a FROM Author a WHERE a.books IS EMPTY")
List<Author> findWithoutBooks();
```

`JOIN` (inner) drops authors that have no books. `LEFT JOIN` keeps them. Pick based on whether the empty parents should appear.

## 9. Gotchas and edge cases

1. **Unidirectional `@OneToMany` without `mappedBy`** creates a hidden **join table** you never asked for. If you only want a one-to-many with an FK in the child, add `@JoinColumn(name = "author_id")` on the `@OneToMany`, or better, make it bidirectional as in section 3.
    
2. **Infinite recursion in `toString()`, `hashCode()`, and JSON.** `Author → books → Book → author → books...` ends in `StackOverflowError`. Keep relation fields out of `toString`, and **don't return entities from controllers**. Return DTOs or records. (Lombok `@Data` on entities is a classic cause. Avoid it there.)
    
3. **`equals`/`hashCode` with generated IDs.** If `hashCode` uses `id`, it changes after `save()` and breaks `HashSet` membership. Use a stable business key, or a constant `hashCode`.
    
4. **Replacing a collection.** `author.setBooks(newList)` with `orphanRemoval = true` throws `HibernateException: A collection with cascade="all-delete-orphan" was no longer referenced`. Mutate the existing collection with `clear()` and `addAll()` instead.
    
5. **Foreign key to a row that doesn't exist** throws `DataIntegrityViolationException` at flush time. If you only have an id, use `getReferenceById(id)` for a cheap proxy instead of loading the whole entity:
    
    ```java
    book.setAuthor(authorRepository.getReferenceById(authorId));   // no SELECT
    ```
    
6. **`ddl-auto=update` is not a migration tool.** Changing relations (like moving an FK) doesn't cleanly alter existing columns. Move to Flyway/Liquibase once the schema matters.
    

## 10. Choosing quickly

|Question|Answer|
|---|---|
|Where do I put `@JoinColumn`?|On the entity whose **table** holds the FK|
|Where do I put `mappedBy`?|On the other side, naming the **field** in the owning entity|
|Many-to-many with extra data?|Link entity with two `@ManyToOne`|
|Cascade on a ManyToOne?|Almost never|
|`List` or `Set`?|`List` for one-to-many (ordered or not), `Set` for many-to-many|
|Default fetch for to-one?|Override to `LAZY`|

## Practice task

1. Add `Publisher` (one publisher → many books) with a bidirectional relation and helper methods.
2. Add `Reader` ↔ `Book` as a `@ManyToMany` (favorites), then redo it with a `Loan` link entity holding `borrowedOn` and `returnedOn`.
3. Write a JPQL query: authors with their books in one query (`LEFT JOIN FETCH`), then explain why paging it triggers `HHH000104`.
4. Predict: what SQL runs when you remove one book from `author.getBooks()` with and without `orphanRemoval`?





[[Spring Framework]]