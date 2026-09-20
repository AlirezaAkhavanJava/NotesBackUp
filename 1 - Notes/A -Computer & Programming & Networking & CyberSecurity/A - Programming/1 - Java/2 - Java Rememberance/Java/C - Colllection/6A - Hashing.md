
## **1. What is Hashing?**

**Hashing** is converting an input (key) into a fixed-size value (hash code) for efficient searching, insertion, and deletion. It's the foundation for data structures like `HashMap`, `HashSet`, and `Hashtable`.

---

## **2. Java's Built-in Hashing**

Every Java `Object` has a `hashCode()` method. Hash-based collections use this to quickly locate elements.

---

## **3. Custom Class with Hashing**

When using custom objects as keys in `HashMap`, you must override both `equals()` and `hashCode()`:

```java
class Person {
    private String name;
    private int age;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Person person = (Person) o;
        return age == person.age && name.equals(person.name);
    }

    @Override
    public int hashCode() {
        int result = name.hashCode();
        result = 31 * result + age;
        return result;
    }
}
```

**Usage:**

```java
import java.util.HashMap;

public class Main {
    public static void main(String[] args) {
        HashMap<Person, String> map = new HashMap<>();
        Person p1 = new Person("Alice", 30);
        map.put(p1, "Engineer");

        Person p2 = new Person("Alice", 30);
        System.out.println(map.get(p2)); // Output: Engineer
    }
}
```

---

## **4. How String Hashing Works**

Java's `String.hashCode()` uses a simple algorithm:

```java
public int hashCode() {
    int h = 0;
    for (int i = 0; i < value.length; i++) {
        h = 31 * h + value[i];
    }
    return h;
}
```

The multiplier **31** is chosen because it's odd, prime, and creates good hash distribution.

---

## **5. Simple Hash Table Implementation**

Here's a basic implementation with collision handling:

```java
class SimpleHashTable {
    private final int SIZE = 100;
    private String[] table = new String[SIZE];

    private int hash(String key) {
        return Math.abs(key.hashCode()) % SIZE;
    }

    public void put(String key, String value) {
        int index = hash(key);
        table[index] = value;
    }

    public String get(String key) {
        int index = hash(key);
        return table[index];
    }
}
```

---

## **6. Using Java's HashMap**

```java
import java.util.HashMap;

public class Example {
    public static void main(String[] args) {
        HashMap<String, Integer> map = new HashMap<>();
        map.put("apple", 1);
        map.put("banana", 2);
        map.put("orange", 3);
        
        System.out.println(map.get("apple"));  // Output: 1
        System.out.println(map.containsKey("banana")); // Output: true
    }
}
```

---

## **Key Takeaways**

✅ Always override both `hashCode()` and `equals()` for custom objects  
✅ Use `HashMap`/`HashSet` for production code  
✅ The hash code should be consistent and well-distributed  
✅ Collisions are handled internally by Java's collections



[[Java]]