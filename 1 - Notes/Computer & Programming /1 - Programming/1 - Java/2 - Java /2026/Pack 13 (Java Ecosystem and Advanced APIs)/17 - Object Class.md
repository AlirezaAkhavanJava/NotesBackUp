Alright. Let’s dissect Java’s **`Object` class**—the root of everything in Java—**from very basic to advanced**.

---

## 🔹 1. The Basics

- **`java.lang.Object`** is the **root superclass** of all classes in Java.
    
- Every class in Java **implicitly extends `Object`** if no other superclass is specified.
    

```java
class MyClass { }  
// This is the same as:
class MyClass extends Object { }
```

- This means every object in Java **inherits methods from `Object`**.
    

---

## 🔹 2. Core Methods of `Object`

Here are the key methods, grouped by purpose:

### Equality & Hashing

- `boolean equals(Object obj)`
    
    - Checks if two objects are **logically equal**.
        
    - Default: compares **references** (`==`).
        
    - Usually overridden.
        
- `int hashCode()`
    
    - Returns a hash value, used in **HashMap, HashSet, etc.**
        
    - Must follow contract with `equals`.
        

### String Representation

- `String toString()`
    
    - Returns a string describing the object.
        
    - Default: `ClassName@hashCodeHex`.
        
    - Often overridden for readability.
        

### Cloning

- `protected Object clone() throws CloneNotSupportedException`
    
    - Makes a **copy** of the object.
        
    - Class must implement `Cloneable`.
        

### Object Coordination (Threading)

- `void wait()` / `void wait(long timeout)` / `void wait(long timeout, int nanos)`
    
    - Causes the current thread to wait until notified.
        
- `void notify()`
    
    - Wakes one waiting thread.
        
- `void notifyAll()`
    
    - Wakes all waiting threads.
        
- These are the basis of **low-level thread communication** (rarely used directly now; `Lock`/`Condition` are preferred).
    

### Class Info

- `final Class<?> getClass()`
    
    - Returns the runtime class object.
        
    - Used heavily in reflection.
        

### Garbage Collection

- `protected void finalize() throws Throwable`
    
    - Called before GC reclaims the object.
        
    - Deprecated (not reliable).
        

---

## 🔹 3. Common Overriding Examples

### `equals` and `hashCode`

If you don’t override them:

```java
Object o1 = new Object();
Object o2 = new Object();
System.out.println(o1.equals(o2)); // false
```

Custom example:

```java
class Person {
    String name;
    Person(String name) { this.name = name; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Person)) return false;
        Person p = (Person) o;
        return name.equals(p.name);
    }

    @Override
    public int hashCode() {
        return name.hashCode();
    }
}
```

### `toString`

```java
Person p = new Person("Alice");
System.out.println(p);
// Without override: Person@6bc7c054
// With override: Person{name='Alice'}
```

---

## 🔹 4. Advanced Topics

### Reflection

```java
Object obj = new String("Hello");
Class<?> clazz = obj.getClass();
System.out.println(clazz.getName()); // java.lang.String
```

### Synchronization with `wait/notify`

```java
synchronized (lock) {
    while (!condition) {
        lock.wait(); // releases lock, waits
    }
    // do work
}
```

### Marker Interfaces & Cloning

```java
class MyClass implements Cloneable {
    @Override
    protected Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}
```

### Contract Between Methods

- **equals & hashCode** → must be consistent. If two objects are equal, they must have the same hash code.
    
- **wait/notify** → must be called inside a `synchronized` block.
    

---

## 🔹 5. Summary Table

|Method|Default Behavior|Typical Override?|
|---|---|---|
|`equals`|Reference equality|✅ Yes|
|`hashCode`|Memory-based hash|✅ Yes|
|`toString`|ClassName@hashCodeHex|✅ Yes|
|`clone`|Shallow copy (if `Cloneable`)|⚠ Sometimes|
|`getClass`|Runtime class info|❌ No|
|`wait/notify`|Thread communication|❌ Rare (use higher-level APIs)|
|`finalize`|Cleanup before GC (deprecated)|❌ Avoid|

---

👉 So in short:

- **Every class in Java extends `Object`.**
    
- It provides **fundamental methods** for equality, hashing, string representation, synchronization, and reflection.
    
- You almost always override **`equals`, `hashCode`, and `toString`** in real-world apps.



#### Tags : [[Java]]