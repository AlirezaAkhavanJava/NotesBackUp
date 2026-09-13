**Date**: 2025-08-24  
**Tags**: [[Java]] 

## What is Coupling?

Coupling refers to how much one class or module depends on another in a program. It measures how interconnected components are. In Java, good design aims for **loose coupling** to make code more flexible, maintainable, and testable, while **tight coupling** can lead to rigid, hard-to-change code.

## Key Concepts

- **Tight Coupling**: When classes are highly dependent on each other, so a change in one class requires changes in others.
- **Loose Coupling**: When classes have minimal dependencies, allowing changes in one class without affecting others.
- **Dependency Injection (DI)**: A technique (often used in Spring) to achieve loose coupling by passing dependencies externally.
- **Interfaces/Abstract Classes**: Tools to reduce direct dependencies by coding to abstractions.
- **Benefits of Loose Coupling**: Easier maintenance, better testability, and flexibility to swap components.

---

## Tight Coupling

### What is it?

Tight coupling occurs when one class directly uses another class’s implementation details (e.g., creating instances with `new` or accessing specific methods/fields). This makes classes tightly bound, so changes in one break the other.

### Characteristics

- Classes know too much about each other’s internals.
- Hard to modify or replace a class without affecting others.
- Difficult to test because dependencies are hardcoded.
- Common in poorly designed systems.

### Example of Tight Coupling

```java
public class Database {
    public String getData() {
        return "Data from Database";
    }
}

public class DataProcessor {
    // Directly creates Database instance (tight coupling)
    private Database db = new Database();

    public void process() {
        String data = db.getData();
        System.out.println("Processing: " + data);
    }
}

public class Main {
    public static void main(String[] args) {
        DataProcessor processor = new DataProcessor();
        processor.process();
    }
}
```

**Problem**: `DataProcessor` is tightly coupled to `Database`. If you want to use a different data source (e.g., `FileStorage`), you must modify `DataProcessor`.

## Loose Coupling

### What is it?

Loose coupling means classes interact through interfaces or abstractions, not specific implementations. Dependencies are injected externally (e.g., via constructor or setter), making it easy to swap components without changing code.

### Characteristics

- Classes depend on interfaces or abstract classes, not concrete implementations.
- Easy to swap or modify components without breaking other parts.
- Improves testability (e.g., use mocks in tests).
- Common in frameworks like Spring using dependency injection.

### Example of Loose Coupling

```java
// Interface for data source
public interface DataSource {
    String getData();
}

// Concrete implementation 1
public class Database implements DataSource {
    @Override
    public String getData() {
        return "Data from Database";
    }
}

// Concrete implementation 2
public class FileStorage implements DataSource {
    @Override
    public String getData() {
        return "Data from File";
    }
}

// Processor depends on interface, not implementation
public class DataProcessor {
    private final DataSource dataSource;

    // Dependency injected via constructor
    public DataProcessor(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public void process() {
        String data = dataSource.getData();
        System.out.println("Processing: " + data);
    }
}

public class Main {
    public static void main(String[] args) {
        // Inject Database or FileStorage
        DataSource db = new Database();
        DataProcessor processor = new DataProcessor(db);
        processor.process(); // Output: Processing: Data from Database

        // Easily switch to FileStorage
        DataSource file = new FileStorage();
        processor = new DataProcessor(file);
        processor.process(); // Output: Processing: Data from File
    }
}
```

**Benefit**: `DataProcessor` doesn’t care if it’s using `Database` or `FileStorage`, as long as it implements `DataSource`. You can swap implementations without changing `DataProcessor`.

## Tight vs. Loose Coupling

- **Tight Coupling**:
    - Hard to change or test (e.g., `new Database()` hardcodes the dependency).
    - Example: Directly instantiating a class inside another.
    - Drawback: Changing `Database` breaks `DataProcessor`.
- **Loose Coupling**:
    - Flexible, testable, and maintainable.
    - Example: Using interfaces and dependency injection.
    - Benefit: Swap `Database` for `FileStorage` without modifying `DataProcessor`.

## Common Issues

- **Overusing Tight Coupling**: Hardcoding dependencies makes code rigid.
    - **Fix**: Use interfaces and inject dependencies.
- **Complex Dependency Injection**: Too many dependencies can make DI setups confusing.
    - **Fix**: Keep interfaces simple and use frameworks like Spring for DI.
- **Missing Abstractions**: Without interfaces, you’re stuck with tight coupling.
    - **Fix**: Define interfaces for key components.

## Best Practices

1. **Use Interfaces**: Code to interfaces or abstract classes, not concrete classes.
2. **Inject Dependencies**: Use constructor, setter, or Spring’s `@Autowired` for flexibility.
3. **Leverage Spring**: Use Spring Boot’s dependency injection to manage loose coupling.
4. **Keep Classes Focused**: Each class should have one responsibility (Single Responsibility Principle).
5. **Test with Mocks**: Loose coupling makes it easy to mock dependencies in unit tests (e.g., with Mockito).
6. **Avoid Static Dependencies**: Static methods/fields often lead to tight coupling.

## Example with Spring Boot (Loose Coupling)

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// Interface
public interface DataSource {
    String getData();
}

// Implementation 1
@Service
public class Database implements DataSource {
    @Override
    public String getData() {
        return "Data from Database";
    }
}

// Implementation 2
@Service
public class FileStorage implements DataSource {
    @Override
    public String getData() {
        return "Data from File";
    }
}

// Service using dependency injection
@Service
public class DataProcessor {
    private final DataSource dataSource;

    @Autowired
    public DataProcessor(DataSource dataSource) { // Spring injects the dependency
        this.dataSource = dataSource;
    }

    public String process() {
        return "Processing: " + dataSource.getData();
    }
}

// Controller
@RestController
public class DataController {
    private final DataProcessor processor;

    @Autowired
    public DataController(DataProcessor processor) {
        this.processor = processor;
    }

    @GetMapping("/data")
    public String getData() {
        return processor.process();
    }
}
```

**Note**:

- Add `spring-boot-starter-web` to your project.
- Configure Spring to inject the desired `DataSource` (e.g., `Database` or `FileStorage`) via `@Qualifier` or profiles.
- Test with `http://localhost:8080/data`.

## Summary

**Tight coupling** ties classes directly, making code hard to change or test (e.g., using `new Database()`). **Loose coupling** uses interfaces and dependency injection (e.g., Spring’s `@Autowired`) for flexibility, testability, and maintainability. Always code to interfaces, inject dependencies, and use frameworks like Spring to achieve loose coupling in Java applications.