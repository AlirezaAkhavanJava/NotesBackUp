
### Binary Tree — Definition

A **Binary Tree** is a **tree data structure** in which **each node has at most two children**, usually referred to as:

- **Left child**
    
- **Right child**
    

It’s the foundation for many advanced tree structures (BST, Heap, AVL, etc.).

![[Pasted image 20251215084733.png]]

---

### Key Terms

|Term|Definition|
|---|---|
|Root|Topmost node of the tree|
|Leaf|Node with no children|
|Internal Node|Node with at least one child|
|Subtree|Tree formed by any node and its descendants|
|Height|Number of edges on the longest path from node to leaf|
|Depth|Distance from root to a node|

---

### Types of Binary Trees

1. **Full Binary Tree** – Every node has 0 or 2 children.
    
2. **Perfect Binary Tree** – All internal nodes have 2 children, all leaves at same level.
    
3. **Complete Binary Tree** – All levels filled except possibly last, filled left to right.
    
4. **Balanced Binary Tree** – Height difference between left and right subtree ≤ 1.
    
5. **Degenerate (Skewed) Tree** – Each parent has only one child (like a linked list).
    

---

### Common Operations

- **Insertion**
    
- **Deletion**
    
- **Traversal**:
    
    - **Inorder** (Left → Root → Right)
        
    - **Preorder** (Root → Left → Right)
        
    - **Postorder** (Left → Right → Root)
        
    - **Level-order** (BFS)
        
- **Searching**
    
- **Finding Height / Depth**
    

---

### Example

```
       10
      /  \
     5    20
    / \   /
   3   7 15
```

- Root = 10
    
- Leaves = 3, 7, 15
    
- Left child of 10 = 5, Right child of 10 = 20
    

---



###### Tags : [[1 - DSA 🥭]]