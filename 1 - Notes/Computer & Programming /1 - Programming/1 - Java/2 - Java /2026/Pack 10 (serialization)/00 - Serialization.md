
[Official Youtube video](https://www.youtube.com/watch?v=2sxK-z84Oi4)

**Mental model:** serialization takes a snapshot of an object's state (its fields) and writes it as bytes. Deserialization rebuilds an object from that snapshot. Think of flat-pack furniture: you disassemble it (serialize), ship it, and reassemble it from the parts (deserialize). The reassembled object is a new object with the same state, not the same object.

![[1791179066.jpg]]

Use cases: saving objects to disk, sending them over a network, caching, and HTTP session replication.


> In Simple words :  **Serialization = converting an object's/state's data into a format that can be stored or transmitted, often as bytes.**


[Usefull video](https://www.youtube.com/watch?v=uS37TujnLRw)

---


## 1. The basics

Implement `Serializable`, a marker interface with no methods. It just tells the JVM "this class may be serialized".

```java
import java.io.*;

class Person implements Serializable {
    private static final long serialVersionUID = 1L;
    private String name;
    private int age;

    Person(String name, int age) { this.name = name; this.age = age; }
}

// Serialize
try (var out = new ObjectOutputStream(new FileOutputStream("person.ser"))) {
    out.writeObject(new Person("Alice", 25));
}

// Deserialize
try (var in = new ObjectInputStream(new FileInputStream("person.ser"))) {
    Person p = (Person) in.readObject();  // throws IOException, ClassNotFoundException
}
```

---

## 2. What actually gets serialized

|Member|Serialized?|
|---|---|
|Instance fields|Yes, if the field's type is serializable|
|`transient` fields|No. They get default values (`null`, `0`, `false`) after deserialization|
|`static` fields|No. They belong to the class, not the object|
|Methods|No. Only state is saved, never code|

**Gotchas**

- If a field's type is not `Serializable`, you get `NotSerializableException` at runtime, not at compile time.
- **The constructor is not called** for `Serializable` classes during deserialization. The JVM bypasses it, so validation in your constructor doesn't run. This is the root of many security problems (see section 6).
- **Parent classes:** if a parent is not `Serializable`, its fields are not saved. Instead, its **no-arg constructor** runs, so it must have an accessible one or deserialization fails.

---

## 3. `serialVersionUID`

A version stamp for the class. On deserialization, Java compares the stamp in the bytes with the one in the current class, and throws `InvalidClassException` if they differ.

```java
private static final long serialVersionUID = 1L;
```

- If you don't declare it, Java computes one from the class structure. Adding even a method can change it and break old data.
- If you declare it, you control compatibility. Compatible changes (such as adding a field) still load, and the new field gets its default value.
- Change the UID only when you deliberately want to reject old data.

---

## 4. Customizing serialization

There are four tools. Pick the lightest one that solves your problem.

### 4.1 `transient` (skip a field)

```java
private transient String password;  // sensitive or derived data
```

### 4.2 `writeObject` / `readObject` (hook into the default process)

Both are `private` and are found by reflection. Call the default behavior first, then add your own.

```java
private void writeObject(ObjectOutputStream out) throws IOException {
    out.defaultWriteObject();                    // writes non-transient fields
    out.writeObject(encrypt(password));          // password is transient
}

private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
    in.defaultReadObject();
    password = decrypt((String) in.readObject()); // must read in the same order written
}
```

Use it for encryption, handling transient fields, and validation.

### 4.3 `writeReplace` / `readResolve` (swap the object itself)

- `writeReplace()` serializes a different object in place of this one.
- `readResolve()` replaces the freshly deserialized object with another, which is how singletons and enums are kept unique.

```java
private Object readResolve() { return INSTANCE; }  // preserves the singleton
```

Without `readResolve`, deserializing a singleton creates a second instance.

### 4.4 `Externalizable` (take full control)

You write and read every field yourself, so nothing is automatic.

```java
class Person implements Externalizable {
    private String name; private int age;

    public Person() {}   // REQUIRED: public no-arg constructor

    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeUTF(name); out.writeInt(age);
    }
    public void readExternal(ObjectInput in) throws IOException {
        name = in.readUTF(); age = in.readInt();
    }
}
```

||`Serializable`|`Externalizable`|
|---|---|---|
|Field handling|Automatic|Manual|
|Constructor on read|Not called|Public no-arg is called|
|Format size|Larger|Smaller if you're careful|
|Risk|Less code, hidden behavior|More code, easy to make mistakes|

Use `Externalizable` only when you need a compact custom format. Most code never needs it.

---

## 5. Object graphs and references

Serializing one object serializes everything reachable from it. Java tracks objects it has already written, so:

- Shared references stay shared after deserialization (two fields pointing to the same object still point to one object).
- Circular references work without infinite loops.

**Gotcha:** one non-serializable object deep in the graph breaks the whole operation, and large graphs make serialization slow and the output big. Mark references you don't need as `transient`.

---

## 6. Security (the part that matters most)

Deserializing untrusted bytes is dangerous. Because constructors are bypassed, an attacker can craft a byte stream that builds objects in states your code never allows, and can chain classes already on your classpath ("gadget chains") into remote code execution. This is a long-standing source of real-world vulnerabilities.

**Defenses**

1. **Never deserialize untrusted data** with native Java serialization if you can avoid it.
2. **Use deserialization filters** (`ObjectInputFilter`), which allow only the classes you expect:
    
    ```java
    var filter = ObjectInputFilter.Config.createFilter("com.myapp.*;java.base/*;!*");in.setObjectInputFilter(filter);
    ```
    
    You can also set a JVM-wide filter with `-Djdk.serialFilter=...`.
3. **Validate state in `readObject`**, since the constructor didn't.
4. **Prefer alternatives** for data crossing trust boundaries: JSON (Jackson), Protocol Buffers, Avro. This is the mainstream advice, and it's also what you'll use in Spring Boot.

---

## 7. Modern Java

- **Records:** a record is serializable only if it declares `implements Serializable`. Serialization of records is safer by design. Deserialization goes through the **canonical constructor**, so your validation runs. `writeObject`/`readObject` are ignored for records, and `serialVersionUID` is not compared.
- **Enums:** always serialized by name, so they stay unique. No custom serialization is allowed.
- **Sealed classes:** sealing doesn't change how serialization works.
- **Virtual threads:** nothing special for serialization.

---

## 8. Best-practice checklist

1. Declare `serialVersionUID` explicitly.
2. Mark sensitive or derived fields `transient`.
3. Validate in `readObject` (or use a record so the constructor validates).
4. Use `readResolve` for singletons.
5. Apply `ObjectInputFilter` whenever you deserialize external data.
6. Choose `Externalizable` only when you need it.
7. Plan for class evolution, since old serialized data lives longer than your code expects.
8. For new designs, strongly consider JSON or Protobuf instead of native serialization.

---

## Corrections to the original notes

I changed a few claims that were inaccurate:

- **Records** are not automatically serializable "if all fields are": they must implement `Serializable`.
- **Sealed classes** and **virtual threads** have no serialization-specific behavior, so I removed them as "features".
- The `writeObject` example in the original wrote `age` twice (once by default, once manually), which is confusing, so I replaced it with a realistic transient-field example.

[[Java]]
[[19 - Serialization ✧]]
[[30 - Serializable]]
[[Serialization]]