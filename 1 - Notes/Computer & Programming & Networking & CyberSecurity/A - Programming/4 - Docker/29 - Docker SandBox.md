
> A **Docker sandbox** is basically a _safe, isolated environment_ where you can run and test applications without affecting your real system.


### 🧱 What “sandbox” means

A sandbox is an **isolated space** — like a playground where your app can “play” freely without breaking your OS.

### 🐳 In Docker’s case

Docker creates **containers**, which are sandboxed environments. Each container has:

- Its own **filesystem** (based on an image)
    
- Its own **network stack**
    
- Its own **processes**
    
- But shares the same **kernel** with the host (it’s lightweight)
    

### 🧪 What you can do in a Docker sandbox

- Test new code safely
    
- Try new dependencies or configurations
    
- Run services (like a DB or API) temporarily
    
- Experiment without installing stuff on your machine
    

### ⚙️ Example

Run a sandbox container with Ubuntu:

```bash
docker run -it --rm ubuntu bash
```

This gives you a clean Ubuntu sandbox. When you exit, it’s gone (`--rm` removes it automatically).


---
## 🧱 1️⃣ When you run a container

When you type:

```bash
docker run -d -p 8080:8080 my-java-app
```

Docker does **not** just “install” the app — it actually **starts a running container**.

That container is:

- A **lightweight isolated environment** (like a tiny Linux computer)
    
- Running your app as its **main process**
    

So yes — it **runs like a normal app**, but **inside Docker’s sandbox**.

---

## ⚙️ 2️⃣ What happens behind the scenes

When Docker runs a container:

1. It creates a **filesystem** (based on the image you built).
    
2. It starts a **process** (like `java -jar myapp.jar`) inside that sandbox.
    
3. That process keeps running as long as the app is alive.
    
4. When the app stops → the container stops automatically.
    

So, the **container is basically your app’s runtime environment**.

---

## 🚀 3️⃣ It keeps running until you stop it

If you ran:

```bash
docker run -d -p 8080:8080 my-java-app
```

- `-d` = detached (runs in background)
    
- Docker keeps the container running as long as the app process (your Java JAR) is alive.
    

To stop it:

```bash
docker stop <container-name>
```

To remove it:

```bash
docker rm <container-name>
```

You can check it anytime:

```bash
docker ps
```

---

## 🧩 4️⃣ If the app inside crashes

The container automatically stops too.  
You can verify it with:

```bash
docker ps -a
```

That shows even stopped containers.

If your Java app exits (for example, throws an error),  
Docker marks the container as **exited**.

You can check logs:

```bash
docker logs my-java-app
```

---

## 🧠 5️⃣ So to answer simply:

|Question|Answer|
|---|---|
|Is Docker running the container or the app?|Both — Docker runs a container that runs your app inside it.|
|Does it stay running until I stop it?|✅ Yes, as long as your app process stays alive.|
|What happens when I stop it?|Docker terminates the process and shuts down the container.|
|Can I restart it later?|✅ Yes, with `docker start <name>`|

---



##### Tags : [[1 - Docker 🧋]]