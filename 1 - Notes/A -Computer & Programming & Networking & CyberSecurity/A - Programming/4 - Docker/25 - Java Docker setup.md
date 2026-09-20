


## 🧱 1️⃣ `docker build` — Build your image

**Purpose:** Takes your project and Dockerfile → creates a runnable _image_.

### 🧩 Example:

```bash
docker build -t my-java-app .
```

**Explanation:**

- `docker build` → starts the build process.
    
- `-t my-java-app` → names the image `my-java-app`.
    
- `.` → means “use the Dockerfile in the current directory”.
    

### 🧰 Typical Java Dockerfile:

```dockerfile
# Use an official JDK image
FROM openjdk:17-jdk-slim

# Copy your JAR file into the container
COPY target/myapp.jar /app/myapp.jar

# Set working directory
WORKDIR /app

# Expose app port (Spring Boot default = 8080)
EXPOSE 8080

# Run your app
ENTRYPOINT ["java", "-jar", "myapp.jar"]
```

Then build it:

```bash
docker build -t my-java-app .
```

---

## 🚀 2️⃣ `docker run` — Run your container

**Purpose:** Start a container (an instance of your image).

### ✅ Example:

```bash
docker run -d -p 8080:8080 --name my-running-app my-java-app
```

**Explanation:**

- `-d` → run detached (in background).
    
- `-p 8080:8080` → maps **host port 8080** → **container port 8080**.
    
    - Left side: your **machine (Docker host)**.
        
    - Right side: inside **container (Java app)**.
        
- `--name my-running-app` → name for container.
    
- `my-java-app` → image name to run.
    

So you can open 👉 **[http://localhost:8080](http://localhost:8080/)**

---

## ⚠️ Common Port Rules (to avoid errors)

1. **Container port** must match what your app uses internally (Spring Boot default = 8080).
    
2. **Host port** can be **anything not already in use**.
    
    - Example if 8080 is busy:
        
        ```bash
        docker run -p 9090:8080 my-java-app
        ```
        
        → now access via [http://localhost:9090](http://localhost:9090/)
        
3. Don’t reuse ports across multiple containers unless you use different host ports.
    

---

## 🧠 3️⃣ “Host” meaning here:

- The **host port** is the port on your **machine**.
    
- The **container port** is the port **inside the container**.
    
- Docker bridges them via `-p host:container`.
    

---

## 🧩 Full Example Summary

```bash
# 1. Build the image
docker build -t my-java-app .

# 2. Run it, mapping host 8080 to container 8080
docker run -d -p 8080:8080 my-java-app
```

✅ Access at: [http://localhost:8080](http://localhost:8080/)

---



##### Tags : [[1 - Docker 🧋]]