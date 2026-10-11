
These three types all store something other than plain numbers or short text. ENUM and SET are about _restricting_ a column to a fixed list of choices, while BLOB is about storing _raw bytes_. Let's take them one at a time.

## ENUM: pick exactly one from a fixed list

```sql
CREATE TABLE tickets (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  title    VARCHAR(100) NOT NULL,
  status   ENUM('open', 'in_progress', 'closed') NOT NULL DEFAULT 'open'
);

INSERT INTO tickets (title, status) VALUES ('Fix login', 'in_progress');
```

You can think of it like a Java `enum`: the column can only hold one of the listed names. Where the analogy bends is that a Java enum is checked by the compiler, while this one is checked by the database when the row is stored. An invalid value is rejected in strict mode:

```sql
INSERT INTO tickets (title, status) VALUES ('Oops', 'done');
-- ERROR 1265: Data truncated for column 'status'
```

(Without strict mode, MariaDB quietly stores an empty string `''` instead, which is a good reason to keep strict mode on.)

Here is the part that surprises people: internally, MariaDB doesn't store the words. It stores a small number, the position of the value in your list (`'open'` is 1, `'in_progress'` is 2, `'closed'` is 3). That makes it compact, taking only 1 or 2 bytes, but it has three consequences:

- **Sorting follows the list order, not the alphabet.** `ORDER BY status` gives open, in_progress, closed, which is sometimes handy and sometimes a trap.
- **Inserting a bare number picks by position.** `INSERT ... VALUES (..., 2)` stores `'in_progress'`, not the text "2". Always quote your values to avoid this.
- **You can see both sides** with `SELECT status, status + 0 FROM tickets;`.

Changing the list later means altering the table:

```sql
ALTER TABLE tickets
  MODIFY status ENUM('open', 'in_progress', 'closed', 'archived') NOT NULL DEFAULT 'open';
```

Adding a new value at the _end_ is cheap. Inserting one in the middle or reordering can force MariaDB to rewrite the table, and, because the numbers shift, you must be careful that existing rows still mean what you think they mean.

That rigidity is why many developers use a small lookup table with a foreign key instead, whenever the list might grow or needs extra data like a label or a color. A rough rule is that if the options are truly stable (like `'pending'`, `'paid'`) an ENUM is fine, and if business people might add options, use a lookup table.

## SET: pick zero or more from a fixed list

```sql
CREATE TABLE users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  permissions SET('read', 'write', 'delete', 'admin') NOT NULL DEFAULT 'read'
);

INSERT INTO users (name, permissions) VALUES ('Sara', 'read,write');
INSERT INTO users (name, permissions) VALUES ('Omid', '');            -- empty set is allowed
```

A SET looks like an ENUM, but the column can hold _several_ of the listed values at once, written as one comma-separated string. The closest Java relative is `EnumSet`. Internally it's a bitmap, with one bit per member, so it takes 1 to 8 bytes and holds at most 64 members.

To query it, use `FIND_IN_SET`:

```sql
SELECT name FROM users WHERE FIND_IN_SET('write', permissions);
```

Some details worth knowing:

- Values are stored in the order of your definition, no matter how you typed them, and duplicates are dropped. `'write,read,read'` becomes `'read,write'`.
- Member names can't contain commas, since the comma is the separator.
- Don't use `permissions = 'write'` when you mean "includes write", because that matches only rows where `write` is the _only_ permission.

I'd call SET the most debatable of the three. It breaks a basic rule of good table design, that each column holds one value, because here a single column holds a list. Searching and indexing a list is awkward, and changing the allowed members needs an `ALTER TABLE`. The more flexible design is a junction table (like the `enrollments` example from the keys lesson), with one row per user-permission pair. SET is fine for a small, stable group of flags, but you'll see far more junction tables in real projects.

## BLOB: raw bytes

A BLOB ("binary large object") stores bytes with no meaning attached: an image, a PDF, a compressed file. Like TEXT, it comes in four sizes:

|Type|Maximum size|
|---|---|
|`TINYBLOB`|255 bytes|
|`BLOB`|65,535 bytes (about 64 KB)|
|`MEDIUMBLOB`|about 16 MB|
|`LONGBLOB`|about 4 GB|

The difference between BLOB and TEXT is that TEXT has a character set and collation (so `'a'` and `'A'` can compare as equal), while BLOB has neither. It's compared byte by byte, so nothing is converted, ignored, or case-folded.

```sql
CREATE TABLE images (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(100) NOT NULL,
  mime_type VARCHAR(50)  NOT NULL,
  data      MEDIUMBLOB   NOT NULL
);
```

Getting a file in with plain SQL uses `LOAD_FILE`:

```sql
INSERT INTO images (name, mime_type, data)
VALUES ('logo', 'image/png', LOAD_FILE('/tmp/logo.png'));
```

Just like `INTO OUTFILE` earlier, this runs on the **server**, so the file must be somewhere the database's Linux user can read, and your account needs the `FILE` privilege. If the result comes back `NULL`, that's almost always the reason. To get the bytes back out into a file:

```sql
SELECT data FROM images WHERE id = 1 INTO DUMPFILE '/tmp/logo_copy.png';
```

(`DUMPFILE` writes the raw bytes with no formatting, unlike `OUTFILE`.)

Don't `SELECT *` on a table with BLOBs in the terminal. You'll flood your screen with binary garbage. Select the other columns, or use `LENGTH(data)` to see the size.

Some practical points:

- You can't just index a whole BLOB. An index needs a prefix length, like `INDEX (data(20))`.
- There's a server limit called `max_allowed_packet` on how much data one statement can carry, so a large file may fail until you raise it.
- Big BLOBs bloat backups, slow down copies, and crowd out cache space for your useful data.

I also need to correct something I said in the datatypes lesson, where I told you `TEXT` columns can't have a default value. That was true of older versions, but since MariaDB 10.2.1 both BLOB and TEXT can have defaults, so on your Debian 13 install it's not a limitation.

## Using them from Spring Boot

In Java, a BLOB maps to a `byte[]`, and JPA marks it with `@Lob`:

```java
@Lob
private byte[] data;
```

An ENUM column is usually written as a Java `enum` with `@Enumerated(EnumType.STRING)`, which stores the names as text and works fine with a MariaDB `ENUM` or a plain `VARCHAR`. Avoid `EnumType.ORDINAL`, which stores the position number, because reordering your Java enum would silently change the meaning of old rows. It's the same trap as ENUM's hidden numbers, just on the Java side.

## Quick guidance

Use ENUM when exactly one value from a short, stable list is right, SET when you need a small, stable group of flags, and BLOB when you truly need the bytes inside the database. For files, the common pattern is to save the file on disk (or in object storage) and keep only its path in a `VARCHAR` column. BLOBs are most reasonable for small items, like thumbnails or icons, where keeping the data and its row together in one transaction and one backup is worth the cost. If you do store large ones, put them in their own table linked by a foreign key, so everyday queries on the main table stay light.



[[MySQL]]