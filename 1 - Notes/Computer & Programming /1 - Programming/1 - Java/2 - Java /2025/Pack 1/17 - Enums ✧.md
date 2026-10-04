

## The mental model

An enum is a class whose instances are **fixed in advance**. Think of a club with a closed guest list: nobody new can ever be created, and everyone on the list is known at compile time.

```java
enum Day { MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY }
```

Each name is a `public static final` object of type `Day`, created once when the class loads. Because the list is closed, the compiler can check you against it. A method taking `Day` can never receive "FUNDAY", whereas a `String` or `int` parameter would accept anything.

## Using enums

Since each constant is a single shared object, compare with `==`. It is null-safe and type-checked.

```java
Day today = Day.MONDAY;
if (today == Day.MONDAY) System.out.println("Work week starts");

for (Day d : Day.values()) System.out.println(d);   // all constants, in declaration order
```

## Built-in methods

```java
Day.MONDAY.name();       // "MONDAY"
Day.MONDAY.ordinal();    // 0  (position in the declaration)
Day.valueOf("FRIDAY");   // Day.FRIDAY
```

Two gotchas:

- `valueOf` is **case-sensitive** and throws `IllegalArgumentException` for unknown names. When parsing user input, normalize it (`.toUpperCase()`) and catch the exception.
- Don't use `ordinal()` for logic or storage. Reordering or inserting a constant silently changes every number. Store an explicit field instead (next section).

## Fields, constructors, methods

Since an enum is a class, each constant can carry data. The values in parentheses are passed to the constructor.

```java
enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    EARTH  (5.976e+24, 6.3781e6),
    MARS   (6.421e+23, 3.3895e6);

    private final double mass;    // kg
    private final double radius;  // m

    Planet(double mass, double radius) {   // implicitly private
        this.mass = mass;
        this.radius = radius;
    }

    double surfaceGravity() {
        return 6.673e-11 * mass / (radius * radius);
    }
}

Planet.MARS.surfaceGravity();   // ≈ 3.73
```

Rules to remember:

- The constructor is always private. You can't write `new Planet(...)`, and that is what keeps the list closed.
- Constants come first, ended with `;`, then fields and methods.
- Make fields `final`. Mutable enum state is shared globally, which is a bug waiting to happen.

A common real-world use is replacing `ordinal()` with a stable ID:

```java
enum HttpStatus {
    OK(200), NOT_FOUND(404), SERVER_ERROR(500);

    private final int code;
    HttpStatus(int code) {
	     this.code = code; 
	}
	
    int code() {
	     return code; 
	}
	
    boolean isSuccess() {
	     return code >= 200 && code < 300; 
	}
}
```

## Different behavior per constant

Sometimes constants differ in what they do, not just in their data. There are two ways.

**1. Abstract method.** Every constant must implement it, and the compiler enforces that:

```java
enum Operation {
    PLUS   { double apply(double x, double y) { return x + y; } },
    MINUS  { double apply(double x, double y) { return x - y; } },
    TIMES  { double apply(double x, double y) { return x * y; } };

    abstract double apply(double x, double y);
}

Operation.PLUS.apply(2, 3);   // 5.0
```

This replaces a chain of `if/else` over the type with polymorphism. Adding a new constant forces you to define its behavior.

**2. Default behavior with overrides.** Write a normal method, and override it only where needed:

```java
enum PayrollDay {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY,
    SATURDAY { double pay(double hours, double rate) { return hours * rate * 1.5; } },
    SUNDAY   { double pay(double hours, double rate) { return hours * rate * 2.0; } };

    double pay(double hours, double rate) { return hours * rate; }   // default
}
```

Each `{ ... }` body creates an anonymous subclass of the enum for that one constant.

## Interfaces

Enums can't extend another class, because they already extend `java.lang.Enum`. They can implement any number of interfaces, which lets different enums be used interchangeably:

```java
interface Describable { String description(); }

enum Color implements Describable {
    RED("#FF0000", "Passion"), GREEN("#00FF00", "Growth");

    private final String hex, desc;
    Color(String hex, String desc) { this.hex = hex; this.desc = desc; }

    public String description() { return desc; }
}
```

## EnumSet and EnumMap

Normal `HashSet` and `HashMap` work with enums, but there are specialized versions. Internally, `EnumSet` is a bit mask (one bit per constant), and `EnumMap` is a plain array indexed by ordinal. They are faster and keep entries in declaration order.

```java
EnumSet<Day> weekend = EnumSet.of(Day.SATURDAY, Day.SUNDAY);
EnumSet<Day> weekdays = EnumSet.complementOf(weekend);

EnumMap<Day, String> plan = new EnumMap<>(Day.class);
plan.put(Day.MONDAY, "Gym");
```

This is the one legitimate use of `ordinal()`. It's hidden inside the library, so you never depend on it.

## Switch expressions

When you switch over an enum with the arrow form and use the result as a value, the compiler requires **every constant to be covered**. If you later add a constant, every such switch fails to compile until you handle it.

```java
String type = switch (today) {
    case SATURDAY, SUNDAY -> "Weekend";
    case MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY -> "Weekday";
};   // no default needed; the compiler checks exhaustiveness
```

Avoid `default` here if you can. It silences that safety check.

## Enums and sealed types (Java 17+)

An enum is good when every case is a fixed constant and carries no per-instance data. If some cases need data, combine an enum with a record under a sealed interface:

```java
sealed interface Command permits SimpleCommand, Move {}

enum SimpleCommand implements Command { QUIT, HELP }
record Move(int dx, int dy) implements Command {}

String describe(Command c) {
    return switch (c) {
        case SimpleCommand.QUIT -> "Quitting";
        case SimpleCommand.HELP -> "Showing help";
        case Move m             -> "Moving by " + m.dx() + "," + m.dy();
    };   // exhaustive: the compiler knows every possibility
}
```

## Rules of thumb

- Use an enum for any fixed set of known values (statuses, roles, types). Never use `int` or `String` constants for this.
- Don't rely on `ordinal()` for logic or storage. Store an explicit field.
- Don't rely on `name()` as a stable stored value either, since renaming the constant breaks old data. Use an explicit code field for databases and APIs.
- Prefer `EnumSet` and `EnumMap` over `HashSet` and `HashMap` when the keys are enums.
- Enums are singletons per constant, so they are safe to compare with `==` and safe to use across threads if their fields are `final`.



[[Java]]