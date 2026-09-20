
A **Docker image** is a **blueprint** for creating containers.

Think of it like this:  
🧱 **Image = Recipe**  
🍱 **Container = Meal made from that recipe**

It contains:

- The **operating system layer** (like Ubuntu or Alpine)
    
- Your **application code**
    
- All **dependencies**, libraries, and environment settings
    

When you run:

```bash
docker run nginx
```

Docker uses the **nginx image** to create a running **container** (an isolated instance).

✅ **Key facts:**

- Images are **read-only** templates.
    
- Containers are **writable** copies of images.
    
- You can see your images with `docker images`.
    
- You can build your own using a `Dockerfile`.
---


### 🧱 `docker images`

Shows **all top-level images** on your system — the ones you can run directly.

**Example:**

```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
nginx        latest    6b914bbcb89e   2 weeks ago    187MB
python       3.12      1f2e1c8c2bcd   3 weeks ago    980MB
```

These are the main images you’ve pulled or built.

---

### 🔍 `docker images -a` _(same as `docker images --all`)_

Shows **all images**, **including intermediate layers** created during `docker build`.

Those “intermediate” images are hidden by default but can take up space.

**Example:**

```
<none>       <none>    8b7eac5b03d9   3 weeks ago   400MB
```

These `<none>` entries are **dangling images** — leftover build layers not currently used by any container.

You can safely clean them up with:

```bash
docker image prune
```

---

### 🧠 In short:

|Command|Shows|Typical Use|
|---|---|---|
|`docker images`|Only main images|See what you can run|
|`docker images -a`|All (main + hidden layers)|Debugging / cleanup|
##### [[1 - Docker 🧋]]