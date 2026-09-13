# Creating Custom Exceptions — Complete Guide

## Step 1: Decide checked or unchecked

This is the first and most important decision, and it comes straight from the checked/unchecked distinction we covered.

```java
class InsufficientFundsException extends Exception       // CHECKED — extends Exception
class InvalidAccountException extends RuntimeException   // UNCHECKED — extends RuntimeException
```

**Ask:** _"Is this a condition the caller can reasonably expect and should be forced to handle — or is it a bug that should just fail loudly?"_

|Choose|When|
|---|---|
|`extends Exception` (checked)|The failure is an expected, recoverable business condition — insufficient funds, file not found, invalid user input from an external source. The caller _should_ be forced to think about it.|
|`extends RuntimeException` (unchecked)|The failure represents a programming error or a violated precondition — a null argument that should never be null, an invalid internal state. You want it to fail fast without cluttering every caller with `try/catch`.|

---

## Step 2: The minimal version

```java
class InsufficientFundsException extends Exception {
    public InsufficientFundsException(String message) {
        super(message); // passes the message up to Throwable, so getMessage() works
    }
}
```

That's a fully valid custom exception. `super(message)` stores the message in the parent `Throwable` class, which is what `.getMessage()` retrieves later.

**Usage:**

```java
class Account {
    private double balance;

    void withdraw(double amount) throws InsufficientFundsException {
        if (amount > balance) {
            throw new InsufficientFundsException(
                "Cannot withdraw " + amount + ", balance is only " + balance
            );
        }
        balance -= amount;
    }
}

try {
    account.withdraw(500);
} catch (InsufficientFundsException e) {
    System.out.println("Transaction failed: " + e.getMessage());
}
```

---

## Step 3: The complete, production-quality version

A well-built custom exception usually provides **multiple constructors**, matching the pattern every JDK exception follows:

```java
class InsufficientFundsException extends Exception {

    public InsufficientFundsException() {
        super();
    }

    public InsufficientFundsException(String message) {
        super(message);
    }

    public InsufficientFundsException(String message, Throwable cause) {
        super(message, cause); // preserves the ORIGINAL exception that triggered this one
    }

    public InsufficientFundsException(Throwable cause) {
        super(cause);
    }
}
```

### Why the `(String message, Throwable cause)` constructor matters

This is the one people skip, and it's the most important one in real systems. It enables **exception chaining** — wrapping a lower-level exception in a more meaningful, higher-level one, without losing the original error information:

```java
void processPayment(Account account, double amount) throws InsufficientFundsException {
    try {
        callExternalBankApi(account, amount);
    } catch (BankApiException e) {
        // wrap the low-level cause in a domain-specific exception
        throw new InsufficientFundsException("Payment failed for account " + account.getId(), e);
    }
}
```

When this is eventually printed or logged, Java shows **both** the new exception _and_ the original cause's full stack trace (`Caused by: ...`), so you never lose the real root cause just because you translated it into a more meaningful type.

---

## Step 4: Adding custom fields (going beyond just a message)

A plain message is often not enough — you may want structured data attached to the exception so calling code can react programmatically, not just log text.

```java
class InsufficientFundsException extends Exception {
    private final double requestedAmount;
    private final double availableBalance;

    public InsufficientFundsException(double requestedAmount, double availableBalance) {
        super(String.format("Cannot withdraw %.2f, only %.2f available",
                requestedAmount, availableBalance));
        this.requestedAmount = requestedAmount;
        this.availableBalance = availableBalance;
    }

    public double getRequestedAmount() { return requestedAmount; }
    public double getAvailableBalance() { return availableBalance; }
}
```

**Usage — now the caller can react to the actual numbers, not just parse a string:**

```java
try {
    account.withdraw(500);
} catch (InsufficientFundsException e) {
    double shortfall = e.getRequestedAmount() - e.getAvailableBalance();
    System.out.println("You're short by: " + shortfall);
}
```

---

## Step 5: Building an exception hierarchy for a whole domain

In real applications, you usually don't create one isolated exception — you build a small family, rooted in one base type, so callers can catch broadly or narrowly as needed.

