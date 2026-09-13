
## Sealed Classes and Sealed Interfaces

A **sealed class** is a class that **restricts which other classes may extend it** — you explicitly list the permitted subclasses, and no one else can inherit from it. A **sealed interface** does the same for interfaces: only the named classes/records/interfaces may implement it. Both were introduced to give you a middle ground between "open to everyone" (regular class/interface) and "closed to everyone" (`final`). They let you model **closed hierarchies** — a fixed, known set of subtypes — which unlocks exhaustive pattern matching and safer APIs.

The core keyword is **`sealed`**, paired with **`permits`** (Java 17+) or a similar mechanism in Kotlin, C#, and Scala. The compiler enforces the boundary.

---

## Table of Sealed Types Across Languages

| Language | Sealed Class Syntax | Sealed Interface | Notes |
|----------|--------------------|------------------|-------|
| **Java 17+** | `sealed class Shape permits Circle, Square` | `sealed interface Shape permits Circle, Square` | Permitted types must be `final`, `sealed`, or `non-sealed` |
| **Kotlin** | `sealed class Shape` | `sealed interface Shape` | Subtypes must be in the same package/module |
| **Scala 3** | `sealed class Shape` | `sealed trait Shape` | Same file required for direct subtypes |
| **C# 11+** | No direct equivalent; use `abstract` + internal constructors | — | C# uses `abstract`/`internal` tricks instead |

---

## How Sealed Classes Work

```java
public sealed class Shape permits Circle, Square, Triangle {
    // common state/behavior
}

final class Circle extends Shape { }
final class Square extends Shape { }
final class Triangle extends Shape { }
```

**What this guarantees:**
- **Only** `Circle`, `Square`, and `Triangle` can extend `Shape`. Nobody else — not even in another module.
- The compiler knows the **complete list** of subtypes at compile time.

**The three permitted-subclass modifiers:**
- `final` — ends the chain (no further subclassing).
- `sealed` — continues the restriction (must declare its own `permits`).
- `non-sealed` — reopens the class to anyone.

---

## How Sealed Interfaces Work

```java
public sealed interface PaymentMethod
    permits CreditCard, PayPal, Crypto, BankTransfer { }

record CreditCard(String number) implements PaymentMethod { }
record PayPal(String email) implements PaymentMethod { }
record Crypto(String wallet) implements PaymentMethod { }
record BankTransfer(String iban) implements PaymentMethod { }
```

Sealed interfaces are often **more useful than sealed classes** because:
- A class can implement **multiple** interfaces, so you can seal just one dimension of behavior.
- Records implement them beautifully, giving you compact, immutable data variants.
- They pair perfectly with **algebraic data types** (sum types).

---

## Why They Exist — The Big Win: Exhaustive Pattern Matching

Before sealed types, the compiler could never know if you'd handled every case:

```java
// OLD — compiler forces a default, you might miss a case
if (shape instanceof Circle) { ... }
else if (shape instanceof Square) { ... }
else { /* what else? no idea */ }
```

With sealed types, the compiler knows the full set, so **switch expressions can be exhaustive** — no default needed, and adding a new subtype becomes a **compile error** everywhere you forgot to handle it:

```java
double area = switch (shape) {
    case Circle c    -> Math.PI * c.radius() * c.radius();
    case Square s    -> s.side() * s.side();
    case Triangle t  -> 0.5 * t.base() * t.height();
    // no default needed — compiler verified all cases
};
```

**This is the killer feature.** Add a `Pentagon` subtype tomorrow, and every `switch` in your codebase fails to compile until you handle it. The compiler becomes your checklist.

---

## Sealed Class vs. Sealed Interface — When to Use Which

| Situation | Use |
|-----------|-----|
| Subtypes share **state/fields** (common constructor) | Sealed **class** |
| Subtypes are unrelated but share a **capability** | Sealed **interface** |
| Modeling a fixed set of **data variants** (sum type) | Sealed **interface** + records |
| You need single inheritance but want to close the hierarchy | Sealed **class** |
| A type needs to be part of **multiple** sealed hierarchies | Sealed **interface** |

**Rule of thumb:** Sealed interface is more flexible and composes better. Use a sealed class only when the subtypes genuinely share implementation or state.

---

## Key Rules

1. **Direct subtypes must be listed** in the `permits` clause (Java) or be in the same file/module (Kotlin/Scala).
2. **Every permitted subtype must declare a modifier:** `final`, `sealed`, or `non-sealed` (Java).
3. **The `permits` clause can be omitted** in Java if all subtypes are in the same file — the compiler infers them.
4. **Sealed types can be abstract** — in fact, they usually are, since you rarely instantiate them directly.
5. **Sealed hierarchies are closed but not frozen** — you can add subtypes, but only by editing the sealed declaration itself.
6. **Reflection and runtime checks still work** — sealing is a compile-time guarantee.
7. **Sealed types work with records, enums, and normal classes** as subtypes.

---

## What a Great Programmer Knows

- **Sealed = a sum type.** It's the OOP way of saying "this value is exactly one of these N things" — the same idea as Rust's `enum`, Haskell's `data`, or TypeScript's discriminated unions.
- **Prefer sealed over `enum` when variants carry different data.** An enum is a sealed set of *singletons*; a sealed interface is a sealed set of *shapes*.
- **Use sealed to make invalid states unrepresentable.** Instead of `Order` with nullable `shippedDate`, `cancelReason`, etc., model `Pending | Shipped | Cancelled` as sealed variants.
- **Sealed + records + pattern matching = algebraic data types.** This trio is the single biggest modernization in Java in a decade.
- **Don't seal unnecessarily.** Sealing is a *commitment* that the set is fixed. If third parties must extend your type, keep it open or use `non-sealed`.
- **Sealing is about control, not secrecy.** It's a design tool for domain modeling, not an access-control mechanism.
- **Watch for module boundaries.** In Java, permitted subtypes must be in the same module (or same package for unnamed modules). Plan your packages accordingly.

**The one-sentence summary:** A sealed class or interface is a **closed contract** — you decide exactly who may implement or extend it, which lets the compiler reason about your entire type hierarchy, enables exhaustive pattern matching, and turns "I forgot a case" from a runtime bug into a compile-time error.


[[Java]]
[[API]]