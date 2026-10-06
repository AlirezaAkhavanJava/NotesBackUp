
Java Serialization becomes much easier once you stop thinking of it as “some magic Java feature” and think of it as a **process for representing an object graph as a byte stream**.

Your mental model should be:

```text
Java object
   ↓
Serialization
   ↓
byte stream
   ↓
file / network / other storage
   ↓
Deserialization
   ↓
Java object
```

## 1. What is Java Serialization?

### Definition

**Serialization** is the process of converting the state of a Java object, including the reachable object graph, into a byte stream.

**Deserialization** is the reverse process: reading that byte stream and reconstructing the objects.

For example:

```java
Person p = new Person("John", 83);
```

Conceptually:

```text
Person object
    name = "John"
    age = 83
        ↓
serialization
        ↓
101010001010100101...
```

Later:

```text
101010001010100101...
        ↓
deserialization
        ↓
Person object
    name = "John"
    age = 83
```

The important word is **state**.

You're not converting the Java source code into bytes. You're storing enough information to reconstruct the object's serialized state.

---

# 2. The scenario

Imagine you have an application that wants to save a `Person` object to disk.

```java
Person person = new Person("John", 83);
```

You want:

```text
Application
    ↓
Person object
    ↓
serialize
    ↓
person.ser
```

Then tomorrow:

```text
person.ser
    ↓
deserialize
    ↓
Person object
```

This is one of the simplest ways to understand serialization.

---

# 3. The class must be Serializable

Suppose:

```java
public class Person implements Serializable {

    private String name;
    private int age;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

`Serializable` is an interface from:

```java
java.io.Serializable
```

It is a **marker interface**.

That means it doesn't require you to implement methods like:

```java
serialize()
deserialize()
```

It simply tells Java:

> “Objects of this class are allowed to participate in Java's default serialization mechanism.”

So:

```java
public class Person implements Serializable
```

is essentially giving Java permission to serialize instances of `Person`.

---

# 4. Serialize the object

You use:

```java
ObjectOutputStream
```

Example:

```java
import java.io.*;

public class SenderApplication {

    Person person = new Person("John", 83);

