

This explanation covers four things in order: where foreign keys live, how to decide the relationship type, how each annotation is mapped, and how fetching and joining work at runtime.

## Part 1: Where the Foreign Key Lives

**Definition.** A relationship between two tables is stored as a foreign key, which is a column in one table that holds the primary key of a row in another table. JPA relationship annotations describe that same structure in Java.

**Why it exists.** A relational database cannot store an object graph directly. It stores rows, and each row can only hold flat values. A foreign key is the only way a row can point to another row, so every relationship in JPA must end up as a foreign key or as a join table.

**The rule that decides everything.** The foreign key always goes on the side that is "many," or on the side that owns the relationship in a one-to-one. The `@JoinColumn` annotation marks that side. The other side is the inverse side and uses `mappedBy` to say "the other entity owns this relationship."

Look at the difference between these two tables:

```
author                      book
------------------          ------------------------------
id | name                   id | title          | author_id
---+--------                ---+----------------+----------
 1 | Rumi                    10 | Masnavi        |    1
 2 | Hafez                   11 | Divan          |    2
                             12 | Fihi Ma Fihi   |    1
```

Each book row holds `author_id`. One author appears in many book rows, so a book can only point to one author. An author cannot hold a list of book ids in its own row, because a column can only hold one value. So the foreign key belongs on `book`.

## Part 2: How to Decide Which Relationship You Need

Choosing the annotation is a question about the real world, not about Java. Ask these questions in order, and write the answers in plain English before writing any code.

**Question 1: How many B can one A have?**  
**Question 2: How many A can one B have?**

Your answers give you the relationship type:

|Answer to Q1|Answer to Q2|Relationship|Example|
|---|---|---|---|
|one|one|One-to-one|A user has one profile, and a profile belongs to one user|
|many|one|Many-to-one (seen from the many side) or one-to-many (seen from the one side)|An author has many books, and a book has one author|
|many|many|Many-to-many|A student takes many courses, and a course has many students|

A common mistake is choosing one-to-one because each object seems to have "one" of something. Check whether the answer could change later. If a user might eventually have several addresses, a one-to-one is the wrong model now, and changing it later means a schema migration.

**Question 3: Does the child have a life of its own?** If the child is only meaningful inside its parent, such as an order line inside an order, it is a candidate for cascade and orphan removal. If the child is shared, such as a category, a tag, or a product, it should not be cascaded.

**Question 4: Does the relationship itself carry data?** A many-to-many that only links two things can use a simple `@ManyToMany`. If the link has its own facts, such as a grade for a student in a course, the link must become its own entity. That is a join entity, covered in Part 4.

## Part 3: The Relationship Annotations

### @ManyToOne and @OneToMany (the most common pair)

**Definition.** `@ManyToOne` is placed on the field that holds one parent reference, and it means the foreign key is in this table. `@OneToMany` is placed on the collection of children, and it means the foreign key is in the child's table.

**Full mapping.** This example uses `Author` and `Book`.

```java
@Entity
public class Author {

    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Book> books = new ArrayList<>();

    public void addBook(Book book) {
        books.add(book);
        book.setAuthor(this);
    }
}
```

```java
@Entity
public class Book {

    @Id
    @GeneratedValue
    private Long id;

    private String title;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "author_id", nullable = false, foreignKey = @ForeignKey(name = "fk_book_author"))
    private Author author;
}
```

Here is what each part does:

- `mappedBy = "author"` on `Author.books` says the foreign key is controlled by the `author` field in `Book`. Without this, Hibernate would create a second, separate join table, which is a common beginner error.
- `@ManyToOne` on `Book.author` is the owning side. It is the side that writes `author_id`.
- `@JoinColumn(name = "author_id")` sets the column name. `nullable = false` requires every book to have an author.
- `optional = false` tells JPA the relationship must exist, which is checked at the Java level before the database is involved.
- `foreignKey = @ForeignKey(name = ...)` names the constraint, which helps when reading error messages.
- `addBook` keeps both sides of the object graph consistent. Without it, the list on `Author` and the field on `Book` can disagree in memory, and Hibernate only saves the owning side.

