
In Unix/Linux, a **file path** is the **location of a file or directory** in the filesystem. It tells the system **how to find it**.

---

### **1. Types of File Paths**

#### **A. Absolute Path**

- Starts from the **root directory `/`**.
    
- Always points to the same location, no matter where you are.
    
- Example:
    

```bash
/home/ethan/Documents/report.txt
```

- `/` → root
    
- `home` → directory inside root
    
- `ethan` → subdirectory
    
- `report.txt` → file
    

#### **B. Relative Path**

- Starts from your **current working directory**.
    
- Example: If you are in `/home/ethan`:
    

```bash
Documents/report.txt
```

- Same file as the absolute path above, but shorter because it’s relative to current location.
    

---

### **2. Special Symbols**

- `.` → current directory
    
- `..` → parent directory
    
- `~` → home directory of the current user
    

```bash
cd ~        # go to home
cd ..       # go up one directory
cd ./Documents  # go to Documents from current directory
```

---

### **3. Quick Analogy**

- **Absolute path:** Full street address: “123 Main St, City, Country”
    
- **Relative path:** Directions from where you are standing: “Go two blocks north, then turn left.”
    

---




##### Tags : [[2 - Tags/Linux|Linux]]