    public void send() {
        File path = new File(
            "/mnt/hdd/Home/Programming Files/Java/DumJava/received.ser"
        );

        try (ObjectOutputStream out =
                 new ObjectOutputStream(new FileOutputStream(path))) {

            out.writeObject(person);

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

The important part is:

```java
out.writeObject(person);
```

That is where serialization happens.

---

# 5. What is `ObjectOutputStream`?

Think of it as:

> A stream that knows how to turn Java objects into a serialized byte representation.

Normally a file stream writes bytes:

```java
FileOutputStream
```

You could think of:

```text
Object
  ↓
ObjectOutputStream
  ↓
FileOutputStream
  ↓
Disk
```

So:

```java
new ObjectOutputStream(
    new FileOutputStream(path)
)
```

means:

```text
ObjectOutputStream
        ↓
FileOutputStream
        ↓
file
```

`ObjectOutputStream` is layered on top of another `OutputStream`.

This is the same stream-composition idea you see elsewhere in Java I/O.

---

# 6. Your original code had one important mistake

You had something like:

```java
new ObjectOutputStream(path.getoutput())
```

`File` doesn't provide `getoutput()`.

You need an actual output stream:

```java
new FileOutputStream(path)
```

So:

```java
new ObjectOutputStream(
    new FileOutputStream(path)
)
```

is correct.

---

# 7. Now deserialize it

Serialization:

```java
out.writeObject(person);
```

Deserialization uses:

```java
ObjectInputStream
```

Example:

```java
File path = new File(
    "/mnt/hdd/Home/Programming Files/Java/DumJava/received.ser"
);

try (ObjectInputStream in =
         new ObjectInputStream(new FileInputStream(path))) {

    Person person = (Person) in.readObject();

    System.out.println(person);

} catch (IOException | ClassNotFoundException e) {
    e.printStackTrace();
}
```

The important part:

```java
Object person = in.readObject();
```

`readObject()` returns:

```java
Object
```

so you commonly cast it:

```java
Person person = (Person) in.readObject();
```

---

# 8. Complete example

### Person

```java
import java.io.Serializable;

public class Person implements Serializable {

    private String name;
    private int age;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    @Override
    public String toString() {
        return "Person{name='%s', age=%d}"
                .formatted(name, age);
    }
}
```

### Serialize

```java
import java.io.*;

public class SenderApplication {

    public static void main(String[] args) {

        Person person = new Person("John", 83);

        File file = new File(
            "/mnt/hdd/Home/Programming Files/Java/DumJava/received.ser"
        );

        try (ObjectOutputStream out =
                 new ObjectOutputStream(new FileOutputStream(file))) {

            out.writeObject(person);

            System.out.println("Object serialized.");

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

### Deserialize

```java
import java.io.*;

public class ReceiverApplication {

    public static void main(String[] args) {

        File file = new File(
            "/mnt/hdd/Home/Programming Files/Java/DumJava/received.ser"
        );

        try (ObjectInputStream in =
                 new ObjectInputStream(new FileInputStream(file))) {

            Person person = (Person) in.readObject();

            System.out.println(person);

        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
}
```

Flow:

```text
SenderApplication
       │
       │ Person("John", 83)
       ▼
ObjectOutputStream
       │
       │ serialization
       ▼
received.ser
       │
       │ deserialization
       ▼
ObjectInputStream
       │
       ▼
Person("John", 83)
```

---

# 9. What exactly gets serialized?

Suppose:

```java
Person person = new Person("John", 83);
```

The **instance state** includes:

```text
name → "John"
age  → 83
```

Java serialization can serialize that state.

But consider:

```java
public class Person implements Serializable {

    private String name;
    private int age;

    private static String species = "Human";
}
```

`static` belongs to the **class**, not the particular object.

So it isn't serialized as part of the object's instance state.

---

# 10. `transient`

Sometimes you have a field that you explicitly do **not** want serialized.

Use:

```java
transient
```

Example:

```java
public class Person implements Serializable {

    private String name;
    private int age;

    private transient String password;

    public Person(String name, int age, String password) {
        this.name = name;
        this.age = age;
        this.password = password;
    }
}
```

When serialized:

```text
name     → serialized
age      → serialized
password → NOT serialized
```

After deserialization:

```java
password == null
```

for this `String` field.

Primitive transient fields get their default values:

```text
int     → 0
boolean → false
```

This is useful for things such as temporary data or values that should never be persisted in serialized form.

---

# 11. `serialVersionUID`

This is one of the most important concepts once you go beyond toy examples.

You can write:

```java
public class Person implements Serializable {

    private static final long serialVersionUID = 1L;

    private String name;
    private int age;
}
```

Think of `serialVersionUID` as a **version identifier for the serialized class definition**.

Imagine you serialize:

```java
Person
name = John
age = 83
```

Then later you modify the class:

```java
Person
name = John
age = 83
email = ...
```

Java can use `serialVersionUID` to determine whether the serialized data is compatible with the current class.

That's why explicitly declaring it is common practice:

```java
private static final long serialVersionUID = 1L;
```

---

# 12. Serialization can serialize an object graph

This is where things become interesting.

Suppose:

```java
class Person implements Serializable {

    String name;
    Address address;
}
```

and:

```java
class Address implements Serializable {

    String city;
}
```

Then:

```java
Person person = new Person();
person.address = new Address();
```

When you do:

```java
out.writeObject(person);
```

Java doesn't just serialize:

```text
Person
```

It follows the object's references:

```text
Person
 ├── name
 └── Address
       └── city
```

So the serialization process works with an **object graph**.

This is why the referenced objects generally also need to be serializable.

For example:

```java
class Person implements Serializable {
    Address address;
}
```

but:

```java
class Address {
}
```

can cause:

```text
NotSerializableException
```

when the object is written.

---

# 13. Serialization over a network

This is where the name **SenderApplication** starts making sense.

Imagine:

```text
Application A
     │
     │ Person object
     ▼
ObjectOutputStream
     │
     │ bytes
     ▼
Network / Socket
     │
     ▼
ObjectInputStream
     │
     ▼
Application B
```

You can use Java serialization over a socket.

### Sender

```java
Socket socket = new Socket("localhost", 5000);

ObjectOutputStream out =
        new ObjectOutputStream(socket.getOutputStream());

out.writeObject(person);

out.close();
socket.close();
```

### Receiver

```java
ServerSocket server = new ServerSocket(5000);

Socket socket = server.accept();

ObjectInputStream in =
        new ObjectInputStream(socket.getInputStream());

Person person = (Person) in.readObject();

System.out.println(person);
```

Now serialization isn't about a file.

The destination is:

```text
socket
```

instead of:

```text
file
```

That's an important concept:

`ObjectOutputStream` doesn't inherently mean "write to a file."

It means:

> serialize objects into an `OutputStream`.

That output stream could represent:

```text
File
Socket
ByteArray
Compressed stream
Encrypted stream
...
```

---

# 14. Very important: Java Serialization vs JSON

You're working with Spring Boot, so this distinction matters a lot.

Suppose frontend sends:

```json
{
    "title": "Learn Java",
    "priority": 5
}
```

Spring receives JSON:

```text
JSON
 ↓
HTTP
 ↓
@RequestBody
 ↓
DTO
```

That's **not Java Serialization**.

Usually the flow is:

```text
Frontend
   ↓
JSON
   ↓
HTTP
   ↓
Spring/Jackson
   ↓
DTO
```

Java Serialization is more like:

```text
Java Object
   ↓
ObjectOutputStream
   ↓
Java serialized byte stream
```

So don't confuse:

```text
JSON serialization
```

with:

```text
Java native serialization
```

Both are serialization in the broad sense, but they use completely different formats and mechanisms.

---

# 15. Why would you use Java Serialization?

Historically, it has been used for things like:

```text
Java object
   ↓
serialize
   ↓
store/send
   ↓
deserialize
```

For example:

### Saving object state

```text
Application
   ↓
Person object
   ↓
person.ser
```

### Java-to-Java communication

```text
Java Application A
       ↓
serialized object
       ↓
Java Application B
```

### Caching / session-style mechanisms

Certain Java systems and frameworks have used serialization to preserve Java object state.

---

# 16. Why you usually DON'T use it for REST APIs

Suppose your Spring Boot backend has:

```java
@PostMapping("/users")
public UserDto create(@RequestBody CreateUserDto dto) {
    ...
}
```

Your frontend doesn't want a Java-specific serialized object.

It wants a portable format:

```json
{
    "name": "John",
    "age": 83
}
```

JSON works across:

```text
Java
JavaScript
TypeScript
Python
Go
C#
Rust
...
```

Java serialization is much more Java-specific.

So:

```text
REST API → JSON
Java internal persistence/communication → Java serialization may be appropriate
```

But even inside Java systems, there are often better alternatives depending on the architecture.

---

# 17. Custom serialization

You can take control of how an object is serialized.

For example:

```java
private void writeObject(ObjectOutputStream out)
        throws IOException {

    out.defaultWriteObject();

    // custom logic
}
```

And:

```java
private void readObject(ObjectInputStream in)
        throws IOException, ClassNotFoundException {

    in.defaultReadObject();

    // custom logic
}
```

This allows you to customize serialization behavior.

Mental model:

```text
defaultWriteObject()
        ↓
Java's normal serialization
```

plus:

```text
your custom logic
```

This is an advanced feature, not something you need for basic serialization.

---

# 18. The complete mental model

When you write:

```java
out.writeObject(person);
```

think:

```text
                  Java Heap
                     │
                     ▼
              Person object
                     │
              object graph
                     │
                     ▼
           ObjectOutputStream
                     │
               serialization
                     │
                     ▼
                byte stream
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
        File                  Socket
          │                     │
          └──────────┬──────────┘
                     ▼
           ObjectInputStream
                     │
               deserialization
                     │
                     ▼
           reconstructed object
```

---

# 19. The vocabulary you should know

|Term|Meaning|
|---|---|
|**Serialization**|Converting an object's state/object graph into a byte stream|
|**Deserialization**|Reconstructing objects from that byte stream|
|**Serializable**|Marker interface enabling default Java serialization|
|**ObjectOutputStream**|Writes serialized objects|
|**ObjectInputStream**|Reads serialized objects|
|**`writeObject()`**|Serializes an object|
|**`readObject()`**|Deserializes an object|
|**`transient`**|Excludes a field from default serialization|
|**`serialVersionUID`**|Version identifier used for serialization compatibility|
|**Object graph**|An object plus objects reachable through its references|
|**Byte stream**|Sequence of bytes representing the serialized data|

---

# 20. One subtle but important point

Serialization does **not** mean:

```text
Java object → arbitrary raw bytes
```

It's actually closer to:

```text
Java object graph
       ↓
Java Serialization Format
       ↓
byte stream
```

The stream contains structured information needed to reconstruct the objects.

So when you open:

```text
received.ser
```

in a text editor, you're likely to see garbage-looking binary data.

That's expected.

---

## 21. A professional warning

Do **not** deserialize arbitrary untrusted data with:

```java
ObjectInputStream
```

Native Java deserialization has a long history of serious security problems when attackers can control the serialized input.

For untrusted network input, prefer a controlled data format such as JSON and validate it. Where native serialization is unavoidable, Java provides serialization filtering mechanisms to restrict what classes may be deserialized.

---

## The workflow to memorize

```text
1. Make class Serializable
       ↓
2. Create object
       ↓
3. Create OutputStream
       ↓
4. Wrap it with ObjectOutputStream
       ↓
5. writeObject()
       ↓
6. bytes are stored/sent
       ↓
7. Create InputStream
       ↓
8. Wrap it with ObjectInputStream
       ↓
9. readObject()
       ↓
10. reconstructed Java object
```

The next useful step is to understand **what exactly is inside the `.ser` byte stream and what happens inside the JVM during `writeObject()` and `readObject()`**, because that's where Java Serialization stops being mysterious and starts becoming a real JVM concept.


[[Serialization]]