**Why the helper method matters.** Hibernate writes the foreign key from `Book.author`, not from `Author.books`. If you add a book only to the list, the database row ends up with a null `author_id`, which causes a constraint error or silently loses the link.

### @OneToOne

**Definition.** A one-to-one relationship links exactly one row in table A to exactly one row in table B. One side owns the foreign key, and the foreign key has a unique constraint so no two rows can point to the same target.

```java
@Entity
public class User {

    @Id
    @GeneratedValue
    private Long id;

    private String username;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private UserProfile profile;
}
```

```java
@Entity
public class UserProfile {

    @Id
    @GeneratedValue
    private Long id;

    private String bio;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;
}
```

The `unique = true` is what makes this one-to-one rather than many-to-one. Without it, the database would allow two profiles to point at the same user, and your Java model would be lying.

`@OneToOne` defaults to `fetch = EAGER`, which is the opposite of what you usually want. Set `LAZY` explicitly on the owning side. The inverse side, the one with `mappedBy`, cannot be lazy in standard Hibernate without bytecode enhancement, so do not rely on it for performance.

### @ManyToMany and @JoinTable

**Definition.** A many-to-many relationship cannot be stored with a single foreign key, because each row on either side would need to point to many rows. It is stored in a third table called a join table, which has one row for each pair of linked ids.

```java
@Entity
public class Student {

    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @ManyToMany
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "course_id")
    )
    private Set<Course> courses = new HashSet<>();
}
```

```java
@Entity
public class Course {

    @Id
    @GeneratedValue
    private Long id;

    private String title;

    @ManyToMany(mappedBy = "courses")
    private Set<Student> students = new HashSet<>();
}
```

`@JoinTable` describes the third table. `joinColumns` names the column pointing back to the owning side, and `inverseJoinColumns` names the column pointing to the other side. The inverse side uses `mappedBy` for the same reason as before.

Use a `Set` here rather than a `List`. A `List` used in a many-to-many is treated as a "bag," and fetching two bags in one query fails with `MultipleBagFetchException`.

### When the Link Has Its Own Data: the Join Entity

**Definition.** A join entity is an explicit entity that represents the link between two others. It replaces the hidden join table with a visible table that can hold extra columns.

```java
@Entity
@Table(
    name = "enrollment",
    uniqueConstraints = @UniqueConstraint(columnNames = {"student_id", "course_id"})
)
public class Enrollment {

    @Id
    @GeneratedValue
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    private LocalDate enrolledOn;
    private String grade;
}
```

This is now two one-to-many relationships pointing into a middle table. The `uniqueConstraints` stops a student from enrolling in the same course twice. A grade and an enrollment date belong to the link itself, so they live on `Enrollment`, not on either `Student` or `Course`.

When a many-to-many starts needing extra columns, convert it to a join entity. The change is always the same: add an entity, make two many-to-one fields, and move the relationship's data onto it.

### Quick Reference of Attributes

|Attribute|Found on|What it does|Default|
|---|---|---|---|
|`mappedBy`|`@OneToMany`, `@OneToOne`, `@ManyToMany`|Marks this side as inverse; the other side owns the foreign key|none (this side owns)|
|`fetch`|all four|`LAZY` loads when accessed; `EAGER` loads with the parent|`EAGER` for `@ManyToOne`/`@OneToOne`, `LAZY` for `@OneToMany`/`@ManyToMany`|
|`cascade`|all four|Propagates `PERSIST`, `REMOVE`, `MERGE`, etc. to children|none|
|`orphanRemoval`|`@OneToMany`, `@OneToOne`|Deletes children removed from the collection|`false`|
|`optional`|`@ManyToOne`, `@OneToOne`|Whether the relationship may be null|`true`|
|`name`|`@JoinColumn`|Name of the foreign key column|`<field>_<pk>`|
|`referencedColumnName`|`@JoinColumn`|Column in the parent to point at|parent's primary key|
|`nullable`|`@JoinColumn`|Whether the foreign key column can be null in the database|`true`|
|`unique`|`@JoinColumn`|Adds a unique constraint on the foreign key column|`false`|
|`foreignKey`|`@JoinColumn`|Names the constraint|generated name|
|`joinColumns`, `inverseJoinColumns`|`@JoinTable`|Columns in the join table for each side|generated|

