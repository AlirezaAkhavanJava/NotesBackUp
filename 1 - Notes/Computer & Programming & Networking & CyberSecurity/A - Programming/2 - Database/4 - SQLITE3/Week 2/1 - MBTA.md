

**MBTA** refers to the **Massachusetts Bay Transportation Authority** — the public transportation agency serving the Boston area.

Massachusetts Bay Transportation Authority

### What is MBTA?

The MBTA operates transportation such as:

- 🚇 Subway
    
- 🚌 Buses
    
- 🚆 Commuter rail
    
- ⛴️ Ferries
    

CS50 uses **MBTA data as a realistic example** for learning databases and SQLite3.

---

## What does MBTA have to do with SQLite3?

CS50 gives you transportation data and asks you to model/query it using **SQLite3**.

Imagine the MBTA has information like:

```text
stations
--------
id
name

routes
--------
id
name

stops
--------
id
station_id
route_id
```

You can represent that information in SQLite:

```sql
CREATE TABLE stations (
    id INTEGER,
    name TEXT
);

CREATE TABLE routes (
    id INTEGER,
    name TEXT
);

CREATE TABLE stops (
    id INTEGER,
    station_id INTEGER,
    route_id INTEGER
);
```

Now SQLite stores the MBTA data in a structured relational database.

---

# Where does "schema" come in?

The **schema** is the design/structure of your database.

For example:

```text
Database
│
├── stations
│   ├── id
│   └── name
│
├── routes
│   ├── id
│   └── name
│
└── stops
    ├── id
    ├── station_id
    └── route_id
```

That's essentially the database's **schema**.

It tells SQLite:

> "These are my tables, these are their columns, and these are the relationships between them."

---

## Why does CS50 use MBTA?

Because a transportation system naturally demonstrates **relational database concepts**.

For example:

```text
Station
   │
   │ has
   ▼
Stops
   │
   │ belongs to
   ▼
Route
```

So you can practice:

### `SELECT`

```sql
SELECT name
FROM stations;
```

### `WHERE`

```sql
SELECT name
FROM stations
WHERE name = 'Harvard';
```

### `JOIN`

```sql
SELECT stations.name, routes.name
FROM stops
JOIN stations ON stops.station_id = stations.id
JOIN routes ON stops.route_id = routes.id;
```

### `GROUP BY`

```sql
SELECT route_id, COUNT(*)
FROM stops
GROUP BY route_id;
```

### Subqueries

```sql
SELECT name
FROM stations
WHERE id IN (
    SELECT station_id
    FROM stops
    WHERE route_id = 1
);
```

So **MBTA isn't a SQLite feature**.

It's simply the **real-world dataset/domain** CS50 uses to teach you how to design and query a relational database with SQLite.

### The mental model

```text
REAL WORLD
   │
   │ MBTA transportation system
   ▼
DATA
   │
   │ stations, routes, stops...
   ▼
DATABASE
   │
   │ SQLite3
   ▼
SCHEMA
   │
   │ tables + columns + relationships
   ▼
SQL
   │
   │ SELECT, JOIN, GROUP BY, etc.
   ▼
ANSWERS
```

**MBTA = the real-world problem.**  
**SQLite3 = the database engine.**  
**Schema = the structure/design of the database.**  
**SQL = the language you use to work with that database.**




[[1 - SQL 🦬]]
[[1 - WHAT IS SQLITE3 🍕]]