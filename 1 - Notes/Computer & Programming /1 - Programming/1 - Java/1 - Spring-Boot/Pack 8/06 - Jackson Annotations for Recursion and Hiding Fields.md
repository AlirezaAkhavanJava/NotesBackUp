

All of these live in `com.fasterxml.jackson.annotation` (the `jackson-annotations` library). `spring-boot-starter-web` already includes it, so you don't add a dependency.

## Mental model: three groups

|Group|Goal|Annotations|
|---|---|---|
|**Break the loop**|Keep both sides, but stop the cycle|`@JsonManagedReference`, `@JsonBackReference`, `@JsonIdentityInfo`, `@JsonIdentityReference`, `@JsonIgnoreProperties`|
|**Hide data**|Remove fields or types from JSON|`@JsonIgnore`, `@JsonIgnoreType`, `@JsonView`|
|**Fine-tune**|Rename a field or make it read-only / write-only|`@JsonProperty`|

All examples use the `Customer` / `Order` entities from before.

---

## 1. `@JsonManagedReference`

**Definition:** Marks the **forward (parent) side** of a two-way link. It is serialized normally. It always works together with `@JsonBackReference`.

**Parameters:**

- `value` (String, default `"defaultReference"`): the name of the link. It must match the `value` of its `@JsonBackReference`.

**What it does:**

- Serialization: the annotated field is written to JSON as usual.
- Deserialization: after Jackson builds the child objects, it automatically sets the back-link on each child.

**How to use:** Put it on the **parent's collection or object field** (the `mappedBy` side).

**Example:**

```java
@Entity
public class Customer {
    @Id @GeneratedValue
    private Long id;
    private String name;

    @OneToMany(mappedBy = "customer")
    @JsonManagedReference
    private List<Order> orders = new ArrayList<>();
}
```

