

In Unix/Linux, `head` and `tail` are commands used to **view parts of a file** rather than the whole thing.

---

### **1. `head`**

- Shows the **first lines of a file**.
    
- **Default:** 10 lines.
    

**Example:**

```bash
head file.txt
```

- Shows the first 10 lines of `file.txt`.
    

**Change number of lines:**

```bash
head -n 5 file.txt
```

- Shows the first 5 lines.
    

---

### **2. `tail`**

- Shows the **last lines of a file**.
    
- **Default:** 10 lines.
    

**Example:**

```bash
tail file.txt
```

- Shows the last 10 lines of `file.txt`.
    

**Change number of lines:**

```bash
tail -n 5 file.txt
```

- Shows the last 5 lines.
    

**Monitor a file in real-time:**

```bash
tail -f logfile.log
```

- Continuously displays new lines as they are added (useful for logs).
    

---

### **3. Quick Analogy**

- `head` → **peek at the beginning of a book**
    
- `tail` → **peek at the last pages**
    

---


##### Tags : [[2 - Core-concepts/Linux|Linux]]