


## Primary Key: exactly one _per table_

A table can only have **one** primary key. But that primary key can consist of **multiple columns** (a composite key, like we saw earlier with `student_id + course_id`). So it's more accurate to say:

> A table has **one primary key constraint**, but that constraint can span **one or more columns**.

```sql
-- Single-column primary key (most common)
CREATE TABLE movies (
    id INTEGER PRIMARY KEY
);

-- Composite primary key — STILL just "one" primary key, made of 2 columns
CREATE TABLE stars (
    movie_id INTEGER,
    person_id INTEGER,
    PRIMARY KEY(movie_id, person_id)
);
```

You can't declare two separate, independent `PRIMARY KEY` constraints on two different columns in the same table — SQLite (and SQL generally) will reject that.

## Foreign Keys: yes, as many as you need

Correct — a table can have **many** foreign keys, no limit really, one for every relationship it needs to reference.

```sql
CREATE TABLE stars (
    movie_id INTEGER,
    person_id INTEGER,
    FOREIGN KEY(movie_id) REFERENCES movies(id),   -- foreign key #1
    FOREIGN KEY(person_id) REFERENCES people(id)   -- foreign key #2
);
```

A table like `enrollments` in a school database might even have three or four: `student_id`, `course_id`, `teacher_id`, `semester_id` — each pointing to a different parent table.

## Quick summary

|Key type|How many per table?|
|---|---|
|Primary Key|Exactly **1** (but can cover multiple columns)|
|Foreign Key|**0 to many**|
|Unique Key|**0 to many** (separate from the primary key)|

So your instinct is correct — you just want to remember that "one primary key" doesn't mean "one column." It means one uniqueness rule that identifies the row, even if that rule needs several columns to do its job.


[[1 - WHAT IS SQLITE3]]