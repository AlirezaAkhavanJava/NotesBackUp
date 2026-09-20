
A **container** is a **running instance** of a Docker **image** — like a lightweight, isolated mini-computer running your app.

Think of it like this:  
📦 **Image = Blueprint**  
🚀 **Container = The live, running thing built from that blueprint**

✅ **Key traits:**

- Runs isolated from your main system (like a sandbox).
    
- Has its own filesystem, processes, network ports, etc.
    
- Starts instantly (much faster than a virtual machine).
    
- You can start, stop, or delete it anytime.
    

**Example:**

```bash
docker run -d -p 8080:80 nginx
```

This starts an **nginx container** (running web server) from the **nginx image**, serving pages on `localhost:8080`.

You can view running ones with:

```bash
docker ps
```
##### [[1 - Docker 🧋]]