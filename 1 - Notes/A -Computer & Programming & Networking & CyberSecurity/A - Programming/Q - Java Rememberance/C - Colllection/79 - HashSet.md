
# HashSet in Java - Complete In-Depth Guide

---

## **1. WHAT IS HASHSET?**

**HashSet** is a class in the Java Collections Framework that implements the `Set` interface and uses a **hash table** for storage.

### **Key Definition:**
- Stores **unique elements only** (no duplicates)
- **Unordered** collection (no guaranteed iteration order)
- **Fast operations** - O(1) average time complexity
- **Allows one null** element
- **Not thread-safe** by default
- **Backed by HashMap** internally

---

## **2. CHARACTERISTICS & FEATURES**

| Feature | Details |
|---------|---------|
| **No Duplicates** | Adding duplicate elements has no effect |
| **No Ordering** | Elements not stored in insertion order |
| **Null Support** | Allows exactly ONE null element |
| **Thread-Safe** | ❌ Not synchronized (use `Collections.synchronizedSet()`) |
| **Internal Structure** | Uses HashMap (key = element, value = dummy object) |
| **Performance** | O(1) average for add, remove, contains |
| **Iteration** | O(n) - must visit each element |
| **Memory** | More memory per element than arrays |

---

## **3. HOW HASHSET WORKS INTERNALLY**

```
┌─────────────────────────────────────────────────┐
│           HashSet Internal Structure            │
├─────────────────────────────────────────────────┤
│                                                 │
│  HashSet (Frontend)                            │
│       ↓                                         │
│  HashMap (Backend)                             │
│       ↓                                         │
│  Hash Table (Array of Buckets)                │
│  ┌─────┬─────┬─────┬─────┬─────┐              │
│  │  0  │  1  │  2  │  3  │  4  │              │
│  └─────┴─────┴─────┴─────┴─────┘              │
│    ↓     ↓     ↓     ↓     ↓                   │
│   [A]   [B]   [C]  null  [D]                  │
│         ↓                                      │
│        [E]  (collision - chaining)            │
│                                                 │
└─────────────────────────────────────────────────┘
```

### **Step-by-Step Process:**

**When you add an element:**
1. **Calculate hash code** - `element.hashCode()`
2. **Map to bucket** - `bucket_index = hash % table_size`
3. **Check for duplicates** - Compare with elements using `equals()`
4. **Add if unique** - Insert into bucket (or chain if collision)

**When you search:**
1. **Calculate hash code**
2. **Find bucket**
3. **Linear search in bucket** (if collisions exist)
4. **Return true/false**

---

## **4. BASIC EXAMPLES**

### **4.1 Creating and Adding Elements**

```java
import java.util.HashSet;
import java.util.Set;

public class HashSetBasicExample {
    public static void main(String[] args) {
        // Create a HashSet
        HashSet<String> fruits = new HashSet<>();
        
        // Add elements
        fruits.add("Apple");
        fruits.add("Banana");
        fruits.add("Orange");
        fruits.add("Mango");
        
        System.out.println("HashSet: " + fruits);
        // Output: [Banana, Orange, Mango, Apple] (order not guaranteed)
        
        System.out.println("Size: " + fruits.size()); // 4
    }
}
```

---

### **4.2 No Duplicates**

```java
public class NoDuplicatesExample {
    public static void main(String[] args) {
        HashSet<Integer> numbers = new HashSet<>();
        
        // Try adding duplicates
        numbers.add(10);
        numbers.add(20);
        numbers.add(30);
        numbers.add(20);  // Duplicate - ignored
        numbers.add(10);  // Duplicate - ignored
        
        System.out.println("Numbers: " + numbers); // [20, 10, 30]
        System.out.println("Size: " + numbers.size()); // 3, not 5!
    }
}
```

---

### **4.3 Removing Duplicates from a List**

```java
import java.util.*;

public class RemoveDuplicatesExample {
    public static void main(String[] args) {
        // Original list with duplicates
        List<String> names = Arrays.asList(
            "Alice", "Bob", "Alice", "Carol", "Bob", "Dave"
        );
        
        System.out.println("Original list: " + names);
        // [Alice, Bob, Alice, Carol, Bob, Dave]
        
        // Convert to HashSet to remove duplicates
        Set<String> uniqueNames = new HashSet<>(names);
        
        System.out.println("Unique names: " + uniqueNames);
        // [Bob, Carol, Alice, Dave]
        
        // Convert back to list if needed
        List<String> uniqueList = new ArrayList<>(uniqueNames);
        System.out.println("As list: " + uniqueList);
    }
}
```

