


## The mental model: generic notes vs. purpose-built forms

Suppose every problem in a company were reported on a blank sheet of paper that says "Something went wrong." The receiving department would have to read each sheet, guess what kind of problem it is, and hunt for the details. Throwing `new Exception("insufficient funds")` is that blank sheet.

A **custom exception** is a purpose-built form: "Insufficient Funds Report," with labeled boxes for account ID, balance, and amount requested. It has three advantages:

1. **Routing by type.** The mail room (the `catch` clause) can send it straight to the right department without reading it.
2. **Structured data.** The handler reads `e.getShortfall()` instead of parsing text out of a message string.
3. **Vocabulary.** It names the problem in _your domain's_ language instead of the JDK's.

A custom exception is a **new type in your program's vocabulary of failure**. The catch clause matches on type, so the class itself carries the meaning.

## Mechanics

### The minimal version

```java
public class ConfigException extends RuntimeException {
    public ConfigException(String message) {
        super(message);
    }
    public ConfigException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

Checked or unchecked is decided entirely by **which class you extend**: `Exception` gives checked, `RuntimeException` gives unchecked. (Never extend `Error` or bare `Throwable` for application exceptions; those are reserved for JVM-level problems.)

### The conventional constructors

Throwable offers four constructor shapes, and custom exceptions usually mirror the ones they need:

|Constructor|Use|
|---|---|
|`()`|Rarely; the type alone says everything|
|`(String message)`|A fresh failure with no underlying cause|
|`(String message, Throwable cause)`|**Wrapping** a lower-level failure (the important one)|
|`(Throwable cause)`|Wrapping; message defaults to `cause.toString()`|

You don't need to provide all four. Provide what your callers will actually use. In particular, if the exception is _always_ created from a lower-level failure, don't offer a constructor that allows omitting the cause.

### An exception that carries data

```java
public class InsufficientFundsException extends Exception {   // checked
    private static final long serialVersionUID = 1L;

    private final String accountId;
    private final long balanceCents;
    private final long requestedCents;

    public InsufficientFundsException(String accountId, long balanceCents, long requestedCents) {
        super("Account %s has %d cents but %d were requested"
                .formatted(accountId, balanceCents, requestedCents));
        this.accountId = accountId;
        this.balanceCents = balanceCents;
        this.requestedCents = requestedCents;
    }

