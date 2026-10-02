
The `rm` command (**remove**) deletes files or directories. ⚠️ It’s permanent — no recycle bin.

### 🔹 Basic usage

```bash
rm file.txt
```

→ deletes `file.txt`.

### 🔹 Remove multiple files

```bash
rm file1.txt file2.txt file3.txt
```

### 🔹 Remove a directory

You can’t remove directories with plain `rm` — use flags:

```bash
rm -r folder_name
```

→ removes folder **and everything inside**.

### 🔹 Common options

- `-r` → recursive (for directories)
    
- `-f` → force (no confirmation, even if file is write-protected)
    
- `-v` → verbose (shows what’s deleted)
    

Example:

```bash
rm -rf /home/ethan/test
```

⚠️ **Be very careful** with `rm -rf` — it can wipe your system if used wrongly (e.g., `rm -rf /`).

---

Here’s the **safe rule set** for using `rm`:

1. 🧠 **Always double-check the path** before pressing Enter.
    
    ```bash
    echo /path/to/delete
    ```
    
    → use this to print it first.
    
2. 🧱 **Use `ls` before `rm`** to see what’s inside.
    
    ```bash
    ls folder_name
    ```
    
3. 🛑 **Never run `sudo rm -rf /` or `rm -rf *`** in important directories.  
    These commands can destroy your whole system.
    
4. 🧩 **Add `-i` for safety** (asks before deleting each file):
    
    ```bash
    rm -ri folder_name
    ```
    
5. 🧰 **Test with `echo` first**:
    
    ```bash
    echo rm -rf folder_name
    ```
    
    → confirms what would run, without actually deleting.
    



##### Tags : [[2 - Tags/Linux|Linux]]