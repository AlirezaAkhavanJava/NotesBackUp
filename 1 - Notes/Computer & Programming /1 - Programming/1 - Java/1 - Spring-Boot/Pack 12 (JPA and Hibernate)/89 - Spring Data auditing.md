Spring Data auditing fills in "who created this row, when, and who last changed it" for you. You add four fields to your entity, switch auditing on once, and from then on every `save()` stamps `createdAt`, `updatedAt`, `createdBy` and `updatedBy` automatically. You never write `entity.setCreatedAt(Instant.now())` in a service again, and nobody can forget to.

It works through an entity listener. Before Hibernate inserts or updates a row, a listener that Spring Data provides runs, reads the current time and the current user, and writes them into your annotated fields. The time comes from the system clock. The user comes from a small bean you write, called `AuditorAware`. That bean is where Spring Security enters, and it ties back to your `Authentication` and `SecurityContext` lessons.

## The moving parts

There are exactly five pieces:

|Piece|Role|
|---|---|
|`@CreatedDate`|Set once, at insert|
|`@LastModifiedDate`|Set at insert, and again at every update|
|`@CreatedBy`|Set once, at insert, from `AuditorAware`|
|`@LastModifiedBy`|Set at insert and every update, from `AuditorAware`|
|`@EnableJpaAuditing` + `AuditingEntityListener`|The switch and the listener that does the work|

Behind the scenes, `AuditingEntityListener` is a normal JPA listener. It has a `@PrePersist` method (runs before INSERT) and a `@PreUpdate` method (runs before UPDATE). Those two callbacks are the whole mechanism.

## Step 1: a base class for the audit fields

Put the fields in one `@MappedSuperclass` so every entity can inherit them. Your `@GeneratedValue` id stays in each entity, so the base class only holds audit data.

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter
public abstract class Auditable {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @CreatedBy
    @Column(name = "created_by", nullable = false, updatable = false)
    private String createdBy;

    @LastModifiedBy
    @Column(name = "updated_by", nullable = false)
    private String updatedBy;
}
```

Line by line:

- `@MappedSuperclass` means the class is not a table. Its fields become columns in every subclass's table.
- `@EntityListeners(AuditingEntityListener.class)` attaches the listener. Without this line, nothing happens and the fields stay `null`. This is the most common mistake.
- `Instant` is the best type here. It's a point in UTC time, so no time zone confusion. `LocalDateTime`, `OffsetDateTime`, `ZonedDateTime` and `java.util.Date` also work.
- `updatable = false` on the "created" columns is a safety net: even if some code overwrites the field, Hibernate won't include it in an UPDATE statement.
- Only `@Getter`, no setters. These fields are written by the listener (it uses field access, not setters), so you don't want your own code touching them. This is the same idea as excluding `id` from setters in your Lombok lesson.

Then use it:

```java
@Entity
@Getter @Setter
public class Orders extends Auditable {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "orders_seq_gen")
    @SequenceGenerator(name = "orders_seq_gen", sequenceName = "orders_seq", allocationSize = 50)
    private Long id;

    private String status;
}
```

## Step 2: tell Spring who the current user is

`AuditorAware<T>` has one method. The type `T` is whatever you want stored in `createdBy`: a `String` username, a `Long` user id, or a `UUID`.

```java
@Component
public class SecurityAuditorAware implements AuditorAware<String> {

    @Override
    public Optional<String> getCurrentAuditor() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
            return Optional.of("system");
        }
        return Optional.of(auth.getName());
    }
}
```

Walkthrough:

- `SecurityContextHolder` gives you the `Authentication` of the current request thread. That's the object from your Authentication lesson, and with your JWT filter it's already filled in by the time the controller runs.
- Unauthenticated callers show up as an `AnonymousAuthenticationToken`, not as `null`, so you check for both.
- `Optional.of("system")` is the fallback for things with no logged-in user: scheduled jobs, startup data loaders, a public `/register` endpoint. Because the columns are `NOT NULL`, returning `Optional.empty()` would make the insert fail. Choose "system" or choose nullable columns, but decide on purpose.
- `auth.getName()` returns the username. If you'd rather store the user id, cast `getPrincipal()` to your `UserDetails` implementation and return its id.

## Step 3: switch it on

```java
@Configuration
@EnableJpaAuditing(auditorAwareRef = "securityAuditorAware")
public class JpaAuditingConfig { }
```

- `auditorAwareRef` is the **bean name** of your `AuditorAware`. If only one such bean exists, Spring finds it by itself and you can omit it.
- Put this on its own `@Configuration` class, not on your `@SpringBootApplication` class. If it sits on the main class, slice tests like `@WebMvcTest` load it and fail, because they have no JPA metamodel.

The other parameters of `@EnableJpaAuditing`:

- `dateTimeProviderRef` points to a `DateTimeProvider` bean. By default Spring uses the system clock. You override it when you want a fixed or injected `Clock` in tests.
- `modifyOnCreate` (default `true`) controls whether the "last modified" fields are also set on insert. With `true`, a brand-new row has `updatedAt == createdAt`. Set it to `false` if you want them `null` until the first real update.
- `setDates` (default `true`) lets you turn off date auditing and keep only the user fields.

## Step 4: the database side

Create the columns in a Flyway migration. You already know this part from your DDL lesson.

```sql
-- V4__add_audit_columns.sql
ALTER TABLE orders
    ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN created_by TEXT        NOT NULL DEFAULT 'system',
    ADD COLUMN updated_by TEXT        NOT NULL DEFAULT 'system';