## Part 4: Fetch Types

**Definition.** A fetch type controls when Hibernate loads a related object. `EAGER` means it is loaded together with the parent. `LAZY` means it is loaded only when your code first reads the field.

**Why it exists.** Loading everything connected to an object can mean loading most of the database. If you load one author and that author has 10,000 books, each book with a publisher, each publisher with its own list, an EAGER chain pulls far more than you need. LAZY loads only what you touch.

**How it works, step by step.** Suppose you run this:

```java
Author author = authorRepository.findById(1L).get();
System.out.println(author.getName());
```

With `books` as LAZY (the default for `@OneToMany`), Hibernate runs one query for the author, prints the name, and never touches the books. Hibernate gives the `books` field a stand-in object called a proxy. The proxy only queries the database when a method like `size()` or `iterator()` is called on it.

```java
author.getBooks().size();   // now Hibernate runs: select ... from book where author_id = 1
```

**The problem with LAZY.** The proxy needs an open database session to load. Outside a transaction, the call throws `LazyInitializationException`. Spring Boot keeps the session open during web requests by default through `spring.jpa.open-in-view`, which hides the problem but also hides the query cost. Set it to `false` in `application.properties` once you understand what is happening, so that lazy loading outside a transaction fails loudly in development rather than silently in production.

**The N+1 problem.** This is the main performance bug caused by LAZY loading. Suppose you load ten authors and print each author's book titles:

```java
List<Author> authors = authorRepository.findAll();   // 1 query
for (Author a : authors) {
    a.getBooks().forEach(b -> System.out.println(b.getTitle()));   // 1 query per author
}
```

That is 1 query for authors plus 10 queries for books, which is 11 total. With 1,000 authors, it is 1,001 queries. The fix is not to switch everything to EAGER. The fix is to load the books in the same query, which is covered in Part 5.

**What to use.** Set `fetch = LAZY` on every relationship you write, including `@ManyToOne` and `@OneToOne`, because their EAGER default causes surprise loads. Then load what each use case needs explicitly with joins or entity graphs. EAGER is almost always wrong for collections, because it multiplies rows and queries.

**Fetch defaults summary.** `@ManyToOne` and `@OneToOne` default to EAGER. `@OneToMany`, `@ManyToMany`, and `@ElementCollection` default to LAZY. Override all of them to LAZY explicitly, so the code shows the intent.

## Part 5: Joins and Loading Related Data

**Definition.** A join combines rows from two tables in one query, based on a matching condition such as `book.author_id = author.id`. The result is a single set of rows that includes data from both tables.

**Why it matters.** The fetch type decides when a related object is loaded. A join decides how it is loaded, in the same round trip or in a separate one. Joins are how you avoid N+1.

### Plain SQL joins for reference

```sql
-- Inner join: only authors who have books
SELECT a.name, b.title
FROM author a
INNER JOIN book b ON b.author_id = a.id;

-- Left join: every author, with books if any exist
SELECT a.name, b.title
FROM author a
LEFT JOIN book b ON b.author_id = a.id;
```

The inner join drops an author with no books. The left join keeps that author and fills the book columns with null. Choosing between them is a question about what rows you want, and JPA has both.

### JPQL join fetch

Use `join fetch` when you need the parent and its children in one query. It loads the associated collection in the same SELECT, and the fetch type no longer causes extra queries for that field.

