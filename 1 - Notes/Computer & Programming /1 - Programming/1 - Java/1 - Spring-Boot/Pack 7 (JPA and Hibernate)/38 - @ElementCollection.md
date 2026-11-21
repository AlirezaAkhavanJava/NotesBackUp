
# `@ElementCollection` in Spring Boot (JPA)

## 1. What it is

`@ElementCollection` is a JPA annotation that maps a collection of simple values or embeddable objects onto a separate database table that belongs to an entity. Each element in the collection is a row in that table, linked back to its owner by a foreign key.

The key idea is that the elements are **not entities**. They have no `@Id`, no repository, and no lifecycle of their own. They exist only as part of their parent. If the parent is deleted, its elements are deleted with it, and if the parent is saved, its collection is saved with it.

## 2. Why it exists

A relational database stores data in tables, and each table row needs a way to be identified. JPA gives you two obvious ways to store a collection of related things:

- **Make each item a full `@Entity`** with its own `@Id`, its own repository, and a `@OneToMany` relationship. This is correct when the items are important in their own right, such as `Order` and `OrderLine`, or when you need to query them independently.
- **Use `@ElementCollection`** when the items are just values attached to a parent, such as tags, phone numbers, or email addresses. Creating a full entity for each one is overkill: more classes, more repositories, and more code to keep consistent.

`@ElementCollection` is the lighter option for the second case.

## 3. The problem it solves

In your Family Inbox app, a `Message` sent by a school might have several tags, such as `"urgent"`, `"field-trip"`, or `"permission-slip"`. A tag has no meaning outside the message it belongs to, and nobody needs to look up "all tags" as a standalone thing. Modeling each tag as its own entity would add a class, a table with an ID, and a repository for no real benefit. `@ElementCollection` stores the tags in a child table and keeps them tied to their message.

## 4. How it works under the hood

When Hibernate starts, it sees `@ElementCollection` on a field and does the following:

1. It creates a **collection table** (by default named `<EntityName>_<fieldName>`, so `Message_tags`). You can rename it with `@CollectionTable`.
2. The table has a **foreign key column** pointing to the owner's primary key. You can rename this with `joinColumns` inside `@CollectionTable`.
3. The table has one or more **value columns** that store the element data. For a basic type, that is one column. For an `@Embeddable`, there is one column per field.
4. When you save the owner, Hibernate compares the in-memory collection against the rows in the database and inserts, updates, or deletes the child rows to match. You never write SQL for this.
5. The collection is **lazily loaded** by default. Its rows are fetched only when you first access the collection, inside an open transaction or session.

Because the child rows are never managed on their own, the owner is the only way to reach them. That is the defining property of this mapping.

## 5. Example 1: A set of simple values

This is the most common use. We map a `Set<String>` of tags onto a `Message`.

```java
import jakarta.persistence.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String subject;

    @ElementCollection
    @CollectionTable(
            name = "message_tags",
            joinColumns = @JoinColumn(name = "message_id")
    )
    @Column(name = "tag", nullable = false, length = 50)
    private Set<String> tags = new HashSet<>();

    protected Message() {
        // JPA requires a no-args constructor
    }

    public Message(String subject) {
        this.subject = subject;
    }

    public Long getId() { return id; }
    public String getSubject() { return subject; }
    public Set<String> getTags() { return tags; }
}
```

What each part does:

- `@ElementCollection` tells JPA that `tags` is a collection of values, not a relationship to another entity.
- `@CollectionTable` names the child table `message_tags` and says the foreign key column in it is called `message_id`. Without it, Hibernate would choose the names itself.
- `@Column(name = "tag", ...)` names the value column and applies constraints to it. Here it is `NOT NULL` and has a maximum length.
- `= new HashSet<>()` initialises the collection. This prevents `NullPointerException` when you call `tags.add(...)` on a new message.
- `Set` is used instead of `List` here because a message should not have the same tag twice, and a set enforces that. Section 8 explains why `List` needs extra care.

The table Hibernate creates looks like this:

```
messages              message_tags
-----------           ---------------------
id (PK)        <----- message_id (FK)
subject               tag
```

Using it in a service:

```java
@Service
public class MessageService {

    private final MessageRepository messageRepository;

    public MessageService(MessageRepository messageRepository) {
        this.messageRepository = messageRepository;
    }

    @Transactional
    public Message createUrgentMessage(String subject) {
        Message message = new Message(subject);
        message.getTags().add("urgent");
        message.getTags().add("field-trip");

        // Saving the parent also inserts the two rows into message_tags
        return messageRepository.save(message);
    }
}
```

What this does: the `save` call inserts one row into `messages` and two rows into `message_tags`. You never call a repository for tags. The parent controls them.

## 6. Example 2: An `@Embeddable` element with several fields

Often a single value needs more than one field. For example, each recipient of a message has an email, a delivery status, and a role. We create an `@Embeddable` class for that.

