

# **What is a Queue?**

A **Queue** is an **ADT** that follows **FIFO**:

### **First In → First Out**

The first item that enters is the first item that leaves.

Think of:

- people in a line
    
- tasks waiting to be processed
    
- messages in a message broker
    
- HTTP requests in a server

![[Pasted image 20251202083215.png]]

---

# **1. Queue ADT (behavior, not implementation)**

A Queue supports:

### **enqueue(x)**

Add item to the **back**.

### **dequeue()**

Remove item from the **front**.

### **peek() / front()**

Look at the first item without removing it.

### **isEmpty()**

This is the **abstract behavior**.

---

# **2. Implementations (Data Structures that implement Queue)**

A queue can be implemented with:

### **1. Array**

- circular buffer
    
- fastest for fixed-size queue
    

### **2. Linked List**

- easy to grow
    
- O(1) enqueue/dequeue if you track head + tail
    

### **3. Two Stacks**

- clever solution
    
- used in some interview problems
    

### **4. Java Collections:**

- `LinkedList<>`
    
- `ArrayDeque<>` ← **best general choice**
    
- `PriorityQueue<>` (special variant, not FIFO)
    

---

# **3. Simple example in Java**

```java
Queue<Integer> q = new LinkedList<>();

q.add(10);  // enqueue
q.add(20);
q.add(30);

System.out.println(q.remove()); // 10 (dequeue)
System.out.println(q.peek());   // 20
```

---

# **4. Big-O (always know this)**

|Operation|Array|LinkedList|
|---|---|---|
|enqueue|O(1)*|O(1)|
|dequeue|O(1)*|O(1)|
|peek|O(1)|O(1)|

* using circular buffer.

---

# **5. Real-world uses (important for backend)**

### **1. Task scheduling**

CPU task queues, thread pools.

### **2. Messaging**

Kafka, RabbitMQ, SQS — all use queues.

### **3. BFS (graph algorithm)**

Graph traversal uses a queue.

### **4. HTTP server request handling**

Requests get queued.

### **5. Logging systems**

Producer → consumer pattern.



###### Tags : [[1 - DSA 🥭]]