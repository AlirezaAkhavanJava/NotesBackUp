Date : 2025-09-04


The Java Collections Framework (JCF) in the `java.util` package provides data structures to store and manipulate data efficiently. This guide covers arrays, collections, and algorithms, with a focus on practical implementations and Java features up to Java 25 (September 2025).

---

## Phase 1: Arrays & ArrayLists

### Data Structure: Dynamic Array

Arrays are fixed-size, while `ArrayList` and `Vector` are dynamic arrays that grow automatically.

### Algorithms to Master

- **Traversal**: Iterate over elements.
- **Insertion/Deletion**: Add/remove elements (`O(n)` for arrays, `O(1)` for `ArrayList` at end).
- **Searching**: Linear (`O(n)`), Binary (`O(log n)` for sorted arrays).
- **Sorting**: Selection, Bubble (`O(n²)`), Quick, Merge (`O(n log n)`).
- **Two-Pointer/Sliding Window**: Solve subarray problems efficiently.

### Java Collections

- **ArrayList**: Fast random access (`O(1)`), slow insert/delete in middle (`O(n)`).
- **Vector**: Synchronized `ArrayList`, rarely used.

**Example: Reverse an ArrayList**

```java
import java.util.ArrayList;

public class Main {
    public static void main(String[] args) {
        ArrayList<Integer> list = new ArrayList<>();
        list.add(1);
        list.add(2);
        list.add(3);
        Collections.reverse(list);
        System.out.println(list); // [3, 2, 1]
    }
}
```

**Practice: Rotate Array**

```java
import java.util.Arrays;

public class Main {
    public static void rotate(int[] arr, int k) {
        k %= arr.length;
        reverse(arr, 0, arr.length - 1);
        reverse(arr, 0, k - 1);
        reverse(arr, k, arr.length - 1);
    }

    private static void reverse(int[] arr, int start, int end) {
        while (start < end) {
            int temp = arr[start];
            arr[start++] = arr[end--];
        }
    }

    public static void main(String[] args) {
        int[] arr = {1, 2, 3, 4, 5};
        rotate(arr, 2);
        System.out.println(Arrays.toString(arr)); // [4, 5, 1, 2, 3]
    }
}
```

---

## Phase 2: Linked Lists

### Data Structure: Singly/Doubly Linked List

Linked lists store elements as nodes with pointers to the next (singly) or next/previous (doubly) node.

### Algorithms to Master

- **Traversal/Insertion/Deletion**: `O(n)` for access, `O(1)` for insert/delete at known positions.
- **Reverse**: Reverse a linked list in-place.
- **Detect Cycle**: Floyd’s cycle-finding algorithm.
- **Merge Sorted Lists**: Combine two sorted lists.

### Java Collection

- **LinkedList**: Doubly-linked, implements `List` and `Deque`.

**Example: Reverse a LinkedList**

```java
import java.util.LinkedList;

public class Main {
    public static void main(String[] args) {
        LinkedList<Integer> list = new LinkedList<>();
        list.add(1);
        list.add(2);
        list.add(3);
        Collections.reverse(list);
        System.out.println(list); // [3, 2, 1]
    }
}
```

**Practice: Custom LinkedList**

```java
class Node {
    int data;
    Node next;
    Node(int data) { this.data = data; }
}

public class MyLinkedList {
    Node head;

    public void add(int data) {
        Node newNode = new Node(data);
        if (head == null) head = newNode;
        else {
            Node curr = head;
            while (curr.next != null) curr = curr.next;
            curr.next = newNode;
        }
    }

    public void print() {
        Node curr = head;
        while (curr != null) {
            System.out.print(curr.data + " ");
            curr = curr.next;
        }
    }

    public static void main(String[] args) {
        MyLinkedList list = new MyLinkedList();
        list.add(1);
        list.add(2);
        System.out.println(); // 1 2
    }
}
```

---

## Phase 3: Stacks

### Data Structure: Array/Linked List

Stacks follow LIFO (Last-In-First-Out).

### Algorithms to Master

