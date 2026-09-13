

Every node has **either 0 or 2 children**. Some people use the terms interchangeably.

Here’s a clear explanation with a Java example:

---

### **Definition**

- Each node has **0 or 2 children**.
    
- No node has exactly **1 child**.
    

---

### **Node Class**

```java
class Node {
    int data;
    Node left, right;

    Node(int data) {
        this.data = data;
        this.left = null;
        this.right = null;
    }
}
```

---

### **Example Full Binary Tree**

```java
class FullBinaryTree {
    Node root;

    // Sample tree creation
    public void createTree() {
        root = new Node(1);
        root.left = new Node(2);
        root.right = new Node(3);

        root.left.left = new Node(4);
        root.left.right = new Node(5);

        root.right.left = new Node(6);
        root.right.right = new Node(7);
    }

    // Check if tree is full
    public boolean isFull(Node node) {
        if (node == null) return true; // empty tree is full
        if ((node.left == null && node.right != null) || 
            (node.left != null && node.right == null)) {
            return false; // node has exactly 1 child
        }
        return isFull(node.left) && isFull(node.right);
    }

    public static void main(String[] args) {
        FullBinaryTree tree = new FullBinaryTree();
        tree.createTree();
        System.out.println("Is Full Binary Tree? " + tree.isFull(tree.root));
    }
}
```

---

### **Key Points**

1. Leaf nodes are allowed (0 children).
    
2. Internal nodes must have exactly **2 children**.
    
3. Height of a full binary tree with `n` nodes is `log2(n+1)` (if complete).
    

---



###### Tags : [[1 - DSA 🥭]]