
`docker inspect` shows **detailed technical info** (in JSON format) about Docker **containers**, **images**, **volumes**, or **networks**.

---

### 🧠 Syntax:

```bash
docker inspect <name or ID>
```

---

### 🔍 Examples:

**Inspect a container:**

```bash
docker inspect mynginx
```

Shows details like:

- Container ID
    
- Image used
    
- IP address
    
- Mounted volumes
    
- Environment variables
    
- Network settings
    

**Inspect an image:**

```bash
docker inspect nginx
```

Gives info like:

- Layers
    
- Created date
    
- Architecture
    
- Entrypoint / CMD
    

---

### 🧩 Common usage:

You can extract specific values using `--format`:

```bash
docker inspect --format='{{.NetworkSettings.IPAddress}}' mynginx
```

👉 Prints just the container’s internal IP address.

---

**In short:**  
🧱 `docker inspect` = “show me everything about this Docker thing — all its hidden details.”

##### Tags : [[1 - Docker 🧋]]