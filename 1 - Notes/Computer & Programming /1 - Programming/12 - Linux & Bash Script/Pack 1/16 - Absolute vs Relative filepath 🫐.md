
In Unix/Linux, **file paths** tell the system **where a file or directory is located**. They come in **two types: absolute and relative**.

---

### **1. Absolute File Path**

- Starts from the **root directory `/`**.
    
- Always points to the **same location**, no matter where you are.
    
- **Syntax:** `/directory/subdirectory/file`
    

**Example:**

```bash
/home/ethan/Documents/report.txt
```

- `/` → root
    
- `home` → folder inside root
    
- `ethan` → subfolder
    
- `report.txt` → file
    

---

### **2. Relative File Path**

- Starts from your **current working directory**.
    
- Depends on **where you are currently located** in the filesystem.
    
- **Syntax:** `subdirectory/file` or `../file`
    

**Example:** If your current directory is `/home/ethan`:

```bash
Documents/report.txt
```

- Refers to the same file as the absolute path above.
    

**Special symbols:**

- `.` → current directory
    
- `..` → parent directory
    
- `~` → home directory of the current user
    

```bash
cd ../Downloads   # go up one directory, then into Downloads
cd ~/Documents    # go to home/Documents
```

---

### **3. Quick Analogy**

- **Absolute path:** Full street address: “123 Main St, City, Country”
    
- **Relative path:** Directions from where you are: “Go two blocks north, then turn left.”
    



##### Tags : [[2 - Tags/Linux|Linux]]