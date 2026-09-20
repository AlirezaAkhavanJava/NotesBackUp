
# Checkout Conflict

We've _manually_ edited files to resolve conflicts, but it turns out Git has some built-in tools to help us out.

The [`git checkout` command](https://www.git-scm.com/docs/git-checkout) can checkout the individual changes during a merge conflict using the `--theirs` or `--ours` flags.

- `--ours` will overwrite the file with the changes from the branch you are currently on and merging into
- `--theirs` will overwrite the file with the changes from the branch you are merging into the current branch

```bash
git checkout --theirs path/to/file
```

---
# ✅ What this is about

You’re learning how to resolve **merge conflicts** using:

```
git checkout --ours
git checkout --theirs
```

These commands let you **automatically pick one side of the conflict** instead of manually editing the file.

---

# 🧠 The important rule (most people get this wrong)

**OURS = the branch you are currently on.**  
**THEIRS = the branch you are merging into your branch.**

It does _not_ mean “the code is ours” or “the code is theirs”.  
It is purely based on which branch is checked out.

---

# 🧩 During a merge

Example:

```bash
git checkout feature
git merge main
```

- **OURS** = `feature` (your current branch)
    
- **THEIRS** = `main` (the branch you merged into feature)
    

---

# 🛠 What the commands actually do

### **Use your version (discard their changes)**

```bash
git checkout --ours path/to/file
```

Git replaces the file's content with **your branch’s version**, wiping the incoming changes.

### **Use their version (discard your changes)**

```bash
git checkout --theirs path/to/file
```

Git replaces the file with **the version from the branch being merged in**.

---

# 🔥 Example with conflict markers

Conflict:

```
<<<<<<< HEAD
x = 1
=======
x = 2
>>>>>>> main
```

Running:

```bash
git checkout --ours file
```

You get:

```
x = 1
```

Running:

```bash
git checkout --theirs file
```

You get:

```
x = 2
```

---

# ✔ Why this is useful

- You can quickly resolve conflicts in _many_ files
    
- You don’t need to open an editor
    
- Works great in rebases, cherry-picks, and merges
    


##### Tags : [[0 - Git 🍋‍🟩]]