In the context of Unix/Linux, `echo` is a **command** used to **display text or variables** to the terminal.

---

### **1. Basic Usage**

```bash
echo "Hello, World!"
```

Output:

```
Hello, World!
```

---

### **2. Common Features**

1. **Display variables**
    

```bash
name="Ethan"
echo "My name is $name"
```

Output:

```
My name is Ethan
```

2. **Escape characters**
    

- `\n` → new line
    
- `\t` → tab
    

```bash
echo -e "Hello\nWorld"
```

Output:

```
Hello
World
```

(`-e` enables interpretation of escape sequences)

3. **Suppress newline**
    

```bash
echo -n "Hello "
echo "World"
```

Output:

```
Hello World
```

---

### **3. Quick Analogy**

`echo` is like **talking to the terminal**—you “say” something, and it repeats it back to you.

---


##### Tags : [[1 - SQL 🦬]]