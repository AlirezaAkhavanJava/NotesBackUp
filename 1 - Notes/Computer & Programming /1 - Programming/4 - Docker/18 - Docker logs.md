
`docker logs` shows the **output (stdout + stderr)** from a running or stopped container — basically what the app inside it printed.

---

### 🧠 Syntax:

```bash
docker logs <container-name or ID>
```

---

### 🔍 Examples:

```bash
docker logs mynginx
```

→ shows everything the Nginx container has logged so far.

```bash
docker logs -f myapp
```

→ **follows** the logs in real-time (like `tail -f`).

```bash
docker logs --tail 50 myapp
```

→ shows only the last 50 lines.

---

### ⚙️ Common options:

|Option|Meaning|
|---|---|
|`-f`|Follow logs live|
|`--tail n`|Show last _n_ lines|
|`--since 10m`|Show logs from last 10 minutes|
|`--timestamps`|Include timestamps|

---

 **Use it to:**  
Debug containers, check server output, or see error messages from apps running inside Docker.

---

docker logs` **only works for containers**, not images.

Here’s why:

- **Images** are just blueprints — they don’t “run,” so they produce no logs.
    
- **Containers** are the _running instances_ of images — they execute code and generate logs (stdout/stderr).
    

So:

```bash
docker logs mycontainer   # ✅ works
docker logs nginx         # ❌ fails — nginx is an image, not a running container
```

If you want to see what’s inside an image, you can **inspect** it instead:

```bash
docker inspect nginx
```

But only **containers** have logs.

##### Tags : [[1 - Docker 🧋]]