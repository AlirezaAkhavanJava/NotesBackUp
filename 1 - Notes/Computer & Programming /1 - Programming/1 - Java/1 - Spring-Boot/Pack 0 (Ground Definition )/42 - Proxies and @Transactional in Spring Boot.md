


A **proxy** is a stand-in object. It looks exactly like the real object, has the same methods, and can be used in the same places, but it sits in front of the real one. Every call goes to the proxy first. The proxy can do extra work before the call, after it, or instead of it, and then (usually) pass the call on to the real object. The caller never notices, because it thinks it is talking to the real thing.

This matters in Spring because a huge amount of "magic" is really just proxies. When you put `@Transactional` on a method, you never write any code that opens or commits a transaction. Spring quietly gives your other classes a proxy of your bean, and the proxy does the opening, committing and rolling back around your method. Once you understand the proxy, `@Transactional` (and `@Async`, `@Cacheable`, `@PreAuthorize`, and Spring Data repositories) stop being magic and become predictable, including the strange bugs that come with them.

---

## Part 1: A proxy built by hand

Forget Spring for a moment. Here is the idea in plain Java.

```java
public interface PaymentService {
    void pay(int amount);
}

public class RealPaymentService implements PaymentService {
    @Override
    public void pay(int amount) {
        System.out.println("Paying " + amount);
    }
}
```

Now a proxy that adds logging, without touching `RealPaymentService`:

```java
public class LoggingProxy implements PaymentService {

    private final PaymentService target;          // 1

    public LoggingProxy(PaymentService target) { // 2
        this.target = target;
    }

    @Override
    public void pay(int amount) {                 // 3
        System.out.println("Before pay()");
        target.pay(amount);                       // 4
        System.out.println("After pay()");
    }
}
```

Line by line:

1. The proxy holds a reference to the **target**, which is the real object it stands in for.
2. The target arrives through the constructor.
3. The proxy implements the **same interface**. That is the whole trick. Anyone who wants a `PaymentService` can't tell which one they got.
4. It forwards the call to the target, wrapped in extra behavior.

Using it:

```java
PaymentService service = new LoggingProxy(new RealPaymentService());
service.pay(50);
```

Output:

```
Before pay()
Paying 50
After pay()
```

The caller wrote `service.pay(50)` like always. The logging was added from the outside, and `RealPaymentService` stayed clean.

**The catch:** writing a proxy class by hand for every service would be exhausting. So Java and Spring *generate* them automatically at runtime.

---

## Part 2: How the proxy gets generated

There are two ways to generate a proxy while the app runs:

| | JDK dynamic proxy | CGLIB proxy |
|---|---|---|
| **How it works** | Creates a class that implements your **interfaces** | Creates a **subclass** of your class |
| **Needs an interface?** | Yes | No |
| **Limits** | Only interface methods are proxied | Class and methods can't be `final` |
| **Where you see it** | Spring Data repositories | Most `@Service` classes in Spring Boot |

Spring Boot uses CGLIB-style class proxies by default, so your `@Service` doesn't need an interface. You can see this yourself:

```java
System.out.println(transferService.getClass());
// class com.example.TransferService$$SpringCGLIB$$0
```

That odd name is the proof. The object you were given is a generated *subclass*, not your plain class.

### When does Spring build the proxy?

During the bean lifecycle. After Spring creates your bean and fills in its dependencies, a `BeanPostProcessor` looks at it and asks, "does this bean have anything that needs a proxy, like `@Transactional`?" If yes, Spring **replaces** the bean with a proxy wrapping it. From then on, whoever asks the container for that bean gets the proxy:

```
Spring creates real TransferService
        │
        ▼
BeanPostProcessor: "has @Transactional methods → wrap it"
        │
        ▼
Container stores the PROXY under the name "transferService"
        │
        ▼
Controller receives the PROXY when it injects TransferService
```

Your controller never sees the real object. It only talks to the proxy, and the proxy decides when to call the real one.

---

## Part 3: Why proxies matter

A proxy lets you add behavior around a method **without editing the method**. That kind of behavior is called a **cross-cutting concern**: it applies to many classes but isn't part of their real job. (This is exactly what AOP is about, and proxies are how Spring AOP is implemented.)

| Annotation | What the proxy adds around your method |
|---|---|
| `@Transactional` | Starts a transaction, commits or rolls back |
| `@Async` | Runs the method on another thread |
| `@Cacheable` | Returns a stored result instead of calling the method |
| `@PreAuthorize` | Checks permissions before the call |
| `@Retryable` | Calls the method again if it fails |
| Spring Data repository | Creates the whole implementation of your interface |

Without proxies, every service method would be full of repeated "open transaction, try, commit, catch, roll back" code. With proxies, it is written once and attached by annotation.

---

## Part 4: What @Transactional actually does

### First, what is a transaction?

A **transaction** is a group of database operations that must succeed or fail *together*. The classic example is moving money:

```
1. Take 100 from Alice's account
2. Add 100 to Bob's account
```

If step 1 works and step 2 crashes, 100 has vanished. A transaction guarantees that either **both** happen (commit) or **neither** happens (rollback).

| Money transfer | Transaction word |
|---|---|
| Both steps succeed | **commit** |
| Something fails midway, everything is undone | **rollback** |

### The code

