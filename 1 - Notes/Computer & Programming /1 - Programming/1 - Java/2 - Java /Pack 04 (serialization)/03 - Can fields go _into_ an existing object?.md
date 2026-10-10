


> "can the state from object A be poured into an object that already exists, instead of creating a new one?" 

## Short answer

- **Native Java serialization: no.** Deserialization always creates a **new** object.
- **Jackson (JSON): yes**, you can update an existing object.

## 1. Native serialization always makes a new object

Think of the bytes as an order form, not a delivery. The JVM never opens an existing house and rewrites it. It builds a fresh one every time.

```java
Person existing = new Person("Bob", 40);
Person fromBytes = (Person) in.readObject();   // brand-new object

existing == fromBytes   // false, always
```

There is no `in.readInto(existing)` method. Even in `Externalizable`, `readExternal` is called on a fresh instance that the JVM just created through your no-arg constructor.

**The one trick:** `readResolve()` lets you throw away the fresh object and return an existing one instead. It's how singletons survive deserialization. But that swaps the object, it does not merge fields into it.

## 2. Jackson can update an existing object

JSON libraries are not tied to the JVM's serialization machinery, so they offer this:

```java
Person existing = new Person("Bob", 40);

new ObjectMapper()
    .readerForUpdating(existing)
    .readValue("{\"age\": 41}");

// existing is the SAME object, now name="Bob", age=41
```

Only the fields present in the JSON are overwritten. This is exactly what a **PATCH** endpoint needs: "change just these fields on the object that already exists."

Mental model:

```
Native:   bytes ──▶ NEW object
Jackson:  json  ──▶ NEW object      (default)
          json  ──▶ EXISTING object (readerForUpdating, only the listed fields)
```

## 3. The other meaning: an object _inside_ an object

If you meant "can object A travel as a field inside object B", then yes, and it's automatic. This is the object graph from the notes:

```java
class Order implements Serializable {
    Person customer;      // Person travels together with Order
}
```

Serialize `Order`, and `customer` goes with it. On the other side you get a new `Order` containing a new `Person`. Both classes must be `Serializable`, or you get `NotSerializableException`.

## Gotchas

- **Immutable objects and records can't be updated in place.** Their fields are final, so "update" really means creating a new record with changed values. This is one reason records and `readerForUpdating` don't mix well.
- **Concurrency:** updating a live object that other threads are using can expose half-updated state. Creating a new object and swapping the reference is safer.
- **Security and validation:** updating in place can bypass the setters or constructor checks you rely on, just like native deserialization bypasses constructors.
- **JPA entities:** Spring has a similar "copy fields into an existing object" need, for example loading an entity, then copying incoming DTO fields onto it. People do this with `BeanUtils.copyProperties` or MapStruct's `@MappingTarget`. It is the same idea as `readerForUpdating`, but between two Java objects, with no bytes involved.




[[Serialization]]
