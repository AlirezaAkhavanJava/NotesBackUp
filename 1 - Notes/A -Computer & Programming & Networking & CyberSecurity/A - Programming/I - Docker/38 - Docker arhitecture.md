
![[Pasted image 20251206182626.png]]



# 🚢 Docker Architecture (Deep Breakdown)

Docker follows a **client–server architecture** with three main pieces:

## 1) **Docker Client (CLI)**

### What it is:

The tool you use when you type:

```bash
docker ps
docker run nginx
docker build .
```

### What it actually does:

- It **does not run containers**.
    
- It **talks to the Docker Daemon** via:
    
    - UNIX socket: `/var/run/docker.sock`
        
    - or TCP: `tcp://host:2375`
        

### Think of it as:

A remote controller. You press buttons; the daemon does the work.

---

## 2) **Docker Daemon (dockerd) — The Brain**

### What it does:

This is the **core engine**. It handles:

- Building images
    
- Running containers
    
- Creating volumes
    
- Managing networks
    
- Pulling/pushing to registries
    
- Enforcing resource limits
    

### Responsibilities:

- Talks to container runtime (containerd)
    
- Implements Docker’s REST API
    
- Manages metadata (images, layers, containers)
    

### Think of it as:

The brain and manager of everything.

---

## 3) **Container Runtime (containerd + runc)**

This is the **low-level engine** actually responsible for creating containers.

### Two key components:

### 3.1 **containerd**

- A daemon that manages container lifecycle:
    
    - create
        
    - start
        
    - stop
        
    - delete
        
- Handles pulling images
    
- Manages snapshots (filesystem layers)
    

### 3.2 **runc**

- The tool that **creates containers using Linux namespaces & cgroups**.
    
- containerd calls `runc` to spawn containers.
    

### Think of it as:

containerd = manager  
runc = worker who actually builds the container sandbox

---

## 4) **Docker Images**

Images are:

- Layered filesystem
    
- Built from a Dockerfile
    
- Stored locally (`/var/lib/docker`) or on registries.
    

Each layer is immutable.  
Containers add one **writable** layer on top.

---

## 5) **Docker Registries**

These store images (like GitHub, but for containers).

Common:

- Docker Hub (default)
    
- GitHub Container Registry
    
- Private registries
    

Communication example:

```
docker pull nginx
↓
Client → Daemon → Registry → Daemon → Client
```

---

## 6) **Docker Objects**

### Containers → Running instances of images

### Images → Templates

### Volumes → Persistent storage

### Networks → Communication between containers

---

# 🧠 Architecture Summary (Easy Flow)

```
Your CLI
   ↓
Docker Client
   ↓ (REST API over socket)
Docker Daemon (dockerd)
   ↓
containerd (manages lifecycle)
   ↓
runc (creates containers using namespaces/cgroups)
   ↓
Linux Kernel
   ↓
Your Container
```

---

# 🏗️ Visual Mental Model

```
+-----------------------------+
|         You (CLI)           |
+-------------+---------------+
              |
              v
+--------------------------------------+
|          Docker Daemon (API)         |
+-----------------+--------------------+
                  |
        +---------+---------+
        |     containerd    |
        +---------+---------+
                  |
               (calls)
                  |
               +-----+
               | runc|
               +--+--+
                  |
             Linux Kernel
                  |
            Running Container
```

###### Tags : [[1 - Docker 🧋]]