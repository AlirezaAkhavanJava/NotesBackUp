
# Java Record Class: Complete Guide



## Part 1: What is a Record Class?

### **Definition**

A **Record** is a special, concise way to declare an immutable data class. It's designed to be a data carrier that automatically generates:
- Final fields
- Constructor
- Getters (accessor methods)
- `equals()` method (value-based)
- `hashCode()` method
- `toString()` method

**Introduced:** Java 14 (preview) → Java 15 (preview) → Java 16 (standard/final feature)

### **The Problem Records Solve**

Before Records, declaring a simple data holder required massive boilerplate:

```java
// ❌ WITHOUT RECORDS - A LOT of boilerplate
public class Person {
    private final String name;
    private final int age;
    private final String email;
    
    public Person(String name, int age, String email) {
        this.name = name;
        this.age = age;
        this.email = email;
    }
    
    public String name() {
        return name;
    }
    
    public int age() {
        return age;
    }
    
    public String email() {
        return email;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Person person = (Person) o;
        return age == person.age &&
                Objects.equals(name, person.name) &&
                Objects.equals(email, person.email);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(name, age, email);
    }
    
    @Override
    public String toString() {
        return "Person{" +
                "name='" + name + '\'' +
                ", age=" + age +
                ", email='" + email + '\'' +
                '}';
    }
}

// ✅ WITH RECORDS - One line!
record Person(String name, int age, String email) {}
```

---

## Part 2: Basic Record Syntax & Usage

### **Simple Record Declaration**

```java
// Basic syntax
record Person(String name, int age) {}

// Usage
public class Main {
    public static void main(String[] args) {
        Person p = new Person("Alice", 30);
        
        // Accessor methods (NOT getters!)
        System.out.println(p.name());    // Alice
        System.out.println(p.age());     // 30
        
        // Auto-generated toString()
        System.out.println(p);           // Person[name=Alice, age=30]
        
        // Value-based equality
        Person p2 = new Person("Alice", 30);
        System.out.println(p.equals(p2));  // true (same values)
        
        // hashCode support
        Set<Person> people = new HashSet<>();
        people.add(p);
        people.add(p2);
        System.out.println(people.size());  // 1 (same person, same hash)
    }
}
```

### **Key Differences from Regular Classes**

```java
// Record components become:
record Point(int x, int y) {}

// 1. Private final fields
//    private final int x;
//    private final int y;

// 2. Public accessor methods (NOT getters!)
//    public int x() { return x; }
//    public int y() { return y; }

// 3. Canonical constructor (all parameters)
//    public Point(int x, int y) { this.x = x; this.y = y; }

// 4. Auto-generated equals, hashCode, toString
```

---

## Part 3: Advanced Record Features

### **1. Compact Constructor (Validation)**

A **compact constructor** is a concise way to add validation logic without repeating field assignments.

```java
// ❌ Traditional constructor
record Point(int x, int y) {
    public Point {
        if (x < 0 || y < 0) {
            throw new IllegalArgumentException("Coordinates must be non-negative");
        }
        // DO NOT assign fields here - compiler does it automatically
    }
}

// Usage
Point p = new Point(5, 10);      // ✅ Valid
Point p2 = new Point(-5, 10);    // ❌ Throws IllegalArgumentException
```

### **2. Adding Custom Methods**

```java
record Circle(double radius) {
    // Compact constructor for validation
    public Circle {
        if (radius <= 0) {
            throw new IllegalArgumentException("Radius must be positive");
        }
    }
    
    // Custom methods
    public double area() {
        return Math.PI * radius * radius;
    }
    
    public double circumference() {
        return 2 * Math.PI * radius;
    }
}

// Usage
Circle c = new Circle(5);
System.out.println(c.area());          // 78.53981633974483
System.out.println(c.circumference()); // 31.41592653589793
```

### **3. Overriding Auto-Generated Methods**

```java
record Person(String name, int age) {
    // Override toString for custom formatting
    @Override
    public String toString() {
        return name + " (" + age + " years old)";
    }
    
    // Override equals for custom comparison
    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof Person)) return false;
        Person other = (Person) obj;
        return name.equalsIgnoreCase(other.name) && age == other.age;
    }
}

// Usage
Person p1 = new Person("Alice", 30);
Person p2 = new Person("alice", 30);
System.out.println(p1.equals(p2));     // true (case-insensitive)
System.out.println(p1);                // Alice (30 years old)
```

