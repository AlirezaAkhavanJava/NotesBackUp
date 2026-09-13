
A **directory** is just a folder in a file system — it stores files and other directories (called _subdirectories_).

In Unix/Linux:

- `/` is the **root directory** (top-level).
    
- `/home/ethan/Downloads` means:
    
    - `home` → inside root
        
    - `ethan` → inside `home`
        
    - `Downloads` → inside `ethan`
        

You can think of it like a tree:

```
/
├── home
│   └── ethan
│       └── Downloads
```

Commands:

- `ls` → list contents of a directory
    
- `pwd` → show current directory path
    
- `cd directory_name` → move into a directory
    
---

`mkdir` means **make directory** — it creates a new folder.

**Examples:**

```bash
mkdir test
```

→ creates a folder named `test` in your current directory.

```bash
mkdir /home/ethan/projects
```

→ creates the folder at that _absolute path_.

**Options:**

- `mkdir -p path/to/folder` → creates _parent directories_ too (no error if they already exist).  
    Example:
    
    ```bash
    mkdir -p /home/ethan/work/java/spring
    ```
    




##### Tags : [[2 - Core-concepts/Linux|Linux]]