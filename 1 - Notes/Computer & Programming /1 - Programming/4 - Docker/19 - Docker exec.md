
`docker exec` lets you **run a command inside a running container** — like opening a terminal inside it.

---

### 🧠 Syntax:

```bash
docker exec [options] <container> <command>
```

---

### 🔍 Examples:

**1. Open an interactive shell:**

```bash
docker exec -it mynginx bash
```

→ Opens a Bash shell **inside** the `mynginx` container.

If the image doesn’t have `bash`, use `sh`:

```bash
docker exec -it mynginx sh
```

**2. Run a one-time command:**

```bash
docker exec mynginx ls /usr/share/nginx/html
docker exec mydb psql -U postgres -c "\l"
```

---

### ⚙️ Common options:

|Option|Description|
|---|---|
|`-i`|Interactive (keeps STDIN open)|
|`-t`|Allocates a terminal (TTY)|
|`-d`|Run command in background|

---

✅ **In short:**  
`docker exec` = “run a command _inside_ a container that’s already running.”  
It’s perfect for debugging, inspecting files, or managing services inside containers.

##### Tags : [[1 - Docker 🧋]]