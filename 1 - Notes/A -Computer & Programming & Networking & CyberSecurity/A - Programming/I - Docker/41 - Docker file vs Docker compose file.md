![[Pasted image 20251210182218.png]]

## **1. Dockerfile**

- **Purpose:** Tells Docker _how to build a single image_.
    
- **Defines:** Base image, dependencies, code, environment variables, commands.
    
- **Syntax:** Instructions like `FROM`, `COPY`, `RUN`, `CMD`, `EXPOSE`.
    
- **Output:** A **Docker image**.
    

**Example (Spring Boot):**

```dockerfile
FROM openjdk:23-jdk
COPY target/blackunicorn.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app.jar"]
```

---

## **2. Docker Compose file (`docker-compose.yml`)**

- **Purpose:** Orchestrates _multiple containers_ together.
    
- **Defines:** Which images/containers to run, ports, volumes, networks, environment variables, dependencies between services.
    
- **Syntax:** YAML, uses `services:` and `volumes:` blocks.
    
- **Output:** Running **containers** in a networked environment.
    

**Example (Spring Boot + MySQL + Redis):**

```yaml
version: "3.9"
services:
  app:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - db
      - redis
  db:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: blackdb
    ports:
      - "3306:3306"
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
```

---

### **Key Difference**

|Aspect|Dockerfile|Docker Compose|
|---|---|---|
|What it defines|How to build an image|How to run containers|
|Number of containers|Usually 1|1+ (multi-container apps)|
|Syntax|Dockerfile DSL (`RUN`, `COPY`)|YAML|
|Output|Image|Running containers|

✅ **TL;DR:** Dockerfile = recipe, Compose = orchestration.

---

#### When to use What ? 

## **1️⃣ Only Dockerfile**

Use a **Dockerfile alone** if your project is **a single container**.

- Example: A Spring Boot app that runs standalone (no DB, no Redis).
    
- You build the image and run it:
    

```bash
docker build -t myapp:v1 .
docker run -p 8080:8080 myapp:v1
```

✅ Simple, lightweight, perfect for single-service apps.

---

## **2️⃣ Docker Compose**

Use **docker-compose.yml** if your project has **multiple containers** that need to work together.

- Example: Spring Boot + MySQL + Redis + Nginx.
    
- Compose lets you:
    
    - Start all containers with one command (`docker-compose up`)
        
    - Define networks and volumes automatically
        
    - Manage environment variables per service
        

```yaml
version: "3.9"
services:
  app:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - db
      - redis

  db:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: blackdb

  redis:
    image: redis:latest
```

---

### **Rule of Thumb**

|Scenario|Use|
|---|---|
|Single container|Dockerfile only|
|Multi-container (DB, cache, broker, etc.)|Dockerfile + Docker Compose|

---

💡 **Tip:** Even in a multi-container setup, **every service usually has its own Dockerfile** if it’s custom-built (like your Spring Boot app). Compose just orchestrates them.



###### Tags : [[1 - Docker 🧋]]