    public long shortfallCents() { return requestedCents - balanceCents; }
    public String accountId()    { return accountId; }
}
```

The caller can now _act_ on the failure:

```java
try {
    account.withdraw(500);
} catch (InsufficientFundsException e) {
    ui.showMessage("You're short by " + e.shortfallCents() + " cents.");
}
```

Note the design choices:

- **Fields are `final`.** An exception is a report of something that already happened, so it should be immutable.
- **The message is built from the fields**, so the data is both machine-readable (getters) and human-readable (the message in logs). Joshua Bloch calls this _failure capture_: the message should contain the values of every parameter that contributed to the failure.
- **The domain method (`shortfallCents`) lives on the exception**, which keeps handler code short.

## The "why" behind the design

### When to create one, and when not to

Create a custom exception when at least one of these holds:

1. **Callers need to catch it specifically**, distinguishing it from other failures and handling it differently.
2. **It carries structured data** that handlers need.
3. **It is a boundary abstraction**: it hides an implementation detail (like JDBC) behind your own vocabulary.

**Do not** create one when a JDK exception already says it correctly:

|Situation|Use|
|---|---|
|Bad argument value|`IllegalArgumentException`|
|Object is in the wrong state for this call|`IllegalStateException`|
|Null where null is forbidden|`NullPointerException` via `Objects.requireNonNull`|
|Index out of range|`IndexOutOfBoundsException`|
|Operation not supported|`UnsupportedOperationException`|
|Missing element|`NoSuchElementException`|
|I/O failure inside a lambda|`UncheckedIOException`|

The litmus test: **if the only difference between two failures is the message string, they should be the same class.** A new class is justified only if the _handling_ differs.

### Naming matters more than you'd think

The default `toString()` of a Throwable is `ClassName: message`, and that's what appears in logs and stack traces. So the class name is the first thing someone sees at 3 a.m. Use a name ending in `Exception` that states the problem (`InsufficientFundsException`, not `BankException` or `MyException`). The `Error` suffix is reserved for the JDK's `Error` subclasses.

### Hierarchies: catch narrowly or broadly, your choice

```java
public abstract class PaymentException extends Exception {
    protected PaymentException(String msg, Throwable cause) { super(msg, cause); }
}
public class CardDeclinedException extends PaymentException { /* ... */ }
public class GatewayUnavailableException extends PaymentException { /* ... */ }
```

Now callers have a choice:

```java
try { pay(order); }
catch (CardDeclinedException e)        { askForAnotherCard(); }   // specific handling
catch (GatewayUnavailableException e)  { retryLater(); }
catch (PaymentException e)             { logAndFail(e); }          // everything else payment-related
```

This is the same design the JDK uses (`IOException` with `FileNotFoundException`, `SocketTimeoutException`, and others below it) and that Spring uses (`DataAccessException`). It rests on the subtype relationship: a `catch` clause matches by `instanceof`-style subtyping, and the **most specific handlers must come first**, or the compiler rejects the code as unreachable.

A common structure is **one base exception per module or library**, so a caller can write a single catch for "anything from this library."

### Exception translation at layer boundaries

This is the most important real-world use:

```java
public User findUser(long id) {
    try {
        return jdbc.queryForUser(id);
    } catch (SQLException e) {
        throw new UserLookupException("could not load user " + id, e);  // cause preserved
    }
}
```

The service layer now has no dependency on JDBC. If you swap the database for a REST call, only the translation point changes. Always pass the original as the **cause**; dropping it destroys the root-cause information, and the stack trace's "Caused by:" chain is how you debug these.

### Error codes versus many classes

An alternative to dozens of subclasses is one exception with an enum:

```java
public class ApiException extends RuntimeException {
    public enum Code { NOT_FOUND, CONFLICT, RATE_LIMITED }
    private final Code code;
    // ...
}
```

Subclasses let the _compiler and `catch`_ do the routing, and give you type-safe data per error. An enum is lighter and maps neatly to something like HTTP status codes, but handlers must write `switch`/`if` on the code, and nothing checks that they cover every case. Use classes when handling differs structurally; use a code when the variants are mostly about reporting.

## Edge cases and gotchas

### 1. `serialVersionUID`

`Throwable implements Serializable`, so every custom exception is serializable too. The compiler (with `-Xlint:serial`) and IDEs warn if you omit `serialVersionUID`. Without it, the JVM computes one from the class's structure, so an unrelated change to the class can make previously serialized exceptions fail to deserialize. This matters when exceptions cross a process boundary (RMI, some messaging systems, distributed frameworks, session storage).

### 2. Non-serializable fields break serialization

```java
class BadException extends RuntimeException {
    private final Connection conn;   // not Serializable!
}
```

If this exception is ever serialized, you'll get `NotSerializableException`. Store simple data (IDs, strings, numbers), or mark the field `transient`. This also avoids the **memory-retention** problem: an exception that holds a reference to a big object keeps it alive for as long as the exception is reachable, which can be a long time if it sits in a queue, a log buffer, or a future.

### 3. `initCause` can only be called once, and sometimes never

```java
Exception e = new Exception("outer");          // cause is "uninitialized"
e.initCause(inner);                             // OK, once

