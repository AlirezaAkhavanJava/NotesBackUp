**MySQL** is a popular open-source relational database that, like PostgreSQL, runs as a **separate server process** and your app connects to it over the network. It is one of the most widely deployed databases in the world, especially in web hosting and the classic PHP/WordPress ecosystem.

**Analogy:** If PostgreSQL is a bank branch with every specialist service, MySQL is a **fast, efficient post office**: simpler, extremely well known, optimized for handling a huge number of everyday requests quickly, and available almost everywhere.

## Core idea

Same client/server model you saw with PostgreSQL: it listens on **port 3306** and your Spring Boot app talks to it over TCP.

```
Spring Boot --SQL over TCP:3306--> MySQL
```

The SQL you already learned (`CREATE TABLE`, `SELECT`, `JOIN`) works almost identically. What differs is the engine underneath and some advanced features.

## Storage engine: InnoDB

MySQL's distinctive design is that it has pluggable **storage engines**, which are the components that actually store and retrieve data on disk.

- **InnoDB** (the default today): supports ACID transactions, foreign keys, and row-level locking. It uses MVCC too, so readers and writers don't block each other much.
- **MyISAM** (old): no transactions and no foreign keys. Fast for reads but unsafe, so you should avoid it in new projects.

## MySQL vs PostgreSQL

||MySQL|PostgreSQL|
|---|---|---|
|**Philosophy**|Simple, fast, easy to start|Standards-strict, feature-rich|
|**Default port**|3306|5432|
|**Advanced SQL**|Improved a lot (CTEs and window functions since 8.0), but historically behind|Very strong|
|**JSON**|`JSON` type, decent|`JSONB` with powerful indexing|
|**Extensions**|Few|Many (PostGIS, pgvector)|
|**Strictness**|Historically lenient with bad data (depends on SQL mode)|Strict by default|
|**Replication**|Mature and very widely used|Mature, strong|
|**Ownership**|Oracle (plus the community fork **MariaDB**)|Community-governed|

For a typical CRUD back-end, both work well, and the choice often comes down to team experience and what the company already runs.

## Where it is used

- Web applications and content sites (WordPress, many PHP apps).
- High-traffic read-heavy systems, with many read replicas.
- Companies with large existing MySQL infrastructure; some very large internet companies built on it.
- Managed cloud versions: AWS RDS and Aurora, Google Cloud SQL, Azure.

**Choose MySQL when** your team or hosting already uses it, or you want a simple, proven database for a standard web app. **Choose PostgreSQL when** you need advanced features, richer types, or strict correctness by default. For a new Spring Boot project with no constraints, PostgreSQL is the more common recommendation.

## MariaDB

MariaDB is a **fork** of MySQL, created by MySQL's original developers after Oracle bought MySQL. It is mostly compatible, and on Debian, `apt install mariadb-server` actually installs MariaDB, not Oracle's MySQL. For learning, the difference barely matters.

## Hands-on on Debian 13

```bash
sudo apt install mariadb-server       # MySQL-compatible server
sudo systemctl status mariadb
sudo mysql                            # admin shell
```

```sql
CREATE DATABASE library;
CREATE USER 'alireza'@'localhost' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON library.* TO 'alireza'@'localhost';
USE library;

CREATE TABLE books (
    id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    year  INT
);
```

Notice the small syntax differences from other databases: `AUTO_INCREMENT` (SQLite uses `AUTOINCREMENT`, PostgreSQL uses `GENERATED ... AS IDENTITY` or `SERIAL`), and users are tied to a host (`'alireza'@'localhost'`).

## Connecting from Spring Boot

`pom.xml`:

```xml
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <scope>runtime</scope>
</dependency>
```

`application.properties`:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/library
spring.datasource.username=alireza
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
```

Your entity and repository code stays **exactly the same** as with PostgreSQL. That is the benefit of JPA/Hibernate: it hides most database differences behind an abstraction, the same idea as the API lesson. Only the driver dependency and the URL change.

## Gotchas

- **Use `utf8mb4`, not `utf8`.** MySQL's old `utf8` is a broken 3-byte version that can't store emoji or some characters. Modern defaults use `utf8mb4`, but check older setups.
- **Strict mode matters.** Without `STRICT_TRANS_TABLES`, old MySQL could silently truncate or accept invalid data instead of raising an error. Modern versions enable it by default.
- **Always check the storage engine:** tables must be InnoDB to get transactions and foreign keys.
- **Case sensitivity of table names depends on the OS:** table names are case-sensitive on Linux but not on Windows by default, which can break code moved between systems. Use lowercase `snake_case`.
- **Never hardcode passwords**, same rule as before; use environment variables.
- **Portability is not perfect.** Plain CRUD moves easily between MySQL and PostgreSQL, but database-specific features (JSON functions, full-text search, upserts) use different syntax, so avoid them unless you need them.
- **Run it in Docker for development:** `docker run -e MYSQL_ROOT_PASSWORD=secret -p 3306:3306 mysql` gives you a throwaway instance.


[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]