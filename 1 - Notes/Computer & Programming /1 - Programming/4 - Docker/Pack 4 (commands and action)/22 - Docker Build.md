
> docker build` is the command that creates a Docker image from your Dockerfile .



---

## 🧠 **What It Does**

`docker build` reads your **Dockerfile**, executes each instruction line by line (`FROM`, `COPY`, `RUN`, etc.), and produces an **image** — a portable, ready-to-run package of your app.

---

## ⚙️ **Basic Syntax**

```bash
docker build [OPTIONS] PATH
```

**Example:**

```bash
docker build -t my-spring-app .
```

- `-t my-spring-app` → gives your image a name (“tag”).
    
- `.` → means the **current directory** (where the Dockerfile is).
    

---

## 🔹 Common Options

|Option|Meaning|
|---|---|
|`-t name:tag`|Name + optional tag (e.g. `myapp:1.0`)|
|`-f path/to/Dockerfile`|Use a Dockerfile not named `Dockerfile`|
|`--no-cache`|Force rebuild from scratch (ignore cache)|
|`--build-arg KEY=VALUE`|Pass a build-time variable (`ARG`)|
|`-q`|Quiet mode (only shows final image ID)|

---

## 🧩 Example Scenarios

### 1️⃣ Basic build:

```bash
docker build -t myapp .
```

### 2️⃣ Build from a custom Dockerfile:

```bash
docker build -f Dockerfile.prod -t myapp:prod .
```

### 3️⃣ Pass a build argument:

```bash
docker build --build-arg JAR_FILE=target/app.jar -t myapp .
```

### 4️⃣ Disable cache (fresh rebuild):

```bash
docker build --no-cache -t myapp .
```

---

## 🧱 After Building

Run:

```bash
docker images
```

You’ll see something like:

```
REPOSITORY       TAG       IMAGE ID       CREATED         SIZE
my-spring-app    latest    a4b5c3d2e1f0   5 seconds ago   315MB
```

That’s your new **image**, ready to be run with:

```bash
docker run -p 8080:8080 my-spring-app
```

---




##### Tags : [[1 - Docker 🧋]]