```java
import jakarta.persistence.*;
import java.util.Objects;

@Embeddable
public class Recipient {

    @Column(nullable = false)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DeliveryStatus status;

    protected Recipient() {}

    public Recipient(String email, DeliveryStatus status) {
        this.email = email;
        this.status = status;
    }

    public String getEmail() { return email; }
    public DeliveryStatus getStatus() { return status; }

    public void setStatus(DeliveryStatus status) { this.status = status; }

    // equals and hashCode are required when the collection is a Set
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Recipient that)) return false;
        return Objects.equals(email, that.email);
    }

    @Override
    public int hashCode() {
        return Objects.hash(email);
    }
}

public enum DeliveryStatus {
    PENDING, DELIVERED, READ
}
```

Now the parent uses it:

```java
@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String subject;

    @ElementCollection
    @CollectionTable(
            name = "message_recipients",
            joinColumns = @JoinColumn(name = "message_id")
    )
    private Set<Recipient> recipients = new HashSet<>();

    // constructors and getters omitted for brevity
}
```

What this does:

- Each `Recipient` becomes one row in `message_recipients`, with columns `message_id`, `email`, and `status`. Because `Recipient` is embedded, its fields become columns of the child table. No separate table is created for `Recipient`.
- `equals` and `hashCode` use only `email`. A `Set` uses them to decide whether two recipients are the same, so one email cannot appear twice.
- `@Enumerated(EnumType.STRING)` stores `"DELIVERED"` as text instead of `1`. This is safer because adding an enum value later does not shift the meaning of existing rows.

Updating the status of one recipient:

```java
@Transactional
public void markRead(Long messageId, String email) {
    Message message = messageRepository.findById(messageId)
            .orElseThrow();

    message.getRecipients().stream()
            .filter(r -> r.getEmail().equals(email))
            .findFirst()
            .ifPresent(r -> r.setStatus(DeliveryStatus.READ));

    // No save() call needed: the entity is managed inside the transaction,
    // so Hibernate detects the change and issues an UPDATE on message_recipients.
}
```

What this does: it loads the message, finds the matching recipient, and changes one field. Because the method is `@Transactional`, Hibernate tracks the change and writes it back when the transaction commits. This is called **dirty checking**.

## 7. Example 3: A `Map` with a key

Sometimes each value needs a name. For example, a message might have metadata such as `"sentFrom" -> "school-office"` or `"floor" -> "3"`.

```java
@ElementCollection
@CollectionTable(
        name = "message_metadata",
        joinColumns = @JoinColumn(name = "message_id")
)
@MapKeyColumn(name = "meta_key", length = 50)
@Column(name = "meta_value", length = 255)
private Map<String, String> metadata = new HashMap<>();
```

What each annotation does:

- `@MapKeyColumn` names the column that stores each map key.
- `@Column` names the column that stores each map value.

Resulting rows: `(message_id=1, meta_key="sentFrom", meta_value="school-office")`.

## 8. Ordering and the `List` trap

If you use a `List` instead of a `Set`, the order of elements matters to you, but a plain `@ElementCollection` does not store an order. Hibernate treats it as a **bag**, which has no defined order and allows duplicates.

To keep the order, add `@OrderColumn`:

```java
@ElementCollection
@CollectionTable(name = "message_attachments",
                 joinColumns = @JoinColumn(name = "message_id"))
@OrderColumn(name = "position")
@Column(name = "file_name")
private List<String> attachments = new ArrayList<>();
```

This adds a `position` column to the child table, which Hibernate fills and reads so the list keeps its order.

A related trap: if an entity has **two** `List` element collections fetched together, Hibernate throws `MultipleBagFetchException`. The fix is to use `Set`, add `@OrderColumn`, or fetch them in separate queries.

## 9. Fetching and the N+1 problem

Element collections are lazy by default. This causes a common performance problem.

Suppose you load 100 messages and then read each message's tags. Hibernate runs one query for the messages, then one query per message for its tags. That is 101 queries, which is called the **N+1 problem**.

Fix it with a join fetch in the repository:

```java
public interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("SELECT DISTINCT m FROM Message m LEFT JOIN FETCH m.tags")
    List<Message> findAllWithTags();
}
```

What this does: it loads the messages and their tags in one SQL query with a join. `DISTINCT` is needed because a message with three tags would otherwise appear three times in the result.

Alternatively, you can use `@EntityGraph` if you want the fetch rule attached to the repository method without writing the JPQL yourself:

```java
@EntityGraph(attributePaths = "tags")
List<Message> findAll();
```

A related error you will meet early: `LazyInitializationException`. It happens when you touch a lazy collection after the transaction or session has closed, for example in a controller that returns the entity after the service method ends. Keep the fetch inside the transaction, or map the entity to a DTO inside the service method.

## 10. When to use it, and when not to

Use `@ElementCollection` when all of these are true:

- The elements are simple values or small embeddable objects.
- The elements belong entirely to one parent and are never shared with another.
- You will not need to query the elements directly, such as "find every message tagged `urgent` across all families." Queries are possible, but they are awkward.
- The collection is small. Loading and rewriting a large collection on every save is expensive.

Use a full `@OneToMany` entity instead when:

- The child needs its own ID and its own lifecycle, for example a `Comment` that someone can edit or delete directly.
- You need to query or report on the children on their own.
- The collection is large, or children are added and removed often. An entity-level `@OneToMany` lets you insert one child without reloading the whole collection.

For a many-to-many relationship between two existing entities, such as a `Family` and many `Message`s, use `@ManyToMany`, not `@ElementCollection`.





[[Spring Framework]]