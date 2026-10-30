


Jakarta EE is a set of **standard specifications** for building enterprise Java applications: web apps, REST APIs, database access, transactions, messaging, security, and more. It is not a framework you download and run. It is a collection of agreed-upon rules (APIs) that describe how these features should look and behave in Java. Different vendors then build the real software that follows those rules.

It is the new name of **Java EE**. Oracle handed Java EE to the Eclipse Foundation in 2017, and it was renamed Jakarta EE. If you have used Servlets, JPA, or `@Inject`, you have already used parts of it. Spring Boot uses many of them under the hood.

---

## 1. The big idea: specification vs. implementation

This is the one idea that makes everything else easy.

A **specification** is a document plus a set of Java interfaces and annotations. It says _what_ should happen. An **implementation** is real code that does it.

|Specification (the rules)|Example implementations|
|---|---|
|Jakarta Servlet|Tomcat, Jetty, Undertow|
|Jakarta Persistence (JPA)|Hibernate, EclipseLink|
|Jakarta REST (JAX-RS)|Jersey, RESTEasy|
|Jakarta CDI (dependency injection)|Weld, OpenWebBeans|
|Jakarta Bean Validation|Hibernate Validator|

You write your code against the specification, for example `jakarta.persistence.Entity`. Hibernate or EclipseLink does the real work. Because you code against the rules, you can switch the implementation without rewriting your code.

You probably know this from Spring Boot already. When you write `@Entity` and use Spring Data JPA, `@Entity` comes from Jakarta Persistence, and Hibernate runs behind it.

---

## 2. A short history

The name changes confuse many people, so here is the timeline.

|Year|What happened|
|---|---|
|1999 to 2017|**J2EE, then Java EE**, owned by Sun, then Oracle|
|2017|Oracle donates it to the Eclipse Foundation|
|2018|Renamed **Jakarta EE** (Oracle kept the "Java" trademark)|
|2019|**Jakarta EE 8**: same as Java EE 8, only the name changed. Packages are still `javax.*`|
|2020|**Jakarta EE 9**: all packages renamed from `javax.*` to `jakarta.*`|
|2022|**Jakarta EE 10**: new features, Java 11+|
|2025|**Jakarta EE 11**: modern Java (17+), cleanup, and new specs such as Jakarta Data|

### The `javax` to `jakarta` rename

Oracle kept the rights to the `javax` name, so the community had to rename the packages. This is a one-time breaking change:

```java
// Old (Java EE / Jakarta EE 8)
import javax.persistence.Entity;
import javax.servlet.http.HttpServletRequest;

// New (Jakarta EE 9 and later)
import jakarta.persistence.Entity;
import jakarta.servlet.http.HttpServletRequest;
```

**This affects you directly.** Spring Boot 2 used `javax.*`. Spring Boot 3 and later use `jakarta.*`. If you copy an old tutorial and your imports fail, this is almost always the reason. Change `javax.` to `jakarta.` and it usually works.

---

## 3. What is inside Jakarta EE

Jakarta EE is a family of many specifications. Here are the ones you will meet most:

|Area|Specification|What it gives you|
|---|---|---|
|Web|**Servlet**|Handle HTTP requests and responses|
|Web|**Faces** (JSF)|Server-side component UI|
|REST|**Jakarta REST** (JAX-RS)|`@Path`, `@GET`, and similar for REST APIs|
|Data|**Persistence** (JPA)|Map Java objects to database tables|
|Data|**Transactions** (JTA)|Commit or roll back work as one unit|
|Data|**Data** (new in 11)|Repository-style interfaces, like Spring Data|
|Core|**CDI**|Dependency injection and scopes|
|Core|**Bean Validation**|`@NotNull`, `@Size`, `@Email`|
|JSON|**JSON-P / JSON-B**|Read, write, and bind JSON|
|Messaging|**Messaging** (JMS)|Send messages through queues and topics|
|Security|**Security**|Authentication and authorization|
|Other|Mail, Batch, Concurrency, WebSocket|Email, batch jobs, async tasks, real-time|

### Profiles: you don't need everything

Not every app needs all of it, so Jakarta EE is split into three sizes:

- **Core Profile:** small. Good for microservices and cloud use (CDI Lite, REST, JSON).
- **Web Profile:** the middle. Servlet, CDI, JPA, REST, Validation, Transactions. This covers most web apps.
- **Platform (Full):** everything, including messaging, batch, and mail.

