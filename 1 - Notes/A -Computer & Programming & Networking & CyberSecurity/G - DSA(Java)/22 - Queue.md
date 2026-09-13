

### Queue (DSA) — Definition

A **Queue** is a **linear data structure** that follows **FIFO**  
**First In, First Out**.

> The **first element inserted** is the **first one removed**.

### Core Operations

- **Enqueue** → insert element at the **rear**
    
- **Dequeue** → remove element from the **front**
    
- **Peek/Front** → view front element without removing
    
- **isEmpty / isFull**
    

### Visual

```
Front ← [10, 20, 30] ← Rear
```

### Key Characteristics

- Order-preserving
    
- Access restricted to **front (remove)** and **rear (insert)**
    
- No random access like arrays
    

### Common Implementations

- **Array-based Queue**
    
- **Linked List Queue**
    
- **Circular Queue** (fixes wasted space)
    
- **Deque** (double-ended queue)
    

### Time Complexity

- Enqueue: **O(1)**
    
- Dequeue: **O(1)**
    

### Real-world Examples

- Printer jobs
    
- CPU scheduling
    
- Request handling in servers
    
- BFS traversal
    




###### Tags : [[1 - DSA 🥭]]