 `@ElementCollection` tells JPA/Hibernate to store a collection of simple values or embeddable objects in a separate table, and that table is linked back to the owning entity's table by a foreign key. You don't write the table yourself. Hibernate creates it from the mapping when the schema is generated.

## What `@ElementCollection` Is

It maps a collection field (a `List`, `Set`, `Map`, or `Collection`) whose elements are not entities. The elements are either:

1. **Basic values**, such as `String`, `Integer`, `LocalDate`, or enums.
2. **Embeddable objects**, which are classes annotated with `@Embeddable` that have no table or identity of their own.

The elements have no `@Id` and no repository of their own. They exist only as rows that belong to one parent.

## Why It Exists

Relational databases store data in flat tables with single-valued columns. A row can't hold a list. So when an object has a list, something has to split that list into rows. Without `@ElementCollection`, you would have to create a table yourself, define a foreign key, write the insert and delete logic, and map it manually. JPA does this for you.

It solves a specific problem: you have a value that belongs to one parent and has no meaning on its own. A person's nicknames, an article's tags, or a customer's phone numbers are examples. None of these need their own lifecycle. If the person is deleted, the nicknames should be deleted with them.

## How It Works Under the Hood

Consider this entity:

```java
@Entity
public class Person {

    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @ElementCollection
    private Set<String> nicknames = new HashSet<>();

    // getters and setters
}
```

Hibernate sees two things:

- `person` is an ordinary table, because `Person` is an `@Entity`.
- `nicknames` is a collection of basic values, so Hibernate creates a second table for it.

With Spring Boot's default naming strategy, the generated schema looks roughly like this:

```sql
CREATE TABLE person (
    id   BIGINT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE person_nicknames (
    person_id BIGINT NOT NULL REFERENCES person(id),
    nicknames VARCHAR(255),
    PRIMARY KEY (person_id, nicknames)
);
```

Each part of this does a specific job:

- `person_nicknames` is the table name. It is built from the owner entity name and the field name, converted to snake_case.
- `person_id` is the foreign key back to the owner. Hibernate adds it automatically.
- `nicknames` holds the actual values. Each nickname is one row.
- The primary key is the combination of owner and value. Because this is a `Set`, the same nickname can't appear twice for the same person.

When you run this code:

```java
Person p = new Person();
p.setName("Alireza");
p.getNicknames().add("Ali");
p.getNicknames().add("Reza");
personRepository.save(p);
```

Hibernate runs one insert into `person` and then one insert per nickname into `person_nicknames`. You can see these statements by setting `spring.jpa.show-sql=true` in `application.properties`.

## Customizing the Table

The defaults work, but you will usually want to control the table and column names. Use `@CollectionTable` for the table and join column, and `@Column` for the value column.

```java
@ElementCollection
@CollectionTable(
    name = "person_phone",
    joinColumns = @JoinColumn(name = "owner_id")
)
@Column(name = "phone_number", nullable = false, length = 20)
private List<String> phones = new ArrayList<>();
```

This creates a `person_phone` table with an `owner_id` foreign key and a `phone_number` column that cannot be null. The `List` type also needs an extra decision, covered next.

## Keeping Order with a List

A plain `List` with `@ElementCollection` has no stored order. Hibernate treats it as a "bag," and it handles updates inefficiently because it may delete and re-insert every row when anything changes. To store the order, add `@OrderColumn`:

```java
@ElementCollection
@CollectionTable(name = "person_phone", joinColumns = @JoinColumn(name = "owner_id"))
@Column(name = "phone_number", nullable = false, length = 20)
@OrderColumn(name = "position")
private List<String> phones = new ArrayList<>();
```

Now the table has a `position` column (0, 1, 2, ...), and Hibernate keeps the list in order. Use a `Set` when order doesn't matter, and a `List` with `@OrderColumn` when it does.

## Using an Embeddable

This is where `@ElementCollection` becomes most useful. Suppose a person can have several addresses. Each address has several fields, but no identity of its own.

```java
@Embeddable
public class Address {

    private String street;
    private String city;
    private String zipCode;

    // getters and setters
}
```

```java
@Entity
public class Person {

    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @ElementCollection
    @CollectionTable(
        name = "person_address",
        joinColumns = @JoinColumn(name = "person_id")
    )
    private List<Address> addresses = new ArrayList<>();

    // getters and setters
}
```

This produces a `person_address` table with columns `person_id`, `street`, `city`, and `zip_code`. Each row is one address. You never write SQL for it, and you never write a repository for `Address`. You just add to the list and save the `Person`.

## Using It in Practice

```java
Person p = new Person();
p.setName("Alireza");

Address home = new Address();
home.setStreet("12 Main St");
home.setCity("Tehran");
home.setZipCode("12345");

p.getAddresses().add(home);
personRepository.save(p);
```

This code inserts one row into `person` and one row into `person_address`. Loading the person later loads the addresses with it, depending on the fetch type. Deleting the person deletes its addresses too, because they cannot exist without their owner.

## When to Use It and When Not To

Use `@ElementCollection` when the elements are simple values or embeddables that belong to one parent and have no independent life.

Use `@OneToMany` instead when the elements are entities with their own identity. For example, an `Order` with `OrderLine` objects that need their own IDs, can be queried on their own, or are referenced from other tables should be mapped with `@OneToMany` and its own `@Entity`. The rule of thumb is: if you would ever want to query, reference, or manage the element directly through its own repository, it should be an entity.

## A Note on Production

Hibernate creates these tables automatically only when `spring.jpa.hibernate.ddl-auto` is set to `create`, `create-drop`, or `update`. Those settings are fine while you're learning, but in a real project you should set it to `validate` and manage the schema with a migration tool such as Flyway or Liquibase. The migration would contain the `CREATE TABLE person_address` statement explicitly, so every environment gets the same schema and changes are tracked in version control.




[[Spring Framework]]