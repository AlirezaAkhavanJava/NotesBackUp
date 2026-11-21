

Deciding where to put `@Transactional` is deciding where a unit of work starts and ends. Everything inside that boundary uses one database transaction: it commits together or rolls back together. You already know the proxy is what makes the annotation work, so this lesson is about the decisions: which methods get a boundary, what goes inside it, and which settings to change.

Most `@Transactional` mistakes are not syntax mistakes. They are boundary mistakes: a boundary that is too small, so a half-finished change gets committed, or one that is too big, so a database connection is held for seconds. Getting this right matters more than memorizing the attributes.

## When to use it

Ask one question: **does this method need several database operations to succeed or fail as one?**

|Situation|Use it?|
|---|---|
|One `save()` or `findById()` call|No. Repository methods already run in their own transaction.|
|Two or more writes that must succeed together|Yes|
|Read something, then change it based on what you read|Yes|
|Query method that maps lazy relations into a DTO|Yes, with `readOnly = true`|
|Controller method|No. The boundary belongs in the service layer you designed earlier.|
|Method that calls an external HTTP API and also saves|Not around the whole method. Split it (see the gotchas below).|

The service layer is the natural home. A service method is one business operation, and one business operation is one unit of work.

## How to use it

Put `readOnly = true` on the class as the default, then override it on the methods that write:

```java
@Service
@Transactional(readOnly = true)
public class OrderService {

    private final OrderRepository orders;
    private final ProductRepository products;

    public OrderService(OrderRepository orders, ProductRepository products) {
        this.orders = orders;
        this.products = products;
    }

    public OrderResponse getOrder(Long id) {
        return orders.findById(id)
                .map(OrderMapper::toResponse)
                .orElseThrow(() -> new OrderNotFoundException(id));
    }

    @Transactional
    public OrderResponse placeOrder(PlaceOrderRequest request) {
        Product product = products.findById(request.productId())
                .orElseThrow(() -> new ProductNotFoundException(request.productId()));

        product.decreaseStock(request.quantity());   // throws if stock is too low
        Order order = orders.save(new Order(product, request.quantity()));

        return OrderMapper.toResponse(order);
    }
}
```

Two things in this example are new:

- **Dirty checking.** Inside a transaction, Hibernate tracks the entities it loaded. When the transaction commits, it compares them to their original state and issues an `UPDATE` for anything that changed. That is why there is no `products.save(product)`. If `decreaseStock` throws, nothing is written at all.
- **Mapping to the DTO inside the method.** Lazy relations can only be loaded while the transaction is open. Mapping before the method returns means the entity never leaves the service half-loaded.

Always import `org.springframework.transaction.annotation.Transactional`, not the `jakarta.transaction` one. Spring's version has `readOnly`, `rollbackFor`, and `propagation` with the behavior described here.

## The settings that matter

**`readOnly = true`** is more than documentation. Hibernate skips dirty checking for the transaction, so it does less work, and the PostgreSQL driver marks the transaction read-only. It also protects you: an accidental write in a method you declared read-only won't be flushed.

**`rollbackFor`.** By default Spring rolls back only on unchecked exceptions (`RuntimeException` and `Error`). A checked exception like `IOException` commits whatever was already written. If a checked exception should undo the work, say so:

```java
@Transactional(rollbackFor = Exception.class)
public void importOrders(Path file) throws IOException { ... }
```

**`propagation`** decides what happens when a transactional method is called while a transaction is already running. You will use two values almost all the time:

|Value|Behavior|
|---|---|
|`REQUIRED` (default)|Join the existing transaction, or start one if none exists|
|`REQUIRES_NEW`|Suspend the current transaction and run in a separate one that commits on its own|

The others (`SUPPORTS`, `MANDATORY`, `NOT_SUPPORTED`, `NEVER`, `NESTED`) exist, but reach for them only when you can name the exact reason. `REQUIRES_NEW` is for work that must persist even if the outer transaction rolls back, like recording a failure:

```java
@Service
public class AuditService {

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordFailure(String message) {
        // saved and committed even if the caller's transaction rolls back
    }
}
```

It takes a second connection from the pool while the first is still held. If many requests do this at once and the pool is small, every connection can end up held by an outer transaction waiting for an inner one. That is the connection-pool lesson showing up again, so use `REQUIRES_NEW` sparingly.

**`isolation`** controls what concurrent transactions can see of each other. Leave it at the default, which is `READ COMMITTED` on PostgreSQL. Raising it to `REPEATABLE_READ` or `SERIALIZABLE` can make the database abort transactions with serialization errors, so only do it if your code is ready to retry.

**`timeout`** is in seconds. A transaction that exceeds it is rolled back. It is a useful safety net on operations that could run long.

## Gotchas that bite in real code

**1. A caught exception can still doom the transaction.** When an inner `@Transactional` method (joined with `REQUIRED`) throws a runtime exception, Spring marks the whole transaction as rollback-only at that moment. If the outer method catches the exception and carries on, the commit fails:

```java
@Transactional
public void outer() {
    try {
        inner.doWork();          // @Transactional, throws RuntimeException
    } catch (RuntimeException e) {
        log.warn("ignored", e);  // too late: transaction is already rollback-only
    }
}   // commit -> UnexpectedRollbackException
```

If the inner work really is optional, make it `REQUIRES_NEW` so its failure stays separate.

**2. Swallowing the exception inside the method.** A `try/catch` around your own writes that doesn't rethrow means Spring never sees a failure, so it commits.

**3. Slow work inside the boundary.** A transaction holds a pooled connection from the first query until commit. Calling an external API, sending an email, or waiting on a file inside that boundary keeps the connection busy. Do the slow call before or after, and keep only the database work inside.

**4. Check-then-act is not automatically safe.** Reading stock and then decreasing it in one transaction still lets two requests read the same value under `READ COMMITTED`. A transaction groups the operations, but it doesn't lock the row by itself. You need optimistic locking (`@Version`) or a pessimistic lock on the query for that.

## Related concepts, briefly

**`TransactionTemplate`** gives you the same boundary as plain code instead of an annotation. It is useful when only a few lines of a method should be transactional, so you don't have to split the method into two beans.

**`@TransactionalEventListener(phase = AFTER_COMMIT)`** runs a listener only after the transaction has committed successfully. It is the clean way to send a confirmation email or publish a message after an order is saved, without holding the transaction open and without sending anything if it rolls back.



[[Spring Framework]]