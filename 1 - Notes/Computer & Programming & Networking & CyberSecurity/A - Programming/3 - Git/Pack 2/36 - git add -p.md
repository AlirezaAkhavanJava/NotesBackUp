
`git add -p` (short for `git add --patch`) is an interactive way to stage changes in Git. Instead of staging entire files, it lets you review your changes hunk by hunk and decide what to include in the next commit.

## How it works

When you run `git add -p`, Git breaks your unstaged changes into **hunks** (contiguous blocks of modified lines) and prompts you for each one with a menu like:

```
@@ -1,5 +1,6 @@
 context line
-removed line
+added line
 context line

Stage this hunk [y,n,q,a,d,s,e,?]?
```

## Common responses

| Key | Meaning |
|-----|---------|
| `y` | Stage this hunk |
| `n` | Don't stage this hunk |
| `q` | Quit — don't stage this or any remaining hunks |
| `a` | Stage this and all remaining hunks in the file |
| `d` | Don't stage this or any remaining hunks in the file |
| `s` | Split the hunk into smaller hunks (if possible) |
| `e` | Manually edit the hunk before staging |
| `?` | Show help |

## Why use it

- **Cleaner commits**: Stage only related changes, leaving unrelated edits for a separate commit.
- **Avoid committing debug code**: Skip `console.log`/`print` lines or temporary hacks.
- **Partial-file staging**: Useful when one file contains multiple logical changes.
- **Review before staging**: Forces you to look at each change rather than blindly `git add .`.

## Related commands

- `git add -i` — interactive mode with broader options (status, update, patch, etc.)
- `git add -p <file>` — restrict patching to a specific file
- `git stash -p` — same hunk-by-hunk selection but for stashing
- `git checkout -p` / `git reset -p` — selectively discard or unstage hunks

## Tips

- Use `s` to split large hunks; if Git can't split further, use `e` to edit manually.
- The `e` option opens the hunk in your editor — delete `+` lines you don't want to stage, keep `-` lines intact, and save.
- Combine with `git commit` right after to lock in a focused change set.


[[0 - Git 🍋‍🟩]]