---

### **4.4 Null Handling**

```java
public class NullHandlingExample {
    public static void main(String[] args) {
        HashSet<String> set = new HashSet<>();
        
        set.add(null);      // First null - allowed
        set.add("value1");
        set.add(null);      // Second null - ignored (duplicate)
        
        System.out.println("Set: " + set); // [null, value1]
        System.out.println("Size: " + set.size()); // 2
        
        System.out.println("Contains null: " + set.contains(null)); // true
    }
}
```

---

## **5. CORE METHODS**

```java
public class HashSetMethodsExample {
    public static void main(String[] args) {
        HashSet<Integer> set = new HashSet<>(Arrays.asList(10, 20, 30, 40, 50));
        
        // add(E e) - adds element if not present
        boolean added = set.add(60);
        System.out.println("Added 60: " + added); // true
        added = set.add(10);
        System.out.println("Added 10 again: " + added); // false
        
        // contains(Object o) - checks if element exists
        System.out.println("Contains 20: " + set.contains(20)); // true
        System.out.println("Contains 100: " + set.contains(100)); // false
        
        // remove(Object o) - removes element
        boolean removed = set.remove(30);
        System.out.println("Removed 30: " + removed); // true
        removed = set.remove(100);
        System.out.println("Removed 100: " + removed); // false
        
        // size() - number of elements
        System.out.println("Size: " + set.size()); // 5
        
        // isEmpty() - checks if empty
        System.out.println("Is empty: " + set.isEmpty()); // false
        
        // clear() - removes all elements
        set.clear();
        System.out.println("After clear: " + set); // []
        System.out.println("Size after clear: " + set.size()); // 0
    }
}
```

**Output:**
```
Added 60: true
Added 10 again: false
Contains 20: true
Contains 100: false
Removed 30: true
Removed 100: false
Size: 5
Is empty: false
After clear: []
Size after clear: 0
```

---

## **6. ITERATION METHODS**

```java
import java.util.*;

public class HashSetIterationExample {
    public static void main(String[] args) {
        HashSet<String> colors = new HashSet<>(
            Arrays.asList("Red", "Green", "Blue", "Yellow")
        );
        
        // Method 1: For-each loop
        System.out.println("Method 1: For-each");
        for (String color : colors) {
            System.out.println("  " + color);
        }
        
        // Method 2: Iterator
        System.out.println("\nMethod 2: Iterator");
        Iterator<String> iterator = colors.iterator();
        while (iterator.hasNext()) {
            System.out.println("  " + iterator.next());
        }
        
        // Method 3: forEach() method
        System.out.println("\nMethod 3: forEach()");
        colors.forEach(color -> System.out.println("  " + color));
        
        // Method 4: Stream API
        System.out.println("\nMethod 4: Stream API");
        colors.stream()
              .forEach(color -> System.out.println("  " + color));
    }
}
```

---

## **7. PERFORMANCE ANALYSIS**

### **7.1 Time Complexity**

```java
public class PerformanceExample {
    public static void main(String[] args) {
        HashSet<Integer> set = new HashSet<>();
        
        // Measure add() performance - O(1)
        long startTime = System.nanoTime();
        for (int i = 0; i < 1_000_000; i++) {
            set.add(i);
        }
        long addTime = System.nanoTime() - startTime;
        System.out.println("Time to add 1M elements: " + (addTime / 1_000_000) + " ms");
        
        // Measure contains() performance - O(1)
        startTime = System.nanoTime();
        for (int i = 0; i < 1_000_000; i++) {
            set.contains(i);
        }
        long searchTime = System.nanoTime() - startTime;
        System.out.println("Time to search 1M times: " + (searchTime / 1_000_000) + " ms");
        
        // Measure remove() performance - O(1)
        startTime = System.nanoTime();
        for (int i = 0; i < 100_000; i++) {
            set.remove(i);
        }
        long removeTime = System.nanoTime() - startTime;
        System.out.println("Time to remove 100K elements: " + (removeTime / 1_000_000) + " ms");
    }
}
```

| Operation | Average | Worst Case | Why |
|-----------|---------|-----------|-----|
| **add()** | O(1) | O(n) | Hash collision |
| **remove()** | O(1) | O(n) | Hash collision |
| **contains()** | O(1) | O(n) | Hash collision |
| **Iteration** | O(n) | O(n) | Must visit each element |

---

## **8. WORKING WITH CUSTOM OBJECTS**