```java
@Service
public class TransferService {

    private final AccountRepository repo;

    public TransferService(AccountRepository repo) {
        this.repo = repo;
    }

    @Transactional                                        // 1
    public void transfer(Long fromId, Long toId, BigDecimal amount) {
        Account from = repo.findById(fromId).orElseThrow();   // 2
        Account to   = repo.findById(toId).orElseThrow();

        from.withdraw(amount);                            // 3
        to.deposit(amount);
    }                                                     // 4
}
```

1. `@Transactional` tells Spring: "wrap this method in a transaction."
2. The entities are loaded *inside* the transaction, so JPA tracks them.
3. You change the objects in memory. You never call `save()`. When the transaction commits, JPA notices what changed (called **dirty checking**) and writes the UPDATE statements itself.
4. When the method ends normally, the proxy commits.

### What the proxy does for you

Here is the code you'd have to write without it, which is basically what the proxy does:

```java
// This is what the PROXY does around your method:
TransactionStatus tx = transactionManager.getTransaction(definition);  // begin
try {
    target.transfer(fromId, toId, amount);   // your real method
    transactionManager.commit(tx);           // success → commit
} catch (RuntimeException | Error e) {
    transactionManager.rollback(tx);         // failure → rollback
    throw e;                                 // rethrow to the caller
}
```

Behind the scenes, the transaction is attached to the current **thread**, so every repository call inside your method automatically uses the same database connection. That is why all the steps become one unit. (This links back to threads: a transaction belongs to one thread, and it does not follow you onto another one.)

---

## Part 5: The settings you will actually use

### Rollback rules

This one surprises almost everyone:

| What is thrown | Default behavior |
|---|---|
| `RuntimeException` (unchecked) | **Rolls back** |
| `Error` | **Rolls back** |
| Checked exception (`IOException`, your own `extends Exception`) | **Commits anyway!** |

To roll back on checked exceptions too:

```java
@Transactional(rollbackFor = Exception.class)
```

### readOnly

```java
@Transactional(readOnly = true)
public List<Movie> findAll() { ... }
```

This tells Spring and the database that nothing will be written, which allows some optimizations. Use it for pure read methods.

### Propagation: what if a transactional method calls another?

Propagation answers: "a transaction already exists, so what should this method do?"

| Propagation | Meaning |
|---|---|
| `REQUIRED` (default) | Join the existing transaction, or start one if none exists |
| `REQUIRES_NEW` | Always start a fresh, separate transaction (pauses the old one) |
| `SUPPORTS` | Join if one exists, otherwise run without |
| `MANDATORY` | Must already be inside one, otherwise throw an error |
| `NOT_SUPPORTED` | Run without a transaction (pauses the existing one) |
| `NEVER` | Throw an error if a transaction exists |
| `NESTED` | A sub-transaction inside the current one (savepoint) |

`REQUIRED` covers most cases. `REQUIRES_NEW` is useful for things that must be saved even if the main work fails, like writing an audit log.

### Isolation (short version)

Isolation controls how much concurrent transactions can "see" of each other's unfinished work. The default (`DEFAULT`) uses your database's own default, which is fine until you have a specific concurrency problem.

---

## Part 6: The traps (where proxy knowledge pays off)

Because `@Transactional` lives in the proxy, anything that **skips the proxy** skips the transaction.

### Trap 1: Self-invocation

```java
@Service
public class OrderService {

    public void process() {
        save();          // 1: calls this.save(), NOT through the proxy
    }

    @Transactional
    public void save() { ... }
}
```

When a controller calls `process()`, it goes through the proxy, but `process()` isn't transactional, so the proxy just passes the call along. Inside, `save()` is called on `this`, which is the **real object**, not the proxy. The transaction never starts. No error, no warning, just silently no transaction.

Fixes:

- Move `save()` into **another bean** and inject it (the cleanest fix).
- Put `@Transactional` on `process()` itself.
- Use `TransactionTemplate` for manual control.

### Trap 2: Private or final methods

A proxy can only intercept methods it can override and reach from outside. Keep `@Transactional` on **public, non-final** methods.

### Trap 3: Swallowing the exception

```java
@Transactional
public void transfer(...) {
    try {
        ...
    } catch (Exception e) {
        log.error("failed", e);   // exception eaten, proxy never sees it
    }
}
```

The proxy only rolls back if the exception **escapes** the method. If you catch it, the proxy believes everything went fine and commits.

### Trap 4: Checked exceptions

Covered above. Remember the `rollbackFor` setting.

### Trap 5: Wrong layer

Put `@Transactional` on the **service** layer, where one method equals one business action. Putting it on controllers or repositories tends to produce either too wide or too narrow transactions.

---

## A short related concept: AOP

**AOP (Aspect-Oriented Programming)** is the idea of pulling cross-cutting behavior (transactions, logging, security) out of your business code and attaching it from the outside. In Spring, the attaching is done by proxies. So "AOP" is the *idea* and "proxy" is the *mechanism*. `@Transactional` is simply a ready-made aspect that Spring ships for you.

---

## Quick recap

- A **proxy** is a stand-in with the same type as the real object that wraps each call with extra behavior.
- Spring creates proxies automatically (JDK proxy for interfaces, CGLIB subclass for classes) and swaps them in for your beans during startup.
- `@Transactional` = the proxy opens a transaction before your method, commits on success, and rolls back on a `RuntimeException`.
- Gotchas all come from bypassing the proxy: **self-invocation**, **private/final methods**, **swallowed exceptions**, and **checked exceptions**.




[[Spring Framework]]