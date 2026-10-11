
# Database Configuration in Spring Boot, and the Types of JDBC URLs

## 1. The scenario

It's Tuesday. You're building `LibraryApp`, a Spring Boot app with a `Book` entity and a `BookRepository`. Yesterday you added `spring-boot-starter-data-jpa` and the app crashed with _"Failed to configure a DataSource"_. Today you fix it the quick way: add H2 to `pom.xml`, and it starts. You create a few books through your controller. Everything works.

Then you restart the app and `GET /books` returns `[]`. Your data is gone.

You switch to PostgreSQL, since that's what real apps use. You type a URL into `application.properties`, run the app, and get:

```
java.sql.SQLException: No suitable driver found for jdbc:postgres://localhost:5432/library
```

You stare at it. The driver is in `pom.xml`. What's wrong? Spotting the single missing `ql` in that URL is exactly what this lesson trains you to do.

## 2. The core mental model

> **A JDBC URL is a structured address that tells Java _which driver to use_, _where the database lives_, and _which database to open_. `application.properties` is where you hand that address, plus credentials, to Spring Boot, which builds one `DataSource` (a connection pool) from it.**

Think of it like a postal address on a package: the courier company (driver), the city (host and port), the apartment (database name), and delivery instructions (parameters). Get the courier name wrong and nobody picks up the package.

## 3. Step-by-step walkthrough

### Step 1: Anatomy of a JDBC URL

```
jdbc:postgresql://localhost:5432/library?sslmode=disable
 |       |           |       |     |           |
 |       |           |       |     |           +-- parameters (driver-specific)
 |       |           |       |     +-- database name
 |       |           |       +-- port
 |       |           +-- host
 |       +-- subprotocol: SELECTS THE DRIVER
 +-- always "jdbc"
```

The **subprotocol** is the important part. Each driver registers itself with Java's `DriverManager`. When a connection is requested, `DriverManager` asks each registered driver: _"Do you accept this URL?"_ The PostgreSQL driver says yes only if the URL starts with `jdbc:postgresql:`. A URL starting with `jdbc:postgres:` gets a "no" from every driver, hence "No suitable driver found."

### Step 2: The minimal configuration

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.datasource.username=library_user
spring.datasource.password=secret123
```

Here is what Boot does with these three lines:

```
application.properties
        |
        v
DataSourceProperties  (binds spring.datasource.*)
        |
        v
HikariDataSource      (connection pool, created at startup)
        |
        v
EntityManagerFactory  (Hibernate, uses the DataSource)
        |
        v
Your BookRepository
```

You don't need `spring.datasource.driver-class-name` in most cases. Boot derives the driver class from the URL prefix. Set it only for unusual drivers.

### Step 3: The JPA/Hibernate properties

The `spring.datasource.*` keys control the **connection**. The `spring.jpa.*` keys control **how Hibernate behaves** on top of it:

```properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

|`ddl-auto`|What happens at startup|Use for|
|---|---|---|
|`none`|Nothing|Production with migration tools|
|`validate`|Checks that tables match entities, fails if not|Production|
|`update`|Adds missing tables/columns, never drops|Learning|
|`create`|Drops and recreates the schema every start|Throwaway tests|
|`create-drop`|Creates at start, drops at shutdown|Tests|

### Step 4: The types of URLs

```
+------------------+---------------------------------------------------------+
| Database         | URL pattern                                             |
+------------------+---------------------------------------------------------+
| H2 in-memory     | jdbc:h2:mem:library                                     |
| H2 file          | jdbc:h2:file:./data/library                             |
| SQLite (file)    | jdbc:sqlite:./library.db                                |
| PostgreSQL       | jdbc:postgresql://localhost:5432/library                |
| MySQL            | jdbc:mysql://localhost:3306/library                     |
| MariaDB          | jdbc:mariadb://localhost:3306/library                   |
| SQL Server       | jdbc:sqlserver://localhost:1433;databaseName=library    |
| Oracle           | jdbc:oracle:thin:@//localhost:1521/XEPDB1               |
+------------------+---------------------------------------------------------+
```

Notice they fall into **three families**:

1. **Embedded, in-memory** (`jdbc:h2:mem:`): no host, no port. The database is a Java object inside your JVM. It dies when the JVM dies. This is your "data vanished" mystery.
2. **Embedded, file-based** (`jdbc:h2:file:`, `jdbc:sqlite:`): still inside your process, but persisted to a file path.
3. **Client-server** (PostgreSQL, MySQL, and so on): a separate process listens on a port, and your app is just a client.

Note the oddities: SQL Server uses `;databaseName=` instead of `/library`, and Oracle uses `@//`. Don't memorize every pattern; look up the official driver docs when you add a new database.