**Example explained:** When a `Customer` is serialized, `orders` is written normally. Each `Order` inside is serialized without its `customer` field (that is the back side's job), so the loop is cut.

**Rules:**

- It must be paired with exactly one `@JsonBackReference` of the same name.
- It can be placed on a collection, map, array, or single object.
- You can have several pairs in one class graph if each pair has a unique `value`.

**Related:** `@JsonBackReference` (next).

---

## 2. `@JsonBackReference`

**Definition:** Marks the **back (child) side** of the link. It is **omitted** from serialization.

**Parameters:**

- `value` (String, default `"defaultReference"`): must match the managed side's name.

**What it does:**

- Serialization: the field is skipped entirely.
- Deserialization: Jackson fills it in automatically from the parent that contains the child.

**How to use:** Put it on the **child's field that holds the parent** (the side with `@JoinColumn`).

**Example:**

```java
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "customer_id")
    @JsonBackReference
    private Customer customer;
}
```

**Example explained:** `Order` JSON is `{"id": 10}` with no `customer`. When you POST a `Customer` JSON with nested `orders`, Jackson sets `order.customer` on every nested order for you, which is why saving cascades work without manual wiring.

**Rules:**

- The back reference **cannot be a collection, map, or array**. It must be a single object (fine for `@ManyToOne`).
- It can only go on fields or methods, not constructor parameters.
- Direction is permanent: serializing an `Order` alone will never include its customer. If you need that, use DTOs or `@JsonIgnoreProperties`.

**Related:** `@JsonManagedReference`.

---

## 3. `@JsonIgnore`

**Definition:** Excludes a property from both serialization and deserialization.

**Parameters:**

- `value` (boolean, default `true`): if set to `false`, it cancels an ignore that would otherwise be inherited.

**What it does:** Jackson acts as if the property does not exist, both when writing JSON and when reading it.

**How to use:** On a field, getter, or setter.

**Example:**

```java
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String email;

    @JsonIgnore
    private String passwordHash;

    @OneToMany(mappedBy = "owner")
    @JsonIgnore
    private List<Post> posts;
}
```

**Example explained:** `passwordHash` never leaks into responses, and a client cannot set it by sending JSON. `posts` is hidden, which also cuts any loop through `Post.owner`.

**Rules:**

- Annotating **one** accessor (field, getter, or setter) ignores the **whole property** (all three), unless another accessor has an explicit `@JsonProperty`.
- It is all-or-nothing, in every context. If you need "hidden here, visible there," use `@JsonView` or DTOs.
- It hides input too. If you want hidden output but accepted input (like a password on signup), use `@JsonProperty(access = WRITE_ONLY)` instead.

**Related:** `@JsonProperty`, `@JsonIgnoreProperties`.

---

## 4. `@JsonIgnoreProperties`

**Definition:** Ignores specific properties, on a **class** or on a **field holding another object**.

**Parameters:**

- `value` (String[]): property names to ignore.
- `ignoreUnknown` (boolean, default `false`): on deserialization, silently skip JSON properties that don't exist in the class.
- `allowGetters` (boolean, default `false`): the listed properties are still serialized (read-only).
- `allowSetters` (boolean, default `false`): the listed properties are still deserialized (write-only).

**What it does:** Removes the named properties from JSON, with finer control than `@JsonIgnore`.

**How to use:** Two places, and the meaning differs.

**Example A, on a field (breaks the loop, keeps both directions):**

```java
@Entity
public class Order {
    @ManyToOne
    @JoinColumn(name = "customer_id")
    @JsonIgnoreProperties("orders")
    private Customer customer;
}
```

**Example A explained:** The names refer to properties **of the field's type** (`Customer`), not of `Order`. So when an `Order` is serialized, its `customer` is written **without** the customer's `orders`. Serializing a `Customer` still includes `orders`, and each order includes a customer (minus `orders`). No loop, and both directions work.

**Example B, on a class:**

```java
@JsonIgnoreProperties(ignoreUnknown = true)
public class CreateOrderRequest {
    private Long customerId;
}
```

**Example B explained:** If a client sends extra JSON fields, they are ignored instead of causing an error.

**Rules:**

- On a field, the names apply to the **nested object's** properties. This is the most common source of confusion.
- On a collection field, it applies to each element.
- Spring Boot already disables `FAIL_ON_UNKNOWN_PROPERTIES`, so `ignoreUnknown` is often unnecessary there.
- A common use with lazy-loading: `@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})` hides the Hibernate proxy's internal fields.

**Related:** `@JsonIgnore`, `@JsonIncludeProperties` (the opposite: a whitelist of properties to keep).

---

## 5. `@JsonIdentityInfo`

**Definition:** Gives objects an identity so Jackson writes each object **in full once**, then uses just its **id** for every repeat.

**Parameters:**

- `generator` (class): how ids are produced.
    - `ObjectIdGenerators.PropertyGenerator.class`: use an existing property (like `id`).
    - `ObjectIdGenerators.IntSequenceGenerator.class`: counter 1, 2, 3...
    - `ObjectIdGenerators.UUIDGenerator.class`: random UUIDs.
    - `ObjectIdGenerators.StringIdGenerator.class`: string ids.
- `property` (String, default `"@id"`): the JSON key that holds the id. With `PropertyGenerator`, it must name a real property.
- `scope` (Class, default `Object.class`): limits uniqueness of ids to a type.
- `resolver` (Class): advanced, for custom lookups during deserialization.

**What it does:** Turns a cycle into references. The loop ends because the second time Jackson meets an object, it writes only its id.

**How to use:** On the class (or on a field).

**Example:**

```java
@JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator.class, property = "id")
@Entity
public class Customer { /* id, name, orders */ }

@JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator.class, property = "id")
@Entity
public class Order { /* id, customer */ }
```

**Example explained:** Serializing a customer gives:

```json
{ "id": 1, "name": "Ali",
  "orders": [ { "id": 10, "customer": 1 },
              { "id": 11, "customer": 1 } ] }
```

The `1` inside each order is a reference to the customer already written above.

**Rules:**

- Put it on **both** classes in the cycle.
- The output shape depends on traversal order: whichever object is reached first is written in full.
- Clients must understand "a number here means a reference," which makes the API awkward.
- With `PropertyGenerator`, an unsaved entity with a `null` id produces bad output.

**Related:** `@JsonIdentityReference`, `ObjectIdGenerators`.

---

## 6. `@JsonIdentityReference`

**Definition:** Controls whether an identity-enabled object is written as an id **always**, or only on repeats.

**Parameters:**

- `alwaysAsId` (boolean, default `false`).

**What it does:** With `alwaysAsId = true`, the annotated field is always just the id, never the full object.

**How to use:** On a field (or class), where the target class has `@JsonIdentityInfo`.

**Example:**

```java
@Entity
public class Order {
    @ManyToOne
    @JoinColumn(name = "customer_id")
    @JsonIdentityReference(alwaysAsId = true)
    private Customer customer;
}
```

**Example explained:** Every order's JSON contains `"customer": 1`, matching the foreign key column in the database. This is a neat middle ground: the order exposes only the FK, with no nested customer.

**Rules:** It needs `@JsonIdentityInfo` on the target class, or the id can't be determined.

**Related:** `@JsonIdentityInfo`.

---

## 7. `@JsonIgnoreType`

**Definition:** Ignores **every property of a given type**, everywhere in the object graph.

**Parameters:**

- `value` (boolean, default `true`).

**What it does:** Any field whose type is this class is dropped from JSON.

**How to use:** On a class.

**Example:**

```java
@JsonIgnoreType
public class InternalAuditInfo { /* ... */ }

public class Document {
    private String title;
    private InternalAuditInfo audit;   // never serialized
}
```

**Example explained:** You annotate the type once instead of every field using it.

**Rules:** It affects all fields of that type, including in classes you didn't think of. Use it carefully. Don't put it on an entity you also return elsewhere.

**Related:** `@JsonIgnore` (per field).

---

## 8. `@JsonView`

**Definition:** Defines **named views** so different endpoints return different subsets of the same class.

**Parameters:**

- `value` (Class[]): one or more marker classes (usually empty interfaces) naming the view(s).

**What it does:** Fields are tagged with a view. When a view is active, only fields tagged with it (or a parent view) are written.

**How to use:**

1. Create marker interfaces.
2. Tag fields.
3. Activate the view on the Spring controller method.

**Example:**

```java
public class Views {
    public interface Summary {}
    public interface Detail extends Summary {}   // Detail includes Summary
}

@Entity
public class Customer {
    @JsonView(Views.Summary.class) private Long id;
    @JsonView(Views.Summary.class) private String name;

    @OneToMany(mappedBy = "customer")
    @JsonView(Views.Detail.class)
    private List<Order> orders;
}

@GetMapping("/customers")
@JsonView(Views.Summary.class)
public List<Customer> list() { ... }   // id, name only
```

**Example explained:** The list endpoint returns `id` and `name`. A detail endpoint annotated with `Views.Detail.class` also returns `orders`.

**Rules:**

- View classes inherit: `Detail extends Summary` means Detail shows both.
- In Spring Boot, fields **without** `@JsonView` are excluded when a view is active (`DEFAULT_VIEW_INCLUSION` is disabled by default).
- It limits what is shown but doesn't break loops by itself. You still need the nested side to be out of the active view.

**Related:** `ObjectMapper`, `MapperFeature.DEFAULT_VIEW_INCLUSION`.

---

## 9. `@JsonProperty`

**Definition:** Controls how a single property appears in JSON: its name, whether it is required, and whether it is read-only or write-only.

**Parameters:**

- `value` (String): the JSON name.
- `required` (boolean, default `false`): whether deserialization should fail if missing (mainly applies to constructor parameters).
- `index` (int): the order of properties in output.
- `defaultValue` (String): informational, mainly for schema generation.
- `access` (`JsonProperty.Access`): `AUTO` (default), `READ_ONLY`, `WRITE_ONLY`, `READ_WRITE`.

**What it does:** Renames properties, un-hides partially ignored ones, and sets direction.

**How to use:** On a field, getter, setter, or constructor parameter.

**Example:**

```java
@Entity
public class User {
    @Id @GeneratedValue
    @JsonProperty(access = JsonProperty.Access.READ_ONLY)
    private Long id;                       // output only, can't be set by client

    @JsonProperty("full_name")
    private String name;                   // JSON key is full_name

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String password;               // accepted on input, never output
}
```

**Example explained:** Clients can't forge an `id`. The JSON key `full_name` maps to the Java field `name`. The password can be submitted on signup but never appears in any response.

**Rules:**

- `WRITE_ONLY` is the correct tool for passwords. `@JsonIgnore` would block the input too.
- Explicit `@JsonProperty` on one accessor can override a `@JsonIgnore` on another, to un-hide just one direction.

**Related:** `@JsonIgnore`.

---

## Summary table

|Annotation|Goes on|Breaks loops?|Key parameter|
|---|---|---|---|
|`@JsonManagedReference`|Parent collection|Yes (with Back)|`value`|
|`@JsonBackReference`|Child's parent field|Yes (with Managed)|`value`|
|`@JsonIgnore`|Field / getter / setter|Yes (hides one side)|`value`|
|`@JsonIgnoreProperties`|Class or field|Yes (one level)|`value`, `ignoreUnknown`, `allowGetters`, `allowSetters`|
|`@JsonIdentityInfo`|Class|Yes (via ids)|`generator`, `property`, `scope`|
|`@JsonIdentityReference`|Field|Supports identity|`alwaysAsId`|
|`@JsonIgnoreType`|Class|Indirectly|none|
|`@JsonView`|Field + controller|Only if nested field is excluded|`value` (view classes)|
|`@JsonProperty`|Field / getter / setter|No|`value`, `access`, `required`, `index`|




[[Spring Framework]]