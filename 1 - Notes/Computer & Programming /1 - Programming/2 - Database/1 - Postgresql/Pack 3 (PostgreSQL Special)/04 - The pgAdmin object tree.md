![[1792937407.png]]

What you are looking at is pgAdmin's **Object Browser**. It is a map of everything that can exist inside a PostgreSQL server, drawn as a tree. PostgreSQL stores things in nested containers: a **server** holds **databases**, a database holds **schemas** and a few database-wide objects, and a schema holds the objects you use every day, like tables, views, and functions. Each folder in your screenshots is one _kind_ of object. Most folders are empty on a fresh database, and that is normal. They fill up only when you create something of that kind.

Your two screenshots show two different levels. Image 1 shows what lives directly inside a **database** (`dummy`). Image 2 shows what lives inside a **schema** (`public`). Once you see which level an object belongs to, the tree stops feeling random, and you also know _where_ to look when something goes wrong.

---

## 1. The map

|Level|Nodes|Shared across|
|---|---|---|
|**Server** (`PostgreSQL-17`)|Databases, Login/Group Roles, Tablespaces|The whole server|
|**Database** (`dummy`)|Casts, Catalogs, Event Triggers, Extensions, Foreign Data Wrappers, Languages, Publications, Schemas, Subscriptions|One database|
|**Schema** (`public`)|Aggregates, Collations, Domains, FTS Configurations, FTS Dictionaries, FTS Parsers, FTS Templates, Foreign Tables, Functions, Materialized Views, Operators, Procedures, Sequences, Tables, Trigger Functions, Types, Views|One schema|

Your server has six databases: `DimmerTick`, `doitlater`, `dummy`, `ethan`, `postgres`, and `sb`. They are completely separate from each other. A table in `dummy` cannot be queried from `ethan` (unless you use a foreign data wrapper, covered below).

---

## 2. How to work with any node in pgAdmin

The same few moves work everywhere:

1. **Create:** right-click the folder, choose **Create**, then pick the object type. A dialog opens with tabs. The last tab, **SQL**, shows the exact SQL pgAdmin will run. Reading that tab is one of the best ways to learn the syntax.
2. **Inspect:** click an object, then use the right-hand panel. **Properties** shows its settings, **SQL** shows its `CREATE` script, **Dependencies** and **Dependents** show what it needs and what needs it.
3. **Change or remove:** right-click the object, then **Properties** (to edit) or **Delete** (and choose **Delete (Cascade)** only if you accept dropping dependents).
4. **Run your own SQL:** right-click the database, then **Query Tool**. Press **F5** to run. Everything in this lesson can be typed there.
5. **Refresh:** if you create something with SQL, the tree won't notice until you select the parent folder and press **F5**.
6. **See hidden things:** pgAdmin hides built-in objects by default. There is a "show system objects" option in Preferences (under the Browser section), which is useful for exploring.

---

## 3. Server level (just outside your first screenshot)

### Login/Group Roles

**What it is:** A _role_ is PostgreSQL's single idea for both users and groups. A role with the `LOGIN` right is what you'd call a user. A role without it is usually a group that holds permissions.

**The problem it solves:** Your Spring Boot app should not connect as the all-powerful `postgres` user. Roles let you give each app or person only the permissions they need.

```sql
CREATE ROLE app_user LOGIN PASSWORD 'change_me';
CREATE ROLE readers;                         -- a group, no login
GRANT readers TO app_user;                   -- app_user joins the group
GRANT USAGE ON SCHEMA public TO readers;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readers;
```

Line by line: the first line makes a user that can log in. The second makes an empty group. The third puts the user in the group. The last two give the group read access, so every member inherits it.

**Errors:** `permission denied for table orders` (the role lacks a `GRANT`), `role "app_user" does not exist`, `password authentication failed` (wrong password, or a restricted `pg_hba.conf` rule).

### Tablespaces

**What it is:** A named folder on disk where PostgreSQL may store data files.

**The problem it solves:** Putting big or busy tables on a faster or larger disk.

```sql
CREATE TABLESPACE fast_ssd LOCATION '/mnt/ssd/pgdata';
CREATE TABLE big_log (id bigint, msg text) TABLESPACE fast_ssd;
```