- **Push/Pop/Peek**: Add, remove, and view top element.
- **Expression Evaluation**: Convert infix to postfix, evaluate postfix.
- **Balanced Parentheses**: Check valid brackets.
- **Next Greater Element**: Find next larger element.

### Java Collections

- **Stack**: Legacy, extends `Vector`.
- **ArrayDeque**: Preferred for stack operations.

**Example: Balanced Parentheses**

```java
import java.util.ArrayDeque;

public class Main {
    public static boolean isValid(String s) {
        ArrayDeque<Character> stack = new ArrayDeque<>();
        for (char c : s.toCharArray()) {
            if (c == '(' || c == '{') stack.push(c);
            else if (stack.isEmpty() || (c == ')' && stack.pop() != '(') || (c == '}' && stack.pop() != '{')) return false;
        }
        return stack.isEmpty();
    }

    public static void main(String[] args) {
        System.out.println(isValid("({})")); // true
    }
}
```

**Practice: Browser History**

```java
import java.util.ArrayDeque;

public class BrowserHistory {
    private ArrayDeque<String> history = new ArrayDeque<>();
    
    public void visit(String url) {
        history.push(url);
    }
    
    public String back() {
        return history.isEmpty() ? null : history.pop();
    }
}
```

---

## Phase 4: Queues

### Data Structure: Array/Linked List

Queues follow FIFO (First-In-First-Out).

### Algorithms to Master

- **Enqueue/Dequeue/Peek**: Add, remove, view front element.
- **Sliding Window**: Process subarrays efficiently.
- **BFS**: Traverse graphs/trees level by level.

### Java Collections

- **Queue**: Interface, implemented by `LinkedList`, `ArrayDeque`.
- **ArrayDeque**: Efficient for queue operations.

**Example: Circular Queue**

```java
public class CircularQueue {
    private int[] arr;
    private int front, rear, size, capacity;

    public CircularQueue(int capacity) {
        this.arr = new int[capacity];
        this.capacity = capacity;
        this.front = this.rear = -1;
        this.size = 0;
    }

    public void enqueue(int value) {
        if (isFull()) return;
        if (isEmpty()) front = 0;
        rear = (rear + 1) % capacity;
        arr[rear] = value;
        size++;
    }

    public int dequeue() {
        if (isEmpty()) return -1;
        int value = arr[front];
        front = (front + 1) % capacity;
        size--;
        if (isEmpty()) front = rear = -1;
        return value;
    }

    public boolean isEmpty() { return size == 0; }
    public boolean isFull() { return size == capacity; }
}
```

**Practice: BFS**

```java
import java.util.ArrayDeque;
import java.util.Queue;

public class Main {
    public static void bfs(int[][] graph, int start) {
        Queue<Integer> queue = new ArrayDeque<>();
        boolean[] visited = new boolean[graph.length];
        queue.offer(start);
        visited[start] = true;
        
        while (!queue.isEmpty()) {
            int node = queue.poll();
            System.out.print(node + " ");
            for (int neighbor : graph[node]) {
                if (!visited[neighbor]) {
                    queue.offer(neighbor);
                    visited[neighbor] = true;
                }
            }
        }
    }
}
```

---

## Phase 5: Priority Queues / Sex Heaps

### Data Structure: Binary Heap

Priority queues order elements by priority (min-heap by default).

### Algorithms to Master

- **Insertion/Deletion**: `O(log n)`.
- **Heap Sort**: `O(n log n)`.
- **Kth Largest/Smallest**: Use heap for `O(n log k)`.
- **Median in Stream**: Use two heaps.

### Java Collection

- **PriorityQueue**: Min-heap, customizable with `Comparator`.

**Example: Top K Frequent Elements**

```java
import java.util.HashMap;
import java.util.PriorityQueue;

public class Main {
    public static int[] topKFrequent(int[] nums, int k) {
        HashMap<Integer, Integer> map = new HashMap<>();
        for (int num : nums) map.merge(num, 1, Integer::sum);
        
        PriorityQueue<int[]> pq = new PriorityQueue<>((a, b) -> a[1] - b[1]);
        for (var entry : map.entrySet()) {
            pq.offer(new int[]{entry.getKey(), entry.getValue()});
            if (pq.size() > k) pq.poll();
        }
        
        int[] result = new int[k];
        for (int i = k - 1; i >= 0; i--) result[i] = pq.poll()[0];
        return result;
    }
}
```

