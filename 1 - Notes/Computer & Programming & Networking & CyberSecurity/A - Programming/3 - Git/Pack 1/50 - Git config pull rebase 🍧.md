`git config pull.rebase` is a **Git configuration setting** that tells Git how to handle `git pull` when your local branch has commits that the remote branch doesn’t.

By default, `git pull` does two things:

1. Fetches changes from the remote (`git fetch`).
    
2. Merges those changes into your current branch (`git merge`).
    

The `pull.rebase` option changes step 2: instead of merging, it **rebases your local commits on top of the remote branch**.

- **Merge (default)**: Combines histories and may create a merge commit.
    
- **Rebase**: Moves your local commits to appear **after** the remote commits, keeping history linear.
    

**Values:**

- `true` → Always rebase instead of merge.
    
- `false` → Always merge (default).
    
- `interactive` → Rebase interactively.
    

**Command example:**

```bash
# Make pull always rebase
git config --global pull.rebase true
```

✅ Effect: Cleaner history, no unnecessary merge commits.

***

### **Git Config Note: Pull Strategy**

#### **The Core Idea**
When you run `git pull`, Git needs to combine remote changes with your local work. There are two main ways to do this: **merge** (safe) and **rebase** (clean history). The command `git config --add --local pull.rebase false` tells Git to always use the **merge** strategy.

---

#### **Key Concepts**

**1. What is `git pull`?**
- `git fetch` (downloads changes) + `git merge`/`rebase` (integrates them)

**2. Merge vs. Rebase**
- **Merge**: Creates a "merge commit" that preserves both histories
  - ✅ Safe, shows true history
  - ❌ Can create messy commit graphs

- **Rebase**: Moves your commits to top of remote changes
  - ✅ Clean, linear history
  - ❌ Rewrites history (can be dangerous)

**3. Configuration Levels**
- **--local**: Only this repository (`.git/config`)
- **--global**: All your repositories
- **--system**: All users on computer

---

#### **The Command Explained**
```bash
git config --add --local pull.rebase false
```
- **`--add --local`**: "Add this setting to my current repository only"
- **`pull.rebase false`**: "When pulling, use MERGE instead of REBASE"

**Result**: Your `git pull` will now create merge commits instead of rebasing.

---

#### **When You'd Use This**
- You prefer the safety of merge commits
- You're collaborating with others and want clear merge points
- You find rebase confusing or dangerous

---

#### **Quick Examples**
```bash
# Check current setting
git config pull.rebase
# (returns 'false' after our command)

# Set globally (all projects)
git config --global pull.rebase false

# One-time merge pull
git pull --no-rebase

# One-time rebase pull  
git pull --rebase
```

---

#### **Visual Result**
```
MERGE STRATEGY (what we set)          REBASE STRATEGY
*---*---*---M  (merge commit)         *---*---*---*---* (linear)
     \     /                              (your commits moved)
      *---* (remote changes)             (remote changes)
```

**Bottom Line**: You've told Git "I want to see merge commits when I pull, keeping the history exactly as it happened."



##### Tags : [[0 - Git 🍋‍🟩]]