**A special case, MongoDB.** MongoDB is not JDBC at all. There is no `jdbc:` prefix and no `DataSource`, because it's a document store accessed through Spring Data MongoDB:

```properties
spring.data.mongodb.uri=mongodb://localhost:27017/library
```

Different technology, different property family, but the same idea: one URI describing driver/protocol, host, port, and database.

## 4. The conflict, failure, and tricky moment

Back to your PostgreSQL attempt. Your `application.properties` says:

```properties
spring.datasource.url=jdbc:postgres://localhost:5432/library
```

Spring Boot starts, Hikari tries to open a connection, and `DriverManager` runs through its list of registered drivers:

```
DriverManager: "jdbc:postgres://..." - who accepts this?
   org.postgresql.Driver      -> acceptsURL? NO (expects "jdbc:postgresql:")
   org.h2.Driver (if present) -> acceptsURL? NO
   ...
   -> SQLException: No suitable driver found
```

**Why can't the system decide on its own?** Because it has no authority to guess. "postgres" and "postgresql" look obviously similar to you, but to a string-prefix check they're completely different. If Spring silently "fixed" typos, it might connect you to the wrong database, which is far worse than crashing.

You fix the typo and get a new error:

```
FATAL: password authentication failed for user "library_user"
```

or:

```
FATAL: database "library" does not exist
```

or:

```
Connection to localhost:5432 refused.
```

Each message maps to one layer of the address, and that is your debugging map:

```
"No suitable driver"         -> the URL PREFIX is wrong (courier)
"Connection refused"         -> host/port wrong or server not running (city)
"database does not exist"    -> database name wrong or not created (apartment)
"authentication failed"      -> username/password wrong (key to the door)
```

## 5. Resolution

On Debian 13, set up PostgreSQL properly:

```bash
sudo apt install postgresql
sudo systemctl status postgresql        # is the server running?

sudo -u postgres psql
```

Inside `psql`:

```sql
CREATE USER library_user WITH PASSWORD 'secret123';
CREATE DATABASE library OWNER library_user;
\q
```

Verify outside of Spring, so you know whether the problem is the database or your config:

```bash
psql -h localhost -U library_user -d library
```

If that works, your URL parts are right. Now correct `application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.datasource.username=library_user
spring.datasource.password=secret123
spring.jpa.hibernate.ddl-auto=update
```

State before and after:

```
BEFORE:  App --"jdbc:postgres:"--> [no driver accepts] --> CRASH

AFTER:   App --"jdbc:postgresql:"--> PostgreSQL driver --TCP:5432--> [library DB]
                                                                       ^ tables created by Hibernate
```

Restart the app, create books, restart again: the data survives, because it now lives in a separate server process, not in your JVM's memory.

## 6. Advanced example: dev, prod, secrets, and a silent trap

**The situation.** Your team wants H2 for local development (fast, zero setup) and PostgreSQL in production. The production password must not be committed to Git. You set up three files:

```
src/main/resources/
├── application.properties        # shared defaults
├── application-dev.properties    # dev profile
└── application-prod.properties   # prod profile
```

`application.properties`:

```properties
spring.profiles.active=dev
spring.jpa.show-sql=false
```

`application-dev.properties`:

```properties
spring.datasource.url=jdbc:h2:mem:library
spring.jpa.hibernate.ddl-auto=create-drop
spring.h2.console.enabled=true
```

`application-prod.properties`:

```properties
spring.datasource.url=jdbc:postgresql://db-host:5432/library
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
spring.datasource.hikari.maximum-pool-size=10
```

On the server you run:

```bash
export DB_USER=library_user
export DB_PASSWORD='S3cret!'
java -jar libraryapp.jar --spring.profiles.active=prod
```

### Why it works: property precedence

Spring merges property sources in a fixed priority order. Higher beats lower:

```
HIGHEST  1. Command-line args        --spring.profiles.active=prod
         2. OS environment variables  SPRING_DATASOURCE_URL=...
         3. application-{profile}.properties
LOWEST   4. application.properties
```

Boot uses **relaxed binding**: the environment variable `SPRING_DATASOURCE_URL` maps to `spring.datasource.url` (uppercase, dots become underscores). That means you can override any value without touching files, which is how Docker and Kubernetes inject configuration. The profile file layers over the base file: `prod` replaces `dev`'s URL and keeps shared keys you didn't override.

### The underlying mechanism

`${DB_PASSWORD}` is a **placeholder**: Spring resolves it from the environment when binding properties. If `DB_PASSWORD` is not set, startup fails with `Could not resolve placeholder 'DB_PASSWORD'`. That is good, because it fails loudly.

### What could go wrong

