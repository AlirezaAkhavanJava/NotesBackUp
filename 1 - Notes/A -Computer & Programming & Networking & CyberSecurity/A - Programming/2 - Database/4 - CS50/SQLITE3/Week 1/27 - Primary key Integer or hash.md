> should a Primary key always be an increamenting number ? in CS50 i am seeing a hash like code called ISBN , so how that works , i think it is not an auto increament !

No, a primary key does **not** have to be an auto-incrementing number. That's just the _most common convenient default_. The actual requirement for a primary key is only:

1. It must be **unique** per row
2. It must be **not null**

Anything satisfying those two rules qualifies — a number, a string, a code, whatever.

## The ISBN example

CS50's `longlist.sql` / books database uses something like:

```sql
CREATE TABLE "longlist" (
    "isbn" TEXT,
    "title" TEXT NOT NULL,
    "author" TEXT NOT NULL,
    "year" INTEGER,
    PRIMARY KEY("isbn")
);
```

Here `isbn` (International Standard Book Number) is the primary key, and it's a **TEXT** field, not an integer. Why does this work?

**Because ISBNs are already naturally unique.** Every published book edition gets exactly one ISBN, assigned by an international standards body — no two books share one (barring rare cataloging errors). So instead of generating an artificial ID (a "surrogate key"), the database just uses a value that's _already guaranteed unique in the real world_ — a "natural key."

### Natural key vs Surrogate key

This is actually a named concept worth knowing:

||**Natural Key**|**Surrogate Key**|
|---|---|---|
|What it is|A real-world attribute that's inherently unique|An artificial ID generated just for the database|
|Examples|ISBN, SSN, email address, VIN (car), country code|`INTEGER PRIMARY KEY AUTOINCREMENT`, UUID|
|Pro|Meaningful, no extra column needed, often self-validating|Never changes, simple, fast to index, no external dependency|
|Con|Real-world values can occasionally change or turn out non-unique after all|Meaningless outside the database — a "1" tells you nothing|

### Why ISBN specifically makes sense as a key here

- It's **stable** — a book's ISBN doesn't change over its life
- It's **externally guaranteed unique** — you don't have to invent your own numbering scheme
- It **doubles as useful data** — you'd probably want to store the ISBN anyway, so why not let it also serve as the identifier instead of adding a redundant `id` column?

### When you'd prefer auto-increment instead

Auto-incrementing surrogate keys are usually better when:

- There's **no natural unique attribute** (e.g., a `comments` table — what would uniquely identify a comment except an artificial ID?)
- The "natural" identifier **could theoretically change** (e.g., using someone's email as a primary key is risky if they update their email — now you'd have to update every table referencing it as a foreign key)
- You want a **short, simple, fast** key for indexing/joining (an integer compares much faster than a long text string like an ISBN)

### So, rule of thumb

> Use a natural key when a real, stable, unique identifier already exists and makes sense.  
> Use a surrogate (auto-increment) key when no such natural attribute exists, or when the natural one might change.




[[1 - WHAT IS SQLITE3]]