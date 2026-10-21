

## 1. The Core Mental Model

When mapping a relationship between two entities, ask two questions:

1. **Which table stores the foreign key?**
    
2. **Which entity is responsible for mapping that relationship?**
    

These questions lead you to the correct annotation.

- `@JoinColumn` specifies the database column used to reference another entity.
    
- `mappedBy` tells JPA that the relationship is already mapped by a field on the other entity.
    

**Remember:**

> Foreign key mapping goes on the owning side. `mappedBy` goes on the inverse side of a bidirectional relationship.

You do not normally put both annotations on the same relationship field.

---

## 2. First, Understand the Database

Imagine a cinema application with two entities:

- `Movie`
    
- `Showtime`
    

One movie can have many showtimes, but each showtime belongs to one movie.

Before writing Java code, design the tables:

```
CREATE TABLE movie (
    id BIGINT PRIMARY KEY,
    title VARCHAR(200)
);

CREATE TABLE showtime (
    id BIGINT PRIMARY KEY,
    movie_id BIGINT REFERENCES movie(id)
);
```

Notice where `movie_id` exists: in the `showtime` table.

Why?

Because each showtime needs to identify the movie it belongs to. Multiple showtime rows can reference the same movie.

This database structure gives us the first important conclusion:

**The** `**Showtime**` **entity owns this relationship because it maps the foreign key column.**

That tells us where `@JoinColumn` belongs.

---

## 3. When Should I Use `@JoinColumn`?

### Definition

`@JoinColumn` specifies the database join column used by an entity relationship. In a typical foreign-key relationship, it identifies the foreign key column in the owning entity's table.

Consider the `Showtime` entity:

```
@Entity
public class Showtime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "movie_id")
    private Movie movie;
}
```

Let's reason through it.

**Question 1:** Does each showtime belong to a movie?

Yes. Therefore, we use `@ManyToOne`.

**Question 2:** Which table stores the foreign key?

The `showtime` table stores `movie_id`.

**Question 3:** Which entity maps that column?

`Showtime`.

Therefore, we put `@JoinColumn(name = "movie_id")` on the `movie` relationship field in `Showtime`.

### What does `name` mean?

```
@JoinColumn(name = "movie_id")
```

The `name` refers to the **database column name**, not the Java field name.

```
private Movie movie;
```

Here, `movie` is the Java field. `movie_id` is the database column.

They serve different purposes.

### Do I always need `@JoinColumn`?

No.

JPA can infer a join-column name using its default naming rules when you omit the annotation. However, writing it explicitly can make your schema easier to understand and control.

Use it when you want to specify the column name or its constraints and other supported join-column properties.

---

## 4. When Should I Use `mappedBy`?

### Definition

`mappedBy` identifies the Java field or property on the owning entity that already maps the relationship.

Look at the other side:

```
@Entity
public class Movie {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "movie")
    private List<Showtime> showtimes = new ArrayList<>();
}
```

Why is `mappedBy = "movie"` here?

Because the `Showtime` entity already maps the foreign key through this field:

```
@ManyToOne
@JoinColumn(name = "movie_id")
private Movie movie;
```

The value of `mappedBy` is `"movie"` because that is the **Java field name in** `**Showtime**`.

It is not `"movie_id"`, because `movie_id` is the database column name.

### How to think about it

Imagine JPA encounters both sides of the relationship.

- `Showtime.movie` says: "I map the foreign key that connects this showtime to a movie."
    
- `Movie.showtimes` says: "My relationship is mapped by the `movie` field in `Showtime`."
    

The second side does not independently map another foreign key.

That is what `mappedBy` communicates.

---

## 5. The Most Important Difference

|Annotation|Purpose|What its value refers to|
|---|---|---|
|`@JoinColumn(name = "movie_id")`|Specifies a database join column|Database column name|
|`mappedBy = "movie"`|Points to the field mapping the relationship on the owning side|Java field/property name|

A useful rule:

> `@JoinColumn` points to a database column. `mappedBy` points to a Java field or property.

Confusing these two names is a common source of JPA mapping errors.

---

## 6. How to Find the Correct Side Step by Step

Whenever you create a relationship, follow this process.

### Step 1 — Identify the relationship

Example:

"Many showtimes belong to one movie."

```
@ManyToOne
private Movie movie;
```

### Step 2 — Decide where the foreign key belongs

Ask: "Which row needs to store the ID of the other entity?"

