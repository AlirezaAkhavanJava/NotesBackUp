

## **1️⃣ What is Docker Compose?**

- **Docker** manages containers individually.
    
- **Docker Compose** lets you **define and run multi-container applications** with a single file (`docker-compose.yml`) and a single command (`docker-compose up`).
    
- Think of it as **a manager telling Docker how to run your Spring Boot app, database, caches, message queues, etc., together**.
    

---

## **2️⃣ Basics: Structure of docker-compose.yml**

A `docker-compose.yml` is a **YAML file**. YAML is strict about **spaces**, no tabs allowed.

Basic syntax:

```yaml
version: '3.9'  # Docker Compose file version

services:  # List of containers to run
  service_name:  # Name of your container
    image: image_name:tag  # Docker image to use
    build: path_to_dockerfile  # Optional: if you want to build your own image
    ports:  # Map container ports to host
      - "host_port:container_port"
    environment:  # Environment variables
      - VAR_NAME=value
    volumes:  # Map files or directories between host and container
      - host_path:container_path
    depends_on:  # Service dependencies
      - other_service_name
```

---

### **3️⃣ Example for Spring Boot + PostgreSQL**

Let’s say you have a Spring Boot app that connects to PostgreSQL. Here’s a simple `docker-compose.yml`:

```yaml
version: '3.9'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/mydb
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=postgres
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

✅ **Explanation:**

- `app` → Spring Boot container built from your project (`Dockerfile` must exist in the root).
    
- `db` → PostgreSQL container.
    
- `depends_on` ensures `db` starts before `app`.
    
- `volumes` make DB data persistent.
    

---

## **4️⃣ Advanced features**

### **4.1 Networks**

You can define custom networks:

```yaml
networks:
  mynetwork:
    driver: bridge

services:
  app:
    networks:
      - mynetwork
  db:
    networks:
      - mynetwork
```

This isolates your app’s containers from the host network if you want.

---

### **4.2 Environment variables file**

Instead of writing in `docker-compose.yml`, use `.env`:

`.env` file:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/mydb
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
POSTGRES_DB=mydb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

Then in `docker-compose.yml`:

```yaml
environment:
  - SPRING_DATASOURCE_URL=${SPRING_DATASOURCE_URL}
  - SPRING_DATASOURCE_USERNAME=${SPRING_DATASOURCE_USERNAME}
```

---

### **4.3 Multiple Spring Boot services**

If you have multiple microservices:

```yaml
services:
  service1:
    build: ./service1
    ports:
      - "8081:8080"
  service2:
    build: ./service2
    ports:
      - "8082:8080"
```

---

### **4.4 Restart policies**

Ensure your container auto-restarts:

```yaml
restart: unless-stopped
```

---

### **4.5 Healthchecks**

For orchestration:

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 5
```

---

### **5️⃣ Typical Spring Boot Docker workflow with Compose**

1. Write `Dockerfile` for your Spring Boot app:
    

```dockerfile
FROM openjdk:17-jdk-slim
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

2. Define `docker-compose.yml` (as above).
    
3. Run everything:
    

```bash
docker-compose up -d
```

4. Check logs:
    

```bash
docker-compose logs -f
```

5. Stop all services:
    

```bash
docker-compose down
```

---

### **6️⃣ Bonus pro tips**

- Use **`depends_on` + healthchecks** to prevent Spring Boot from starting before DB is ready.
    
- Use **volumes** for persistence; otherwise your database resets every time.
    
- Use **override files** (`docker-compose.override.yml`) for dev vs prod.
    
- Keep **environment variables outside the compose file** for security (use `.env`).
    

---

## a **production-ready Spring Boot setup** using **Docker Compose**. We'll include: 

- **Spring Boot app**
    
- **PostgreSQL** database
    
- **Redis** cache
    
- **Eureka server** (for service discovery)
    

---

## **1️⃣ Folder Structure Example**

```
project-root/
│
├─ app/             # Your Spring Boot application
│   └─ Dockerfile
├─ eureka/          # Eureka server app
│   └─ Dockerfile
├─ docker-compose.yml
└─ .env
```

---

## **2️⃣ Dockerfiles**

### **Spring Boot App (app/Dockerfile)**

```dockerfile
FROM eclipse-temurin:17-jdk-jammy
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

### **Eureka Server (eureka/Dockerfile)**

```dockerfile
FROM eclipse-temurin:17-jdk-jammy
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} eureka.jar
ENTRYPOINT ["java","-jar","/eureka.jar"]
```

---

## **3️⃣ .env File**

```env
# Database
POSTGRES_DB=mydb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Redis
REDIS_PASSWORD=secret

# Eureka
EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://eureka:8761/eureka
```

---

## **4️⃣ docker-compose.yml**

```yaml
version: '3.9'

services:

  eureka:
    build: ./eureka
    ports:
      - "8761:8761"
    environment:
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE}
    restart: unless-stopped

  app:
    build: ./app
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/${POSTGRES_DB}
      - SPRING_DATASOURCE_USERNAME=${POSTGRES_USER}
      - SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASSWORD}
      - SPRING_REDIS_HOST=redis
      - SPRING_REDIS_PASSWORD=${REDIS_PASSWORD}
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE}
    depends_on:
      - db
      - redis
      - eureka
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 30s
      retries: 5

  redis:
    image: redis:7
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 30s
      retries: 5

volumes:
  pgdata:
```

---

## **5️⃣ Explanation**

- **Services**: `app`, `db`, `redis`, `eureka`
    
- **Environment Variables**: Secure and flexible via `.env`
    
- **Healthchecks**: Ensure containers are ready before others start
    
- **Volumes**: Persist PostgreSQL data (`pgdata`)
    
- **depends_on**: Guarantees DB, Redis, Eureka start before `app`
    

---

## **6️⃣ Running the stack**

```bash
docker-compose up -d        # Start all services in detached mode
docker-compose logs -f app  # Follow logs for Spring Boot app
docker-compose down         # Stop and remove containers
```

---

✅ This setup is **production-ready**, modular, and scalable. You can add more Spring Boot microservices by copying the `app` service and changing ports and names.

---


##### Tags : [[1 - Docker 🧋]]