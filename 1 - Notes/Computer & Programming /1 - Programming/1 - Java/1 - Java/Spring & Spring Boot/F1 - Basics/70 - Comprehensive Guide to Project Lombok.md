Date : 2025-09-07

## What is Lombok?

Project Lombok is a Java library that reduces boilerplate code by using annotations to automatically generate common code patterns (e.g., getters, setters, constructors, `toString`, `equals`, and `hashCode`) during compilation. It integrates seamlessly with your IDE and build tools, making Java development more concise and readable.

Lombok does not generate code in your source files but rather in the compiled bytecode, keeping your source code clean. It is widely used in Java projects to improve productivity and maintainability.

## Why Use Lombok?

- **Reduces Boilerplate Code**: Eliminates repetitive code, such as getters/setters, constructors, and common methods.
- **Improves Readability**: Keeps your codebase concise and focused on business logic.
- **Maintains Safety**: Generated code follows Java best practices and is type-safe.
- **IDE Integration**: Works with popular IDEs like IntelliJ IDEA, Eclipse, and VS Code.
- **Customizable**: Allows fine-grained control over generated code via annotation parameters.

## Prerequisites

Before using Lombok, ensure you have:

- Java Development Kit (JDK) installed (Java 8 or higher recommended).
- A supported IDE (IntelliJ IDEA, Eclipse, NetBeans, or VS Code with Java extensions).
- A build tool like Maven or Gradle (optional but recommended for dependency management).

## Setting Up Lombok

### 1. Add Lombok Dependency

Lombok is a compile-time dependency. Add it to your project using Maven or Gradle.

#### Maven

Add the following to your `pom.xml`:

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.34</version> <!-- Use the latest version -->
    <scope>provided</scope>
</dependency>
```

#### Gradle

Add the following to your `build.gradle`:

```groovy
dependencies {
    provided 'org.projectlombok:lombok:1.18.34' // Use the latest version
    annotationProcessor 'org.projectlombok:lombok:1.18.34'
}
```

**Note**: The `provided` scope ensures Lombok is used only during compilation and not included in the runtime classpath.

#### Manual JAR Download

If not using a build tool, download the Lombok JAR from [Project Lombok's official site](https://projectlombok.org/download) and add it to your project's classpath.

### 2. IDE Configuration

Lombok requires IDE plugins or configuration for proper integration, as it generates code that your IDE needs to recognize.

#### IntelliJ IDEA

1. Go to `File > Settings > Plugins`.
2. Search for "Lombok" in the Marketplace and install the Lombok plugin.
3. Restart IntelliJ.
4. Enable annotation processing:
    - Go to `File > Settings > Build, Execution, Deployment > Compiler > Annotation Processors`.
    - Check "Enable annotation processing".

#### Eclipse

1. Download the Lombok JAR from [Project Lombok](https://projectlombok.org/download).
2. Run `java -jar lombok.jar`. This opens a GUI to locate your Eclipse installation.
3. Follow the prompts to install Lombok into Eclipse.
4. Restart Eclipse.

#### VS Code

1. Install the "Java Extension Pack" or "Lombok Annotations Support for VS Code" extension.
2. Ensure your project is configured with a build tool (Maven/Gradle) that includes Lombok.

### 3. Verify Lombok Installation

To confirm Lombok is set up:

1. Create a simple Java class with a Lombok annotation (e.g., `@Getter`).
2. Compile the project or check if your IDE recognizes the generated methods (e.g., getters).

## Lombok Annotations

Lombok provides a wide range of annotations to simplify Java development. Below is a comprehensive list of commonly used annotations, their purposes, and examples.

### 1. `@Getter` and `@Setter`

Generates getter and setter methods for fields.

```java
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Person {
    private String name;
    private int age;
}
```

- **Generated Code**:
    
    ```java
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }
    ```
    
- **Customization**:
    - `@Getter(AccessLevel.PROTECTED)`: Set access level (e.g., `PUBLIC`, `PROTECTED`, `PRIVATE`, `NONE`).
    - `@Setter(AccessLevel.PRIVATE)`: Similarly for setters.
    - Apply to individual fields: `@Getter private String name;`.

### 2. `@ToString`

Generates a `toString()` method that includes field names and values.

```java
import lombok.ToString;

