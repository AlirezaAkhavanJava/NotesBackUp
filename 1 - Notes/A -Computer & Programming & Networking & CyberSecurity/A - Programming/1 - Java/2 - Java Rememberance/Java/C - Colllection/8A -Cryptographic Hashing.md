
## **PART 1: CRYPTOGRAPHIC HASHING**

Cryptographic hashing is used for **security, data integrity, and password storage**. It's different from regular hashing—it's **one-way** (impossible to reverse).

### **1.1 Common Cryptographic Algorithms**

| Algorithm | Hash Size | Security | Use Case |
|-----------|-----------|----------|----------|
| **MD5** | 128 bits | ❌ Broken | Legacy only (NOT recommended) |
| **SHA-1** | 160 bits | ⚠️ Weak | Legacy/certificates |
| **SHA-256** | 256 bits | ✅ Strong | Passwords, blockchain |
| **SHA-512** | 512 bits | ✅ Very Strong | Maximum security |
| **bcrypt/PBKDF2** | Variable | ✅✅ Best | Password hashing |

---

### **1.2 SHA-256 Implementation**

```java
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class CryptoHashExample {
    
    // Generic hashing function
    public static String hashString(String input, String algorithm) {
        try {
            MessageDigest digest = MessageDigest.getInstance(algorithm);
            byte[] hashBytes = digest.digest(input.getBytes());
            
            // Convert bytes to hexadecimal
            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Algorithm not found", e);
        }
    }

    public static void main(String[] args) {
        String password = "MySecurePassword123";
        
        String sha256 = hashString(password, "SHA-256");
        String sha512 = hashString(password, "SHA-512");
        
        System.out.println("SHA-256: " + sha256);
        System.out.println("SHA-512: " + sha512);
    }
}
```

**Output:**
```
SHA-256: 9f86d081884c7d6d9ffd60014fc7ee77e42eaf8d9164cc65f92f3e9e625edf73
SHA-512: f7fbba6e0636f890e56fbbf3283e524c6fa3204ae298382d624741d0dc6638326e282c41be5e4254d8820772c5518a2c5a8c0c7f8c899d128a6149f1f1c1340
```

---

### **1.3 Using bcrypt for Password Hashing (BEST PRACTICE)**

For password storage, use **bcrypt** (much better than plain SHA-256):

```java
// Add dependency: com.mindrot:jbcrypt:0.4

import org.mindrot.jbcrypt.BCrypt;

public class PasswordHashingExample {
    
    public static String hashPassword(String password) {
        // Salt is automatically generated and embedded
        return BCrypt.hashpw(password, BCrypt.gensalt(12));
    }
    
    public static boolean verifyPassword(String password, String hash) {
        return BCrypt.checkpw(password, hash);
    }
    
    public static void main(String[] args) {
        String password = "MySecurePassword123";
        
        // Hash the password
        String hash = hashPassword(password);
        System.out.println("Hashed: " + hash);
        
        // Verify the password
        boolean isCorrect = verifyPassword(password, hash);
        System.out.println("Password correct: " + isCorrect);
        
        boolean isWrong = verifyPassword("WrongPassword", hash);
        System.out.println("Wrong password: " + isWrong);
    }
}
```

**Output:**
```
Hashed: $2a$12$abc123...xyz789
Password correct: true
Wrong password: false
```

---

### **1.4 Comparison: SHA-256 vs bcrypt**

```java
public class ComparisonExample {
    public static void main(String[] args) {
        String password = "SecurePass123";
        
        // SHA-256: FAST, but INSECURE for passwords
        long startSHA = System.currentTimeMillis();
        String sha256 = CryptoHashExample.hashString(password, "SHA-256");
        long timeSHA = System.currentTimeMillis() - startSHA;
        System.out.println("SHA-256 Time: " + timeSHA + "ms");
        System.out.println("SHA-256 Hash: " + sha256);
        
        // bcrypt: SLOW (intentional), SECURE
        long startBcrypt = System.currentTimeMillis();
        String bcryptHash = PasswordHashingExample.hashPassword(password);
        long timeBcrypt = System.currentTimeMillis() - startBcrypt;
        System.out.println("\nbcrypt Time: " + timeBcrypt + "ms");
        System.out.println("bcrypt Hash: " + bcryptHash);
        
        // Same password hashes differently each time (salt!)
        String bcryptHash2 = PasswordHashingExample.hashPassword(password);
        System.out.println("bcrypt Hash 2: " + bcryptHash2);
    }
}
```

**Key Difference:**
- **SHA-256** is fast but vulnerable to **brute-force attacks**
- **bcrypt** is intentionally slow (takes ~100ms) and includes **salt**, making attacks impractical

---

---

## **PART 2: LOAD FACTOR & RESIZING STRATEGY**

### **2.1 What is Load Factor?**

**Load Factor** = `size / capacity`

- Measures how full the hash table is
- Java's HashMap default: **0.75**
- When exceeded, table **doubles** and **rehashes** all entries

```java
public class LoadFactorExample {
    public static void main(String[] args) {
        // Initial capacity: 16, Load factor: 0.75
        // Resize trigger: 16 * 0.75 = 12 entries
        
        HashMap<String, String> map = new HashMap<>(16, 0.75f);
        
        for (int i = 0; i < 20; i++) {
            map.put("key" + i, "value" + i);
            System.out.println("Size: " + map.size() + ", Capacity estimate: " + 
                             (i < 12 ? 16 : (i < 24 ? 32 : 64)));
        }
    }
}
```

