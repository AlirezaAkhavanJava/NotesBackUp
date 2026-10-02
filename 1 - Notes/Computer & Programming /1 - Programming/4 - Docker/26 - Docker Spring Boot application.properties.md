

## ⚙️ 1️⃣ Basic Spring Boot Port Configuration

By default, Spring Boot runs on port **8080**.

### 🔹 Option A — Default (no config)

If you don’t set anything:

```bash
docker run -p 8080:8080 my-java-app
```

Your app runs on **container port 8080** and maps to **host port 8080**.

✅ Access → [http://localhost:8080](http://localhost:8080/)

---

### 🔹 Option B — Change port (inside app)

In your `src/main/resources/application.properties` or `.yml`:

```properties
server.port=9090
```

or

```yaml
server:
  port: 9090
```

Then run:

```bash
docker run -p 9090:9090 my-java-app
```

If you want **host port 8080 → container 9090**:

```bash
docker run -p 8080:9090 my-java-app
```

🧠 _Rule:_  
`-p <HOST_PORT>:<CONTAINER_PORT>`  
→ host (your PC) → container (inside Docker).

---

## 🧱 2️⃣ Basic Dockerfile for Spring Boot App

```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/myapp.jar myapp.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "myapp.jar"]
```

Then:

```bash
docker build -t my-java-app .
docker run -d -p 8080:8080 my-java-app
```

---

## 🧩 3️⃣ Verifying Ports

Check which ports are used:

```bash
sudo netstat -tuln | grep 8080
```

or

```bash
docker ps
```

Sample output:

```
CONTAINER ID   IMAGE         PORTS                    NAMES
9a1b2c3d4e5f   my-java-app   0.0.0.0:8080->8080/tcp   my-running-app
```

✅ Means host 8080 maps to container 8080.

---

## 🌐 4️⃣ Docker Networking Modes (Advanced)

### 🧩 **Bridge (default)**

- Each container has its own private IP.
    
- You use `-p` to map host↔container ports.
    

```bash
docker run -p 8080:8080 my-java-app
```

### 🧩 **Host Network Mode**

- Container uses **the same network** as the host.
    
- No port mapping needed, but conflicts possible.
    

```bash
docker run --network host my-java-app
```

Then your app must bind to:

```properties
server.address=0.0.0.0
server.port=8080
```

and you can access it at `http://localhost:8080`.

⚠️ Use only on **Linux**, not cross-platform safe.

### 🧩 **Custom Networks**

If you have multiple containers (e.g., app + PostgreSQL):

```bash
docker network create mynet
docker run -d --network mynet --name mydb postgres
docker run -d --network mynet --name myapp -p 8080:8080 my-java-app
```

Then in your app:

```properties
spring.datasource.url=jdbc:postgresql://mydb:5432/mydatabase
```

No IPs needed, just service names!

---

## 🧰 5️⃣ Handling Common Port Errors

|Error|Cause|Fix|
|---|---|---|
|`BindException: Address already in use`|Host port busy|Use a different host port (e.g., `-p 9090:8080`)|
|`Connection refused`|Container port not matching app’s port|Make sure `EXPOSE` and `server.port` are the same|
|`Cannot connect to localhost:8080`|Not published|Add `-p` flag in `docker run`|

---

## 🔒 6️⃣ Pro-level Setup Example

**Dockerfile**

```dockerfile
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY target/myapp.jar myapp.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","myapp.jar"]
```

**application.properties**

```properties
server.address=0.0.0.0
server.port=8080
```

**Build and Run**

```bash
docker build -t my-java-app:latest .
docker run -d -p 8080:8080 --name myapp my-java-app:latest
```

**Verify**

```bash
docker logs myapp
docker ps
```

✅ Open → [http://localhost:8080](http://localhost:8080/)

---

## 🧠 7️⃣ Quick Summary (cheat sheet)

|Task|Command|Notes|
|---|---|---|
|Build image|`docker build -t myapp .`|uses Dockerfile|
|Run container|`docker run -p 8080:8080 myapp`|map host→container|
|Change app port|`server.port=9090`|inside properties|
|Map different ports|`docker run -p 9090:8080 myapp`|host 9090 → container 8080|
|View running|`docker ps`|show ports|
|Logs|`docker logs myapp`|view output|

---


##### Tags : [[1 - Docker 🧋]]