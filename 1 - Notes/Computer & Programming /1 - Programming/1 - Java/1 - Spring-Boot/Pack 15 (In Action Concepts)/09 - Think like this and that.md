

# JPA Entity Relationships — A Mental Model for Mapping

## 1. The Core Idea

When designing entity relationships, do not start by memorizing JPA annotations. Start by understanding how the objects in your application relate to each other in the real world.

Ask yourself:

- What does this entity represent?
    
- What other entity is it related to?
    
- How many instances of one entity can be associated with an instance of the other?
    
- Which entity should store the foreign key?
    

The answers determine the relationship type and how it should be mapped using JPA.

**Core mental model:**

> Many of this belong to one of that → `@ManyToOne`

> One of this belongs to one of that → `@OneToOne`

> One of this has many of that → `@OneToMany`

> Many of this relate to many of that → `@ManyToMany`

These are starting points for reasoning, not substitutes for understanding the actual domain.

---

## 2. Step One — Identify the Entities

An entity represents a concept in your application's domain that needs to be persisted.

Consider a cinema application.

It might contain these entities:

- `Movie`
    
- `Showtime`
    
- `Cinema`
    
- `Screen`
    
- `Ticket`
    
- `Customer`
    

Each represents a different concept.

Before writing any Java code, describe the relationships in plain English.

For example:

- A movie can have many showtimes.
    
- Each showtime belongs to one movie.
    
- A customer can purchase many tickets.
    
- Each ticket belongs to one customer.
    
- A ticket is associated with a particular showtime.
    

These sentences describe the domain before implementation details influence the design.

---

## 3. Step Two — Determine the Cardinality

**Cardinality** describes how many instances of one entity can be associated with instances of another entity.

Consider `Movie` and `Showtime`.

A movie might have these showtimes:

|Showtime ID|Movie|Start time|
|---|---|---|
|1|Interstellar|10:00|
|2|Interstellar|14:00|
|3|Interstellar|18:00|
|4|Inception|12:00|

From this data, we can establish two facts:

1. One movie can have multiple showtimes.
    
2. Each showtime belongs to one movie.
    

Therefore, the relationship is one-to-many when viewed from `Movie`, and many-to-one when viewed from `Showtime`.

### The reasoning

Start from the entity you are currently designing.

If you are designing `Showtime`, ask:

"Can many showtime records reference the same movie?"

Yes.

"Can one showtime reference multiple movies?"

No, according to our domain rules.

Therefore, `Showtime` has a many-to-one relationship with `Movie`.

```
@ManyToOne
@JoinColumn(name = "movie_id")
private Movie movie;
```

The annotation expresses the relationship from the perspective of `Showtime`.

---

## 4. Step Three — Understand the Four Relationship Types

### 4.1. Many-to-One — `@ManyToOne`

**Definition:** Multiple instances of the current entity can reference the same instance of another entity.

Example: many showtimes belong to one movie.

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

The database structure:

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

The `showtime` table stores the foreign key.

Multiple showtime records can contain the same `movie_id`.

**Use this when:** The current entity belongs to one parent or references one shared entity, while that entity can be referenced by many records.

Other examples:

- Many tickets belong to one showtime.
    
- Many employees belong to one department.
    
- Many orders belong to one customer.
    
- Many comments belong to one post.
    

### 4.2. One-to-Many — `@OneToMany`

**Definition:** One instance of the current entity can be associated with multiple instances of another entity.

From the movie's perspective, a movie has many showtimes.

```java
@Entity
public class Movie {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "movie")
    private List<Showtime> showtimes = new ArrayList<>();
}
```

Here, `mappedBy = "movie"` refers to the Java field named `movie` in `Showtime`, not the database column `movie_id`.

This tells JPA that the relationship is already mapped by the `movie` field on the other side.

**Important:** `@OneToMany` does not automatically mean that the current entity owns the relationship.

In this example, `Showtime` owns the relationship because it maps the foreign key through `@JoinColumn`.

Use `@OneToMany` when you need to navigate from one entity to a collection of related entities.

### 4.3. One-to-One — `@OneToOne`

**Definition:** One instance of an entity is associated with at most one instance of another entity, and vice versa.

Example: each user has one profile, and each profile belongs to one user.

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

The `user_profile` table stores `user_id`. The unique constraint prevents multiple profiles from referencing the same user.

The exact foreign-key placement depends on the intended schema and ownership design.

**Use this when:** The domain genuinely requires a one-to-one association.

Examples:

- A user and a unique profile.
    
- A country and its unique capital city, if the model explicitly enforces that rule.
    
- A vehicle and its unique registration record, if each record corresponds to exactly one vehicle and vice versa.
    

Do not use one-to-one merely because two objects are related. The domain must justify the cardinality.

### 4.4. Many-to-Many — `@ManyToMany`

**Definition:** Multiple instances of one entity can relate to multiple instances of another entity.

Example: students enroll in multiple courses, and each course has multiple students.

```
@Entity
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToMany
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "course_id")
    )
    private Set<Course> courses = new HashSet<>();
}
```

The relationship requires a join table:

```
student
-------
id

course
------
id

student_course
--------------
student_id
course_id
```

Each row in `student_course` connects one student to one course.

If the relationship itself has attributes, such as enrollment date, grade, or status, model it as a separate entity such as `Enrollment`, usually with two many-to-one relationships.

---

## 5. Step Four — Determine the Owning Side

Understanding cardinality is not enough. You must also understand which entity maps the database relationship.

