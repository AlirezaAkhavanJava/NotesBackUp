


# **SQL to Java Data Types – Complete Guide**

This is a cheat sheet for Java backend development using SQL databases (PostgreSQL, MySQL, etc.). It includes types, mapping, examples, and tips for real projects.

---

## **1. Numeric Types**

|SQL Type|Java Type|Example & Usage|
|---|---|---|
|`INT` / `INTEGER`|`int` / `Integer`|`Integer id = 101;``int id = 101;`|
|`BIGINT`|`long` / `Long`|`Long userId = 1000000000L;`|
|`SMALLINT`|`short` / `Short`|`Short level = 5;`|
|`TINYINT`|`byte` / `Byte`|`Byte flag = 1; // for boolean 0/1`|
|`DECIMAL(p,s)` / `NUMERIC(p,s)`|`BigDecimal`|`BigDecimal price = new BigDecimal("99.99");`✅ Use for money calculations.|
|`FLOAT` / `REAL`|`float` / `Float`|`Float f = 3.14f;`|
|`DOUBLE` / `DOUBLE PRECISION`|`double` / `Double`|`Double d = 3.14159265359;`|

**Tips:**

- Use wrapper classes (`Integer`, `Long`, etc.) for nullable columns.
    
- Never use `double` for money → use `BigDecimal`.
    

**Example:**

```java
BigDecimal salary = new BigDecimal("1500.75");
int age = 25;
Integer nullableAge = null; // maps to SQL INT nullable column
```

---

## **2. String / Text Types**

|SQL Type|Java Type|Example & Usage|
|---|---|---|
|`CHAR(n)`|`String`|`String code = "A123";` (padded in DB if shorter)|
|`VARCHAR(n)`|`String`|`String name = "John";`|
|`TEXT` / `CLOB`|`String`|`String description = "Long text...";`|

**Example:**

```java
String username = "ethan";
String bio = "I am a backend programmer learning SQL & Java.";
```

**Tip:** Always prefer `VARCHAR` over `CHAR` unless you have strict fixed-length requirements.

---

## **3. Date and Time Types**

|SQL Type|Java Type|Example & Usage|
|---|---|---|
|`DATE`|`java.util.Date` / `java.sql.Date` / `LocalDate`|`LocalDate birth = LocalDate.of(2025, 7, 12);`|
|`TIME`|`java.util.Date` / `java.sql.Time` / `LocalTime`|`LocalTime join = LocalTime.of(9, 0);`|
|`TIMESTAMP` / `DATETIME`|`java.util.Date` / `java.sql.Timestamp` / `LocalDateTime`|`LocalDateTime created = LocalDateTime.now();`|

**Examples:**

```java
// Using java.time API (recommended)
LocalDate dob = LocalDate.of(1995, 10, 22);
LocalTime joiningTime = LocalTime.of(9, 30);
LocalDateTime createdAt = LocalDateTime.now();

// Using java.util.Date for legacy code
Date date = new GregorianCalendar(2025, Calendar.JULY, 12).getTime();
```

**Tip:** Always prefer `java.time` (Java 8+) for cleaner, safer code. Convert to `java.util.Date` only if the library requires it.

---

## **4. Boolean Types**

|SQL Type|Java Type|Example & Usage|
|---|---|---|
|`BOOLEAN` / `BIT` / `TINYINT(1)`|`boolean` / `Boolean`|`Boolean isActive = true;`|

**Tip:** Use `Boolean` if column is nullable.

---

## **5. Binary / Blob Types**

|SQL Type|Java Type|Example & Usage|
|---|---|---|
|`BLOB` / `BYTEA`|`byte[]`|Storing images, files, documents|

**Example:**

```java
byte[] fileData = Files.readAllBytes(Paths.get("image.png"));
```

---

## **6. JSON / UUID**

|SQL Type|Java Type|Example & Usage|
|---|---|---|
|`JSON` / `JSONB`|`String` / custom mapping|Store JSON as `String` or map to Object with libraries like Jackson|
|`UUID`|`java.util.UUID`|`UUID id = UUID.randomUUID();`|

**Example:**

```java
UUID userId = UUID.randomUUID();
String jsonData = "{\"name\":\"John\",\"age\":20}";
```

---

## **7. How to Use in a JPA Entity**

Here’s a full example mapping all types in a **Spring Boot Entity**:

```java
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
public class Students {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private LocalDate birthdate;     // DATE
    private LocalTime joiningtime;   // TIME
    private boolean isactive;        // BOOLEAN
    private double mark;             // DOUBLE
    private int age;                 // INT
    private String country;          // VARCHAR
    private BigDecimal price;        // DECIMAL
    private UUID uuid;               // UUID
    private String profileJson;      // JSON as String
}
```

**Builder Example (Lombok):**

```java
Students student = Students.builder()
        .id(1L)
        .name("John")
        .birthdate(LocalDate.of(2025, 7, 12))
        .joiningtime(LocalTime.of(9, 0))
        .isactive(true)
        .mark(95.5)
        .age(20)
        .country("USA")
        .price(new BigDecimal("1000.0"))
        .uuid(UUID.randomUUID())
        .profileJson("{\"hobby\":\"coding\"}")
        .build();
```

---

## **8. Quick Mapping Summary (For Your Brain 🧠)**

- **Numbers:** INT → int/Integer, BIGINT → long/Long, DECIMAL → BigDecimal
    
- **Text:** CHAR/VARCHAR/TEXT → String
    
- **Date/Time:** DATE → LocalDate, TIME → LocalTime, TIMESTAMP → LocalDateTime
    
- **Boolean:** BOOLEAN → boolean/Boolean
    
- **Binary:** BLOB → byte[]
    
- **Special:** UUID → UUID, JSON → String / Object
    

---




### Tags : [[0 - Spring Framework]]