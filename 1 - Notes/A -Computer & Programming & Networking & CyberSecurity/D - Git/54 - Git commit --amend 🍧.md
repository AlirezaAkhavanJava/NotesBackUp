
`git commit --amend` is a powerful Git command that lets you **modify the most recent commit** — either by changing its message, adding forgotten files, or both.

---

### When to Use It
- You just committed but forgot to add a file.
- You want to fix a typo in the commit message.
- You want to combine changes into the previous commit (instead of making a new one).

> ⚠️ **Warning**: Only use `--amend` on commits that **haven't been pushed** to a shared remote yet (or you're okay with force-pushing).

---

### Basic Usage

#### 1. **Change the commit message only**
```bash
git commit --amend
```
- Opens your editor with the current commit message.
- Edit and save → replaces the last commit.

#### 2. **Add forgotten files and amend**
```bash
git add forgotten-file.txt
git commit --amend
```
- Stages the new file and includes it in the previous commit.

#### 3. **Amend with a new message (no editor)**
```bash
git commit --amend -m "New descriptive commit message"
```

#### 4. **Keep original message but add files**
```bash
git add missing-file.js
git commit --amend --no-edit
```
- `--no-edit` skips opening the editor (keeps old message).

---

### Example Workflow

```bash
# You made a commit
git add file1.txt
git commit -m "Add file1"

# Oops! Forgot file2.txt
git add file2.txt

# Amend the last commit to include file2.txt
git commit --amend --no-edit
```

Now `git log` shows only **one** commit with both files.

---

### What Actually Happens?
- Git creates a **new commit** replacing the old one.
- The old commit is detached (eventually garbage collected).
- The commit hash (SHA) **changes**.

---

### If You've Already Pushed

Don’t amend directly. Instead:

```bash
git commit --amend
git push --force-with-lease origin main
```

> `--force-with-lease` is safer than `--force` — it checks no one else pushed in the meantime.

---

### Undo an Amend? (If you mess up)

If you amended and want to go back:

```bash
git reflog          # Find the old commit hash (before amend)
git reset --hard HEAD@{1}   # Or the specific hash
```

---

### Pro Tips
- Use `--amend` early and often **before pushing**.
- Avoid amending published commits in team branches.
- Combine with `git add -p` for precise staging before amending.



##### Tags : [[0 - Git 🍋‍🟩]]