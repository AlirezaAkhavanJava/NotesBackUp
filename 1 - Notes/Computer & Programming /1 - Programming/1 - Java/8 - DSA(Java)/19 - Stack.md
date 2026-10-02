## DSA: Stack (short, clean, complete)

### 1️⃣ What is a Stack?

A **Stack** is a **linear data structure** that follows  
**LIFO → Last In, First Out**

Think: **plates**

- Put plate → on top
    
- Remove plate → from top only


![[Pasted image 20251213083710.png]]


    

---

### 2️⃣ Core Operations

|Operation|Meaning|
|---|---|
|`push(x)`|Add element to top|
|`pop()`|Remove top element|
|`peek()` / `top()`|View top element|
|`isEmpty()`|Stack empty?|
|`isFull()`|(array stack only)|

All are **O(1)** ⏱️

---

### 3️⃣ Stack Representation

#### A) Array-based Stack

- Uses array + `top` pointer
    
- Fixed size (unless dynamic)
    

```java
class Stack {
    int[] arr = new int[5];
    int top = -1;

    void push(int x) {
        if (top == arr.length - 1) return;
        arr[++top] = x;
    }

    int pop() {
        if (top == -1) return -1;
        return arr[top--];
    }
}
```

✔ Fast  
❌ Size limit

---

#### B) Linked List Stack

- Uses nodes
    
- No size limit
    

```java
class Node {
    int data;
    Node next;
}

Node top = null;

void push(int x) {
    Node n = new Node();
    n.data = x;
    n.next = top;
    top = n;
}

int pop() {
    if (top == null) return -1;
    int val = top.data;
    top = top.next;
    return val;
}
```

✔ Dynamic size  
❌ Extra memory for pointers

---

### 4️⃣ Stack Workflow Example

```
push(10)
push(20)
push(30)

Stack: [10, 20, 30]  ← top

pop() → 30
peek() → 20
```

---

### 5️⃣ Real-World Uses

- Function calls (Call Stack)
    
- Undo / Redo
    
- Expression evaluation
    
- Parenthesis checking
    
- Backtracking (DFS, recursion)
    

---

### 6️⃣ Stack in Java (Built-in)

```java
Stack<Integer> s = new Stack<>();
s.push(10);
s.pop();
s.peek();
```

⚠️ Modern code prefers `Deque`:

```java
Deque<Integer> s = new ArrayDeque<>();
```

---

### 7️⃣ When to Use Stack?

Use Stack when:

- Order matters
    
- You only need **top access**
    
- You need **reverse behavior**
    

---



###### Tags : [[1 - DSA 🥭]]