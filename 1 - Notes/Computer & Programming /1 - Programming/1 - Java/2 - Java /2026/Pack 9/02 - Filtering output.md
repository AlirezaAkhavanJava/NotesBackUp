
In Java, "filtering output" like changing:

```
5.23642 → 5.23
```

is usually called **formatting** or **rounding**, not filtering.

There are several ways depending on what you need.

---

## 1. `printf()` formatting (display only)

If you only want to control how the number appears:

```java
double value = 5.23642;

System.out.printf("%.2f", value);
```

Output:

```
5.24
```

`%.2f` means:

- `%` → format placeholder
    
- `f` → floating-point number
    
- `.2` → show 2 digits after decimal
    

Note: it **rounds**.

---

## 2. `String.format()` (create formatted text)

```java
double value = 5.23642;

String result = String.format("%.2f", value);

System.out.println(result);
```

Output:

```
5.24
```

Useful when building messages:

```java
System.out.println("Price: $" + String.format("%.2f", price));
```

---

## 3. Truncating (cutting without rounding)

If you specifically want:

```
5.23642 → 5.23
```

not:

```
5.23642 → 5.24
```

use `BigDecimal`:

```java
import java.math.BigDecimal;
import java.math.RoundingMode;

double value = 5.23642;

BigDecimal result = BigDecimal.valueOf(value)
        .setScale(2, RoundingMode.DOWN);

System.out.println(result);
```

Output:

```
5.23
```

---

## 4. Using `DecimalFormat`

```java
import java.text.DecimalFormat;

double value = 5.23642;

DecimalFormat df = new DecimalFormat("#.00");

System.out.println(df.format(value));
```

Output:

```
5.24
```

---

## 5. Formatting in Spring Boot APIs

Usually you don't modify the number itself. You control serialization:

Example:

```java
@JsonFormat
private BigDecimal price;
```

or configure Jackson:

```java
objectMapper.setDefaultPropertyInclusion(...)
```

For money values, `BigDecimal` is preferred:

```java
private BigDecimal price = new BigDecimal("5.23642");
```

because `double` has floating-point precision problems.

---

### Summary

|Goal|Use|
|---|---|
|Display 2 decimals|`printf("%.2f")`|
|Create formatted string|`String.format()`|
|Round value|`BigDecimal.setScale(2, HALF_UP)`|
|Cut decimals|`BigDecimal.setScale(2, DOWN)`|
|Financial values|`BigDecimal`|

In professional Java applications (especially Spring Boot), use **`BigDecimal` for currency and precise decimal data**.


[[Java]]