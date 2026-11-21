
# What is a driver?

A driver (JDBC Driver) is a software component that allows a Java application to communicate with a specific database, such as PostgreSQL, MySQL, or Oracle. It implements the JDBC API and handles establishing connections, sending SQL queries, receiving results, and converting data between Java and the database. For example, the PostgreSQL JDBC Driver allows your Spring Boot application to connect to and interact with a PostgreSQL database.

Difference between Driver and Dialect: A driver handles the actual communication between your Java application and the database, while a dialect tells Hibernate how to generate SQL compatible with that database. In simple terms, the dialect determines what SQL to write, and the driver handles sending that SQL to the database and receiving the results.

## The problem it solves

Your Java code wants to talk to a database. But PostgreSQL, MySQL, SQLite and the others all speak their own **network protocol**, which is a private, low-level language of bytes over a connection. You don't want to learn each one.

A **driver** is a piece of software that handles that language for you. You write plain Java, and the driver translates it into whatever your specific database understands.

Think of it like a phone charger cable. Your phone and the wall socket are different shapes. The cable is the adapter that makes them work together.

## Where it sits

```
Your Java code
      ↓
   JDBC API          (standard interfaces: Connection, Statement, ResultSet)
      ↓
 JDBC Driver         (PostgreSQL-specific implementation)
      ↓
   PostgreSQL
```

**JDBC** (Java Database Connectivity) is the standard. It is just a set of interfaces that say "a connection must be able to do this, a statement must be able to do that." It contains no database knowledge at all.

The **driver** is the real implementation of those interfaces for one database. That is why your code can stay almost the same when you switch databases. You swap the driver, and the interfaces remain.

## What a driver actually does

- **Opens the connection**, using the host, port, username and password.
- **Speaks the database's protocol**, sending your SQL and reading the reply.
- **Converts data types**, for example a database `timestamp` into a Java `LocalDateTime`.
- **Reports errors**, turning database error codes into Java `SQLException`s.

## How you add it

In a Spring Boot project, you add the driver as a dependency in `pom.xml`:

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

Then you tell Spring where the database is:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=secret
```

Line by line:

1. **The dependency** puts the driver's code on your classpath. `runtime` means you don't need it to compile, only to run.
2. **The `jdbc:postgresql://` part of the URL** is how Java finds the right driver. Each driver registers the URL prefix it understands, and Java matches them up.
3. **The username and password** are passed to the driver when it opens the connection.

You may also see this line:

```properties
spring.datasource.driver-class-name=org.postgresql.Driver
```

You usually **don't need it**. Spring Boot reads the URL and works out the driver class for you. You only add it if auto-detection fails.

## Driver vs dialect

Since these two get mixed up so often, here they are side by side:

||Driver|Dialect|
|---|---|---|
|Belongs to|JDBC (Java)|Hibernate|
|Job|Carries messages to and from the database|Decides what SQL to write|
|Without it|Can't connect at all|Connects, but SQL may be wrong|
|Example|`org.postgresql.Driver`|`PostgreSQLDialect`|

Hibernate writes the SQL (using the dialect), then hands it to JDBC, and the driver delivers it.

## Related concept: connection pool

Opening a connection is slow. A **connection pool** (Spring Boot uses HikariCP by default) opens several connections ahead of time and lends them out. The driver creates each connection, and the pool keeps them ready so your app doesn't wait.





[[Spring Framework]]