The folder must already exist, be empty, and belong to the `postgres` operating-system user. Creating a tablespace needs a superuser. Most small projects never need one. The built-in ones are `pg_default` and `pg_global`.

---

## 4. Database level (your first screenshot)

### Casts

**What it is:** The rulebook that says _how_ to convert one type into another. It is the engine behind the `::` operator from our earlier lesson.

**The problem it solves:** Letting PostgreSQL convert between your own types and others.

```sql
CREATE TYPE priority AS ENUM ('low', 'medium', 'high');

CREATE FUNCTION int_to_priority(int) RETURNS priority
LANGUAGE sql IMMUTABLE
AS $$ SELECT (ARRAY['low','medium','high'])[$1]::priority $$;

CREATE CAST (int AS priority) WITH FUNCTION int_to_priority(int);

SELECT 2::priority;     -- medium
```

Line by line: we make an enum, then a function that turns 1, 2, 3 into its values (arrays count from 1). `CREATE CAST` registers that function as the official int-to-priority conversion. Now `2::priority` works.

You can add `AS ASSIGNMENT` or `AS IMPLICIT` to let it run automatically, but be careful: implicit casts can cause surprising behavior and hide bugs.

**Errors:** `cast from type X to type Y already exists` (a built-in conversion exists already), `must be owner of type ...`. By default this folder looks empty because pgAdmin shows only user-made casts. The built-in ones live in `pg_cast`.

### Catalogs

**What it is:** The database's own **built-in information tables**: its table of contents. Two things live here:

- `pg_catalog`: PostgreSQL's internal system tables and functions.
- `information_schema`: a standard, friendlier set of views describing your objects (pgAdmin labels it "ANSI").

**The problem it solves:** Letting you ask the database about itself.

```sql
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public';
SELECT version();
```

**Rule:** read from catalogs freely, but never modify them by hand. That can corrupt the database.

### Event Triggers

**What it is:** Code that runs automatically when someone runs a **DDL command** (`CREATE`, `ALTER`, `DROP`). This is different from a normal trigger, which reacts to row changes (`INSERT`, `UPDATE`, `DELETE`).

**The problem it solves:** Auditing schema changes or blocking dangerous ones.

```sql
CREATE TABLE ddl_audit (
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    at      timestamptz NOT NULL DEFAULT now(),
    who     text,
    command text,
    object  text
);

CREATE FUNCTION log_ddl() RETURNS event_trigger
LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
    INSERT INTO ddl_audit (who, command, object)
    VALUES (current_user, r.command_tag, r.object_identity);
  END LOOP;
END;
$$;

CREATE EVENT TRIGGER audit_ddl ON ddl_command_end
EXECUTE FUNCTION log_ddl();
```

Line by line: the table stores the log. The function loops over every command that just finished and writes one row for each. The event trigger connects the function to the `ddl_command_end` event.

Main events: `ddl_command_start`, `ddl_command_end`, `sql_drop`, `table_rewrite`, and since PostgreSQL 17, `login`.

**Errors and warnings:** `permission denied to create event trigger` (superuser only). A buggy event trigger can block _all_ DDL, including the command you'd use to fix it. If that happens, `ALTER EVENT TRIGGER audit_ddl DISABLE;` or, in PostgreSQL 17, set `event_triggers = off`. Test on a scratch database like `dummy` first.

### Extensions

**What it is:** A packaged add-on that installs types, functions, operators, and indexes in one command.

**The problem it solves:** Adding big features without writing them yourself.

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- fuzzy text matching
CREATE EXTENSION IF NOT EXISTS btree_gist;    -- used in our booking example

SELECT crypt('my_password', gen_salt('bf'));  -- hashed password

