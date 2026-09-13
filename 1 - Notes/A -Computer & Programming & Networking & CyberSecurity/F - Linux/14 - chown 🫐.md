In Unix/Linux, `chown` stands for **“change owner”**. It’s a command used to **change the owner and/or group of a file or directory**.

---

### **1. Basic Usage**

```bash
chown newuser filename
```

- Changes the **owner** of `filename` to `newuser`.
    

Example:

```bash
chown ethan report.txt
```

- Now `ethan` owns `report.txt`.
    

---

### **2. Change Owner and Group**

```bash
chown newuser:newgroup filename
```

- `newuser` → new owner
    
- `newgroup` → new group  
    Example:
    

```bash
chown ethan:developers report.txt
```

---

### **3. Recursive Change**

- Use `-R` to change ownership for **all files and subdirectories** inside a directory:
    

```bash
chown -R ethan:developers /home/ethan/projects
```

---

### **4. Quick Analogy**

`chown` is like **giving someone else the keys to a room**:

- Owner → who controls the file
    
- Group → who shares access
    

---


##### Tags : [[2 - Core-concepts/Linux|Linux]]