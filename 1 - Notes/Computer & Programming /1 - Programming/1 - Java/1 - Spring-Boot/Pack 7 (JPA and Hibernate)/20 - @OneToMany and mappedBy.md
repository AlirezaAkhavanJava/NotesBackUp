
# `@OneToMany` and `mappedBy`: when a child becomes a full entity

## The problem first

In the last lesson, comments on a message would have been a poor fit for `@ElementCollection`. Imagine a `Comment` in Family Inbox that a parent can edit, delete, or reply to. It needs its own ID so you can point to it from a URL like `/comments/42`. It needs an author and a timestamp. You might want to query "all comments by this parent across every message." An element collection cannot do any of this, because its rows have no identity of their own.

So the child has to be a full `@Entity`, with its own table, its own primary key, and its own repository. The question is how the parent and child are linked. That link is what `@OneToMany` and `@ManyToOne` describe, and `mappedBy` is the piece that most beginners get wrong.

## What the relationship means

A `@OneToMany` relationship says one `Message` has many `Comment`s. In a relational database, this is never stored as a list. It is always stored as a **foreign key on the child table**. Each comment row contains the ID of the message it belongs to. The parent has no column that lists its children.

That single fact explains everything else in this lesson. Since the foreign key lives on the child, the child is the side that controls the link. JPA needs to know which side owns the foreign key, and that is what `mappedBy` declares.

## The two sides

Every bidirectional relationship has two sides, and they describe the same foreign key from opposite directions.

The **owning side** is the side that holds the foreign key. In this case that is `Comment`, using `@ManyToOne` and `@JoinColumn`. Only this side's mapping is used when Hibernate writes the database.

The **inverse side** is the side that only reads the relationship. In this case that is `Message`, using `@OneToMany(mappedBy = "...")`. The value of `mappedBy` is the name of the field on the owning side. It tells Hibernate: "do not create a second foreign key here; go and look at the `message` field on `Comment`."

If you leave out `mappedBy`, Hibernate assumes the parent owns the relationship and creates a **join table** called something like `message_comments`, with two foreign key columns. This is valid, but it is usually unwanted, and it is the most common source of surprise extra tables.

## The code

Start with the child, because it is the owner.

```java
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "comments")
public class Comment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 1000)
    private String body;

    @Column(nullable = false)
    private String authorEmail;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "message_id", nullable = false)
    private Message message;

    protected Comment() {}

    public Comment(String body, String authorEmail) {
        this.body = body;
        this.authorEmail = authorEmail;
    }

    public Long getId() { return id; }
    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }
    public String getAuthorEmail() { return authorEmail; }
    public Instant getCreatedAt() { return createdAt; }
    public Message getMessage() { return message; }

    // package-private: only Message should set this
    void setMessage(Message message) { this.message = message; }
}
```

What each part does:

`@Entity` and `@Id` make `Comment` a table with its own primary key, as you learned for `Message`.

`@ManyToOne` says many comments can point to one message. This is the owning side, so it is the one that controls the foreign key.

`fetch = FetchType.LAZY` stops Hibernate from loading the parent message every time it loads a comment. The default for `@ManyToOne` is `EAGER`, which quietly causes extra queries across the whole application. Set `LAZY` on every association unless you have a specific reason not to.

`@JoinColumn(name = "message_id", nullable = false)` names the foreign key column `message_id` and makes it required. A comment without a message makes no sense in this app, so the database should refuse it.

`setMessage` is package-private. Only the parent should change this field, through a helper method you will see shortly. This prevents code elsewhere from setting one side of the link and forgetting the other.

Now the parent.

```java
import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String subject;

    @OneToMany(mappedBy = "message", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Comment> comments = new ArrayList<>();

    protected Message() {}

    public Message(String subject) {
        this.subject = subject;
    }

    public Long getId() { return id; }
    public String getSubject() { return subject; }

    // Expose a read-only view so callers cannot bypass the helper methods
    public List<Comment> getComments() {
        return List.copyOf(comments);
    }

    public void addComment(Comment comment) {
        comments.add(comment);
        comment.setMessage(this);
    }

    public void removeComment(Comment comment) {
        comments.remove(comment);
        comment.setMessage(null);
    }
}
```

What each part does:

`@OneToMany(mappedBy = "message")` says this side is the inverse. The string must match the field name on `Comment` exactly, which is `message`. A typo here fails at startup with an error that names the missing property, so it is easy to fix.

`cascade = CascadeType.ALL` means operations on the parent are passed to the children. Saving a message saves its new comments. Deleting a message deletes its comments.

`orphanRemoval = true` means if you remove a comment from the list, Hibernate deletes its row. Without this, removing the comment from the list would only set its `message_id` to null, which `nullable = false` would then reject.

`addComment` and `removeComment` are the important part. Because the relationship is bidirectional, both sides in memory must agree. If you only add to the list, the comment is not saved, because Hibernate only writes the owning side, and the owning side's `message` field is still null. The helper method updates both sides in one place, so you cannot forget one.

`getComments` returns `List.copyOf`, an unmodifiable copy. If it returned the real list, `message.getComments().add(c)` would change the in-memory list without setting `c.message`, and you would be back to the silent-failure bug.

## What the database looks like

```
messages                      comments
-----------                   ----------------------------
id (PK)            <-------   message_id (FK, NOT NULL)
subject                       id (PK)
                              body
                              author_email
                              created_at
```

There is no column on `messages` for comments. All the link information lives on `comments`. This is the same foreign key you saw in the element collection lesson, but here the child has a primary key of its own.

## Using it in a service

```java
@Service
public class CommentService {

    private final MessageRepository messageRepository;

    public CommentService(MessageRepository messageRepository) {
        this.messageRepository = messageRepository;
    }

    @Transactional
    public void addComment(Long messageId, String body, String authorEmail) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("No message " + messageId));

        message.addComment(new Comment(body, authorEmail));
        // No save call needed: the message is managed in this transaction,
        // and cascade = ALL inserts the new comment when the transaction commits.
    }

    @Transactional
    public void deleteComment(Long messageId, Long commentId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow();

        Comment comment = message.getComments().stream()
                .filter(c -> c.getId().equals(commentId))
                .findFirst()
                .orElseThrow();

        message.removeComment(comment);
        // orphanRemoval = true deletes the row on commit
    }
}
```

What this does: `addComment` loads the parent, attaches a new child through the helper, and lets the transaction do the rest. There is no `commentRepository.save(...)`, and you do not need one. Hibernate sees the cascade and the new child and inserts it.

One point to notice: `deleteComment` starts with `message.getComments()`, which returns the copy. Removing from that copy would do nothing. The code above only works because it calls `message.removeComment(comment)`, which changes the real list. This is a good example of why the helper methods exist.

You can also create a `CommentRepository` and query comments directly. That is exactly what the entity-based design makes possible:

```java
public interface CommentRepository extends JpaRepository<Comment, Long> {

    List<Comment> findByAuthorEmailOrderByCreatedAtDesc(String authorEmail);
}
```

Spring Data derives the query from the method name. This query would be impossible with an element collection, because there is no table of comments to search across.

## Fetching: the N+1 problem again

`@OneToMany` is lazy by default, so loading messages does not load their comments. If you then loop over messages and read each one's comments, you get one query per message, the same N+1 problem from the last lesson. The fix is the same: fetch the children with the parent in one query.

```java
@Query("SELECT DISTINCT m FROM Message m LEFT JOIN FETCH m.comments WHERE m.id = :id")
Optional<Message> findWithComments(@Param("id") Long id);
```

Use this when you need one message and all its comments together. Do not fetch comments for a list of messages in a page of search results unless you have a reason. Loading many collections at once makes large result sets expensive, and the page is usually better served by a separate query for just the comment count or the latest few comments.

## Common mistakes

Forgetting `mappedBy` creates an unwanted join table, as described above. Check it first when you see a table you did not expect.

Setting only one side of the link, for example calling `comments.add(c)` directly instead of `addComment(c)`, leaves `c.message` null. Hibernate then fails with a "not-null property references a null" error on insert, or silently skips the row if the column is nullable.

Using `@ManyToOne` with the default `EAGER` fetch makes every comment load its message, and the message can load other associations, so one query expands into several. Always write `fetch = FetchType.LAZY`.

Serialising the entity directly to JSON can cause infinite recursion, because `Message` contains `Comment`, and `Comment` contains `Message`. Map to DTOs in your controller layer, which is the approach you will want anyway for the Family Inbox API.





[[Spring Framework]]]