SELECT name, default_version, installed_version
FROM pg_available_extensions
ORDER BY name;
```

In pgAdmin, right-click **Extensions**, then **Create**, and pick from the dropdown. It only lists extensions that are installed on the server's machine.

**Errors:** `extension "postgis" is not available` means the package is missing on the server. On Debian you would install it with something like `sudo apt install postgresql-17-postgis-3`, then retry. `permission denied to create extension` means you need a superuser or a "trusted" extension. Extensions install into one schema (usually `public`), and one database only.

### Foreign Data Wrappers (FDW)

**What it is:** A connector that lets PostgreSQL read (and sometimes write) **outside data** as if it were a normal table: another PostgreSQL database, a CSV file, MySQL, and so on.

**The problem it solves:** Querying data in another place without copying it first.

There is a chain of four parts, and pgAdmin shows them nested:

|Part|Meaning|
|---|---|
|**Foreign data wrapper**|The driver (`postgres_fdw`, `file_fdw`)|
|**Foreign server**|Where the other data lives (host, port, database)|
|**User mapping**|Which login to use there|
|**Foreign table**|The table-shaped window onto the remote data|

Example A, a CSV file:

```sql
CREATE EXTENSION file_fdw;
CREATE SERVER csv_files FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE movies_csv (title text, year int)
SERVER csv_files
OPTIONS (filename '/var/lib/postgresql/movies.csv', format 'csv', header 'true');

SELECT * FROM movies_csv WHERE year > 2020;
```

Example B, another PostgreSQL database:

```sql
CREATE EXTENSION postgres_fdw;

CREATE SERVER remote_pg FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'db2.example.com', port '5432', dbname 'sales');

CREATE USER MAPPING FOR CURRENT_USER SERVER remote_pg
OPTIONS (user 'reader', password 'secret');

IMPORT FOREIGN SCHEMA public LIMIT TO (orders) FROM SERVER remote_pg INTO public;
```

`IMPORT FOREIGN SCHEMA` saves you from writing each foreign table by hand.

**Errors:** `could not open file ... Permission denied` (the `postgres` OS user can't read the file; reading server files needs a superuser or the `pg_read_server_files` role), `user mapping not found for "..."`, `could not connect to server`. Foreign tables can't have normal indexes or enforce constraints, and `file_fdw` is read-only.

### Languages

**What it is:** The programming languages you may write functions in.

**The problem it solves:** Plain SQL can't loop, branch, or use variables. A procedural language can.

|Language|Notes|
|---|---|
|`sql`|Built in. Simple functions.|
|`plpgsql`|Built in. PostgreSQL's own scripting language. The most used.|
|`plpython3u`, `plperl`, `pltcl`|Add-ons installed as extensions. The `u` means _untrusted_: it can touch the operating system, so only superusers can use it.|

You normally don't create languages by hand. You install them: `CREATE EXTENSION plpython3u;`. You choose one with `LANGUAGE plpgsql` at the end of a function.

---

### Publications and Subscriptions (logical replication)

These two are a pair, so I'll teach them together.

**What they are:**

- A **publication** (on the _source_ database) says "these tables' changes are available to share."
- A **subscription** (on the _target_ database) says "send me those changes."

**The problem they solve:** Copying data between PostgreSQL databases continuously: a read-only reporting copy, a migration with little downtime, or feeding another system.

On the source:

```sql
CREATE PUBLICATION pub_orders FOR TABLE orders, customers;
-- or: CREATE PUBLICATION pub_all FOR ALL TABLES;
```

On the target (the tables must already exist with matching columns):

```sql
CREATE SUBSCRIPTION sub_orders
CONNECTION 'host=source-host dbname=shop user=repl_user password=secret'
PUBLICATION pub_orders;
```

What happens: the target first copies the existing rows, then keeps receiving every `INSERT`, `UPDATE`, and `DELETE`.

**Requirements and errors:**

- The source needs `wal_level = logical` in `postgresql.conf` (a restart is required).
- The connecting role needs the `REPLICATION` attribute.
- DDL is **not** replicated. If you add a column on the source, you must add it on the target yourself.
- `cannot update table "orders" because it does not have a replica identity and publishes updates`: the table needs a primary key, or `ALTER TABLE orders REPLICA IDENTITY FULL;`.
- `CREATE SUBSCRIPTION` can't run inside a transaction block.

On your single local server, these two folders will stay empty unless you set up replication.

### Schemas

You met these in the DDL lesson: a schema is a namespace inside a database. Your `dummy` database has just one, `public`, which is what your second screenshot shows. A note for PostgreSQL 15 and later: ordinary users no longer get permission to create tables in `public` by default, which causes `permission denied for schema public`. Fix it with `GRANT CREATE ON SCHEMA public TO app_user;`.

---

## 5. Schema level (your second screenshot)

I'll group these so they're easier to remember.

### Group A: Objects that hold or present data

#### Tables

**What it is:** The core object. It stores rows in typed columns. This is where your data lives.

```sql
CREATE TABLE clients (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    status      text NOT NULL DEFAULT 'active',
    updated_at  timestamptz NOT NULL DEFAULT now()
);
```

In pgAdmin, expand a table and you'll see its own sub-folders: **Columns, Constraints, Indexes, RLS Policies, Rules, Triggers**. To see data, right-click the table, then **View/Edit Data**, then **All Rows**. Two extras worth knowing: `CREATE UNLOGGED TABLE` (faster, but emptied after a crash) and **partitioned tables** (one big table split into pieces by range or list: `PARTITION BY RANGE (placed_at)`).

#### Views

**What it is:** A saved `SELECT` with a name. It stores no data, just the query.

**The problem it solves:** Reusing a long query, and hiding columns you don't want others to see.

```sql
CREATE VIEW active_clients AS
SELECT id, name FROM clients WHERE status = 'active';

