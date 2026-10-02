
In Unix/Linux, `curl` is a **command-line tool for transferring data to or from a server** using various protocols, most commonly **HTTP, HTTPS, FTP, and others**.

---

### **1. Basic Usage**

```bash
curl https://example.com
```

- Downloads the content of the URL and prints it to the terminal.
    

---

### **2. Common Options**

- `-O` → save the file with its original name
    

```bash
curl -O https://example.com/file.txt
```

- `-o` → save the file with a custom name
    

```bash
curl -o myfile.txt https://example.com/file.txt
```

- `-I` → fetch only the HTTP headers
    

```bash
curl -I https://example.com
```

- `-d` → send POST data
    

```bash
curl -d "name=Ethan&age=25" https://example.com/form
```

- `-H` → add custom headers
    

```bash
curl -H "Authorization: Bearer TOKEN" https://example.com
```

---

### **3. Quick Analogy**

`curl` is like a **universal postal service for the internet**:

- You can **request data**,
    
- **send data**,
    
- or **check the envelope (headers) without opening it**.
    



##### Tags : [[2 - Tags/Linux|Linux]]