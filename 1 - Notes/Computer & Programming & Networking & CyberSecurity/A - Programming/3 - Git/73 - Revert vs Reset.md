![[Pasted image 20251119152133.png]]


- `git reset --soft`: Undo _commits_ but keep changes staged
- `git reset --hard`: Undo _commits_ and discard changes
- `git revert`: Create a _new commit_ that undoes a previous commit



### **1. `git revert`** – Safe “undo” for public history

- Creates a **new commit** that **reverses the changes** of a previous commit.
    
- Doesn’t touch history; safe for shared repositories.
    
- Example:
    

```bash
git revert <commit-hash>
```

- If commit `A` added a line `foo`, revert creates a new commit that **removes `foo`**.
    
- History looks like:
    

```
... -> A -> Revert-A
```

✅ Use when: You already pushed commits to a shared repo and need to undo changes **without rewriting history**.

---

### **2. `git reset`** – History-rewriting “undo”

![[Pasted image 20251119152940.png]]
- Moves your branch pointer backward to a specific commit. Can affect staged files or working directory depending on mode:
    

|Mode|Effect|
|---|---|
|`--soft`|Keep changes in staging area (index). Only moves HEAD.|
|`--mixed` (default)|Keep changes in working directory, but unstage them.|
|`--hard`|**Deletes changes** in staging area and working directory. **Permanent loss** if not backed up.|

Example:

```bash
git reset --hard HEAD~1
```

- Moves branch one commit back and wipes the last commit’s changes completely.
    

⚠️ Use with caution. Never `--hard` on commits already pushed to shared repos.

---

### **Quick mental model**

- **`revert`** = “Undo this commit safely, keep history.”
    
- **`reset`** = “Rewind history, optionally wipe changes.”
    



###### Tags : [[0 - Git 🍋‍🟩]]