SELECT * FROM active_clients;
```

Two useful options: `WITH CHECK OPTION` blocks inserts through the view that wouldn't pass its `WHERE`, and `WITH (security_invoker = true)` (PostgreSQL 15+) makes the view respect the _caller's_ permissions rather than the owner's.

#### Materialized Views

**What it is:** A view that **stores its result**, like a snapshot.

**The problem it solves:** Heavy reports that are too slow to recompute on every request.

```sql
CREATE MATERIALIZED VIEW daily_sales AS
SELECT placed_at::date AS day, sum(total) AS revenue
FROM orders GROUP BY 1;

CREATE UNIQUE INDEX ON daily_sales (day);
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales;
```

`CONCURRENTLY` refreshes without blocking readers, but it requires a unique index. Without one you get: `cannot refresh materialized view "daily_sales" concurrently` with a hint to create a unique index. The data is stale until you refresh it (for example from a Spring `@Scheduled` job).

#### Sequences

**What it is:** A counter object that hands out numbers. Identity and `serial` columns use one behind the scenes.

```sql
CREATE SEQUENCE invoice_no_seq START 1000;
SELECT nextval('invoice_no_seq');    -- 1000
SELECT currval('invoice_no_seq');    -- 1000
SELECT setval('invoice_no_seq', 5000);
```

**The most common real-world error:** after importing rows with explicit ids, new inserts fail with `duplicate key value violates unique constraint "clients_pkey"`. The counter is behind the data. Fix it:

```sql
SELECT setval(pg_get_serial_sequence('clients', 'id'),
              (SELECT max(id) FROM clients));
```

#### Foreign Tables

Table-shaped windows onto outside data, from the FDW section above. They show up here, in the schema, because the _table_ belongs to a schema even though the _wrapper_ belongs to the database.

#### Domains

**What it is:** A base type with a built-in rule, reusable across tables.

```sql
CREATE DOMAIN positive_money AS numeric(12,2) CHECK (VALUE >= 0);
CREATE TABLE invoices (id serial PRIMARY KEY, amount positive_money);

ALTER DOMAIN positive_money ADD CONSTRAINT max_limit CHECK (VALUE < 1000000);
```

The benefit is that you change the rule in one place and every column using it follows. Error: `value for domain positive_money violates check constraint`.

#### Types

**What it is:** Your own data types. There are four kinds: **enum** (a fixed list), **composite** (several fields in one value), **range**, and **base** (rare, written in C).

```sql
CREATE TYPE address AS (street text, city text, zip text);

CREATE TABLE places (id serial PRIMARY KEY, home address);
INSERT INTO places (home) VALUES (ROW('1 Main St', 'London', 'E1'));

SELECT (home).city FROM places;
```

The parentheses in `(home).city` are required. Without them you get `missing FROM-clause entry for table "home"`, because PostgreSQL thinks `home` is a table name. For enums, remember from the DDL lesson that values can be added but not easily removed.

---

### Group B: Objects that hold code

#### Functions

**What it is:** A named, reusable piece of logic that **returns a value**. You call it inside queries.

```sql
CREATE OR REPLACE FUNCTION price_with_tax(p_total numeric, p_rate numeric DEFAULT 0.20)
RETURNS numeric
LANGUAGE sql IMMUTABLE
AS $$ SELECT round(p_total * (1 + p_rate), 2) $$;

