
The `touch` command in Linux is used to **create new empty files** or **update the access and modification timestamps** of existing files.

> Mostly use it for creating new file .

### Basic Syntax
```bash
touch [options] file...
```

---

### Common Use Cases

#### 1. **Create a new empty file**
```bash
touch newfile.txt
```
- If `newfile.txt` doesn't exist, it creates an empty file.
- If it exists, it updates the file's timestamps.

#### 2. **Create multiple files at once**
```bash
touch file1.txt file2.log report.md
```

#### 3. **Update timestamp without changing content**
```bash
touch existing_file.txt
```
- Changes **access time** and **modification time** to current time.

---

### Important Options

| Option | Description | Example |
|--------|-------------|---------|
| `-a` | Change only the **access time** | `touch -a file.txt` |
| `-m` | Change only the **modification time** | `touch -m file.txt` |
| `-c` | Do **not** create file if it doesn't exist | `touch -c nonexistent.txt` |
| `-d` | Set timestamp to a specific date/time | `touch -d "2025-01-01 10:30" file.txt` |
| `-t` | Set timestamp using `[[CC]YY]MMDDhhmm[.ss]` format | `touch -t 202501011030 file.txt` |
| `-r` | Use another file's timestamp | `touch -r reference.txt target.txt` |

---

### Practical Examples

```bash
# Create 3 empty files
touch alpha.txt beta.txt gamma.log

# Update only modification time
touch -m script.sh

# Set file date to yesterday
touch -d "yesterday" report.txt

# Copy timestamp from one file to another
touch -r source.txt destination.txt

# Avoid creating file if it doesn't exist
touch -c /tmp/missing_file
```

---

### Check Timestamps
Use `stat` to verify changes:
```bash
stat filename.txt
```
Output includes:
- **Access time** (`Atime`)
- **Modify time** (`Mtime`)
- **Change time** (`Ctime`) — updated when metadata changes

---

### Pro Tip
Use `touch` in scripts to create placeholder files or trigger file watchers:
```bash
touch /tmp/trigger_file
```

---

**Summary**:  
`touch` = **create** or **refresh timestamp**.  
No content is written unless you redirect input:
```bash
echo "Hello" > newfile.txt   # creates with content
touch newfile.txt            # creates empty
```




##### Tags : [[2 - Tags/Linux|Linux]]