
### What is `find`?

The `find` command recursively searches directories for files and directories that match specified criteria. It can perform various actions on the matches, making it extremely versatile for file management tasks.

---

### Basic Syntax

```bash
find [PATH...] [EXPRESSION]
```

- **PATH**: Where to search (defaults to current directory `.` if omitted)
- **EXPRESSION**: Search criteria and actions

---

### 1. Common Tests (Search Criteria)

#### Search by Name
```bash
# Find files named exactly "file.txt" in current directory
find . -name "file.txt"

# Case-insensitive name search
find . -iname "file.txt"

# Use wildcards (find all .txt files)
find . -name "*.txt"

# Find directories named "documents"
find . -type d -name "documents"
```

#### Search by Type
```bash
# Find only regular files
find . -type f

# Find only directories
find . -type d

# Find symbolic links
find . -type l

# Find sockets
find . -type s
```

#### Search by Size
```bash
# Find files larger than 10MB
find . -type f -size +10M

# Find files smaller than 1KB
find . -type f -size -1k

# Find files exactly 50 bytes
find . -type f -size 50c

# Size units: c (bytes), k (KB), M (MB), G (GB)
```

#### Search by Time
```bash
# Find files modified in the last 7 days
find . -type f -mtime -7

# Find files modified more than 30 days ago
find . -type f -mtime +30

# Find files accessed in the last 2 days
find . -type f -atime -2

# Find files whose status changed in the last hour (in minutes)
find . -type f -cmin -60
```

#### Search by Permissions
```bash
# Find files with exact permission 644
find . -type f -perm 644

# Find executable files
find . -type f -perm /u=x

# Find world-writable files (security risk!)
find . -type f -perm /o=w
```

#### Search by Owner
```bash
# Find files owned by user "john"
find . -type f -user john

# Find files owned by group "developers"
find . -type f -group developers
```

---

### 2. Combining Tests (AND/OR/NOT)

#### Logical AND (default)
```bash
# Find .txt files modified in the last 2 days
find . -name "*.txt" -type f -mtime -2
```

#### Logical OR (`-o`)
```bash
# Find .jpg OR .png files
find . -name "*.jpg" -o -name "*.png"
```

#### Logical NOT (`-not` or `!`)
```bash
# Find all files NOT ending with .txt
find . -type f -not -name "*.txt"

# Using ! (remember to escape it or use quotes)
find . -type f \! -name "*.txt"
```

#### Grouping with Parentheses
```bash
# Find (.txt OR .md) files that are larger than 1MB
find . -type f \( -name "*.txt" -o -name "*.md" \) -size +1M
```

---

### 3. Actions (What to Do with Results)

#### Default Action: Print
```bash
# Simply print found files (default action)
find . -name "*.txt" -print
```

#### Delete Files (**Use with caution!**)
```bash
# Delete all .tmp files
find . -name "*.tmp" -delete

# Safer: preview first, then delete
find . -name "*.tmp" -print  # Preview what will be deleted
find . -name "*.tmp" -delete # Then actually delete
```

#### Execute Commands (`-exec`)
```bash
# Change permissions of found files
find . -name "*.sh" -type f -exec chmod +x {} \;

# Copy found files to a directory
find . -name "*.jpg" -type f -exec cp {} /backup/ \;

# Delete files with confirmation (interactive)
find . -name "*.log" -type f -exec rm -i {} \;
```

**Note about `-exec` syntax:**
- `{}` is replaced by the current file name
- `\;` marks the end of the command (must be escaped with backslash)

#### Modern `-exec` with `+` (more efficient)
```bash
# More efficient: passes multiple files to one command
find . -name "*.txt" -type f -exec chmod 644 {} +
```

#### Using `xargs` Alternative
```bash
# Using find with xargs (handles spaces in filenames safely)
find . -name "*.txt" -type f -print0 | xargs -0 ls -l
```

---

### 4. Practical Examples

#### Cleanup Operations
```bash
# Find and delete empty files
find . -type f -empty -delete

# Find and delete empty directories
find . -type d -empty -delete

# Clean up temporary files
find /tmp -type f -name "*.tmp" -mtime +7 -delete
```

#### Backup Operations
```bash
# Find all .conf files and create backups
find /etc -name "*.conf" -type f -exec cp {}{,.bak} \;

# Find large log files to archive
find /var/log -name "*.log" -type f -size +100M
```

#### Security and Maintenance
```bash
# Find files modified in the last 10 minutes (monitoring)
find . -type f -mmin -10

# Find large files taking up space
find /home -type f -size +500M

# Find files with SUID bit set (potential security review)
find / -type f -perm /4000 2>/dev/null
```

#### Development Workflows
```bash
# Find all Python files containing a specific function
find . -name "*.py" -type f -exec grep -l "def calculate_" {} \;

# Find and count all source code files
find src/ -name "*.java" -o -name "*.py" -o -name "*.js" | wc -l
```

---

### 5. Performance Tips

1. **Be specific with paths**: Search in `/home/user` instead of `/`
2. **Use `-maxdepth` to limit recursion**:
   ```bash
   # Search only in current directory (non-recursive)
   find . -maxdepth 1 -name "*.txt"
   
   # Search 2 levels deep
   find . -maxdepth 2 -name "*.txt"
   ```
3. **Combine tests efficiently**: Put selective tests first
4. **Redirect errors**: `find / -name "file" 2>/dev/null`

---

### 6. Common Pitfalls and Solutions

#### Handling Spaces in Filenames
```bash
# Safe way with -print0 and xargs -0
find . -name "*.txt" -print0 | xargs -0 rm

# Or use -exec with {} \;
find . -name "*.txt" -exec rm {} \;
```

#### Permission Denied Errors
```bash
# Redirect error messages
find / -name "myfile" 2>/dev/null

# Or filter specific errors
find / -name "myfile" 2>&1 | grep -v "Permission denied"
```

---

### Summary

The `find` command is incredibly powerful for:
- **Locating files** by name, type, size, time, permissions
- **Batch processing** with `-exec` or `xargs`
- **System maintenance** and cleanup operations
- **Security auditing** of file permissions and ownership

Start with simple searches and gradually incorporate more complex criteria and actions. The `-exec` option is particularly powerful for automating file management tasks. Always test with `-print` first before using destructive operations like `-delete`!

##### Tags : [[2 - Core-concepts/Linux|Linux]]