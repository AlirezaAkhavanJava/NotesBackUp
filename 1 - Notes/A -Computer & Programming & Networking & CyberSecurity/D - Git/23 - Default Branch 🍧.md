




### What is a Default Branch?

The **default branch** is the primary branch in your Git repository that serves as:

- **The main development line** - where stable code resides
- **The automatic checkout target** - when cloning a repository
- **The default merge target** - for Pull Requests/Merge Requests
- **The "source of truth"** - represents the current production-ready state

### Common Default Branch Names

```bash
main        # Modern standard (most common today)
master      # Historical standard (older repositories)
develop     # Git Flow workflow
trunk       # Trunk-Based Development
production  # Deployment-focused workflows
```

### Identifying Your Default Branch

**On GitHub/GitLab:**
- Go to repository → Settings → Branches → "Default branch"

**Via Command Line:**
```bash
# See current branch (asterisk * indicates current)
git branch

# See all branches
git branch -a

# Check what remote considers default
git remote show origin

# Check the remote's HEAD (points to default branch)
git symbolic-ref refs/remotes/origin/HEAD
```

---

## How to Rename a Branch

### 1. Renaming a Local Branch

**When you're on the branch you want to rename:**
```bash
# Rename current branch
git branch -m new-branch-name
```

**When you're on a different branch:**
```bash
# Rename specific branch while on another branch
git branch -m old-branch-name new-branch-name
```

### 2. Renaming the Default Branch (Common Scenario)

**Situation**: You want to rename from `master` to `main` (or vice versa)

```bash
# Step 1: Switch to the branch you want to rename
git checkout master

# Step 2: Rename the local branch
git branch -m master main

# Step 3: Push the new branch to remote
git push -u origin main

# Step 4: Update the remote's HEAD reference
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
```

### 3. Updating the Remote Repository

After renaming locally, you need to update the remote:

```bash
# Push the newly named branch and set upstream
git push -u origin new-branch-name

# Delete the old branch from remote
git push origin --delete old-branch-name
```

### 4. Complete Rename Workflow Example

**Renaming `feature-login` to `auth-system`:**

```bash
# Start from any branch except the one you're renaming
git checkout main

# Rename the branch locally
git branch -m feature-login auth-system

# Push the new branch and set upstream
git push -u origin auth-system

# Delete the old branch from remote
git push origin --delete feature-login

# Update your local tracking reference
git branch --unset-upstream
git push -u origin auth-system
```

---

## Renaming the DEFAULT Branch on GitHub/GitLab

### On GitHub:

1. **Go to your repository** on GitHub
2. **Click Settings** tab
3. **Scroll to "Branches"** section
4. **Click "✏️" (edit) icon** next to default branch
5. **Select new default branch** from dropdown
6. **Confirm** the change

### On GitLab:

1. **Go to your project** on GitLab
2. **Navigate to Settings → Repository**
3. **Expand "Default branch"** section
4. **Select new default branch**
5. **Save changes**

### Important Notes for Default Branch Rename:

```bash
# After changing default branch on remote platform:

# Step 1: Fetch the changes from remote
git fetch origin

# Step 2: Update your local clone's tracking
git branch --unset-upstream
git branch -u origin/main   # Replace 'main' with your new default

# Step 3: If you have the old default branch locally, rename it too
git branch -m master main   # If renaming master to main
```

---

## Team Collaboration Considerations

### When Renaming Shared Branches

**⚠️ Important**: Never rename branches that others are actively using without coordination!

**Safe renaming workflow for teams:**
```bash
# 1. Communicate with your team about the rename
# 2. Make sure no one has unmerged work on the branch
# 3. Rename the branch
# 4. Notify team members to update their local repos

# Team members should run:
git fetch --prune
git branch -m old-name new-name
git push origin --delete old-name
```

### Fixing Local Repository After Remote Default Branch Change

If someone else changed the default branch:

```bash
# Get the latest changes from remote
git fetch origin

# See what branches exist now
git branch -a

# Create a local branch tracking the new default
git checkout -b main origin/main

# Delete your old local default branch (if desired)
git branch -d master
```

---

## Common Renaming Scenarios

### Scenario 1: Typo in Branch Name
```bash
# From: featrue-login
# To: feature-login
git branch -m featrue-login feature-login
git push -u origin feature-login
git push origin --delete featrue-login
```

### Scenario 2: Changing Branch Convention
```bash
# From: login-feature
# To: feature/login
git branch -m login-feature feature/login
git push -u origin feature/login
git push origin --delete login-feature
```

### Scenario 3: Repository Transfer (Different Default)
```bash
# When moving from a repo using 'master' to one using 'main'
git branch -m master main
git push -u origin main
```

---

## Troubleshooting

### "Error: Cannot delete branch 'X' checked out"
**Solution**: Checkout a different branch first
```bash
git checkout main
git branch -d old-branch-name
```

### "Error: Failed to push some refs"
**Solution**: The remote branch might have diverged
```bash
# Force push (use with caution!)
git push -f origin new-branch-name

# Or better: pull and merge first
git pull origin new-branch-name
```

### "Error: Remote branch already exists"
**Solution**: Delete the remote branch first or use different name
```bash
git push origin --delete conflicting-name
git push -u origin new-branch-name
```

---

## Best Practices

1. **Coordinate with team** before renaming shared branches
2. **Update CI/CD pipelines** that reference branch names
3. **Use descriptive, consistent naming** conventions
4. **Test the rename** in a personal repository first
5. **Keep a changelog** of significant branch structure changes

## Quick Reference Commands

```bash
# Rename current branch
git branch -m new-name

# Rename specific branch
git branch -m old-name new-name

# Push renamed branch to remote
git push -u origin new-name

# Delete old remote branch
git push origin --delete old-name

# Update local tracking after remote rename
git fetch --prune
```

### Tags : [[0 - Git 🍋‍🟩]]