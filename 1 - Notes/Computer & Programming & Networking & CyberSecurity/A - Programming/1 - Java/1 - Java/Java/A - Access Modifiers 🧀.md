In Java, **modifiers** are keywords that define the properties and behavior of classes, methods, variables, and constructors. They control access levels, behavior, and scope. Java modifiers are broadly categorized into **access modifiers** and **non-access modifiers**.

### 1. **Access Modifiers**
These control the visibility or accessibility of a class, method, variable, or constructor.

- **`public`**: The member is accessible from everywhere.
  - Example: `public int myVariable;`
  - Usable with: Classes, interfaces, methods, fields, constructors.

- **`protected`**: The member is accessible within the same package and also in subclasses (even if in different packages).
  - Example: `protected void myMethod() {}`
  - Usable with: Methods, fields, constructors (not classes or interfaces).

- **`default`** (also called package-private): If no access modifier is specified, the member is accessible only within the same package.
  - Example: `int myVariable;` (no modifier implies default)
  - Usable with: Classes, interfaces, methods, fields, constructors.

- **`private`**: The member is accessible only within the same class.
  - Example: `private String myField;`
  - Usable with: Methods, fields, constructors (not top-level classes or interfaces).

### 2. **Non-Access Modifiers**
These affect the behavior or characteristics of a class, method, or variable.

- **`static`**: Indicates that a member belongs to the class, not instances. Can be used for methods, variables, nested classes, or initialization blocks.
  - Example: `static int counter;`
  - Usage: Class-level variables/methods, utility methods (e.g., `Math.sqrt()`).

- **`final`**:
  - For variables: Makes them constant (value cannot be changed once assigned).
    - Example: `final int MAX = 100;`
  - For methods: Prevents overriding in subclasses.
    - Example: `final void myMethod() {}`
  - For classes: Prevents inheritance.
    - Example: `final class MyClass {}`
  - Usage: Constants, preventing method overriding or class extension.

- **`abstract`**:
  - For classes: Indicates the class cannot be instantiated and may contain abstract methods.
    - Example: `abstract class Animal {}`
  - For methods: Declares a method without a body; subclasses must provide implementation.
    - Example: `abstract void makeSound();`
  - Usage: Abstract classes and methods for defining templates.

- **`synchronized`**:
  - For methods or blocks: Ensures only one thread can execute at a time, preventing race conditions.
    - Example: `synchronized void increment() { counter++; }`
  - Usage: Thread safety in concurrent programming.

- **`transient`**:
  - For variables: Prevents serialization of the variable.
    - Example: `transient int sensitiveData;`
  - Usage: When you don’t want a field to be saved during serialization.

- **`volatile`**:
  - For variables: Ensures visibility of changes to variables across threads.
    - Example: `volatile boolean isRunning;`
  - Usage: Thread synchronization for variables.

- **`strictfp`**:
  - For classes or methods: Ensures consistent floating-point calculations across platforms.
    - Example: `strictfp double calculate() {}`
  - Usage: Rarely used, ensures portability of floating-point operations.

- **`native`**:
  - For methods: Indicates the method is implemented in native code (e.g., C/C++).
    - Example: `native void myNativeMethod();`
  - Usage: Interfacing with native libraries.

### 3. **Modifiers for Specific Contexts**
- **Classes**: Can use `public`, `default`, `final`, `abstract`, `strictfp`.
- **Interfaces**: Can use `public`, `default`, `abstract` (implicitly abstract, so no need to declare).
- **Methods**: Can use `public`, `protected`, `default`, `private`, `static`, `final`, `abstract`, `synchronized`, `native`, `strictfp`.
- **Fields**: Can use `public`, `protected`, `default`, `private`, `static`, `final`, `transient`, `volatile`.
- **Constructors**: Can use `public`, `protected`, `default`, `private`.

### Example Usage
```java
public final class MyClass {
    private static int counter; // static variable
    protected final String name = "Example"; // constant field
    public synchronized void increment() { // thread-safe method
        counter++;
    }
    abstract void doSomething(); // abstract method
}
```

### Notes
- Not all modifiers can be combined (e.g., `abstract` and `final` are mutually exclusive).
- The order of modifiers doesn’t matter in Java.
- Inner classes and nested classes can have additional considerations (e.g., `static` for nested classes).

[[Java]]