@ToString
public class Person {
    private String name = "John";
    private int age = 30;
}
```

- **Output**: `Person(name=John, age=30)`
- **Customization**:
    - `@ToString(exclude = {"age"})`: Excludes specific fields.
    - `@ToString(includeFieldNames = false)`: Omits field names in output (e.g., `Person(John, 30)`).
    - `@ToString(callSuper = true)`: Includes superclass fields for inherited classes.

### 3. `@EqualsAndHashCode`

Generates `equals()` and `hashCode()` methods.

```java
import lombok.EqualsAndHashCode;

@EqualsAndHashCode
public class Person {
    private String name;
    private int age;
}
```

- **Customization**:
    - `@EqualsAndHashCode(exclude = {"age"})`: Excludes fields from comparison.
    - `@EqualsAndHashCode(callSuper = true)`: Includes superclass fields.
    - `@EqualsAndHashCode(onlyExplicitlyIncluded = true)`: Only includes fields marked with `@EqualsAndHashCode.Include`.

### 4. `@NoArgsConstructor`, `@RequiredArgsConstructor`, `@AllArgsConstructor`

Generates constructors with no arguments, required fields, or all fields, respectively.

```java
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.AllArgsConstructor;

@NoArgsConstructor
@RequiredArgsConstructor
@AllArgsConstructor
public class Person {
    private final String name; // Required field
    private int age;
}
```

- **Generated Code**:
    - `@NoArgsConstructor`: `public Person() {}`
    - `@RequiredArgsConstructor`: `public Person(String name) { this.name = name; }` (for `final` or `@NonNull` fields)
    - `@AllArgsConstructor`: `public Person(String name, int age) { this.name = name; this.age = age; }`
- **Customization**:
    - `@NoArgsConstructor(force = AccessLevel.PRIVATE)`: Set access level.
    - `@RequiredArgsConstructor(staticName = "of")`: Generates a static factory method (e.g., `Person.of("John")`).

### 5. `@Data`

A convenience annotation that combines `@Getter`, `@Setter`, `@ToString`, `@EqualsAndHashCode`, and `@RequiredArgsConstructor`.

```java
import lombok.Data;

@Data
public class Person {
    private final String name;
    private int age;
}
```

- **Note**: Use `@Data` for simple classes, but prefer individual annotations for fine-grained control.

### 6. `@Builder`

Generates a fluent builder pattern for object creation.

```java
import lombok.Builder;

@Builder
public class Person {
    private String name;
    private int age;
}
```

- **Usage**:
    
    ```java
    Person person = Person.builder()
        .name("John")
        .age(30)
        .build();
    ```
    
- **Customization**:
    - `@Builder(toBuilder = true)`: Adds a `toBuilder()` method to create a builder from an existing object.
    - `@Builder(builderMethodName = "customBuilder")`: Changes the builder method name.
    - `@Builder.Default`: Specifies default values for fields.

### 7. `@Value`

Creates an immutable class (similar to `@Data` but with `final` fields and no setters).

```java
import lombok.Value;

@Value
public class Person {
    String name;
    int age;
}
```

- **Generated**: Immutable class with `@Getter`, `@ToString`, `@EqualsAndHashCode`, and an all-args constructor.
- **Customization**: Similar to `@Data` (e.g., `exclude`, `callSuper`).

### 8. `@NonNull`

Enforces null checks in setters or constructors.

```java
import lombok.NonNull;

public class Person {
    private final String name;

    public Person(@NonNull String name) {
        this.name = name;
    }
}
```

- **Generated**: Throws `NullPointerException` if `name` is null.
- **Usage**: Often combined with `@RequiredArgsConstructor`.

### 9. `@SneakyThrows`

Suppresses checked exceptions, allowing you to avoid explicit `try-catch` blocks.

```java
import lombok.SneakyThrows;

public class Example {
    @SneakyThrows
    public void riskyMethod() {
        throw new IOException("Error!");
    }
}
```

- **Generated**: Wraps the exception in a `RuntimeException`.
- **Caution**: Use sparingly, as it can obscure exception handling.

### 10. `@Cleanup`

Ensures resources (e.g., streams) are automatically closed.

```java
import lombok.Cleanup;
import java.io.*;

