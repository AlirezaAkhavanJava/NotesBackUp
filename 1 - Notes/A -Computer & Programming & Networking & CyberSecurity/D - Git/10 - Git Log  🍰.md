Date : 2025-08-29

## Introduction

Git log is a powerful command that displays the commit history of a repository. It helps you track changes, understand project evolution, and debug issues by examining past commits.

## Basic Git Log Commands

### 1. Basic Log
```bash
git log
```
Shows the commit history in reverse chronological order (newest first).

### 2. Limited Output
```bash
git log -n 5
```
Shows only the last 5 commits.

### 3. One-line Format
```bash
git log --oneline
```
Shows each commit on a single line with abbreviated hash and commit message.

```bash
git log --oneline -5
```
Combines one-line format with limit.

### 4. Show Changes
```bash
git log -p
```
Shows the patch (diff) for each commit.

```bash
git log --stat
```
Shows statistics about changed files (number of insertions/deletions).


---

## Formatting Output

### 1. Custom Format
```bash
git log --pretty=format:"%h - %an, %ar : %s"
```
- `%h`: abbreviated commit hash
- `%an`: author name
- `%ar`: author relative date
- `%s`: subject (commit message)

### 2. Common Format Options
```bash
git log --pretty=format:"%C(yellow)%h %C(red)%d %C(reset)%s %C(green)%an, %ar"
```
Adds colors to the output for better readability.

### 3. Available Format Placeholders:
- `%H`: full commit hash
- `%h`: abbreviated commit hash
- `%an`: author name
- `%ae`: author email
- `%ad`: author date
- `%ar`: author relative date
- `%cn`: committer name
- `%s`: commit subject
- `%d`: ref names
- `%Cred`: switch to red color
- `%Cgreen`: switch to green color
- `%Creset`: reset color

## Filtering and Searching

### 1. By Author
```bash
git log --author="John Doe"
git log --author="john@example.com"
```

### 2. By Date
```bash
git log --since="2023-01-01"
git log --until="2023-12-31"
git log --since="2 weeks ago"
```

### 3. By Message Content
```bash
git log --grep="bug fix"
git log --grep="feature" -i  # case-insensitive
```

### 4. By File
```bash
git log -- path/to/file.txt
git log -- *.js  # all JavaScript files
```

### 5. By Commit Range
```bash
git log HEAD~10..HEAD  # last 10 commits
git log v1.0..v2.0    # between tags
```

### 6. Combined Filters
```bash
git log --author="John" --since="1 month ago" --oneline
```

## Advanced Visualization

### 1. Graph View
```bash
git log --graph --oneline --decorate --all
```
Shows branch structure with ASCII art.

### 2. Custom Graph Format
```bash
git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
```

### 3. Follow File Renames
```bash
git log --follow -- path/to/file.txt
```

### 4. Show Merge Commits Only
```bash
git log --merges
```

### 5. Show Non-Merge Commits Only
```bash
git log --no-merges
```

## Custom Aliases

Add these to your `~/.gitconfig` file:

```ini
[alias]
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    lol = log --graph --decorate --pretty=oneline --abbrev-commit --all
    lola = log --graph --decorate --pretty=oneline --abbrev-commit --all --author-date-order
    hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
```



---

## Practical Examples

### 1. Find Recent Changes to Specific File
```bash
git log --oneline -10 -- path/to/file.js
```

### 2. See Who Changed What and When
```bash
git log --pretty=format:"%h - %an, %ad : %s" --date=short -- path/to/file.py
```

### 3. Track Bug Introductions
```bash
git log --grep="bug" --oneline -20
```

### 4. Review Branch History
```bash
git log --graph --oneline --decorate --all -20
```

### 5. Generate Change Report
```bash
git log --since="last month" --author="team@company.com" --stat
```

### 6. Find Commits by Content
```bash
git log -S "functionName"  # find commits that added/removed this string
```

### 7. Show File History with Diffs
```bash
git log -p --follow -- path/to/file.txt
```

### 8. Custom Output for Scripting
```bash
git log --pretty=format:"%H|%an|%ad|%s" --date=iso > commits.csv
```

## Tips and Best Practices

1. **Use aliases** for frequently used log commands
2. **Combine filters** to narrow down results
3. **Use `--since` and `--until`** for time-based filtering
4. **Leverage `--grep`** for searching commit messages
5. **Use `--graph`** to understand branch relationships
6. **Pipe to less** for long outputs: `git log --oneline | less`
7. **Export to file** for reporting: `git log --since="2023-01-01" > changes.txt`

Remember that Git log is extremely flexible - experiment with different combinations of options to find what works best for your workflow!



##### *Tags : [[0 - Git 🍋‍🟩]]