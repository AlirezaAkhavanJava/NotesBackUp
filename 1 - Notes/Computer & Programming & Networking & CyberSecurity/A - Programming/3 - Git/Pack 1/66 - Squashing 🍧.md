![[Pasted image 20251117160538.png]]
### What is "git squash"?

**Squashing** in Git means combining multiple commits into a single commit. It's most commonly done using `git rebase -i` (interactive rebase) or during a merge with the `--squash` option.

Squashing is extremely useful when:
- You have many small, messy commits on a feature branch (e.g., "fix typo", "add debug log", "oops fix again").
- You want to clean up history before merging into `main`/`master` or before creating a pull request.
- You want a cleaner, more readable project history.

### Two main ways to squash

#### 1. Squash commits on the current branch (most common) – using interactive rebase

Let’s say your last 4 commits are messy and you want to combine them into one:

```bash
git rebase -i HEAD~4
```

or (newer Git versions ≥2.26):

```bash
git rebase -i --autosquash HEAD~4
```

This opens an editor that looks like this:

```
pick a1b2c3d First commit
pick e4f5g6h Second commit
pick i7j8k9l Third commit
pick m0n1o2p Fourth commit

# Rebase instructions...
```

To squash the last three into the first one, change `pick` to `squash` (or just `s`):

```
pick a1b2c3d First commit
squash e4f5g6h Second commit
squash i7j8k9l Third commit
squash m0n1o2p Fourth commit
```

Save and close. Git will:
1. Combine all those commits into one.
2. Open another editor so you can edit the final commit message (it shows all the original messages so you can craft a good one).

Result: Your branch now has only one new commit instead of four.

You can also use `fixup` instead of `squash` if you want to completely discard the later commit messages:

```
pick a1b2c3d First commit
fixup e4f5g6h Second commit
fixup i7j8k9l Third commit
```

#### 2. Squash when merging a branch – using `git merge --squash`

If you have a feature branch and want to apply all its changes as a single commit on `main`:

```bash
git checkout main
git merge --squash feature-branch
git commit                  # create the single squashed commit
```

This stages all changes from `feature-branch` but does not create a merge commit automatically. You then commit manually (usually with a good summary message).

### Quick everyday workflow example (recommended for clean PRs)

```bash
# While on your feature branch
git rebase -i origin/main        # or HEAD~N if you know how many commits

# In the editor, squash everything except the very first commit
pick  abc123 Initial work on feature
squash def456 More work
squash ghi789 Fix bug
squash jkl012 Polish

# Save → edit the final commit message → save again

git push --force-with-lease     # update the remote branch safely
```

### Important warnings

- Never squash commits that are already pushed and shared with others (unless everyone on the team is okay with force-pushing).
- Use `--force-with-lease` instead of `--force` when pushing squashed history to avoid overwriting someone else’s work.

### Summary

- **Squashing = combining multiple commits into one**
- Primary tool: `git rebase -i` (interactive rebase)
- Alternative: `git merge --squash`
- Purpose: cleaner history, better pull requests, easier code reviews



###### Tags : [[0 - Git 🍋‍🟩]]