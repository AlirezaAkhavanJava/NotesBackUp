**Lombok** (Project Lombok) is a Java library that reduces boilerplate code by generating common methods **at compile time** using annotations. It is not a runtime framework; it plugs into the Java compiler / annotation processing and adds code like getters, setters, constructors, `toString`, `equals`, `hashCode`, builders, and loggers into your compiled `.class` files.

### Example

Without Lombok:

```java
public class User {
    private Long id;
    private String name;

    public User() {}

    public User(Long id, String name) {
        this.id = id;
        this.name = name;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    @Override
    public String toString() {
        return "User(id=" + id + ", name=" + name + ")";
    }

    // equals/hashCode...
}
```

With Lombok:

```java
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class User {
    private Long id;
    private String name;
}
```

Lombok generates the missing methods during compilation.

### Common Lombok annotations

| Annotation | What it generates |
|---|---|
| `@Getter`, `@Setter` | getters/setters |
| `@ToString` | `toString()` |
| `@EqualsAndHashCode` | `equals()` and `hashCode()` |
| `@NoArgsConstructor` | no-args constructor |
| `@AllArgsConstructor` | constructor with all fields |
| `@RequiredArgsConstructor` | constructor for `final` / `@NonNull` fields |
| `@Data` | combines `@Getter`, `@Setter`, `@ToString`, `@EqualsAndHashCode`, `@RequiredArgsConstructor` |
| `@Value` | immutable variant of `@Data` |
| `@Builder` | builder pattern |
| `@Slf4j` | creates a `log` field using SLF4J |
| `@NonNull` | inserts null checks |
| `@Cleanup` | calls `close()` automatically |
| `@SneakyThrows` | throws checked exceptions without declaring them |

### How it works

Lombok runs as an **annotation processor** during compilation. It modifies the compiler’s internal representation of the class and injects the generated methods into the bytecode. The generated methods are real methods in the compiled class—they are not added at runtime via reflection.

Because of that, IDEs need a Lombok plugin to understand the generated code. Otherwise, the IDE may show errors like “method `getUser()` is undefined” even though compilation works.

### Maven setup

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.34</version>
    <scope>provided</scope>
</dependency>
```

### Gradle setup

```groovy
compileOnly 'org.projectlombok:lombok:1.18.34'
annotationProcessor 'org.projectlombok:lombok:1.18.34'
```

### Pros

- Less boilerplate
- Cleaner, shorter classes
- Useful for DTOs, entities, configuration classes
- Builder and logging support are convenient

### Cons / caveats

- Can feel like “magic” because code is hidden
- Requires IDE plugin and sometimes build-tool configuration
- Debugging generated code can be harder
- May hide poor design, e.g. overuse of mutable data classes
- Compatibility can break with very new Java versions until Lombok updates
- Java `record` now covers many immutable data-carrier use cases without Lombok

### In short

Lombok is a compile-time annotation processor that generates boilerplate Java code for you. It is widely used but optional; many teams like it, while others prefer plain Java, records, or IDE-generated code.


[[Java]]