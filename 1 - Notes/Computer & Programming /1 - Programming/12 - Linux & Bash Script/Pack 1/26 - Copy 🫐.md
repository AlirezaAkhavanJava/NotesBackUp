
In Linux, the **`cp`** command is used to copy files or directories.

### 📘 Basic syntax:

```bash
cp [options] source destination
```

### 🧩 Examples:

- Copy a file:
    
    ```bash
    cp file.txt /home/ethan/Documents/
    ```
    
- Copy and rename:
    
    ```bash
    cp file.txt newfile.txt
    ```
    
- Copy a directory (recursively):
    
    ```bash
    cp -r myfolder /home/ethan/Backup/
    ```
    
- Copy with confirmation before overwrite:
    
    ```bash
    cp -i file.txt /home/ethan/
    ```
    

---
Here’s how to copy **multiple files at once** with `cp`:

### 🧩 Examples:

- Copy several files to a folder:
    
    ```bash
    cp file1.txt file2.txt file3.txt /home/ethan/Documents/
    ```
    
- Copy all files with a certain extension:
    
    ```bash
    cp *.txt /home/ethan/Documents/
    ```
    
- Copy everything in a folder (not hidden files):
    
    ```bash
    cp * /home/ethan/Backup/
    ```
    
- Copy **everything including hidden files**:
    
    ```bash
    cp -r .* * /home/ethan/Backup/
    ```
    




##### Tags : [[2 - Tags/Linux|Linux]]