Each showtime needs a `movie_id`, so the foreign key belongs in the `showtime` table.

### Step 3 — Map the foreign key

```
@ManyToOne
@JoinColumn(name = "movie_id")
private Movie movie;
```

Now `Showtime` owns the relationship.

### Step 4 — Decide whether the other side needs navigation

Do you need to retrieve the showtimes from a movie using `movie.getShowtimes()`?

If not, you can keep the relationship unidirectional and omit the collection from `Movie`.

If yes, add the inverse side:

```
@OneToMany(mappedBy = "movie")
private List<Showtime> showtimes = new ArrayList<>();
```

### Step 5 — Point `mappedBy` to the owning field

Find the field in the owning entity:

```
private Movie movie;
```

Use its name:

```
mappedBy = "movie"
```

Do not use the database column name.

---

## 7. What If the Relationship Is `@OneToOne`?

The same reasoning applies, but either entity can own the relationship, depending on where the foreign key is stored.

Suppose every user has one profile, and each profile belongs to one user.

The database has a `user_profile` table with a unique `user_id` foreign key.

```
@Entity
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", unique = true)
    private AppUser user;
}
```

The `UserProfile` entity owns the relationship because it maps `user_id`.

The inverse side can be:

```
@Entity
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(mappedBy = "user")
    private UserProfile profile;
}
```

Notice that `mappedBy = "user"` refers to `UserProfile.user`.

**The annotation does not determine ownership by itself.** The database mapping design determines which side owns the relationship.

---

## 8. What About `@ManyToMany`?

A many-to-many relationship typically uses a join table.

For example, students can enroll in multiple courses, and courses can contain multiple students.

The owning side defines the join table:

```
@ManyToMany
@JoinTable(
    name = "student_course",
    joinColumns = @JoinColumn(name = "student_id"),
    inverseJoinColumns = @JoinColumn(name = "course_id")
)
private Set<Course> courses = new HashSet<>();
```

The inverse side references the owning field:

```
@ManyToMany(mappedBy = "courses")
private Set<Student> students = new HashSet<>();
```

Here:

- `joinColumns` identifies the join-table column referencing `Student`.
    
- `inverseJoinColumns` identifies the join-table column referencing `Course`.
    
- `mappedBy = "courses"` points to the `courses` field in `Student`.
    

The join table is not the same thing as the foreign key in the simple `Showtime` example, but the ownership principle remains similar.

---

## 9. Common Mistakes

### Mistake 1 — Using the column name in `mappedBy`

Incorrect:

```
@OneToMany(mappedBy = "movie_id")
private List<Showtime> showtimes;
```

Correct:

```
@OneToMany(mappedBy = "movie")
private List<Showtime> showtimes;
```

`mappedBy` refers to the Java field, `movie`.

### Mistake 2 — Putting `mappedBy` on both sides

In a conventional bidirectional relationship, one side maps the relationship, and the other side refers to that mapping.

Do not make both sides inverse.

### Mistake 3 — Assuming every relationship needs both annotations

A unidirectional relationship often needs no `mappedBy`, because there is no inverse side.

A `@ManyToOne` can use `@JoinColumn` without a corresponding `@OneToMany`.

### Mistake 4 — Thinking `mappedBy` creates the foreign key

It does not. It identifies the existing mapping on the other side.

### Mistake 5 — Thinking ownership determines object lifecycle

Owning a relationship does not automatically mean that deleting one entity deletes the other. Cascades and orphan removal are separate configuration decisions.

---

## 10. Final Mental Model

When you see two related entities, ask these questions in order:

1. **What is the cardinality?** Choose `@ManyToOne`, `@OneToMany`, `@OneToOne`, or `@ManyToMany`.
    
2. **Where is the database relationship stored?** Identify the foreign key or join table.
    
3. **Which side maps it?** That is the owning side.
    
4. **Do I need navigation from the other side?** If yes, add the inverse relationship and use `mappedBy`.
    
5. **What name goes in** `**mappedBy**`**?** Use the Java field/property name on the owning side.
    
6. **What name goes in** `**@JoinColumn(name = ...)**`**?** Use the database column name.
    

### The rule to memorize

`**@JoinColumn**` **maps the database relationship.** `**mappedBy**` **points to the Java field that already maps it.**

Do not begin by asking, "Where should I put the annotation?"

Begin by asking, "Where does the foreign key belong, and which entity maps it?"

Once you answer that, the correct placement becomes much easier to determine.


[[Spring Framework]]