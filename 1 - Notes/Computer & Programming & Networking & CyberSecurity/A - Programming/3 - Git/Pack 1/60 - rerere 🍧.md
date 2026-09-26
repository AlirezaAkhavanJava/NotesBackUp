

# **git rerere — what it does**

**rerere = REuse REcorded REsolution**

Git automatically **records how you resolved a merge conflict**.  
Later, if **the exact same conflict appears again**, Git will **auto-apply your previous resolution**.

This saves time when:

- You keep rebasing the same branch
    
- You maintain long-running feature branches
    
- You merge multiple branches that hit the same conflict
    
- You revert and re-apply commits
    
- You cherry-pick repeatedly
    

---

# **How to enable it**

Globally:

```bash
git config --global rerere.enabled true
```

Or per repo:

```bash
git config rerere.enabled true
```

---

# **How it works (internals, quick)**

1. You start a merge that has conflicts.
    
2. Git stores the _conflict hunks_ in `.git/rr-cache/`.
    
3. You fix the conflict.
    
4. Git stores your _resolved version_ in the same cache.
    
5. Next time Git sees the exact conflict → it applies your fix automatically.
    

---

# **Useful commands**

### See what’s in the cache

```bash
git rerere status
```

### Manually trigger resolution

```bash
git rerere
```

### Clear recorded resolutions

```bash
rm -rf .git/rr-cache/*
```

---

# **Real example**

You merge branch A → conflict.  
You fix it. Git saves your fix.

Later you rebase the same branch on main → **same conflict happens** → Git says:

```
Resolved 'src/Service.java' using previous resolution.
```

Boom. No manual conflict fixing.


##### Tags : [[0 - Git 🍋‍🟩]]