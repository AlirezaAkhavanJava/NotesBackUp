
**`System.arraycopy`** is a **native, low-level Java method** used to **copy elements from one array to another efficiently**.

### Definition

```java
System.arraycopy(
    Object src,
    int srcPos,
    Object dest,
    int destPos,
    int length
);
```

### What it does

Copies `length` elements **from `src[srcPos...]` to `dest[destPos...]`**.

### Key rules (important)

- Both `src` and `dest` **must be arrays**
    
- Arrays must be **compatible types** (or same primitive type)
    
- Performs a **shallow copy**
    
- **Much faster** than manual loops
    
- Throws runtime exceptions if:
    
    - Index out of bounds
        
    - Type mismatch
        
    - Null array
        

### Example

```java
int[] a = {1, 2, 3, 4};
int[] b = new int[4];

System.arraycopy(a, 0, b, 0, a.length);
```

### When to use

- High-performance array copying
    
- Internal library / system-level operations
    
- Replacing `for` loops for array copy
    



###### Tags : [[1 - DSA 🥭]]