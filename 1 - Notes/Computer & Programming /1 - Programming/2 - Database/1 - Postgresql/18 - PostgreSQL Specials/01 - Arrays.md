

An **array** is a single column value that holds an ordered list of items, all of the same type. Instead of creating a separate table for a short list of tags, phone numbers, or scores, you can store the whole list right in one column, like `{'java','spring','sql'}`. You can then read, search, and change the items inside it with built-in operators and functions.

Arrays are a PostgreSQL strength that many other databases don't have. They make small lists simple, but they are not a replacement for proper tables. In this lesson you will learn how to create arrays, read from them, search them, change them, index them, and know when to avoid them.

---

## 1. Declaring an array column

Add `[]` after any type name:

```sql
CREATE TABLE posts (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title  text NOT NULL,
    tags   text[],
    scores integer[],
    grid   integer[][]
);
```

Line by line:

- `text[]`: a list of text values.
- `integer[]`: a list of whole numbers.
- `integer[][]`: a two-dimensional array (a grid). You can nest as many dimensions as you need.

You can also write `text ARRAY` or `text[3]`. But PostgreSQL **ignores the size number**. `text[3]` can still hold 5 items. Don't rely on it as a limit.

---

## 2. Inserting arrays

There are two ways to write an array value.

**Way 1: the `ARRAY[...]` constructor** (the one most people prefer):

```sql
INSERT INTO posts (title, tags, scores)
VALUES ('Intro to Java', ARRAY['java', 'beginner'], ARRAY[90, 85, 77]);
```

**Way 2: the curly-brace text literal:**

```sql
INSERT INTO posts (title, tags, scores)
VALUES ('Spring Boot', '{"spring", "java", "web"}', '{70, 88}');
```

- Inside `{ }`, items are separated by commas.
- Text items with spaces or commas need double quotes: `'{"hello world", "a,b"}'`.

Two-dimensional arrays:

```sql
INSERT INTO posts (title, grid)
VALUES ('Matrix', ARRAY[[1,2,3],[4,5,6]]);
```

Every inner array must have the same length. PostgreSQL rejects uneven rows.

---

## 3. Reading items: indexing and slicing

**Important:** PostgreSQL arrays start at index **1**, not 0. This is different from Java.

|Expression|Meaning|
|---|---|
|`tags[1]`|The first item|
|`tags[2]`|The second item|
|`tags[1:2]`|A slice: items 1 through 2|
|`tags[:2]`|From the start up to item 2|
|`tags[2:]`|From item 2 to the end|

```sql
SELECT title, tags[1] AS first_tag, tags[1:2] AS first_two
FROM posts;
```

Results:

|title|first_tag|first_two|
|---|---|---|
|Intro to Java|java|{java,beginner}|
|Spring Boot|spring|{spring,java}|

If you ask for an index that doesn't exist, you get `NULL`, not an error.

For a 2D array: `grid[2][3]` reads row 2, column 3.

---

## 4. Useful array functions

|Function|What it does|Example|Result|
|---|---|---|---|
|`array_length(arr, dim)`|Number of items in a dimension|`array_length(tags, 1)`|`2`|
|`cardinality(arr)`|Total number of items (all dimensions)|`cardinality(tags)`|`2`|
|`array_upper(arr, 1)`|Highest index|`array_upper(tags, 1)`|`2`|
|`array_to_string(arr, sep)`|Join items into one string|`array_to_string(tags, ', ')`|`java, beginner`|
|`string_to_array(str, sep)`|Split a string into an array|`string_to_array('a,b,c', ',')`|`{a,b,c}`|
|`array_position(arr, x)`|Index of first match|`array_position(tags, 'java')`|`1`|
|`array_positions(arr, x)`|Indexes of all matches|`array_positions(tags, 'java')`|`{1}`|

Quick demo:

```sql
SELECT array_length(tags, 1), array_to_string(tags, ' | ')
FROM posts;
```

---

## 5. Searching inside arrays

This is where arrays become really useful. First, the operators:

|Operator|Meaning|
|---|---|
|`= ANY(arr)`|The value matches **at least one** item|
|`= ALL(arr)`|The value matches **every** item|
|`@>`|Left array **contains** the right array|
|`<@`|Left array is **contained by** the right array|
|`&&`|The two arrays **overlap** (share at least one item)|
|`=`|Arrays are exactly equal (same items, same order)|

### Is a single value in the array?

```sql
SELECT title FROM posts WHERE 'java' = ANY(tags);
```

Read it as: "is `'java'` equal to any item in `tags`?"

### Does the array contain all of these values?

```sql
SELECT title FROM posts WHERE tags @> ARRAY['java', 'web'];
```

Only rows whose `tags` include **both** `java` and `web` match.

### Does the array contain any of these values?

```sql
SELECT title FROM posts WHERE tags && ARRAY['web', 'beginner'];
```

`&&` is true if there's **at least one** item in common.

### Is the array a subset of a list?

```sql
SELECT title FROM posts WHERE tags <@ ARRAY['java', 'spring', 'web', 'beginner'];
```

True when **every** tag of the row is in the list on the right.

### ANY vs ALL with numbers

```sql
SELECT title FROM posts WHERE 80 < ALL(scores);   -- every score is above 80
SELECT title FROM posts WHERE 80 < ANY(scores);   -- at least one score is above 80
```

---

## 6. Changing arrays (DML)

### Add an item to the end

```sql
UPDATE posts SET tags = array_append(tags, 'new') WHERE id = 1;
-- same as: SET tags = tags || 'new'
```

### Add an item to the beginning

```sql
UPDATE posts SET tags = array_prepend('first', tags) WHERE id = 1;
```

### Join two arrays