### **4. Secondary Constructors**

You can add **overloaded constructors**, but they **must delegate to the canonical constructor**.

```java
record Person(String name, int age) {
    // Compact constructor (canonical)
    public Person {
        if (age < 0) {
            throw new IllegalArgumentException("Age cannot be negative");
        }
    }
    
    // Secondary constructor: must call this(...)
    public Person(String name) {
        this(name, 0);  // ✅ Must call canonical constructor
    }
    
    // Another secondary constructor
    public Person(int age) {
        this("Unknown", age);
    }
}

// Usage
Person p1 = new Person("Bob", 25);     // Canonical
Person p2 = new Person("Alice");       // Secondary (age defaults to 0)
Person p3 = new Person(30);            // Secondary (name defaults to "Unknown")
```

### **5. Records Implementing Interfaces**

```java
interface Drawable {
    void draw();
}

record Circle(double radius) implements Drawable {
    @Override
    public void draw() {
        System.out.println("Drawing circle with radius " + radius);
    }
}

// Usage
Circle c = new Circle(5);
c.draw();  // Drawing circle with radius 5.0
```

### **6. Generic Records**

```java
// Generic record with type parameter
record Box<T>(T content) {}

// Usage
Box<String> stringBox = new Box<>("Hello");
Box<Integer> intBox = new Box<>(42);
Box<List<String>> listBox = new Box<>(List.of("a", "b", "c"));

System.out.println(stringBox);  // Box[content=Hello]
System.out.println(intBox);     // Box[content=42]
System.out.println(listBox);    // Box[content=[a, b, c]]
```

### **7. Static Fields and Methods**

```java
record Person(String name, int age) {
    // Static fields
    static int personCount = 0;
    
    // Compact constructor to increment counter
    public Person {
        personCount++;
    }
    
    // Static method
    static void printCount() {
        System.out.println("Total people: " + personCount);
    }
}

// Usage
new Person("Alice", 30);
new Person("Bob", 25);
Person.printCount();  // Total people: 2
```

---

## Part 4: Common Mistakes & Limitations

### **🔴 Mistake #1: Trying to Set Fields After Creation**

**The Problem:**
Records are immutable. All fields are `final`.

```java
// ❌ WRONG
record Point(int x, int y) {}

Point p = new Point(5, 10);
p.x = 20;  // ❌ Compilation error: cannot assign to final variable x
```

**✅ Solution:**
```java
// Create a new record instead
Point p = new Point(5, 10);
Point p2 = new Point(20, 10);  // New instance with updated x
```

---

### **🔴 Mistake #2: Adding Non-Header Instance Fields**

**The Problem:**
You cannot declare instance fields beyond those in the record header.

```java
// ❌ WRONG
record Person(String name, int age) {
    int id;  // ❌ NOT allowed! Can't add new instance fields
}
```

**✅ Solution:**
Use `static` fields instead or redesign your record:

```java
// Solution 1: Use static fields
record Person(String name, int age) {
    static int nextId = 1;  // ✅ Static field is OK
}

// Solution 2: Redesign to include field in header
record Person(int id, String name, int age) {}
```

---

### **🔴 Mistake #3: Shallow Immutability with Mutable Components**

**The Problem:**
If a record contains a mutable object (like `List` or `StringBuilder`), the contents can still be modified.

```java
// ❌ DANGEROUS - Fields are final but contents can change
record Person(String name, List<String> hobbies) {}

Person p = new Person("Alice", new ArrayList<>(List.of("reading")));
p.hobbies().add("swimming");  // ❌ Mutates the list!
System.out.println(p.hobbies());  // [reading, swimming]

// Two equal records can become unequal after mutation
Person p2 = new Person("Alice", new ArrayList<>(List.of("reading")));
System.out.println(p.equals(p2));  // false (after mutation)
```

**✅ Solution: Defensive Copy**

