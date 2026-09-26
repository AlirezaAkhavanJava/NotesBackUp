### What is `git cherry-pick`?

`git cherry-pick` is a powerful Git command that lets you pick one or more existing commits from anywhere in your repository's history and apply them as new commits on your current branch.

It's like "copy-pasting" specific commits instead of merging or rebasing entire branches.

![[Pasted image 20251119153445.png]]

### When to use it
- Apply a bug fix from `main` to a release branch without merging everything.
- Bring in only certain feature commits from another branch.
- "Undo" a commit by cherry-picking everything except the bad one.
- Move or duplicate commits to another branch.

### Basic syntax
```bash
git cherry-pick <commit-hash>          # one commit
git cherry-pick <commit1> <commit2>    # multiple commits (in order)
git cherry-pick <older-commit>^..<newer-commit>  # a range (note the ^)
git cherry-pick branch-name            # cherry-pick commits that are on branch-name but not on current branch
```

### Common examples

1. **Pick a single commit**
   ```bash
   git checkout feature/login
   git cherry-pick a1b2c3d4   # applies commit a1b2c3d4 as a new commit on feature/login
   ```

2. **Pick multiple commits**
   ```bash
   git cherry-pick abc123 def456 ghi789
   ```

3. **Pick a range of commits** (inclusive of the older one)
   ```bash
   git cherry-pick abc123^..ghi789
   ```

4. **Pick all commits that exist on hotfix-branch but not on current branch**
   ```bash
   git cherry-pick hotfix-branch
   ```

### Important options

| Option                  | Meaning                                                                 |
|-------------------------|-------------------------------------------------------------------------|
| `-e` or `--edit`        | Open the commit message in your editor before committing               |
| `-x`                    | Add a line to the commit message `(cherry picked from commit ...)`     |
| `--no-commit` or `-n`   | Apply changes but don't create a commit (useful for combining)         |
| `--continue`            | Continue after resolving conflicts                                      |
| `--abort`               | Cancel the entire cherry-pick operation                                 |
| `--quit`                | Stop cherry-picking but keep the changes you've already applied        |
| `--mainline <n>`        | For merge commits: choose which parent to pick (rarely needed)         |

### What happens during conflicts
If the commit can't be applied cleanly:
- Git stops before creating the commit
- Shows conflicted files
- You resolve them normally (`git add`, etc.)
- Then run:
  ```bash
  git cherry-pick --continue   # to finish with the original commit message
  # or
  git cherry-pick --abort      # to cancel everything
  ```

### Real-world example: Hotfix to multiple branches

```bash
# You have a bug on main that was fixed with commit deadbeef
git checkout main
git pull

# Apply the fix to older release branches
git checkout release/2.0
git cherry-pick -x deadbeef    # -x records where it came from

git checkout release/1.9
git cherry-pick -x deadbeef
```

### Common pitfalls
- Cherry-picking a merge commit is tricky (Git asks which parent to use).
- Repeated cherry-picking the same commit creates duplicates.
- Use `-x` in shared repos so others know it was cherry-picked (helps avoid picking it again).

### Alternatives
| Goal                          | Better command?                  |
|-------------------------------|----------------------------------|
| Bring many commits            | `git merge` or `git rebase`      |
| Move a whole feature branch   | `git rebase --onto`              |
| Apply a patch                 | `git apply` or `git am`          |

In short: `git cherry-pick` is perfect when you want surgical precision with commits instead of merging entire branches.



###### Tags : [[0 - Git 🍋‍🟩]]