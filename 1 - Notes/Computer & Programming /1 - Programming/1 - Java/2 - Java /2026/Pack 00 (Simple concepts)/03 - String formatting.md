## String formatting in Java

**String formatting** means creating a string with values inserted into a predefined template instead of manually concatenating strings.

Java provides this mainly through:

- `String.format()`
    
- `Formatter`
    
- `System.out.printf()`
    

---

## 1. Basic `String.format()`

Syntax:

```java
String result = String.format("format", values);
```

Example:

```java
String name = "Ali";
int age = 25;

String message = String.format("My name is %s and I am %d years old.", name, age);

System.out.println(message);
```

Output:

```
My name is Ali and I am 25 years old.
```

---

# Format specifiers

A **format specifier** starts with `%` and tells Java how to convert a value into text.

|Specifier|Type|Example|
|---|---|---|
|`%s`|String|`"Java"`|
|`%d`|Integer|`123`|
|`%f`|Floating point|`5.236`|
|`%b`|Boolean|`true`|
|`%c`|Character|`'A'`|
|`%n`|New line|platform-independent newline|

---

## `%s` → String

```java
String language = "Java";

System.out.printf("Language: %s", language);
```

Output:

```
Language: Java
```

---

## `%d` → Integer

```java
int count = 10;

System.out.printf("Count: %d", count);
```

Output:

```
Count: 10
```

---

## `%f` → Floating point

```java
double price = 5.23642;

System.out.printf("Price: %f", price);
```

Output:

```
Price: 5.236420
```

Default precision is **6 decimal places**.

---

## Controlling decimal places

```java
double price = 5.23642;

System.out.printf("%.2f", price);
```

Output:

```
5.24
```

Meaning:

```
% . 2 f
│ │ │ │
│ │ │ └── floating point
│ │ └──── two digits after decimal
│ └────── precision
└──────── format start
```

---

# Width and alignment

## Right aligned

```java
System.out.printf("%10s", "Java");
```

Output:

```
      Java
```

`10` means minimum width of 10 characters.

---

## Left aligned

Use `-`:

```java
System.out.printf("%-10s", "Java");
```

Output:

```
Java      
```

---

# Multiple values

```java
String product = "Laptop";
double price = 999.99;

System.out.printf(
    "Product: %s, Price: %.2f",
    product,
    price
);
```

Output:

```
Product: Laptop, Price: 999.99
```

---

# Escaping `%`

If you want to print the `%` character:

```java
System.out.printf("Battery: 90%%");
```

Output:

```
Battery: 90%
```

---

# Modern Java alternative: `formatted()` (Java 15+)

Instead of:

```java
String.format("Hello %s", name);
```

you can write:

```java
"Hello %s".formatted(name);
```

Example:

```java
String user = "Ali";

String message = "Welcome %s".formatted(user);

System.out.println(message);
```

Output:

```
Welcome Ali
```

---

## Professional usage

In backend applications:

```java
String log = String.format(
    "User %s created task with id %d",
    username,
    taskId
);
```

However, for logging frameworks like Spring Boot:

```java
logger.info("User {} created task {}", username, taskId);
```

is preferred because it avoids unnecessary string creation when the log level is disabled.



[[Java]]