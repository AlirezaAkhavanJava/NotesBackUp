 Designing an entity means deciding what a table looks like in Java: which fields exist, how they're typed, which are required, and how entities relate to one another. Flyway is a tool that turns those decisions into versioned SQL scripts that run automatically, so every copy of your database (your laptop, your teammate's machine, the production server) ends up with exactly the same structure. We'll cover why Flyway is needed, set it up in a Spring Boot project on Debian 13, design an entity, and write the migration that creates its table.

## Why do we need Flyway?

In the previous lesson we used `spring.jpa.hibernate.ddl-auto=update`, which lets Hibernate change your database to match your entities. That's convenient for experiments, but it causes real problems as a project grows:

- **Hibernate can't see your history.** It only knows the current shape of your classes, not what changed last week. It can't rename a column safely or move data from one column to another.
- **Changes aren't reviewable.** The SQL Hibernate runs is generated behind the scenes. Nobody reviews it before it hits production.
- **Environments drift apart.** Your laptop, your teammate's machine, and the server each may have slightly different tables depending on when each one was last updated.
- **Destructive changes can happen silently.** Changing a field's type or removing it may drop data without any warning.

Flyway solves this by treating the database like source code. You write numbered SQL files, such as `V1__create_customers.sql`, and Flyway runs each one exactly once, in order, and records what it ran in a table called `flyway_schema_history`. When the app starts, Flyway looks at that table, runs only the scripts that are new, and stops if something has been tampered with. The result is that any database, anywhere, reaches the same state by the same steps.

The key rule: **never edit a migration after it has run anywhere.** Flyway stores a checksum of each script, and changing one causes a validation error. To change the structure, you add a new migration file.

## Step 1: Add the dependencies

Add Flyway to your `pom.xml`, alongside the JPA starter and PostgreSQL driver from the last lesson:

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- Flyway core: runs the migration scripts at startup -->
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>

    <!-- Needed for Flyway with PostgreSQL 15+ and recent versions -->
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-database-postgresql</artifactId>
    </dependency>

    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
</dependencies>
```

`flyway-core` contains the migration engine. `flyway-database-postgresql` contains the PostgreSQL-specific support. Spring Boot manages the versions for both, so you don't specify them. Since Flyway 10, PostgreSQL support lives in this separate module, which is why it's listed explicitly.

## Step 2: Configure the database and Hibernate

In `application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/shopdb
spring.datasource.username=postgres
spring.datasource.password=yourpassword

