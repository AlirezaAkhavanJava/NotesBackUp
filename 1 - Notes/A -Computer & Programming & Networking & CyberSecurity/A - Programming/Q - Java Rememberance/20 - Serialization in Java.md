


**Serialization** is the process of converting an object's state into a byte stream, so it can be:

- Saved to a file
- Sent over a network
- Stored in a database

**Deserialization** is the reverse — reconstructing the object from that byte stream.

### Why it's needed

Objects in memory are just structures the JVM understands. If you want to persist an object or send it somewhere else (another JVM, a file, over HTTP), you need a portable representation — that's what serialization gives you.

### How to do it

A class must implement the `Serializable` marker interface (it has no methods — it just tells the JVM "this class can be serialized"):

```java
import java.io.Serializable;

public class User implements Serializable {
    private String name;
    private int age;

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }
    // getters/setters
}
```

**Serializing an object:**

```java
try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream("user.ser"))) {
    User user = new User("Alireza", 25);
    out.writeObject(user);
}
```

**Deserializing it back:**

```java
try (ObjectInputStream in = new ObjectInputStream(new FileInputStream("user.ser"))) {
    User user = (User) in.readObject();
}
```

### Key points to remember

- `serialVersionUID` — a version number for the class. If you don't declare it, Java generates one automatically, but it's best practice to define it explicitly, so deserialization doesn't break if the class changes slightly:
    
    ```java
    private static final long serialVersionUID = 1L;
    ```
    
- `transient` keyword — marks a field to be **excluded** from serialization (e.g., passwords, sensitive data):
    
    ```java
    private transient String password;
    ```
    
- Static fields are **never** serialized — they belong to the class, not the instance.

### Where this matters in Spring Boot

You won't usually serialize objects manually like this in a Spring Boot app — instead, Spring handles JSON serialization/deserialization for you (via Jackson) when your REST controllers return objects or accept request bodies. But understanding core Java serialization helps you understand what's happening under the hood, and it's still relevant for things like caching (e.g., storing session objects or Redis cache entries) or distributed systems.


[[Java]]