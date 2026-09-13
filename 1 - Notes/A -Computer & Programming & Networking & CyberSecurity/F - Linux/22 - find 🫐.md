
The `find` command in Linux is a powerful tool to **search for files and directories** in a directory hierarchy based on various criteria (name, size, type, time, permissions, etc.) and optionally **execute actions** on the matched files.

---

### Basic Syntax
```bash
find [path...] [expression]
```

- `path`: Starting directory (default: current directory `.`)
- `expression`: Conditions and actions

---

## Common Use Cases & Examples

### 1. **Find by Name**
```bash
# Case-sensitive
find . -name "readme.txt"

# Case-insensitive
find . -iname "readme.txt"

# Using wildcards
find /home -name "*.log"
find . -name "config.*"
```

---

### 2. **Find by Type**
| Option | Type |
|--------|------|
| `-type f` | Regular file |
| `-type d` | Directory |
| `-type l` | Symbolic link |

```bash
find . -type f -name "*.sh"      # All shell scripts
find /etc -type d                # All directories in /etc
find ~ -type l                   # All symlinks in home
```

---

### 3. **Find by Size**
| Unit | Meaning |
|------|---------|
| `c` | bytes |
| `k` | kilobytes |
| `M` | megabytes |
| `G` | gigabytes |

```bash
find . -size +100M               # Files > 100 MB
find /var/log -size +10M -size -50M  # Between 10–50 MB
find ~ -size 0                   # Empty files
```

---

### 4. **Find by Time**
| Option | Meaning |
|--------|---------|
| `-mtime n` | Modified n*24 hours ago |
| `-atime n` | Accessed n*24 hours ago |
| `-ctime n` | Status changed n*24 hours ago |
| Use `+n` = older than, `-n` = less than |

```bash
find . -mtime -7                 # Modified in last 7 days
find . -mtime +30                # Older than 30 days
find /tmp -atime +1              # Not accessed in over 1 day
find . -newer reference.txt      # Newer than reference.txt
```

---

### 5. **Find by Permissions**
```bash
find . -perm 644                 # Exact permissions
find . -perm -644                # At least these permissions
find . -perm /u=x                # Files executable by user
find . -perm /a=w                # Writable by anyone (security risk)
```

---

### 6. **Execute Commands on Results (`-exec`)**
```bash
# Delete all .tmp files
find . -name "*.tmp" -exec rm {} \;

# Safer: prompt before delete
find . -name "*.tmp" -exec rm -i {} \;

# Use + to batch commands (faster)
find . -name "*.log" -exec cat {} + > all_logs.txt

# Change permissions
find . -type f -name "*.sh" -exec chmod 755 {} \;
```

> **Note**:  
> - `{} ` = placeholder for each found file  
> - `\;` = terminates `-exec` (required when using `\;`)  
> - `+` = passes multiple files at once (like `xargs`)

---

### 7. **Combine with `touch` (Your Previous Question!)**

#### Example: **Create a file if it doesn't exist, or update timestamp**
```bash
find . -name "daily.log" -exec touch {} \;
```

#### Example: **Touch all `.txt` files not modified in 7 days**
```bash
find . -name "*.txt" -mtime +7 -exec touch {} \;
```

#### Example: **Create missing log files from a list**
```bash
# If you have a list of expected log files
cat <<EOF > expected_logs.txt
app1.log
app2.log
backup.log
EOF

# Create any missing ones
xargs -I {} touch {} < expected_logs.txt
```

---

### 8. **Limit Search Depth**
```bash
find . -maxdepth 1 -name "*.conf"   # Only current directory
find . -mindepth 2 -maxdepth 3      # Depth 2 to 3
```

---

### 9. **Exclude Directories**
```bash
find . -name "*.py" -not -path "./venv/*" -not -path "./__pycache__/*"
# Or shorter:
find . -name "*.py" -path "./venv" -prune -o -print
```

---

### 10. **Find + Delete (Be Careful!)**
```bash
# Dry-run first
find . -name "*.bak" -ls

# Then delete
find . -name "*.bak" -delete
# or
find . -name "*.bak" -exec rm {} +
```

---

## Pro Tips

| Tip | Command |
|-----|---------|
| **Preview results** | `find . -name "*.log" -ls` |
| **Count matches** | `find . -name "*.jpg" | wc -l` |
| **Find empty directories** | `find . -type d -empty` |
| **Find largest files** | `find . -type f -exec du -h {} + | sort -hr | head -10` |

---

## Summary Cheat Sheet

```bash
find /path -name "pattern"          # Basic search
find . -type f -name "*.conf"       # Config files
find . -size +1G -delete            # Delete >1GB files
find . -mtime +30 -exec rm {} +     # Delete old files
find . -iname "*.JPG" -exec mv {} {}.jpeg \;  # Rename
```

---

**`find` + `touch` = Powerful combo for file management!**



##### Tags : [[2 - Core-concepts/Linux|Linux]]