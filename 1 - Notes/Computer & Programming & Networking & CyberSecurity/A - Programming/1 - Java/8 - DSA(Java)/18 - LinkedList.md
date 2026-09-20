

# 🚀 **1. What Is a LinkedList (DSA Definition)**

A **LinkedList** is a linear data structure where **each element (node)** holds:

1. **data**
    
2. **a pointer/reference to the next node**
    

Nodes are connected like a chain.

Not stored in **contiguous memory** like arrays.

![[Pasted image 20251211083620.png]]



---

# 🧩 **2. Components of a LinkedList**

## ✔ Node

Every node contains two fields:

```text
+---------+-----------+
|  data   |  next---->|
+---------+-----------+
```

If it’s a _doubly linked list_, there’s also a **prev** pointer.

## ✔ Head

Pointer/reference to the **first node**.

## ✔ Tail (sometimes)

Pointer/reference to the **last node** (only needed for efficient insert-at-end).

---

# ⚙️ **3. Types of LinkedLists**

![Image](https://i.sstatic.net/VJdku.gif?utm_source=chatgpt.com)

![Image](https://deen3evddmddt.cloudfront.net/uploads/content-images/what-is-circular-linked-list.webp?utm_source=chatgpt.com)

### **A) Singly Linked List**

Each node points only to the next.

- Simple
    
- Memory efficient
    
- Can't move backwards
    

### **B) Doubly Linked List**

Each node has **prev** and **next**.

- Can move both directions
    
- Slightly more memory
    

### **C) Circular Linked List**

Last node points back to head.

- Useful for round-robin, scheduling
    

---

# ✨ **4. Operations (One by One)**

These are MUST-KNOW for interviews + DSA.

---

## **1. Insert at Beginning — O(1)**

### Explanation

Just create a new node and set its `next = head`, then move head.

### Diagram

```text
Before:
head → A → B → C

Insert X at start:
X → A → B → C
head = X
```

### Code (Java)

```java
void insertAtStart(int val) {
    Node newNode = new Node(val);
    newNode.next = head;
    head = newNode;
}
```

---

## **2. Insert at End — O(n) or O(1)**

O(n) if no tail.  
O(1) if we maintain tail pointer.

### Code (tail version)

```java
void insertAtEnd(int val) {
    Node newNode = new Node(val);
    tail.next = newNode;
    tail = newNode;
}
```

---

## **3. Delete a Node — O(n)**

To delete a node with value `x`, find the **previous** node and relink:

```text
A → B → C → D
Delete C:

A → B --------> D
```

---

## **4. Search an Element — O(n)**

Traverse node by node.

---

## **5. Traversal — O(n)**

```java
Node temp = head;
while (temp != null) {
    System.out.println(temp.data);
    temp = temp.next;
}
```

---

# 🧠 **5. Advantages**

- Dynamic size
    
- No need for contiguous memory
    
- Insert/delete in middle is efficient (no shifting)
    

---

# ⚠️ **6. Disadvantages**

- Slow random access (no O(1) index like array)
    
- Extra memory for pointers
    
- Cache-unfriendly (scattered in memory)
    

---

# 🥇 **7. When to Use LinkedList**

Use when:

- You have **lots of insertions/deletions**
    
- Data size changes frequently
    

Avoid when:

- You need **random access**
    
- You want **tight memory layout**
    

---




###### Tags : [[1 - DSA 🥭]]