### **8.1 Using HashSet with Custom Classes**

```java
public class StudentHashSetExample {
    
    static class Student {
        int id;
        String name;
        
        Student(int id, String name) {
            this.id = id;
            this.name = name;
        }
        
        // CRITICAL: Must override hashCode() and equals()
        @Override
        public int hashCode() {
            return Objects.hash(id, name);
        }
        
        @Override
        public boolean equals(Object obj) {
            if (this == obj) return true;
            if (obj == null || getClass() != obj.getClass()) return false;
            Student other = (Student) obj;
            return id == other.id && name.equals(other.name);
        }
        
        @Override
        public String toString() {
            return "Student(" + id + ", " + name + ")";
        }
    }
    
    public static void main(String[] args) {
        HashSet<Student> students = new HashSet<>();
        
        Student s1 = new Student(1, "Alice");
        Student s2 = new Student(2, "Bob");
        Student s3 = new Student(1, "Alice"); // Duplicate
        
        students.add(s1);
        students.add(s2);
        students.add(s3); // Won't be added (duplicate)
        
        System.out.println("Students: " + students);
        System.out.println("Size: " + students.size()); // 2
        System.out.println("Contains s3: " + students.contains(s3)); // true
    }
}
```

**⚠️ CRITICAL RULE:**
```
When using custom objects in HashSet:
1. Override hashCode()
2. Override equals()
3. Ensure: if equals() returns true, hashCode() must return same value
```

---

### **8.2 ❌ WRONG - Not Overriding hashCode() and equals()**

```java
static class BadStudent {
    int id;
    String name;
    
    BadStudent(int id, String name) {
        this.id = id;
        this.name = name;
    }
    // NO hashCode() or equals() override!
}

public static void main(String[] args) {
    HashSet<BadStudent> set = new HashSet<>();
    
    BadStudent s1 = new BadStudent(1, "Alice");
    BadStudent s2 = new BadStudent(1, "Alice"); // Same data
    
    set.add(s1);
    set.add(s2);
    
    System.out.println("Size: " + set.size()); // 2 (WRONG! Should be 1)
    System.out.println("Contains s2: " + set.contains(s2)); // false (WRONG!)
}
```

---

## **9. HASHSET VS OTHER SETS**

| Feature | HashSet | LinkedHashSet | TreeSet |
|---------|---------|---------------|---------|
| **Order** | No | Insertion order | Sorted order |
| **Performance** | O(1) | O(1) | O(log n) |
| **Null** | 1 allowed | 1 allowed | Not allowed |
| **Thread-Safe** | No | No | No |
| **Use Case** | Fast lookup | Preserve order | Sorted iteration |

### **Comparison Example:**

```java
public class SetComparison {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(5, 2, 8, 2, 1, 8, 9);
        
        // HashSet - no order
        Set<Integer> hashSet = new HashSet<>(numbers);
        System.out.println("HashSet: " + hashSet);
        // [1, 2, 5, 8, 9] (order not guaranteed)
        
        // LinkedHashSet - insertion order
        Set<Integer> linkedSet = new LinkedHashSet<>(numbers);
        System.out.println("LinkedHashSet: " + linkedSet);
        // [5, 2, 8, 1, 9] (insertion order preserved)
        
        // TreeSet - sorted order
        Set<Integer> treeSet = new TreeSet<>(numbers);
        System.out.println("TreeSet: " + treeSet);
        // [1, 2, 5, 8, 9] (sorted)
    }
}
```

---

## **10. COMMON USE CASES**

### **10.1 Finding Unique Elements**

```java
List<String> emails = Arrays.asList(
    "alice@gmail.com", "bob@gmail.com", "alice@gmail.com", "carol@gmail.com"
);

Set<String> uniqueEmails = new HashSet<>(emails);
System.out.println("Unique emails: " + uniqueEmails.size()); // 3
```

### **10.2 Checking Membership (Fast Lookup)**

```java
Set<Integer> allowedIds = new HashSet<>(Arrays.asList(1, 2, 3, 4, 5));

int userId = 3;
if (allowedIds.contains(userId)) {
    System.out.println("User is authorized");
}
```

### **10.3 Set Operations (Union, Intersection, Difference)**