**Practice: Merge K Sorted Lists**

```java
import java.util.PriorityQueue;

class ListNode {
    int val;
    ListNode next;
    ListNode(int val) { this.val = val; }
}

public class Main {
    public static ListNode mergeKLists(ListNode[] lists) {
        PriorityQueue<ListNode> pq = new PriorityQueue<>((a, b) -> a.val - b.val);
        for (ListNode node : lists) if (node != null) pq.offer(node);
        
        ListNode dummy = new ListNode(0);
        ListNode curr = dummy;
        while (!pq.isEmpty()) {
            ListNode node = pq.poll();
            curr.next = node;
            curr = curr.next;
            if (node.next != null) pq.offer(node.next);
        }
        return dummy.next;
    }
}
```

---

## Phase 6: Sets

### Data Structure: Hash Table / Balanced BST

Sets store unique elements.

### Algorithms to Master

- **Hashing**: `O(1)` average lookup.
- **Union/Intersection/Difference**: Set operations.
- **Duplicate Removal**: Convert list to set.
- **Two-Sum**: Use set for `O(n)` solution.

### Java Collections

- **HashSet**: Unordered, fast.
- **LinkedHashSet**: Maintains insertion order.
- **TreeSet**: Sorted, `O(log n)`.

**Example: Longest Consecutive Sequence**

```java
import java.util.HashSet;

public class Main {
    public static int longestConsecutive(int[] nums) {
        HashSet<Integer> set = new HashSet<>();
        for (int num : nums) set.add(num);
        
        int longest = 0;
        for (int num : set) {
            if (!set.contains(num - 1)) {
                int current = num;
                int streak = 1;
                while (set.contains(current + 1)) {
                    current++;
                    streak++;
                }
                longest = Math.max(longest, streak);
            }
        }
        return longest;
    }
}
```

---

## Phase 7: Maps / HashMaps

### Data Structure: Hash Table / Balanced BST

Maps store key-value pairs.

### Algorithms to Master

- **Key-Value Lookup**: `O(1)` average for `HashMap`.
- **Frequency Counting**: Track occurrences.
- **Sliding Window**: Use map for dynamic problems.
- **Grouping**: Group elements by key.

### Java Collections

- **HashMap**: Unordered, allows null key.
- **LinkedHashMap**: Maintains insertion order.
- **TreeMap**: Sorted by key.
- **ConcurrentHashMap**: Thread-safe.

**Example: Anagrams Grouping**

```java
import java.util.*;

public class Main {
    public static List<List<String>> groupAnagrams(String[] strs) {
        Map<String, List<String>> map = new HashMap<>();
        for (String s : strs) {
            char[] chars = s.toCharArray();
            Arrays.sort(chars);
            String key = new String(chars);
            map.computeIfAbsent(key, k -> new ArrayList<>()).add(s);
        }
        return new ArrayList<>(map.values());
    }
}
```

**Practice: LRU Cache**

```java
import java.util.LinkedHashMap;

public class LRUCache extends LinkedHashMap<Integer, Integer> {
    private final int capacity;

    public LRUCache(int capacity) {
        super(capacity, 0.75f, true);
        this.capacity = capacity;
    }

    @Override
    protected boolean removeEldestEntry(Map.Entry<Integer, Integer> eldest) {
        return size() > capacity;
    }
}
```

---

## Phase 8: Deques

### Data Structure: Doubly Linked List / Circular Buffer

Deques support adding/removing from both ends.

### Algorithms to Master

- **Monotonic Queue**: Maintain sorted order in sliding window.
- **Sliding Window Max/Min**: Find max/min in subarrays.

### Java Collections

- **ArrayDeque**: Efficient for both ends.
- **LinkedList**: Slower alternative.

**Example: Sliding Window Maximum**

