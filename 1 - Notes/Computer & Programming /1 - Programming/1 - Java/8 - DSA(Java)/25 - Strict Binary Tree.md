
A **Strict Binary Tree** (also called a **Full Binary Tree**) is a type of binary tree where **every node has either 0 or 2 children**. No node can have only one child.

Here’s a complete breakdown and a Java implementation:

---

### **Definition**

- Node with **0 children** → leaf node.
    
- Node with **2 children** → internal node.
    
- Node with **1 child** → **not allowed** in strict binary tree.
    

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

### **Strict Binary Tree Example**

```java
class StrictBinaryTree {
    Node root;

    // Utility function to create tree
    public void createSampleTree() {
        root = new Node(1);
        root.left = new Node(2);
        root.right = new Node(3);

        root.left.left = new Node(4);
        root.left.right = new Node(5);

        root.right.left = new Node(6);
        root.right.right = new Node(7);
    }

    // Check if tree is strict
    public boolean isStrict(Node node) {
        if (node == null) return true;  // empty tree is strict
        if ((node.left == null && node.right != null) || 
            (node.left != null && node.right == null)) {
            return false;  // node has only one child
        }
        return isStrict(node.left) && isStrict(node.right);
    }

    public static void main(String[] args) {
        StrictBinaryTree tree = new StrictBinaryTree();
        tree.createSampleTree();

        System.out.println("Is Strict Binary Tree? " + tree.isStrict(tree.root));
    }
}
```

---

### **Explanation**

1. `isStrict(node)` recursively checks:
    
    - If a node has only one child → return `false`.
        
    - Else → check left and right subtrees.
        
2. Leaf nodes are fine (0 children).
    
3. Internal nodes must have **exactly 2 children**.
    

---

### **Sample Tree Visualization**

```
        1
      /   \
     2     3
    / \   / \
   4   5 6   7
```

✅ This is a strict binary tree.

---


##### Tags : [[1 - DSA 🥭]]