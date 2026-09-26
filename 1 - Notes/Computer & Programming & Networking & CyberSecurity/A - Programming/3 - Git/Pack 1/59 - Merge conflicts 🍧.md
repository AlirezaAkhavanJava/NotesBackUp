
A **Git merge conflict** happens when Git can’t automatically combine changes between two branches — usually because both modified the same line or nearby lines in a file.

### 🧠 When it happens:

- Two people edited the same part of a file.
    
- One deleted a file that another modified.
    
- The same line was changed differently in both branches.
    

---

### ⚔️ Example:

You’re on `main`, and you merge `feature`:

```bash
git merge feature
```

Git says:

```
Auto-merging src/App.java
CONFLICT (content): Merge conflict in src/App.java
```

---

### 📄 What you’ll see in the file:

```java
public String getName() {
<<<<<<< HEAD
    return "Ethan";
=======
    return "Mark";
>>>>>>> feature
}
```

- `<<<<<<< HEAD` → your current branch’s version
    
- `=======` → separator
    
- `>>>>>>> feature` → the other branch’s version
    

---

### 🧰 How to fix:

1. **Open the conflicted file** and decide which change (or mix) to keep.  
    Example fix:
    
    ```java
    public String getName() {
        return "Ethan Davis";
    }
    ```
    
2. **Mark conflict as resolved:**
    
    ```bash
    git add src/App.java
    ```
    
3. **Complete the merge:**
    
    ```bash
    git commit
    ```
    

---

### 🧽 Tips:

- To abort the merge:
    
    ```bash
    git merge --abort
    ```
    
- To see conflicts:
    
    ```bash
    git status
    ```
    
- To use a visual tool:
    
    ```bash
    git mergetool
    ```
    




##### Tags : [[0 - Git 🍋‍🟩]]