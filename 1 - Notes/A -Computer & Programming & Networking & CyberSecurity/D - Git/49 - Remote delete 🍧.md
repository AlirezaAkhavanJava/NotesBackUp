
To **drop (delete) a remote** in Git, use the `git remote remove` command.

---

### Command: Delete a Remote

```bash
git remote remove <remote-name>
```

or (alias):

```bash
git remote rm <remote-name>
```

---

### Example

```bash
# Remove the remote named "origin"
git remote remove origin
```

```bash
# Remove a secondary remote like "upstream"
git remote rm upstream
```

---

### Verify It’s Gone

```bash
git remote -v
```

→ Should **no longer list** the removed remote.

---

### What Happens When You Remove a Remote?

| Effect | Description |
|-------|-------------|
| Local branches stay | Your local branches (e.g., `main`, `feature/login`) are **not deleted** |
| Remote-tracking branches removed | `origin/main`, `origin/feature/*` are gone |
| You can’t push/pull | Until you add a new remote |
| No effect on actual remote server | Only your local Git config is changed |

---

### Common Use Cases

| Scenario | Command |
|--------|--------|
| Wrong remote URL | `git remote remove origin` → then `git remote add origin <correct-url>` |
| Fork → want to switch upstream | `git remote remove upstream` → `git remote add upstream <new-url>` |
| Cleanup old remotes | `git remote rm old-server` |

---

### How to Re-Add a Remote (After Dropping)

```bash
git remote add origin https://github.com/user/repo.git
# or SSH:
git remote add origin git@github.com:user/repo.git
```

Then verify:

```bash
git remote -v
```

---

### Bonus: Rename Instead of Remove?

```bash
git remote rename old-name new-name
```

Example:
```bash
git remote rename origin old-origin
```

---

### Warning: Don’t Do This

```bash
# NEVER do this — it deletes your LOCAL branch!
git branch -d origin/main   # Wrong! This is a local tracking branch
```

→ `origin/main` is **not** the remote — it’s your local copy of it.

---

### TL;DR

```bash
git remote remove origin    # Drop the remote
git remote -v               # Confirm it's gone
git remote add origin <url> # Add it back (if needed)
```

Done! Your remote is **dropped locally** — safely and cleanly.

---

Need to **delete a remote branch** instead? That’s different:
```bash
git push origin --delete branch-name
```

Let me know which one you meant!

##### Tags : [[0 - Git 🍋‍🟩]]