```java
record Person(String name, List<String> hobbies) {
    // Compact constructor: make defensive copy
    public Person {
        hobbies = List.copyOf(hobbies);  // ✅ Immutable copy
    }
}

Person p = new Person("Alice", new ArrayList<>(List.of("reading")));
p.hobbies().add("swimming");  // ❌ UnsupportedOperationException
```

---

### **🔴 Mistake #4: Trying to Extend Other Classes**

**The Problem:**
Records are implicitly `final` and cannot extend classes.

```java
// ❌ WRONG - Records cannot extend classes
record Employee(String name) extends Person {}

// ❌ WRONG - Records cannot be abstract or extended
abstract record Shape(int x, int y) {}

class Circle extends Shape {}  // ❌ Not allowed
```

**✅ Solution: Use Interfaces or Sealed Classes**

```java
// ✅ Records can implement interfaces
interface Entity {
    void display();
}

record Employee(String name, int salary) implements Entity {
    @Override
    public void display() {
        System.out.println(name + ": $" + salary);
    }
}

// ✅ Use sealed classes for polymorphism
sealed interface Shape permits Circle, Rectangle {}

record Circle(double radius) implements Shape {}
record Rectangle(double width, double height) implements Shape {}
```

---

### **🔴 Mistake #5: Incorrect Canonical Constructor Syntax**

**The Problem:**
Forgetting that the compact constructor body **automatically assigns fields**.

```java
// ❌ WRONG - Compact constructor shouldn't assign fields
record Point(int x, int y) {
    public Point {
        this.x = x;  // ❌ Redundant - compiler does this
        this.y = y;  // ❌ Redundant
    }
}
```

**✅ Correct:**

```java
// ✅ Compact constructor - only add validation/logic
record Point(int x, int y) {
    public Point {
        if (x < 0 || y < 0) {
            throw new IllegalArgumentException("Coordinates must be >= 0");
        }
        // DON'T assign - compiler does it automatically
    }
}
```

---

### **🔴 Mistake #6: No-Arg Constructor**

**The Problem:**
Records don't support no-arg constructors by default.

```java
// ❌ WRONG
record Person(String name, int age) {
    public Person() {}  // ❌ Not allowed
}
```

**✅ Solution 1: Use Optional Pattern**

```java
record Person(String name, int age) {
    static Person empty() {
        return new Person("", 0);
    }
}

Person p = Person.empty();
```

**✅ Solution 2: Default Record with Optional**

```java
record Person(Optional<String> name, Optional<Integer> age) {}

Person p = new Person(Optional.empty(), Optional.empty());
```

---

### **🔴 Mistake #7: Improper Serialization**

**The Problem:**
Records serialize by component name, which can break if components change.

```java
// Original record
record Person(String name, int age) {}

// Later changed to
record Person(int age, String name) {}  // ❌ Deserialization fails!
```

**✅ Solution: Use `@Serial`**

```java
record Person(String name, int age) {
    @Serial
    private static final long serialVersionUID = 1L;
}
```

---

## Part 5: Record vs Regular Class Comparison

### **Comprehensive Comparison Table**

| Feature | Record | Regular Class |
|---------|--------|---------------|
| **Immutability** | By design (final fields) | Optional |
| **Boilerplate** | Minimal | Extensive |
| **Constructor** | Auto-generated canonical + optional secondary | Manual |
| **Getters** | Auto-generated (no `get` prefix) | Manual or IDE generated |
| **equals/hashCode** | Value-based (auto) | Reference-based (default), must override |
| **toString** | Auto-generated, readable | Manual or IDE generated |
| **Inheritance** | Cannot extend classes | Can extend classes |
| **Interfaces** | Can implement | Can implement |
| **Mutable fields** | Not by default | Yes |
| **Use case** | Data carriers (DTOs, POJOs) | Domain models, services, complex logic |

---

## Part 6: Real-World Use Cases

### **Use Case 1: Data Transfer Object (DTO)**

```java
// API response DTO
record UserDTO(
    long id,
    String username,
    String email,
    LocalDateTime createdAt
) {}

// Usage with REST API
public UserDTO getUser(long id) {
    // Fetch from database and map to DTO
    return new UserDTO(
        1L,
        "alice",
        "alice@example.com",
        LocalDateTime.now()
    );
}
```

### **Use Case 2: Configuration Object**

