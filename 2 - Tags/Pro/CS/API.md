
An **API** (Application Programming Interface) is a defined contract that lets one piece of software use the features or data of another, without knowing how it works inside.

**Analogy:** A wall socket. You don't need to understand the power plant; you just plug in following the standard shape. The socket is the interface, and the rules (voltage, plug shape) are the contract.

**Core idea:** an API exposes a set of allowed operations, what you send in, and what you get back. Everything else stays hidden. This is called _abstraction_, and it lets both sides change internally without breaking each other, as long as the contract stays the same.

**Where you meet APIs:**

- **Library API:** the methods you call in Java, like `List.add()` or `Math.max()`. The "contract" is the method signature and its documented behavior.
- **Web API:** a program calling another over a network, usually HTTP. A REST API is the most common style of this.
- **OS API:** how programs ask the operating system to open files or use the network.

**Tiny Java example (an API as an interface):**

```java
public interface PaymentService {
    boolean pay(double amount);
}

public class PayPalService implements PaymentService {
    public boolean pay(double amount) {
        // internal details hidden from the caller
        return true;
    }
}
```

Code that uses `PaymentService` only knows `pay(...)` exists. You can swap `PayPalService` for another implementation and the caller never changes. This idea is exactly what Spring's dependency injection builds on.

**Relationship to what you just learned:** API is the broad concept, REST is one style of designing web APIs, and Spring Boot is a tool for building them, with Maven managing the dependencies.

**Gotchas:**

- "API" does not always mean web or HTTP; a Java interface or library is an API too.
- Changing a public API (renaming a method, removing a field) can break everyone who depends on it, which is why APIs are often **versioned** (`/v1/books`).


[[Rest-API]]
[[Java]]