SELECT price_with_tax(100);        -- 120.00
SELECT price_with_tax(100, 0.05);  -- 105.00
```

Line by line: `p_` is just a naming habit for parameters. `DEFAULT 0.20` makes the second argument optional. `IMMUTABLE` promises the same input always gives the same output, which lets PostgreSQL optimize and index on it. `$$ ... $$` is _dollar quoting_: it wraps the body so you don't need to escape quotes inside.

A function with logic, in `plpgsql`:

```sql
CREATE FUNCTION grade(score int) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  IF score IS NULL THEN
    RAISE EXCEPTION 'score is required';
  ELSIF score >= 90 THEN RETURN 'A';
  ELSIF score >= 75 THEN RETURN 'B';
  ELSE RETURN 'C';
  END IF;
END;
$$;
```

A function that returns rows:

```sql
CREATE FUNCTION orders_of(p_client bigint)
RETURNS TABLE (id bigint, total numeric)
LANGUAGE sql AS $$ SELECT id, total FROM orders WHERE customer_id = p_client $$;

SELECT * FROM orders_of(7);
```

Volatility labels: `IMMUTABLE` (pure), `STABLE` (same result within one query), `VOLATILE` (default, may change anytime).

**Errors:** `function price_with_tax(unknown) does not exist` with a hint about casts (you need `::numeric`), `cannot change return type of existing function` (drop it, then recreate), `control reached end of function without RETURN`.

#### Trigger Functions

**What it is:** A function declared `RETURNS trigger`. pgAdmin lists it in its own folder because it can only be attached to a table trigger. It runs automatically when rows change.

**The problem it solves:** Keeping rules in the database no matter which app writes the data, like auto-updating `updated_at`.

```sql
CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_clients_updated
BEFORE UPDATE ON clients
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

Line by line: `NEW` is the row about to be saved. We set its `updated_at`, then `RETURN NEW` so the save continues. `BEFORE UPDATE ... FOR EACH ROW` means it runs once per row, just before the write.

|Special variable|Meaning|
|---|---|
|`NEW` / `OLD`|The row after / before the change|
|`TG_OP`|`'INSERT'`, `'UPDATE'`, or `'DELETE'`|
|`TG_TABLE_NAME`|The table that fired it|

**Errors:** `record "new" has no field "updated_at"` (the table lacks that column), `control reached end of trigger procedure without RETURN`. Remember that a `BEFORE` trigger returning `NULL` silently _cancels_ that row's change. In pgAdmin, the trigger itself appears under the table, in its **Triggers** folder.

#### Procedures

**What it is:** Like a function, but you run it with `CALL`, it returns no value, and it can **control transactions** (`COMMIT` / `ROLLBACK` inside it).

**The problem it solves:** Long jobs that should commit in batches, such as processing a million rows without holding one giant transaction.

```sql
CREATE PROCEDURE archive_old_orders(p_days int)
LANGUAGE plpgsql AS $$
DECLARE n int;
BEGIN
  LOOP
    DELETE FROM orders
    WHERE id IN (SELECT id FROM orders
                 WHERE placed_at < now() - make_interval(days => p_days)
                 LIMIT 1000);
    GET DIAGNOSTICS n = ROW_COUNT;
    EXIT WHEN n = 0;
    COMMIT;
  END LOOP;
END;
$$;

CALL archive_old_orders(365);
```

It deletes in chunks of 1000 and commits after each chunk. `GET DIAGNOSTICS n = ROW_COUNT` reads how many rows were just deleted.

**Error:** `invalid transaction termination` happens when `COMMIT` runs inside a procedure that was called from within an already-open transaction (such as a Spring `@Transactional` method). Call it from a non-transactional context, or drop the `COMMIT`.

**Function vs procedure:**

||Function|Procedure|
|---|---|---|
|Called with|`SELECT f(...)`|`CALL p(...)`|
|Returns a value|Yes|No (only `INOUT` parameters)|
|Can `COMMIT` inside|No|Yes|
|Usable inside a query|Yes|No|