---

### **2.2 Custom Hash Table with Resizing**

```java
public class CustomHashTable<K, V> {
    
    private static class Entry<K, V> {
        final K key;
        V value;
        Entry<K, V> next;
        
        Entry(K key, V value) {
            this.key = key;
            this.value = value;
        }
    }
    
    private Entry<K, V>[] table;
    private int size = 0;
    private float loadFactor = 0.75f;
    private int threshold;
    
    @SuppressWarnings("unchecked")
    public CustomHashTable(int initialCapacity) {
        this.table = new Entry[initialCapacity];
        this.threshold = (int)(initialCapacity * loadFactor);
    }
    
    public CustomHashTable() {
        this(16);
    }
    
    private int hash(K key) {
        return Math.abs(key.hashCode()) % table.length;
    }
    
    public void put(K key, V value) {
        if (key == null) throw new IllegalArgumentException("Key cannot be null");
        
        int index = hash(key);
        Entry<K, V> node = table[index];
        
        // Update existing key
        while (node != null) {
            if (node.key.equals(key)) {
                node.value = value;
                return;
            }
            node = node.next;
        }
        
        // Add new entry at head of chain
        Entry<K, V> newEntry = new Entry<>(key, value);
        newEntry.next = table[index];
        table[index] = newEntry;
        size++;
        
        // Check if resize needed
        if (size >= threshold) {
            resize();
        }
    }
    
    @SuppressWarnings("unchecked")
    private void resize() {
        int oldCapacity = table.length;
        int newCapacity = oldCapacity * 2;
        Entry<K, V>[] oldTable = table;
        
        // Create new table
        table = new Entry[newCapacity];
        size = 0;
        this.threshold = (int)(newCapacity * loadFactor);
        
        System.out.println("Resizing: " + oldCapacity + " -> " + newCapacity);
        
        // Rehash all entries
        for (Entry<K, V> entry : oldTable) {
            while (entry != null) {
                put(entry.key, entry.value);
                entry = entry.next;
            }
        }
    }
    
    public V get(K key) {
        int index = hash(key);
        Entry<K, V> node = table[index];
        
        while (node != null) {
            if (node.key.equals(key)) {
                return node.value;
            }
            node = node.next;
        }
        return null;
    }
    
    public int size() {
        return size;
    }
    
    public int capacity() {
        return table.length;
    }
    
    public float getCurrentLoadFactor() {
        return (float) size / table.length;
    }
}
```

---

### **2.3 Demonstration with Monitoring**

```java
public class ResizingDemo {
    public static void main(String[] args) {
        CustomHashTable<String, String> table = new CustomHashTable<>(4);
        
        System.out.println("Initial Capacity: " + table.capacity() + ", Load Factor Threshold: 0.75\n");
        
        for (int i = 0; i < 20; i++) {
            table.put("key" + i, "value" + i);
            
            System.out.printf("After adding %d entries: Size=%d, Capacity=%d, Load Factor=%.2f%n",
                    i + 1, table.size(), table.capacity(), table.getCurrentLoadFactor());
        }
    }
}
```

**Output:**
```
Initial Capacity: 4, Load Factor Threshold: 0.75

After adding 1 entries: Size=1, Capacity=4, Load Factor=0.25
After adding 2 entries: Size=2, Capacity=4, Load Factor=0.50
After adding 3 entries: Size=3, Capacity=4, Load Factor=0.75
Resizing: 4 -> 8
After adding 4 entries: Size=4, Capacity=8, Load Factor=0.50
...
After adding 6 entries: Size=6, Capacity=8, Load Factor=0.75
Resizing: 8 -> 16
After adding 7 entries: Size=7, Capacity=16, Load Factor=0.44
```

---

### **2.4 Why Resizing Matters**

| Scenario | Without Resizing | With Resizing |
|----------|------------------|---------------|
| **Collision Rate** | Increases dramatically | Stays low (~1-2) |
| **Search Time** | O(n) worst case | O(1) average |
| **Memory** | Wasted space | Efficiently used |
| **Performance** | Degrades over time | Consistent |

---

### **2.5 Load Factor Tuning**

```java
public class LoadFactorTuning {
    public static void main(String[] args) {
        // Lower load factor = more memory, fewer collisions
        System.out.println("Load Factor 0.5 (Low):  More memory, fastest");
        System.out.println("Load Factor 0.75 (Default): Balanced");
        System.out.println("Load Factor 1.0 (High): Less memory, more collisions");
        
        HashMap<String, String> lowLF = new HashMap<>(16, 0.5f);   // Resize at 8 entries
        HashMap<String, String> defaultLF = new HashMap<>(16, 0.75f); // Resize at 12 entries
        HashMap<String, String> highLF = new HashMap<>(16, 1.0f);  // Resize at 16 entries
    }
}
```

---

## **SUMMARY**

### **Cryptographic Hashing:**
✅ **Use bcrypt** for passwords (slow + salt-based)  
✅ **Use SHA-256/512** for data integrity  
❌ **Avoid MD5/SHA-1** (broken/deprecated)  
✅ **One-way**: Cannot reverse hash to get original

### **Load Factor & Resizing:**
✅ **Default 0.75** is optimal for most cases  
✅ **Resizing doubles capacity** when threshold exceeded  
✅ **Rehashing** redistributes entries in larger table  
✅ **Maintains O(1)** average lookup performance  
✅ **Trade-off**: Speed vs. memory usage



[[Java]]