```java
import java.util.ArrayDeque;

public class Main {
    public static int[] maxSlidingWindow(int[] nums, int k) {
        int[] result = new int[nums.length - k + 1];
        ArrayDeque<Integer> deque = new ArrayDeque<>();
        
        for (int i = 0; i < nums.length; i++) {
            while (!deque.isEmpty() && deque.peekFirst() <= i - k) deque.pollFirst();
            while (!deque.isEmpty() && nums[deque.peekLast()] <= nums[i]) deque.pollLast();
            deque.offerLast(i);
            if (i >= k - 1) result[i - k + 1] = nums[deque.peekFirst()];
        }
        return result;
    }
}
```

---

## Phase 9: Iterators & Traversals

### Algorithms to Master

- **Iterator Traversal**: Use `Iterator` or `forEach`.
- **Reverse Iteration**: Use `ListIterator` for lists.
- **Fail-Fast**: Throws `ConcurrentModificationException` if modified during iteration.
- **Stream Operations**: `map`, `filter`, `reduce`, `collect`.

**Example: Stream Transformation**

```java
import java.util.List;

public class Main {
    public static void main(String[] args) {
        List<Integer> numbers = List.of(1, 2, 3, 4);
        List<Integer> doubled = numbers.stream()
                                       .map(n -> n * 2)
                                       .collect(Collectors.toList());
        System.out.println(doubled); // [2, 4, 6, 8]
    }
}
```

---

## Phase 10: Advanced DSA / Optimization

### Techniques to Master

- **Time/Space Optimization**: Choose collections based on complexity.
- **Amortized Analysis**: `ArrayList` resizing is `O(1)` amortized.
- **Custom Comparator**: For `TreeSet`/`TreeMap`.
- **Thread-Safe Collections**: Use `ConcurrentHashMap`, `CopyOnWriteArrayList`.

**Example: Custom Comparator for TreeSet**

```java
import java.util.TreeSet;

public class Main {
    public static void main(String[] args) {
        TreeSet<String> set = new TreeSet<>((a, b) -> b.compareTo(a));
        set.add("Apple");
        set.add("Banana");
        System.out.println(set); // [Banana, Apple]
    }
}
```

---

## Java Features Up to Java 25

- **Java 8 (2014)**:
    - Streams for collections: `list.stream().filter(n -> n > 0).collect(Collectors.toList())`.
    - Lambda expressions: `Comparator.comparingInt(String::length)`.
- **Java 9 (2017)**: Immutable collections (`List.of()`, `Set.of()`, `Map.of()`).
- **Java 10 (2018)**: `var` for cleaner code: `var list = new ArrayList<String>();`.
- **Java 14 (2020)**: Records for immutable data in collections.
    
    ```java
    record Point(int x, int y) {}
    Set<Point> points = Set.of(new Point(1, 2));
    ```
    
- **Java 17 (2021)**: Pattern matching for `instanceof`.
    
    ```java
    if (collection instanceof List<?> list) { list.size(); }
    ```
    
- **Java 21 (2023)**: Virtual threads for concurrent processing.
    
    ```java
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        executor.submit(() -> list.forEach(System.out::println));
    }
    ```
    
- **Java 25 (2025)**: Implicit classes for utility methods.
    
    ```java
    implicit class Utils {
        static <T> void print(List<T> list) { list.forEach(System.out::println); }
    }
    ```
    

---

## Best Practices

1. **Choose Correct Collection**: `ArrayList` for random access, `HashMap` for lookups, `TreeSet` for sorted data.
2. **Use Generics**: `List<String>` for type safety.
3. **Handle Concurrency**: Use `ConcurrentHashMap` for multi-threaded apps.
4. **Optimize**: Understand time complexity (e.g., `HashSet` `O(1)` vs `TreeSet` `O(log n)`).
5. **Test**: Use JUnit for testing collections.

**Maven Dependency for JUnit**:

```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.11.0</version>
    <scope>test</scope>
</dependency>
```

---

## Conclusion

The Java Collections Framework provides versatile data structures for various use cases. Master algorithms like sorting, searching, and traversals, and apply them in real-world problems like caching, analytics, and concurrent systems. Leverage Java 25 features like records and virtual threads to write concise, efficient code.



##### *Tags : [[Java]]