Exception e2 = new Exception("outer", null);   // cause explicitly set to null
e2.initCause(inner);                            // IllegalStateException: Can't overwrite cause
```

Internally, `Throwable` uses `cause == this` as the "not yet set" marker. Passing a cause to the constructor, _even `null`_, marks it as set. `initCause` exists for old exception classes created before the cause parameter existed. In your own classes, pass the cause via the constructor.

### 4. A custom exception cannot be generic

```java
class MyEx<T> extends Exception { }   // COMPILE ERROR: a generic class may not extend Throwable
```

The reason is **type erasure**. `catch (MyEx<String> e)` and `catch (MyEx<Integer> e)` would both erase to `catch (MyEx e)`, and the JVM's exception table matches on the _runtime class_, which has no type-argument information. The language forbids it rather than allow catch clauses that can't work. (By contrast, a generic _throws_ clause, `<E extends Exception> void f() throws E`, is fine, which is what the `ThrowingFunction` trick from the previous topic uses.)

### 5. Records can't be exceptions

A `record` implicitly extends `java.lang.Record` and can't declare an `extends` clause, so it cannot extend `Exception`. If you want boilerplate-free data, use a normal class with `final` fields, as above.

### 6. Stack trace capture is the expensive part

The `Throwable` constructor calls `fillInStackTrace()`, which walks the stack. For exceptions used as rare error signals, that's a good trade. For exceptions thrown at very high frequency (some parsers and control-flow signals), you can opt out:

```java
public class FastSignalException extends RuntimeException {
    public FastSignalException(String msg) {
        super(msg, null, false, false);   // enableSuppression=false, writableStackTrace=false
    }
}
```

Use this sparingly. It makes debugging much harder, and using exceptions for control flow is usually a design smell in the first place.

### 7. Messages end up in logs and sometimes in responses

Don't put passwords, tokens, or full personal data in exception messages. They get logged, shipped to monitoring systems, and occasionally shown to end users by a sloppy error handler.

### 8. Log once, where you handle it

```java
catch (SQLException e) {
    log.error("failed", e);    // logged here...
    throw new ServiceException("failed", e);   // ...and again by whoever catches this
}
```

Log-and-rethrow produces duplicate entries of the same failure at every layer. Either **handle** the exception (and log it there) or **wrap and throw** it (and let the eventual handler log it). When you do log, pass the exception object itself (`log.error("failed for {}", id, e)`) so the full trace and cause chain are printed.

### 9. Stay away from these anti-patterns

- A custom exception per message string
- `catch (Exception e) { throw new MyException(e.getMessage()); }`, which loses the cause and the stack trace
- Exceptions used for ordinary control flow (looping until one is thrown)
- `public class MyException extends Exception {}` with no data and no purpose beyond the JDK's equivalent

## Putting it together: a well-formed example

```java
public class OrderValidationException extends RuntimeException {
    private static final long serialVersionUID = 1L;

    private final String orderId;
    private final List<String> violations;   // List.copyOf makes it immutable

    public OrderValidationException(String orderId, List<String> violations) {
        super("Order %s failed validation: %s".formatted(orderId, violations));
        this.orderId = orderId;
        this.violations = List.copyOf(violations);
    }

    public String orderId()           { return orderId; }
    public List<String> violations()  { return violations; }
}
```

It is unchecked (caller bug or bad input, not an external contingency), immutable, carries structured data the UI can display, serializable by virtue of simple field types, and has a message that includes everything needed to diagnose the problem from logs alone.

## How it connects

- **Checked vs. unchecked:** the base class you choose is exactly that decision, so the guidance from the previous topic applies directly.
- **Inheritance and polymorphism:** hierarchies work because `catch` is subtype matching, and the overriding rules constrain which checked exceptions subclass methods may declare.
- **Generics and erasure:** explain why exceptions can't be generic.
- **Serialization:** explains `serialVersionUID` and the field-type constraints.
- **Layered architecture:** exception translation keeps layers decoupled.
- **Testing:** with JUnit, `assertThrows(InsufficientFundsException.class, () -> ...)` returns the exception so you can assert on its fields, which is another benefit of structured data over message strings.



[[Exception]]
[[Java]]