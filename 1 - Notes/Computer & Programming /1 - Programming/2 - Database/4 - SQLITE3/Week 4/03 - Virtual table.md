
**You can call a view a "virtual table" in a conceptual sense**, but there is an important distinction.

### View as a virtual table (concept)

A view behaves like a table:

```sql
SELECT *
FROM adult_users;
```

You can:

- query it with `SELECT`
    
- use `WHERE`
    
- use `JOIN`
    
- use `ORDER BY`
    
- use it inside other queries
    

So from a user's perspective:

```text
Real Table              View
-----------             -----------
users                   adult_users
(data stored)           (query stored)
     │                       │
     └──────────┬────────────┘
                ▼
             SELECT
```

A view is a **virtual representation of data**.

---

### But technically, SQLite has a different thing called a Virtual Table

SQLite's **virtual table** is a special database object created by modules.

Example:

```sql
CREATE VIRTUAL TABLE email USING fts5(
    subject,
    body
);
```

This is not a view.

A virtual table:

- behaves like a table
    
- can have custom storage
    
- is implemented by a SQLite extension/module
    
- can represent data outside SQLite
    

Examples:

- Full-text search (`FTS5`)
    
- CSV files
    
- JSON sources
    
- external data sources
    

Architecture:

```text
VIEW:

SELECT
  |
  ▼
SQL Query
  |
  ▼
Existing Tables


Virtual Table:

SELECT
  |
  ▼
Virtual Table Module
  |
  ▼
Custom Data Source
```

---

### Correct terminology

|Object|Correct description|
|---|---|
|Table|Physical table storing rows|
|View|Virtual table / saved query / logical table|
|SQLite Virtual Table|Special table implemented by a module|

So:

> Calling a **view** a virtual table is acceptable when explaining the concept, but in SQLite documentation "virtual table" specifically means a different feature.

A better professional wording:

> "A view is a virtual (logical) table generated from a query."  
> "A SQLite virtual table is a special table implementation provided by an extension module."


[[SQlite]]