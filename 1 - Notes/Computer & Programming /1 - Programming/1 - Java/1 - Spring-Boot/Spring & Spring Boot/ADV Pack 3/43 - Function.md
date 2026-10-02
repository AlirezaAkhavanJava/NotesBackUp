

## **1. Definition**

`Function<T, R>` is a **functional interface** that represents a function which:

- Takes an input of type `T`
    
- Returns a result of type `R`
    

It’s part of Java’s **functional programming** utilities (introduced in Java 8).

---

## **2. Key Method**

```java
R apply(T t);
```

- `T t` → input
    
- Returns `R` → output
    

Optional default methods:

- `andThen(Function<? super R,? extends V> after)` → chains functions: f1.andThen(f2)
    
- `compose(Function<? super V,? extends T> before)` → f1.compose(f2)
    

---

## **3. Example**

```java
import java.util.function.Function;

public class FunctionExample {
    public static void main(String[] args) {
        // Function: Integer -> String
        Function<Integer, String> intToString = i -> "Number: " + i;

        String result = intToString.apply(10);
        System.out.println(result); // Output: Number: 10

        // Chaining functions
        Function<String, String> addExclamation = s -> s + "!";
        Function<Integer, String> combined = intToString.andThen(addExclamation);

        System.out.println(combined.apply(5)); // Output: Number: 5!
    }
}
```

---

## **4. Where it’s useful**

- **Streams API**: mapping elements
    
- **Lambda expressions**: passing behavior
    
- **Functional programming** patterns
    

**Example with Stream:**

```java
List<Integer> nums = List.of(1, 2, 3);
List<String> strings = nums.stream()
                           .map(i -> "Num:" + i) // uses Function<Integer, String>
                           .toList();
```

---

###### Tags : [[1 - Spring Security 🍌]]