# Flyway creates the schema. Hibernate only checks that it matches the entities.
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true
```

This is the most important change from the last lesson. We switched `ddl-auto` from `update` to `validate`. Hibernate still reads your entities, but it no longer modifies the database. At startup it compares your classes with the real tables, and if they don't match it refuses to start. This turns silent mismatches into loud early errors.

`spring.flyway.locations=classpath:db/migration` tells Flyway to look for scripts in `src/main/resources/db/migration`. Flyway runs them before Hibernate starts, which is why the order works.

To start PostgreSQL on Debian 13 and create the database:

```bash
sudo apt install postgresql
sudo systemctl enable --now postgresql
sudo -u postgres psql -c "CREATE DATABASE shopdb;"
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'yourpassword';"
```

The first command installs the server, the second makes sure it starts automatically, and the other two create the database and set the password your config expects.

## Step 3: Design the entity

Before writing any code, decide on the structure. For this lesson we'll design a simple shop with **customers** who place **orders**. Each customer can have many orders, and each order belongs to exactly one customer. That's a one-to-many relationship, which is the most common kind you'll meet.

Here's the design, written out before the code:

- `customers` table: `id` (primary key), `full_name` (required), `email` (required and unique), `created_at` (required, set when the row is created).
- `orders` table: `id` (primary key), `customer_id` (foreign key pointing to `customers.id`, required), `total_amount` (required, with exact decimal precision), `status` (required), `placed_at` (required).

Designing first matters because the answers to questions like "is this required?", "must it be unique?", and "what happens to orders if a customer is deleted?" determine both the Java code and the SQL. Writing them down on paper before coding prevents most rework.

Now the Java side. First, the `Customer` entity:

```java
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)   // Database assigns the ID (BIGSERIAL in PostgreSQL)
    private Long id;

    @Column(name = "full_name", nullable = false, length = 100)  // Required, max 100 characters
    private String fullName;

    @Column(nullable = false, unique = true, length = 255)       // Required and unique
    private String email;

    @Column(name = "created_at", nullable = false, updatable = false) // Set once, never changed
    private Instant createdAt;

    @OneToMany(mappedBy = "customer")                     // The "orders" side of the relationship
    private List<Order> orders = new ArrayList<>();

    protected Customer() {}                               // Required by JPA

    public Customer(String fullName, String email) {
        this.fullName = fullName;
        this.email = email;
        this.createdAt = Instant.now();
    }

    public Long getId() { return id; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public Instant getCreatedAt() { return createdAt; }
    public List<Order> getOrders() { return orders; }
}
```

Here is what each part does:

- `GenerationType.IDENTITY` lets PostgreSQL's `BIGSERIAL` column generate the ID. We use it here instead of a sequence to keep this lesson focused. You met sequences in the last lesson, and both approaches are valid.
- `@Column(nullable = false, length = 100)` controls both the Java validation and the SQL `NOT NULL` and `VARCHAR(100)` that Flyway must create. Keep these in sync with your migration.
- `unique = true` on `email` means the database itself rejects duplicates, which is more reliable than checking in Java alone.
- `Instant` is the modern Java type for a point in time, and it maps cleanly to `TIMESTAMP` in PostgreSQL.
- `updatable = false` on `createdAt` means JPA never includes it in an `UPDATE` statement, so the original timestamp is kept.
- `@OneToMany(mappedBy = "customer")` declares the inverse side of the relationship. `mappedBy` says the foreign key lives on the `Order` side, which is why the `orders` table will have the `customer_id` column and the `Customer` class has no column for it.
- The no-argument constructor is `protected` because JPA needs it, but application code should not use it.

Next, the `Order` entity, which owns the foreign key:

```java
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)  // Many orders belong to one customer
    @JoinColumn(name = "customer_id", nullable = false)  // The foreign key column
    private Customer customer;

    @Column(name = "total_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "placed_at", nullable = false)
    private Instant placedAt;

    protected Order() {}

    public Order(Customer customer, BigDecimal totalAmount, String status) {
        this.customer = customer;
        this.totalAmount = totalAmount;
        this.status = status;
        this.placedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Customer getCustomer() { return customer; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public String getStatus() { return status; }
    public Instant getPlacedAt() { return placedAt; }
}
```

- `@ManyToOne` is the owning side. This class holds the `customer_id` column.
- `fetch = FetchType.LAZY` means Hibernate doesn't load the customer until you ask for it. The default for `@ManyToOne` is `EAGER`, which often causes slow queries, so `LAZY` is the safer habit.
- `@JoinColumn(name = "customer_id")` gives the foreign key column its name.
- `BigDecimal` is used for money. `double` can't represent values like 0.10 exactly, which leads to rounding errors. `precision = 10, scale = 2` means up to 10 digits total, with 2 after the decimal point, which maps to `NUMERIC(10,2)`.

## Step 4: Write the Flyway migration

Create the folder and the first script:

```bash
mkdir -p src/main/resources/db/migration
```

Name the file `V1__create_customers_and_orders.sql`. The naming rule matters: `V` marks a versioned migration, `1` is the version, and `__` (two underscores) separates the version from the description.

```sql
-- V1__create_customers_and_orders.sql

CREATE TABLE customers (
    id          BIGSERIAL PRIMARY KEY,              -- Auto-incrementing 64-bit ID
    full_name   VARCHAR(100) NOT NULL,              -- Required, max 100 characters
    email       VARCHAR(255) NOT NULL UNIQUE,       -- Required, and no two customers share one
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL   -- Required timestamp
);

CREATE TABLE orders (
    id            BIGSERIAL PRIMARY KEY,
    customer_id   BIGINT NOT NULL
                  REFERENCES customers (id)         -- Foreign key: must point to a real customer
                  ON DELETE RESTRICT,               -- Refuse to delete a customer who still has orders
    total_amount  NUMERIC(10, 2) NOT NULL,          -- Exact decimal, matches BigDecimal
    status        VARCHAR(20) NOT NULL,
    placed_at     TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_orders_customer_id ON orders (customer_id);
```

Going through the parts:

- `BIGSERIAL` creates a `BIGINT` column backed by a sequence, which is how `GenerationType.IDENTITY` works in PostgreSQL.
- `NOT NULL` matches `nullable = false` in Java. The two must agree, or Java will allow a value the database then rejects.
- `UNIQUE` on `email` is the database-level guarantee we mentioned earlier.
- `REFERENCES customers (id)` creates the foreign key, so an order can't point to a customer that doesn't exist.
- `ON DELETE RESTRICT` means the database refuses to delete a customer who has orders. The alternatives are `CASCADE` (delete the orders too) or `SET NULL`. `RESTRICT` is the safest default for business data, because deleting orders by accident is hard to recover from.
- `NUMERIC(10, 2)` stores money exactly.
- `CREATE INDEX` speeds up looking up all orders for one customer. PostgreSQL doesn't index foreign keys automatically, so adding this by hand is a good habit.
- `TIMESTAMP WITH TIME ZONE` stores an unambiguous moment in time, which pairs well with `Instant`.

Start the application (`./mvnw spring-boot:run`). In the log you should see Flyway report that it is applying `V1`, and then Hibernate validates the entities against the tables. You can confirm the result directly in PostgreSQL:

```bash
sudo -u postgres psql -d shopdb -c "\dt"
sudo -u postgres psql -d shopdb -c "SELECT version, description, success FROM flyway_schema_history;"
```

The first command lists your tables, and the second shows Flyway's record of the migration.

## Step 5: Change the design safely with V2

Suppose you later decide each order should store a short note. You don't edit `V1`. You add a new file, `V2__add_order_note.sql`:

```sql
ALTER TABLE orders ADD COLUMN note VARCHAR(500);
```

Then add the matching field to `Order`:

```java
@Column(length = 500)                                  // Nullable, so no nullable = false
private String note;
```

On the next startup Flyway runs only `V2`, and everything else is left alone. Notice that `note` is nullable, which means existing orders can keep working without a value. Adding a `NOT NULL` column to a table that already has rows would fail, so you'd first add the column as nullable, fill it in, then tighten it in a later migration. That's a pattern worth remembering.

## Try it yourself

1. Add an `Address` entity linked to `Customer` with a many-to-one relationship, and write `V3__create_addresses.sql` for it. Before writing the SQL, decide whether the address should be required, and what `ON DELETE` rule fits.
2. Deliberately edit `V1` after it has run, restart, and read the validation error Flyway gives. Then undo the edit and make the same change as `V4`.
3. Run `\d orders` in `psql` and compare each column with your Java annotations. Every mismatch you find is a bug waiting to happen, so try to find one.

Once you're comfortable with migrations, a good next step is writing a Spring Data repository for `Customer` and `Order`, and testing it against a real PostgreSQL database.




[[Spring Framework]]