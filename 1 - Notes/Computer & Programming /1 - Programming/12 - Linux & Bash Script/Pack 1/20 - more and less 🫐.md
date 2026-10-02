
In Unix/Linux, `more` and `less` are **commands used to view long text files one screen at a time**, so you don’t have to scroll endlessly.

---

### **1. `more`**

- **Displays text page by page**, moving forward only.
    
- Basic usage:
    

```bash
more file.txt
```

- Navigation:
    
    - `Space` → next page
        
    - `Enter` → next line
        
    - `q` → quit
        

**Limitation:** You can mostly **move forward**, not backward.

---

### **2. `less`**

- More advanced than `more`.
    
- Allows **both forward and backward navigation**.
    

```bash
less file.txt
```

- Navigation:
    
    - `Space` → next page
        
    - `b` → previous page
        
    - `/search_term` → search for a term
        
    - `q` → quit
        

**Tip:** `less` is often preferred for large files because it’s faster and more flexible.

```bash 
less -N 2023.csv  #Shows the number of 2023.csv file lines
```

---

### **3. Quick Analogy**

- `more` → reading a book **page by page, can’t flip back easily**
    
- `less` → reading a book **with a bookmark and ability to flip pages back and forth**
    




##### Tags : [[2 - Tags/Linux|Linux]]