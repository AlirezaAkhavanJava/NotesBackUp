
Generics in Java are a way to write reusable, type-safe code by allowing classes, interfaces, and methods to operate on different data types without sacrificing compile-time type checking.

---

## 🌟 What Are Generics?

- **Definition**: Generics mean _parameterized types_. Instead of writing separate versions of code for each data type, you can use a type parameter (like `<T>`) that acts as a placeholder [GeeksForGeeks](https://www.geeksforgeeks.org/java/generics-in-java/) [W3School](https://www.w3schools.com/java/java_generics.asp).
- **Purpose**:
    - **Type Safety**: Catch type errors at compile time instead of runtime.
    - **Code Reusability**: One class or method can work with multiple data types.
    - **Cleaner Code**: No need for explicit casting when retrieving objects [W3School](https://www.w3schools.com/java/java_generics.asp) [FreeCodecamp](https://www.freecodecamp.org/news/generics-in-java/).

---

## 🛠️ Key Features of Generics

- **Generic Classes**: Classes that can work with any type.
    
    ```java
    class Box<T> {
        T value;
        void set(T value) { this.value = value; }
        T get() { return value; }
    }
    
    public class Main {
        public static void main(String[] args) {
            Box<String> stringBox = new Box<>();
            stringBox.set("Hello");
            System.out.println(stringBox.get());
    
            Box<Integer> intBox = new Box<>();
            intBox.set(50);
            System.out.println(intBox.get());
        }
    }
    ```
    
    Here, `T` is a type parameter that can be replaced with `String`, `Integer`, etc. [W3School](https://www.w3schools.com/java/java_generics.asp).
    
- **Generic Methods**: Methods that can accept arguments of different types.
    
    ```java
    public static <T> void printArray(T[] array) {
        for (T item : array) {
            System.out.println(item);
        }
    }
    ```
    
    This method works for arrays of `String`, `Integer`, `Double`, etc. [W3School](https://www.w3schools.com/java/java_generics.asp).
    
- **Bounded Types**: Restrict the type parameter to certain classes.
    
    ```java
    class Stats<T extends Number> {
        T[] nums;
        Stats(T[] nums) { this.nums = nums; }
        double average() {
            double sum = 0;
            for (T num : nums) sum += num.doubleValue();
            return sum / nums.length;
        }
    }
    ```
    
    Here, `T` must be a subclass of `Number` [W3School](https://www.w3schools.com/java/java_generics.asp).
    

---

## 📊 Comparison Table

|Feature|Without Generics|With Generics|
|---|---|---|
|**Type Safety**|Errors at runtime|Errors caught at compile time|
|**Casting**|Manual casting required|No casting needed|
|**Reusability**|Separate code for each type|One code works for multiple types|
|**Readability**|More cluttered|Cleaner and more maintainable|

---

## ⚠️ Limitations of Generics

- Cannot use **primitive types** directly (e.g., `int`, `double`). Must use wrapper classes (`Integer`, `Double`) [GeeksForGeeks](https://www.geeksforgeeks.org/java/generics-in-java/).
- Type information is erased at runtime (called **type erasure**), meaning generics exist only at compile time [GeeksForGeeks](https://www.geeksforgeeks.org/java/generics-in-java/).

---

✅ **In short:** Generics in Java let you write flexible, reusable, and type-safe code by parameterizing types. They are widely used in collections (`ArrayList<String>`, `HashMap<Integer, String>`) and custom classes/methods.



###### Tags : [[1 - Collection interface 🤑]]