```java
public interface AuthorRepository extends JpaRepository<Author, Long> {

    @Query("select a from Author a join fetch a.books where a.name = :name")
    Optional<Author> findWithBooks(@Param("name") String name);
}
```

What this does: Hibernate generates one SQL statement with a join, so the author and all its books come back together. Calling `getBooks()` afterward does not trigger another query. In Hibernate 6, duplicate parent rows that a join creates are removed automatically, so you no longer need `select distinct` for this case.

Use `left join fetch` when the parent may have no children and you still want it returned:

```java
@Query("select a from Author a left join fetch a.books")
List<Author> findAllWithBooks();
```

### Entity graphs

An entity graph names the fields to load eagerly for one query, without writing JPQL. It is the cleanest option for Spring Data.

```java
public interface AuthorRepository extends JpaRepository<Author, Long> {

    @EntityGraph(attributePaths = {"books"})
    Optional<Author> findByName(String name);
}
```

What this does: Spring Data derives the query from the method name, and the entity graph tells Hibernate to load `books` in the same query. The mapping still says LAZY, so other queries are unaffected.

### Derived queries across relationships

Spring Data can follow relationships in method names. Use dot notation for the path:

```java
List<Book> findByAuthorName(String name);   // joins book to author on author_id
```

This generates a join automatically. You don't see it in the code, but it's there in the SQL, which you can confirm with `spring.jpa.show-sql=true`.

### Choosing the right loading tool

Use `join fetch` in JPQL when you need precise control over the query. Use `@EntityGraph` when the query is simple and you want the loading rule attached to the method. Use DTO projections when the screen needs only a few columns from several tables, because loading whole entities for a list view wastes memory.

## Part 6: A Complete Worked Example

This brings the parts together for a small library system. It is also a checklist for the decision process.

Start by asking the questions. An author can write many books, and a book has one author, so it is one-to-many. A book can belong to many categories, and a category contains many books, so it is many-to-many. Each book has one detail record that holds its page count and ISBN, and that detail cannot exist without the book, so it is one-to-one with cascade.

```java
@Entity
public class Author {
    @Id @GeneratedValue private Long id;
    private String name;

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Book> books = new ArrayList<>();
}
```

```java
@Entity
public class Book {
    @Id @GeneratedValue private Long id;
    private String title;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "author_id", nullable = false)
    private Author author;

    @OneToOne(mappedBy = "book", cascade = CascadeType.ALL, orphanRemoval = true)
    private BookDetail detail;

    @ManyToMany
    @JoinTable(
        name = "book_category",
        joinColumns = @JoinColumn(name = "book_id"),
        inverseJoinColumns = @JoinColumn(name = "category_id")
    )
    private Set<Category> categories = new HashSet<>();
}
```

```java
@Entity
public class BookDetail {
    @Id @GeneratedValue private Long id;
    private int pageCount;
    private String isbn;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false, unique = true)
    private Book book;
}
```

```java
@Entity
public class Category {
    @Id @GeneratedValue private Long id;
    private String name;

    @ManyToMany(mappedBy = "categories")
    private Set<Book> books = new HashSet<>();
}
```

The `Author` and `Book` pair uses the foreign key on `book`, with cascade and orphan removal on the parent side. The `Book` and `BookDetail` pair is one-to-one, and the foreign key has `unique = true`. `Category` is shared, so it has no cascade, and the join table is named explicitly.

To load an author with their books in one query, use the entity graph from Part 5. To print every book's categories without N+1, load the books with `@EntityGraph(attributePaths = {"categories"})` on the repository method.

## Decision Checklist

Before writing an annotation, answer these in order: how many on each side, which side is the child, whether the child is owned or shared, whether the link carries data, and what fetch type you need. Set every relationship to LAZY. Load related data with joins or entity graphs at the point of use.





[[Spring Framework]]