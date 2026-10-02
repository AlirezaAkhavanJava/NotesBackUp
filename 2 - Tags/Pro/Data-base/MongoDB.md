**MongoDB** is a **document database** (a type of NoSQL database). Instead of tables with rows and columns, it stores flexible **JSON-like documents** inside **collections**. It runs as a separate server, like PostgreSQL and MySQL, and listens on **port 27017**.

**Analogy:** A relational database is a **filing cabinet of printed forms**: every form has the same fields, and you must follow the template. MongoDB is a **cabinet of folders**: each folder holds a self-contained bundle of information, and two folders in the same drawer can contain different things.

## Core idea: documents

A whole object lives in one document, including its nested parts. In SQL you would split a book and its reviews into two tables and `JOIN` them. In MongoDB you store them together:

```json
{
  "_id": "665f1c...",
  "title": "Clean Code",
  "year": 2008,
  "author": { "name": "Robert C. Martin" },
  "tags": ["java", "best-practices"],
  "reviews": [
    { "user": "sam", "stars": 5 },
    { "user": "lea", "stars": 4 }
  ]
}
```

(This is stored internally as **BSON**, a binary form of JSON with extra types like dates.)

**Terminology map:**

|SQL|MongoDB|
|---|---|
|Database|Database|
|Table|Collection|
|Row|Document|
|Column|Field|
|`JOIN`|Embedding (or `$lookup`)|
|Primary key|`_id` (added automatically)|

## Why it exists: the key trade-off

- **Flexible schema:** documents in one collection can have different fields, so changing your data shape needs no migration.
- **Reads are fast for whole objects:** one query returns the book _with_ its reviews, no joins.
- **Horizontal scaling (sharding):** data can be split across many servers, built in from the start.

The cost: you give up much of the relational model's safety net (enforced relationships, easy cross-collection joins), and **data duplication** becomes your responsibility.

## Embedding vs referencing (the central design decision)

- **Embed** when the child data is always read together with the parent and is bounded in size (a book's tags, an order's line items).
- **Reference** (store another document's `_id`) when the child is large, grows without limit, or is shared (a user's thousands of comments).

In SQL you design around the _data_ (normalize it). In MongoDB you design around your _queries_ (how the app reads it).

## Where it fits in a real back-end

```
Angular --HTTP/JSON--> Spring Boot --driver over TCP:27017--> MongoDB
```

Note how naturally it fits: JSON from the front-end, JSON-like documents in the database.

**Good fits:**

- Content and catalogs where items have varying attributes (products with different specs).
- Event logs, activity feeds, IoT and sensor data.
- Fast-changing prototypes where the schema isn't settled.
- Data that is naturally hierarchical.

**Poor fits:**

- Money and accounting, where multi-record transactions and strict relationships are central.
- Highly relational data with many-to-many links and complex reporting.

Many real systems use **both**: PostgreSQL for core transactional data, MongoDB (or Redis) for the parts that suit it. This is called **polyglot persistence**.

## Hands-on on Debian 13

MongoDB is not in Debian's default repositories (its license is not considered free by Debian), so you add MongoDB's official repository or use Docker. Docker is easiest:

```bash
docker run -d --name mongo -p 27017:27017 mongo
docker exec -it mongo mongosh
```

In `mongosh`:

```javascript
use library
db.books.insertOne({ title: "Clean Code", year: 2008, tags: ["java"] })
db.books.find({ year: { $gt: 2000 } })
db.books.updateOne({ title: "Clean Code" }, { $set: { year: 2009 } })
db.books.deleteOne({ title: "Clean Code" })
```

Notice this is JavaScript-style syntax, connecting to your JS lesson.

## Using it from Spring Boot

`pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```

`application.properties`:

```properties
spring.data.mongodb.uri=mongodb://localhost:27017/library
```

Document class and repository (the pattern mirrors JPA, but with Mongo annotations):

```java
@Document(collection = "books")
public class Book {
    @Id
    private String id;          // usually a String/ObjectId, not a Long
    private String title;
    private int year;
    private List<String> tags;
    private List<Review> reviews;
    // getters and setters
}

public record Review(String user, int stars) {}

public interface BookRepository extends MongoRepository<Book, String> {
    List<Book> findByYearGreaterThan(int year);
}
```

Compare with the PostgreSQL version: `@Entity` became `@Document`, `JpaRepository` became `MongoRepository`, and the nested `Review` list lives _inside_ the book, with no second table or `@OneToMany`. Spring Data's repository idea stays the same, so your controller and service layers don't change.

## Gotchas

- **"Schemaless" does not mean "no schema."** Your _code_ still assumes a shape. Without discipline, collections fill with inconsistent documents. Use MongoDB's **schema validation** and validate in Spring.
- **Transactions exist but are costly.** Since version 4.0, MongoDB supports multi-document ACID transactions (on replica sets), but the design intent is that one document is the unit of atomicity. Needing many transactions is a sign you may want a relational database.
- **The 16 MB document limit:** an ever-growing embedded array (like all comments on a viral post) will eventually break it. That is when to reference instead.
- **Indexes still matter.** Without them, a query scans the whole collection. Create indexes for your common queries and check with `explain()`.
- **Duplication drifts.** If you copy an author's name into every book and the name changes, you must update every copy.
- **Security:** older default installs had no authentication, and exposed instances have been mass-compromised. Always enable auth and never expose port 27017 to the internet.
- **"NoSQL" is not "better" or "faster."** It is a different set of trade-offs. For most standard business back-ends, PostgreSQL is still the safer default; choose MongoDB when your data genuinely fits documents.


[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]