

# 🚀 **What “ours” and “theirs” actually mean**

These terms appear during merges when Git needs you to choose which version of the file to keep.

### **OURS → the version from the branch you are currently on**

The branch you _checked out_ before running `git merge`.

### **THEIRS → the version from the branch you are merging into yours**

The branch you _specified_ in the merge command.

---

# 🔍 Example

You are on branch **feature**:

```bash
git checkout feature
git merge main
```

- **OURS** = `feature`
    
- **THEIRS** = `main`
    

Git uses “ours”/“theirs” based on **your current branch**, not based on moral correctness.

---

# 🎯 How this relates to merge conflict markers

```
<<<<<<< HEAD      ← ours
YOUR version
=======
THEIR version
>>>>>>> main      ← theirs
```

- The top section (`<<<<<<< HEAD`) = **OURS**
    
- The bottom section (`>>>>>>> main`) = **THEIRS**
    

---

# 🛠 When you use these labels

## 1. During a merge resolution

When editing conflict markers, choosing “ours” means **keep the top part**, choosing “theirs” means **keep the bottom part**.

## 2. Using `git checkout --ours` / `--theirs`

```bash
git checkout --ours   file.csv
git checkout --theirs file.csv
```

- `--ours` = keep **your branch’s version**
    
- `--theirs` = keep **the other branch’s version**
    

## 3. Using merge strategies

Force Git to ignore their changes:

```bash
git merge -s ours main
```

This records the merge but uses **your version entirely**.

Opposite:

```bash
git merge -X theirs main
```

---

# 🧠 Mental model (simple + accurate)

- **OURS = the branch you are standing on**
    
- **THEIRS = the branch you are pulling into your branch**
    

It doesn’t matter what the branches are named.



##### Tags : [[0 - Git 🍋‍🟩]]