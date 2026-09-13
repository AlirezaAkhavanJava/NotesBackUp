In Unix/Linux, `chmod` stands for **“change mode”**. It’s a command used to **change the permissions of a file or directory**.

---
### 🔹 Basic `chmod` usage

```bash
chmod [WHO][+ or - or =][PERMISSIONS] [FILE or FOLDER]
```

### 🔹 WHO

- `u` → user (owner)
    
- `g` → group
    
- `o` → others
    
- `a` → all (u+g+o)
    

### 🔹 OPERATORS

- `+` → add permission
    
- `-` → remove permission
    
- `=` → set exactly these permissions
    

### 🔹 PERMISSIONS

- `r` → read
    
- `w` → write
    
- `x` → execute (or enter a folder)
    

---

### 🔹 Examples

|Command|Meaning|
|---|---|
|`chmod u+x file.sh`|give execute permission to the owner|
|`chmod g-w file.txt`|remove write from group|
|`chmod o=`|remove all permissions from others|
|`chmod 755 script.sh`|set full for user, read+execute for others|
|`chmod -R 700 myfolder`|recursive — only owner can read/write/execute|

### **1. Permissions Basics**

Every file/directory has **three types of permissions** for **three categories of users**:

|User|Permission|Description|
|---|---|---|
|**Owner (u)**|r, w, x|Read, Write, Execute|
|**Group (g)**|r, w, x|Permissions for users in the file’s group|
|**Others (o)**|r, w, x|Permissions for everyone else|

- **r = read** → can view the file
    
- **w = write** → can modify the file
    
- **x = execute** → can run the file (if it’s a program/script)
    

---

### **2. Syntax**

```bash
chmod [options] mode filename
```

#### **A. Symbolic Mode**

```bash
chmod u+x script.sh
```

- `u+x` → add execute permission for the owner
    

```bash
chmod g-w file.txt
```

- `g-w` → remove write permission for the group
    

```bash
chmod o=r file.txt
```

- `o=r` → give read-only permission to others
    

#### **B. Numeric (Octal) Mode**

- Permissions can be represented as numbers:
    
    - `r = 4`
        
    - `w = 2`
        
    - `x = 1`
        

Add them up per category:

```bash
chmod 755 script.sh
```

- 7 → owner: r(4)+w(2)+x(1) = 7
    
- 5 → group: r(4)+x(1) = 5
    
- 5 → others: r(4)+x(1) = 5
    

---

### **3. Recursive Change**

```bash
chmod -R 644 /home/ethan/docs
```

- Changes permissions of all files and subdirectories inside `/home/ethan/docs`.
    

---

### **4. Quick Analogy**

- **chmod** = “lock or unlock doors” of a file:
    
    - Owner decides permissions for themselves, their group, and everyone else.
        

---

In the context of Unix/Linux commands like `chmod`, **“mod”** is short for **“mode”**, which refers to the **permissions of a file or directory**.

---

### **1. Meaning**

- **Mode** = combination of **read (r), write (w), and execute (x) permissions** for the **owner, group, and others**.
    
- When you use `chmod`, you’re **changing the mode** of a file.
    

---

### **2. Examples**

- Symbolic mode:
    

```bash
chmod u+x file.txt
```

- Here, you’re **modifying the mode** to add execute permission for the owner.
    
- Numeric (octal) mode:
    

```bash
chmod 755 script.sh
```

- `755` represents the **mode** in numbers (rwx for owner, r-x for group, r-x for others).
    

---

### **3. Quick Analogy**

Think of the **mode** as the **lock settings of a file**: it determines who can **read, write, or execute** it.

---


##### Tags : [[2 - Core-concepts/Linux|Linux]]