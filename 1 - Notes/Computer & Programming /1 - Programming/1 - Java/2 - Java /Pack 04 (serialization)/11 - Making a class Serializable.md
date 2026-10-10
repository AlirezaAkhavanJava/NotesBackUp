


## 1. Short answers

1. **Creating it** takes one word: `implements Serializable`. There is nothing to write, because it is a marker interface with no methods.
2. **Do you need it on every object?** For Java's native serialization, **yes, on every class in the object graph** (or mark the field `transient`). For Jackson/JSON, **no**, you don't need it at all.

## 2. Mental model: a customs inspector

Picture the serializer as an inspector walking through your object, opening every field and checking each item's stamp. Each class has to carry the `Serializable` stamp to cross the border. If the inspector finds one unstamped item anywhere inside, the **whole shipment is rejected**. A `transient` field is an item you declare as "not shipping", so it's never inspected.

## 3. How to do it

```java
import java.io.Serializable;

public class Address implements Serializable {
    private static final long serialVersionUID = 1L;
    private String city;
    public Address(String city) { this.city = city; }
}

public class Person implements Serializable {
    private static final long serialVersionUID = 1L;
    private String name;          // String: already Serializable
    private int age;              // primitive: fine
    private Address address;      // YOUR class: must be Serializable too
    private transient String password;  // skipped, so no stamp needed
}
```

Serializing `Person` works only because `Address` also has the stamp. Remove `implements Serializable` from `Address` and you get:

```
java.io.NotSerializableException: Address
```

This is a **runtime** error, not a compile error, because the compiler doesn't walk the object graph.

## 4. What is already Serializable, and what isn't

|Already stamped|Not stamped (can't be serialized)|
|---|---|
|`String`, `Integer`, `Long`, `Double`, and the other wrappers|`Thread`|
|`ArrayList`, `HashMap`, `HashSet`, and most collections|`Socket`, `InputStream`, `OutputStream`|
|`enum` types|`Connection` (JDBC)|
|`LocalDate`, `Instant`, and `java.time` types|Your own classes, until you add the stamp|
|Arrays (if the elements are serializable)|Most classes holding OS or network resources|

The resource classes are excluded on purpose: a live connection or file handle makes no sense as bytes on another machine.

## 5. The rules that decide whether it works

1. **Every non-`transient` instance field's actual object must be serializable.** Static fields are ignored.
2. **The check uses the real object, not the declared type.** This trips people up:
    
    ```java
    private Object data;            // compiles fine// works if data holds a String, fails if it holds a Threadprivate List<Address> list;     // List is an interface, ArrayList is stamped,                                // but each Address must be stamped too
    ```
    
3. **Subclasses inherit the stamp.** If `Student extends Person` and `Person` is `Serializable`, then `Student` is too. Its own new fields must still be serializable.
4. **Parent without the stamp:** the parent's fields are **not saved**, and its no-arg constructor runs on deserialization (covered in the notes).
5. **Records** need `record Point(int x, int y) implements Serializable {}`, since the stamp isn't automatic.
6. **You can put the stamp on an interface:** `interface Event extends Serializable {}` makes every implementer serializable.

## 6. Gotchas

- **You can't stamp classes you don't own.** If a library class lacks `Serializable`, you can't add it. Options: mark that field `transient`, copy only the needed values into your own serializable class, or switch to JSON.
- **One bad field breaks the whole object.** The failure happens at write time, deep in the graph, and the exception names the offending class (look at its message).
- **The stamp is a permanent promise.** Once a class is serializable and its bytes are stored somewhere, changing its fields becomes a compatibility problem (`serialVersionUID` again).
- **A serializable class exposes its private fields** to anyone who can read the bytes. Mark sensitive ones `transient`.

## 7. When you need it, and when you don't

|Situation|Needs `Serializable`?|
|---|---|
|`ObjectOutputStream` / `ObjectInputStream`|Yes|
|RMI|Yes|
|`HttpSession` attributes (session replication)|Yes|
|Spring Data Redis with the default JDK serializer|Yes|
|**Spring Boot `@RequestBody` / `@RestController` (Jackson)**|**No**|
|JPA entities saved to a database|**No** (Hibernate maps fields to columns)|
|Protobuf / Avro|**No** (their own generated classes)|

So for the Spring Boot flow we discussed, your DTOs and entities don't need `implements Serializable`. Jackson reads getters and constructors by reflection and never asks for the stamp.

The one place you'll often add it in Spring projects is an entity or object that gets cached (Redis, or an HTTP session). A common practice there is to switch Redis to a JSON serializer instead, which removes the requirement and avoids the native-serialization security risks.

## 8. Quick decision rule

```
Using ObjectOutputStream / sessions / JDK-serialized cache?
   └─ yes → every class in the graph: implements Serializable (+ serialVersionUID),
            and mark what shouldn't travel as transient
   └─ no, using Jackson / JSON / DB → don't bother
```




[[Serialization]]