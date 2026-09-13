
### `git stash apply` – What it does and how to use it with a message

`git stash` saves your current changes (both staged and unstaged) in a stack, and `git stash apply` reapplies the most recent stash (or a specific one) **without removing it from the stash list**.

Unlike `git stash pop`, which applies and then deletes the stash, `apply` lets you re-apply the same stash multiple times (e.g., to different branches).

#### Basic usage

```bash
# Apply the most recent stash (stash@{0})
git stash apply

# Apply a specific stash by its index or ref
git stash apply stash@{2}
git stash apply 1            # shorthand for stash@{1}
```

#### How to see the message/description of a stash

When you create a stash, you can (and should!) add a descriptive message:

```bash
git stash push -m "WIP: fixing login form validation"
# or the older syntax
git stash save "WIP: fixing login form validation"
```

To see the list of stashes with their messages:

```bash
git stash list --oneline
# Example output:
# stash@{0}: WIP: fixing login form validation
# stash@{1}: On feature/user-profile: added avatar upload
# stash@{2}: refs/stash: On main: emergency hotfix for payment bug
```

Or more detailed:

```bash
git stash list
# Shows commit hash, parent, and the message
```

#### Applying a stash and seeing its message at the same time

Git does **not** automatically print the message when you run `git stash apply`.  
If you want to see the message while applying, combine it with `git stash list`:

```bash
# Show what you're about to apply
git stash list | grep stash@{0}

# Then apply it
git stash apply
```

Or use this handy one-liner to apply and echo the message:

```bash
git stash apply stash@{0} && git log --oneline -1 stash@{0}
```

#### Applying a stash by its message (partial match)

Git doesn't let you apply directly by message, but you can script it:

```bash
# Apply the stash that contains "login form" in the message
git stash apply $(git stash list | grep "login form" | cut -d: -f1)
```

Or as a reusable alias in your ~/.gitconfig:

```ini
[alias]
  stash-apply = "!f() { git stash apply $(git stash list | grep \"$1\" | head -1 | cut -d: -f1); }; f"
```

Then use it like:

```bash
git stash-apply "login form"
```

#### Summary table

| Command                          | Applies stash | Removes from list | Shows message automatically | Can re-apply later |
|----------------------------------|---------------|-------------------|-----------------------------|--------------------|
| `git stash apply`                | Yes           | No                | No                          | Yes                |
| `git stash apply stash@{n}`      | Yes           | No                | No                          | Yes                |
| `git stash pop`                  | Yes           | Yes               | No                          | No                 |
| `git stash apply` + `git log -1 stash` | Yes       | No                | Yes (manually)              | Yes                |

**Best practice**: Always stash with a clear message (`git stash push -m "your message"`) — it makes `git stash list` much more useful and prevents confusion later.
##### Tags : [[0 - Git 🍋‍🟩]]