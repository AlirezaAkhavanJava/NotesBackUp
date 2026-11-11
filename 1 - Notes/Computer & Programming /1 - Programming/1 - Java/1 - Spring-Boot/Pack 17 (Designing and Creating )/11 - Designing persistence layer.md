
Every method in your repository and service layers makes a promise through its return type. `Optional<Orders>` promises "the result might be missing, and you must deal with that." `OrderResponse` promises "here is exactly what you need, nothing more." `Orders` promises "here is a live database object", and that promise is the dangerous one, because it comes with hidden rules about transactions and lazy loading.

So designing these two layers is mostly one question asked over and over: **what should this method hand back, given who calls it?** The persistence layer (repositories) answers in terms of data and absence. The logic layer (services) answers in terms of use cases: it throws when a business rule is broken, and it hands the controller something safe to serialize. You've already met the pieces (entities, DTOs, mappers, CRUD, `@Transactional`, `ProblemDetail`). This lesson wires them together.

## The two layers have different jobs

|Layer|Job|Speaks in terms of|Returns|
|---|---|---|---|
|Repository|Fetch and store rows. No business rules.|Entities, projections, absence|`Optional`, `List`, `Page`, `boolean`, `int`|
|Service|Business rules, transactions, mapping|Use cases, failures|DTOs, `void`, exceptions|
|Controller|HTTP|Status codes, JSON|`ResponseEntity` / DTO|

Keep this rule in mind through the rest: **entities live between the repository and the service. DTOs live between the service and the controller.**

## Part 1: the repository layer

```java
public interface OrderRepository extends JpaRepository<Orders, Long> {

    Optional<Orders> findByOrderNumber(String orderNumber);   // zero or one
    boolean existsByOrderNumber(String orderNumber);          // just yes/no
    List<Orders> findByStatus(String status);                 // zero or many
    Page<OrderSummary> findByCustomerId(Long customerId, Pageable pageable);

    @Modifying
    @Query("update Orders o set o.status = :status where o.id = :id")
    int updateStatus(@Param("id") Long id, @Param("status") String status);
}

public record OrderSummary(Long id, String orderNumber, String status) {}
```

Why each return type fits:

**`Optional<T>`: a lookup of at most one row.** `findById` and unique derived queries like `findByOrderNumber` use it because "not found" is normal for a lookup. `Optional` makes the caller handle it. If you declare the return type as plain `Orders` instead, a missing row gives you `null`, and the first `.getStatus()` throws a `NullPointerException` somewhere far away. Worse, if more than one row matches, Spring Data throws `IncorrectResultSizeDataAccessException`. So: unique lookup → `Optional`.

**`List<T>`: zero or many.** It's never `null`; an empty result is an empty list. Don't wrap it in `Optional`, because `Optional<List<T>>` has two ways to say "nothing" and no benefit.

**`boolean` (`existsBy...`): when you only need to know it exists.** It runs `select 1 ... limit 1` and loads no entity. Use it for duplicate checks instead of `findBy(...).isPresent()`.

**`Page<T>` / `Slice<T>`: paging.** `Page` runs an extra `count` query so you know the total. `Slice` skips the count and only tells you if there is a next page, so it's cheaper for "load more" screens.

**`int`: from `@Modifying` queries.** It's the number of rows changed. Check it: `0` means the id didn't exist.

**`Stream<T>`: huge results.** It must be consumed inside a transaction and closed (try-with-resources). Rare in typical CRUD.

**Projections (`OrderSummary` above).** For read-only lists, don't load full entities. A record with only the fields you need makes Hibernate select just those columns. No lazy collections, no wasted memory.

Two more repository points:

- `save()` returns `T`. **Use the returned object, not the one you passed in.** For a new entity they're the same, but for an existing one `save()` does a `merge` and returns a _different_ instance.
- `getReferenceById(id)` returns a lazy proxy without hitting the database, and throws `EntityNotFoundException` only when you touch it. Use it when you just need a foreign key reference, such as `order.setCustomer(customerRepo.getReferenceById(id))`. Don't use it to check existence.

