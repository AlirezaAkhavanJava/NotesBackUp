
### Tree (DSA) — Definition

A **Tree** is a **non-linear hierarchical data structure** consisting of **nodes** connected by **edges**.

- One node is the **root**.
    
- Each node can have **zero or more child nodes**.
    
- Nodes with **no children** are called **leaves**.
![[Pasted image 20251215084040.png]]

---

### Key Terms

|Term|Definition|
|---|---|
|Root|Topmost node of the tree|
|Node|Element of the tree|
|Edge|Connection between two nodes|
|Parent|Node with children|
|Child|Node that has a parent|
|Sibling|Nodes with the same parent|
|Leaf|Node with no children|
|Depth|Distance from root|
|Height|Longest path from node to a leaf|

---

### Types of Trees

1. **General Tree** – Any node can have any number of children.
    
2. **Binary Tree** – Each node has at most **2 children**.
    
3. **Binary Search Tree (BST)** – Binary tree with **left < root < right** property.
    
4. **Balanced Trees** – e.g., AVL, Red-Black Tree.
    
5. **Heap** – Complete binary tree with min/max property.
    
6. **Trie** – Tree for string storage/search.
    

---

### Common Operations

- **Traversal**:
    
    - **Preorder** (Root → Left → Right)
        
    - **Inorder** (Left → Root → Right)
        
    - **Postorder** (Left → Right → Root)
        
    - **Level-order** (BFS)
        
- **Insertion**
    
- **Deletion**
    
- **Searching**
    
- **Finding Height/Depth**
    

---

### Example (Binary Tree)

```
       10
      /  \
     5    20
    / \   /
   3   7 15
```

- Root = 10
    
- Leaves = 3, 7, 15
    
- Height = 3
    

---



###### Tags : [[1 - DSA 🥭]]