```java
// Base type for all banking-related failures
abstract class BankingException extends Exception {
    protected BankingException(String message) { super(message); }
    protected BankingException(String message, Throwable cause) { super(message, cause); }
}

class InsufficientFundsException extends BankingException {
    public InsufficientFundsException(String message) { super(message); }
}

class AccountFrozenException extends BankingException {
    public AccountFrozenException(String message) { super(message); }
}
```

```java
try {
    account.withdraw(500);
} catch (InsufficientFundsException e) {
    // handle this specific case
} catch (AccountFrozenException e) {
    // handle this specific case
} catch (BankingException e) {
    // catch-all for any OTHER banking failure not specifically handled above
}
```

This mirrors exactly how the JDK itself is structured (`IOException` as a base, with `FileNotFoundException` etc. underneath) — it's the standard pattern, not something unique to custom exceptions.

---

## Common mistakes

### 1. Forgetting `super(message)` — losing the message entirely

```java
class BadException extends Exception {
    public BadException(String message) {
        // forgot super(message)!
    }
}

try {
    throw new BadException("Something broke");
} catch (BadException e) {
    System.out.println(e.getMessage()); // prints: null
}
```

**Fix:** always call `super(message)` (or one of `Throwable`'s other constructors) — otherwise the message you passed in is silently discarded.

### 2. Swallowing the original cause when wrapping

```java
try {
    riskyDatabaseCall();
} catch (SQLException e) {
    throw new DataAccessException("Query failed"); // original SQLException is LOST
}
```

Now the stack trace shows only `DataAccessException` — the real underlying SQL error (what query, what line) is gone, making debugging much harder.

**Fix:**

```java
} catch (SQLException e) {
    throw new DataAccessException("Query failed", e); // chain it — cause preserved
}
```

### 3. Making everything unchecked "to avoid the hassle"

```java
class InsufficientFundsException extends RuntimeException { ... } // tempting, but...
```

This compiles fine and callers _aren't forced_ to handle it — which sounds convenient, but for something as clearly expected and recoverable as "insufficient funds," this means the compiler no longer helps anyone remember to handle it. It becomes easy for a caller to simply forget, and the failure only surfaces at runtime, in production, instead of at compile time.

**Fix:** reserve unchecked for genuine bugs/preconditions; use checked when _you specifically want the compiler's help_ enforcing that callers think about the failure.

### 4. Overly generic custom exceptions

```java
class MyException extends Exception { ... } // used for EVERYTHING in the app
```

If one exception type covers "file not found," "invalid input," and "network timeout," callers can't distinguish between them without parsing the message string — which defeats the entire purpose of typed exceptions.

**Fix:** one exception type per distinct failure _category_ your callers might want to react to differently.

### 5. Catching your own custom exception too early and discarding it

```java
void withdraw(double amount) {
    try {
        if (amount > balance) throw new InsufficientFundsException("...");
    } catch (InsufficientFundsException e) {
        // swallowed silently — caller of withdraw() never knows it failed
    }
}
```

**Fix:** if a method isn't equipped to meaningfully _handle_ the exception (retry, fall back, show a real message), let it propagate — don't catch-and-ignore just to silence the compiler.

---

## Quick checklist

- [ ] Checked (`Exception`) or unchecked (`RuntimeException`) — chosen deliberately, not by default
- [ ] `super(message)` called in every constructor
- [ ] A `(String message, Throwable cause)` constructor included, for exception chaining
- [ ] Custom fields added if callers need structured data, not just a message string
- [ ] Named specifically for the failure it represents (`InsufficientFundsException`, not `MyException`)
- [ ] Grouped under a shared base type if it's part of a larger family of domain-specific failures
- [ ] Never caught-and-swallowed unless you're genuinely handling it there

## Where this fits into Spring Boot

Spring Boot has a dedicated pattern for this: you'll typically pair custom exceptions with `@ControllerAdvice` and `@ExceptionHandler` to convert them into proper HTTP error responses (e.g., an `InsufficientFundsException` → HTTP 400 with a JSON error body) instead of manually catching them in every controller method. That's a natural next topic once you're ready for it.

[[Java]]