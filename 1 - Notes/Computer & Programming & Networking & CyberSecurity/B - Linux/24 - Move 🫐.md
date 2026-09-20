

`mv` (move) is used to **move or rename** files and directories.

**Basic syntax:**

```bash
mv source destination
```

### 🧩 Examples

- **Move a file:**
    
    ```bash
    mv file.txt /home/ethan/Documents/
    ```
    
    → moves `file.txt` into the `Documents` directory.
    
- **Rename a file:**
    
    ```bash
    mv oldname.txt newname.txt
    ```
    
    → same directory, new name.
    
- **Move a directory:**
    
    ```bash
    mv project /home/ethan/Desktop/
    ```
    
    → moves the entire `project` folder.
    

### ⚙️ Options

- `-i` → asks before overwriting
    
- `-v` → shows what’s happening (verbose)
    

Example:

```bash
mv -iv old.txt new.txt
```



##### Tags : [[2 - Tags/Linux|Linux]]