---

## 4. How it runs

A Jakarta EE app traditionally runs on an **application server** or **runtime**. This is a program that implements the specs and hosts your code.

Common runtimes: **WildFly**, **Payara**, **Open Liberty**, **GlassFish**, **TomEE**.

You package your app as a `.war` file and deploy it to the server. The server provides the Servlet engine, injection, transactions, and more.

Spring Boot works differently: it embeds Tomcat inside your app and runs as a plain `java -jar`. Many modern Jakarta EE runtimes can also run this way now, so the gap is smaller than it used to be.

---

## 5. A small example, line by line

Here is a tiny REST API using only Jakarta EE specs.

**The entity (Jakarta Persistence):**

```java
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;

@Entity
public class Book {

    @Id
    @GeneratedValue
    private Long id;

    @NotBlank
    private String title;

    // getters and setters
}
```

- `@Entity` tells JPA this class maps to a database table.
- `@Id` marks the primary key, and `@GeneratedValue` lets the database create the value.
- `@NotBlank` comes from Bean Validation. It rejects empty titles.

**The REST resource (Jakarta REST + CDI + JPA):**

```java
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

@Path("/books")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BookResource {

    @Inject
    EntityManager em;

    @GET
    public List<Book> all() {
        return em.createQuery("select b from Book b", Book.class)
                 .getResultList();
    }

    @POST
    @Transactional
    public Book add(Book book) {
        em.persist(book);
        return book;
    }
}
```

Walk through it:

1. `@Path("/books")`: this class answers requests at `/books`.
2. `@ApplicationScoped`: CDI creates **one** instance and shares it (like a Spring singleton).
3. `@Produces` / `@Consumes`: responses and requests use JSON.
4. `@Inject EntityManager em`: CDI gives you the JPA object that talks to the database. You never write `new`.
5. `@GET` on `all()`: runs on `GET /books`. It runs a JPQL query and returns the list, which is converted to JSON automatically.
6. `@POST` on `add()`: runs on `POST /books`.
7. `@Transactional`: wraps the method in a transaction, so `persist` is committed if it succeeds and rolled back if it throws.

---

## 6. Jakarta EE and Spring: how they relate

They are not enemies. They overlap, and Spring actually uses Jakarta EE.

|Task|Jakarta EE|Spring|
|---|---|---|
|Inject a dependency|`@Inject`|`@Autowired`|
|Singleton bean|`@ApplicationScoped`|`@Component` / `@Service`|
|REST endpoint|`@Path` + `@GET`|`@RestController` + `@GetMapping`|
|Transaction|`@Transactional` (JTA)|`@Transactional` (Spring's own)|
|Database access|JPA (standard)|Spring Data JPA, built on JPA|
|Servlet engine|Servlet spec|Embedded Tomcat (Servlet spec)|

Spring is an **independent framework** that _uses_ several Jakarta EE specs (Servlet, JPA, Validation). Jakarta EE is the **standard**. Spring is one popular way to build apps with it, with its own extra APIs on top.

You already know a good part of Jakarta EE from Spring Boot: JPA entities, Bean Validation, and Servlets.

---

## 7. Related concept: MicroProfile

**MicroProfile** is a smaller, faster-moving set of specs, also run by the Eclipse Foundation. It adds things Jakarta EE did not originally cover for microservices: config, health checks, metrics, fault tolerance, and JWT auth. Runtimes such as Open Liberty and Payara support both. Quarkus and Helidon build on it.

---

## 8. When to choose Jakarta EE

**It fits well when:**

- You want standards and low vendor lock-in.
- You work in a company or on a system already built on Java EE.
- You like a stable platform that lasts for many years.

**Spring Boot often fits better when:**

- You want the biggest community and the most tutorials.
- You want fast setup and a huge ecosystem (Spring Security, Spring Data, Spring Cloud).

Many jobs use both, and the knowledge transfers well. If you learn the specs, you understand what Spring is sitting on.

---

## Summary

- Jakarta EE = standard specifications for enterprise Java, the successor to Java EE.
- Specs are the rules. Hibernate, Tomcat, and others are the implementations.
- Since Jakarta EE 9, packages use `jakarta.*` instead of `javax.*`.
- It comes in Core, Web, and Platform profiles.
- Spring Boot 3+ is built on the `jakarta.*` namespace.




[[Spring Framework]]