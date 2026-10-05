
# `@Id` and `@GeneratedValue` in Spring Boot + JPA

## 1. The scenario

 You're on Debian, running PostgreSQL locally, building a Spring Boot 3 app. You've written your first entity, `User.java`, and a `UserService.java` that saves users.

You write this:

```java
@Entity
@Table(name = "users")
public class User {

    private Long id;
    private String email;

    // getters/setters
}
```

You start the app. Hibernate throws:

```
org.hibernate.AnnotationException: No identifier specified for entity: com.example.demo.User
```

You haven't done anything exotic, and the app refuses to boot. You add `@Id`, restart, and it boots. You call `userRepository.save(new User("a@x.com"))` and get:

```
ids for this class must be manually assigned before calling save()
```

So you add `@GeneratedValue`, and now it works. But a week later your bulk import of 10,000 users takes 40 seconds, and after a restart your IDs jump from 7 to 51. That isn't a bug, and by the end you'll know why.

## 2. The core mental model

> **`@Id` tells JPA which column is the entity's identity (its primary key). `@GeneratedValue` tells JPA who is responsible for producing that value: you, or the database/Hibernate.**

Hibernate keeps a map in memory called the **persistence context**, with entries like `(User, 42) -> the User object`. Without an identity, it can't tell whether two objects are the same row, whether to INSERT or UPDATE, or how to find the row later.

## 3. Step-by-step walkthrough

### Step 1: `@Id` alone means you assign the key

```java
@Id
private Long id;
```

```
You                     Hibernate                 DB
 |  new User(id=5)        |                         |
 |----- save() ---------->|                         |
 |                        |-- INSERT id=5 --------->|
```

This is fine for natural keys (an ISO country code, an ISBN), where the value comes from the real world. For surrogate keys (meaningless numeric IDs), you don't want to invent them yourself, because two app instances could pick the same number.

### Step 2: add `@GeneratedValue`

```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```

State before and after `save()`:

```
BEFORE save():            AFTER save():
User { id=null }          User { id=1 }   <- Hibernate wrote it back
```

The rule is that the id is `null` before the first save and filled in after. That is also how Spring Data decides whether an entity is new: `id == null` means it calls `persist` (INSERT), and `id != null` means it calls `merge` (SELECT, then INSERT or UPDATE). Remember this, because it matters in section 4.

### Step 3: the four strategies, in order of complexity

|Strategy|Who makes the ID|Typical DB|
|---|---|---|
|`IDENTITY`|The DB column itself (`GENERATED ... AS IDENTITY`, `AUTO_INCREMENT`)|MySQL, Postgres, SQL Server|
|`SEQUENCE`|A DB sequence object, queried _before_ the insert|Postgres, Oracle|
|`TABLE`|A helper table that simulates a sequence|Anything (slow, rarely used)|
|`AUTO`|Hibernate picks one for your dialect|Default|

#### IDENTITY: the DB assigns the ID _during_ the INSERT

```
Hibernate                         PostgreSQL
   |-- INSERT INTO users(email) -->|
   |<-------- generated id = 1 ----|
```

Hibernate **cannot know the ID until the INSERT actually runs**. So it must execute the INSERT immediately when you call `save()`, even inside a transaction that hasn't committed. This means no JDBC batching of inserts.

#### SEQUENCE: Hibernate asks the DB for IDs _first_

```java
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_seq")
@SequenceGenerator(name = "user_seq", sequenceName = "user_seq", allocationSize = 50)
private Long id;
```

```
Hibernate                            PostgreSQL
   |-- SELECT nextval('user_seq') -->|
   |<-- 51 --------------------------|   (increment is 50)
   |
   |  Hibernate now owns IDs 1..50 in memory (the "pooled optimizer")
   |  and hands them out with no DB round trip:
   |  User#1 -> 1, User#2 -> 2, ... User#50 -> 50
   |
   |-- INSERT x 50 (can be batched) -->|
```

This is where your "7 to 51" mystery comes from. When the app restarted, Hibernate threw away its unused in-memory IDs and asked for a fresh block. The gaps are **normal and harmless**. Primary keys must be unique, not contiguous.

#### AUTO in Spring Boot 3 / Hibernate 6

On PostgreSQL, `AUTO` resolves to `SEQUENCE`, using a sequence named `<entity>_seq` (here `users_seq`) with `allocationSize = 50`. In older Hibernate 5 it resolved to a shared `hibernate_sequence`, so old tutorials may not match what you see.

## 4. The conflict: where the system can't decide for you

### Failure A: setting an ID yourself on a generated entity

```java
User u = new User();
u.setId(100L);                    // you "helpfully" set it
u.setEmail("a@x.com");
userRepository.save(u);
```

Spring Data sees `id != null`, so it assumes this is an existing row and calls `merge`. Hibernate runs a `SELECT ... WHERE id = 100`, finds nothing, and then **inserts a new row with a generated ID, ignoring your 100**. With `EntityManager.persist()` directly you get:

```
PersistentObjectException: detached entity passed to persist
```

The system can't tell whether your `100` means "update row 100" or "insert with 100", so it picks one interpretation, and it's often not the one you wanted.

### Failure B: sequence mismatch

You create the sequence by hand, or via a migration script:

```sql
CREATE SEQUENCE user_seq START 1 INCREMENT 1;
```

But the entity says `allocationSize = 50`. Hibernate believes it owns IDs 1..50 after the first `nextval`, but the DB hands out 1, then 2. Result:

```
Hibernate block:   [ 1 ........................ 50 ]
Another instance:  nextval -> 2  (collision zone)

ERROR: duplicate key value violates unique constraint "users_pkey"
```

With `spring.jpa.hibernate.ddl-auto=validate` you'd catch this at startup: `sequence [user_seq] defined inconsistent increment of [1]; expected [50]`.

