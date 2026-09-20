
![[Pasted image 20251123074125.png]]

The **Java object lifecycle** refers to the stages an object goes through from its creation to its destruction in a Java program (both in JVM-managed memory and developer-controlled logic). Here are the complete phases with explanations and practical examples:

### 1. **Object Creation Phase**

#### a. **Class Loading** (happens once per class)
- The `.class` file is loaded by the ClassLoader.
- Static variables are initialized, static blocks execute.

#### b. **Memory Allocation**
- When you call `new`, the JVM allocates memory on the **heap** for the object.
- All instance variables are assigned default values (e.g., `int` → 0, `Object` → null).

#### c. **Object Initialization** (in strict order)
Java executes the following in this exact order:

```java
public class Person {
    int age = 10;                    // 1. Instance variable initializers
    static { System.out.println("Static block"); }  // (once)
    
    { System.out.println("Instance initializer block"); } // 2. Instance blocks
    
    public Person() {                // 3. Constructor body
        System.out.println("Constructor");
    }
}
```

Output when creating one object:
```
Static block          // only once
Instance initializer block
Constructor
age = 10
```

### 2. **Object in Use (Live Phase)**
- Object is reachable via references (local vars, static refs, instance refs, etc.).
- You can call methods, modify fields.
- If the object implements `AutoCloseable`, you may use try-with-resources.

### 3. **Object Becomes Unreachable**
- No strong references point to the object anymore.
- Example:

```java
Person p = new Person();
p = null;  // now unreachable (if no other references)
```

### 4. **Garbage Collection Eligibility**
- The object is now eligible for GC.
- It may still be kept alive temporarily by:
  - WeakReference, SoftReference, PhantomReference
  - Finalizers (deprecated since Java 9, removed in Java 14+ best practice)

### 5. **Finalization (Legacy & Discouraged)**
If the object overrides `finalize()` (now deprecated):

```java
@Override
protected void finalize() throws Throwable {
    System.out.println("I'm being finalized!");
}
```

The GC may call `finalize()` once before collecting it.  
**Never rely on `finalize()`** — it's slow, unpredictable, and can resurrect objects.

Better alternative: use **try-with-resources** or **Cleaner** (Java 9+).

Modern clean-up example with `Cleaner`:

```java
public class Resource implements AutoCloseable {
    private static final Cleaner cleaner = Cleaner.create();
    
    private final Cleaner.Cleanable cleanable;
    
    public Resource() {
        cleanable = cleaner.register(this, () -> {
            System.out.println("Cleaning up resources");
            // actual cleanup code
        });
    }
    
    @Override
    public void close() {
        cleanable.clean();  // explicit cleanup
    }
}
```

### 6. **Memory Reclamation**
- The Garbage Collector (e.g., G1, ZGC, Shenandoah) frees the memory.
- The object is gone forever.

### Summary Diagram of Object Lifecycle

```
Class Loading (once)
     ↓
new Keyword → Heap allocation + default values
     ↓
Instance initializers & constructor → Object ready
     ↓
Object used (reachable)
     ↓
All references removed → Unreachable
     ↓
Eligible for GC
     ↓
(Optional: Cleaner / try-with-resources cleanup)
     ↓
Garbage Collected → Memory freed
```

### Key Points Every Java Developer Should Know

| Phase                  | Can you control it?       | Recommended way today         |
|------------------------|---------------------------|-------------------------------|
| Creation               | Yes                       | Constructor + records         |
| Cleanup                | Preferably explicitly     | `AutoCloseable` + try-with-resources or `Cleaner` |
| Finalization           | Avoid                     | `finalize()` is deprecated    |
| Garbage Collection     | No direct control         | Tune JVM flags if needed      |

### Quick Example – Best Practice in 2025+

```java
try (var db = new DatabaseConnection()) {  // AutoCloseable
    db.query("SELECT ...");
} 
// db.close() automatically called here, even on exception
// No finalize(), no manual nulling needed
```

That’s the modern, complete Java object lifecycle! Let me know if you want deep dives into class loading, GC algorithms, or memory leaks.


[[Java]]