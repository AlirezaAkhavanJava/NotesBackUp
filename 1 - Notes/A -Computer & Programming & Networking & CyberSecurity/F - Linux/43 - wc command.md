
The `wc` command in Linux/Unix stands for **word count**. It **counts lines, words, and characters** in a file or input.

---

### 🧩 Basic Usage

```bash
wc filename
```

Output looks like:

```
  10  50 300 filename
```

- `10` → number of lines
    
- `50` → number of words
    
- `300` → number of bytes/characters
    

---

### ⚙️ Common Flags

- `-l` → lines only
    

```bash
wc -l file.txt
```

- `-w` → words only
    

```bash
wc -w file.txt
```

- `-c` → bytes (characters) only
    

```bash
wc -c file.txt
```

- `-m` → characters (handles multibyte characters better than `-c`)
    
- `-L` → length of the **longest line**
    

---

### 🧠 Example

```bash
echo "Hello world" | wc
```

Output:

```
1 2 12
```

- 1 line
    
- 2 words
    
- 12 characters (including space and newline)
    

---

Basically, `wc` is your **quick stats tool for files or streams**.



##### Tags : [[2 - Core-concepts/Linux|Linux]]