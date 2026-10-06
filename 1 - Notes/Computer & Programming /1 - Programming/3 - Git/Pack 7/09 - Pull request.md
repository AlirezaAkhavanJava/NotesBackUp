
The standard workflow is:

```text
local branch
    ↓
git push
    ↓
GitHub branch
    ↓
Pull Request
    ↓
main
```

Let's use your `add_scanner` branch as the example.

## 1. Make sure you're on the branch

```bash
git switch add_scanner
```

Check:

```bash
git status
```

You should see:

```text
On branch add_scanner
```

---

## 2. Commit your changes

```bash
git add .
git commit -m "Add scanner functionality"
```

Check the history if needed:

```bash
git log --oneline --graph
```

---

## 3. Push the branch to GitHub

If this is the **first time** you're pushing this branch:

```bash
git push -u origin add_scanner
```

The important part is:

```text
-u origin add_scanner
  │      │
  │      └── remote branch
  └───────── GitHub remote
```

After this, Git remembers the relationship:

```text
local add_scanner
        ↕
origin/add_scanner
```

So future pushes can simply be:

```bash
git push
```

---

# 4. Create the Pull Request

Go to your repository on GitHub.

GitHub will usually show something like:

> `add_scanner had recent pushes`  
> **Compare & pull request**

Click it.

You'll get:

```text
base repository:  megacorp
base:             main

head repository:  megacorp
compare:          add_scanner
```

This means:

```text
add_scanner ────────► main
              PR
```

Set the title:

```text
Add scanner functionality
```

Describe what you changed, then click:

**Create pull request**

---

# 5. What happens now?

Your branch stays separate:

```text
main
 │
 A──B
     \
      C──D──E
            ↑
       add_scanner
```

The Pull Request is essentially GitHub saying:

> "I want to merge the changes from `add_scanner` into `main`."

After review and approval, you can merge it.

Then:

```text
main
 │
 A──B──C──D──E
             ↑
            main
```

---

# CLI alternative

Since you're comfortable with the terminal, you can also create the PR using GitHub CLI (`gh`).

After pushing:

```bash
gh pr create
```

It will ask you for the base branch, title, and description.

Or directly:

```bash
gh pr create --base main --head add_scanner --title "Add scanner functionality"
```

Then check it with:

```bash
gh pr view
```

---

## One important thing

A **Pull Request is not a Git command**.

Git handles:

```text
commit
branch
merge
rebase
push
pull
```

GitHub adds the collaboration layer:

```text
Git branch
    ↓
git push
    ↓
GitHub branch
    ↓
Pull Request
    ↓
review
    ↓
merge
```

So the essential workflow you'll use constantly is:

```bash
git switch -c add_scanner

# work...

git add .
git commit -m "Add scanner functionality"

git push -u origin add_scanner

gh pr create --base main --head add_scanner
```

Then the PR can be reviewed and merged into `main`.



[[Git & Github]]