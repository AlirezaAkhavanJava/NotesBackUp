
## What Is an Interface?

An **interface** is a shared boundary or contract that defines *how* two things communicate, without specifying *how* either side works internally. It specifies what inputs are accepted, what outputs are produced, and what behavior is guaranteed — nothing more. Think of it as a plug socket: the socket defines the shape and voltage (the contract), but it doesn't care whether the device plugged in is a lamp, a charger, or a toaster. In programming, interfaces let you swap implementations freely, decouple modules, and write code that depends on *capabilities* rather than *concrete types*. The core idea is **"program to an interface, not an implementation"** — you commit to a promise, not a mechanism.

---

## Table of Types of Interfaces

| # | Type | Domain | What It Defines |
|---|------|--------|-----------------|
| 1 | **Language-level interface** | OOP (Java, C#, TypeScript) | Method signatures a class must implement |
| 2 | **Abstract class / protocol** | OOP, Python, Swift | Partial implementation + required methods |
| 3 | **Functional interface** | Java, C#, functional langs | A single abstract method (SAM) for lambdas |
| 4 | **API (Application Programming Interface)** | Systems, web, libraries | Network/function contract for external consumers |
| 5 | **Hardware interface** | Electronics, drivers | Electrical/mechanical signaling spec (USB, I2C) |
| 6 | **User Interface (UI)** | Product design | How humans interact with a system |
| 7 | **Duck-typed / structural interface** | Python, Go, Ruby | Any object with the right methods qualifies |
| 8 | **Marker interface** | Java, C# | Empty interface used as a tag/flag |

---

## Detailed Explanation of Each Type

### 1. Language-Level Interface
**Simple terms:** A written list of method names that any class signing up must provide.

```java
interface PaymentProcessor {
    void charge(double amount);
    boolean refund(String transactionId);
}
```

**What a great programmer knows:**
- Interfaces contain **no state** (in most languages) — only behavior.
- A class can implement **many** interfaces, but extend only one class. This is how you get "multiple inheritance of type."
- Keep interfaces **small and focused** (Interface Segregation Principle). A 20-method interface is a design smell.

**Key rules:**
- All methods are implicitly `public` and `abstract` (unless default/static in Java 8+).
- You cannot instantiate an interface directly.
- Name interfaces after **capabilities**: `Comparable`, `Serializable`, `Runnable` — not `UserManagerImpl`.

**Tip:** If you find yourself adding a method to an interface used everywhere, you'll break every implementer. Prefer adding a *new* interface or use default methods.

---

### 2. Abstract Class / Protocol
**Simple terms:** A half-built blueprint — some methods are done, some you must fill in.

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self): ...

    def describe(self):          # shared implementation
        return f"Area is {self.area()}"
```

**What a great programmer knows:**
- Use an abstract class when implementations **share code**; use an interface when they only share a **contract**.
- Swift and Objective-C call these **protocols**; Python calls them **ABCs**.
- Prefer interfaces for flexibility, abstract classes for code reuse.

**Key rules:**
- A subclass **must** implement all abstract methods, or it too becomes abstract.
- Abstract classes **can** have constructors and fields.

**Tip:** The "fragile base class" problem is real — changes to a base class ripple to all children. Favor composition over inheritance when in doubt.

---

### 3. Functional Interface
**Simple terms:** An interface with exactly **one** method, so it can be written as a lambda.

```java
@FunctionalInterface
interface Validator {
    boolean isValid(String input);
}

