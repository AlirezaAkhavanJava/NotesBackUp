
The `docker login` command is used to authenticate your Docker client to a Docker registry (like Docker Hub, AWS ECR, GCP Artifact Registry, or a private registry). Once logged in, you can push and pull images from that registry. Here’s a detailed breakdown:

---

### **Basic Syntax**

```bash
docker login [OPTIONS] [SERVER]
```

- **SERVER** – The URL of the Docker registry (optional for Docker Hub).
    
- **OPTIONS** – Useful flags like `-u` for username, `-p` for password.
    

---

### **Examples**

#### **1. Login to Docker Hub (default)**

```bash
docker login
```

It will prompt you for:

```
Username: your_username
Password: your_password
```

#### **2. Login with username and password inline**

```bash
docker login -u your_username -p your_password
```

⚠️ **Security warning:** Inline passwords can be seen in your shell history. Better to use the prompt method.

#### **3. Login to a private registry**

```bash
docker login myregistry.example.com
```

It will prompt for your registry username and password.

---

### **Verify Login**

After logging in, you can check your login status:

```bash
docker info
```

Look for the `Username:` under `Registry` info.

---

### **Logout**

```bash
docker logout
```

or for a specific registry:

```bash
docker logout myregistry.example.com
```

---

💡 **Tip:** Once logged in, Docker stores credentials in `~/.docker/config.json` so you don’t need to log in every time.

---



##### Tags : [[1 - Docker 🧋]]