```java
public class SetOperationsExample {
    public static void main(String[] args) {
        Set<String> set1 = new HashSet<>(Arrays.asList("A", "B", "C"));
        Set<String> set2 = new HashSet<>(Arrays.asList("B", "C", "D"));
        
        // Union
        Set<String> union = new HashSet<>(set1);
        union.addAll(set2);
        System.out.println("Union: " + union); // [A, B, C, D]
        
        // Intersection
        Set<String> intersection = new HashSet<>(set1);
        intersection.retainAll(set2);
        System.out.println("Intersection: " + intersection); // [B, C]
        
        // Difference (A - B)
        Set<String> difference = new HashSet<>(set1);
        difference.removeAll(set2);
        System.out.println("Difference: " + difference); // [A]
    }
}
```

### **10.4 Graph Traversal (Visited Tracking)**

```java
public class GraphTraversalExample {
    
    static class Graph {
        Map<Integer, List<Integer>> adjacencyList = new HashMap<>();
        
        void addEdge(int u, int v) {
            adjacencyList.computeIfAbsent(u, k -> new ArrayList<>()).add(v);
        }
        
        void dfs(int node, Set<Integer> visited) {
            visited.add(node);
            System.out.println("Visited: " + node);
            
            for (int neighbor : adjacencyList.getOrDefault(node, new ArrayList<>())) {
                if (!visited.contains(neighbor)) {
                    dfs(neighbor, visited);
                }
            }
        }
    }
    
    public static void main(String[] args) {
        Graph graph = new Graph();
        graph.addEdge(0, 1);
        graph.addEdge(0, 2);
        graph.addEdge(1, 2);
        graph.addEdge(2, 3);
        
        Set<Integer> visited = new HashSet<>();
        graph.dfs(0, visited);
    }
}
```

---

## **11. THREAD-SAFE HASHSET**

```java
import java.util.*;

public class ThreadSafeHashSetExample {
    public static void main(String[] args) {
        // Non-thread-safe HashSet
        HashSet<String> regularSet = new HashSet<>();
        
        // Thread-safe version using Collections.synchronizedSet()
        Set<String> threadSafeSet = Collections.synchronizedSet(new HashSet<>());
        
        threadSafeSet.add("A");
        threadSafeSet.add("B");
        System.out.println("Thread-safe set: " + threadSafeSet);
    }
}
```

---

## **12. SENIOR DEVELOPER PATTERNS**

### **12.1 Builder Pattern for HashSet**

```java
public class HashSetBuilder {
    private Set<String> set = new HashSet<>();
    
    public HashSetBuilder add(String... elements) {
        Collections.addAll(set, elements);
        return this;
    }
    
    public HashSetBuilder addAll(Collection<String> elements) {
        set.addAll(elements);
        return this;
    }
    
    public Set<String> build() {
        return set;
    }
    
    public static void main(String[] args) {
        Set<String> result = new HashSetBuilder()
            .add("A", "B", "C")
            .add("D", "E")
            .build();
        
        System.out.println(result);
    }
}
```

### **12.2 Efficient Duplicate Removal**

```java
public class DuplicateRemover {
    
    // For primitive arrays
    public static int[] removeDuplicates(int[] arr) {
        return new HashSet<>(Arrays.stream(arr).boxed().collect(Collectors.toList()))
            .stream()
            .mapToInt(Integer::intValue)
            .toArray();
    }
    
    // For object lists
    public static <T> List<T> removeDuplicates(List<T> list) {
        return new ArrayList<>(new HashSet<>(list));
    }
    
    public static void main(String[] args) {
        int[] numbers = {1, 2, 2, 3, 4, 4, 5};
        System.out.println(Arrays.toString(removeDuplicates(numbers)));
        // [1, 2, 3, 4, 5]
    }
}
```

---

## **SUMMARY TABLE**

| Aspect | Details |
|--------|---------|
| **Definition** | Unordered collection of unique elements |
| **Backed by** | HashMap |
| **Add** | O(1) average |
| **Contains** | O(1) average |
| **Remove** | O(1) average |
| **Iteration** | O(n) |
| **Duplicates** | Not allowed |
| **Null** | 1 allowed |
| **Order** | Not guaranteed |
| **Thread-Safe** | No |
| **Best for** | Fast lookups, removing duplicates |

---

## **KEY TAKEAWAYS**

✅ **Use HashSet for:** Fast O(1) lookups and removing duplicates  
✅ **Always override** `hashCode()` and `equals()` for custom objects  
✅ **Remember:** HashSet order is not guaranteed  
✅ **Use LinkedHashSet** if you need insertion order  
✅ **Use TreeSet** if you need sorted order  
✅ **Not thread-safe** - wrap with `Collections.synchronizedSet()` if needed  




[[Java]]