## Part 2: the service layer

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OrderService {

    private final OrderRepository repo;
    private final OrderMapper mapper;

    public OrderResponse getById(Long id) {
        return repo.findById(id)
                   .map(mapper::toResponse)
                   .orElseThrow(() -> new ResourceNotFoundException("Order " + id + " not found"));
    }

    public Page<OrderSummary> list(Long customerId, Pageable pageable) {
        return repo.findByCustomerId(customerId, pageable);
    }

    @Transactional
    public OrderResponse create(CreateOrderRequest request) {
        if (repo.existsByOrderNumber(request.orderNumber())) {
            throw new DuplicateResourceException("Order number already used");
        }
        Orders saved = repo.save(mapper.toEntity(request));
        return mapper.toResponse(saved);
    }

    @Transactional
    public OrderResponse update(Long id, UpdateOrderRequest request) {
        Orders order = repo.findById(id)
                           .orElseThrow(() -> new ResourceNotFoundException("Order " + id + " not found"));
        mapper.updateEntity(order, request);   // changes tracked automatically
        return mapper.toResponse(order);       // no save() needed
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) {
            throw new ResourceNotFoundException("Order " + id + " not found");
        }
        repo.deleteById(id);
    }
}
```

Walkthrough of the decisions:

- **`@Transactional(readOnly = true)` on the class, `@Transactional` on writes.** Reads default to read-only, writes opt in. This works through the proxy from your `@Transactional` lesson, so calling one of these methods from another method _inside the same class_ skips the proxy.
- **`getById` converts `Optional` into an exception.** The caller asked for a specific order, so "missing" is an error. Throwing `ResourceNotFoundException` lets your `@RestControllerAdvice` turn it into a `404` `ProblemDetail`, as in your exception handler lesson. The controller stays free of `if (x.isEmpty())` code.
- **Mapping to the DTO happens _inside_ the service.** The transaction is still open, so any lazy field the mapper touches loads fine. After the method returns, the transaction ends, and a lazy field touched later throws `LazyInitializationException`.
- **`update` returns after changing a managed entity.** Inside a transaction, Hibernate tracks changes (dirty checking) and writes an UPDATE at commit. No `save()` call is needed.
- **`create` checks `existsByOrderNumber` first**, which gives a nice error message, but two requests can pass that check at once. The real guarantee is the unique constraint from your `@Table` lesson. Catch `DataIntegrityViolationException` in the handler and answer `409`.
- **`delete` returns `void`.** Success is silence, failure is an exception. Don't return `boolean` for success or failure.

## Why not return the entity from the service?

It's tempting: `public Orders getById(Long id)`. In production code this causes real trouble:

1. **Lazy loading breaks.** Jackson serializes the entity in the controller, after the transaction closed. Any lazy association throws `LazyInitializationException`.
2. **Spring Boot hides this by default.** `spring.jpa.open-in-view` is `true`, which keeps the session open during the request so lazy loading "works", but it holds a database connection for the whole request, including JSON writing. Set it to `false` and design properly.
3. **Leaks.** A `User` entity has `passwordHash`. Return it and you serialize it.
4. **Coupling.** Every column rename changes your public API.
5. **Cycles.** `Order → Customer → Orders → …` makes Jackson recurse forever.

So the service returns DTOs (usually records), produced by the mapper from your MapStruct lesson. Services _may_ pass entities to each other inside one transaction, when `OrderService` calls `CustomerService` internally. That's fine because the transaction is shared.

## Part 3: when `Optional` should come out of the service

Most of the time, the service throws. But `Optional` belongs in a service return type when absence is a **legitimate outcome the caller decides what to do with**:

```java
public Optional<ProfileResponse> findProfile(Long userId) {   // user may not have set one up
    return profileRepo.findByUserId(userId).map(mapper::toResponse);
}
```

The controller can then return the profile, or an empty default, or `204`. The test: _if "missing" is a mistake, throw; if "missing" is a normal answer, return `Optional`._

`Optional` rules:

- Only as a **return type**. Not as a field, a method parameter, or inside a collection.
- Never call `.get()` without checking. Use `orElseThrow`, `map`, `orElseGet`.
- `orElse(x)` always computes `x`; use `orElseGet(() -> ...)` when the default is expensive.
- Never return `null` from a method that returns `Optional`.

## Part 4: when there are several expected outcomes

Sometimes a method has more than "success or exception". Registration might succeed, or the email might be taken, or the password might be too weak. These are business outcomes, not crashes. A sealed type makes each outcome explicit, and the compiler forces the caller to handle all of them:

```java
public sealed interface RegisterResult {
    record Created(UserResponse user) implements RegisterResult {}
    record EmailTaken(String email)   implements RegisterResult {}
    record WeakPassword(String reason) implements RegisterResult {}
}

// controller
return switch (userService.register(request)) {
    case RegisterResult.Created c      -> ResponseEntity.status(201).body(c.user());
    case RegisterResult.EmailTaken e   -> ResponseEntity.status(409).build();
    case RegisterResult.WeakPassword w -> ResponseEntity.badRequest().build();
};
```

Use this sparingly. For the plain case, exceptions plus `ProblemDetail` are simpler and your project already has the infrastructure.

## The decision table

|Situation|Repository returns|Service returns|
|---|---|---|
|Get one by id, must exist|`Optional<Entity>`|DTO, throws if missing|
|Get one, missing is normal|`Optional<Entity>`|`Optional<DTO>`|
|Does it exist?|`boolean`|`boolean` or throws|
|List|`List<Entity>` or `List<Projection>`|`List<DTO>`|
|Paged list|`Page<Projection>`|`Page<DTO>`|
|Create|`T save(...)`|DTO including the new id|
|Update|(managed entity)|DTO, or `void`|
|Delete|`void`|`void`, throws if missing|
|Bulk update|`int`|`void` or count|
|Several valid outcomes|n/a|sealed result type|

## Common mistakes

- Returning `null` from a method instead of `Optional` or an empty list.
- Returning entities from the service, then fighting `LazyInitializationException` with `open-in-view` or `FetchType.EAGER` everywhere.
- Using the object you passed into `save()` instead of the returned one.
- Putting business rules (checks, state transitions) in the repository. It should only know how to read and write.
- Returning `Page` straight from a controller. Recent Spring Data versions warn about serializing `PageImpl` because its JSON shape isn't guaranteed stable. Wrap it in your own response record, or use Spring Data's `PagedModel`.

## A related concept, briefly

**Fetching strategy** decides which related data gets loaded together. When your DTO needs `order.getCustomer().getName()`, loading it lazily for each of 100 orders causes the "N+1 queries" problem. The fix is a repository method with `@EntityGraph` or a `join fetch` query, or, better for read endpoints, a projection that selects exactly those columns in one query. It's the reason projections appear in the repository layer.


[[Spring Framework]]