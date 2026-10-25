

The `docker push` command is used to **upload a Docker image from your local machine to a Docker registry** (like Docker Hub or a private registry). Here’s a detailed guide:

---

### **Basic Syntax**

```bash
docker push [OPTIONS] NAME[:TAG]
```

- **NAME** – The name of the image including the registry and repository.
    
- **TAG** – Optional, default is `latest`. Specifies the version of the image.
    

---

### **Steps to Push an Image**

#### **1. Build your Docker image**

```bash
docker build -t yourusername/myapp:1.0 .
```

- `yourusername/myapp` → image name in the registry
    
- `1.0` → version tag
    
- `.` → current directory (Dockerfile location)
    

---

#### **2. Login to the registry**

```bash
docker login
```

- Enter your credentials for Docker Hub or the target registry.
    

---

#### **3. Push the image**

```bash
docker push yourusername/myapp:1.0
```

- Docker will upload your image **layer by layer**.
    
- If the same layers already exist in the registry, they will be skipped (faster push).
    

---

### **Notes**

- You **must tag the image** with the correct registry/repository before pushing.
    
- For private registries:
    

```bash
docker tag myapp:1.0 myregistry.example.com/myproject/myapp:1.0
docker push myregistry.example.com/myproject/myapp:1.0
```

---

### **Verify**

You can check if the image is on the registry:

```bash
docker images
# or check directly on Docker Hub / your registry UI
```

---

##### Tags : [[1 - Docker 🧋]]