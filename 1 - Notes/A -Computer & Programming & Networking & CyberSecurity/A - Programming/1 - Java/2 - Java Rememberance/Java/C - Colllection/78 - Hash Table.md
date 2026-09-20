

## What is a Hash Table in Java?

A **Hash Table** (implemented as `Hashtable` class or more commonly `HashMap` in Java) is a data structure that stores key-value pairs and provides fast data retrieval. It uses a technique called **hashing** to map keys to specific locations in memory.

## How It Works

1. **Hashing**: When you insert a key-value pair, the hash table applies a hash function to the key to calculate an index
2. **Storage**: The value is stored at that calculated index in an underlying array
3. **Retrieval**: To find a value, you provide the key, and the hash function quickly calculates where it's stored

## Key Characteristics

- **Fast Operations**: Average O(1) time complexity for insert, delete, and search
- **Key-Value Storage**: Each element has a unique key mapped to a value
- **No Duplicate Keys**: Each key can appear only once
- **Unordered**: Elements are not stored in any particular order

## Java Implementations

```java
// Most common - HashMap (not synchronized, allows null)
HashMap<String, Integer> map = new HashMap<>();
map.put("apple", 5);
map.put("banana", 3);
int value = map.get("apple"); // returns 5

// Hashtable (synchronized, thread-safe, no nulls)
Hashtable<String, Integer> table = new Hashtable<>();
table.put("orange", 7);

// ConcurrentHashMap (thread-safe, better performance than Hashtable)
ConcurrentHashMap<String, Integer> concurrentMap = new ConcurrentHashMap<>();
```

## Common Use Cases

1. **Caching**: Store frequently accessed data for quick retrieval
2. **Database Indexing**: Map keys to record locations
3. **Counting Frequencies**: Count occurrences of items
4. **Symbol Tables**: In compilers and interpreters
5. **Session Management**: Store user session data in web applications

## Example: Word Frequency Counter

```java
String text = "the quick brown fox jumps over the lazy dog the fox";
String[] words = text.split(" ");

HashMap<String, Integer> frequency = new HashMap<>();
for (String word : words) {
    frequency.put(word, frequency.getOrDefault(word, 0) + 1);
}

System.out.println(frequency); 
// Output: {the=3, quick=1, brown=1, fox=2, jumps=1, over=1, lazy=1, dog=1}
```

## Important Considerations

- **Hash Collisions**: When two keys hash to the same index, the table must handle it (usually via chaining or open addressing)
- **Load Factor**: The ratio of stored elements to table size; when it gets too high, the table is resized
- **equals() and hashCode()**: Objects used as keys must properly implement these methods
- **Thread Safety**: Choose the right implementation based on your concurrency needs

## HashMap vs Hashtable

| Feature | HashMap | Hashtable |
|---------|---------|-----------|
| Thread-safe | No | Yes |
| Null keys/values | Yes | No |
| Performance | Faster | Slower |
| Legacy | No | Yes (since Java 1.0) |

In modern Java, **HashMap** is generally preferred unless you specifically need thread safety, in which case **ConcurrentHashMap** is usually the better choice.


[[Java]]