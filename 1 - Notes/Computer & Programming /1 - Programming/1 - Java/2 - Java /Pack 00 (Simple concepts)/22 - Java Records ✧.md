

## The mental model

An enum is a class with a **fixed set of instances**. A record is the opposite: you can create as many instances as you like, but each one is just a **bundle of values**, with no identity beyond those values. Think of a shipping label or a map coordinate. Two labels with the same address are interchangeable, so the question "are these the same object?" doesn't matter, only "do they hold the same data?".

Before records, a class like this took about 40 lines of constructor, getters, `equals`, `hashCode`, and `toString`. Now:

```java
record Point(int x, int y) {}
```

The parenthesized list is the **record header**, and each entry is a _component_. From it the compiler generates:

- a `private final` field per component
- a **canonical constructor** taking all components in order
- an **accessor** per component, named after the component with no `get` prefix: `p.x()`, not `p.getX()`
- `equals`, `hashCode`, and `toString` based on all components

```java
Point a = new Point(3, 4);
Point b = new Point(3, 4);

a.x();            // 3
a.equals(b);      // true  (same values)
a == b;           // false (still two objects)
a;                // prints Point[x=3, y=4]
```

Records are implicitly `final` and extend `java.lang.Record`. That's why they can't extend another class, but they can implement interfaces.

## Validation: the compact constructor

The generated constructor accepts anything. To reject or clean up bad data, write a **compact constructor**: the same name as the record, with no parameter list. It runs _before_ the fields are assigned, and the assignment happens automatically at the end.

```java
record Person(String name, int age) {
    Person {
        if (age < 0) throw new IllegalArgumentException("age < 0");
        name = name.strip();          // normalize: reassigns the *parameter*
    }
}
```

Inside it you work with the **parameters**, not the fields. Writing `this.name = ...` is a compile error, because the compiler does the assignment for you. This is why reassigning the parameter (`name = name.strip()`) is how you normalize.

Because the validation lives in the canonical constructor, every instance, however it was created, passes through it. A record can't exist in an invalid state.

You can add extra constructors, but they must delegate to the canonical one:

```java
record Point(int x, int y) {
    Point() { this(0, 0); }           // origin
}
```

## The immutability gotcha

Record fields are `final`, but that only means the **reference** can't change. It's _shallow_ immutability:

```java
record Team(String name, List<String> members) {}

var list = new ArrayList<>(List.of("Ana"));
var t = new Team("A", list);
list.add("Bob");                      // the "immutable" record just changed
```

The fix is a defensive copy in the compact constructor:

```java
record Team(String name, List<String> members) {
    Team { members = List.copyOf(members); }   // unmodifiable snapshot
}
```

Arrays are worse: `equals` on an array component compares references, not contents. Prefer `List` in records.

## Adding behavior

A record can have methods, static members, and nested types. What it can't have is **extra instance fields**. All state must be in the header, which is what keeps the "this is just its components" guarantee true.

```java
record Rectangle(double width, double height) {
    static final Rectangle UNIT = new Rectangle(1, 1);   // static: allowed

    double area() { return width * height; }             // derived value: fine

    static Rectangle square(double side) {               // factory method
        return new Rectangle(side, side);
    }
}
```

You can also override an accessor (it must be `public` with the same return type), but do it rarely, since it breaks the expectation that `p.x()` returns exactly what you passed in.

Records can be generic (`record Pair<A, B>(A first, B second) {}`) and can be declared **locally** inside a method, which is handy for throwaway grouping:

```java
record Scored(String name, int score) {}
var best = names.stream().map(n -> new Scored(n, score(n))).max(...);
```

## Destructuring with record patterns (Java 21)

A record's shape is transparent, so you can take it apart directly in `instanceof` and `switch`, with no accessor calls:

```java
if (obj instanceof Point(int x, int y)) {
    System.out.println(x + "," + y);
}
```

Patterns can **nest**, which is where it gets powerful:

```java
record Line(Point from, Point to) {}

if (obj instanceof Line(Point(var x1, var y1), Point(var x2, var y2))) { ... }
```

Combined with the sealed-interface idea from enums, this gives exhaustive, data-driven code:

```java
sealed interface Shape permits Circle, Rect {}
record Circle(double r) implements Shape {}
record Rect(double w, double h) implements Shape {}

double area(Shape s) {
    return switch (s) {
        case Circle(double r)         -> Math.PI * r * r;
        case Rect(double w, double h) -> w * h;
    };   // exhaustive: add a new Shape and this stops compiling
}
```

**Rule of thumb:** an enum is for a closed set of _constants_, and a sealed interface with records is for a closed set of _shapes of data_. You can mix both under one sealed interface, as in the earlier `Command` example.

## Records in Spring Boot

This is where you'll use them most:

- **DTOs for requests and responses.** Jackson (Spring Boot 3) reads and writes records directly, so `record CreateUserRequest(String name, String email) {}` works as a `@RequestBody`. Bean Validation annotations go on the components: `record CreateUserRequest(@NotBlank String name, @Email String email) {}`.
- **Configuration.** `@ConfigurationProperties` can bind to a record, giving you immutable settings.
- **Map keys and set elements.** Value-based `equals`/`hashCode` is exactly what a key needs.
- **JPA entities cannot be records.** Hibernate needs a no-arg constructor and mutable fields. Records are fine for query projections and DTOs _from_ entities.

## Serialization

Records are **not** serializable automatically. They are `Serializable` only if they declare `implements Serializable`. Once they do, deserialization goes through the canonical constructor, so your validation runs on incoming data, which classes don't give you for free. JSON (Jackson) is separate and needs no `Serializable`.

## Rules of thumb

- Use a record whenever a class is purely "these fields, compared by value".
- Don't use one when you need mutability, inheritance, or hidden state.
- Validate and normalize in the compact constructor, and copy any mutable collection component.
- Don't put mutable objects (arrays, `ArrayList`, `Date`) in components.
- Let records carry data and put heavy logic elsewhere. Small derived methods like `area()` are fine.

[[Java]]