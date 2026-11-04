

## Part 1: What it is

`@EntityListeners` is an annotation you place on an entity class. It names one or more separate classes, called **listener classes**, whose callback methods JPA should run for that entity.

A callback method is a method marked with `@PrePersist`, `@PreUpdate`, `@PostLoad`, and so on. In the previous lesson, those methods lived inside the entity itself. With `@EntityListeners`, they live in a different class.

```java
@Entity
@EntityListeners(TimestampListener.class)  // "Use this other class for callbacks"
public class Task {
    // fields and getters/setters
}
```

The entity says _which_ listener to use. The listener class says _what_ to do.

## Part 2: Why it exists

Imagine you have three entities, `Task`, `Project`, and `Comment`, and all three need `createdAt` and `updatedAt` timestamps. With the approach from the previous lesson, you would write the same `@PrePersist` and `@PreUpdate` methods in each class:

```java
// Repeated in Task, Project, and Comment
@PrePersist
void onCreate() {
    this.createdAt = Instant.now();
    this.updatedAt = this.createdAt;
}
```

If you later decide timestamps should use a different time zone, you would have to edit three files. You might also miss one.

`@EntityListeners` solves this by letting you write the logic once and attach it to many entities.

## Part 3: The problem it solves

There are two problems in the example above:

1. **Duplication.** The same code appears in every entity that needs it.
2. **Clutter.** Entities are supposed to describe data and its rules. Bookkeeping code like timestamp logic makes them longer and harder to read.

A listener class fixes both. The entity stays focused on its data, and the shared behavior has one home.

## Part 4: How it works

When Hibernate is about to insert, update, load, or delete an entity, it checks the entity class for listener declarations. It does this in roughly this order:

1. **Default listeners**, if any are configured globally (rare in everyday projects).
2. **Listeners named in `@EntityListeners`**, in the order you list them.
3. **Callback methods on the entity itself**, if the entity has any.

For each listener, Hibernate creates one instance of the listener class. Then, at the right moment, it calls every method annotated with the matching callback annotation.

There is one important difference from entity callbacks. **Listener callback methods receive the entity as a parameter.** Entity callbacks take no parameters because they belong to the entity. A listener is a separate object, so it needs to be told which entity it is working on.

Here is the rule in one line:

> A listener method must return `void` and accept exactly one parameter, which is the entity being saved, updated, loaded, or deleted.

## Part 5: Building the first listener, step by step

### Step 1: Define a shared contract

The listener needs to set timestamps on any entity that has them, but it cannot know the class of every entity. The solution is an interface that describes the behavior the listener needs.

```java
import java.time.Instant;

public interface Timestamped {
    Instant getCreatedAt();
    void setCreatedAt(Instant createdAt);

    Instant getUpdatedAt();
    void setUpdatedAt(Instant updatedAt);
}
```

**What this does:** It declares four methods. Any class that implements `Timestamped` promises to provide them. The listener can then work with any such entity without knowing its exact type.

### Step 2: Write the listener

```java
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import java.time.Instant;

public class TimestampListener {

    @PrePersist
    public void onCreate(Object target) {
        if (target instanceof Timestamped entity) {
            Instant now = Instant.now();
            entity.setCreatedAt(now);
            entity.setUpdatedAt(now);
        }
    }

    @PreUpdate
    public void onUpdate(Object target) {
        if (target instanceof Timestamped entity) {
            entity.setUpdatedAt(Instant.now());
        }
    }
}
```

**What each part does:**

- `onCreate` runs before a new entity is inserted. It receives the entity as `target`, typed as `Object` because the listener accepts any entity.
- `target instanceof Timestamped entity` checks whether the entity implements the interface. If it does, Java gives you a variable called `entity` typed as `Timestamped`, so you can call its methods. This is called _pattern matching for `instanceof`_, and it requires Java 16 or newer. Spring Boot 3 requires Java 17, so you are covered.
- The `if` check is a safety net. If someone accidentally attaches this listener to an entity that does not implement the interface, nothing breaks.
- `onUpdate` runs before an existing entity is updated. It only refreshes `updatedAt`, which is the correct behavior for an update.

### Step 3: Attach the listener to entities

```java
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@EntityListeners(TimestampListener.class)
public class Task implements Timestamped {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    // getters and setters for all fields
    @Override public Instant getCreatedAt() { return createdAt; }
    @Override public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    @Override public Instant getUpdatedAt() { return updatedAt; }
    @Override public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
```

**What this does:**

- `implements Timestamped` promises that `Task` supports the four methods.
- `@EntityListeners(TimestampListener.class)` tells Hibernate to route this entity's callbacks through the listener.
- The getters and setters are required by the interface. They are where the listener's changes are actually stored.

Now a second entity can reuse the same behavior by adding two small pieces:

```java
@Entity
@EntityListeners(TimestampListener.class)
public class Project implements Timestamped {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    // getters and setters, same as Task
}
```

**What changed:** Only the annotation and the `implements` clause are new. The timestamp logic is not copied. Both `Task` and `Project` now behave identically, and any future fix to `TimestampListener` applies to both at once.

## Part 6: A second listener, with a different purpose

Listeners are not limited to timestamps. Here is one that logs every deletion, so you can see what was removed and when.

```java
import jakarta.persistence.PostRemove;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DeletionAuditListener {

    private static final Logger log = LoggerFactory.getLogger(DeletionAuditListener.class);

    @PostRemove
    public void afterDelete(Object target) {
        log.info("Deleted entity of type {}", target.getClass().getSimpleName());
    }
}
```

**What each part does:**

- `@PostRemove` runs after the row is deleted from the database.
- `target.getClass().getSimpleName()` returns the entity's class name, such as `"Task"`. This makes the log readable without hardcoding any particular entity.
- `Logger` comes from SLF4J, which Spring Boot includes by default. It is the standard way to log in Spring projects.

Attach it to any entity you want audited:

```java
@Entity
@EntityListeners({TimestampListener.class, DeletionAuditListener.class})
public class Task implements Timestamped {
    // ...
}
```

**What this does:** The curly braces let you list several listeners. Hibernate runs them in the order written. Here, the timestamp listener handles creation and update, and the audit listener handles deletion. Each listener focuses on one job.

## Part 7: Two gotchas you will meet

### Gotcha 1: Spring dependencies are not injected into listeners by default

Hibernate creates listener instances itself, not Spring. This means a listener like this will not work as you might expect:

```java
public class EmailListener {

    @Autowired  // Spring does not inject into this object by default
    private NotificationService notificationService;

    @PostPersist
    public void notify(Object target) {
        notificationService.send(...);  // NullPointerException at runtime
    }
}
```

The field stays `null` because Spring never sees this object. Simple listeners like the timestamp example do not need Spring, so they work fine. If you do need Spring beans inside a listener, the usual fix is to configure Hibernate to use Spring's bean container, which is an advanced topic we can cover later. For beginners, the safer rule is: **keep listeners self-contained, and put anything needing services in the service layer.**

### Gotcha 2: The listener must have a no-argument constructor

Hibernate creates the listener by calling its constructor with no arguments. If your listener has only a constructor that takes parameters, Hibernate cannot create it. Keeping the listener as a plain class with no explicit constructor avoids this problem.

## Part 8: Where you will use this in practice

You will reach for `@EntityListeners` when:

- Several entities need the same callback behavior, such as timestamps, audit logging, or normalization.
- You want the entity classes to stay focused on their data.
- The shared behavior is a cross-cutting concern, meaning something that applies across many classes rather than belonging to one.

You will not need it when only one entity needs a callback. In that case, putting the method directly on the entity is simpler and easier to read.




[[Spring Framework]]