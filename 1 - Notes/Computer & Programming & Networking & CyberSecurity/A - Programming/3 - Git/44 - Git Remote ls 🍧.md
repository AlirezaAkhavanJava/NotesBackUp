> The command `git ls-remote` is used to **list references in a remote repository** without actually cloning it. It shows you the branches, tags, and their commit hashes.

---

### Syntax:

```bash
git ls-remote <remote-url-or-name>
```

- `<remote-url-or-name>` → Either the URL of a Git repo (HTTPS/SSH) or a remote name you’ve added with `git remote add`.
    

---

### Example:

```bash
git ls-remote https://github.com/username/repo.git
```

Output looks like:

```
e1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9 refs/heads/main
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8 refs/tags/v1.0
```

- Left column → commit hash
    
- Right column → reference (branch or tag)
    

---

### With a named remote:

```bash
git remote add origin https://github.com/username/repo.git
git ls-remote origin
```

This does the same thing, but using your remote alias `origin`.

---

It’s useful to:

- Check what branches/tags exist before cloning or fetching.
    
- Verify that a remote URL is valid.
    
- Inspect a remote repo without downloading all data.
    

---


##### Tags : [[0 - Git 🍋‍🟩]]