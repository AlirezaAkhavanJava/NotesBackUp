


# 🧩 **Merge Commit (in Git)**

---

## **1. Definition**

A **merge commit** is a **special commit created by Git** when combining two (or more) branches **that have diverged** — meaning both have new commits since they split.

👉 In simple words:

> It’s a commit that joins two different histories together.

---

## **2. When It Happens**

It occurs **only** when:

- You merge a branch into another,
    
- **and** both branches have new commits since they last shared a common ancestor.
    

So Git can’t just move a pointer (fast-forward).  
Instead, it must create a **new commit** that merges both changes.

---

## **3. Visual Example**

### Before merge:

```
main:    A---B---C
feature:      D---E
```

Both changed after commit `B`.

Now run:

```bash
git checkout main
git merge feature
```

### After merge:

```
main:    A---B---C---M
                 /   \
           D---E      (M = merge commit)
```

✅ `M` is the **merge commit** — it ties both lines of development into one unified history.

---

## **4. What Git Does Internally**

1. Finds the **common ancestor** of both branches.
    
2. Compares differences from that ancestor to each branch.
    
3. Merges both sets of changes into a new commit (`M`).
    
4. Gives `M` **two parent commits** (one from each branch).
    

---

## **5. Checking Merge Commits**

You can view merges with:

```bash
git log --merges
```

Or view a specific merge commit:

```bash
git show <merge_commit_hash>
```

You’ll see something like:

```
commit 8a7b6c5d (HEAD -> main)
Merge: 4d2e1f3 9c8b7a6
Author: Ethan <ethan@example.com>
Date:   Mon Oct 27 2025

    Merge branch 'feature' into main
```

- `Merge:` line shows the **two parents** of the merge.
    

---

## **6. Merge Commit Command Example**

```bash
# create main
git init merge-demo
echo "v1" > app.txt
git add .
git commit -m "Initial commit"

# create and switch to feature branch
git checkout -b feature
echo "feature" >> app.txt
git commit -am "Feature commit"

# go back to main and make another commit
git checkout main
echo "main update" >> app.txt
git commit -am "Main commit"

# now merge (creates merge commit)
git merge feature
```

Output:

```
Auto-merging app.txt
Merge made by the 'recursive' strategy.
```

✅ A new **merge commit** is now created.

---

## **7. Viewing It as a Graph**

```bash
git log --oneline --graph --decorate --all
```

Example:

```
*   4e5f6a7 (HEAD -> main) Merge branch 'feature'
|\
| * 9c8b7a6 (feature) Feature commit
* | 3d2c1b0 Main commit
|/
* 1a2b3c4 Initial commit
```

Notice the **split and rejoin** — that’s your merge commit in action.

---

## **8. When to Use Merge Commits**

✅ Use merge commits when:

- You want to **preserve full branch history**.
    
- You want to **see when branches were merged** clearly.
    
- You’re working in a **team** (GitHub’s default PR merge creates this).
    

---

## **9. When to Avoid Merge Commits**

❌ Avoid them when:

- You prefer **clean linear history** → then use **rebase** instead.
    
- You don’t need to record every branch merge.
    

---

## **10. Force Merge Commit (even if fast-forward possible)**

Sometimes, even if a fast-forward is possible, you may want a merge commit to keep branch structure visible:

```bash
git merge --no-ff feature -m "Merge feature branch"
```

This forces Git to **always** create a merge commit.

---

## **11. Merge Commit Conflicts**

If both branches modify the same line → conflict happens.

You’ll see:

```text
<<<<<<< HEAD
main changes
=======
feature changes
>>>>>>> feature
```

Fix it manually → `git add <file>` → `git commit`  
That final commit is your **merge commit**.

---

## ✅ **Summary**

|Concept|Description|
|---|---|
|**Definition**|Commit that joins two diverged branches|
|**Created when**|Both branches have new commits|
|**Has**|Two parent commits|
|**Command**|`git merge <branch>`|
|**View**|`git log --merges`|
|**Force it**|`git merge --no-ff <branch>`|
|**Pros**|Full history, clarity|
|**Cons**|Can clutter history if overused|

---


### Tags : [[0 - Git 🍋‍🟩]]