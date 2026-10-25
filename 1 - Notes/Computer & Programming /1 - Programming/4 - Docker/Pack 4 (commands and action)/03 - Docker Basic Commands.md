
### **1. `docker run`**

- **What it does:** Starts a container from an image. Can also pull the image if not present.
    
- **Example:**
    

```bash
docker run -it ubuntu bash
```

- `-it` = interactive + terminal
    
- This gives you a shell inside an Ubuntu container.
    

---

### **2. `docker ps`**

- **What it does:** Lists running containers.
    
- **Example:**
    

```bash
docker ps
```

- Add `-a` to see all containers (running + stopped):
    

```bash
docker ps -a
```

---

### **3. `docker images`**

- **What it does:** Lists all images on your system.
    
- **Example:**
    

```bash
docker images
```

---

### **4. `docker pull`**

- **What it does:** Downloads an image from Docker Hub.
    
- **Example:**
    

```bash
docker pull nginx
```

---

### **5. `docker stop` / `docker start`**

- **Stop a running container:**
    

```bash
docker stop <container_id>
```

- **Start a stopped container:**
    

```bash
docker start <container_id>
```

---

### **6. `docker rm`**

- **What it does:** Deletes a container (stopped first).
    
- **Example:**
    

```bash
docker rm <container_id>
```

---

### **7. `docker rmi`**

- **What it does:** Deletes an image.
    
- **Example:**
    

```bash
docker rmi <image_id>
```

---

### **8. `docker exec`**

- **What it does:** Runs a command inside a running container.
    
- **Example:**
    

```bash
docker exec -it <container_id> bash
```

---

### **9. `docker logs`**

- **What it does:** Shows logs of a container.
    
- **Example:**
    

```bash
docker logs <container_id>
```

---

### **10. `docker build`**

- **What it does:** Builds an image from a Dockerfile.
    
- **Example:**
    

```bash
docker build -t myapp:1.0 .
```

- `-t` = tag (name:version)
    
- `.` = current directory (where Dockerfile is)
    


#### Tags : [[1 - Docker 🧋]]