
Lombok’s `@Builder` is an annotation that generates the **Builder pattern** for a class, which is useful for creating immutable objects or objects with many optional parameters without writing boilerplate code. Here's the breakdown:

---

### 1. Basic Usage

```java
import lombok.Builder;
import lombok.ToString;

@Builder
@ToString
public class User {
    private String name;
    private int age;
    private String email;
}

public class Main {
    public static void main(String[] args) {
        User user = User.builder()
                        .name("Ethan")
                        .age(30)
                        .email("ethan@example.com")
                        .build();
        System.out.println(user);
    }
}
```

**Output:**

```
User(name=Ethan, age=30, email=ethan@example.com)
```

- `User.builder()` → creates a builder object.
    
- `.name()`, `.age()`, `.email()` → sets properties.
    
- `.build()` → creates the actual `User` instance.
    

---

### 2. Benefits

- Avoids **telescoping constructors** (constructors with many parameters).
    
- Makes code more **readable**.
    
- Works well with **immutable objects** (no setters needed).
    

---

### 3. Advanced Features

- **Custom builder method names**:
    

```java
@Builder(builderMethodName = "customBuilder")
public class User { ... }

// usage:
User user = User.customBuilder().name("Ethan").build();
```

- **Builder on constructor**:
    

```java
public class User {
    private String name;
    private int age;

    @Builder
    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

- **`@Singular` for collections**:
    

```java
@Builder
public class Team {
    private String name;
    @Singular
    private List<String> members;
}

// usage:
Team team = Team.builder()
                .name("Avengers")
                .member("Iron Man")
                .member("Thor")
                .build();
```

---

### ⚠️ Notes

- `@Builder` generates a **static inner class** named `ClassNameBuilder`.
    
- Works well with `@AllArgsConstructor` or `@NoArgsConstructor` if combined.
    
- Does **not automatically work with inheritance**; some workarounds needed for subclassing.
    

---




##### Tags : [[0 - Spring Framework]]