Validator v = s -> s.length() > 3;   // lambda!
```

**What a great programmer knows:**
- This is the bridge between OOP and functional programming.
- Java's `Runnable`, `Callable`, `Comparator`, and all of `java.util.function` are functional interfaces.
- The `@FunctionalInterface` annotation is optional but **catches mistakes** at compile time.

**Key rules:**
- Exactly one abstract method. Default/static methods don't count.
- A lambda is just a compact implementation of that one method.

**Tip:** When passing behavior as a parameter, reach for a functional interface instead of an anonymous class — it's cleaner and intent-revealing.

---

### 4. API (Application Programming Interface)
**Simple terms:** The menu a service offers — you order by name, send the right ingredients, and get a result.

**What a great programmer knows:**
- APIs are **contracts with strangers**. Once published, breaking changes are expensive.
- Version your API (`/v1/`, `/v2/`) so you can evolve without breaking clients.
- Design APIs around **resources and intent**, not internal database tables.

**Key rules:**
- Be consistent: naming, error formats, pagination, auth.
- Return meaningful HTTP/status codes and structured errors.
- Document **idempotency** — which calls are safe to retry.
- Never expose internal implementation details (leaky abstractions).

**Tip:** Treat your own internal APIs with the same care as public ones. The best time to fix a bad API is *before* anyone depends on it.

---

### 5. Hardware Interface
**Simple terms:** The agreed voltage, pins, and timing that let two chips talk.

**What a great programmer knows:**
- As a software dev you'll meet these as **drivers** and **HALs** (Hardware Abstraction Layers).
- Protocols: USB, I2C, SPI, UART, PCIe, GPIO.
- Abstraction layers exist so application code never touches registers directly.

**Key rules:**
- Timing and voltage are part of the contract — violate them and nothing works.
- Always code against the HAL, not the specific chip, so you can port easily.

**Tip:** When writing firmware, define your own thin interface over each peripheral. It makes unit testing possible without real hardware.

---

### 6. User Interface (UI)
**Simple terms:** Everything a human sees, clicks, taps, or reads.

**What a great programmer knows:**
- A UI is an interface between **humans and logic** — the same design principles apply: clear contract, predictable behavior, graceful errors.
- Separate **presentation** from **business logic** (MVC, MVVM) so the UI can change without rewriting core rules.
- Accessibility is not optional — it's part of a good interface contract.

**Key rules:**
- Consistent feedback for every action (loading, success, error).
- Don't make users guess; make the "contract" obvious.
- Test with real users, not just your own assumptions.

**Tip:** If your UI needs a manual, your interface has failed. Good interfaces are self-explanatory.

---

### 7. Duck-Typed / Structural Interface
**Simple terms:** "If it walks like a duck and quacks like a duck, it's a duck." No formal declaration needed — just have the right methods.

```python
def save(obj):
    obj.write()      # works for ANY object with .write()
```

**What a great programmer knows:**
- Python, Ruby, and JavaScript use duck typing; Go uses **structural interfaces** (implicit satisfaction).
- More flexible, but errors surface at **runtime** instead of compile time.
- Tools like `mypy`, `Protocol` (Python), and TypeScript bring back static checks.

**Key rules:**
- Document the "shape" you expect (what methods/properties).
- Prefer explicit protocols in large codebases to catch mistakes early.

**Tip:** Duck typing shines in small scripts and glue code; it bites in large teams. Add type hints when a project grows.

---

### 8. Marker Interface
**Simple terms:** An empty interface used as a **label** or tag.

```java
public interface Serializable {}   // no methods, just a flag
```

**What a great programmer knows:**
- They signal intent to the runtime or framework (e.g., "this can be serialized").
- Modern practice prefers **annotations** (`@Serializable`) over empty interfaces because annotations are more expressive.

**Key rules:**
- No methods, no behavior — pure metadata.
- Use sparingly; overusing them clutters the type system.

**Tip:** If you're about to create a marker interface, ask whether an annotation or an attribute would be clearer.

---

## Universal Rules Every Great Programmer Should Internalize

1. **Program to interfaces, not implementations.** Depend on abstractions so you can swap parts.
2. **Keep interfaces small.** One responsibility each (ISP). `Reader`, `Writer` beat `IOHandler`.
3. **An interface is a promise.** Changing it breaks everyone who trusted it — version or extend instead.
4. **Document the contract.** Preconditions, postconditions, side effects, error behavior.
5. **Don't leak abstractions.** Callers shouldn't need to know what's underneath.
6. **Name for what it does, not how.** `Notifier`, not `EmailSenderImpl`.
7. **Composition beats inheritance.** Interfaces + delegation scale better than deep class trees.
8. **Make illegal states unrepresentable.** A good interface prevents misuse by design.

**The one-sentence summary:** An interface is a *contract of behavior* — design it carefully, keep it narrow, document it honestly, and your entire system becomes easier to change, test, and understand.

[[Java]]