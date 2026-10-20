
`@CollectionTable` is optional. Without it, Hibernate picks a table name and join column for you. You add it when you want those names to be exact, usually to match an existing schema or your team's naming rules. So the real question is what problem the join column solves, and that's where we'll start.

## The Problem: Rows Need to Know Their Owner

A `person_address` table holds many addresses. Each row needs to say which person it belongs to. Otherwise, if two people each have an address on Main Street, the database has no way to tell whose is whose.

The mechanism is a **foreign key**: a column in the child table that stores the primary key of the parent row. The child table holds a value that points to a row in the parent table.

```
person                         person_address
-----------------              ----------------------------------
id | name                      person_id | street       | city
---+--------                   ----------+--------------+---------
 1 | Alireza                       1     | 12 Main St   | Tehran
 2 | Sara                          1     | 5 Park Ave   | Shiraz
                                   2     | 9 Oak Rd     | Isfahan
```

Here `person_id` in `person_address` is the join column. Its value `1` means "this address belongs to the person whose id is 1." `@JoinColumn` is the annotation that tells Hibernate to create this column, name it, and fill it correctly.

## What `@JoinColumn` Does

`@JoinColumn` describes one foreign key. It answers three questions:

1. **What is the column in the child table called?** (`name`)
2. **Which column in the parent does it point to?** (by default, the primary key)
3. **What rules apply to it?** (nullable, unique, constraint name, and so on)

It does not add a field to your Java class. `Address` has no reference back to `Person`, and `Person` has no extra field for the column. The join column exists only in the database. Hibernate fills it in when it saves the list and reads it back when it loads the list.

## Putting It Together

Here is the mapping with both annotations:

```java
@Entity
public class Person {

    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @ElementCollection
    @CollectionTable(
        name = "person_address",                          // table name
        joinColumns = @JoinColumn(name = "person_id")     // FK column in that table
    )
    private List<Address> addresses = new ArrayList<>();
}
```

Here is what each part does:

- `@CollectionTable` controls the child table. `name` sets its name.
- `joinColumns` is a list of join columns, which is an array because a parent's primary key can be composite and needs several columns. With a simple `Long id`, you use one.
- `@JoinColumn(name = "person_id")` creates a column called `person_id` in `person_address`.

Without `@CollectionTable`, Hibernate would generate roughly `person_addresses` with a `person_id` column. The only difference is the names you chose.

When you save a `Person` with two addresses, Hibernate runs:

```sql
INSERT INTO person (id, name) VALUES (1, 'Alireza');
INSERT INTO person_address (person_id, street, city, zip_code)
    VALUES (1, '12 Main St', 'Tehran', '12345');
INSERT INTO person_address (person_id, street, city, zip_code)
    VALUES (1, '5 Park Ave', 'Shiraz', '67890');
```

Notice that `person_id` is filled with `1` in both rows. Hibernate took the owner's id and wrote it into every child row.

## Pointing at a Column Other Than the Primary Key

By default the foreign key points to the parent's primary key. Sometimes you need it to point to another unique column, often a business key like a customer code. `referencedColumnName` handles that.

```java
@Entity
public class Customer {

    @Id
    @GeneratedValue
    private Long id;

    @Column(unique = true, nullable = false)
    private String code;              // business key, e.g. "CUST-0042"

    @ElementCollection
    @CollectionTable(
        name = "customer_note",
        joinColumns = @JoinColumn(
            name = "customer_code",
            referencedColumnName = "code"   // point at 'code', not 'id'
        )
    )
    @Column(name = "note_text")
    private List<String> notes = new ArrayList<>();
}
```

The generated table is:

```sql
CREATE TABLE customer_note (
    customer_code VARCHAR(255) NOT NULL,
    note_text     VARCHAR(255),
    CONSTRAINT fk_note_customer FOREIGN KEY (customer_code)
        REFERENCES customer (code)
);
```

The database now enforces that every note belongs to an existing customer code. The `referencedColumnName` must point to a column that is unique, otherwise the database will reject the constraint.

## Other Attributes Worth Knowing

These are the ones you'll see most often:

- `nullable = false` makes the join column required. Use it when a child must always have an owner. Element collections already behave this way in practice, but it makes the intent explicit.
- `unique = true` prevents two child rows from pointing to the same owner, which is rarely what you want for collections, so you'll seldom use it here.
- `insertable = false, updatable = false` tells Hibernate not to write this column itself. You use this only when another mapping in the same table already manages it, which is an advanced case you can skip for now.
- `foreignKey = @ForeignKey(name = "fk_address_person")` gives the constraint a name you choose. This matters when you read error messages or write migrations.




[[Spring Framework]]