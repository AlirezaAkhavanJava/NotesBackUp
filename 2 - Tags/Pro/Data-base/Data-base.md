

## Start with the problem

Imagine you store books in a plain text file, `books.txt`:

```
1,Clean Code,2008
2,SICP,1985
```

This works until real life shows up:

1. **Finding:** to find one book, your code must read the whole file line by line. With 10 million lines, that is very slow.
2. **Duplicates:** nothing stops two lines with ID `1`.
3. **Two users at once:** both edit the file at the same moment, and one overwrites the other.
4. **Crashes:** the power dies halfway through a write, and the file is half-updated and corrupted.
5. **Connections:** if a book has an author, you copy the author's name onto every line, and when it changes you must fix every copy.

A **database** is software built to solve exactly these five problems. You hand it your data, and it takes care of speed, rules, simultaneous access, and safety.

## Mental model

Think of a **spreadsheet with a strict manager standing next to it**:

- The spreadsheet part: data in tables, with rows and columns.
- The manager part: refuses bad data, lets only one person change a cell at a time, keeps an index so lookups are instant, and keeps a diary so that after a crash everything can be restored.

## Two things people mix up

|Term|What it is|Example|
|---|---|---|
|**Database**|The stored data itself|The `library` data|
|**DBMS**|The program that manages the data|PostgreSQL, SQLite, MySQL|

You never touch the data files directly. You send a request to the DBMS, and it does the work:

```
Your code --"SELECT * FROM books"--> DBMS --reads files--> Disk
```

The language for these requests is **SQL**.

## The building blocks, with one tiny example

```
authors                     books
+----+-----------------+    +----+------------+------+-----------+
| id | name            |    | id | title      | year | author_id |
+----+-----------------+    +----+------------+------+-----------+
| 1  | Robert Martin   |    | 1  | Clean Code | 2008 | 1         |
| 2  | Harold Abelson  |    | 2  | SICP       | 1985 | 2         |
+----+-----------------+    +----+------------+------+-----------+
```

- **Table:** one kind of thing (`authors`, `books`).
- **Column:** one property (`title`).
- **Row:** one item (one book).
- **Primary key (`id`):** a unique label for each row, like a national ID number.
- **Foreign key (`author_id`):** a pointer to a row in another table. The author's name is stored **once**, and books just point to it. If the name changes, you fix it in one place.

```sql
SELECT books.title, authors.name
FROM books
JOIN authors ON authors.id = books.author_id;
```

`JOIN` follows the pointer and combines the two tables in the result.

## What the "manager" guarantees: ACID

Imagine a bank transfer: take 100 from account A, add 100 to account B.

- **Atomic:** both steps happen, or neither does. The money never disappears halfway.
- **Consistent:** the rules are never broken (no negative balance if forbidden, no pointer to a missing row).
- **Isolated:** two people transferring at the same time don't corrupt each other.
- **Durable:** once the database says "done," it survives a power cut.

This is the main reason to use a database instead of files.

## Where it sits in the whole system

```
Angular --HTTP/JSON--> Spring Boot --SQL--> Database
 (screen)               (brain)              (memory)
```

The browser shows things, Spring Boot decides things, and the database **remembers** things permanently. When your app restarts, its variables vanish, but the database still holds everything.

## The kinds, mapped to what you've already learned

|Kind|Examples|Shape of data|Lives where|
|---|---|---|---|
|**Relational (SQL)**|SQLite, PostgreSQL, MySQL|Tables with strict structure|SQLite: a file inside your app. PostgreSQL and MySQL: separate server|
|**Document (NoSQL)**|MongoDB|Flexible JSON-like documents|Separate server|

Simple rule of thumb: if your data has clear relationships and must be correct (orders, users, payments), start with a **relational** database. PostgreSQL is the usual choice for a real Spring Boot project, and SQLite is perfect for learning.

## Gotchas

- **A database is not a backup by itself.** If the disk dies, the data dies with it, so you need real backups.
- **Don't store everything in one giant table.** Splitting into linked tables avoids duplication. Splitting too far makes queries slow and complicated.
- **Without an index, searching a big table means scanning every row.** Indexes make reads fast but writes slightly slower.
- **The database is the single source of truth.** Validate data in Spring Boot _and_ enforce it in the database with constraints (`NOT NULL`, `UNIQUE`, foreign keys), because the database is the last line of defense.
- **Variables are not storage.** A Java `List` holds data only while the program runs; anything that must survive a restart belongs in the database.





[[SQlite]]
[[Spring Framework]]
[[PostgreSQL]]
[[MySQL]]
[[MongoDB]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]