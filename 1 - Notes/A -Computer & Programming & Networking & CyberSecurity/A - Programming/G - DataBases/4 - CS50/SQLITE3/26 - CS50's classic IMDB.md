

## Schema: movies, people, stars, ratings, directors

```sql
CREATE TABLE movies (
    id INTEGER,
    title TEXT NOT NULL,
    year NUMERIC,
    PRIMARY KEY(id)
);

CREATE TABLE people (
    id INTEGER,
    name TEXT NOT NULL,
    birth NUMERIC,
    PRIMARY KEY(id)
);

CREATE TABLE stars (
    movie_id INTEGER,
    person_id INTEGER,
    FOREIGN KEY(movie_id) REFERENCES movies(id),
    FOREIGN KEY(person_id) REFERENCES people(id)
);

CREATE TABLE ratings (
    movie_id INTEGER,
    rating REAL,
    votes INTEGER,
    FOREIGN KEY(movie_id) REFERENCES movies(id)
);

CREATE TABLE directors (
    movie_id INTEGER,
    person_id INTEGER,
    FOREIGN KEY(movie_id) REFERENCES movies(id),
    FOREIGN KEY(person_id) REFERENCES people(id)
);
```

### Walking through the keys

**`movies.id` and `people.id`** — these are **primary keys**. Every movie and every person needs a unique numeric ID because titles and names aren't reliable identifiers. Multiple movies can share a title ("Aladdin" 1992 vs 2019), and multiple people can share a name (there are several "Robert Smith"s in real life). The ID sidesteps that ambiguity entirely.

**`stars` table** — this is the interesting one. It has _no primary key of its own_ — just two **foreign keys**: `movie_id` and `person_id`. This is a classic **join table** (also called a junction/bridge table), and it solves a specific problem:

> A movie has many stars, and an actor stars in many movies. That's a **many-to-many relationship**, and you can't represent it with a simple foreign key on either side.

If you tried to put a `star_id` column directly on `movies`, one movie could only reference one star. The join table breaks the many-to-many relationship into two many-to-one relationships:

- Many rows in `stars` → one `movie` (via `movie_id`)
- Many rows in `stars` → one `person` (via `person_id`)

Together, each row in `stars` represents _one_ "this person is in this movie" fact.

**`ratings.movie_id`** — a straightforward **foreign key**, one-to-one/one-to-many: each movie has (typically) one rating row, linking back to `movies`.

### Why this design solves real problems

Without this structure, you'd be tempted to just cram everything into one giant `movies` table:

```
title | year | star1 | star2 | star3 | director | rating
```

That falls apart fast:

- What if a movie has 8 stars? You'd need 8 columns, most empty most of the time.
- What if an actor's name is misspelled once as "Tom Hanks" and once as "Tom Hank"? Now your data thinks these are different people — you've lost the ability to reliably ask "what movies is this person in?"
- Updating a person's birth year means finding and fixing it in every single movie row they appear in.

By pulling `people` out into its own table with a primary key, and connecting it to `movies` via the `stars` join table, you get:

- **No duplication** — each person and movie exists exactly once
- **No arbitrary limits** — a movie can have 1 star or 50, no schema changes needed
- **Consistency** — update a person's name once, it's correct everywhere

[[1 - WHAT IS SQLITE3]]