```java
record DatabaseConfig(
    String host,
    int port,
    String username,
    String password
) {
    public DatabaseConfig {
        if (port < 1 || port > 65535) {
            throw new IllegalArgumentException("Invalid port: " + port);
        }
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("Username cannot be empty");
        }
    }
    
    public String getJdbcUrl() {
        return "jdbc:mysql://" + host + ":" + port;
    }
}

// Usage
DatabaseConfig config = new DatabaseConfig("localhost", 3306, "root", "password");
System.out.println(config.getJdbcUrl());  // jdbc:mysql://localhost:3306
```

### **Use Case 3: Value Object in Collections**

```java
record Coordinates(double latitude, double longitude) {
    public Coordinates {
        if (latitude < -90 || latitude > 90) {
            throw new IllegalArgumentException("Invalid latitude");
        }
        if (longitude < -180 || longitude > 180) {
            throw new IllegalArgumentException("Invalid longitude");
        }
    }
    
    public double distance(Coordinates other) {
        // Haversine formula
        double lat1Rad = Math.toRadians(latitude);
        double lat2Rad = Math.toRadians(other.latitude);
        double dLat = Math.toRadians(other.latitude - latitude);
        double dLng = Math.toRadians(other.longitude - longitude);
        
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                   Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.asin(Math.sqrt(a));
        return 6371 * c;  // Earth radius in km
    }
}

// Usage in Set (value-based equality and hashCode)
Set<Coordinates> locations = new HashSet<>();
locations.add(new Coordinates(40.7128, -74.0060));  // NYC
locations.add(new Coordinates(40.7128, -74.0060));  // Same location
System.out.println(locations.size());  // 1 (duplicate removed)

Coordinates nyc = new Coordinates(40.7128, -74.0060);
Coordinates la = new Coordinates(34.0522, -118.2437);
System.out.println(nyc.distance(la));  // ~3944.77 km
```

### **Use Case 4: Pattern Matching with Records**

```java
sealed interface Shape permits Circle, Rectangle {}

record Circle(double radius) implements Shape {}
record Rectangle(double width, double height) implements Shape {}

double area(Shape shape) {
    return switch (shape) {
        case Circle c -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.width() * r.height();
    };
}

// Usage with pattern matching
Circle c = new Circle(5);
System.out.println(area(c));  // 78.53981633974483
```

---

## Part 7: Best Practices (Senior Engineer Tips)

### **1. Use Records for Immutable Data Carriers**

```java
// ✅ GOOD - Simple data holder
record Product(String name, BigDecimal price, String description) {}

// ❌ AVOID - Business logic in records
record User(String name) {
    public void authenticateUser() {  // ❌ Too much logic
        // Complex authentication logic
    }
}
```

### **2. Leverage Value-Based Equality**

```java
record Person(String name, int age) {}

// Use in collections confidently
Map<Person, String> people = new HashMap<>();
people.put(new Person("Alice", 30), "Developer");
System.out.println(people.get(new Person("Alice", 30)));  // Developer
```

### **3. Make Defensive Copies for Mutable Components**

```java
record Order(String id, List<Item> items) {
    public Order {
        items = List.copyOf(items);  // ✅ Immutable copy
    }
}
```

### **4. Use with Functional Programming**

```java
List<Person> people = List.of(
    new Person("Alice", 30),
    new Person("Bob", 25),
    new Person("Charlie", 30)
);

// Records work great with streams
people.stream()
    .filter(p -> p.age() > 25)
    .map(Person::name)
    .forEach(System.out::println);  // Alice, Charlie
```

### **5. Prefer Records over Lombok's @Data**

```java
// ❌ OLD WAY (with Lombok)
@Data
class Person {
    private String name;
    private int age;
}

// ✅ NEW WAY (Java Records)
record Person(String name, int age) {}
```

---

## Summary Table: When to Use What

| Use Records When | Use Classes When |
|-----------------|-----------------|
| Data holder (DTO) | Business logic needed |
| Immutability desired | Mutability needed |
| Value equality important | Reference equality OK |
| Simple data carrier | Complex inheritance required |
| Functional programming style | Traditional OOP design |
| No setters/mutation needed | Need to modify state |



[[Java]]