#### Aggregates

**What it is:** A function that **collapses many rows into one value**, like `sum`, `count`, `avg`, or `string_agg`.

```sql
SELECT status, count(*), string_agg(name, ', ' ORDER BY name)
FROM clients GROUP BY status;
```

You can build your own. It needs a _state function_ (what to do with each row), a _state type_, and a starting value:

```sql
CREATE AGGREGATE product(numeric) (
    SFUNC    = numeric_mul,
    STYPE    = numeric,
    INITCOND = '1'
);

SELECT product(x) FROM generate_series(1, 5) AS x;    -- 120
```

Starting at 1, each row multiplies the running total: 1 × 1 × 2 × 3 × 4 × 5. The folder is empty by default because pgAdmin hides the built-in aggregates.

#### Operators

**What it is:** The symbols between values: `+`, `=`, `||`, `@>`, `&&`, `<->`. Each one is secretly a function with a symbol attached.

You can define your own:

```sql
CREATE FUNCTION text_contains_ci(text, text) RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$ SELECT position(lower($2) in lower($1)) > 0 $$;

CREATE OPERATOR ~~~ (
    LEFTARG  = text,
    RIGHTARG = text,
    FUNCTION = text_contains_ci
);

SELECT 'Hello World' ~~~ 'world';    -- true
```

**Errors:** `operator does not exist: integer = text` (you need a cast), and `operator is not unique` (several operators fit, add casts). To make a custom operator use an index, you need an _operator class_, which is advanced and rarely needed.

---

### Group C: Text rules (collations and full-text search)

#### Collations

**What it is:** The rules for **comparing and sorting text**: alphabet order, accents, case, and language.

**The problem it solves:** `ORDER BY name` can give different orders on different machines, and you may want case-insensitive comparison.

```sql
SELECT name FROM clients ORDER BY name COLLATE "C";        -- byte order: uppercase first
SELECT name FROM clients ORDER BY name COLLATE "en_US";    -- human order (if installed)

CREATE COLLATION case_insensitive (
    provider = icu, locale = 'und-u-ks-level2', deterministic = false
);

SELECT 'ABC' = 'abc' COLLATE case_insensitive;   -- true
```

**Warnings:**

- In PostgreSQL 17, `LIKE` does not work with nondeterministic collations like the one above. A common alternative is the `citext` extension.
- After an operating-system upgrade (for example a Debian release upgrade), you may see `WARNING: database has a collation version mismatch`. Sorting rules changed, so indexes on text may be wrong. Fix it by running `REINDEX` as the warning suggests.
- `collation "x" for encoding "UTF8" does not exist`: that locale isn't installed.

#### The four FTS folders (Full-Text Search)

These four work as one pipeline. Remember the `tsvector` lesson? This is how it works inside.

|Stage|Object|Job|
|---|---|---|
|1|**Parser**|Splits raw text into tokens and labels each one (word, number, email, URL...)|
|2|**Dictionary**|Turns each token into a clean _lexeme_ (lowercase, stemmed, or dropped as a stop word)|
|3|**Template**|The blueprint a dictionary is built from|
|4|**Configuration**|The recipe: "for tokens of type X, use dictionaries Y then Z"|

When you write `to_tsvector('english', text)`, `'english'` is a **configuration**.

**FTS Parsers.** Look at what the default parser sees:

```sql
SELECT * FROM ts_parse('default', 'Email me at a@b.com now');
```

It returns each token with a type id. `ts_token_type('default')` lists the type names. Writing your own parser needs C code and superuser rights, so almost nobody does it.

**FTS Templates.** The built-in ones are `simple`, `synonym`, `thesaurus`, `ispell`, and `snowball`. See them with `SELECT * FROM pg_ts_template;`. Creating new ones also needs C code, so you will mostly just _use_ them in the next step.

**FTS Dictionaries.** Test what a dictionary does to a word:

```sql
SELECT ts_lexize('english_stem', 'running');   -- {run}
SELECT ts_lexize('english_stem', 'the');       -- {}   (a stop word, thrown away)

CREATE TEXT SEARCH DICTIONARY english_nostop (TEMPLATE = snowball, language = english);
SELECT ts_lexize('english_nostop', 'the');     -- {the} (no stop-word list, so it stays)
```