1. **The silent H2 trap.** Both the H2 and PostgreSQL drivers are on your classpath, and in some profile you forget to set `spring.datasource.url`. Boot sees no URL and an embedded database on the classpath, so it **quietly starts an in-memory H2**. Your app "works" in production, saving everything to RAM. The next restart wipes it all. The invariant to remember: _no URL plus an embedded driver means an embedded database, with no error._ Mitigation: in production, use `ddl-auto=validate`, which will fail immediately because H2 has none of your tables.
2. **Wrong profile active.** You deploy and forget `--spring.profiles.active=prod`. The `dev` default wins and you're on H2 again. Same symptoms, same mitigation.
3. **Special characters in passwords.** In a properties file, `#` can start a comment, and `!` and `$` can be misread by shells and placeholder resolution. Quote values in the shell (`'S3cret!'`) and prefer environment variables over hard-coding.
4. **Pool exhaustion.** Hikari's default pool size is 10 connections. If your database allows only 5 connections and you run 3 app instances, you'll get connection errors under load that look unrelated to configuration.

### What if...

**...your PostgreSQL requires SSL (typical for cloud databases)?** Add a parameter to the URL:

```properties
spring.datasource.url=jdbc:postgresql://db-host:5432/library?sslmode=require
```

**...you want to use a non-default schema?** `?currentSchema=library_schema`.

**...you want H2 data to survive restarts without installing a server?** Switch from in-memory to file-based: `jdbc:h2:file:./data/library`. Different URL family, different lifetime.

**...you want H2 to survive between connections inside one run?** `jdbc:h2:mem:library;DB_CLOSE_DELAY=-1` keeps it alive until the JVM exits, since by default H2 may drop an in-memory database when the last connection closes.

**...your Debian PostgreSQL gives `password authentication failed` even with the right password?** Debian's default setup uses _peer_ authentication for local socket connections, but JDBC connects over TCP (`localhost`), which uses the password rules in `pg_hba.conf`. Make sure the user has a password set (`ALTER USER library_user PASSWORD '...';`) and that the `host` lines in `/etc/postgresql/*/main/pg_hba.conf` use `scram-sha-256`.

## 7. Contrastive comparison: embedded vs client-server

**Embedded (H2 / SQLite):**

```
+---------------- JVM process ----------------+
|  Your Spring Boot app                       |
|     |                                       |
|     v  (plain method calls)                 |
|  [ H2 engine ] --> memory or ./library.mv.db|
+---------------------------------------------+
```

**Client-server (PostgreSQL):**

```
+--- JVM process ---+      TCP :5432      +--- postgres process ---+
| Spring Boot app   | <=================> | PostgreSQL server      |
| Hikari pool       |   (network, auth)   |    |                   |
+-------------------+                     |    v  /var/lib/...    |
                                          +------------------------+
```

||Embedded|Client-server|
|---|---|---|
|Setup|None|Install, create user + DB|
|Failure modes|Mostly data loss/file locks|Network, auth, server down|
|Concurrency|Limited|Built for many clients|
|Multiple app instances|Not possible (in-memory) / risky (file)|Natural|
|Use for|Learning, tests, prototypes|Anything real|

**When to use which:** Use embedded for unit tests and your first hour of learning. Use client-server as soon as data matters, or if more than one process needs the data. Many teams run integration tests against a real PostgreSQL (often in Docker) because H2's SQL dialect differs subtly, and a test that passes on H2 can fail on production PostgreSQL.

## 8. Key mental model recap

- The JDBC URL has three jobs: **select the driver** (subprotocol), **locate the database** (host, port, name), and **tune the connection** (parameters).
- `spring.datasource.*` builds the connection pool; `spring.jpa.*` controls Hibernate's behavior on top of it.
- Three URL families: in-memory (dies with the JVM), file-based (persists), client-server (separate process).
- Errors map to layers: _no suitable driver_ means a bad prefix, _refused_ means a bad host/port or server down, _does not exist_ means a bad DB name, _authentication failed_ means bad credentials.
- Profiles and environment variables let one codebase run against different databases without code changes. Precedence: command line > environment > profile file > base file.
- No URL plus an embedded driver means a silent in-memory database.

```
                 Add JPA starter
                       |
                       v
           Is a URL configured?
              /              \
            NO                YES
            |                  |
  Embedded driver on        Prefix matches a
  classpath?                registered driver?
     /        \               /          \
   YES        NO            YES          NO
    |          |             |            |
 Silent H2   CRASH:          v         CRASH:
 in-memory   "Failed to   Server reachable?   "No suitable
 (data lost) configure"    /        \         driver"
                         YES        NO
                          |          |
                  DB exists +      CRASH:
                  creds valid?     "Connection
                   /      \         refused"
                 YES      NO
                  |        |
               APP RUNS   CRASH: "auth failed" /
                          "database does not exist"
```

**Takeaway:** The JDBC URL is a precise address, not a hint, so when the database connection fails, read the error to find which part of the address (driver, host, database, or credentials) is wrong.





[[Spring Framework]]