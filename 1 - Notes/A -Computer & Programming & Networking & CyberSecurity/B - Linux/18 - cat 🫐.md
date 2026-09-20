
In Unix/Linux, `cat` is a **command used to display, create, or combine files**. Its name comes from **“concatenate”**.

---

### **1. Basic Usage**

```bash
cat filename.txt
```

- Displays the content of `filename.txt` in the terminal.
    

---

### **2. Common Uses**

1. **View a file**
    

```bash
cat file.txt
```

- Prints the whole file to the terminal.
    

2. **Create a new file**
    

```bash
cat > newfile.txt
```

- Lets you type content into a new file.
    
- Press `Ctrl+D` to save and exit.
    

3. **Append one file to another**
    

```bash
cat file1.txt >> file2.txt
```

- Adds the content of `file1.txt` to the end of `file2.txt`.
    

4. **Combine multiple files**
    

```bash
cat file1.txt file2.txt > combined.txt
```

- Creates a new file `combined.txt` containing both files.
    

---

### **3. Quick Analogy**

`cat` is like a **document reader and copier**:

- You can **read a file**,
    
- **copy it into another**,
    
- or **merge multiple files into one**.
    

---

##### Tags : [[2 - Core-concepts/Linux|Linux]]