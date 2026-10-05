

**Hash collisions** occur when two different keys hash to the same index. Here are the main techniques to handle them:

---

## **1. Chaining (Separate Chaining)**

Each hash table index points to a linked list. If collisions occur, elements are stored in the same list.

**Java's HashMap uses this approach:**

```java
// Conceptual representation of how HashMap handles collisions
class ChainedHashTable {
    private LinkedList<Entry>[] buckets;
    private int size = 16;

    public ChainedHashTable() {
        buckets = new LinkedList[size];
        for (int i = 0; i < size; i++) {
            buckets[i] = new LinkedList<>();
        }
    }

    public void put(String key, String value) {
        int index = Math.abs(key.hashCode()) % size;
        LinkedList<Entry> chain = buckets[index];
        
        // Check if key already exists
        for (Entry entry : chain) {
            if (entry.key.equals(key)) {
                entry.value = value;
                return;
            }
        }
        // Add new entry
        chain.add(new Entry(key, value));
    }

    public String get(String key) {
        int index = Math.abs(key.hashCode()) % size;
        LinkedList<Entry> chain = buckets[index];
        
        for (Entry entry : chain) {
            if (entry.key.equals(key)) {
                return entry.value;
            }
        }
        return null;
    }

    static class Entry {
        String key, value;
        Entry(String key, String value) {
            this.key = key;
            this.value = value;
        }
    }
}
```

**Pros:** Simple, flexible load factor  
**Cons:** Extra memory for linked lists

---

## **2. Open Addressing**

All elements stored directly in the array. On collision, find the next available slot.

### **Linear Probing**
```java
class LinearProbingHashTable {
    private String[] table = new String[16];
    private int size = 0;

    public void put(String key, String value) {
        int index = Math.abs(key.hashCode()) % table.length;
        
        // Linear probing: keep moving forward
        while (table[index] != null) {
            index = (index + 1) % table.length;
        }
        table[index] = value;
        size++;
    }

    public String get(String key) {
        int index = Math.abs(key.hashCode()) % table.length;
        
        while (table[index] != null) {
            if (table[index].equals(key)) {
                return table[index];
            }
            index = (index + 1) % table.length;
        }
        return null;
    }
}
```

**Pros:** Memory efficient, no extra structures  
**Cons:** Clustering problem (contiguous blocks get filled)

---

### **Quadratic Probing**
Instead of moving by 1, move by i²:

```java
// Probing sequence: hash(k), hash(k) + 1², hash(k) + 2², hash(k) + 3², ...
public void put(String key, String value) {
    int index = Math.abs(key.hashCode()) % table.length;
    int i = 0;
    
    while (table[index] != null) {
        index = (Math.abs(key.hashCode()) + i * i) % table.length;
        i++;
    }
    table[index] = value;
}
```

**Pros:** Reduces clustering compared to linear probing  
**Cons:** More complex, may not find empty slot if table is full

---

### **Double Hashing**
Use a second hash function to determine the step size:

```java
class DoubleHashingHashTable {
    private String[] table = new String[16];

    private int hash1(String key) {
        return Math.abs(key.hashCode()) % table.length;
    }

    private int hash2(String key) {
        // Must return non-zero and less than table size
        return 1 + Math.abs(key.hashCode()) % (table.length - 1);
    }

    public void put(String key, String value) {
        int index = hash1(key);
        int step = hash2(key);
        int i = 0;
        
        while (table[index] != null) {
            index = (index + i * step) % table.length;
            i++;
        }
        table[index] = value;
    }
}
```

**Pros:** Minimal clustering  
**Cons:** Requires second hash function, slower

---

## **Comparison Table**

| Technique | Method | Pros | Cons |
|-----------|--------|------|------|
| **Chaining** | Linked lists at each bucket | Simple, flexible | Extra memory |
| **Linear Probing** | (index + 1) % size | Memory efficient | Clustering |
| **Quadratic Probing** | (index + i²) % size | Better than linear | May fail to find slot |
| **Double Hashing** | (index + i × hash2) % size | Minimal clustering | Slower, complex |

---

## **Real-world Usage in Java**

```java
// Java's HashMap automatically handles collisions with chaining
// From Java 8+, if collision chain gets too long, it converts to a red-black tree
HashMap<String, String> map = new HashMap<>();
map.put("key1", "value1");
map.put("key2", "value2");

// Load factor determines when to resize (default 0.75)
// If (size / capacity) > 0.75, HashMap doubles its size
```

---

## **Summary**

- **Chaining** (used by Java's HashMap): Simple, most flexible
- **Open Addressing**: Memory efficient but prone to clustering
- **Linear Probing**: Easiest to implement
- **Double Hashing**: Best performance for open addressing




[[Java]]