```

`TIMESTAMPTZ` is the PostgreSQL type that matches `Instant`. The `DEFAULT` values let you add `NOT NULL` columns to a table that already has rows, and they cover rows written by raw SQL. With SQLite there is no real timestamp type, so Hibernate stores the value as text or a number. It still works, but compare dates through Java, not SQL.

## What happens at runtime

```java
Orders o = new Orders();
o.setStatus("NEW");
orderRepository.save(o);          // INSERT
```

Before the INSERT, the listener sets all four fields. All four are filled: `createdAt` and `updatedAt` with the same instant, `createdBy` and `updatedBy` with the username.

```java
o.setStatus("PAID");
orderRepository.save(o);          // UPDATE
```

Before the UPDATE, only `updatedAt` and `updatedBy` change. The created fields stay, protected by `updatable = false`.

## Gotchas you'll hit

**Only entity changes trigger the listener.** `@PreUpdate` runs when Hibernate finds the entity _dirty_ at flush. If you call `save()` but nothing actually changed, there is no UPDATE and `updatedAt` stays the same. That's correct behavior.

**Bulk operations skip auditing completely.** A `@Modifying @Query("UPDATE Orders o SET o.status = ...")`, a native SQL insert, and `deleteAllInBatch()` all bypass the entity lifecycle, so no listener runs. If you use them, set `updated_at` and `updated_by` in the query yourself, or rely on a database trigger.

**The listener sees the thread's user.** If you save from a `@Async` method or a new thread, the `SecurityContext` is not copied over by default, so `getCurrentAuditor()` falls to your "system" branch. Use a security-aware executor if you need the real user there.

**Don't let clients send audit fields.** Keep them out of request DTOs and tell MapStruct to ignore them when mapping DTO → entity:

```java
@Mapping(target = "createdAt", ignore = true)
@Mapping(target = "updatedAt", ignore = true)
@Mapping(target = "createdBy", ignore = true)
@Mapping(target = "updatedBy", ignore = true)
Orders toEntity(OrderRequest request);
```

Response DTOs can include them freely.

## Testing it

```java
@DataJpaTest
@Import(JpaAuditingConfig.class)
class AuditingTest {

    @Autowired OrderRepository repo;

    @Test
    @WithMockUser("alice")
    void fillsAuditFields() {
        Orders saved = repo.saveAndFlush(new Orders());
        assertThat(saved.getCreatedBy()).isEqualTo("alice");
        assertThat(saved.getCreatedAt()).isNotNull();
    }
}
```

`@DataJpaTest` doesn't load your config automatically, so you `@Import` it. `@WithMockUser` fills the `SecurityContext`. `saveAndFlush` forces the INSERT so the listener runs inside the test.

## Production design

- One `Auditable` base class for all entities, so every table has the same four columns.
- `Instant` in Java, `TIMESTAMPTZ` in PostgreSQL, always UTC. Convert to a user's time zone only at the edge, when you show it.
- Store a stable identifier in `createdBy`: a username that can change makes old rows misleading, so many teams store the user id instead.
- Keep the database defaults in the migration as a safety net for anything that bypasses JPA.
- Inject a `Clock` through a `DateTimeProvider` so tests can use fixed time.
- Combine with `@Version` (optimistic locking) if concurrent edits matter. Auditing tells you _who last changed_ a row. `@Version` stops two people from overwriting each other.

## Related concepts, briefly

- **Hibernate `@CreationTimestamp` / `@UpdateTimestamp`**: Hibernate's own annotations for timestamps only. No user tracking and no Spring dependency, but no `@CreatedBy` either.
- **Hibernate Envers**: auditing in a different sense. Instead of "last modified by", it keeps the _full history_ of every row in `_aud` tables, so you can see each old value. Use it when you need a real change log. Use Spring Data auditing when "who and when, last time" is enough. The two combine well.
- **Other stores**: Mongo and R2DBC have their own enable annotations (`@EnableMongoAuditing`, `@EnableR2dbcAuditing`), and the four annotations and `AuditorAware` work the same way.



[[Spring Framework]]