```sql
UPDATE posts SET tags = tags || ARRAY['x', 'y'] WHERE id = 1;
-- or array_cat(tags, ARRAY['x','y'])
```

### Remove every copy of a value

```sql
UPDATE posts SET tags = array_remove(tags, 'beginner') WHERE id = 1;
```

### Replace a value

```sql
UPDATE posts SET tags = array_replace(tags, 'java', 'Java') WHERE id = 1;
```

### Change one item by position

```sql
UPDATE posts SET tags[2] = 'advanced' WHERE id = 1;
```

If you assign to a position beyond the end, PostgreSQL stretches the array and fills the gap with `NULL`.

### Replace the whole array

```sql
UPDATE posts SET tags = ARRAY['one', 'two'] WHERE id = 1;
```

> **Note:** like `jsonb`, an array is stored as one value. Updating a single item rewrites the whole array. That's fine for short lists, and slow for huge ones.

---

## 7. Turning arrays into rows (and back)

### `unnest`: one row per item

```sql
SELECT id, unnest(tags) AS tag FROM posts;
```

Results:

|id|tag|
|---|---|
|1|java|
|1|beginner|
|2|spring|
|2|java|
|2|web|

This is the key to counting and grouping by array items:

```sql
SELECT tag, count(*)
FROM posts, unnest(tags) AS tag
GROUP BY tag
ORDER BY count(*) DESC;
```

Line by line:

- `unnest(tags) AS tag` expands each array into rows.
- `GROUP BY tag` groups identical tags together.
- `count(*)` counts how many posts use each tag.

To keep each item's position, use `WITH ORDINALITY`:

```sql
SELECT t.tag, t.pos
FROM posts, unnest(tags) WITH ORDINALITY AS t(tag, pos)
WHERE id = 1;
```

### `array_agg`: rows back into one array

```sql
SELECT array_agg(title ORDER BY title) FROM posts;
-- {"Intro to Java","Spring Boot"}
```

Often used with `GROUP BY` to collect child values into one list per parent.

### `ARRAY(subquery)`: build an array from a query

```sql
SELECT ARRAY(SELECT title FROM posts ORDER BY id);
```

---

## 8. Indexing arrays: making searches fast

Without an index, `@>`, `&&`, and `<@` scan every row. Add a **GIN index** (the same type you saw with `jsonb`):

```sql
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);
```

This index speeds up `@>`, `<@`, `&&`, and `=`. It does **not** help `= ANY(tags)`. If you need fast lookups for a single value, rewrite it as containment:

```sql
-- Can use the GIN index
WHERE tags @> ARRAY['java']

-- Cannot use it
WHERE 'java' = ANY(tags)
```

---

## 9. Constraints and defaults

```sql
CREATE TABLE courses (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tags  text[] NOT NULL DEFAULT '{}',
    CHECK (cardinality(tags) <= 5)
);
```

- `DEFAULT '{}'`: an empty array when none is given.
- `CHECK (cardinality(tags) <= 5)`: a real way to limit the size, since `text[5]` doesn't.

You can also reject empty or `NULL` items with a check such as `CHECK (array_position(tags, NULL) IS NULL)`.

---

## 10. NULL and empty arrays: a tricky spot

These are three different things:

|Value|Meaning|
|---|---|
|`NULL`|No array at all|
|`'{}'`|An array that exists but has no items|
|`'{NULL}'`|An array with one item, which is NULL|

Watch out: `array_length('{}', 1)` returns `NULL`, not `0`. Use `cardinality('{}')`, which returns `0`, when you need a count.

---

## 11. Using arrays from Java (JDBC)

Since you use Java with PostgreSQL, here's how to work with arrays.

**Reading:**

```java
try (ResultSet rs = stmt.executeQuery("SELECT tags FROM posts")) {
    while (rs.next()) {
        Array sqlArray = rs.getArray("tags");
        String[] tags = (String[]) sqlArray.getArray();
        System.out.println(Arrays.toString(tags));
    }
}
```

- `rs.getArray(...)` returns a `java.sql.Array`.
- `.getArray()` converts it to a normal Java array. Cast it to the right type.

**Writing:**

```java
String sql = "INSERT INTO posts (title, tags) VALUES (?, ?)";
try (PreparedStatement ps = conn.prepareStatement(sql)) {
    ps.setString(1, "JDBC Arrays");
    Array arr = conn.createArrayOf("text", new String[]{"java", "jdbc"});
    ps.setArray(2, arr);
    ps.executeUpdate();
}
```

- `conn.createArrayOf("text", ...)` builds a JDBC array. The first argument is the PostgreSQL element type name.

---

## 12. Related concept: a join table (short summary)

A **join table** (or "junction table") is the classic relational way to store lists: one table for posts, one for tags, and a third table linking them with `post_id` and `tag_id`. It takes more setup than an array, but it gives you foreign keys, tag metadata, and easy many-to-many queries.

---

## 13. Arrays or a separate table? A quick guide

|Use an **array** when…|Use a **separate table** when…|
|---|---|
|The list is short and simple|The list can grow large|
|Items are plain values (tags, scores)|Items have their own columns or details|
|You mostly read the whole list together|You need to join items to other tables|
|You don't need foreign keys on items|You need foreign keys or per-item updates|

---

## 14. Common mistakes to avoid

1. **Using index 0.** PostgreSQL starts at 1, so `tags[0]` returns `NULL`.
2. **Trusting the size in `text[3]`.** It's ignored. Use a `CHECK` instead.
3. **Using `= ANY` and expecting an index.** Switch to `@>` for index support.
4. **Mixing up `NULL`, `'{}'`, and `'{NULL}'`.** They behave differently.
5. **Storing huge lists in an array.** Every update rewrites the whole value.
6. **Forgetting quotes in the curly-brace format** for items with spaces or commas.




[[PostgreSQL]]