public class Example {
    public void readFile() throws IOException {
        @Cleanup FileInputStream fis = new FileInputStream("file.txt");
        // Use fis
    }
}
```

- **Generated**: Equivalent to a `try-finally` block to close the resource.

### 11. `@Synchronized`

Generates synchronized methods or blocks.

```java
import lombok.Synchronized;

public class Example {
    @Synchronized
    public void criticalSection() {
        // Thread-safe code
    }
}
```

- **Generated**: Uses a dedicated lock object to avoid locking on `this`.

### 12. `@Log`, `@Slf4j`, `@Log4j`, etc.

Generates logger instances for various logging frameworks.

```java
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class Example {
    public void doSomething() {
        log.info("Hello, Lombok!");
    }
}
```

- **Supported Loggers**:
    - `@Log`: `java.util.logging`
    - `@Slf4j`: SLF4J
    - `@Log4j`: Apache Log4j
    - `@Log4j2`: Apache Log4j 2
    - `@CommonsLog`: Apache Commons Logging
- **Generated**: `private static final Logger log = ...;`

### 13. `@With`

Generates "with" methods to create immutable copies with modified fields.

```java
import lombok.With;

public class Person {
    @With private final String name;
    private final int age;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

- **Usage**:
    
    ```java
    Person person = new Person("John", 30);
    Person updated = person.withName("Jane");
    ```
    
- **Generated**: A new instance with the modified field.

### 14. Experimental Annotations

Lombok includes experimental features (use with caution):

- `@FieldDefaults`: Sets default access levels or modifiers for fields.
- `@UtilityClass`: Marks a class as a utility class (static methods only, no instantiation).
- `@ExtensionMethod`: Enables extension-like methods (not widely used).

## Example: Complete Lombok Class

```java
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Person {
    @NonNull
    private String name;
    private int age;

    @ToString.Exclude
    private String sensitiveData;

    @SneakyThrows
    public void riskyOperation() {
        throw new IOException("Test");
    }
}
```

- **Generated**: Getters, setters, `toString` (excluding `sensitiveData`), `equals`, `hashCode`, no-args and all-args constructors, a builder, and null checks for `name`.

## Best Practices

1. **Use Sparingly**: Avoid overusing Lombok in small classes where boilerplate is minimal.
2. **Combine with Care**: Annotations like `@Data` can generate more code than needed; use specific annotations for better control.
3. **Document Generated Code**: Ensure team members know Lombok is used, as generated methods are not visible in source code.
4. **Check IDE Support**: Ensure all developers have Lombok configured in their IDEs.
5. **Avoid `@SneakyThrows` for Critical Exceptions**: Use explicit exception handling for important cases.
6. **Test Generated Code**: Verify that generated methods (e.g., `equals`, `hashCode`) behave as expected.

## Common Pitfalls

- **IDE Issues**: If Lombok annotations are not recognized, ensure the plugin is installed and annotation processing is enabled.
- **Build Tool Errors**: Verify Lombok is in the `provided` scope and the version matches in all dependencies.
- **Team Adoption**: Some developers may resist Lombok due to its "magic" nature; communicate its benefits clearly.
- **Generated Code Conflicts**: Be cautious with `@EqualsAndHashCode` or `@ToString` in complex class hierarchies to avoid unintended behavior.

## Lombok Configuration (Optional)

You can customize Lombok's behavior using a `lombok.config` file in your project root. Example:

```properties
lombok.getter.noIsPrefix=true
lombok.toString.includeFieldNames=true
```

- **Common Options**:
    - `lombok.getter.noIsPrefix`: Disables `is` prefix for boolean getters.
    - `lombok.copyableAnnotations`: Specifies annotations to copy to generated methods.
    - `lombok.anyConstructor.addConstructorProperties`: Adds `@ConstructorProperties` to constructors.

## Troubleshooting

- **"Cannot find symbol" Errors**: Ensure Lombok is in the classpath and annotation processing is enabled.
- **IDE Not Recognizing Methods**: Reinstall the Lombok plugin or restart the IDE.
- **Incompatible Versions**: Use the same Lombok version in your build tool and IDE.
- **Debugging Generated Code**: Use `delombok` (a Lombok tool) to generate explicit Java source code for inspection:
    
