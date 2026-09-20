

The `git diff` command shows the differences between files in your Git repository. It’s basically Git’s way of saying, _“Hey, here’s what changed since the last snapshot.”_

Here are the common usages:

1. **Check changes in your working directory (unstaged changes):**
    

```bash
git diff
```

- Shows what you changed but haven’t staged yet.
    

2. **Check changes staged for commit:**
    

```bash
git diff --cached
```

or

```bash
git diff --staged
```

- Shows what’s in the staging area ready to be committed.
    

3. **Check changes between commits:**
    

```bash
git diff <commit1> <commit2>
```

- Shows differences between two commits.
    

4. **Check changes for a specific file:**
    

```bash
git diff <file>
```

5. **Side-by-side view (optional, needs `--color-words` or `--word-diff`):**
    

```bash
git diff --word-diff
```

💡 Quick tip: `git status` is your friend before `git diff`—it tells you which files have changed and whether they are staged or not.




##### Tags : [[0 - Git 🍋‍🟩]]