**The owning side is the side responsible for mapping and updating the relationship's foreign key or join table.**

Consider:

```
@Entity
public class Showtime {

    @ManyToOne
    @JoinColumn(name = "movie_id")
    private Movie movie;
}
```

`Showtime` is the owning side because it maps `movie_id`.

The inverse side is:

```
@Entity
public class Movie {

    @OneToMany(mappedBy = "movie")
    private List<Showtime> showtimes = new ArrayList<>();
}
```

The `mappedBy` attribute tells JPA that `Movie.showtimes` is the inverse representation of the relationship already mapped by `Showtime.movie`.

### How to reason about ownership

1. Find the foreign key in the database design.
    
2. Identify which entity's table contains it.
    
3. Map the relationship on that entity using the appropriate association annotation and, where needed, `@JoinColumn`.
    
4. If the relationship is bidirectional, map the other side using `mappedBy`.
    

For a conventional many-to-one relationship, the many side normally stores the foreign key and owns the relationship.

For a one-to-one relationship, either side can own the relationship depending on where the foreign key belongs.

For a many-to-many relationship, the owning side defines the join table mapping.

**Important:** Owning a relationship does not mean owning the lifecycle of the other entity. Database relationship ownership and entity lifecycle management are separate concepts.

---

## 6. Step Five — Decide Whether the Relationship Should Be Bidirectional

A relationship can be unidirectional or bidirectional.

### Unidirectional

Only one entity has a reference to the other.

```
@Entity
public class Showtime {

    @ManyToOne
    @JoinColumn(name = "movie_id")
    private Movie movie;
}
```

You can navigate from `Showtime` to `Movie`, but not directly from `Movie` to its showtimes through a mapped Java field.

### Bidirectional

Both entities have references to each other.

```
// Showtime
@ManyToOne
@JoinColumn(name = "movie_id")
private Movie movie;
```

```
// Movie
@OneToMany(mappedBy = "movie")
private List<Showtime> showtimes = new ArrayList<>();
```

You can navigate in both directions.

Bidirectional mapping is useful when the application needs both navigation paths, but it introduces synchronization and serialization concerns.

**Do not add both sides automatically.** Map only the navigation your domain and application actually need.

---

## 7. Step Six — Keep Both Sides Consistent

In a bidirectional relationship, changing one Java reference does not automatically update the other Java reference.

For example, this code sets the owning side:

```
showtime.setMovie(movie);
```

But it does not automatically add `showtime` to `movie.getShowtimes()`.

A helper method can maintain both sides:

```
public void addShowtime(Showtime showtime) {
    showtimes.add(showtime);
    showtime.setMovie(this);
}
```

This method belongs in `Movie`, assuming the collection and setter are available.

It keeps the in-memory object graph consistent.

The owning side remains responsible for the database relationship mapping.

---

## 8. A Reusable Decision Workflow

Use this workflow whenever you create entity relationships.

### Step 1: Describe the domain

Write a sentence describing the relationship.

Example: "Many showtimes belong to one movie."

### Step 2: Check the cardinality

Ask how many instances on each side are allowed.

Example:

- One movie → many showtimes.
    
- One showtime → one movie.
    

### Step 3: Start from the current entity

If you are implementing `Showtime`, the relationship to `Movie` is many-to-one.

If you are implementing `Movie`, the relationship to `Showtime` is one-to-many.

### Step 4: Design the foreign key

Determine which table should reference the other table's primary key.

Example: `showtime.movie_id` references `movie.id`.

### Step 5: Determine ownership

The entity mapping `movie_id` owns this relationship.

### Step 6: Choose the navigation direction

Decide whether the application needs to navigate from `Showtime` to `Movie`, from `Movie` to `Showtime`, or both.

### Step 7: Implement and validate

Add the appropriate annotations, then verify the generated schema, foreign keys, unique constraints, and application behavior.

---

## 9. Practice — Determine the Relationship

For each scenario, determine the relationship type from the perspective of the first entity.

1. Many `Order` objects belong to one `Customer`.
    
2. One `AppUser` has one `Watchlist`, and each `Watchlist` belongs to one `AppUser`.
    
3. Many `Student` objects enroll in many `Course` objects.
    
4. One `Department` has many `Employee` objects.
    
5. Many `WatchlistItem` objects belong to one `Watchlist`.
    

Answers:

1. `Order` → `Customer`: `@ManyToOne`
    
2. `AppUser` → `Watchlist`: `@OneToOne`
    
3. `Student` → `Course`: `@ManyToMany`, if the relationship has no independent attributes
    
4. `Department` → `Employee`: `@OneToMany`
    
5. `WatchlistItem` → `Watchlist`: `@ManyToOne`
    

For scenario 2, if the application requires each user to have exactly one watchlist, remember that a Java association annotation alone does not enforce every lifecycle or existence rule. Database constraints and application logic may also be necessary.

---

## 10. Final Mental Model

Keep these four questions in mind:

1. **Domain:** What is the real-world relationship?
    
2. **Cardinality:** How many objects can be associated on each side?
    
3. **Database:** Where does the foreign key or join table belong?
    
4. **Navigation:** Which side or sides need a Java reference?
    

Then determine ownership and map the relationship.

The key principle is:

> Understand the relationship first. Choose the JPA annotation second. Design the foreign key and ownership deliberately.

Once this becomes habitual, JPA relationship annotations become a description of your domain model rather than something you have to memorize.


[[Spring Framework]]