    ```bash
    java -jar lombok.jar delombok src -d output
    ```
    

## Alternatives to Lombok

If Lombok doesn't suit your needs, consider:

- **Immutables**: Generates immutable objects with a similar annotation-based approach.
- **AutoValue**: A Google library for immutable value classes.
- **Kotlin**: A language with built-in features to reduce boilerplate (e.g., data classes).
- **Manual Code**: Writing boilerplate manually for full control.

---

# Lombok Annotations

|Annotation|Category|Where to Use|Description|
|---|---|---|---|
|**@Getter**|Boilerplate|On class or field|Generates getter methods.|
|**@Setter**|Boilerplate|On class or field|Generates setter methods.|
|**@Data**|Boilerplate|On class|Combines `@Getter`, `@Setter`, `@ToString`, `@EqualsAndHashCode`, `@RequiredArgsConstructor`.|
|**@Value**|Boilerplate|On class|Immutable `@Data` (all fields `private final`, no setters).|
|**@ToString**|Boilerplate|On class|Generates `toString()`.|
|**@EqualsAndHashCode**|Boilerplate|On class|Generates `equals()` and `hashCode()`.|
|**@NoArgsConstructor**|Constructor|On class|Generates no-args constructor.|
|**@RequiredArgsConstructor**|Constructor|On class|Constructor for `final` and `@NonNull` fields.|
|**@AllArgsConstructor**|Constructor|On class|Constructor with all fields as parameters.|
|**@Builder**|Builder Pattern|On class, constructor, or method|Creates builder API for object construction.|
|**@Singular**|Builder Pattern|On collection fields inside a `@Builder`|Adds single-element adder in builder.|
|**@SuperBuilder**|Builder Pattern|On class|Like `@Builder` but works with inheritance.|
|**@With**|Immutability|On field or class|Creates copy methods (`withField(value)`).|
|**@NonNull**|Null-safety|On parameter, field, or method return|Adds null-check; throws `NullPointerException`.|
|**@Cleanup**|Resource Mgmt|On local variable|Ensures resource’s `close()` is called.|
|**@SneakyThrows**|Exception Handling|On method or constructor|Allows throwing checked exceptions without declaring.|
|**@Synchronized**|Concurrency|On method|Thread-safe locking with private lock object.|
|**@Log** / **@Slf4j** / **@Log4j2** / **@CommonsLog**|Logging|On class|Auto-generates a logger instance.|
|**@Delegate**|Experimental|On field|Delegates methods of another type to this field.|
|**@FieldDefaults**|Experimental|On class|Defines default modifiers (e.g., `private final`).|
|**@Accessors**|Experimental|On class or field|Changes naming style of accessors (e.g., fluent setters).|
|**@ExtensionMethod**|Experimental|On class|Simulates extension methods (adds static methods to types).|
|**@UtilityClass**|Utility Classes|On class|Makes class final, private constructor, all members `static`.|

---

## Category Explanations

- **Boilerplate** → Removes repetitive getter/setter, `toString()`, equals/hashCode code.
    
- **Constructor** → Auto-generates constructors based on fields.
    
- **Builder Pattern** → Provides builder API for flexible object creation.
    
- **Immutability** → Helps enforce immutability with copy-like methods.
    
- **Null-safety** → Prevents null issues with checks at runtime.
    
- **Resource Mgmt** → Simplifies cleanup of resources (like try-with-resources).
    
- **Exception Handling** → Makes exception handling less verbose.
    
- **Concurrency** → Thread-safe method locking.
    
- **Logging** → Generates logger fields for various frameworks.
    
- **Experimental** → Advanced but less stable features; use cautiously.
    
- **Utility Classes** → Creates static-only helper classes automatically.
    

## Resources

- [Official Lombok Website](https://projectlombok.org/)
- [Lombok Features Documentation](https://projectlombok.org/features/)
- [GitHub Repository](https://github.com/projectlombok/lombok)
- [Lombok Maven Repository](https://mvnrepository.com/artifact/org.projectlombok/lombok)
##### *Tags : [[0 - Spring Framework]]