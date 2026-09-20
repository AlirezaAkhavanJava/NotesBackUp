


## Basic Log Formatting Flags

### Short Format
```bash
# One line per commit (most commonly used)
git log --oneline

# Equivalent long form
git log --pretty=oneline

# Example output:
# a1b2c3d Add user authentication
# e4f5g6h Fix login bug
# i7j8k9l Initial commit
```

### Medium Format (Default)
```bash
# Default format - shows commit, author, date, message
git log

# Equivalent explicit command
git log --pretty=medium

# Example output:
# commit a1b2c3d...
# Author: John Doe <john@example.com>
# Date:   Mon Dec 11 10:30:00 2023 -0500
#
#     Add user authentication
```

### Full Format
```bash
# Shows complete commit information
git log --pretty=full

# Example output:
# commit a1b2c3d...
# Author: John Doe <john@example.com>
# Commit: John Doe <john@example.com>
# Date:   Mon Dec 11 10:30:00 2023 -0500
#
#     Add user authentication
```

### Custom Formats
```bash
# Custom format with hash and message only
git log --pretty=format:"%h - %s"

# Custom format with author and date
git log --pretty=format:"%h - %an, %ar : %s"

# Show as graph with custom format
git log --graph --pretty=format:"%C(yellow)%h%Creset - %s %Cgreen(%cr)%Creset %C(blue)<%an>%Creset"
```

---

## Output Control Flags

### Limiting Output
```bash
# Show last N commits
git log -5
git log -n 5
git log --max-count=5

# Show since specific date
git log --since="2023-12-01"
git log --since="2 weeks ago"
git log --since="yesterday"

# Show until specific date
git log --until="2023-12-10"
git log --until="1 week ago"

# Show commits by author
git log --author="John"
git log --author="john@example.com"

# Show commits containing specific text
git log --grep="bug"
git log --grep="fix" -i  # Case insensitive
```

### File-specific History
```bash
# Show history of specific file
git log -- README.md

# Show history of directory
git log -- src/

# Show what changed in specific file
git log -p -- README.md

# Show only commit stats for files
git log --stat -- README.md
```

---

## Decoration Flags

### `--decorate` - Show References
```bash
# Show branch and tag references
git log --decorate

# Short decorate format
git log --decorate=short

# Full decorate format (shows full ref names)
git log --decorate=full

# Auto decoration (Git 2.13+)
git log --decorate=auto

# Example output with --decorate:
# a1b2c3d (HEAD -> main, origin/main) Add feature
# e4f5g6h (tag: v1.0.0) Release v1.0.0
# i7j8k9l (feature/login) Initial commit
```

### `--all` - Show All Branches
```bash
# Show history from all branches
git log --all

# Show all branches with graph
git log --all --graph --oneline

# Show all branches with decorations
git log --all --decorate --oneline
```

### `--simplify-by-decoration`
```bash
# Show only commits that are referenced (branches/tags)
git log --simplify-by-decoration --decorate --oneline

# Useful for seeing your branch structure
git log --all --simplify-by-decoration --decorate --oneline
```

---

## Graph Visualization

### Basic Graph
```bash
# ASCII graph of commit history
git log --graph

# Graph with one-line format
git log --graph --oneline

# Graph with all branches
git log --graph --all --oneline
```

### Enhanced Graph Views
```bash
# Colorized graph
git log --graph --color=always

# Graph with simplified history
git log --graph --simplify-by-decoration

# Full branch visualization
git log --graph --all --decorate --oneline
```

### Popular Graph Aliases
```bash
# Add to your ~/.gitconfig
[alias]
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    lol = log --graph --decorate --pretty=oneline --abbrev-commit
    lola = log --graph --decorate --pretty=oneline --abbrev-commit --all
```

---

## Diff and Patch Information

### `-p` or `--patch` - Show Diffs
```bash
# Show patch (diff) for each commit
git log -p

# Show patch for last 3 commits
git log -p -3

# Show patch with word diff
git log -p --word-diff

# Show patch with specific file
git log -p -- README.md
```

### `--stat` - Show File Statistics
```bash
# Show file change statistics
git log --stat

# Example output:
# README.md  | 4 ++++
# src/main.js | 15 +++++++++++++++
# 2 files changed, 19 insertions(+)
```

### `--name-only` and `--name-status`
```bash
# Show only names of changed files
git log --name-only

# Show names with status (A=added, M=modified, D=deleted)
git log --name-status

# Example output:
# M       README.md
# A       src/main.js
```

---

## Advanced Filtering

### By File Content
```bash
# Show commits that added/removed specific string
git log -S "function_name"  # Pickaxe search

# Show commits that changed specific string (more precise)
git log -G "regex_pattern"

# Show commits that touched specific function
git log -L :function_name:file.py
```

### By Commit Range
```bash
# Show commits between two points
git log main..feature  # In feature but not in main
git log feature..main  # In main but not in feature

# Show commits since tag
git log v1.0.0..HEAD

# Show merge commits only
git log --merges

# Show non-merge commits only
git log --no-merges
```

### Combined Flags Examples
```bash
# Show recent activity across all branches
git log --all --oneline --decorate -10

# Show detailed history of current branch
git log --oneline --decorate --stat -15

# Find when a specific feature was added
git log --oneline -S "newFeature" --name-only

# See who changed a specific file recently
git log --pretty=format:"%h - %an, %ar : %s" -- README.md
```

---

## Practical Usage Examples

### Daily Development Workflow
```bash
# See recent commits on current branch
git log --oneline -10

# See what's changed since yesterday
git log --since="yesterday" --oneline

# Check what's ready to merge to main
git log --oneline main..HEAD

# See all branches and their latest commits
git log --all --oneline --decorate -15
```

### Code Archaeology
```bash
# Find when a bug was introduced
git log -p -S "buggy_function"

# See history of a specific file
git log --follow -- README.md

# Find commits by specific author
git log --author="alice" --oneline --since="1 month ago"
```

### Release Preparation
```bash
# See all changes since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Review merge commits for release
git log --merges --oneline --since="last month"

# Check what's in develop but not in main
git log --oneline main..develop
```

---

## Quick Reference Cheat Sheet

### Basic Viewing
```bash
git log                          # Default detailed view
git log --oneline               # Compact view
git log -5                      # Last 5 commits
git log --since="1 week ago"    # Recent commits
```

### Branch & Reference Views
```bash
git log --oneline --decorate           # Show branch/tag info
git log --all --oneline --decorate     # All branches
git log --graph --oneline --decorate   # Visual history
git log --all --graph --oneline        # Complete overview
```

### Filtering & Searching
```bash
git log --author="name"                # By author
git log --grep="text"                  # Search messages
git log -S "text"                      # Search content
git log -- README.md                   # File history
```

### Diff & Stats
```bash
git log -p                            # Show changes
git log --stat                        # File statistics
git log --name-status                 # File status
```

### Useful Aliases
```bash
# Add to ~/.gitconfig
[alias]
    hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
    tree = log --graph --oneline --decorate --all
    recent = log --oneline -10
    today = log --oneline --since=\"6am\"
```

These log flags give you powerful tools to explore, analyze, and understand your repository's history from every angle.

### Tags : [[0 - Git 🍋‍🟩]]