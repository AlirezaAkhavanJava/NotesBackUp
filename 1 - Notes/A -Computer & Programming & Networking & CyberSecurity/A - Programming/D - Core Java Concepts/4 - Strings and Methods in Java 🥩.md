Date : 2025-09-04


This document covers everything about **Strings** in Java, including **String class, StringBuffer, StringBuilder**, and their methods.

---

## 1. `String` Class

### Characteristics

- Immutable → once created, cannot be changed.
    
- Stored in **String Pool** (special memory inside heap).

	![[Pasted image 20251122074632.png]]

### Creating Strings

```java
String s1 = "Hello"; // string literal (stored in String pool)
String s2 = new String("World"); // stored in heap
```

### Common Methods

```java
s.length();              // length of string
s.charAt(2);             // character at index
s.toUpperCase();         // convert to uppercase
s.toLowerCase();         // convert to lowercase
s.trim();                // remove leading/trailing spaces
s.substring(1, 4);       // substring
s.replace("a", "b");    // replace characters
s.contains("abc");      // check if contains substring
s.equals(str2);          // check equality (case-sensitive)
s.equalsIgnoreCase(str2);// check equality ignoring case
s.compareTo(str2);       // lexicographical comparison
s.split(",");           // split into array
```

---
>HashCode in Java is a **number that represents an object for fast lookup**. It’s not about identity or meaning—it’s about **speed**.
## 2. `StringBuffer`

### Characteristics

- Mutable (can be modified).
    
- ==**Thread-safe** → synchronized methods.==
    
- Slower than `StringBuilder`.
    

### Example

```java
StringBuffer sb = new StringBuffer("Hello");
sb.append(" World"); // Hello World
sb.insert(5, " Java");
sb.replace(0, 5, "Hi");
sb.delete(0, 2);
sb.reverse();
```

### Common Methods

- `append(str)` → adds to the end.
    
- `insert(offset, str)` → insert at position.
    
- `replace(start, end, str)` → replace range.
    
- `delete(start, end)` → delete characters.
    
- `reverse()` → reverse string.
    
- `capacity()` → storage capacity.
    
- `ensureCapacity(n)` → increase buffer capacity.
    

---

## 3. `StringBuilder`

### Characteristics

- Mutable like `StringBuffer`.
    
- **Not thread-safe** → no synchronization.
    
- Faster than `StringBuffer`.
    

### Example

```java
StringBuilder sb = new StringBuilder("Fast");
sb.append(" StringBuilder");
sb.reverse();
```

### Common Methods

(Same as `StringBuffer`)

---

## 4. When to Use?

- `String` → when data is constant/immutable.
    
- ==`StringBuffer` → when multiple threads modify string.==
    
- `StringBuilder` → when single-threaded string modifications.
    

---

## 5. Utility Classes for Strings

### `StringJoiner`

- Used for joining strings with delimiter and optional prefix/suffix.
    

```java
StringJoiner joiner = new StringJoiner(", ", "[", "]");
joiner.add("Java");
joiner.add("Python");
System.out.println(joiner); // [Java, Python]
```

### `StringTokenizer`

- Breaks string into tokens.
    

```java
StringTokenizer st = new StringTokenizer("apple orange banana");
while (st.hasMoreTokens()) {
    System.out.println(st.nextToken());
}
```

---

## 6. Conversion Between Types

- `String → int` → `Integer.parseInt("123")`
    
- `int → String` → `String.valueOf(123)`
    
- `String → char[]` → `s.toCharArray()`
    
- `char[] → String` → `new String(arr)`
    

---

## Summary

- **String** → immutable, stored in String pool.
    
- **StringBuffer** → mutable, thread-safe, slower.
    
- **StringBuilder** → mutable, non-thread-safe, faster.
    
- Use `StringJoiner` and `StringTokenizer` for special operations.
    

Strings are **fundamental in Java**, and choosing between `String`, `StringBuffer`, and `StringBuilder` depends on **immutability, performance, and thread-safety



##### *Tags : [[Java]]