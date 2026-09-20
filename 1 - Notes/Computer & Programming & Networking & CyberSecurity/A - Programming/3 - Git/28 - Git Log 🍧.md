


# 🧩 **Git Log — Complete Explanation**

---

## **1. What is `git log`?**

`git log` shows the **commit history** of your Git repository.  
It’s like the **timeline of everything that ever happened** — who did what, when, and why.

---

## **2. Basic Usage**

```bash
git log
```

### Output example:

```
commit 1a2b3c4d5e6f7g8h9i0j
Author: Ethan <ethan@example.com>
Date:   Mon Oct 27 14:35 2025 +0330

    Added employee controller

commit 0z9y8x7w6v5u4t3s2r1q
Author: Ethan <ethan@example.com>
Date:   Mon Oct 27 13:12 2025 +0330

    Fixed DB connection
```

🧠 Shows:

- **commit hash** (unique ID)
    
- **author**
    
- **date**
    
- **commit message**
    

---

## **3. Short & Custom Formats**

You can make `git log` cleaner or shorter:

|Command|Description|Example|
|---|---|---|
|`git log --oneline`|One-line per commit|`1a2b3c4 (HEAD -> main) Add login feature`|
|`git log --decorate`|Shows branch/tags|`(HEAD -> main, origin/main)`|
|`git log --graph`|ASCII tree of branches|Shows visual tree|
|`git log --all`|Shows all branches|Good for global view|

### Combine them 🐐

```bash
git log --oneline --graph --decorate --all
```

✅ **Pro tip:** This is the “pro dev view” of your repo. It shows branch history visually.

Example output:

```
* 8f12a34 (HEAD -> main) Merge branch 'feature'
|\
| * 9a7bc12 (feature) Add API route
* | 1b6e8c4 Update README
|/
* 7f5da11 Initial commit
```

---

## **4. Filtering Logs**

### **By number of commits**

```bash
git log -3
```

→ last 3 commits

### **By author**

```bash
git log --author="Ethan"
```

### **By date**

```bash
git log --since="2 weeks ago"
git log --until="2025-10-01"
```

### **By message**

```bash
git log --grep="fix"
```

→ commits with “fix” in the message

### **By file**

```bash
git log -- <file_path>
```

→ shows history of that file

---

## **5. Pretty Formatting**

You can control how each commit is shown.

```bash
git log --pretty=format:"%h - %an, %ar : %s"
```

**Output:**

```
1a2b3c4 - Ethan, 2 hours ago : Added login route
7d6e5f4 - Ethan, 1 day ago : Fix bug in auth
```

**Common placeholders:**

|Placeholder|Meaning|
|---|---|
|`%h`|short commit hash|
|`%an`|author name|
|`%ae`|author email|
|`%ar`|relative date|
|`%s`|commit message|
|`%d`|decorations (branch, tags)|

---

## **6. View Specific Commits**

```bash
git show <commit_hash>
```

Shows what changed in that commit:

- diff of changes
    
- author/date/message
    

Example:

```bash
git show 1a2b3c4
```

---

## **7. Reverse Order**

```bash
git log --reverse
```

→ shows commits from oldest to newest.

---

## **8. Logs Between Branches**

```bash
git log main..feature
```

→ commits in `feature` not in `main`

```bash
git log feature..main
```

→ commits in `main` not in `feature`

---

## **9. Search Inside Commits**

### Search by commit content (not message):

```bash
git log -S"keyword"
```

→ shows commits where that text was added/removed in the code.

---

## **10. Limit Output to One Line Per Commit**

```bash
git log --pretty=oneline
```

→ good for scripting or quick lookups.

---

## **11. Aliases for Logging (optional but pro move)**

You can make your life easier by adding aliases:

```bash
git config --global alias.lg "log --oneline --decorate --graph --all"
```

Then just type:

```bash
git lg
```

→ clean, compact, visual log.

---

## **12. Example Visual Breakdown**

Imagine this branch tree:

```
* c3 (HEAD -> main) Merge branch 'feature'
|\
| * c2 (feature) Add user model
| * c1 (feature) Add user repo
* | b2 Update config
|/
* b1 Initial commit
```

You can see this exact tree using:

```bash
git log --oneline --graph --decorate --all
```

---

## **13. Combine with Diff**

See what changed in last 2 commits:

```bash
git log -p -2
```

---

## ✅ **Summary Table**

|Action|Command|
|---|---|
|Normal log|`git log`|
|Compact one-line log|`git log --oneline`|
|Show branches visually|`git log --graph --decorate --all`|
|Show last N commits|`git log -5`|
|Search by author|`git log --author="Ethan"`|
|Search by keyword in message|`git log --grep="fix"`|
|Search by code content|`git log -S"User"`|
|Filter by file|`git log -- <file>`|
|View specific commit|`git show <hash>`|


### Tags : [[0 - Git 🍋‍🟩]]