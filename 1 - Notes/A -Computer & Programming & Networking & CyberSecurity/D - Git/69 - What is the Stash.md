The `git stash` command stores your changes in a [stack (LIFO) data structure](https://www.youtube.com/watch?v=SD45xbKReT4). That means that when you retrieve your changes from the stash, you'll always get the most recent changes first.

![[Pasted image 20251118150853.png]]

### What is "the Stash" in Git?

`git stash` (often just called **the stash**) is Git's built-in mechanism to **temporarily save unfinished changes** so you can switch context (e.g., switch branches, pull updates, or fix a bug) without committing half-done work.

Think of it as a **quick "hide this mess for a minute"** button.

#### How it works (the stash stack)
- Every time you run `git stash` (or `git stash push`), Git takes:
  - Your current **working directory changes** (uncommitted modifications)
  - Your **staged changes** (what’s in the index)
  - Optionally untracked files (`git stash -u`) or even ignored files (`git stash -a`)
- It saves all of that as a single entry on a **LIFO stack** (Last In, First Out).
- Your working tree is then reset to match the last commit (clean state).

The stack looks like this:
```
stash@{0}  ← most recent (top of the stack)
stash@{1}
stash@{2}
...
```

#### Common stash commands

| Command                        | What it does                                                                 | Typical use |
|--------------------------------|-------------------------------------------------------------------------------|-------------|
| `git stash` or `git stash push`| Save changes on the stack (with optional message: `-m "fix login bug"`)      | Hide work   |
| `git stash list`               | Show all stashed entries                                                      | See what’s saved |
| `git stash show`               | Summary of the top stash (`stash@{0}`)                                        | Quick peek  |
| `git stash show -p`            | Full diff of the top stash                                                    | Detailed view |
| `git stash apply`              | Re-apply the top (or specified) stash **without removing** it from the stack| Try it out safely |
| `git stash pop`                | Apply + remove from stack (if no conflicts)                                   | "I’m done, bring it back" |
| `git stash drop stash@{n}`     | Delete a specific stash entry                                                 | Clean up    |
| `git stash clear`              | Delete **all** stashes                                                        | Nuke everything |
| `git stash branch new-branch`  | Create a new branch from a stash (super useful when conflicts are messy)     | Recover safely |

#### Real-world examples

```bash
# You're on feature/login, have uncommitted changes, but need to fix a hotbug
git stash push -m "half-done login validation"

# Switch to main, fix the bug, push, come back
git switch main
# ...fix and commit...
git switch feature/login

# Bring your work back
git stash pop          # or git stash apply if you want to be cautious
```

#### Important things to know
- Stashes are **local** to your repository (they don’t get pushed).
- They are saved in `.git/refs/stash` and survive reboots.
- If you have multiple stashes, always check `git stash list` first.
- Stashes can include **untracked** files (`git stash -u`) or even **ignored** ones (`git stash -a`).

#### Analogy
It’s like hitting "Save Draft" in an email instead of sending a half-written message — you can come back later exactly where you left off.

In short: **The stash = Git’s emergency "pause button" for your work-in-progress.** Super handy once you get used to it! Let me know if you want a cheat sheet or common workflows.

###### Tags : [[0 - Git 🍋‍🟩]]