

# **What is a Stack?**

A **Stack** is an **ADT** that follows **LIFO**:

### **Last In → First Out**

Whatever you put in last is the first thing that comes out.

Think:

- browser back button
    
- undo/redo
    
- Java call stack
    
- parsing expressions
    
- DFS graph search
    
![[Pasted image 20251202083048.png]]

---

# **1. Stack ADT (the contract)**

A stack supports:

### **push(x)**

Add element to the **top**.

### **pop()**

Remove and return the **top** element.

### **peek()**

Return the top element without removing it.

### **isEmpty()**

This set of operations defines the **ADT**, not the implementation.

---

# **2. Stack Implementations (how you actually build it)**

A stack can be implemented with:

### **1. Array**

- simple
    
- fast
    
- might require resizing
    

### **2. Linked List**

- infinite growth
    
- no resizing issues
    
- slightly more overhead per node
    

### **3. Two Queues (interview trick)**

A stack can be built using queues.

### **4. Java built-ins**

Best choices:

- `ArrayDeque<E>` ← **fastest and recommended**
    
- Avoid `Stack<E>` class (it's legacy and synchronized).
    

---

# **3. Java Example (using ArrayDeque)**

```java
Deque<Integer> stack = new ArrayDeque<>();

stack.push(10);
stack.push(20);
stack.push(30);

System.out.println(stack.pop());  // 30
System.out.println(stack.peek()); // 20
```

This is the modern way to use stacks in Java.

---

# **4. Big-O Complexity**

|Operation|Array|LinkedList|
|---|---|---|
|push|O(1)|O(1)|
|pop|O(1)|O(1)|
|peek|O(1)|O(1)|

Both are efficient.

---

# **5. Professional Use Cases (backend + CS)**

### **1. Java virtual machine call stack**

Every method call → push  
Method return → pop

### **2. Expression evaluation**

`( ( 2 + 3 ) * 5 )`  
Parsers use stacks.

### **3. Undo/redo**

Editors store actions in stacks.

### **4. DFS (Depth First Search)**

Graphs and trees use stacks.

### **5. Parentheses checking**

Valid parentheses problems (`()[]{}`) use stacks.

---

# **6. Example: Parentheses checker**

```java
boolean isValid(String s) {
    Deque<Character> st = new ArrayDeque<>();

    for (char c : s.toCharArray()) {
        if (c == '(') st.push(')');
        else if (c == '{') st.push('}');
        else if (c == '[') st.push(']');
        else if (st.isEmpty() || st.pop() != c) return false;
    }
    return st.isEmpty();
}
```

This shows how stacks solve real problems.

---



###### Tags : [[1 - DSA 🥭]]