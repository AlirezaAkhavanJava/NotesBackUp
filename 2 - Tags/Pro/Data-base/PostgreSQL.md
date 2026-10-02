

**PostgreSQL** (often just "Postgres") is a powerful open-source relational database that runs as a **separate server process**. It is the standard choice for serious back-ends because it combines strict correctness (full ACID), rich SQL features, and the ability to handle many users at once.

**Analogy:** In the SQLite lesson, the database was a notebook on your desk. PostgreSQL is a **bank branch**: a dedicated building with staff (the server process), a front desk (the network port), ID checks (users and passwords), and many customers served at the same time without getting in each other's way.

## Core idea: client/server

Unlike SQLite, PostgreSQL does not live inside your app. It runs on its own, listens on **port 5432** (this is the networking lesson in action), and your app connects over TCP.

```
Angular (browser) --HTTP/JSON--> Spring Boot --SQL over TCP:5432--> PostgreSQL
```

This split is why it scales: the database can run on a different machine, be backed up and replicated separately, and serve many app instances at once.

## Why it handles concurrency well: MVCC

SQLite allows only one writer at a time. PostgreSQL uses **MVCC (Multi-Version Concurrency Control)**: when a row is updated, it keeps the old version visible to transactions that started earlier and creates a new version for new ones.

**Result:** readers never block writers, and writers never block readers. Hundreds of users can read and write simultaneously, each seeing a consistent snapshot. (The cost: old row versions pile up and must be cleaned by a background process called **VACUUM**.)

## What makes it stand out

|Feature|Why it matters|
|---|---|
|**Strict standards and constraints**|Types are actually enforced (unlike SQLite's flexible typing); foreign keys are always on|
|**JSONB**|Store and index JSON documents inside a relational table, so it can partly replace MongoDB|
|**Rich types**|Arrays, UUIDs, timestamps with time zones, ranges, enums|
|**Extensions**|**PostGIS** (maps and geo data), **pgvector** (AI embeddings), full-text search|
|**Advanced SQL**|CTEs, window functions, partial and expression indexes|
|**Replication**|Copies of the database for backup and for spreading read traffic|

## Where to use it (decision guide)

**Use PostgreSQL when:**

- Building a real web or mobile back-end with multiple users (the default recommendation).
- Data correctness matters: orders, payments, accounts, inventory.
- You need complex queries, reports, or relationships between many tables.
- You want one database that also covers JSON, search, and geo needs.

**SQLite is still better for:** learning, tests, desktop and mobile apps, small single-user tools.

**Something else is better for:** a simple cache (Redis), huge unstructured document stores or extreme write scale (MongoDB, Cassandra), pure analytics on huge data (data warehouses like BigQuery).

## In a real back-end

Typical real-world setup:

1. **App layer:** several Spring Boot instances behind a load balancer.
2. **PostgreSQL:** one primary database (handles writes) plus optional **read replicas** (handle read-heavy queries).
3. **Connection pool:** opening a connection is expensive, so the app keeps a pool open and reuses them (Spring Boot includes **HikariCP** for this automatically).
4. **Migrations:** schema changes are written as versioned scripts and applied automatically with **Flyway** or **Liquibase**, instead of editing tables by hand.
5. **Backups:** scheduled backups and point-in-time recovery.
6. **Managed hosting:** most companies don't run it themselves; they use a managed service (AWS RDS, Google Cloud SQL, Azure, Supabase, Neon) that handles backups, updates, and failover.

PostgreSQL is widely used in production by companies of all sizes, including large consumer products.

## Hands-on on Debian 13

```bash
sudo apt install postgresql
sudo systemctl status postgresql          # it runs as a service
sudo -u postgres psql                     # open the admin shell
```

Inside `psql`:

```sql
CREATE USER alireza WITH PASSWORD 'secret';
CREATE DATABASE library OWNER alireza;
\c library          -- connect to the database
\dt                 -- list tables
\q                  -- quit
```

## Connecting from Spring Boot

Maven dependencies in `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

`application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.datasource.username=alireza
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
```

Compare with the SQLite URL: `jdbc:sqlite:library.db` was a file path, while this one has a **host, port, and database name**, because it is a network connection.

An entity and repository (Spring Data writes the SQL for you):

```java
@Entity
@Table(name = "books")
public class Book {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private int year;
    // getters and setters
}

public interface BookRepository extends JpaRepository<Book, Long> {
    List<Book> findByTitleContainingIgnoreCase(String text);
}
```

This is the "real project" layering from earlier: controller, then service, then repository, then PostgreSQL.

## Gotchas

- **Never hardcode the password** (see `${DB_PASSWORD}`); use environment variables, as the real-projects lesson said.
- **`ddl-auto=update` is for learning only.** In real projects use `validate` or `none` and manage the schema with Flyway migrations, so schema changes are reviewed and repeatable.
- **Run it in Docker for easy development:** `docker run -e POSTGRES_PASSWORD=secret -p 5432:5432 postgres` gives you a throwaway database, and your teammates get an identical setup.
- **Connection limits:** each connection costs memory, and PostgreSQL's default maximum is around 100. That is why pooling matters, and why you shouldn't open a new connection per request.
- **Indexes are not automatic** (except for primary keys and unique constraints). Slow queries on big tables usually need an index, and `EXPLAIN ANALYZE` shows how a query actually runs.
- **Case sensitivity:** unquoted table and column names are folded to lowercase, so naming things `snake_case` avoids surprises.
- **Transactions in Spring:** put `@Transactional` on service methods so several database operations succeed or fail together (this is the atomicity idea from the ACID lesson).





[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]