## 5. Resolution

For Failure A, let the generator own the ID:

```java
User u = new User();             // id stays null
u.setEmail("a@x.com");
User saved = userRepository.save(u);   // use the RETURNED object
System.out.println(saved.getId());
```

For Failure B, make the two sides agree:

```sql
CREATE SEQUENCE user_seq START 1 INCREMENT 50;
```

```java
@SequenceGenerator(name = "user_seq", sequenceName = "user_seq", allocationSize = 50)
```

The invariant is that **the DB sequence's `INCREMENT BY` must equal `allocationSize`.** In real projects, Flyway or Liquibase creates the sequence and `ddl-auto=validate` guards it.

## 6. Advanced example: bulk import with two instances

**Situation:** two instances of your app run behind a load balancer, and each imports 10,000 users nightly. Compare both strategies.

### With IDENTITY

```java
@Transactional
public void importUsers(List<User> users) {
    for (User u : users) {
        userRepository.save(u);   // INSERT fires immediately, each time
    }
}
```

```
save(u1) -> INSERT (1 round trip) -> id known
save(u2) -> INSERT (1 round trip) -> id known
... 10,000 round trips
```

Hibernate needs each ID right away, because the entity must live in the persistence context under its key. So `hibernate.jdbc.batch_size` is **silently ignored** for inserts. It's slow, and no error tells you why.

### With SEQUENCE (`allocationSize = 50`)

```properties
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true
```

```
10,000 users -> 200 x nextval (one per 50)
             -> 200 batched INSERT statements of 50 rows each
```

Hibernate already knows every ID, so it defers the INSERTs until flush and sends them in batches. This is typically an order of magnitude faster.

### Why two instances don't collide

```
Instance A: nextval -> 1    => owns [1..50]
Instance B: nextval -> 51   => owns [51..100]
Instance A: nextval -> 101  => owns [101..150]
```

Each `nextval` jumps by 50, so every instance gets a disjoint block. This works _only because_ of the invariant from section 5.

### What could go wrong

- **Someone inserts rows manually with SQL** (`INSERT ... VALUES (7, ...)`), bypassing the sequence. Later the sequence reaches 7 and you get a duplicate key. Fix: always use the sequence, or `SELECT setval(...)` after bulk loads.
- **`allocationSize = 1`** "fixes" the gaps but costs one DB round trip per insert, so you've lost the main benefit of sequences.
- **IDs are not time-ordered across instances.** Instance B can insert ID 51 before Instance A inserts ID 2. Never use the ID as a creation-order proxy. Use a `createdAt` timestamp.

### What-if variations

**What if you use `Long` vs `long` for the id?** Prefer the wrapper type `Long`. A primitive `long` defaults to `0`, never `null`, so Spring Data can't tell "new" from "persisted" by null-check.

**What if the ID is exposed in URLs and you don't want it guessable?** Use a UUID:

```java
@Id
@GeneratedValue(strategy = GenerationType.UUID)   // Hibernate 6.2+/Spring Boot 3.1+
private UUID id;
```

No DB round trip is needed, so IDs can be generated anywhere. The cost is a bigger index (16 bytes vs 8) and random insert locations, which fragment B-tree indexes. Random UUIDv4 is worse for big tables than sequential IDs.

## 7. Contrastive comparison: IDENTITY vs SEQUENCE

```
IDENTITY                              SEQUENCE
--------                              --------
save(u1)                              save(u1)  -> id from memory block
  -> INSERT now                       save(u2)  -> id from memory block
save(u2)                              save(u3)  -> id from memory block
  -> INSERT now                       flush()
save(u3)                                -> BATCH INSERT (u1,u2,u3)
  -> INSERT now
```

||IDENTITY|SEQUENCE|
|---|---|---|
|Insert batching|Disabled|Works|
|DB round trips for IDs|0 extra (it's in the INSERT)|1 per `allocationSize` entities|
|Setup complexity|Trivial|Must keep sequence and `allocationSize` in sync|
|Gaps in IDs|Rare (rollbacks only)|Common (restarts, rollbacks, blocks)|
|Best for|Simple apps, MySQL, low insert volume|Postgres/Oracle, bulk writes, multiple instances|

**Rule of thumb:** on PostgreSQL (your Debian setup), use `SEQUENCE`, which `AUTO` already gives you. On MySQL, `IDENTITY` is your only real option. Use `UUID` when IDs must be generated outside the DB or must not be guessable.

## 8. Key mental model recap

- `@Id` declares identity. Without it the entity doesn't exist for JPA.
- `@GeneratedValue` hands ID creation to the framework, so **you never set the ID on a new entity**.
- `id == null` means new (INSERT), and `id != null` means existing (merge).
- `IDENTITY` means the DB assigns the ID during the INSERT, so there's no batching.
- `SEQUENCE` means Hibernate reserves a block of IDs up front, which gives batching and gaps.
- The DB sequence `INCREMENT` must equal `allocationSize`.
- Gaps in IDs are normal, and IDs are not an ordering mechanism.

```
          new User()  (id = null)
                 |
                 v
          repository.save(u)
                 |
        +--------+---------+
        |                  |
    IDENTITY           SEQUENCE
        |                  |
  INSERT now,         take next ID from
  DB returns ID       in-memory block
        |            (nextval every 50)
        |                  |
        |             defer INSERT,
        |             batch on flush
        +--------+---------+
                 |
                 v
        entity has id != null
        (managed in persistence context)
```

**Takeaway:** _Let the framework own surrogate keys, never set them yourself, and choose `SEQUENCE` over `IDENTITY` whenever your database supports it, keeping its increment in sync with `allocationSize`._



[[Spring Framework]]
[[PostgreSQL]]