The second dictionary is built from the `snowball` template, but with no stop-word list.

**FTS Configurations.** Build a configuration that ignores accents:

```sql
CREATE EXTENSION unaccent;
CREATE TEXT SEARCH CONFIGURATION my_english (COPY = english);

ALTER TEXT SEARCH CONFIGURATION my_english
    ALTER MAPPING FOR hword, hword_part, word
    WITH unaccent, english_stem;

SELECT to_tsvector('my_english', 'Café running');   -- 'cafe':1 'run':2
```

Line by line: we copy the `english` configuration, then tell it that for word-type tokens it should first run `unaccent` (removes the accent), then `english_stem` (stems the word). Searching for "cafe" now finds "Café".

To debug any of this, `ts_debug('english', 'some text')` shows every step for every token.

---

## 6. How these map to Spring Boot

|Object|How you meet it from Java|
|---|---|
|Roles|`spring.datasource.username` and `password`|
|Schemas|`spring.jpa.properties.hibernate.default_schema`|
|Extensions|`CREATE EXTENSION` in a Flyway migration (`V1__extensions.sql`)|
|Tables|`@Entity` and `@Table`|
|Views|`@Entity` with `@Immutable`, mapped read-only|
|Materialized views|Same as views, plus a `@Scheduled` job that runs `REFRESH`|
|Sequences|`@SequenceGenerator` with `GenerationType.SEQUENCE`, or identity columns|
|Enum types, Domains|`@JdbcTypeCode(SqlTypes.NAMED_ENUM)`, or `CAST(:x AS type)` in native queries|
|Functions|Native query: `SELECT price_with_tax(:t)`|
|Procedures|`CALL` in a native query, or `@Procedure` / `SimpleJdbcCall`|
|Trigger functions|Invisible to Java. Remember that the DB changes a row behind Hibernate's back, so call `refresh()` if you need the new value|
|Full-text search|Native query with `@@` (see the `tsvector` lesson)|
|Publications, Subscriptions, Tablespaces, Event Triggers|Server administration, not application code|

---

## 7. The same objects in `psql`

If you ever work without pgAdmin (on your Debian machine, for example), these commands show the same folders:

|pgAdmin node|`psql` command|
|---|---|
|Databases / Roles / Tablespaces|`\l` / `\du` / `\db`|
|Schemas|`\dn`|
|Extensions|`\dx`|
|Casts|`\dC`|
|Event Triggers|`\dy`|
|Foreign Data Wrappers / Servers / Foreign Tables|`\dew` / `\des` / `\det`|
|Languages|`\dL`|
|Publications / Subscriptions|`\dRp` / `\dRs`|
|Aggregates|`\da`|
|Collations|`\dO`|
|Domains|`\dD`|
|FTS Configurations / Dictionaries / Parsers / Templates|`\dF` / `\dFd` / `\dFp` / `\dFt`|
|Functions, Procedures, Trigger Functions|`\df`|
|Materialized Views / Views|`\dm` / `\dv`|
|Operators|`\do`|
|Sequences|`\ds`|
|Tables|`\dt`|
|Types|`\dT`|

Add `+` for more detail (`\dt+`), and a name to inspect one object (`\d clients`).

---

## Related concepts, in short

- **Row-Level Security (RLS Policies):** the folder inside each table. It limits _which rows_ a role can see, using `CREATE POLICY` after `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- **Rules:** an older feature that rewrites queries. Triggers are almost always the better choice today.
- **Search path:** the list of schemas PostgreSQL checks when you write a bare name like `clients`. See it with `SHOW search_path;`.
- **Ownership and privileges:** every object has an owner, and `GRANT` / `REVOKE` control who else may use it. Most "permission denied" errors in this lesson come from here.

---

## Quick way to remember it all

- **Server:** people (roles), disks (tablespaces), and databases.
- **Database:** add-ons (extensions), outside data (FDWs), languages, copying (publications / subscriptions), event watchers, casts, and the catalogs that describe everything.
- **Schema:** data holders (tables, views, sequences, types, domains), code (functions, procedures, trigger functions, aggregates, operators), and text rules (collations, the four FTS objects).





[[PostgreSQL]]